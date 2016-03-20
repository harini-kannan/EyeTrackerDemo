//
//  EyeCaptureSession.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/24/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import AVFoundation
import CoreGraphics
import CoreImage
import Foundation
import UIKit

/// 👀 🎥
///
/// `EyeCaptureSession` abstracts away the details of video capture and face/eye
/// detection. The `EyeCaptureSessionDelegate` allows you to make use of
/// real-time detections. The delegate call is blocking, as to drop frames
/// rather than backing the pipeline up if it takes too long.
///
/// To use this class, simply call the initializer, feeling free to use nil for
/// unneeded optional values. Though not required, you will most likely want to
/// implement your own `EyeCaptureSessionDelegate`. Work is done on a separate
/// thread, so be sure to make UI changes on the main thread. Most properties
/// have the default internal visibility. Feel free to access or modify them as
/// needed. Capture will begin automatically at initialization.
///
/// Output (i.e., arguments to the delegate methods) coordinates are in the
/// `UIKit` (e.g., `UIImage`) space (with the origin at the top left).
/// Regardless of supported UI orientations, EyeCaptureSession will detect the
/// device's orientation and rotate the camera image and bounding boxes
/// accordingly. One exception is if the phone's orientation is locked. You may
/// modify the supportedOrientations variable to remove support for one or more
/// orientations. If you are displaying bounding boxes, you will need to account
/// for different orientations differently depending on how your UI responds to
/// orientation changes. If your app displays the camera preview, we recommend
/// not rotating the entire view since the main UI element (i.e., the camera
/// preview) naturally rotates as the device rotates. See the Camera app or any
/// other camera UI for examples. If your app doesn't display the camera
/// preview, it's up to you.
///
/// Internally, it uses `AVCaptureMetadataOutputObjectsDelegate`'s method to
/// detect faces very quickly (on the GPU). At the same time, each frame is
/// processed in `AVCaptureVideoDataOutputSampleBufferDelegate`'s method. The
/// metadata and the frame delegate methods don't work together or even in
/// order, but they are called so frequently, we can just detect a face when no
/// frames are being processed, and process frames using the most recent face
/// detection. A face detector could be used explicitly on each frame, but this
/// is much faster.
class EyeCaptureSession: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {  // We must inherit from NSObject to implement the AV protocols.
    
    var circleTimer: NSTimer?
    let redLayer = CALayer()
    let circleRadius = CGFloat(25)
    
    // Delegate.
    var delegate: EyeCaptureSessionDelegate?
    
    // Capture session.
    var captureSession: AVCaptureSession!  // Initialized in setUpCaptureSession.
    // TODO: Provide a way to disable creation of this layer in the first place if it won't be used.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!  // Initialized in setUpCaptureSession, even if there is no view to display it. This avoids a delay later on if a view is added.
    
    // Pipeline state (for communication between the face and frame delegate methods).
    private var metadataFaceRect: CGRect?  // The metadata face detector will give us coordinates in the range 0–1. These variables are not modified during frame processing.
    private var metadataFaceYaw: CGFloat?
    private var metadataFaceRoll: CGFloat?
    private var queuedMetadataFaceRect: CGRect?  // Variables with "queued" as a prefix are for face detections that happen during frame processing. Data here will be migrated to the plain "metadata" variables once the frame is done processing, so there's something ready at the next frame call.
    private var queuedMetadataFaceYaw: CGFloat?
    private var queuedMetadataFaceRoll: CGFloat?
    private var processingFrame = false  // This prevents the metadata variables from changing while a frame is being processed.
    
    // Eye detection.
    var faceImageContext = CIContext(options: nil)  // Reusing this context speeds things up.
    var contextFix = 0  // Recreate the context every so many frames. Workaround for https://forums.developer.apple.com/thread/17142
    let contextFixFrequency = 50  // How often to recreate the context?
    let eyeDetectorCI: CIDetector  // Apple's CIDetector for detecting faces and facial features. We only use this for locating eyes.
    let eyeDetectorCV: CVEyeDetector  // Wrapper around OpenCV's cv::CascadeClassifier.
    enum DetectorMethod {
        case CIDetector, OpenCV  // Represents the CIDetector and CVEyeDetector classes.
    }
    var selectedDetector = DetectorMethod.CIDetector  // Which detector to use. This may be changed at any point. The default detector is the CIDetector (same default as in the segmented control).
    var detectBlinks = false {  // Whether or not to detect blinks. This is only supported in the CIDetector.
        willSet {
            if selectedDetector == .OpenCV {
                print("Warning: The OpenCV eye detector does not detect blinks. Expect nil blink values.")
            }
        }
    }
    // TODO: Consider incoroporating the temporal filter into the debugView. (It
    // currently displays raw detections.) This would make some things
    // disorganized due to encapsulation though.
    var enableTemporalSmoothing = true  // This may be changed whenever (from an outside class).
    let kalmanFilterLeft = KalmanFilter()  // Class to smooth out jitter in eye detection.
    let kalmanFilterRight = KalmanFilter()
    
    // Maximum framerate. Otherwise, the frames are processed as quickly as they
    // can be received from the camera and processed (e.g., eye detection).
    var maximumFPS: Int? {
        didSet {
            if self.maximumFPS == nil {
                self.mostRecentFrameTime = nil  // Clean the state.
            }
        }
    }
    private var mostRecentFrameTime: NSDate?
    
    // Locked face/eye detections.
    var detectionLocked = false
    var detectionLockFaceFrame: FaceFrame?  // The locked-on face/eye detections. The image is updated, but everything else is left the same.
    
