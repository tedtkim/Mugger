//
//  ImageAnalysis.h
//  Mugger
//
//  Created by Ted Kim on 12/6/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <Foundation/Foundation.h>

// keys to values in the image info dictionary
#define MUGGER_ORIGINAL_IMAGE @"originalImage"      // UIImage
#define MUGGER_ENHANCED_IMAGE @"enhancedImage"      // UIImage
#define MUGGER_ANNOTATIONS @"imageAnnotations"      // UIImage
#define MUGGER_ANNOTATIONS_FACES @"facesAnnotations"   // Array of face annotation dicts
#define MUGGER_SCORE_TOTAL @"scoreTotal"
#define MUGGER_SCORE_TOTAL_DESC @"scoreTotalDescription"    // Dictionary of <description> -> <score>

// keys to values in a face annotation dictionary
// note: if key doesn't exist for eye/mouth, then they weren't found in photo
#define MUGGER_FACE_LEFT_EYE_IS_OPEN @"isLeftEyeOpen"   // [NSNumber boolValue]
#define MUGGER_FACE_RIGHT_EYE_IS_OPEN @"isRightEyeOpen" // [NSNumber boolValue]
#define MUGGER_FACE_MOUTH_IS_SMILING @"isMouthSmiling"  // [NSNumber boolValue]
#define MUGGER_FACE_ANGLE @"angle"                      // [NSNumber floatValue]

#define MUGGER_FACE_SCORE @"faceScore"
#define MUGGER_FACE_SCORE_DESC @"faceScoreDescription"
#define MUGGER_FACE_EYES_SCORE @"eyesScore"
#define MUGGER_FACE_EYES_SCORE_DESC @"eyesScoreDescription"
#define MUGGER_FACE_MOUTH_SCORE @"mouthScore"
#define MUGGER_FACE_MOUTH_SCORE_DESC @"mouthScoreDescription"
#define MUGGER_FACE_ANGLE_SCORE @"faceAngleScore"
#define MUGGER_FACE_ANGLE_SCORE_DESC @"faceAngleScoreDescription"

@interface ImageAnalysis : NSObject

// Returns info dictionary for analyzed image
+ (NSDictionary *)analyzeImage:(UIImage *)image;

// Colors used for each annotation label and score
+ (UIColor *)eyeColor;
+ (UIColor *)mouthColor;
+ (UIColor *)faceBoundsColor;
+ (UIColor *)scoreColor:(int)score;

@end
