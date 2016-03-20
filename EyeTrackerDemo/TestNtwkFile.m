//
//  TestNtwkFile.m
//  EyeTrackerDemo
//
//  Created by Harini Kannan on 3/11/16.
//  Copyright © 2016 Harini Kannan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DeepBelief/DeepBelief.h>
#import <UIKit/UIKit.h>
#import "TestNtwkFile.h"

@implementation TestNtwkFile {
}

+ (void)testNtwkFile {
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:@"face_219FC" ofType:@"ntwk"]; //cifar10_quick.ntwk
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(network != NULL);
    
    NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"test_face219" ofType:@"jpg"]; //cifar10_1.jpg
    
    void* inputImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);

        /* CONVERTING FROM JPG TO UIIMAGE */
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    
//    // Add the file to the end of the documents path
//    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"cifar10_1.jpg"];
//    
////    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
//    
//    UIImage *image = [UIImage imageNamed:@"cifar10_1.jpg"];
//    NSString *byteArray = [UIImageJPEGRepresentation(image, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//
//    const unsigned char *baseAddress = (const unsigned char *) [byteArray cStringUsingEncoding:NSASCIIStringEncoding];
    
    //void* inputImage = jpcnn_create_image_buffer_from_uint8_data(baseAddress, 32, 32, 3, 96, 0, 0);

//    UIImage *img = [UIImage imageNamed:@"cifar10_1.jpg"];
//    
//    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(img.CGImage));
//    
//    const unsigned char *buffer = CFDataGetBytePtr(pixelData);
//    
//    CFRelease(pixelData);
    //void* inputImage = jpcnn_create_image_buffer_from_uint8_data_four_channel(buffer, 32, 32, 4, 128, 0, 0);

    /* END CONVERTING FROM JPG TO UIIMAGE */
    
    float* predictions;
    int predictionsLength;
    char** predictionsLabels;
    int predictionsLabelsLength;
    jpcnn_classify_image(219, network, inputImage, 0, 0, &predictions, &predictionsLength, &predictionsLabels, &predictionsLabelsLength);
    
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

