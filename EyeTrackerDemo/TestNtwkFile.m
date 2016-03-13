//
//  TestNtwkFile.m
//  EyeTrackerDemo
//
//  Created by Harini Kannan on 3/11/16.
//  Copyright © 2016 Harini Kannan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeepBelief/DeepBelief.h>
#import "TestNtwkFile.h"

@implementation TestNtwkFile {
}

+ (void)testNtwkFile {
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:@"cifar10_quick" ofType:@"ntwk"];
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* network = jpcnn_create_network([networkPath UTF8String]);
    assert(network != NULL);
    
    NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"cifar10_1" ofType:@"jpg"];
    void* inputImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);
    
    float* predictions;
    int predictionsLength;
    char** predictionsLabels;
    int predictionsLabelsLength;
    jpcnn_classify_image(network, inputImage, 0, 0, &predictions, &predictionsLength, &predictionsLabels, &predictionsLabelsLength);
    
    jpcnn_destroy_image_buffer(inputImage);
    
    for (int index = 0; index < predictionsLength; index += 1) {
        const float predictionValue = predictions[index];
        char* label = predictionsLabels[index % predictionsLabelsLength];
        NSString* predictionLine = [NSString stringWithFormat: @"%s - %0.2f\n", label, predictionValue];
        NSLog(@"%@", predictionLine);
    }
    
    jpcnn_destroy_network(network);
    
}
@end

