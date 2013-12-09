//
//  ImageAnalysis.m
//  Mugger
//
//  Created by Ted Kim on 12/6/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "ImageAnalysis.h"
#import "ScoringConstants.h"
#import <ImageIO/CGImageProperties.h>

@implementation ImageAnalysis

#pragma mark - Public methods
+ (NSDictionary *)analyzeImage:(UIImage *)image
{
    // Set original image
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:image forKey:MUGGER_ORIGINAL_IMAGE];
    
    // CIDetector's methods operate on CIImage
    CIImage* ciImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    
    // Adding new iOS7 options for EyeBlink and Smile!
    NSDictionary *options = @{ CIDetectorImageOrientation : [NSNumber numberWithInt:[self orientation:image]],
                               CIDetectorEyeBlink : [NSNumber numberWithBool:YES],
                               CIDetectorSmile : [NSNumber numberWithBool:YES] };
    
    // Set enhanced image into info
    CIImage *adjusted = [self applyAutoEnhancement:ciImage options:options];
    [info setValue:[[UIImage alloc] initWithCIImage:adjusted] forKey:MUGGER_ENHANCED_IMAGE];
    
    NSArray *features = [self facesInImage:ciImage options:options];
    NSLog(@"Found %lu faces", (unsigned long)[features count]);
    
    // Draw annotations
    UIImage *annotationsImage = [self drawAnnotations:features origImage:image];
    [info setValue:annotationsImage forKey:MUGGER_ANNOTATIONS];

    
    // Score and set annotations
    [self scoreAnnotations:features info:info];
    
    return info;
}


#pragma mark - Private helpers

// Returns array of CIFeature objects, each of which represents a face in image
+ (NSArray *)facesInImage:(CIImage *)image options:(NSDictionary *)options
{
    CIContext *context = [CIContext contextWithOptions:nil];
    NSDictionary *accuracyOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:accuracyOptions];
    
    NSArray *features = [detector featuresInImage:image options:options];
    return features;
}



// Returns auto-enhanced image from Core Image
+ (CIImage *)applyAutoEnhancement:(CIImage *)image options:(NSDictionary *)options
{
    NSArray *adjustments = [image autoAdjustmentFiltersWithOptions:options];
    
    for (CIFilter *filter in adjustments) {
        [filter setValue:image forKey:kCIInputImageKey];
        image = filter.outputImage;
    }
    
    return image;
}

// Determines kCGImagePropertyOrientation as per Apple docs:
// https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGImageProperties_Reference/Reference/reference.html#//apple_ref/c/data/kCGImagePropertyOrientation

+ (int)orientation:(UIImage *)image
{
    // This is because EXIF orientation is different from UIImage's, and thus needed
    int orientation;
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
            orientation = 1;
            break;
        case UIImageOrientationDown:
            orientation = 3;
            break;
        case UIImageOrientationLeft:
            orientation = 8;
            break;
        case UIImageOrientationRight:
            orientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            orientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            orientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            orientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            orientation = 7;
            break;
        default:
            break;
    }
    return orientation;
}

#pragma mark - Drawing
// Draw annotations
+ (UIImage *)drawAnnotations:(NSArray *)faces origImage:(UIImage *)origImage
{
    // Translate Core Image coordinates to UIKit's
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -origImage.size.height);
    
    UIGraphicsBeginImageContext(origImage.size);
    
    for (CIFaceFeature *face in faces)
    {
        [self drawFaceAnnotations:face usingTransform:transform];
    }
    
    UIImage *annotations = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *orientedAnnotations = [UIImage imageWithCGImage:[annotations CGImage]
                                                       scale:1.0
                                                 orientation:[origImage imageOrientation]];
    
    UIGraphicsEndImageContext();
    return orientedAnnotations;
}

+ (void)drawFaceAnnotations:(CIFaceFeature *)face usingTransform:(CGAffineTransform)transform
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw outline of face bounds
    [[self faceBoundsColor] setStroke];
    CGContextSetLineWidth(context, 2.0);
    
    CGRect faceBoundsTransformed = CGRectStandardize(CGRectApplyAffineTransform(face.bounds, transform));
    CGContextStrokeRect(context, faceBoundsTransformed);
    
    [self drawEyeAnnotations:face usingTransform:transform];
    
    [self drawMouthAnnotations:face usingTransform:transform];
}

