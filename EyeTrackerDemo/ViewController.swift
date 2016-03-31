//
//  ViewController.swift
//  EyeTrackerDemo
//
//  Created by Harini Kannan on 2/18/16.
//  Copyright © 2016 Harini Kannan. All rights reserved.
//

///Users/harini/EyeTrackerDemo/EyeTrackerDemo/ViewController.swift
//  CameraViewController.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/4/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import CoreGraphics
import CoreImage
import Foundation
import UIKit

/// Implements the view that shows camera output with boxes around the face and
/// eyes as well as an optional debug view to see the raw output of the eye
/// detectors.
class ViewController: UIViewController, EyeCaptureSessionDelegate {
    
    // MARK: Outlets.
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var debugView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var detectorSegmentedControl: UISegmentedControl!
    @IBOutlet weak var rightEyeView: UIImageView!
    @IBOutlet weak var leftEyeView: UIImageView!
    // Boxes to display the most confident face.
    var faceLayer = CALayer()
    var leftEyeLayer = CALayer()
    var rightEyeLayer = CALayer()
    // Hide the boxes if they haven't been updated (i.e., their timer hasn't
    // been reset) recently enough.
    var faceTimeout: NSTimer?
    var leftEyeTimeout: NSTimer?
    var rightEyeTimeout: NSTimer?
    let timeoutLength = 0.2  // Number of seconds to leave a box on the screen after it's displayed.
    
    // Properties that will be initialized in viewDidLoad.
    var eyeCaptureSession: EyeCaptureSession!
    var statusTimer: NSTimer!

    var circleTimer: NSTimer?
    let redLayer = CALayer()
    let circleRadius = CGFloat(25)
    
