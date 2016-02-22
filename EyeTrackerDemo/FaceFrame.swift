//
//  FaceFrame.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/29/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

// TODO: Remove @objc and debugQuickLookObject() once everything works.

/// Describes a frame from an eye tracking session with a date/time, face image,
/// coordinates of everything, and some additional info. This class is designed
/// to be processed by `EyeCaptureSessionDelegate` and potentially collected by
/// the `EyeRecording` class.
///
/// "Left," "right," "yaw," and "roll" are all relative to the person's
/// perspective, not the camera's. Coordinates are in UIKit coordinates (origin
/// at the top left; flipped y-axis from CoreImage coordinates). Originally,
/// a CoreImage object was stored (with coordinates in CoreImage coordinates)
/// but the image data was getting overwritten.
class FaceFrame {
    var time: NSDate
    var faceCrop: UIImage?  // Could be computed from fullFrame and faceRect.
    var fullFrame: UIImage?
    var fullFrameSize: CGSize?  // The dimensions of the raw (but orientation-corrected) video data.
    var faceRect: CGRect?
    var faceYaw: CGFloat?  // Measured in degrees.
    var faceRoll: CGFloat?
    var leftEye: CGRect?
    var rightEye: CGRect?
    var leftEyeClosed: Bool?
    var rightEyeClosed: Bool?
    var deviceOrientation: UIDeviceOrientation
    
    /// Crop the person's left eye out. This does not translate the eye image to
    /// the origin.
    var leftEyeCrop: UIImage? {
        if self.leftEye != nil {
            let imageRef = CGImageCreateWithImageInRect(self.faceCrop!.CGImage, self.leftEye!)!
            return UIImage(CGImage: imageRef)
        } else {
            return nil
        }
    }
    /// Crop the person's right eye out. This does not translate the eye image
    /// to the origin.
    var rightEyeCrop: UIImage? {
        if self.rightEye != nil {
            let imageRef = CGImageCreateWithImageInRect(self.faceCrop!.CGImage, self.rightEye!)!  // Mirror since this is a UIImage.
            return UIImage(CGImage: imageRef)
        } else {
            return nil
        }
    }
    
    // Uses current time and leaves everything else as nil (or some default) to
    // be set later. Ideally, don't use this so that calls to init will break if
    // new properties are added.
    init() {
        time = NSDate()
        deviceOrientation = UIDeviceOrientation.Unknown
    }
    
    // Uses current time.
    convenience init(faceCrop: UIImage?, faceRect: CGRect?, faceYaw: CGFloat?,
        faceRoll: CGFloat?, fullFrame: UIImage?, fullFrameSize: CGSize?,
        leftEye: CGRect?, rightEye: CGRect?, leftEyeClosed: Bool?,
        rightEyeClosed: Bool?, deviceOrientation: UIDeviceOrientation) {
            self.init(time: NSDate(), faceCrop: faceCrop, faceRect: faceRect,
                faceYaw: faceYaw, faceRoll: faceRoll, fullFrame: fullFrame,
                fullFrameSize: fullFrameSize, leftEye: leftEye,
                rightEye: rightEye, leftEyeClosed: leftEyeClosed,
                rightEyeClosed: rightEyeClosed,
                deviceOrientation: deviceOrientation)
    }
    
    init(time: NSDate, faceCrop: UIImage?, faceRect: CGRect?, faceYaw: CGFloat?,
        faceRoll: CGFloat?, fullFrame: UIImage?, fullFrameSize: CGSize?,
        leftEye: CGRect?, rightEye: CGRect?, leftEyeClosed: Bool?,
        rightEyeClosed: Bool?, deviceOrientation: UIDeviceOrientation) {
            self.time = time
            self.faceCrop = faceCrop
            self.faceRect = faceRect
            self.faceYaw = faceYaw
            self.faceRoll = faceRoll
            self.fullFrame = fullFrame
            self.fullFrameSize = fullFrameSize
            self.leftEye = leftEye
            self.rightEye = rightEye
            self.leftEyeClosed = leftEyeClosed
            self.rightEyeClosed = rightEyeClosed
            self.deviceOrientation = deviceOrientation
    }
    
    func debugQuickLookObject() -> AnyObject? {
        return rightEyeCrop
    }
    
    func bothEyesOpened() -> Bool {
        if (leftEyeClosed != nil && leftEyeClosed!) {
            return false;
        }
        if (rightEyeClosed != nil && rightEyeClosed!) {
            return false;
        }
        return true;
    }
    
    var uploadSizeBytes: Int {
        var sum = 0;
        if let faceImg = faceCrop {
            sum += CGImageGetHeight(faceImg.CGImage) * CGImageGetBytesPerRow(faceImg.CGImage);
        }
        return sum;
    }
}