    // External views.
    // We use weak references so they will be set to nil in the unlikely event that the view unloads while this object is still around.
    weak var videoView: UIView? {
        didSet {
            setUpVideoView()
        }
    }
    weak var debugView: UIImageView? {  // Setting this to nil will not hide the view, just stop updating it.
        didSet {
            self.eyeDetectorCV.setDebugView(self.debugView)
        }
    }
    
    weak var rightEyeView: UIImageView?
    weak var leftEyeView: UIImageView?
    
    // Stats.
    private var frameFPSQueue = FPSQueue()  // TODO: Rename this as not to confuse with GCD queues.
    var frameFPS: Int {
        return frameFPSQueue.rate
    }
    private var metadataFPSQueue = FPSQueue()
    var metadataFPS: Int {
        return metadataFPSQueue.rate
    }
    var lastDetectionDuration = 0  // Detection time in milliseconds. This is left unchanged on frames without any faces.
    
    // EXIF orientation values. The value specifies where the origin (0,0) of
    // the image is located as a row/column pair.
    // NOTE: If this list supports more than .Portrait, .LandscapeLeft,
    // .LandscapeRight, or .PortraitUpsideDown, additional code will need to be
    // modified.
    // TODO: This should be a parameter to init; for now, it should be able to
    // be modified directly whenever.
    let supportedOrientations = Set<UIDeviceOrientation>([.Portrait, .LandscapeLeft, .LandscapeRight, .PortraitUpsideDown])
    // If the device orientation is not supported, set it to .Portrait. This
    // will be updated each time a face is detected.
    var currDeviceOrientation = UIDeviceOrientation.Portrait
    enum EXIFOrientation: Int32 {
        case TopLeft     = 1 // 0th row is at the top; 0th column is on the left (default).
        case TopRight    = 2 // 0th row is at the top; 0th column is on the right.
        case BottomRight = 3 // 0th row is at the bottom; 0th column is on the right.
        case BottomLeft  = 4 // 0th row is at the bottom; 0th column is on the left.
        case LeftTop     = 5 // 0th row is on the left; 0th column is the top.
        case RightTop    = 6 // 0th row is on the right; 0th column is the top.
        case RightBottom = 7 // 0th row is on the right; 0th column is the bottom.
        case LeftBottom  = 8 // 0th row is on the left; 0th column is the bottom.
    }
    
    // MARK: - Initializer
    
    /// Initializes a new `EyeCaptureSession` and immediately begins capture.
    ///
    /// - parameter delegate:  An object implementing additional work to be done for
    ///                   each frame.
    /// - parameter videoView: A view to attach a preview of the video capture.
    /// - parameter debugView: A view to display the raw face crops and detections.
    init(delegate: EyeCaptureSessionDelegate?, videoView: UIView?, debugView: UIImageView?, rightEyeView: UIImageView?, leftEyeView: UIImageView?) {
        // Set up properties.
        self.delegate = delegate
        // videoView's didSet method should not be called here; setUpVideoView()
        // will be called initially in setUpCaptureSession(), after the
        // captureSession has been created.
        self.videoView = videoView
        self.debugView = debugView
        
        self.rightEyeView = rightEyeView
        self.leftEyeView = leftEyeView
        
        // Set up both eye detectors.
        eyeDetectorCV = CVEyeDetector(cascadeFilename: NSBundle.mainBundle().pathForResource("haarcascade_eye", ofType: "xml"))
        eyeDetectorCV.setDebugView(self.debugView)
        eyeDetectorCI = CIDetector(ofType: CIDetectorTypeFace, context: self.faceImageContext, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
        
        super.init()
        
        setUpCaptureSession()
    }
    
    // MARK: - Detection Lock Methods
    // TODO: Consider moving these methods to a lockDetection: Bool observer.
    
    /// Lock the next face/eye detection and repeatedly use those until
    /// `detectionUnlock()` is called.
    func detectionLock() {
        if self.detectionLocked {
            self.detectionUnlock()
        }
        self.detectionLocked = true
    }
    
    /// Unlock face/eye detection.
    func detectionUnlock() {
        self.detectionLocked = false
        self.detectionLockFaceFrame = nil
    }
    
    // MARK: - AVCapture Delegate Methods
    
    // Detect faces on the GPU.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        self.metadataFPSQueue.countFrame()
        
        if metadataObjects.count < 1 {
            // This tends to happen once when the face leaves the camera. No cause for alarm.
            // println("Warning: Metadata handler was called without any metadata objects to process.")
            return
        }
        if metadataObjects[0].type != AVMetadataObjectTypeFace {
            print("Warning: Found a non-face metadata. Is the detector configured to only find faces?")
            return
        }
        
        // Get the latest device orientation.
        let newOrientation = UIDevice.currentDevice().orientation
        // If the device changes to an unsupported orientation, leave it as the
        // previous orientation.
        if newOrientation != self.currDeviceOrientation && self.supportedOrientations.contains(newOrientation) {
            self.currDeviceOrientation = newOrientation
        }
        
        // Though orientation is set above, orientation corrections to the
        // following metadata will be made later.
        
        // The first face in the array is the most confident.
        let bestFace = metadataObjects[0] as! AVMetadataFaceObject
        let metadataFaceRect = CGRect(x: bestFace.bounds.origin.x, y: bestFace.bounds.origin.y, width: bestFace.bounds.width, height: bestFace.bounds.height)
        
        // Note: CIDetector can detect face angle and it may or may not
        // offer finer granularity than 30/45 degrees, but we might as well
        // make use of the data here and it can be used with OpenCV.
        let metadataFaceYaw: CGFloat? = bestFace.hasYawAngle ? bestFace.yawAngle : nil
        let metadataFaceRoll: CGFloat? = bestFace.hasRollAngle ? bestFace.rollAngle : nil
        
        if !self.processingFrame {
            self.metadataFaceRect = metadataFaceRect
            self.metadataFaceYaw = metadataFaceYaw
            self.metadataFaceRoll = metadataFaceRoll
        } else {
            // This may overwrite a previous detection, but that's okay; we want the latest once we have the capacity to process a new frame.
            self.queuedMetadataFaceRect = metadataFaceRect
            self.queuedMetadataFaceYaw = metadataFaceYaw
            self.queuedMetadataFaceRoll = metadataFaceRoll
        }
    }
    
