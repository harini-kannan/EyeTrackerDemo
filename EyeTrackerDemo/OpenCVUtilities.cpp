//
//  OpenCVUtilities.cpp
//  iTracker
//
//  Created by Kyle Krafka on 6/3/15.
//  Copyright (c) 2015 Kyle Krafka. All rights reserved.
//

#include "OpenCVUtilities.hpp"

using namespace cv;

void OpenCVUtilities::cropCenter(const Mat &src, Mat *dst, Size dsize) {
    int w = dsize.width;
    int h = dsize.height;
    int x = (src.cols - w) / 2;
    int y = (src.rows - h) / 2;
    *dst = src(Rect(x, y, w, h));
}

void OpenCVUtilities::cropCenter(const Mat &src, Mat *dst, double scale) {
    int w = src.cols * scale;
    int h = src.rows * scale;
    OpenCVUtilities::cropCenter(src, dst, Size(w, h));
}

void OpenCVUtilities::average(const std::vector<Mat> &images, Mat *output) {
    if (images.size() == 0) {
        return;
    }
    const int channels = images[0].channels();
    cv::Mat image32f;
    cv::Mat result = cv::Mat::zeros(images[0].rows, images[0].cols, CV_32FC(channels));
    for (auto &image : images) {
        image.convertTo(image32f, CV_32FC(channels));
        result += image32f;
    }
    result /= images.size();
    result.convertTo(*output, images[0].type());
}

void OpenCVUtilities::flatten(const Mat &src, Mat *dst) {
    // Reshape parameters:
    //     0: same number of channels
    //     1: one row
    *dst = src.reshape(0, 1);
}

double OpenCVUtilities::zncc(const cv::Mat &image1, const cv::Mat &image2) {
    const int channels = image1.channels();
    
    // Zero the mean of both images (converting to float images first).
    cv::Mat imagezm1, imagezm2;
    image1.convertTo(imagezm1, CV_32FC(channels));
    image2.convertTo(imagezm2, CV_32FC(channels));
    imagezm1 -= cv::mean(imagezm1);
    imagezm2 -= cv::mean(imagezm2);
    
    // Square the zero mean images.
    cv::Mat imagesq1, imagesq2;
    cv::pow(imagezm1, 2.0, imagesq1);
    cv::pow(imagezm2, 2.0, imagesq2);
    
    double denom = sqrt((cv::sum(imagesq1) * cv::sum(imagesq2))[0]);
    
    double result = 0;
    if (denom > 1e-10) {
        result = cv::sum(imagezm1.mul(imagezm2))[0] / denom;
    }
    
    return result;
}
