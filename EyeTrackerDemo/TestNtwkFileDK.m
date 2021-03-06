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
    
    float input[625];
    
    float weights2[256*128];
    float bias2[128];
    
    float *eyes_weights1;
    float eyes_bias1[128];
    float eyes_debug_input[256];
    
    float final_bias1[128];
    
    float final_weights2[128*2];
    float final_bias2[2];

}
- (id)init {
    self = [super init];
    
    if (self) {
        weights1 = malloc(sizeof(float) * 625 * 256);
//        eyes_weights1 = malloc(sizeof(float) * 3200 * 128);
        
        NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
        
        NSString *tmp;
        NSArray *lines;
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        NSEnumerator *nse = [lines objectEnumerator];
        int i = 0;
        while(tmp = [nse nextObject]) {
            bias1[i] = [tmp floatValue];
            i++;
        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"test_facegrid_sunday" ofType:@"txt"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            input[i] = [tmp floatValue];
            i++;
        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        
        while(i < 625*256) {
            tmp = [nse nextObject];
            weights1[i] = [tmp floatValue];
            i++;
        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            weights2[i] = [tmp floatValue];
            i++;
        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            bias2[i] = [tmp floatValue];
            i++;
        }
        
        NSString *eyes_tmp;
        NSArray *eyes_lines;
        
        // Bias dimensions are 1 1 1 128
        NSString* eyesTextPath = [[NSBundle mainBundle] pathForResource:@"fc1_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
        lines = [[NSString stringWithContentsOfFile:eyesTextPath] componentsSeparatedByString:@"\n"];
        
        NSEnumerator *eyes_nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [eyes_nse nextObject]) {
            eyes_bias1[i] = [tmp floatValue];
            i++;
        }
        
//        // Eyes dimensions is 1 1 256 128
//        textPath = [[NSBundle mainBundle] pathForResource:@"fc1_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//        
//        nse = [lines objectEnumerator];
//        i = 0;
//        while(tmp = [nse nextObject]) {
//            eyes_weights1[i] = [tmp floatValue];
//            i++;
//        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"concat_eyes_input" ofType:@"txt"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
        
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            eyes_debug_input[i] = [tmp floatValue];
            i++;
        }
        
        float final_bias1[128];
    
        float final_weights2[128*2];
        float final_bias2[2];
    
        // Dimensions: 1 1 320 128
//            textPath = [[NSBundle mainBundle] pathForResource:@"fc2_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//            lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//        
//            nse = [lines objectEnumerator];
//            i = 0;
//            while(i < 320*128) {
//                tmp = [nse nextObject];
//        //        NSLog(@"%d, %@", i, tmp);
//                final_weights1[i] = [tmp floatValue];
//                i++;
//            }
    
        // Dimensions: 1 1 1 128
        textPath = [[NSBundle mainBundle] pathForResource:@"fc2_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
    
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_bias1[i] = [tmp floatValue];
            i++;
        }
    
        // Dimensions: 1 1 128 2
        textPath = [[NSBundle mainBundle] pathForResource:@"fc3_weights" ofType:@"txt" inDirectory:@"gazecapture789"];
        lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
    
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_weights2[i] = [tmp floatValue];
            i++;
        }
    
        // Dimensions 1 1 1 2
        textPath = [[NSBundle mainBundle] pathForResource:@"fc3_bias" ofType:@"txt" inDirectory:@"gazecapture789"];
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

    // BEGIN: LEFTEYE
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:@"lefteye_DK" ofType:@"ntwk" inDirectory:@"DarkKnowledge"]; //cifar10_quick.ntwk
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* left_eye_network = jpcnn_create_network(79, [networkPath UTF8String]);
    assert(left_eye_network != NULL);

    
    // UNCOMMENT BELOW 2 LINES FOR LIVE IMAGE
