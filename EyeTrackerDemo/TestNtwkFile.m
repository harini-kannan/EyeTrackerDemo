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
    float *weights1;
    
    float bias1[256];
    
    float facegrid_input[625];
    
    float weights2[256*128];
    float bias2[128];
    
    float *eyes_weights1;
    float eyes_bias1[128];
    float eyes_debug_input[256];
    
    float *final_weights1;
    float final_bias1[128];
    
    float final_weights2[128*2];
    float final_bias2[2];
}

- (id)init {
    self = [super init];
    
    if (self) {
        weights1 = malloc(sizeof(float) * 625 * 256);
        final_weights1 = malloc(sizeof(float) * 320*128);
        NSString *tmp;
        NSArray *lines;
        
//        NSString* textPath = [[NSBundle mainBundle] pathForResource:@"facegrid_bias1" ofType:@"txt" inDirectory:@"gazecapture789"];
        NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_bias" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        NSEnumerator *nse = [lines objectEnumerator];
        int i = 0;
        while(tmp = [nse nextObject]) {
            bias1[i] = [tmp floatValue];
            i++;
        }
//        textPath = [[NSBundle mainBundle] pathForResource:@"facegrid_weights1" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_weights" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;

        while(i < 625*256) {
            tmp = [nse nextObject];
            weights1[i] = [tmp floatValue];
            i++;
        }
        
//        textPath = [[NSBundle mainBundle] pathForResource:@"facegrid_weights2" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_weights" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            weights2[i] = [tmp floatValue];
            i++;
        }

        
//        textPath = [[NSBundle mainBundle] pathForResource:@"facegrid_bias2" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_bias" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            bias2[i] = [tmp floatValue];
            i++;
        }

        // EYES CONCAT
        NSString *eyes_tmp;
        NSArray *eyes_lines;
        // Bias dimensions are 1 1 1 128
//        NSString* eyesTextPath = [[NSBundle mainBundle] pathForResource:@"concat_eyes_bias" ofType:@"txt" inDirectory:@"gazecapture789"];
        NSString* eyesTextPath = [[NSBundle mainBundle] pathForResource:@"fc1_bias" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:eyesTextPath] componentsSeparatedByString:@"\n"];
        
        NSEnumerator *eyes_nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [eyes_nse nextObject]) {
            eyes_bias1[i] = [tmp floatValue];
            i++;
        }

        textPath = [[NSBundle mainBundle] pathForResource:@"concat_eyes_input" ofType:@"txt"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];

        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            eyes_debug_input[i] = [tmp floatValue];
            i++;
        }
//        textPath = [[NSBundle mainBundle] pathForResource:@"concat_full_weights1" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fc2_weights" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(i < 320*128) {
            tmp = [nse nextObject];
    //        NSLog(@"%d, %@", i, tmp);
            final_weights1[i] = [tmp floatValue];
            i++;
        }

        // Dimensions: 1 1 1 128
//        textPath = [[NSBundle mainBundle] pathForResource:@"concat_full_bias1" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fc2_bias" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_bias1[i] = [tmp floatValue];
            i++;
        }
        
        // Dimensions: 1 1 128 2
//        textPath = [[NSBundle mainBundle] pathForResource:@"concat_full_weights2" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fc3_weights" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_weights2[i] = [tmp floatValue];
            i++;
        }
        
        // Dimensions 1 1 1 2
//        textPath = [[NSBundle mainBundle] pathForResource:@"concat_full_bias2" ofType:@"txt" inDirectory:@"gazecapture789"];
        textPath = [[NSBundle mainBundle] pathForResource:@"fc3_bias" ofType:@"txt" inDirectory:@"iPhoneVertical"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_bias2[i] = [tmp floatValue];
            i++;
        }
    }
    
    return self;
}

- (CGPoint)testNtwkFile: (NSArray*)faceGrid firstImage:(UIImage*) leftEye secondImage:(UIImage*) rightEye thirdImage:(UIImage*) face{

    bool debug = false;
    if (debug) {
        
    }
    
    // BEGIN: LEFTEYE
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:@"lefteye_iphone_vert" ofType:@"ntwk" inDirectory:@"iPhoneVertical"];
    
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* left_eye_network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(left_eye_network != NULL);

    
    // UNCOMMENT BELOW 2 LINES FOR LIVE IMAGE
//    NSString *leftEyeSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveLeftEye.jpg"];
//    [UIImageJPEGRepresentation(leftEye, 1.0) writeToFile:leftEyeSavedPath atomically:YES];
//    void* leftEyeImage = jpcnn_create_image_buffer_from_file([leftEyeSavedPath UTF8String]);
    
//    UIImageWriteToSavedPhotosAlbum(leftEye, nil, nil, nil);
    
    // UNCOMMENT ABOVE 2 LINES FOR LIVE IMAGE
    
    // UNCOMMENT BELOW 2 LINES FOR EXAMPLE IMAGE
    NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"test_left_eye219" ofType:@"jpg"];
    void* leftEyeImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);
    
