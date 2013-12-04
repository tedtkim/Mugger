//
//  ShowMuggerViewController.m
//  Mugger
//
//  Created by Ted Kim on 12/4/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "ShowMuggerViewController.h"
#import "UIImage+CS193p.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ShowMuggerViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *mugTitle;
@property (weak, nonatomic) IBOutlet UILabel *mugScore;
@property (nonatomic, strong) ALAssetsLibrary *library;
@end

@implementation ShowMuggerViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getMug];
    self.mugTitle.delegate = self;
}

// Setup notification observers to check when title is updated
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(titleChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.mugTitle];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:self.mugTitle];
    [super viewWillDisappear:animated];
    self.library = nil; // TODO: needs to be singleton?
}

// Here's where we'll update title - it might seem a lot, but it's just a title
- (void)titleChanged:(NSNotification *)notification
{
    self.mug.title = self.mugTitle.text;
}


#pragma mark - Properties

- (ALAssetsLibrary *)library
{
    if (!_library) _library = [[ALAssetsLibrary alloc] init];
    return _library;
}


#pragma mark - Getting Mug

- (void)getMug
{
    // A bit ungainly, but necessary to grab image from AssetURL
    // TODO: asynchronous - perhaps add activity indicators
    [self.library assetForURL:[NSURL URLWithString:self.mug.mugURL]
                  resultBlock:^(ALAsset *asset) {
                      ALAssetRepresentation *rep = [asset defaultRepresentation];
                      if(rep) {
                          CGImageRef imageRef = [rep fullResolutionImage];
                          [self showMugWithImage:[UIImage imageWithCGImage:imageRef]];
                      }
                  }
                 failureBlock:^(NSError *error) {
                     if (error) {
                         NSLog(@"[%@ %@] Couldn't grab assetURL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
                     }
                 }];
    
    //self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.mug.mugURL]]];
    //NSData *tempData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.mug.mugURL]];
    //NSLog(@"Mug URL: %@", self.mug.mugURL);
    //NSLog(@"Mug Data from URL: %@", tempData);

}

// Convenience method for easier maintenance
- (void)showMugWithImage:(UIImage *)image
{
    self.imageView.image = image;
    
    // Set thumbnail
    if (!self.mug.thumbnailData) {
        UIImage *thumbnail = [self.imageView.image imageByScalingToSize:CGSizeMake(75, 75)];
        self.mug.thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0);
    }
    // Display title & score
    if (self.mug.title) {
        // TODO: attributed string?
        self.mugTitle.text = self.mug.title;
    }
    if (self.mug.score.intValue == 0) {
        // TODO: attributed string?
        self.mugScore.text = [NSString stringWithFormat:@"%d", self.mug.score.intValue];
    } else {
        [self calculateScore];
    }
}

- (void)calculateScore
{
    NSLog(@"Must calculate score!");
}

// TODO: may not be necessary
#pragma mark - Save Mug
- (IBAction)saveMug:(UIBarButtonItem *)sender {

}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder]; // make "return key" hide keyboard
    return YES;
}

@end
