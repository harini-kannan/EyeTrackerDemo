//
//  FPSQueue.swift
//  iTracker
//
//  Created by Kyle Krafka on 5/5/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

import Foundation

/// Keep track of frames per second measure by storing timestamps of recent
/// frames. The `rate` variable returns the exact number of frames displayed in
/// the last second. `countFrame()` must be called on each frame.
class FPSQueue {
    private var queue: [NSDate] = []  // Times of frames ordered from oldest to newest.
    var rate: Int {
        // Synchronize on this object since we will be accessing it from
        // multiple threads (countFrame() on a custom queue and rate on the main
        // queue to display in the UI).
        objc_sync_enter(self)
        let now = NSDate()
        // Remove all times older than a second.
        while (!queue.isEmpty && queue.first!.timeIntervalSince1970 < now.timeIntervalSince1970 - 1.0) {
            queue.removeAtIndex(0)
        }
        objc_sync_exit(self)
        
        return queue.count
    }
    
    func countFrame() {
        objc_sync_enter(self)
        let now = NSDate()
        queue.append(now)
        objc_sync_exit(self)
    }
}