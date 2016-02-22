//
//  KalmanFilter.mm
//  iTracker
//
//  Created by Kyle Krafka on 6/7/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

// Based on: http://www.morethantechnical.com/2011/06/17/simple-kalman-filter-for-tracking-using-opencv-2-2-w-code/

#import <opencv2/opencv.hpp>
#import <opencv2/video/tracking.hpp>

#include <memory>

#import "KalmanFilter.h"

@implementation KalmanFilter {
    std::unique_ptr<cv::KalmanFilter> _filter;
    std::unique_ptr<cv::Mat_<float>> _measurement;
    BOOL _initialized;
}

- (id)init {
    self = [super init];
    if (self) {
        _filter.reset(new cv::KalmanFilter(4, 2, 0));
        _filter->transitionMatrix = (cv::Mat_<float>(4, 4) << 1,0,1,0,
                                                              0,1,0,1,
                                                              0,0,1,0,
                                                              0,0,0,1);
        _measurement.reset(new cv::Mat_<float>(2, 1));
        _measurement->setTo(cv::Scalar(0));

        // The rest of the initialization is done on the first call.
        _initialized = NO;
    }
    return self;
}

- (CGPoint)processPoint:(CGPoint)point {
    if (!_initialized) {
        // TODO: Fine tune starting point; it seems to predict 0s initially.
        _filter->statePre.at<float>(0) = point.x;
        _filter->statePre.at<float>(1) = point.y;
        _filter->statePre.at<float>(2) = 0.0;
        _filter->statePre.at<float>(3) = 0.0;
        
        cv::setIdentity(_filter->measurementMatrix);
        cv::setIdentity(_filter->processNoiseCov, cv::Scalar::all(1e-4));
        cv::setIdentity(_filter->measurementNoiseCov, cv::Scalar::all(1e-1));
        cv::setIdentity(_filter->errorCovPost, cv::Scalar::all(0.1));
        
        _initialized = YES;
        
        return point;
    } else {
        cv::Mat prediction = _filter->predict();
        cv::Point predictPoint(prediction.at<float>(0), prediction.at<float>(1));
        
        (*_measurement)(0) = point.x;
        (*_measurement)(1) = point.y;
        cv::Point measurePoint((*_measurement)(0), (*_measurement)(1));
        cv::Mat estimated = _filter->correct(*_measurement);

        return CGPointMake(estimated.at<float>(0), estimated.at<float>(1));
    }
}

@end
