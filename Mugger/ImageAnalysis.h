//
//  ImageAnalysis.h
//  Mugger
//
//  Created by Ted Kim on 12/6/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <Foundation/Foundation.h>

// keys to values in the image info dictionary
#define MUGGER_ORIGINAL_IMAGE @"originalImage"      // UIImage *
#define MUGGER_ENHANCED_IMAGE @"enhancedImage"      // UIImage *
#define MUGGER_ANNOTATIONS @"imageAnnotations"   // UIImage *

@interface ImageAnalysis : NSObject

// Returns info dictionary for analyzed image
+ (NSDictionary *)analyzeImage:(UIImage *)image;

@end
