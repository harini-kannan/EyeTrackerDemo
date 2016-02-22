//
//  KalmanFilter.h
//  iTracker
//
//  Created by Kyle Krafka on 6/7/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

#ifndef iTracker_KalmanFilter_h
#define iTracker_KalmanFilter_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface KalmanFilter : NSObject

/// Initialize the filter.
- (id)init;

/// Given a point, give the corrected point.
- (CGPoint)processPoint:(CGPoint)point;

@end

#endif