//    NSString *leftEyeByteArray = [UIImageJPEGRepresentation(leftEye, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//
//    const unsigned char *leftEyeBaseAddress = (const unsigned char *) [leftEyeByteArray cStringUsingEncoding:NSASCIIStringEncoding];
//
//    void* inputImage = jpcnn_create_image_buffer_from_uint8_data(leftEyeBaseAddress, 32, 32, 3, 96, 0, 0);
    // UNCOMMENT ABOVE 2 LINES FOR LIVE IMAGE
    
    // UNCOMMENT BELOW 2 LINES FOR EXAMPLE IMAGE
    NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"test_left_eye79" ofType:@"jpg" inDirectory:@"DarkKnowledge"];
    void* inputImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);
    // UNCOMMENT ABOVE 2 LINES FOR EXAMPLE IMAGE
    
    
    float* LE_predictions;
    int LE_predictionsLength;
    char** LE_predictionsLabels;
    int LE_predictionsLabelsLength;
    jpcnn_classify_image(79, left_eye_network, inputImage, 0, 0, &LE_predictions, &LE_predictionsLength, &LE_predictionsLabels, &LE_predictionsLabelsLength);


    jpcnn_destroy_image_buffer(inputImage);

//    for (int index = 0; index < LE_predictionsLength; index += 1) {
//        const float predictionValue = LE_predictions[index];
//        char* label = LE_predictionsLabels[index % LE_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    
    //jpcnn_destroy_network(network);
    
    // END: LEFTEYE
    
    // BEGIN: RIGHTEYE
    networkPath = [[NSBundle mainBundle] pathForResource:@"righteye_DK" ofType:@"ntwk" inDirectory:@"DarkKnowledge"]; //cifar10_quick.ntwk
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* right_eye_network = jpcnn_create_network(79, [networkPath UTF8String]);
    assert(right_eye_network != NULL);

    
    // UNCOMMENT BELOW 3 LINES FOR LIVE IMAGE
//    NSString *rightEyeByteArray = [UIImageJPEGRepresentation(leftEye, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//    
//    const unsigned char *rightEyeBaseAddress = (const unsigned char *) [rightEyeByteArray cStringUsingEncoding:NSASCIIStringEncoding];
//    
//    inputImage = jpcnn_create_image_buffer_from_uint8_data(rightEyeBaseAddress, 32, 32, 3, 96, 0, 0);
    // UNCOMMENT ABOVE 3 LINES FOR LIVE IMAGE
    
    // UNCOMMENT BELOW TWO LINES FOR EXAMPLE IMAGE
    imagePath = [[NSBundle mainBundle] pathForResource:@"test_right_eye79" ofType:@"jpg" inDirectory:@"DarkKnowledge"]; //cifar10_1.jpg
    inputImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);
    // UNCOMMENT ABOVE TWO LINES FOR EXAMPLE IMAGE
    
    float* RE_predictions;
    int RE_predictionsLength;
    char** RE_predictionsLabels;
    int RE_predictionsLabelsLength;
    jpcnn_classify_image(79, right_eye_network, inputImage, 0, 0, &RE_predictions, &RE_predictionsLength, &RE_predictionsLabels, &RE_predictionsLabelsLength);
    
    
    jpcnn_destroy_image_buffer(inputImage);
    NSLog(@"RIGHTEYE");
//    for (int index = 0; index < RE_predictionsLength; index += 1) {
//        const float predictionValue = RE_predictions[index];
//        char* label = RE_predictionsLabels[index % RE_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    
    //jpcnn_destroy_network(network);

    // END: RIGHTEYE

    // BEGIN: FACE
    networkPath = [[NSBundle mainBundle] pathForResource:@"face_DK" ofType:@"ntwk" inDirectory:@"DarkKnowledge"]; //cifar10_quick.ntwk
    if (networkPath == NULL) {
        fprintf(stderr, "Couldn't find the neural network parameters file - did you add it as a resource to your application?\n");
        assert(false);
    }
    void* face_network = jpcnn_create_network(79, [networkPath UTF8String]);
    assert(face_network != NULL);

    // UNCOMMENT BELOW 3 LINES FOR LIVE IMAGE
//    NSString *faceByteArray = [UIImageJPEGRepresentation(leftEye, 1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
//    const unsigned char *faceBaseAddress = (const unsigned char *) [faceByteArray cStringUsingEncoding:NSASCIIStringEncoding];
//    inputImage = jpcnn_create_image_buffer_from_uint8_data(faceBaseAddress, 32, 32, 3, 96, 0, 0);
    // UNCOMMENT ABOVE 3 LINES FOR LIVE IMAGE
    
    // UNCOMMENT BELOW TWO LINES FOR EXAMPLE IMAGE
    imagePath = [[NSBundle mainBundle] pathForResource:@"test_face79" ofType:@"jpg" inDirectory:@"DarkKnowledge"];
    inputImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);
    // UNCOMMENT ABOVE TWO LINES FOR EXAMPLE IMAGE
    
    float* F_predictions;
    int F_predictionsLength;
    char** F_predictionsLabels;
    int F_predictionsLabelsLength;
    jpcnn_classify_image(79, face_network, inputImage, 0, 0, &F_predictions, &F_predictionsLength, &F_predictionsLabels, &F_predictionsLabelsLength);
    
    
    jpcnn_destroy_image_buffer(inputImage);
    
