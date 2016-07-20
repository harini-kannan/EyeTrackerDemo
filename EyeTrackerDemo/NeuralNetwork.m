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
#import "NeuralNetwork.h"

@implementation NeuralNetwork {
    
    NSString* directory_name;
    bool debug;
    
    void* leftEyeImage;
    void* rightEyeImage;
    void* faceImage;
    float facegrid_input[625];
    
    void* left_eye_network;
    void* right_eye_network;
    void* face_network;
    
    float *facegrid_weights1;
    float facegrid_bias1[256];
    float facegrid_weights2[256*128];
    float facegrid_bias2[128];
    
    float eyes_bias1[128];
    
    float *final_weights1;
    float final_bias1[128];
    
    float final_weights2[128*2];
    float final_bias2[2];
}

- (id)init {
    self = [super init];
    NSLog(@"Before initializing the network\n");
    if (self) {
        
        NSLog(@"Initializing the network\n");
        directory_name = @"iPhoneVertical";
        debug = true;
        
        // Reading facegrid weights and biases
        facegrid_weights1 = malloc(sizeof(float) * 625 * 256);
        NSString *tmp;
        NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_weights" ofType:@"txt" inDirectory:directory_name];
        NSArray *lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        NSEnumerator *nse = [lines objectEnumerator];
        int i = 0;
        while(i < 625*256) {
            tmp = [nse nextObject];
            facegrid_weights1[i] = [tmp floatValue];
            i++;
        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_bias" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            facegrid_bias1[i] = [tmp floatValue];
            i++;
        }
        
        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_weights" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            facegrid_weights2[i] = [tmp floatValue];
            i++;
        }

        textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc2_bias" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            facegrid_bias2[i] = [tmp floatValue];
            i++;
        }

        // Reading weights and biases for eye concat
        // Bias dimensions are 1 1 1 128
        NSString* eyesTextPath = [[NSBundle mainBundle] pathForResource:@"fc1_bias" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:eyesTextPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        
        NSEnumerator *eyes_nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [eyes_nse nextObject]) {
            eyes_bias1[i] = [tmp floatValue];
            i++;
        }

        // Reading weights and biases for final concat
        final_weights1 = malloc(sizeof(float) * 320 * 128);
        textPath = [[NSBundle mainBundle] pathForResource:@"fc2_weights" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(i < 320*128) {
            tmp = [nse nextObject];
            final_weights1[i] = [tmp floatValue];
            i++;
        }

        // Dimensions: 1 1 1 128
        textPath = [[NSBundle mainBundle] pathForResource:@"fc2_bias" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_bias1[i] = [tmp floatValue];
            i++;
        }
        
        // Dimensions: 1 1 128 2
        textPath = [[NSBundle mainBundle] pathForResource:@"fc3_weights" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_weights2[i] = [tmp floatValue];
            i++;
        }
        
        // Dimensions 1 1 1 2
        textPath = [[NSBundle mainBundle] pathForResource:@"fc3_bias" ofType:@"txt" inDirectory:directory_name];
        lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        nse = [lines objectEnumerator];
        i = 0;
        while(tmp = [nse nextObject]) {
            final_bias2[i] = [tmp floatValue];
            i++;
        }
        
        NSLog(@"Done initializing the network\n");
    }
    
    return self;
}

