//
//  OpenCVUtilities.h
//  iTracker
//
//  Created by Kyle Krafka on 6/3/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

#ifndef __iTracker__OpenCVUtilities__
#define __iTracker__OpenCVUtilities__

#include <stdio.h>
#import <opencv2/opencv.hpp>

/// Convenience functions for OpenCV.
class OpenCVUtilities {
public:
    /// Crop an image to a certain size by trimming off the borders equally.
    static void cropCenter(const cv::Mat &src, cv::Mat *dst, cv::Size dsize);
    
    /// Crop an image to a certain size as defined by a crop factor (`scale`,
    /// which should be between 0 and 1). Trim from the edges so the crop is in
    /// the center.
    static void cropCenter(const cv::Mat &src, cv::Mat *dst, double scale);
    
    /// Average a vector of images. This works with images that are all the same
    /// size and the same number of channels. The output image will be the same
    /// type as the input images.
    static void average(const std::vector<cv::Mat> &images, cv::Mat *output);
    
    /// Reshape the image to be a single row of pixels.
    static void flatten(const cv::Mat &src, cv::Mat *dst);
    
    /// Compute the zero-mean normalized cross correlation (between -1 and 1,
    /// where 1 is a perfect match) for two equally-sized image patches. This
    /// really only operates on the first color channel, though the souce could
    /// be easily modified to account for more (i.e., find "[0]" in the code and
    /// work with multiple channels; Scalars are currently only accessed at
    /// index 0).
    /// Based on: https://code.google.com/p/matlab-toolboxes-robotics-vision/source/browse/image/zncc.m?spec=svn1506&r=164
    static double zncc(const cv::Mat &image1, const cv::Mat &image2);
};

#endif /* defined(__iTracker__OpenCVUtilities__) */