//    for (int index = 0; index < F_predictionsLength; index += 1) {
//        const float predictionValue = F_predictions[index];
//        char* label = F_predictionsLabels[index % F_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%s - %0.2f\n", label, predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    
    //jpcnn_destroy_network(network);
    // END: FACE

    // BEGIN: FACEGRID

//    float *weights1 = malloc(sizeof(float) * 625 * 256);
//    
//    float bias1[256];
//    
//    float input[625];
//
//    float weights2[256*128];
//    float bias2[128];
//
//    NSString *tmp;
//    NSArray *lines;
//    
//    NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    NSEnumerator *nse = [lines objectEnumerator];
//    int i = 0;
//    while(tmp = [nse nextObject]) {
//        bias1[i] = [tmp floatValue];
//        i++;
//    }
//    
//    // UNCOMMENT BELOW LINES TO USE EXAMPLE FACEGRID
//    
//    textPath = [[NSBundle mainBundle] pathForResource:@"test_facegrid_sunday" ofType:@"txt"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//    while(tmp = [nse nextObject]) {
//        input[i] = [tmp floatValue];
//        i++;
//    }
//    // UNCOMMENT ABOVE LINES TO USE EXAMPLE FACEGRID
//    
//    // UNCOMMENT BELOW LINES TO USE LIVE FACEGRID
////    for (int i=0; i < 625; i++) {
////        float f = [[faceGrid objectAtIndex:i] floatValue];
////        input[i] = f;
////    }
//    // UNCOMMENT ABOVE LINES TO USE LIVE FACEGRID
//
//
//    textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//
//    while(i < 625*256) {
//        tmp = [nse nextObject];
//        weights1[i] = [tmp floatValue];
//        i++;
//    }
//
//    textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//    while(tmp = [nse nextObject]) {
//        weights2[i] = [tmp floatValue];
//        i++;
//    }
//   
//    textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//    while(tmp = [nse nextObject]) {
//        bias2[i] = [tmp floatValue];
//        i++;
//    }

    float* FG_predictions;
    int FG_predictionsLength;
    char** FG_predictionsLabels;
    int FG_predictionsLabelsLength;
    
    jpcnn_classify_image_2FC(&FG_predictions, &FG_predictionsLength, 625, 256, weights1, 1, 256, bias1, 1, 625, input, 256, 128, weights2, 1, 128, bias2);
    
//    for (int index = 0; index < FG_predictionsLength; index += 1) {
//        const float predictionValue = FG_predictions[index];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }

    
    // END: FACEGRID

    // BEGIN: EYES CONCAT
    
    NSDate *methodStart = [NSDate date];
    
    float *eyes_weights1 = malloc(sizeof(float) * 3200 * 128);
    float eyes_bias1[128];