- (void) populateInput: (NSArray*)faceGrid firstImage:(UIImage*) leftEye secondImage:(UIImage*) rightEye thirdImage:(UIImage*) face {

    if (debug) {
        NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"test_left_eye219" ofType:@"jpg"];
        leftEyeImage = jpcnn_create_image_buffer_from_file([imagePath UTF8String]);
        
        NSString* rightEyeImagePath = [[NSBundle mainBundle] pathForResource:@"test_right_eye219" ofType:@"jpg"];
        rightEyeImage = jpcnn_create_image_buffer_from_file([rightEyeImagePath UTF8String]);
        
        NSString* faceImagePath = [[NSBundle mainBundle] pathForResource:@"test_face219" ofType:@"jpg"];
        faceImage = jpcnn_create_image_buffer_from_file([faceImagePath UTF8String]);
        
        NSString* textPath = [[NSBundle mainBundle] pathForResource:@"test_facegrid_sunday" ofType:@"txt"];
        NSArray* lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
        NSEnumerator* nse = [lines objectEnumerator];
        int i = 0;
        NSString* tmp;
        while(tmp = [nse nextObject]) {
            facegrid_input[i] = [tmp floatValue];
            i++;
        }
    } else {
        NSString *leftEyeSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveLeftEye.jpg"];
        [UIImageJPEGRepresentation(leftEye, 1.0) writeToFile:leftEyeSavedPath atomically:YES];
        leftEyeImage = jpcnn_create_image_buffer_from_file([leftEyeSavedPath UTF8String]);
        
        NSString *rightEyeSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveRightEye.jpg"];
        [UIImageJPEGRepresentation(rightEye, 1.0) writeToFile:rightEyeSavedPath atomically:YES];
        rightEyeImage = jpcnn_create_image_buffer_from_file([rightEyeSavedPath UTF8String]);
        
        NSString *faceSavedPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveFace.jpg"];
        [UIImageJPEGRepresentation(face, 1.0) writeToFile:faceSavedPath atomically:YES];
        faceImage = jpcnn_create_image_buffer_from_file([faceSavedPath UTF8String]);
        
        for (int i=0; i < 625; i++) {
            float f = [[faceGrid objectAtIndex:i] floatValue];
            facegrid_input[i] = f;
        }
    }
}

- (CGPoint)runNeuralNetwork: (NSArray*)faceGrid firstImage:(UIImage*) leftEye secondImage:(UIImage*) rightEye thirdImage:(UIImage*) face{

    [self populateInput:faceGrid firstImage:leftEye secondImage:rightEye thirdImage:face];
   
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:@"lefteye" ofType:@"ntwk" inDirectory:directory_name];
    assert(networkPath != NULL);
    left_eye_network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(left_eye_network != NULL);
    
    networkPath = [[NSBundle mainBundle] pathForResource:@"righteye" ofType:@"ntwk" inDirectory:directory_name];
    assert(networkPath != NULL);
    right_eye_network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(right_eye_network != NULL);
    
    networkPath = [[NSBundle mainBundle] pathForResource:@"face" ofType:@"ntwk" inDirectory:directory_name];
    assert(networkPath != NULL);
    face_network = jpcnn_create_network(219, [networkPath UTF8String]);
    assert(face_network != NULL);
    
    // BEGIN: LEFTEYE
    
    float* LE_predictions;
    int LE_predictionsLength;
    char** LE_predictionsLabels;
    int LE_predictionsLabelsLength;
    jpcnn_classify_image(219, left_eye_network, leftEyeImage, 0, 0, &LE_predictions, &LE_predictionsLength, &LE_predictionsLabels, &LE_predictionsLabelsLength);
    
    jpcnn_destroy_image_buffer(leftEyeImage);
    //jpcnn_destroy_network(network);
    
    // END: LEFTEYE
    
    // BEGIN: RIGHTEYE
    
//    float* RE_predictions = [self classifyNtwk:219 a:rightEyeImage b:@"righteye_219FC" c:@"gazecapture789"];
    
    float* RE_predictions;
    int RE_predictionsLength;
    char** RE_predictionsLabels;
    int RE_predictionsLabelsLength;
    jpcnn_classify_image(219, right_eye_network, rightEyeImage, 0, 0, &RE_predictions, &RE_predictionsLength, &RE_predictionsLabels, &RE_predictionsLabelsLength);
    
    jpcnn_destroy_image_buffer(rightEyeImage);
    //jpcnn_destroy_network(network);
    // END: RIGHTEYE

    // BEGIN: FACE
    
    float* F_predictions;
    int F_predictionsLength;
    char** F_predictionsLabels;
    int F_predictionsLabelsLength;
    jpcnn_classify_image(219, face_network, faceImage, 0, 0, &F_predictions, &F_predictionsLength, &F_predictionsLabels, &F_predictionsLabelsLength);
    
    jpcnn_destroy_image_buffer(faceImage);
