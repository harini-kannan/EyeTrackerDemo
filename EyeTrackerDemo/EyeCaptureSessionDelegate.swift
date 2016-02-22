//
//  EyeCaptureSessionDelegate.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/24/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import Foundation

/// Defines the tasks that one can implement in response to events in an
/// `EyeCaptureSession` object.
protocol EyeCaptureSessionDelegate {
    func processFace(ff: FaceFrame)
    // TODO: Add dropped frame method.
}