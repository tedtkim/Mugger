//
//  ShowMuggerViewController.m
//  Mugger
//
//  Created by Ted Kim on 12/4/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "ShowMuggerViewController.h"
#import "ScoreDetailsViewController.h"
#import "UIImage+CS193p.h"
#import "ImageAnalysis.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ShowMuggerViewController () <UITextFieldDelegate, UISplitViewControllerDelegate>

// UI Controls
@property (weak, nonatomic) IBOutlet UITextField *mugTitle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *originalOrEnhanced;
@property (weak, nonatomic) IBOutlet UISwitch *annotationToggle;

// UI to update
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImageView *overlayImageView;  // For annotations
@property (weak, nonatomic) IBOutlet UILabel *mugScore;

// Other properties
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (strong, nonatomic) NSDictionary *imageInfo;  // From ImageAnalysis
// this is weak because we want it to go back to nil
//   when no one else has strong pointer to the popover (i.e. it is dismissed)
@property (weak, nonatomic) UIPopoverController *scoreDetailsPopoverController;

// iPad UI to allow easier viewing of controls without hiding picture
@property (weak, nonatomic) IBOutlet UIView *bottomViewForUI;

// TODO @property (nonatomic, weak) UIActionSheet *actionSheetFilter;
// TODO @property (nonatomic, strong) NSArray *filters; // of CIFilter
@end

@implementation ShowMuggerViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];

}

// Initial setup code to initialize delegates and disable controls
- (void)setup
{
    self.mugTitle.delegate = self;
    self.view.hidden = YES;
    [self enableUIControls:NO];
    
    // We allow selecting user from master view in portrait mode
    // TODO: test in iphone
    if (self.splitViewController && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        NSLog(@"We're in IPAD");
        // This performSelector causes memory leak warning, since compiler doesn't know
        // if any object is being allocated.  We know it's not (we're simply performing
        // the leftBarButtonItem's action), so we ignore this explicitly.
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.navigationItem.leftBarButtonItem.target performSelector:self.navigationItem.leftBarButtonItem.action withObject:self.navigationItem afterDelay:0.0];
        #pragma clang diagnostic pop
    }
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

// We do this to set semi-transparent background colors for UI controls at top at bottom, in landscape mode of iPad
// Let's have some fun and animate it :)
- (void)viewWillLayoutSubviews
{
    // I considered doing this in willRotateToInterfaceOrientation, but decided against it to cover for initial load case
    [super viewWillLayoutSubviews];
    
    if (self.bottomViewForUI) {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            [UIView animateWithDuration:0.2 animations:^{
                self.bottomViewForUI.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
            } completion:NULL];
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                self.bottomViewForUI.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8f];
            } completion:NULL];
        }
    }
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{

}

// Here's where we'll update title - it might seem a lot, but it's just a title
- (void)titleChanged:(NSNotification *)notification
{
    self.mug.title = self.mugTitle.text;
}


#pragma mark - Properties

// lazy instantiation
- (ALAssetsLibrary *)library
{
    if (!_library) _library = [[ALAssetsLibrary alloc] init];
    return _library;
}

- (UIImageView *)overlayImageView
{
    if (!_overlayImageView) {
        _overlayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0,
                                                                          self.imageView.frame.size.width,
                                                                          self.imageView.frame.size.height)];
        [self.imageView addSubview:_overlayImageView];
        self.overlayImageView.layer.borderColor = [[UIColor purpleColor] CGColor];
        self.overlayImageView.layer.borderWidth = 2.0;
        self.overlayImageView.contentMode = UIViewContentModeScaleToFill;
    }
    return _overlayImageView;
}

// When a new mug is set as model
- (void)setMug:(Mug *)mug
{
    _mug = mug;
    
    // TODO: not needed!
    // Must dismiss popover if master changes mug
    //[self.scoreDetailsPopoverController dismissPopoverAnimated:YES];
    
    if (mug) {
        self.view.hidden = NO;
        [self enableUIControls:YES];
        
        // Back to defaults
        self.originalOrEnhanced.selectedSegmentIndex = 0;
        self.overlayImageView.hidden = YES;
        self.annotationToggle.on = NO;
        [self getMug];
    } else {
        self.imageView.image = nil;
        self.view.hidden = YES;
    }
}


