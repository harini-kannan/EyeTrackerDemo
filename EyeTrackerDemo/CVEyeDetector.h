//
//  CVEyeDetector.h
//  iTracker
//
//  Created by Kyle Krafka on 5/15/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

#ifndef iTracker_CVEyeDetector_h
#define iTracker_CVEyeDetector_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CVEyeDetector : NSObject

// Initialize the eye detector with an XML file describing what an eye looks
// like. Recommended: "haarcascade_eye.xml" that comes with OpenCV.
- (id)initWithCascadeFilename:(NSString *)cascadeFilename;

// Return an array of bounding boxes around all detected eyes. Ideally, there
// will be only two bounding boxes, but we leave it up to the caller to
// determine what to make of poor results.
- (NSMutableArray *)detectAllEyes:(UIImage *)image;


// Pass in a UIImageView to display the cv::Mat image (and detections
// rectangles) on the screen. Pass in nil to disable.
- (void)setDebugView:(UIImageView *)debugView;

@end

#endif
