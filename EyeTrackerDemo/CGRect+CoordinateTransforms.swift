//
//  CGRect+CoordinateTransforms.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/25/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import Foundation
import UIKit

/// Convenience functions to accomplish simple coordinate space transforms with
/// logical names. This should make other code easier to read.
extension CGRect {
    // Flip the x-axis. Useful for switching between image data and display
    // (which is mirrored).
    func rectWithFlippedX(inFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: frame.width - (self.origin.x + self.size.width),
            y: self.origin.y,
            width: self.size.width,
            height: self.size.height)
    }
    
    func rectWithFlippedX(inFrame frame: CGRect) -> CGRect {
        return self.rectWithFlippedX(inFrame: frame.size)
    }
    
    // Flip the y-axis. Useful for converting from CI to UI or vice versa.
    func rectWithFlippedY(inFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x,
            y: frame.height - (self.origin.y + self.size.height),
            width: self.size.width,
            height: self.size.height)
    }
    
    func rectWithFlippedY(inFrame frame: CGRect) -> CGRect {
        return self.rectWithFlippedY(inFrame: frame.size)
    }
    
    func rectScaled(byFactor factor: CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x * factor,
            y: self.origin.y * factor,
            width: self.size.width * factor,
            height: self.size.height * factor)
    }
    
    // Rotate a rect 90° clockwise its frame. I.e., given a rect inside a frame,
    // what will its coordinates be if you rotate the source frame 90° to the
    // right?
    func rectRotatedRight(inSourceFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: frame.height - (self.origin.y + self.height),
            y: self.origin.x,
            width: self.height,
            height: self.width)
    }
    
    func rectRotatedRight(inSourceFrame frame: CGRect) -> CGRect {
        return self.rectRotatedRight(inSourceFrame: frame.size)
    }
    
    // Rotate left 90°.
    func rectRotatedLeft(inSourceFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.y,
            y: frame.width - (self.origin.x + self.width),
            width: self.height,
            height: self.width)
    }
    
    func rectRotatedLeft(inSourceFrame frame: CGRect) -> CGRect {
        return self.rectRotatedLeft(inSourceFrame: frame.size)
    }
    
    // Rotate 180°.
    func rectRotated180(inSourceFrame frame: CGSize) -> CGRect {
        return CGRect(
            x: frame.width - (self.origin.x + self.width),
            y: frame.height - (self.origin.y + self.height),
            width: self.width,
            height: self.height)
    }
    
    func rectRotated180(inSourceFrame frame: CGRect) -> CGRect {
        return self.rectRotated180(inSourceFrame: frame.size)
    }
}