//    float eyes_debug_input[256];
//    
    NSString *eyes_tmp;
    NSArray *eyes_lines;

    // Bias dimensions are 1 1 1 128
    NSString* eyesTextPath = [[NSBundle mainBundle] pathForResource:@"fc1_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
    eyes_lines = [[NSString stringWithContentsOfFile:eyesTextPath] componentsSeparatedByString:@"\n"];
    
    NSEnumerator *eyes_nse = [eyes_lines objectEnumerator];
    int i = 0;
    while(eyes_tmp = [eyes_nse nextObject]) {
        eyes_bias1[i] = [eyes_tmp floatValue];
        i++;
    }
    
    // Eyes dimensions is 1 1 256 128
    eyesTextPath = [[NSBundle mainBundle] pathForResource:@"fc1_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
    eyes_lines = [[NSString stringWithContentsOfFile:eyesTextPath] componentsSeparatedByString:@"\n"];
    
    eyes_nse = [eyes_lines objectEnumerator];
    i = 0;
    while(eyes_tmp = [eyes_nse nextObject]) {
        eyes_weights1[i] = [eyes_tmp floatValue];
        i++;
    }
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"executionTime = %f", executionTime);
    
//
//    eyesTextPath = [[NSBundle mainBundle] pathForResource:@"concat_eyes_input" ofType:@"txt"];
//    eyes_lines = [[NSString stringWithContentsOfFile:eyesTextPath] componentsSeparatedByString:@"\n"];
//
//    eyes_nse = [eyes_lines objectEnumerator];
//    i = 0;
//    while(eyes_tmp = [eyes_nse nextObject]) {
//        eyes_debug_input[i] = [eyes_tmp floatValue];
//        i++;
//    }
    
    float* eyes_predictions;
    int eyes_predictionsLength;
    
//    NSLog(@"BEFORE SECONDARY PRINT");
//    
//    for (int index = 0; index < RE_predictionsLength; index += 1) {
//        const float predictionValue = RE_predictions[index];
//        char* label = RE_predictionsLabels[index % RE_predictionsLabelsLength];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
//    NSLog(@"AFTER SECONDARY PRINT");
    jpcnn_concat_eyes(&eyes_predictions, &eyes_predictionsLength, 3200, 128, eyes_weights1, 1, 128, eyes_bias1, 1, 3200, LE_predictions, RE_predictions, eyes_debug_input);
    
//    for (int index = 0; index < eyes_predictionsLength; index += 1) {
//        const float predictionValue = eyes_predictions[index];
//        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
//        NSLog(@"%@", predictionLine);
//    }
    //END: EYES CONCAT
//
//    // BEGIN: FINAL CONCAT
//
    float *final_weights1 = malloc(sizeof(float) * 320*128);
//    float final_bias1[128];
//    
//    float final_weights2[128*2];
//    float final_bias2[2];
//    
    // Dimensions: 1 1 320 128
    NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fc2_weights" ofType:@"txt" inDirectory:@"DarkKnowledge"];
    NSArray *lines;
    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
    
    NSEnumerator *nse = [lines objectEnumerator];
    i = 0;
    NSString *tmp;
    while(i < 320*128) {
        tmp = [nse nextObject];
        final_weights1[i] = [tmp floatValue];
        i++;
    }
//
//    // Dimensions: 1 1 1 128
//    textPath = [[NSBundle mainBundle] pathForResource:@"fc2_bias" ofType:@"txt" inDirectory:@"DarkKnowledge"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//    while(tmp = [nse nextObject]) {
//        final_bias1[i] = [tmp floatValue];
//        i++;
//    }
//    
//    // Dimensions: 1 1 128 2
//    textPath = [[NSBundle mainBundle] pathForResource:@"fc3_weights" ofType:@"txt" inDirectory:@"gazecapture789"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//    while(tmp = [nse nextObject]) {
//        final_weights2[i] = [tmp floatValue];
//        i++;
//    }
//    
//    // Dimensions 1 1 1 2
//    textPath = [[NSBundle mainBundle] pathForResource:@"fc3_bias" ofType:@"txt" inDirectory:@"gazecapture789"];
//    lines = [[NSString stringWithContentsOfFile:textPath] componentsSeparatedByString:@"\n"];
//    
//    nse = [lines objectEnumerator];
//    i = 0;
//    while(tmp = [nse nextObject]) {
//        final_bias2[i] = [tmp floatValue];
//        i++;
//    }
//    
    float* final_predictions;
    int final_predictionsLength;

    jpcnn_concat_final(&final_predictions, &final_predictionsLength, 320, 128, final_weights1, 1, 128, final_bias1, 128, 2, final_weights2, 1, 2, final_bias2, 1, 320, eyes_predictions, FG_predictions, F_predictions);

    for (int index = 0; index < final_predictionsLength; index += 1) {
        const float predictionValue = final_predictions[index];
        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
        NSLog(@"%@", predictionLine);
    }
    CGPoint pp = CGPointMake(final_predictions[0], final_predictions[1]);
    free(eyes_weights1);
    free(weights1);
//    free(final_weights1);
    jpcnn_destroy_network(face_network);
    jpcnn_destroy_network(left_eye_network);
    jpcnn_destroy_network(right_eye_network);
//    CGPoint pp = CGPointMake(23.0, 23.0);
    return pp;
    // END: FINAL CONCAT
}
@end