/* TODO: if using filters later
- (void)setFilters:(NSArray *)filters
{
    _filters = filters;
    self.filtersButton.enabled = filters ? [filters count] : NO;
}
 */

#pragma mark - Getting Mug

- (void)getMug
{
    // A bit ungainly, but necessary to grab image from AssetURL
    // TODO: asynchronous - perhaps add activity indicators
    [self.library assetForURL:[NSURL URLWithString:self.mug.mugURL]
                  resultBlock:^(ALAsset *asset) {
                      ALAssetRepresentation *rep = [asset defaultRepresentation];
                      if (rep) {
                          CGImageRef imageRef = [rep fullResolutionImage];
                          CGImageRef thumbnailRef = NULL;
                          
                          if (!self.mug.thumbnailData) {
                              // Handy - don't have to make one ourselves!
                              thumbnailRef = [asset thumbnail];
                          }
                          
                          // Retrieve the image orientation from the ALAsset
                          UIImageOrientation orientation = UIImageOrientationUp;
                          NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
                          if (orientationValue) {
                              orientation = [orientationValue intValue];
                          }
                          
                          [self showMugWithImage:[UIImage imageWithCGImage:imageRef
                                                                     //scale:scaleRatio
                                                                     scale:1.0
                                                               orientation:orientation]
                                       thumbnail:[UIImage imageWithCGImage:thumbnailRef]];
                      }
                  }
                 failureBlock:^(NSError *error) {
                     if (error) {
                         NSLog(@"[%@ %@] Couldn't grab assetURL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
                     }
                 }];
}

// Convenience method for easier maintenance
- (void)showMugWithImage:(UIImage *)image thumbnail:(UIImage *)thumbnail
{
    self.imageView.image = image;
    
    // Set thumbnail
    if (!self.mug.thumbnailData && thumbnail) {
        self.mug.thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0);
    }
    // Display title & score
    if (self.mug.title) {
        self.mugTitle.text = self.mug.title;
    }

    self.imageInfo = [ImageAnalysis analyzeImage:image];
    
    
    NSNumber *score = [self.imageInfo valueForKey:MUGGER_SCORE_TOTAL];
    UIColor *scoreColor = [ImageAnalysis scoreColor:[score intValue]];
    
    NSDictionary *attrForCombined = @{ NSForegroundColorAttributeName : scoreColor,
                                       NSStrokeColorAttributeName : [UIColor blackColor],
                                       NSStrokeWidthAttributeName : @-4};
    
    self.mugScore.attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", [score intValue]]
                                                                          attributes:attrForCombined];
    
    self.view.backgroundColor = [scoreColor colorWithAlphaComponent:0.5f];
}

/* TODO
- (void)calculateScore:(UIImage *)image
{
    self.filters = [ImageAnalysis analyzeImage:image];
    
    CIImage* ciImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    for (CIFilter *filter in self.filters) {
        [filter setValue:ciImage forKey:kCIInputImageKey];
        //ciImage = filter.outputImage;
    }
    // TODO: Perhaps launch in asynchronous thread
}
*/


// TODO: may not be necessary
#pragma mark - Edit Title
- (IBAction)editTitle:(UIBarButtonItem *)sender {
}

// Switch to toggle annotations
- (IBAction)toggleAnnotationSwitch:(UISwitch *)sender {
    [self toggleAnnotationSwitchTo:sender.on];
}

// Doing this to allow for gesture calling programmatically
- (void)toggleAnnotationSwitchTo:(BOOL)isOn
{
    if (isOn) {
        self.overlayImageView.image = [self.imageInfo valueForKey:MUGGER_ANNOTATIONS];
        self.overlayImageView.hidden = NO;
    } else {
        self.overlayImageView.hidden = YES;
    }
}

- (IBAction)selectOriginalOrEnhanced:(UISegmentedControl *)sender {
    NSString *selected = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
    NSString *key;
    
    if ([selected isEqualToString:@"Original"]) {
        key = MUGGER_ORIGINAL_IMAGE;
    } else if ([selected isEqualToString:@"Enhanced"]) {
        key = MUGGER_ENHANCED_IMAGE;
    }
    
    if (key) self.imageView.image = [self.imageInfo valueForKey:key];
}