    // Process frames. This method is invoked on the frameOutputQueue, so UI
    // changes must be done on a different thread. Frames will be dropped when
    // this method takes too long.
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        if ++self.contextFix > self.contextFixFrequency {
            self.faceImageContext = CIContext(options: nil)
        }
        
        let now = NSDate()
        if let maximumFPS = self.maximumFPS {
            if let mostRecentFrameTime = self.mostRecentFrameTime {
                if now.timeIntervalSinceDate(mostRecentFrameTime) < 1.0 / Double(maximumFPS) {
                    return  // Pretend this frame never happened.
                }
            }
            self.mostRecentFrameTime = now
        }
        self.processingFrame = true
        self.frameFPSQueue.countFrame()
        // Instantiate the FaceFrame object that will be passed to the delegate.
        // Many of the properties may be nil if no face was found.
        let ff = FaceFrame()  // This will store the current time.
        ff.time = now
        
        // Store the frame image in the FaceFrame whether there's a face or not.
        var image: CIImage!
        var fullFrameSize: CGSize!
        var fullFrameExtent: CGRect!
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)) as? [String : AnyObject]  // Contains extra info about the frame, such as the clean aperture. Read more: https://developer.apple.com/library/mac/documentation/GraphicsImaging/Conceptual/CoreVideo/CVProg_Concepts/CVProg_Concepts.html#//apple_ref/doc/uid/TP40001536-CH202-DontLinkElementID_4
        // NOTE: This broke in Xcode 7.0/Swift 2.0. Using "as?" may mean this always produces nil, but it is not essential that we copy attachments.
        image = CIImage(CVPixelBuffer: CMSampleBufferGetImageBuffer(sampleBuffer)!, options: attachments)
        
        // Determine orientation.
        var currEXIFOrientation: EXIFOrientation
        switch self.currDeviceOrientation {
        case .PortraitUpsideDown:
            // Even though this isn't supported now, it could be later by
            // adding this to supportedOrientations.
            currEXIFOrientation = .LeftBottom
        case .LandscapeLeft:
            // Front-facing camera.
            currEXIFOrientation = .BottomRight
            // For the back-facing camera, use .TopLeft.
        case .LandscapeRight:
            // Front-facing camera.
            currEXIFOrientation = .TopLeft
            // For the back-facing camera, use .BottomRight.
        default:  // .Portrait is the default.
            currEXIFOrientation = .RightTop
        }
        
        image = image.imageByApplyingOrientation(currEXIFOrientation.rawValue)
        // NOTE: CIImage operations could be chained together for a potential
        // performance bump (though likely minor). This could also include the
        // resize operation that's in findEyes.
        
        // Similar code often uses the "clean aperture" (or "clap") to get the
        // rectangle describing the origin/dimensions of usable frame data, but
        // the CIImage extent seems to describe the same thing. This probably
        // comes from the clean aperture anyway.
        //
        // This property could be stored into the faceFrame object even if no
        // face is detected, but there's no need. In fact, it should be the same
        // for every frame anyway (unless multiple orientations are supported).
        fullFrameSize = image.extent.size
        fullFrameExtent = image.extent
        
        // Extend the image infinitely in all directions so that the padded crop
        // rectangle won't be clipped at the edges. We could just account for
        // less padding near the edges, but it's better to always assume the
        // face is in the center: CIDetector needs some padding on all sides to
        // operate properly and the CVEyeDetector is optimized by cropping out
        // the eye area (which assumes that the face is centered in the box).
        image = image.imageByClampingToExtent()
        ff.fullFrame = UIImage(CGImage: self.faceImageContext.createCGImage(image, fromRect: fullFrameExtent))
        ff.fullFrameSize = fullFrameSize
        ff.deviceOrientation = self.currDeviceOrientation  // This may be overwritten if face detection is locked.
        // Done saving frame image.
        
        if let lff = self.detectionLockFaceFrame {  // Face detection locked in.
            ff.faceRect = lff.faceRect
            ff.leftEye = lff.leftEye
            ff.rightEye = lff.rightEye
            ff.faceRect = lff.faceRect
            ff.faceYaw = lff.faceYaw
            ff.faceRoll = lff.faceRoll
            ff.leftEyeClosed = lff.leftEyeClosed
            ff.rightEyeClosed = lff.rightEyeClosed
            ff.deviceOrientation = lff.deviceOrientation  // Overwrite current orientation with the locked one.
            
            // Save the current image in there.
            let scaledFaceRect = lff.faceRect!.rectWithFlippedY(inFrame: fullFrameSize)  // Flip back to CI coordinates.
            // lff should definitely have a faceRect, since we only lock it when a faceRect is found.
            let faceCropCI = image.imageByCroppingToRect(scaledFaceRect)
            ff.faceCrop = UIImage(CGImage: self.faceImageContext.createCGImage(faceCropCI, fromRect: faceCropCI.extent))
        } else if let unscaledFaceRect = self.metadataFaceRect {  // Face detected; not locked.
            var rollCorrection = 0.0
            switch self.currDeviceOrientation {
            case .Portrait:
                rollCorrection = 90.0
            case .LandscapeLeft:
                rollCorrection = 180.0
            case .LandscapeRight:
                rollCorrection = 0.0
            case .PortraitUpsideDown:
                rollCorrection = 270.0
            default:
                fatalError("Unsupported orientation when correcting face roll.")
            }
            // Correct face roll according to the current orientation. It should
            // be a positive value in the range 0..<360, relative to the person.
            // Keeping the head stationary and rotating the device in 90°
            // increments should not change roll (provided the orientation is
            // supported).
            var correctedFaceRoll: CGFloat?
            if let metadataFaceRoll = self.metadataFaceRoll {
                correctedFaceRoll = CGFloat((360.0 - (Double(metadataFaceRoll) + rollCorrection) + 360.0) % 360.0)
            }
            
            ff.faceYaw = self.metadataFaceYaw
            ff.faceRoll = correctedFaceRoll
            
            ff.fullFrameSize = fullFrameSize
            
            // The image has already been orientation-corrected at this point,
            // but the unscaled face dimensions have not. This involves a few
            // different transforms: scaling from 0–1 to true pixel values,
            // and perhaps swapping axes and mirroring. Ultimately, we want to
            // be in CoreImage coordinate space.
            var scaledFaceRect = CGRect()
            switch self.currDeviceOrientation {
            case .Portrait:
                let scaledX = unscaledFaceRect.origin.x * ff.fullFrameSize!.height
                let scaledY = unscaledFaceRect.origin.y * ff.fullFrameSize!.width
                let scaledW = unscaledFaceRect.width * ff.fullFrameSize!.height
                let scaledH = unscaledFaceRect.height * ff.fullFrameSize!.width
                scaledFaceRect = CGRect(
                    x: ff.fullFrameSize!.width - (scaledY + scaledH),
                    y: ff.fullFrameSize!.height - (scaledX + scaledW),
                    width: scaledH,
                    height: scaledW)
            case .LandscapeLeft:  // Home button on the right side.
                let scaledX = unscaledFaceRect.origin.x * ff.fullFrameSize!.width
                let scaledY = unscaledFaceRect.origin.y * ff.fullFrameSize!.height
                let scaledW = unscaledFaceRect.width * ff.fullFrameSize!.width
                let scaledH = unscaledFaceRect.height * ff.fullFrameSize!.height
                scaledFaceRect = CGRect(
                    x: ff.fullFrameSize!.width - (scaledX + scaledW),
                    y: scaledY,
                    width: scaledW,
                    height: scaledH)
            case .LandscapeRight:  // Home button on the left side.
                let scaledY = unscaledFaceRect.origin.y * ff.fullFrameSize!.height
                let scaledX = unscaledFaceRect.origin.x * ff.fullFrameSize!.width
                let scaledW = unscaledFaceRect.width * ff.fullFrameSize!.width
                let scaledH = unscaledFaceRect.height * ff.fullFrameSize!.height
                scaledFaceRect = CGRect(
                    x: scaledX,
                    y: ff.fullFrameSize!.height - (scaledY + scaledH),
                    width: scaledW,
                    height: scaledH)
            case .PortraitUpsideDown:
                let scaledX = unscaledFaceRect.origin.x * ff.fullFrameSize!.height
                let scaledY = unscaledFaceRect.origin.y * ff.fullFrameSize!.width
                let scaledW = unscaledFaceRect.width * ff.fullFrameSize!.height
                let scaledH = unscaledFaceRect.height * ff.fullFrameSize!.width
                scaledFaceRect = CGRect(
                    x: scaledY,
                    y: scaledX,
                    width: scaledH,
                    height: scaledW)
            default:
                fatalError("Unsupported orientation when correcting face bounding box.")
            }
            
            // Add some more padding to the face crop. It's required to make the
            // CIDetector find the face at all and it provides a little more
            // margin for error for the OpenCV detector.
            var padding: CGFloat
            switch self.selectedDetector {
            case .CIDetector:
                padding = scaledFaceRect.width * 0.25  // How much (as a percentage of the face width) should be added to each edge?
            case .OpenCV:
                padding = scaledFaceRect.width * 0.10
            }
            
            // Crop the face without padding first.
            ff.faceRect = scaledFaceRect.rectWithFlippedY(inFrame: ff.fullFrameSize!)
            let faceCropCI = image.imageByCroppingToRect(scaledFaceRect)
            ff.faceCrop = UIImage(CGImage: self.faceImageContext.createCGImage(faceCropCI, fromRect: faceCropCI.extent))
            ff.fullFrame = UIImage(CGImage: self.faceImageContext.createCGImage(image, fromRect: fullFrameExtent))
            
            // Adjust the scaledFaceRect to reflect the padding.
            scaledFaceRect.origin.x -= padding
            scaledFaceRect.origin.y -= padding
            scaledFaceRect.size.width += 2 * padding
            scaledFaceRect.size.height += 2 * padding
            
            var faceCropPadded = image.imageByCroppingToRect(scaledFaceRect)
            faceCropPadded = faceCropPadded.imageByApplyingTransform(CGAffineTransformMakeTranslation(-faceCropPadded.extent.origin.x, -faceCropPadded.extent.origin.y))  // Translate to the origin so that CIDetector detections are relative to this crop, not the original.
            
            let timeA = NSDate()
            var (leftEye, rightEye, leftEyeClosed, rightEyeClosed) = findEyes(faceCropPadded)
            let timeB = NSDate()
            self.lastDetectionDuration = Int(round(timeB.timeIntervalSinceDate(timeA) * 1000))  // Store the time in milliseconds.
            
            // Remove padding.
            if leftEye != nil {
                leftEye!.origin.x -= padding
                leftEye!.origin.y -= padding
            }
            if rightEye != nil {
                rightEye!.origin.x -= padding
                rightEye!.origin.y -= padding
            }
            scaledFaceRect.origin.x += padding
            scaledFaceRect.origin.y += padding
            scaledFaceRect.size.width -= 2 * padding
            scaledFaceRect.size.height -= 2 * padding
            
            ff.leftEye = leftEye?.rectWithFlippedY(inFrame: ff.faceRect!)
            ff.rightEye = rightEye?.rectWithFlippedY(inFrame: ff.faceRect!)
            ff.leftEyeClosed = leftEyeClosed
            ff.rightEyeClosed = rightEyeClosed
        }
        
        // Save the FaceFrame if detection lock mode is on and there is not yet
        // a saved FaceFrame. Also, only save it if the current FaceFrame has
        // valid face/eye detections.
        if self.detectionLocked && self.detectionLockFaceFrame == nil && ff.faceRect != nil && ff.leftEye != nil && ff.rightEye != nil {
            self.detectionLockFaceFrame = ff
        }
        
        // Call delegate whether a face was found or not.
        // TODO: Confirm that the bounds are within the image/face. If not,
        //       clip.
        delegate?.processFace(ff)
        
        // If we just processed a face, clear it.
        if self.metadataFaceRect != nil {
            self.metadataFaceRect = nil
            self.metadataFaceYaw = nil
            self.metadataFaceRoll = nil
        }
        
        // If there's another detection waiting for us, set it up to be used next.
        if self.queuedMetadataFaceRect != nil {
            self.metadataFaceRect = self.queuedMetadataFaceRect
            self.metadataFaceYaw = self.queuedMetadataFaceYaw
            self.metadataFaceRoll = self.queuedMetadataFaceRoll
            // Clear the queued values.
            self.queuedMetadataFaceRect = nil
            self.queuedMetadataFaceYaw = nil
            self.queuedMetadataFaceRoll = nil
        }
        
        self.processingFrame = false
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        // TODO: Call a dropped frame delegate.
    }
    
    // MARK: - Helper Methods
    
    func setUpCaptureSession() {
        // TODO: The following will crash in a simulator; check to provide a better error message?
        // TODO: I believe this asks the user for camera permissions; warn first?
        
        // Some of this code comes from the following link:
        // https://github.com/ShinobiControls/iOS7-day-by-day/tree/master/18-coreimage-features
        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480
        
        // Get the front-facing camera.
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]!
        var frontFacingCamera: AVCaptureDevice?
        for device in devices {
            if (device.position == AVCaptureDevicePosition.Front) {
                frontFacingCamera = device
            }
        }
        
        if frontFacingCamera == nil {
            fatalError("Error: Failed to find the front-facing camera.")
            // Alternatively, use AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo), which should be the back-facing camera.
        }
        
        // Add input and output to the session.
        let input = try? AVCaptureDeviceInput(device: frontFacingCamera)
        if let input = input {
            self.captureSession.addInput(input)
        } else {
            fatalError("Error: Failed to initialize video device.")
        }
        
        // Output to respond to faces.
        let metadataOutput = AVCaptureMetadataOutput()
        self.captureSession.addOutput(metadataOutput)
        // Now that the output has been added, we can set the metadata type to recognize faces.
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        // Configure this class as the delegate and call it on the main thread. We could use a
        // different thread, but we would need to make sure to manipulate the UI in the main
        // thread. This should be fast enough, ideally.
        let metadataOutputQueue = dispatch_queue_create("MetadataOutputQueue", DISPATCH_QUEUE_SERIAL)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataOutputQueue)
        
        // Output to process frame data.
        // TODO: Probably make these member variables.
        let frameOutput = AVCaptureVideoDataOutput()
        self.captureSession.addOutput(frameOutput)
        // Create a queue to process frames on. It must be serial so that frames
        // are processed in order. If this queue is blocked, frames may be
        // immediately dropped, depending on the setting of
        // alwaysDiscardsLateFrames.
        let frameOutputQueue = dispatch_queue_create("FrameOutputQueue", DISPATCH_QUEUE_SERIAL)
        frameOutput.setSampleBufferDelegate(self, queue: frameOutputQueue)
        // TODO: Consider the following configs from Apple's SquareCam example code.
        // Convert to BGRA now because CoreGraphics and OpenGL work well with 'BGRA'. Default output is YUV.
        // var rgbOutputSettings: [NSObject: AnyObject] = [kCVPixelBufferPixelFormatTypeKey: NSNumber(integer: kCMPixelFormat_32BGRA)]  // Why is this type annotation necessary?
        // frameOutput.videoSettings = rgbOutputSettings
        frameOutput.alwaysDiscardsLateVideoFrames = true  // Discard if the data output queue is blocked.
        
        // Set up the videoPreviewLayer, whether it is displayed or not.
        //self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        //self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        //setUpVideoView()
        
        self.captureSession.startRunning()
    }
    
    func setUpVideoView() {
        self.videoPreviewLayer.removeFromSuperlayer()  // Remove from any other views, if necessary.
        // If the new videoView isn't nil, set it up with the videoPreviewLayer.
        if let videoView = self.videoView {
            // The following scales the preview layer to be the view's current
            // size (i.e., the original size if called in viewDidLoad) but you
            // should probably also do this in viewDidLayoutSubviews.
            self.videoPreviewLayer.frame = videoView.layer.bounds
            videoView.layer.insertSublayer(self.videoPreviewLayer, atIndex: 0)  // Add the video layer behind everything.
        }
        // Layer position is set in viewDidLayoutSubviews to respond appropriately to layout constraints.
    }
    
    // Assuming the image passed is a face crop with the perspective of the
    // camera (i.e., as opposed to the mirrored version for viewing, but still
    // oriented so that the face is upright), "left eye" will refer to the
    // person's actual, physical, left eye and vice versa for the right eye.
    //
    // The CIImage input argument should be translated to the origin if the
    // CIDetector is used. Cropping in CoreImage simply blanks out the area
    // outside of the specified rectangle without changing the coordinates of
    // the cropped area, thus, detected faces (using CIDetector) would be
    // relative to the original image rather than the face crop. We desire the
    // latter.
    // Read more: http://stackoverflow.com/questions/9601242/cropping-ciimage-with-cicrop-isnt-working-properly
    //
    // This method operates in the CoreImage coordinate space, with the origin
    // at the bottom left. Using these results in UIKit will require flipping the
    // y-axis. This method should really only be used via this class's delegate.
    func findEyes(faceImage: CIImage) -> (leftEye: CGRect?, rightEye: CGRect?, leftEyeClosed: Bool?, rightEyeClosed: Bool?) {
        var leftEyeRect, rightEyeRect: CGRect
        var leftEyeClosed, rightEyeClosed: Bool?
        let faceRect = faceImage.extent
        
        switch selectedDetector {
        case .CIDetector:
            // Downscale the image for better performance.
            let newWidth = CGFloat(100)
            let scaleFactor = newWidth / faceRect.width
            let scaleFactorInverse = faceRect.width / newWidth
            
            let faceImageResized = faceImage.imageByApplyingTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
            let faceWidthResized = newWidth
            let faceHeightResized = faceRect.height * scaleFactor
            
            let features = self.eyeDetectorCI.featuresInImage(faceImageResized, options: [CIDetectorImageOrientation: NSNumber(integer: 0), CIDetectorEyeBlink: self.detectBlinks])  // Orientation of 0 because the cropped image has already been rotated.
            if features.count < 1 {
                if let debugView = self.debugView {
                    let debugImage = UIImage(CGImage: self.faceImageContext.createCGImage(faceImageResized, fromRect: faceImageResized.extent))
                    dispatch_async(dispatch_get_main_queue()) {
                        debugView.image = debugImage
                    }
                }
                return (nil, nil, nil, nil)
            } else {
                let bestFace = features[0] as! CIFaceFeature
                if !bestFace.hasLeftEyePosition || !bestFace.hasRightEyePosition {
                    if self.debugView != nil {
                        let debugImage = UIImage(CGImage: self.faceImageContext.createCGImage(faceImageResized, fromRect: faceImageResized.extent))
                        dispatch_async(dispatch_get_main_queue()) {
                            self.debugView!.image = debugImage
                        }
                    }
                    return (nil, nil, nil, nil)
                }
                
                // Decide how big the box surrounding each eye should be.
                // CIDetector only gives points, not boxes.
                let boxSize = faceWidthResized * 0.2
                let boxSizeHalf = boxSize / 2
                
                if let debugView = self.debugView {  // Optional binding is necessary here, as an external tap event could make the debugView nil after verifying that it's not nil.
                    // This could probably be drawn onto the context directly from the CIImage, though this is just for debugging.
                    var debugImage = UIImage(CGImage: self.faceImageContext.createCGImage(faceImageResized, fromRect: faceImageResized.extent))
                    // Draw the boxes directly onto the image.
                    UIGraphicsBeginImageContext(debugImage.size)
                    debugImage.drawAtPoint(CGPointZero)
                    let ctx = UIGraphicsGetCurrentContext()
                    UIColor.greenColor().setStroke()
                    // Left and right are swapped, as described below.
                    let leftEyeRectDebug = CGRect(
                        x: bestFace.rightEyePosition.x - boxSizeHalf,
                        y: faceHeightResized - (bestFace.rightEyePosition.y - boxSizeHalf) - boxSize,  // Flip y-axis for drawing in UIKit.
                        width: boxSize, height: boxSize)
                    let rightEyeRectDebug = CGRect(
                        x: bestFace.leftEyePosition.x - boxSizeHalf,
                        y: faceHeightResized - (bestFace.leftEyePosition.y - boxSizeHalf) - boxSize,
                        width: boxSize, height: boxSize)
                    CGContextStrokeRectWithWidth(ctx, leftEyeRectDebug, 1.0)
                    CGContextStrokeRectWithWidth(ctx, rightEyeRectDebug, 1.0)
                    debugImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    dispatch_async(dispatch_get_main_queue()) {
                        debugView.image = debugImage
                    }
                }

                if let rightEyeView = self.rightEyeView {  // Optional binding is necessary here, as an external tap event could make the debugView nil after verifying that it's not nil.
                    // This could probably be drawn onto the context directly from the CIImage, though this is just for debugging.
                    
                    let leftEyeRectDebug = CGRect(
                        x: bestFace.rightEyePosition.x - boxSizeHalf,
                        y: faceHeightResized - (bestFace.rightEyePosition.y - boxSizeHalf) - boxSize,  // Flip y-axis for drawing in UIKit.
                        width: boxSize, height: boxSize)
                    let rightEyeRectDebug = CGRect(
                        x: bestFace.leftEyePosition.x - boxSizeHalf,
                        y: faceHeightResized - (bestFace.leftEyePosition.y - boxSizeHalf) - boxSize,
                        width: boxSize, height: boxSize)
                    
                    var firstDebugImage = UIImage(CGImage: self.faceImageContext.createCGImage(faceImageResized, fromRect: faceImageResized.extent))
                    
                    // Create bitmap image from context using the rect
                    let imageRef: CGImageRef = CGImageCreateWithImageInRect(firstDebugImage.CGImage, rightEyeRectDebug)!
                    // Create a new image based on the imageRef and rotate back to the original orientation
                    var debugImage: UIImage = UIImage(CGImage: imageRef)
                    
                    
                    // Draw the boxes directly onto the image.
                    UIGraphicsBeginImageContext(debugImage.size)
                    debugImage.drawAtPoint(CGPointZero)
                    let ctx = UIGraphicsGetCurrentContext()
                    UIColor.greenColor().setStroke()
                    // Left and right are swapped, as described below.
                    CGContextStrokeRectWithWidth(ctx, leftEyeRectDebug, 1.0)
                    CGContextStrokeRectWithWidth(ctx, rightEyeRectDebug, 1.0)
                    debugImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    dispatch_async(dispatch_get_main_queue()) {
                        rightEyeView.image = debugImage
                    }
                }
                
                if let leftEyeView = self.leftEyeView {  // Optional binding is necessary here, as an external tap event could make the debugView nil after verifying that it's not nil.
                    // This could probably be drawn onto the context directly from the CIImage, though this is just for debugging.
                    
                    let leftEyeRectDebug = CGRect(
                        x: bestFace.rightEyePosition.x - boxSizeHalf,
                        y: faceHeightResized - (bestFace.rightEyePosition.y - boxSizeHalf) - boxSize,  // Flip y-axis for drawing in UIKit.
                        width: boxSize, height: boxSize)
//                    let rightEyeRectDebug = CGRect(
//                        x: bestFace.leftEyePosition.x - boxSizeHalf,
//                        y: faceHeightResized - (bestFace.leftEyePosition.y - boxSizeHalf) - boxSize,
//                        width: boxSize, height: boxSize)
                    
                    var firstDebugImage = UIImage(CGImage: self.faceImageContext.createCGImage(faceImageResized, fromRect: faceImageResized.extent))
                    
                    // Create bitmap image from context using the rect
                    let imageRef: CGImageRef = CGImageCreateWithImageInRect(firstDebugImage.CGImage, leftEyeRectDebug)!
                    // Create a new image based on the imageRef and rotate back to the original orientation
                    var debugImage: UIImage = UIImage(CGImage: imageRef)
                    
//                    print("HELLO")
//                    print(debugImage.size.height)
//                    print(debugImage.size.width)
                    
                    
                    // Draw the boxes directly onto the image.
                    //UIGraphicsBeginImageContext(debugImage.size)
                    //debugImage.drawAtPoint(CGPointZero)
                    //let ctx = UIGraphicsGetCurrentContext()
                    //UIColor.greenColor().setStroke()
                    // Left and right are swapped, as described below.
                    //CGContextStrokeRectWithWidth(ctx, leftEyeRectDebug, 1.0)
                    //CGContextStrokeRectWithWidth(ctx, rightEyeRectDebug, 1.0)
                    //debugImage = UIGraphicsGetImageFromCurrentImageContext()
                    //UIGraphicsEndImageContext()
                    dispatch_async(dispatch_get_main_queue()) {
                        leftEyeView.image = debugImage
                    }
                }
                
                
                // "'Right' is relative to the original (non-mirrored) image orientation, not to the owner of the eye."
                // From: https://developer.apple.com/library/prerelease/ios/documentation/CoreImage/Reference/CIFaceFeature/index.html#//apple_ref/occ/instp/CIFaceFeature/rightEyeClosed
                // In this project code, "right" refers to the owner right eye, so we need to swap them.
                leftEyeRect = CGRect(
                    x: (bestFace.rightEyePosition.x - boxSizeHalf) * scaleFactorInverse,
                    y: (bestFace.rightEyePosition.y - boxSizeHalf) * scaleFactorInverse,  // No need to flip the y-axis since we should return CoreImage coordinates.
                    width: boxSize * scaleFactorInverse, height: boxSize * scaleFactorInverse)
                rightEyeRect = CGRect(
                    x: (bestFace.leftEyePosition.x - boxSizeHalf) * scaleFactorInverse,
                    y: (bestFace.leftEyePosition.y - boxSizeHalf) * scaleFactorInverse,
                    width: boxSize * scaleFactorInverse, height: boxSize * scaleFactorInverse)
                if self.detectBlinks {
                    leftEyeClosed = bestFace.rightEyeClosed
                    rightEyeClosed = bestFace.leftEyeClosed
                }
            }
        case .OpenCV:
            let faceImageUI = UIImage(CGImage: self.faceImageContext.createCGImage(faceImage, fromRect: faceImage.extent))
            let eyesArray = self.eyeDetectorCV.detectAllEyes(faceImageUI)
            
            // If we can't find two eyes, don't return any.
            if eyesArray.count < 2 {
                return (nil, nil, nil, nil)
            }
            
            // We have two or more detections now. Choose the leftmost and
            // rightmost boxes, as those tend to be the correct ones. Unless all
            // of the detections have the same x value, they should be
            // different boxes.
            // TODO: Apply more heuristics to improve OpenCV detections.
            leftEyeRect = eyesArray.objectAtIndex(0).CGRectValue
            rightEyeRect = eyesArray.objectAtIndex(0).CGRectValue
            for index in 1..<eyesArray.count {
                let eyeRect = eyesArray.objectAtIndex(index).CGRectValue
                if eyeRect.origin.x < rightEyeRect.origin.x {
                    rightEyeRect = eyeRect
                }
                if eyeRect.origin.x > leftEyeRect.origin.x {
                    leftEyeRect = eyeRect
                }
            }
            // Coordinates were returned in cv::Mat coordinate space (same as
            // UIKit). Flip the y-axis to return to CIImage space.
            leftEyeRect = leftEyeRect.rectWithFlippedY(inFrame: faceRect)
            rightEyeRect = rightEyeRect.rectWithFlippedY(inFrame: faceRect)
            
            // NOTE: OpenCV does not detect blinks as it is now.
        }
        
        // Run the eye rectangles through the Kalman filter to smooth out
        // predictions.
        let leftEyePoint = self.enableTemporalSmoothing ? self.kalmanFilterLeft.processPoint(leftEyeRect.origin) : leftEyeRect.origin
        let rightEyePoint = self.enableTemporalSmoothing ? self.kalmanFilterRight.processPoint(rightEyeRect.origin) : rightEyeRect.origin
        leftEyeRect.origin = leftEyePoint
        rightEyeRect.origin = rightEyePoint
        
        setup()
        return (leftEyeRect, rightEyeRect, leftEyeClosed, rightEyeClosed)
    }

    func setup() {
        TestNtwkFile.testNtwkFile()
        
        redLayer.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
        redLayer.backgroundColor = UIColor.redColor().CGColor
        
        // Round corners
        redLayer.cornerRadius = circleRadius
        
        // Set border
        redLayer.borderColor = UIColor.blackColor().CGColor
        redLayer.borderWidth = 10
        
        redLayer.shadowColor = UIColor.blackColor().CGColor
        redLayer.shadowOpacity = 0.8
        redLayer.shadowOffset = CGSizeMake(2, 2)
        redLayer.shadowRadius = 3
        
        self.videoView!.layer.addSublayer(redLayer)
        
        
        // Create a blank animation using the keyPath "cornerRadius", the property we want to animate
        let animation = CABasicAnimation(keyPath: "shadowRadius")
        
        // Set the starting value
        animation.fromValue = redLayer.cornerRadius
        
        // Set the completion value
        animation.toValue = 0
        
        // How may times should the animation repeat?
        animation.repeatCount = 1000
        
        // Finally, add the animation to the layer
        redLayer.addAnimation(animation, forKey: "cornerRadius")
        
        circleTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("randomizeCirclePosition"), userInfo: nil, repeats: true)
    }
    
    func randomizeCirclePosition() {
        let minX = 0
        let maxX = 375
        let minY = 0
        let maxY = 667
        
        let preferredMinX = CGFloat(minX) + self.circleRadius * 2
        let preferredMaxX = CGFloat(maxX) - self.circleRadius * 2
        let preferredMinY = CGFloat(minY) + self.circleRadius * 2
        let preferredMaxY = CGFloat(maxY) - self.circleRadius * 2
        
        let randomX = CGFloat(arc4random_uniform(UInt32(preferredMaxX - preferredMinX))) + preferredMinX
        let randomY = CGFloat(arc4random_uniform(UInt32(preferredMaxY - preferredMinY))) + preferredMinY
        
        let point = CGPoint(x: randomX, y: randomY)
        self.redLayer.animateToPosition(point)
    }
    
    // TODO: Provide a concrete example in the documentation.
    /// Determine where the video preview is positioned within its view. This
    /// enables one to account for scale and clipping of the video preview, so
    /// image coordinates can be converted into display coordinates.
    ///
    /// This method was adapted from Apple's SquareCam demo. If raw frame data
    /// should be used instead (as is done in SquareCam's original code),
    /// imageSize's width and height should be flipped.
    ///
    /// - parameter gravity:   The gravity setting of the preview layer. This
    ///                   determines how the video is positioned.
    /// - parameter viewSize:  The size of the view in which the video preview is
    ///                   displayed.
    /// - parameter imageSize: The size of the oriented video data (which is
    ///                   displayed on the preview layer).
    ///
    /// - returns: A CGRect describing the position and size of the video
    ///           preview.
    static func videoPreviewBoxForGravity(gravity: String, viewSize: CGSize, imageSize: CGSize) -> CGRect {
        let imageRatio = imageSize.width / imageSize.height
        let viewRatio = viewSize.width / viewSize.height
        
        var size = CGSizeZero
        // TODO: Test this method for all gravities. Currently, only the top one has been tested.
        if gravity == AVLayerVideoGravityResizeAspectFill {
            if viewRatio > imageRatio {
                size.width = viewSize.width
                size.height = imageSize.height * (viewSize.width / imageSize.width)
            } else {
                size.width = imageSize.width * (viewSize.height / imageSize.height)
                size.height = viewSize.height
            }
        } else if gravity == AVLayerVideoGravityResizeAspect {
            if viewRatio > imageRatio {
                size.width = imageSize.width * (viewSize.height / imageSize.height)
                size.height = viewSize.height
            } else {
                size.width = viewSize.width
                size.height = imageSize.height * (viewSize.width / imageSize.width)
            }
        } else if gravity == AVLayerVideoGravityResize {
            size.width = viewSize.width
            size.height = viewSize.height
        }
        
        var videoPreviewBox = CGRect()
        videoPreviewBox.size = size
        if size.width < viewSize.width {
            videoPreviewBox.origin.x = (viewSize.width - size.width) / 2
        } else {
            videoPreviewBox.origin.x = (size.width - viewSize.width) / 2
        }
        
        if size.height < viewSize.height {
            videoPreviewBox.origin.y = (viewSize.height - size.height) / 2
        } else {
            videoPreviewBox.origin.y = (size.height - viewSize.height) / 2
        }
        
        return videoPreviewBox
    }
    
}
