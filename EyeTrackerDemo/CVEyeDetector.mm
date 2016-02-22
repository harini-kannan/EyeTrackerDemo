//
//  CVEyeDetector.mm
//  iTracker
//
//  Created by Kyle Krafka on 5/15/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

// Useful link: http://www.objc.io/issue-21/face-recognition-with-opencv.html

// This is implemented using OpenCV's cv::CascadeClassifier. A more robust
// alternative would be CLandmark (https://github.com/uricamic/clandmark)
// although I doubt it would be as fast.

#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/highgui/highgui.hpp>

#include <memory>

#import "CVEyeDetector.h"
#import "UIImage+OpenCV.h"

@implementation CVEyeDetector {
    std::unique_ptr<cv::CascadeClassifier> _eyeCascade;  // Smart pointer used due to no initializer lists.
    UIImageView *_debugView;
}

- (id)initWithCascadeFilename:(NSString *)cascadeFilename {
    self = [super init];
    if (self) {
        _eyeCascade.reset(new cv::CascadeClassifier());
        _eyeCascade->load(cascadeFilename.UTF8String);
        _debugView = nil;
    }
    return self;
}

// This method operates in the UIKit/cv::Mat coordinate space where the origin
// is at the top left.
- (NSMutableArray *)detectAllEyes:(UIImage *)image {
    if (!_eyeCascade) {
        NSLog(@"cv::CascadeClassifier (the eye detector) has not been instantiated. Did you use initWithCascadeFilename? Returning nil.");
        return nil;
    }
    
    if (_eyeCascade->empty()) {
        NSLog(@"The cascade file was not loaded in successfully. Returning nil.");
        return nil;
    }
    
    if (!image) {
        NSLog(@"No image was passed in. Returning nil.");
        return nil;
    }

    if (!image.CGImage) {
        NSLog(@"The CGImage inside the UIImage is nil. This could happen if you used UIImage's imageWithCIImage instead of using a CIContext to render the CGImage first. Returning nil.");
        return nil;
    }
    
    CGFloat faceWidth = image.size.width;
    CGFloat faceHeight = image.size.height;
    
    // TODO: Does grayscale speed this up? Also, can we eliminate the thin black borders on some frames?
    cv::Mat matImage = [image CVGrayscaleMat];
    
    // Optional: Rotate the input image 90° if this is not done outside. If you
    // do this, you will also need to swap faceWidth and faceHeight, above.
    // cv::transpose(matImage, matImage);
    // cv::flip(matImage, matImage, 1);
    
    // Resize for better performance and consistency between face sizes.
    // Set the width, then choose the height to maintain the aspect ratio.
    // TODO: Do this earlier on, outside of this function.
    // TODO: Only downsample.
    int newWidth = 100;  // Set this to choose the new width.
    CGFloat scaleFactor = newWidth / faceWidth;
    CGFloat scaleFactorInverse = faceWidth / newWidth;  // This is used to scale up the eye boxes at the end.
    faceHeight = faceHeight * scaleFactor;
    faceWidth = newWidth;  // I.e., faceWidth * scaleFactor
    cv::Size newSize(faceWidth, faceHeight);
    cv::Mat matImageResized;
    resize(matImage, matImageResized, newSize);
    
    // No need to consider the bottom half or the very top of the face, so we
    // crop it off, but we keep track of the y offset to correct the coordinates
    // to be relative to the face at the end.
    CGFloat faceYOffset = faceHeight * 0.1;
    cv::Rect eyeRegion(0, faceYOffset, faceWidth, faceHeight * 0.5);
    cv::Mat matImageCropped = matImageResized(eyeRegion);
    
    std::vector<cv::Rect> eyes;
    // The following percentages are based on actual percentages given no restrictions.
    cv::Size minEyeSize(faceWidth * 0.20, faceHeight * 0.20);
    cv::Size maxEyeSize(faceWidth * 0.34, faceHeight * 0.34);
    _eyeCascade->detectMultiScale(matImageCropped,
                                 eyes,
                                 1.1,
                                 2,
                                 CV_HAAR_SCALE_IMAGE/*|CV_HAAR_DO_ROUGH_SEARCH|CV_HAAR_FIND_BIGGEST_OBJECT*/,
                                 minEyeSize,
                                 maxEyeSize);

    if (_debugView) {
        // NSLog(@"Num eyes: %lu", eyes.size());
        for (auto &eye : eyes) {
            // Print out the proportions of the eye boxes.
            // NSLog(@"%f %f", eye.width / faceWidth, eye.height / faceHeight);
            rectangle(matImageCropped, eye, cv::Scalar(0, 255, 0), 1);
        }
        UIImage *debugImage = [UIImage imageWithCVMat:matImageCropped];
        // In case this function is not run on the main thread already, ensure
        // that the UI is updated on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            _debugView.image = debugImage;
        });
    }
    
    NSMutableArray *eyeArray = [[NSMutableArray alloc] init];
    for (auto &eye : eyes) {
        // Account for the fact that the image was scaled down and cropped here
        // in this method.
        CGRect anEye = CGRectMake(eye.x * scaleFactorInverse,
                                  (eye.y + faceYOffset) * scaleFactorInverse,
                                  eye.width * scaleFactorInverse,
                                  eye.height * scaleFactorInverse);
        
        // Another option for debugging to verify the scaled output coordinates.
//        if (_debugView) {
//            cv::Rect anEyeCV(anEye.origin.x, anEye.origin.y, anEye.size.width, anEye.size.height);
//            rectangle(matImage, anEyeCV, cv::Scalar(0, 255, 0), 1);
//            UIImage *debugImage = [UIImage imageWithCVMat:matImage];
//            // In case this function is not run on the main thread already, ensure
//            // that the UI is updated on the main thread.
//            dispatch_async(dispatch_get_main_queue(), ^{
//                _debugView.image = debugImage;
//            });
//        }
        
        [eyeArray addObject:[NSValue valueWithCGRect:anEye]];
    }

    return eyeArray;
}

- (void)setDebugView:(UIImageView *)debugView {
    _debugView = debugView;
}

@end