#pragma mark - Gestures

// Fun gestures to toggle annotations switch on or off
- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    if (self.annotationToggle.enabled && self.annotationToggle.on) {
        [self.annotationToggle setOn:NO animated:YES];
        [self toggleAnnotationSwitchTo:NO];
    }
}
- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    if (self.annotationToggle.enabled && !self.annotationToggle.on) {
        [self.annotationToggle setOn:YES animated:YES];
        [self toggleAnnotationSwitchTo:YES];
    }
}

// If user long presses on image while annotations are on, let's
// show them some details about the score!
- (IBAction)longPress:(UILongPressGestureRecognizer *)sender {
    if (self.annotationToggle.on && !self.scoreDetailsPopoverController) {
        if (self.imageInfo) {
            [self performSegueWithIdentifier:@"Show Score Details" sender:self];
        }
    }
}


#pragma mark - Helper Methods

// Enable/disable UI Controls
- (void)enableUIControls:(BOOL)enable
{
    self.mugTitle.enabled = enable;
    self.annotationToggle.enabled = enable;
    self.originalOrEnhanced.enabled = enable;
}

- (BOOL)isIpad
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

/* TODO: if using filters later
#pragma mark - Filter image, with UIActionSheetDelegate

// Using UIActionSheet
- (IBAction)filterImage:(UIButton *)sender {
    // TODO: First, dismiss action sheet it exists already
    //[self dismissExistingActionSheet];
 
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Filter"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    for (CIFilter *filter in self.filters) {
        [actionSheet addButtonWithTitle:filter.name];
    }
    
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.cancelButtonIndex = [self.filters count];
    
    if ([self isIpad]) {
        [actionSheet showFromRect:self.filtersButton.frame inView:self.view animated:YES];
    } else {
        [actionSheet showInView:self.view];
    }
    self.actionSheetFilter = actionSheet;
 
}

// Present image picker
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (![choice isEqualToString:@"Cancel"]) {
        for (CIFilter *filter in self.filters) {
            if ([choice isEqualToString:filter.name]) {
                self.imageView.image = [[UIImage alloc] initWithCIImage:filter.outputImage];
            }
        }
    }
}
*/

#pragma mark - Score Details
#define SCORE_DETAILS_POPOVER_WIDTH 300.0

// Specific to popover segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[ScoreDetailsViewController class]]) {
        ScoreDetailsViewController *scoreDetailsvc = (ScoreDetailsViewController *)segue.destinationViewController;
        // if we are segueing to a popover, the segue itself will be a UIStoryboardPopoverSegue
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
            self.scoreDetailsPopoverController = popoverSegue.popoverController;
        }
        
        scoreDetailsvc.imageInfo = self.imageInfo;

        // Let's do one more step on popover to size the height properly
        if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
            scoreDetailsvc.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight);
            CGFloat width = SCORE_DETAILS_POPOVER_WIDTH;
            CGSize size = CGSizeMake(width, [scoreDetailsvc textViewHeightWithSetWidth:width]);
            [self.scoreDetailsPopoverController setPopoverContentSize:size];
            NSLog(@"setting popover content size:%@", NSStringFromCGSize(size));
        }
    }
}

/* Note: since I'm doing a manual segue triggered by gesture to perform popover
 * segue, shouldPerformSegueWithIdentifer does not get called.
 * source: https://twitter.com/lucianboboc/statuses/271620542518419456
// don't show score details if it's already showing or we don't have one to show
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSLog(@"shouldPerformSegueWithIdentifier");
    if ([identifier isEqualToString:@"Show Score Details"]) {
        return self.scoreDetailsPopoverController ? NO : (self.imageInfo ? YES : NO);
    } else {
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}
 */

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder]; // make "return key" hide keyboard
    return YES;
}


#pragma mark - UISplitViewControllerDelegate

// this section added during Shutterbug demo

- (void)awakeFromNib
{
    self.splitViewController.delegate = self;
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = aViewController.title;
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}

@end
