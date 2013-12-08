//
//  ShowMuggerViewController.m
//  Mugger
//
//  Created by Ted Kim on 12/4/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "ShowMuggerViewController.h"
#import "UIImage+CS193p.h"
#import "ImageAnalysis.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ShowMuggerViewController () <UITextFieldDelegate, UISplitViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *mugTitle;
@property (weak, nonatomic) IBOutlet UILabel *mugScore;
@property (nonatomic, strong) ALAssetsLibrary *library;
// TODO @property (nonatomic, weak) UIActionSheet *actionSheetFilter;
// TODO @property (nonatomic, strong) NSArray *filters; // of CIFilter
@property (weak, nonatomic) IBOutlet UISwitch *annotationToggle;
@property (weak, nonatomic) IBOutlet UISegmentedControl *originalOrEnhanced;
@property (strong, nonatomic) NSDictionary *imageInfo;  // From ImageAnalysis
@property (strong, nonatomic) UIImageView *overlayImageView;  // For annotations
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
    NSLog(@"NEW Image's size: %@", NSStringFromCGSize(image.size));
    self.imageView.image = image;
    
    // Set thumbnail
    if (!self.mug.thumbnailData && thumbnail) {
        self.mug.thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0);
    }
    // Display title & score
    if (self.mug.title) {
        // TODO: attributed string?
        self.mugTitle.text = self.mug.title;
    }

    [self calculateScore:image];
}

- (void)calculateScore:(UIImage *)image
{
    NSLog(@"Calculate score!");
    /* TODO
    self.filters = [ImageAnalysis analyzeImage:image];
    
    CIImage* ciImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    for (CIFilter *filter in self.filters) {
        [filter setValue:ciImage forKey:kCIInputImageKey];
        //ciImage = filter.outputImage;
    }
     */
    
    // TODO: Perhaps launch in asynchronous thread
    self.imageInfo = [ImageAnalysis analyzeImage:image];
}

// TODO: may not be necessary
#pragma mark - Save Mug
- (IBAction)saveMug:(UIBarButtonItem *)sender {

}

// Switch to toggle annotations
- (IBAction)toggleAnnotationSwitch:(UISwitch *)sender {
    if (sender.on) {
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


#pragma mark - Helper Methods

// Enable/disable UI Controls
- (void)enableUIControls:(BOOL)enable
{
    self.mugTitle.enabled = enable;
    self.annotationToggle.enabled = enable;
    self.originalOrEnhanced.enabled = enable;
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

- (BOOL)isIpad
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
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