    // From: http://iosdevcenters.blogspot.com/2015/12/how-to-resize-image-in-swift-in-ios.html
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, targetSize.width, targetSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - EyeCaptureSessionDelegate Methods
    func processFace(ff: FaceFrame) {
        if leftEyeView.image != nil && rightEyeView.image != nil && debugView.image != nil{
            print ("PRINTING WIDTH")
            let size = CGSize(width: 219, height: 219)
            let resizedLeftEye = resizeImage(leftEyeView.image!, targetSize: size)
            let resizedRightEye = resizeImage(rightEyeView.image!, targetSize: size)
            let resizedFace = resizeImage(debugView.image!, targetSize: size)
            print(leftEyeView.image!.size, resizedLeftEye.size)
            print(rightEyeView.image!.size, resizedRightEye.size)
            print(debugView.image!.size, resizedFace.size)
        }
//        randomizeCirclePosition()
//        circleTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("randomizeCirclePosition"), userInfo: nil, repeats: true)
        if ff.faceCrop != nil && ff.faceRect != nil && ff.fullFrameSize != nil {
            if let videoPreviewLayer = self.eyeCaptureSession?.videoPreviewLayer {
                var faceRectDisp = ff.faceRect!
                
                faceRectDisp = faceRectDisp
                    .rectWithFlippedX(inFrame: ff.fullFrameSize!)  // TODO: Only do this if videoPreviewLayer.isMirrored
                
                // Orientation is corrected according to the device position in
                // EyeCaptureSession, but we don't rotate the UI here. This is
                // common in apps that actually display the camera, since
                // there's no need to rotate the main UI element (i.e., the
                // camera view. See the built-in Camera app (or really any
                // camera's UI) for an example.
                //
                // However, since the bounding box coordinates are relative to
                // the potentially-rotated raw image (so the head will be
                // upright and coordinates will be correct for that image), we
                // will un-rotate them here.
                
                // Rotate the frame so it's in portrait orientation (if it's not
                // already).
                var fullFrameSizePortrait = CGSize()
                if ff.deviceOrientation.isLandscape {
                    fullFrameSizePortrait = CGSize(width: ff.fullFrameSize!.height, height: ff.fullFrameSize!.width)
                } else {
                    // Could be portrait, portrait upside down, flat, or
                    // unknown. Regardless, we'll leave it as is.
                    fullFrameSizePortrait = ff.fullFrameSize!
                }
                // Now, update the coordinates of the face rect, in case the
                // frame was rotated.
                switch ff.deviceOrientation {
                case .Portrait:
                    // Do nothing.
                    break
                case .LandscapeLeft:
                    faceRectDisp = faceRectDisp
                        .rectRotatedRight(inSourceFrame: ff.fullFrameSize!)
                case .LandscapeRight:
                    faceRectDisp = faceRectDisp
                        .rectRotatedLeft(inSourceFrame: ff.fullFrameSize!)
                case .PortraitUpsideDown:
                    faceRectDisp = faceRectDisp
                        .rectRotated180(inSourceFrame: ff.fullFrameSize!)
                default:
                    fatalError("Unsupported orientation when displaying eye boxes.")
                }
                
                
                // The box in which the preview will show.
                // TODO: No need to recompute this every time.
                // TODO: Move this code to EyeCaptureSession since it owns the video
                //       preview layer.
                let videoPreviewBox = EyeCaptureSession.videoPreviewBoxForGravity(
                    videoPreviewLayer.videoGravity,
                    viewSize: videoView.frame.size, imageSize: fullFrameSizePortrait)
                let scaleFactor = videoPreviewBox.width / fullFrameSizePortrait.width  // Could do height separately, but there are bigger problems if they're not the same scale.
                faceRectDisp = CGRectOffset(faceRectDisp, -videoPreviewBox.origin.x, -videoPreviewBox.origin.y)  // These values were positive in Apple's SquareCam demo code.
                faceRectDisp = faceRectDisp.rectScaled(byFactor: scaleFactor)
                var leftEyeDisp, rightEyeDisp: CGRect?
                
                if let aLeftEye = ff.leftEye, aRightEye = ff.rightEye {
                    // Mirror for display. Coordinates are already in UIKit space.
                    // TODO: Move the scaling stuff to the display method as well?
                    leftEyeDisp = aLeftEye
                        .rectScaled(byFactor: scaleFactor)
                        .rectWithFlippedX(inFrame: faceRectDisp)
                    rightEyeDisp = aRightEye
                        .rectScaled(byFactor: scaleFactor)
                        .rectWithFlippedX(inFrame: faceRectDisp)
                    switch ff.deviceOrientation {
                    case .Portrait:
                        // Do nothing.
                        break
                    case .LandscapeLeft:
                        leftEyeDisp = leftEyeDisp!
                            .rectRotatedRight(inSourceFrame: faceRectDisp)
                        rightEyeDisp = leftEyeDisp!
                            .rectRotatedRight(inSourceFrame: faceRectDisp)
                    case .LandscapeRight:
                        leftEyeDisp = leftEyeDisp!
                            .rectRotatedLeft(inSourceFrame: faceRectDisp)
                        rightEyeDisp = rightEyeDisp!
                            .rectRotatedLeft(inSourceFrame: faceRectDisp)
                    case .PortraitUpsideDown:
                        leftEyeDisp = leftEyeDisp!
                            .rectRotated180(inSourceFrame: faceRectDisp)
                        rightEyeDisp = rightEyeDisp!
                            .rectRotated180(inSourceFrame: faceRectDisp)
                    default:
                        fatalError("Unsupported orientation when displaying eye boxes.")
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.drawBoxesForFace(faceRectDisp, faceYaw: ff.faceYaw,
                        faceRoll: ff.faceRoll, leftEye: leftEyeDisp,
                        leftEyeClosed: ff.leftEyeClosed, rightEye: rightEyeDisp,
                        rightEyeClosed: ff.rightEyeClosed)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func updateStatus() {
        statusLabel.text = "FPS: \(self.eyeCaptureSession.frameFPS)  Detection: \(self.eyeCaptureSession.lastDetectionDuration) ms"
    }
    
    // Draw three CGRects to the screen to display the eye detections. This must
    // be run on the main thread. All input values should be in the UIKit
    // coordinate space, with the origin at the top left.
    func drawBoxesForFace(face: CGRect, faceYaw: CGFloat?, faceRoll: CGFloat?,
        leftEye: CGRect?, leftEyeClosed: Bool?,
        rightEye: CGRect?, rightEyeClosed: Bool?) {
            CATransaction.begin()
            
            // Disable animations if the face layer was hidden. This is especially
            // good at the beginning to prevent black boxes from sliding out from
            // the origin. Alternatively, opacity alone could be animated.
            if faceLayer.hidden {
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            }
            
            // Display a red box if the user is not looking directly at the camera.
            // Practically this only accepts values of 0.0 since yaw is currently
            // measured in increments of 45° and roll in increments of 30°.
            if (faceYaw < 45.0 || faceYaw > 315.0) && (faceRoll < 30.0 || faceRoll > 330.0) {
                self.faceLayer.borderColor = UIColor.greenColor().CGColor
            } else {
                self.faceLayer.borderColor = UIColor.redColor().CGColor
            }
            
            if leftEyeClosed == true {  // Explicitly testing == true also checks for nil appropriately.
                self.leftEyeLayer.borderColor = UIColor.redColor().CGColor
            } else {
                self.leftEyeLayer.borderColor = UIColor.greenColor().CGColor
            }
            
            if rightEyeClosed == true {
                self.rightEyeLayer.borderColor = UIColor.redColor().CGColor
            } else {
                self.rightEyeLayer.borderColor = UIColor.greenColor().CGColor
            }
            
            self.faceLayer.hidden = false  // In case the box was hidden before, make sure it isn't now.
            self.faceLayer.frame = face   // Position the box.
            // Reset the timer so that the box disappears if not updated soon enough.
            if let oldFaceTimeout = self.faceTimeout {
                oldFaceTimeout.invalidate()
            }
            faceTimeout = NSTimer.scheduledTimerWithTimeInterval(self.timeoutLength, target: self, selector: Selector("hideFaceBox"), userInfo: nil, repeats: false)
            
            if let aLeftEye = leftEye {
                self.leftEyeLayer.hidden = false
                self.leftEyeLayer.frame = aLeftEye
                if let oldLeftEyeTimeout = self.leftEyeTimeout {
                    oldLeftEyeTimeout.invalidate()
                }
                leftEyeTimeout = NSTimer.scheduledTimerWithTimeInterval(self.timeoutLength, target: self, selector: Selector("hideLeftEyeBox"), userInfo: nil, repeats: false)
            }
            
            if let aRightEye = rightEye {
                self.rightEyeLayer.hidden = false
                self.rightEyeLayer.frame = aRightEye
                if let oldRightEyeTimeout = self.rightEyeTimeout {
                    oldRightEyeTimeout.invalidate()
                }
                rightEyeTimeout = NSTimer.scheduledTimerWithTimeInterval(self.timeoutLength, target: self, selector: Selector("hideRightEyeBox"), userInfo: nil, repeats: false)
            }
            CATransaction.commit()  // Done batching the UI updates together.
    }
    
    func hideFaceBox() {
        self.faceLayer.hidden = true
        faceTimeout = nil
    }
    
    func hideLeftEyeBox() {
        self.leftEyeLayer.hidden = true
        leftEyeTimeout = nil
    }
    
    func hideRightEyeBox() {
        self.rightEyeLayer.hidden = true
        rightEyeTimeout = nil
    }
    
    // MARK: Actions
    
    @IBAction func didChangeDetector(sender: AnyObject) {
        switch self.detectorSegmentedControl.selectedSegmentIndex {
        case 0:
            self.eyeCaptureSession.selectedDetector = .CIDetector
        case 1:
            self.eyeCaptureSession.selectedDetector = .OpenCV
        default:
            print("Warning: Unrecognized index from detectorSegmentedControl. Defaulting to CIDetector.")
            self.eyeCaptureSession.selectedDetector = .CIDetector
        }
    }
    
    @IBAction func didTapVideoView(sender: AnyObject) {
        if self.eyeCaptureSession.debugView != nil {
            self.eyeCaptureSession.debugView = nil
            self.debugView.hidden = true
            setup()
            print(self.leftEyeView.image!.size.height)
        } else {
            self.eyeCaptureSession.debugView = self.debugView
            self.debugView.hidden = false
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.eyeCaptureSession.debugView = self.debugView
        self.debugView.hidden = false
        faceLayer.borderWidth = 5
        leftEyeLayer.borderWidth = 3
        rightEyeLayer.borderWidth = 3
        faceLayer.hidden = true
        leftEyeLayer.hidden = true
        rightEyeLayer.hidden = true
        videoView.layer.masksToBounds = true  // VERIFY: Should not be necessary, but prevent boxes from ever being drawn outside of the video layer.
        
        videoView.layer.insertSublayer(faceLayer, atIndex: 0)
        // Eye boxes will be relative to the face.
        faceLayer.addSublayer(leftEyeLayer)
        faceLayer.addSublayer(rightEyeLayer)

        setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        eyeCaptureSession = EyeCaptureSession(delegate: self, videoView: videoView, debugView: self.debugView, rightEyeView: self.rightEyeView, leftEyeView: self.leftEyeView)  // This will add the video layer to the very back, behind the face/eye boxes.
        
        // This default is set when declaring the variable, but we set it from
        // the segmented controller here just in case.
        didChangeDetector(self.detectorSegmentedControl)
        statusTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("updateStatus"), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        eyeCaptureSession = nil
        statusTimer.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Scale the video output to the screen size.
        if let videoPreviewLayer = eyeCaptureSession?.videoPreviewLayer {  // We use ? because this function may be called after viewWillDisappear() is called.
            videoPreviewLayer.frame = videoView.layer.bounds
            videoPreviewLayer.position = CGPoint(x: videoView.layer.bounds.midX, y: videoView.layer.bounds.midY)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        self.videoView.layer.addSublayer(redLayer)
        
        
        // Create a blank animation using the keyPath "cornerRadius", the property we want to animate
//        let animation = CABasicAnimation(keyPath: "shadowRadius")
//        
//        // Set the starting value
//        animation.fromValue = redLayer.cornerRadius
//        
//        // Set the completion value
//        animation.toValue = 0
//        
//        // How may times should the animation repeat?
//        animation.repeatCount = 1000
//        
//        // Finally, add the animation to the layer
//        redLayer.addAnimation(animation, forKey: "cornerRadius")
        
//        randomizeCirclePosition()
//        randomizeCirclePosition()
//        randomizeCirclePosition()
//        circleTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("randomizeCirclePosition"), userInfo: nil, repeats: true)
    }
    
    func randomizeCirclePosition() {
        let preferredMinX = self.view.bounds.minX + self.circleRadius * 2
        let preferredMaxX = self.view.bounds.maxX - self.circleRadius * 2
        let preferredMinY = self.view.bounds.minY + self.circleRadius * 2
        let preferredMaxY = self.view.bounds.maxY - self.circleRadius * 2
        
        let randomX = CGFloat(arc4random_uniform(UInt32(preferredMaxX - preferredMinX))) + preferredMinX
        let randomY = CGFloat(arc4random_uniform(UInt32(preferredMaxY - preferredMinY))) + preferredMinY
        
        let point = CGPoint(x: randomX, y: randomY)
        
        var toPoint: CGPoint = CGPointMake(randomX, randomY)
        
        print (toPoint.x, toPoint.y, redLayer.position, redLayer.cornerRadius)
        self.redLayer.position = toPoint
        
//        var fromPoint : CGPoint = CGPointZero
//        
//        var movement = CABasicAnimation(keyPath: "movement")
////        movement.additive = true
////        movement.fromValue =  NSValue(CGPoint: self.redLayer.position)
//        movement.toValue =  NSValue(CGPoint: toPoint)
//        movement.duration = 0.3
//        
//        self.redLayer.addAnimation(movement, forKey: "position")
        
//        self.redLayer.animateToPosition(point)
    }
}