//    UIImage *leftEyeImage = [UIImage imageNamed:@"test_left_eye219.jpg"];
//    
//    NSString *leftEyeSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveLeftEye.jpg"];
//    [UIImageJPEGRepresentation(leftEyeImage, 1.0) writeToFile:leftEyeSavedPath atomically:YES];
//    
//    NSError *error;
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
//    
//    // Point to Document directory
//    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
//    
//    // Write out the contents of home directory to console
//    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
//
//    NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"test_left_eye219" ofType:@"jpg"];
//    void* inputImage = jpcnn_create_image_buffer_from_file([leftEyeSavedPath UTF8String]);
    
    // UNCOMMENT ABOVE 2 LINES FOR EXAMPLE IMAGE
    
    
    float* LE_predictions;
    int LE_predictionsLength;
    char** LE_predictionsLabels;
    int LE_predictionsLabelsLength;
    jpcnn_classify_image(219, left_eye_network, leftEyeImage, 0, 0, &LE_predictions, &LE_predictionsLength, &LE_predictionsLabels, &LE_predictionsLabelsLength);
    
    jpcnn_destroy_image_buffer(leftEyeImage);
    
    //jpcnn_destroy_network(network);
    
//    
//    for (int index = 0; index < LE_predictionsLength; index += 1) {
//        const float predictionValue = LE_predictions[index];
//        char* label = LE_predictionsLabels[index % LE_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }

    // END: LEFTEYE
    
    // BEGIN: RIGHTEYE
//    networkPath = [[NSBundle mainBundle] pathForResource:@"righteye_219FC" ofType:@"ntwk"];
    networkPath = [[NSBundle mainBundle] pathForResource:@"righteye_iphone_vert" ofType:@"ntwk" inDirectory:@"iPhoneVertical"];
    
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* right_eye_network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(right_eye_network != NULL);

    
    // UNCOMMENT BELOW 3 LINES FOR LIVE IMAGE

//    NSString *rightEyeSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveRightEye.jpg"];
//    [UIImageJPEGRepresentation(rightEye, 1.0) writeToFile:rightEyeSavedPath atomically:YES];
//    void* rightEyeImage = jpcnn_create_image_buffer_from_file([rightEyeSavedPath UTF8String]);
    // UNCOMMENT ABOVE 3 LINES FOR LIVE IMAGE
    
    // UNCOMMENT BELOW TWO LINES FOR EXAMPLE IMAGE
    NSString* rightEyeImagePath = [[NSBundle mainBundle] pathForResource:@"test_right_eye219" ofType:@"jpg"]; //cifar10_1.jpg
    void* rightEyeImage = jpcnn_create_image_buffer_from_file([rightEyeImagePath UTF8String]);
    // UNCOMMENT ABOVE TWO LINES FOR EXAMPLE IMAGE
    
    float* RE_predictions;
    int RE_predictionsLength;
    char** RE_predictionsLabels;
    int RE_predictionsLabelsLength;
    jpcnn_classify_image(219, right_eye_network, rightEyeImage, 0, 0, &RE_predictions, &RE_predictionsLength, &RE_predictionsLabels, &RE_predictionsLabelsLength);
    
    
    jpcnn_destroy_image_buffer(rightEyeImage);
//    NSLog(@"RIGHTEYE");
//    for (int index = 0; index < RE_predictionsLength; index += 1) {
//        const float predictionValue = RE_predictions[index];
//        char* label = RE_predictionsLabels[index % RE_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    
    //jpcnn_destroy_network(network);

    // END: RIGHTEYE

    // BEGIN: FACE
//    networkPath = [[NSBundle mainBundle] pathForResource:@"face_219FC" ofType:@"ntwk"];
    networkPath = [[NSBundle mainBundle] pathForResource:@"face_iphone_vert" ofType:@"ntwk" inDirectory:@"iPhoneVertical"];
    
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* face_network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(face_network != NULL);

    // UNCOMMENT BELOW 3 LINES FOR LIVE IMAGE
//    NSString *faceSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveFace.jpg"];
//    [UIImageJPEGRepresentation(face, 1.0) writeToFile:faceSavedPath atomically:YES];
//    void* faceImage = jpcnn_create_image_buffer_from_file([faceSavedPath UTF8String]);
    
    // UNCOMMENT ABOVE 3 LINES FOR LIVE IMAGE
    
    // UNCOMMENT BELOW TWO LINES FOR EXAMPLE IMAGE
    NSString* faceImagePath = [[NSBundle mainBundle] pathForResource:@"test_face219" ofType:@"jpg"]; //cifar10_1.jpg
    void* faceImage = jpcnn_create_image_buffer_from_file([faceImagePath UTF8String]);
    // UNCOMMENT ABOVE TWO LINES FOR EXAMPLE IMAGE
    
    float* F_predictions;
    int F_predictionsLength;
    char** F_predictionsLabels;
    int F_predictionsLabelsLength;
    jpcnn_classify_image(219, face_network, faceImage, 0, 0, &F_predictions, &F_predictionsLength, &F_predictionsLabels, &F_predictionsLabelsLength);
    
    
    jpcnn_destroy_image_buffer(faceImage);

