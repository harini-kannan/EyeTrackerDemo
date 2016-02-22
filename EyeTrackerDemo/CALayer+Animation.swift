//
//  CALayer+Animation.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/31/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import Foundation
import UIKit

/// Convenience functions to animate `CALayers`.
extension CALayer {
    func animateToPosition(newPosition: CGPoint) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = self.valueForKey("position")
        animation.toValue = NSValue(CGPoint: newPosition)
        self.position = newPosition
        self.addAnimation(animation, forKey: "position")
    }
}