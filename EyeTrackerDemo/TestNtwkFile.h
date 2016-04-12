//
//  Header.h
//  EyeTrackerDemo
//
//  Created by Harini Kannan on 3/11/16.
//  Copyright © 2016 Harini Kannan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeepBelief/DeepBelief.h>
#import <UIKit/UIKit.h>

#ifndef Header_h
#define Header_h

@interface TestNtwkFile : NSObject

+ (CGPoint)testNtwkFile: (NSArray*)faceGrid firstImage:(UIImage*) leftEye secondImage:(UIImage*) rightEye thirdImage:(UIImage*) face;
@end
#endif /* Header_h */