+ (void)drawEyeAnnotations:(CIFaceFeature *)face usingTransform:(CGAffineTransform)transform
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[self eyeColor] setStroke];
    
    CGRect faceBoundsTransformed = CGRectStandardize(CGRectApplyAffineTransform(face.bounds, transform));
    
    CGFloat eyeWidth = faceBoundsTransformed.size.width/8;
    CGFloat eyeHeight;
    
    // Left
    if (face.hasLeftEyePosition) {
        CGPoint leftEyePositionTransformed = CGPointApplyAffineTransform(face.leftEyePosition, transform);
        
        if (face.leftEyeClosed) {
            eyeHeight = eyeWidth/4;
        } else {
            eyeHeight = eyeWidth;
        }
        
        CGRect eyeRect = CGRectMake(leftEyePositionTransformed.x - eyeWidth/2,
                                    leftEyePositionTransformed.y - eyeWidth/2,
                                    eyeWidth,
                                    eyeHeight);
        
        CGContextStrokeEllipseInRect(context, eyeRect);
    }
    
    // Right
    if (face.hasRightEyePosition) {
        CGPoint rightEyePositionTransformed = CGPointApplyAffineTransform(face.rightEyePosition, transform);
        
        if (face.rightEyeClosed) {
            eyeHeight = eyeWidth/4;
        } else {
            eyeHeight = eyeWidth;
        }
        
        CGRect eyeRect = CGRectMake(rightEyePositionTransformed.x - eyeWidth/2,
                                    rightEyePositionTransformed.y - eyeHeight/2,
                                    eyeWidth,
                                    eyeHeight);
        
        CGContextStrokeEllipseInRect(context, eyeRect);
    }
}

+ (void)drawMouthAnnotations:(CIFaceFeature *)face usingTransform:(CGAffineTransform)transform
{
    if (face.hasMouthPosition) {
        CGRect faceBoundsTransformed = CGRectStandardize(CGRectApplyAffineTransform(face.bounds, transform));
        CGPoint mouthPositionTransformed = CGPointApplyAffineTransform(face.mouthPosition, transform);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[self mouthColor] setStroke];
        
        CGFloat mouthWidth = faceBoundsTransformed.size.width/4;
        CGFloat mouthHeight = mouthWidth/4;
        
        if (face.hasSmile) {
            NSLog(@":) Has smile! :)");
            CGFloat mouthHeightOffset = mouthHeight;    // to account for curvature of smile
            UIBezierPath *path = [[UIBezierPath alloc] init];
            
            // Upper curve
            [path moveToPoint:CGPointMake(mouthPositionTransformed.x - mouthWidth/2,
                                          mouthPositionTransformed.y - mouthHeight/2 - mouthHeightOffset)];

            [path addQuadCurveToPoint:CGPointMake(mouthPositionTransformed.x + mouthWidth/2,
                                                  path.currentPoint.y)
                         controlPoint:CGPointMake(mouthPositionTransformed.x,
                                                  path.currentPoint.y + 2*mouthHeight)];
            
            // Right edge
            [path addLineToPoint:CGPointMake(mouthPositionTransformed.x + mouthWidth/2,
                                             mouthPositionTransformed.y + mouthHeight/2 - mouthHeightOffset)];

            // Lower curve
            [path addQuadCurveToPoint:CGPointMake(mouthPositionTransformed.x - mouthWidth/2,
                                                  path.currentPoint.y)
                         controlPoint:CGPointMake(mouthPositionTransformed.x,
                                                  path.currentPoint.y + 2*mouthHeight)];
            
            // Left edge
            [path closePath];
            [path stroke];
        } else {
            // No smile
            CGRect mouthRect = CGRectMake(mouthPositionTransformed.x - mouthWidth/2,
                                          mouthPositionTransformed.y - mouthHeight/2,
                                          mouthWidth,
                                          mouthHeight);
            
            CGContextStrokeRect(context, mouthRect);
        }
    }
}


#pragma mark - Scoring

// I could have grafted scoring onto drawing, but separated for maintainability and legibility

