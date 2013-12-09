//
//  ScoreDetailsViewController.h
//  Mugger
//
//  Created by Ted Kim on 12/8/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScoreDetailsViewController : UIViewController

// Model for this controller
@property (strong, nonatomic) NSDictionary *imageInfo;  // From ImageAnalysis

- (CGFloat)textViewHeightWithSetWidth:(CGFloat)width;
- (void)updateUI;

@end
