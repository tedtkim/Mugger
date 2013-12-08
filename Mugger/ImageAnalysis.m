//
//  ImageAnalysis.m
//  Mugger
//
//  Created by Ted Kim on 12/6/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "ImageAnalysis.h"
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
    
    // Draw and set annotations
    UIImage *annotations = [self drawAnnotations:features info:info];
    [info setValue:annotations forKey:MUGGER_ANNOTATIONS];
    
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
    NSLog(@"Orientation: %d", orientation);
    return orientation;
}


#pragma mark - Drawing
// Draw annotations and return the image
+ (UIImage *)drawAnnotations:(NSArray *)faces info:(NSMutableDictionary *)info
{
    UIImage *origImage = [info valueForKey:MUGGER_ORIGINAL_IMAGE];
    NSLog(@"Orig image size: %@", NSStringFromCGSize(origImage.size));
    
    // Translate Core Image coordinates to UIKit's
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0, -origImage.size.height);
    
    // 0.0 properly handles for retina-displays
    //UIGraphicsBeginImageContextWithOptions(origImage.size, NO, 0.0);
    UIGraphicsBeginImageContext(origImage.size);
    
    for (CIFaceFeature *face in faces)
    {
        [self drawFaceAnnotations:face usingTransform:transform];
    }
    
    UIImage *annotations = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *orientedAnnotations = [UIImage imageWithCGImage:[annotations CGImage]
                                                       scale:1.0
                                                 orientation:[origImage imageOrientation]];
    NSLog(@"Annotation image size: %@", NSStringFromCGSize(orientedAnnotations.size));
    
    UIGraphicsEndImageContext();
    
    return orientedAnnotations;
}

+ (void)drawFaceAnnotations:(CIFaceFeature *)face usingTransform:(CGAffineTransform)transform
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw outline of face bounds
    [[UIColor redColor] setStroke];
    CGContextSetLineWidth(context, 2.0);
    
    CGRect faceBoundsTransformed = CGRectStandardize(CGRectApplyAffineTransform(face.bounds, transform));
    CGContextStrokeRect(context, faceBoundsTransformed);
    NSLog(@"Face bounds: %@", NSStringFromCGRect(faceBoundsTransformed));
    NSLog(@"Face origin: %@", NSStringFromCGPoint(faceBoundsTransformed.origin));
    NSLog(@"Face size: %@", NSStringFromCGSize(faceBoundsTransformed.size));
    
    [self drawEyeAnnotations:face usingTransform:transform];
    
    [self drawMouthAnnotations:face usingTransform:transform];
    
    if (face.hasFaceAngle)
        NSLog(@"Face angle: %g", face.faceAngle);
}

// Other drawing helpers
+ (void)drawEyeAnnotations:(CIFaceFeature *)face usingTransform:(CGAffineTransform)transform
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor yellowColor] setStroke];
    
    CGRect faceBoundsTransformed = CGRectStandardize(CGRectApplyAffineTransform(face.bounds, transform));
    
    CGFloat eyeWidth = faceBoundsTransformed.size.width/8;
    CGFloat eyeHeight;
    
    // Left
    if (face.hasLeftEyePosition) {
        CGPoint leftEyePositionTransformed = CGPointApplyAffineTransform(face.leftEyePosition, transform);
        
        NSLog(@"Left eye %g %g", leftEyePositionTransformed.x, leftEyePositionTransformed.y);
        
        if (face.leftEyeClosed) {
            NSLog(@"* Left eye closed!");
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
        
        NSLog(@"Right eye %g %g", rightEyePositionTransformed.x, rightEyePositionTransformed.y);
        
        if (face.rightEyeClosed) {
            eyeHeight = eyeWidth/4;
            NSLog(@"* Right eye closed!");
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
        [[UIColor greenColor] setStroke];
        
        CGFloat mouthWidth = faceBoundsTransformed.size.width/4;
        CGFloat mouthHeight = mouthWidth/4;
        NSLog(@"Mouth %g %g, width: %g, height: %g", mouthPositionTransformed.x, mouthPositionTransformed.y, mouthWidth, mouthHeight);
        
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

@end
