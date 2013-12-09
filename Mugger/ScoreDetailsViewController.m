//
//  ScoreDetailsViewController.m
//  Mugger
//
//  Created by Ted Kim on 12/8/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "ScoreDetailsViewController.h"
#import "ImageAnalysis.h"

@interface ScoreDetailsViewController ()
@property (weak, nonatomic) IBOutlet UITextView *body;

@end

@implementation ScoreDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.body.autoresizingMask = (UIViewAutoresizingFlexibleHeight);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self updateUI];
}

- (void)updateUI
{
    //[self.body.textStorage setAttributedString:self.strToShow];
    //CGFloat height = [self textViewHeightForAttributedText:self.body.attributedText andWidth:self.body.frame.size.width];
    //self.body.frame = CGRectMake(self.body.frame.origin.x, self.body.frame.origin.y, self.body.frame.size.width, height);
    //NSLog(@"Initial content size: %@", NSStringFromCGSize(self.preferredContentSize));
    //self.preferredContentSize = CGSizeMake(self.view.frame.size.width, height);
    //NSLog(@"AFTER setting content size: %@", NSStringFromCGSize(self.preferredContentSize));
}

// Model is set!
- (void)setImageInfo:(NSDictionary *)imageInfo
{
    _imageInfo = imageInfo;
    
    NSLog(@"setImageInfo");
    NSAttributedString *value = [self getCombinedScoring];
    
    [self.body.textStorage setAttributedString:value];

}

#pragma mark - UITextViewDelegate

/* TODO:
// to adjust height
- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"textViewDidChange");
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
}
*/

#pragma mark - Form attributed string

- (NSAttributedString *)getCombinedScoring
{
    NSMutableAttributedString *value = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    NSDictionary *attrForCombined = @{ NSStrokeWidthAttributeName : @-2,
                                       NSForegroundColorAttributeName : [UIColor blackColor],
                                       NSFontAttributeName: font};
    
    NSDictionary *combinedDictionary = [self.imageInfo valueForKey:MUGGER_SCORE_TOTAL_DESC];
    [value appendAttributedString:[self getTextFromDescription:combinedDictionary attributes:attrForCombined]];
    
    // Now get each face
    NSArray *facesInfo = [self.imageInfo valueForKey:MUGGER_ANNOTATIONS_FACES];
    if ([facesInfo count]) {
        // One more line, to separate main from the faces
        [value appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"
                                                                             attributes:attrForCombined]];
    }
    int faceNumber = 1;
    for (NSDictionary *faceInfo in facesInfo) {
        NSNumber *faceScore = [faceInfo valueForKey:MUGGER_FACE_SCORE];
        [value appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Face #%d score: %d", faceNumber, faceScore.intValue]
                                                                             attributes:attrForCombined]];
        [value appendAttributedString:[self getFaceScoring:faceInfo]];
        faceNumber++;
    }
    
    return value;
}

- (NSAttributedString *)getFaceScoring:(NSDictionary *)description
{
    NSDictionary *faceScoringDescription = [description valueForKey:MUGGER_FACE_SCORE_DESC];
    NSDictionary *angleScoringDescription = [description valueForKey:MUGGER_FACE_ANGLE_SCORE_DESC];
    
    NSMutableAttributedString *value = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    // Indent for these sub-guys
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 29;
    paragraphStyle.firstLineHeadIndent = 29;
    
    NSDictionary *attrForFace = @{ NSStrokeWidthAttributeName : @-1,
                                   NSForegroundColorAttributeName : [ImageAnalysis faceBoundsColor],
                                   NSFontAttributeName: font,
                                   NSParagraphStyleAttributeName: paragraphStyle};
    
    // Add a new line above each face
    [value appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"
                                                                         attributes:attrForFace]];
    
    [value appendAttributedString:[self getTextFromDescription:faceScoringDescription attributes:attrForFace]];
    [value appendAttributedString:[self getTextFromDescription:angleScoringDescription attributes:attrForFace]];
    
    [value appendAttributedString:[self getEyesScoring:description]];
    [value appendAttributedString:[self getMouthScoring:description]];
    
    return value;
}

- (NSAttributedString *)getEyesScoring:(NSDictionary *)description
{
    NSDictionary *eyeScoringDescription = [description valueForKey:MUGGER_FACE_EYES_SCORE_DESC];
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    // Indent for these sub-guys
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 29;
    paragraphStyle.firstLineHeadIndent = 29;
    
    NSDictionary *attrForEyes = @{ NSStrokeWidthAttributeName : @-1,
                                   NSForegroundColorAttributeName : [ImageAnalysis eyeColor],
                                   NSFontAttributeName: font,
                                   NSParagraphStyleAttributeName: paragraphStyle};
    
    return [self getTextFromDescription:eyeScoringDescription attributes:attrForEyes];
}

- (NSAttributedString *)getMouthScoring:(NSDictionary *)description
{
    NSDictionary *mouthScoringDescription = [description valueForKey:MUGGER_FACE_MOUTH_SCORE_DESC];
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    // Indent for these sub-guys
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 29;
    paragraphStyle.firstLineHeadIndent = 29;
    
    NSDictionary *attrForMouth = @{ NSStrokeWidthAttributeName : @-1,
                                    NSForegroundColorAttributeName : [ImageAnalysis mouthColor],
                                    NSFontAttributeName: font,
                                    NSParagraphStyleAttributeName: paragraphStyle};
    
    return [self getTextFromDescription:mouthScoringDescription attributes:attrForMouth];
}

// Actual helper method that sorts and prints attributed string
- (NSAttributedString *)getTextFromDescription:(NSDictionary *)description attributes:(NSDictionary *)attr
{
    NSMutableAttributedString *value = [[NSMutableAttributedString alloc] init];
    
    for (NSString *key in [description keysSortedByValueUsingSelector:@selector(compare:)]) {
        int score = [[description valueForKey:key] intValue];
        
        NSString *prefix;
        if (score > 0) prefix = [NSString stringWithFormat:@"+"];
        else prefix = [NSString stringWithFormat:@""];
        
        NSString *text = [NSString stringWithFormat:@"%@%d:\t%@\n", prefix, score, key];
        [value appendAttributedString:[[NSMutableAttributedString alloc] initWithString:text
                                                                             attributes:attr]];
    }
    return value;
}



#pragma mark - Sizing

- (CGFloat)textViewHeightWithSetWidth:(CGFloat)width
{
    NSAttributedString *text = self.body.attributedText;
    UITextView *textView = [[UITextView alloc] init];
    [textView setAttributedText:text];
    CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}

@end