//    for (int index = 0; index < F_predictionsLength; index += 1) {
//        const float predictionValue = F_predictions[index];
//        char* label = F_predictionsLabels[index % F_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%s - %0.2f\n", label, predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    
//    jpcnn_destroy_network(network);
//     END: FACE
    
    // BEGIN: FACEGRID

    NSString *tmp;
    NSArray *lines;
    
//    NSString* textPath = [[NSBundle mainBundle] pathForResource:@"facegrid_bias1" ofType:@"txt" inDirectory:@"gazecapture789"];
    NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_bias" ofType:@"txt" inDirectory:@"iPhoneVertical"];
    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
    
    NSEnumerator *nse = [lines objectEnumerator];
    int i = 0;
    while(tmp = [nse nextObject]) {
        bias1[i] = [tmp floatValue];
        i++;
    }
    
    // UNCOMMENT BELOW LINES TO USE EXAMPLE FACEGRID
    textPath = [[NSBundle mainBundle] pathForResource:@"test_facegrid_sunday" ofType:@"txt"];
    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
    
    nse = [lines objectEnumerator];
    i = 0;
    while(tmp = [nse nextObject]) {
        facegrid_input[i] = [tmp floatValue];
        i++;
    }
    // UNCOMMENT ABOVE LINES TO USE EXAMPLE FACEGRID
    
    // UNCOMMENT BELOW LINES TO USE LIVE FACEGRID
//    for (int i=0; i < 625; i++) {
//        float f = [[faceGrid objectAtIndex:i] floatValue];
//        facegrid_input[i] = f;
//    }
    // UNCOMMENT ABOVE LINES TO USE LIVE FACEGRID

    float* FG_predictions;
    int FG_predictionsLength;
    char** FG_predictionsLabels;
    int FG_predictionsLabelsLength;

    jpcnn_classify_image_2FC(&FG_predictions, &FG_predictionsLength, 625, 256, weights1, 1, 256, bias1, 1, 625, facegrid_input, 256, 128, weights2, 1, 128, bias2);
   
//    printf("PRINTING FACEGRID DATA");
//    for (int index = 0; index < FG_predictionsLength; index += 1) {
//        const float predictionValue = FG_predictions[index];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    
    // END: FACEGRID
    
    // BEGIN: EYES CONCAT

    float eyes_weights1[256*128];
    
    NSDate *methodStart = [NSDate date];
    
//    textPath = [[NSBundle mainBundle] pathForResource:@"concat_eyes_weights" ofType:@"txt" inDirectory:@"gazecapture789"];
    textPath = [[NSBundle mainBundle] pathForResource:@"fc1_weights" ofType:@"txt" inDirectory:@"iPhoneVertical"];
    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
    
    nse = [lines objectEnumerator];
    i = 0;
    while(tmp = [nse nextObject]) {
        eyes_weights1[i] = [tmp floatValue];
        i++;
    }

    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"TIME WITHIN READING THE EYE FILE = %f", executionTime);

//    NSLog(@"BEFORE SECONDARY PRINT");
//    
//    for (int index = 0; index < RE_predictionsLength; index += 1) {
//        const float predictionValue = RE_predictions[index];
//        char* label = RE_predictionsLabels[index % RE_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
//    NSLog(@"AFTER SECONDARY PRINT");
    float* eyes_predictions;
    int eyes_predictionsLength;
    
    jpcnn_concat_eyes(&eyes_predictions, &eyes_predictionsLength, 256, 128, eyes_weights1, 1, 128, eyes_bias1, 1, 256, LE_predictions, RE_predictions, eyes_debug_input);
    
//    for (int index = 0; index < eyes_predictionsLength; index += 1) {
//        const float predictionValue = eyes_predictions[index];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    // END: EYES CONCAT

    // BEGIN: FINAL CONCAT
   
    float* final_predictions;
    int final_predictionsLength;
    
    jpcnn_concat_final(&final_predictions, &final_predictionsLength, 320, 128, final_weights1, 1, 128, final_bias1, 128, 2, final_weights2, 1, 2, final_bias2, 1, 320, eyes_predictions, FG_predictions, F_predictions);
    
    for (int index = 0; index < final_predictionsLength; index += 1) {
        const float predictionValue = final_predictions[index];
        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
        NSLog(@"%@", predictionLine);
    }
    CGPoint pp = CGPointMake(final_predictions[0], final_predictions[1]);
//    CGPoint pp = CGPointMake(final_predictions[0], final_predictions[1]*1.8);
    
    
    free(weights1);
    free(final_weights1);

    jpcnn_destroy_network(face_network);
    jpcnn_destroy_network(left_eye_network);
    jpcnn_destroy_network(right_eye_network);
    return pp;
    // END: FINAL CONCAT
}
@end