// Score annotations and set into dictionary
+ (int)scoreAnnotations:(NSArray *)faces info:(NSMutableDictionary *)info
{
    // To communicate face annotation details
    NSMutableArray *faceAnnotations = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *totalScoreDescription = [[NSMutableDictionary alloc] init];
    int totalScore = 0;
    
    int positiveFaces = 0;  // count number of positive faces
    for (CIFaceFeature *face in faces)
    {
        int faceScore = [self scoreFaceAnnotations:face andSet:faceAnnotations];
        totalScore += faceScore;
        if (faceScore > 0) positiveFaces++;
    }
    
    if (![faces count]) {
        totalScore += SCORE_NO_FACES_PENALTY;
        [totalScoreDescription setValue:[NSNumber numberWithInteger:SCORE_NO_FACES_PENALTY]
                                 forKey:[NSString stringWithFormat:@"Where are the faces?"]];
    } else if ([faces count] >= 10) {
        totalScore += SCORE_TOO_MANY_FACES_PENALTY;
        [totalScoreDescription setValue:[NSNumber numberWithInteger:SCORE_TOO_MANY_FACES_PENALTY]
                                 forKey:[NSString stringWithFormat:@"Way too many faces for a good mug shot"]];
    } else {
        totalScore += SCORE_FACE_BONUS * [faces count];
        [totalScoreDescription setValue:[NSNumber numberWithInteger:SCORE_FACE_BONUS * [faces count]]
                                 forKey:[NSString stringWithFormat:@"%lu faces recognized", SCORE_FACE_BONUS * [faces count]]];
        
        if (!positiveFaces) {
            totalScore += SCORE_NO_POSITIVE_FACES_PENALTY;
            [totalScoreDescription setValue:[NSNumber numberWithInteger:SCORE_NO_POSITIVE_FACES_PENALTY]
                                     forKey:[NSString stringWithFormat:@"No positive scoring faces!"]];
        } else {
            totalScore += SCORE_POSITIVE_FACE_BONUS * positiveFaces;
            [totalScoreDescription setValue:[NSNumber numberWithInteger:SCORE_POSITIVE_FACE_BONUS * positiveFaces]
                                     forKey:[NSString stringWithFormat:@"%d positive scoring faces bonus", positiveFaces]];
            
            if (positiveFaces == [faces count]) {
                totalScore += SCORE_ALL_POSITIVE_FACE_BONUS;
                [totalScoreDescription setValue:[NSNumber numberWithInteger:SCORE_ALL_POSITIVE_FACE_BONUS]
                                         forKey:[NSString stringWithFormat:@"All %d faces in mug are positive scoring", positiveFaces]];
            }
        }
    }
    
    [info setValue:[NSNumber numberWithInteger:totalScore] forKey:MUGGER_SCORE_TOTAL];
    [info setValue:totalScoreDescription forKey:MUGGER_SCORE_TOTAL_DESC];
    
    [info setValue:faceAnnotations forKey:MUGGER_ANNOTATIONS_FACES];
    
    return totalScore;
}

+ (int)scoreFaceAnnotations:(CIFaceFeature *)face andSet:(NSMutableArray *)facesArray
{
    NSMutableDictionary *faceDictionary = [[NSMutableDictionary alloc] init];
    
    int faceScore = 0;
    NSMutableDictionary *faceScoreDescription = [[NSMutableDictionary alloc] init];
    
    if (face.hasFaceAngle) {
        [faceDictionary setValue:[NSNumber numberWithFloat:face.faceAngle]
                          forKey:MUGGER_FACE_ANGLE];
        
        faceScore += SCORE_FACE_ANGLE_BONUS;
        [faceScoreDescription setValue:[NSNumber numberWithInteger:SCORE_FACE_ANGLE_BONUS]
                                forKey:[NSString stringWithFormat:@"Has face angle of %g", face.faceAngle]];
    }
    
    faceScore += [self scoreEyesAnnotations:face andSet:faceDictionary];
    faceScore += [self scoreMouthAnnotations:face andSet:faceDictionary];
    
    [faceDictionary setValue:[NSNumber numberWithInteger:faceScore] forKey:MUGGER_FACE_SCORE];
    [faceDictionary setValue:faceScoreDescription forKey:MUGGER_FACE_SCORE_DESC];
    
    [facesArray addObject:faceDictionary];

    return faceScore;
}

