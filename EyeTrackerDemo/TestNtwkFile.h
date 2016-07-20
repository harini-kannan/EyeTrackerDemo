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
- (CGPoint)runNeuralNetwork: (NSArray*)faceGrid firstImage:(UIImage*) leftEye secondImage:(UIImage*) rightEye thirdImage:(UIImage*) face;
- (void) populateInput: (NSArray*)faceGrid firstImage:(UIImage*) leftEye secondImage:(UIImage*) rightEye thirdImage:(UIImage*) face;
- (float*) classifyNtwk: (int)inputSize a:(void*) inputImage b:(NSString*) ntwkFileName c:(NSString*) directory;
@end
#endif /* Header_h */