//    jpcnn_destroy_network(network);
//     END: FACE
    
    // BEGIN: FACEGRID
    
    NSString* textPath = [[NSBundle mainBundle] pathForResource:@"fg_fc1_bias" ofType:@"txt" inDirectory:directory_name];
    NSArray *lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
    
    NSString *tmp;
    NSEnumerator *nse = [lines objectEnumerator];
    int i = 0;
    while(tmp = [nse nextObject]) {
        facegrid_bias1[i] = [tmp floatValue];
        i++;
    }

    float* FG_predictions;
    int FG_predictionsLength;

    jpcnn_classify_image_2FC(&FG_predictions, &FG_predictionsLength, 625, 256, facegrid_weights1, 1, 256, facegrid_bias1, 1, 625, facegrid_input, 256, 128, facegrid_weights2, 1, 128, facegrid_bias2);
    
    // END: FACEGRID
    
    // BEGIN: EYES CONCAT
    
    textPath = [[NSBundle mainBundle] pathForResource:@"fc1_weights" ofType:@"txt" inDirectory:directory_name];
    
    float eyes_weights1[256*128];
    lines = [[NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
    
    nse = [lines objectEnumerator];
    i = 0;
    while(tmp = [nse nextObject]) {
        eyes_weights1[i] = [tmp floatValue];
        i++;
    }

    float* eyes_predictions;
    int eyes_predictionsLength;
    
    jpcnn_concat_eyes(&eyes_predictions, &eyes_predictionsLength, 256, 128, eyes_weights1, 1, 128, eyes_bias1, 1, 256, LE_predictions, RE_predictions);
    
    // END: EYES CONCAT

    // BEGIN: FINAL CONCAT
   
    float* final_predictions;
    int final_predictionsLength;
    
    jpcnn_concat_final(&final_predictions, &final_predictionsLength, 320, 128, final_weights1, 1, 128, final_bias1, 128, 2, final_weights2, 1, 2, final_bias2, 1, 320, eyes_predictions, FG_predictions, F_predictions);

    NSLog(@"%f, %f", final_predictions[0], final_predictions[1]);
    CGPoint pp = CGPointMake(final_predictions[0], final_predictions[1]);
//    CGPoint pp = CGPointMake(final_predictions[0], final_predictions[1]*1.8);
    
    jpcnn_destroy_network(face_network);
    jpcnn_destroy_network(left_eye_network);
    jpcnn_destroy_network(right_eye_network);
    return pp;
    // END: FINAL CONCAT
}

- (void) printIntermediates: (float*) predictions a:(int) predictionsLength {
    for (int index = 0; index < predictionsLength; index += 1) {
        const float predictionValue = predictions[index];
        NSString* predictionLine = [NSString stringWithFormat: @"%0.2f\n", predictionValue];
        NSLog(@"%@", predictionLine);
    }
    
}

- (float*) classifyNtwk: (int)inputSize a:(void*) inputImage b:(NSString*) ntwkFileName c:(NSString*) directory {
    NSString* networkPath = [[NSBundle mainBundle] pathForResource:ntwkFileName ofType:@"ntwk" inDirectory:directory];
    assert(networkPath != NULL);
    void* network = jpcnn_create_network(inputSize, [networkPath UTF8String]);
    assert(network != NULL);
    
    float* predictions;
    int predictionsLength;
    char** predictionsLabels;
    int predictionsLabelsLength;
    jpcnn_classify_image(inputSize, network, inputImage, 0, 0, &predictions, &predictionsLength, &predictionsLabels, &predictionsLabelsLength);
    
    jpcnn_destroy_image_buffer(inputImage);
    //    jpcnn_destroy_network(network);
    return predictions;
}
@end