+ (int)scoreEyesAnnotations:(CIFaceFeature *)face andSet:(NSMutableDictionary *)faceDictionary
{
    int eyeScore = 0;
    NSMutableDictionary *eyesScoreDescription = [[NSMutableDictionary alloc] init];
    
    int eyesCount = 0;
    int openEyesCount = 0;
    if (face.hasLeftEyePosition) {
        [faceDictionary setValue:[NSNumber numberWithBool:!face.leftEyeClosed]
                          forKey:MUGGER_FACE_LEFT_EYE_IS_OPEN];
        eyesCount++;
        if (!face.leftEyeClosed) openEyesCount++;
    }
    if (face.hasRightEyePosition) {
        [faceDictionary setValue:[NSNumber numberWithBool:!face.rightEyeClosed]
                          forKey:MUGGER_FACE_RIGHT_EYE_IS_OPEN];
        eyesCount++;
        if (!face.rightEyeClosed) openEyesCount++;
    }
    
    if (eyesCount == 0) {
        eyeScore += SCORE_EYES_MISSING_PENALTY;
        [eyesScoreDescription setValue:[NSNumber numberWithInteger:SCORE_EYES_MISSING_PENALTY]
                                forKey:[NSString stringWithFormat:@"Woa, no eyes..."]];
    } else {
        eyeScore += SCORE_EYES_BONUS * eyesCount;
        [eyesScoreDescription setValue:[NSNumber numberWithInteger:SCORE_EYES_BONUS * eyesCount]
                                 forKey:[NSString stringWithFormat:@"Eyes found"]];
        
        if (openEyesCount == 0) {
            eyeScore += SCORE_EYES_BOTH_CLOSED_PENALTY;
            [eyesScoreDescription setValue:[NSNumber numberWithInteger:SCORE_EYES_BOTH_CLOSED_PENALTY]
                                    forKey:[NSString stringWithFormat:@"Eyes closed"]];
        } else if (openEyesCount == 1) {
            eyeScore += SCORE_EYES_WINK_BONUS;
            [eyesScoreDescription setValue:[NSNumber numberWithInteger:SCORE_EYES_WINK_BONUS]
                                    forKey:[NSString stringWithFormat:@"Wink! ;)"]];
        } else if (openEyesCount == 2) {
            eyeScore += SCORE_EYES_BOTH_OPEN_BONUS;
            [eyesScoreDescription setValue:[NSNumber numberWithInteger:SCORE_EYES_BOTH_OPEN_BONUS]
                                    forKey:[NSString stringWithFormat:@"Eyes open"]];
        }
        
    }
    
    [faceDictionary setValue:[NSNumber numberWithInteger:eyeScore] forKey:MUGGER_FACE_EYES_SCORE];
    [faceDictionary setValue:eyesScoreDescription forKey:MUGGER_FACE_EYES_SCORE_DESC];
    
    return eyeScore;
}

+ (int)scoreMouthAnnotations:(CIFaceFeature *)face andSet:(NSMutableDictionary *)faceDictionary
{
    int mouthScore = 0;
    NSMutableDictionary *mouthScoreDescription = [[NSMutableDictionary alloc] init];

    if (face.hasMouthPosition) {
        [faceDictionary setValue:[NSNumber numberWithBool:face.hasSmile]
                          forKey:MUGGER_FACE_MOUTH_IS_SMILING];
        
        mouthScore += SCORE_MOUTH_BONUS;
        [mouthScoreDescription setValue:[NSNumber numberWithInteger:SCORE_MOUTH_BONUS]
                                 forKey:[NSString stringWithFormat:@"Mouth found"]];
        
        if (face.hasSmile) {
            mouthScore += SCORE_MOUTH_SMILE_BONUS;
            [mouthScoreDescription setValue:[NSNumber numberWithInteger:SCORE_MOUTH_SMILE_BONUS]
                                     forKey:[NSString stringWithFormat:@"Smile! :)"]];
        }
    } else {
        mouthScore += SCORE_MOUTH_MISSING_PENALTY;
        [mouthScoreDescription setValue:[NSNumber numberWithInteger:SCORE_MOUTH_MISSING_PENALTY]
                                 forKey:[NSString stringWithFormat:@"Missing mouth"]];
    }
    
    [faceDictionary setValue:[NSNumber numberWithInteger:mouthScore] forKey:MUGGER_FACE_MOUTH_SCORE];
    [faceDictionary setValue:mouthScoreDescription forKey:MUGGER_FACE_MOUTH_SCORE_DESC];


    return mouthScore;
}



#pragma mark - Colors for annotations
+ (UIColor *)eyeColor
{
    return [UIColor yellowColor];
}
+ (UIColor *)mouthColor
{
    return [UIColor greenColor];
}
+ (UIColor *)faceBoundsColor
{
    return [UIColor redColor];
}
+ (UIColor *)scoreColor:(int)score
{
    UIColor *color;
    
    if (score < 0) {
        color = [UIColor redColor];
    } else if (score < 10) {
        color = [UIColor orangeColor];
    } else if (score < 25) {
        color = [UIColor yellowColor];
    } else if (score < 40) {
        color = [UIColor cyanColor];
    } else if (score < 55) {
        color = [UIColor blueColor];
    } else if (score < 70) {
        color = [UIColor greenColor];
    } else if (score < 85) {
        color = [UIColor magentaColor];
    } else {
        color = [UIColor purpleColor];
    }
    
    return color;
}
@end
