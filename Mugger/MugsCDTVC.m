//
//  MugsCDTVC.m
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "MugsCDTVC.h"
#import "Mug+Create.h"
#import "ShowMuggerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>   // kUTTypeImage
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

@interface MugsCDTVC () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>
@property (nonatomic, strong) NSDictionary *mugFetchers;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, weak) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIPopoverController *popover;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addMugBarButton;
@property (nonatomic, strong) Mug *mug; // For programmatic segue
@end

@implementation MugsCDTVC

#pragma mark - View Controller Lifecycle

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Let's make sure to handle our popovers
    [self dismissExistingActionSheet];
    [self dismissExistingPopover];
    self.mug = nil;
    self.library = nil; // TODO: needs to be singleton?
}

#pragma mark - Properties

// lazy instantiation
// Getter for the available image picker options
- (NSDictionary *)mugFetchers
{
    if (!_mugFetchers) {
        _mugFetchers = [[NSMutableDictionary alloc] init];
        
        NSDictionary *choices = @{ @"Camera" : [NSNumber numberWithInt:UIImagePickerControllerSourceTypeCamera],
                                   @"Photo Library" : [NSNumber numberWithInt:UIImagePickerControllerSourceTypePhotoLibrary],
                                   @"Saved Photos Album" : [NSNumber numberWithInt:UIImagePickerControllerSourceTypeSavedPhotosAlbum] };
        
        for (NSString *fetcher in choices) {
            NSNumber *sourceType = choices[fetcher];
            if ([UIImagePickerController isSourceTypeAvailable:sourceType.intValue]) {
                NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType.intValue];
                if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage]) {
                    [_mugFetchers setValue:sourceType forKey:fetcher];
                    /* Give choice for front/back as available?
                     if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
                     
                     }
                     */
                }
            }
        }
    }
    return _mugFetchers;
}

- (ALAssetsLibrary *)library
{
    if (!_library) _library = [[ALAssetsLibrary alloc] init];
    return _library;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Mug Cell"];
    
    Mug *mug = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = mug.title;
    cell.detailTextLabel.text = mug.subtitle;
    if (mug.thumbnailData) {
        cell.imageView.image = [UIImage imageWithData:mug.thumbnailData];
    }
    return cell;
}

- (BOOL)isIpad
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

#pragma mark - New Mug

// Using UIActionSheet to add new mug
- (IBAction)addMugBarButtonSelected:(UIBarButtonItem *)sender {
    // First, dismiss popovers if they exist already
    [self dismissExistingPopover];
    [self dismissExistingActionSheet];
    if (![self.mugFetchers count]) {
        // No mug fetchers available!
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Mug Fetchers Available"
                                                        message:@"No camera or photo albums are accessible on this device!"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add New Mug"
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        
        for (NSString *fetcher in [[self.mugFetchers allKeys] sortedArrayUsingSelector: @selector(compare:)]) {
            [actionSheet addButtonWithTitle:fetcher];
        }
        // Manually adding Cancel and setting cancel button index, so that we get benefit of
        // iOS 7 displaying mode for cancel and also support iPad popover dismissal.  Without this,
        // dismissing by clicking outside of popover crashes. Nice! :)
        [actionSheet addButtonWithTitle:@"Cancel"];
        actionSheet.cancelButtonIndex = [self.mugFetchers count];
        
        if ([self isIpad]) {
            [actionSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [actionSheet showInView:self.view];
        }
        self.actionSheet = actionSheet;
    }
}

- (void)dismissExistingPopover
{
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)dismissExistingActionSheet
{
    if (self.actionSheet) {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
    }
}


// Present image picker
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (![choice isEqualToString:@"Cancel"]) {
        NSNumber *sourceType = self.mugFetchers[choice];
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = sourceType.intValue;    // type enum
        NSString *desired = (NSString *)kUTTypeImage;
        
        if ([[UIImagePickerController availableMediaTypesForSourceType:picker.sourceType] containsObject:desired]) {
            picker.mediaTypes = @[desired];
            // Present picker
            picker.allowsEditing = YES;
            if ([self isIpad]) {
                // For camera, we prefer displaying in full-screen mode.  This is done just like iphone's modal presenter.
                if ([choice isEqualToString:@"Camera"]) {
                    [self presentViewController:picker animated:YES completion:NULL];
                } else {
                    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
                    [popover presentPopoverFromBarButtonItem:self.addMugBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                    popover.delegate = self;
                    self.popover = popover;
                }
            } else {
                [self presentViewController:picker animated:YES completion:NULL];
            }
        } else {
            NSLog(@"[%@ %@] Can't present desired media type!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
        NSLog(@"Source Type: %@, with enum value: %d", choice, sourceType.intValue);
    }
}


#pragma mark - New Mug - delegates

#define MUGGER_ALBUM_NAME @"Smart Little Mugger"
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Got the mug image!
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    [self.library saveImage:image
                    toAlbum:MUGGER_ALBUM_NAME
        withCompletionBlock:^(NSError *error, NSURL *url) {
            if (!error) {
                NSLog(@"Trying to save new mug with url: %@", url);
                self.mug = [Mug mugWithURL:url
                                   forUser:self.user
                    inManagedObjectContext:self.user.managedObjectContext];
                if (self.mug) [self performSegueWithIdentifier:@"Show Mugger" sender:picker];
                // TODO: can add activity indicator if takes too long
            } else {
                NSLog(@"[%@ %@] Error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error description]);
                return;
            }
        }];
    NSLog(@"imagePickerController didFinishPickingMediaWithInfo called!");
    if (self.popover) {
        [self dismissExistingPopover];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"imagePickerControllerDidCancel called!");
    if (self.popover) {
        [self dismissExistingPopover];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    NSLog(@"popoverControllerDidDismissPopover called!");
    [self dismissExistingPopover];
}


#pragma mark - Navigation

/* TODO: not needed yet
// prepares the given ShowMuggerViewController to show the given mug
// used either when segueing to an ShowMuggerViewController
//   or when our UISplitViewController's Detail view controller is an ShowMuggerViewController

- (void)prepareShowMuggerViewController:(ShowMuggerViewController *)smvc toDisplayMug:(Mug *)mug
{
    smvc.mug = mug;
}
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Mugger"] &&
        [segue.destinationViewController isKindOfClass:[ShowMuggerViewController class]]) {
        
        Mug *mug;
        if ([sender isKindOfClass:[UIImagePickerController class]]) {
            // Image picker has stored the mug to use for us temporarily
            mug = self.mug;
            self.mug = nil;
        } else if ([sender isKindOfClass:[UITableViewCell class]]) {
            // Mug can be found from table cell
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            if (indexPath) {
                mug = [self.fetchedResultsController objectAtIndexPath:indexPath];
            }
        }
        
        if (mug) {
            ShowMuggerViewController *smvc = segue.destinationViewController;
            smvc.mug = mug;
            // TODO [self prepareShowMuggerViewController:segue.destinationViewController toDisplayMug:mug];
        }
    }
}


/* TODO: Copied from Region
#pragma mark - UITableViewDelegate

// when a row is selected and we are in a UISplitViewController,
//   this updates the Detail ImageViewController (instead of segueing to it)
// knows how to find an ImageViewController inside a UINavigationController in the Detail too
// otherwise, this does nothing (because detail will be nil and not "isKindOfClass:" anything)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the Detail view controller in our UISplitViewController (nil if not in one)
    id detail = self.splitViewController.viewControllers[1];
    // if Detail is a UINavigationController, look at its root view controller to find it
    if ([detail isKindOfClass:[UINavigationController class]]) {
        detail = [((UINavigationController *)detail).viewControllers firstObject];
    }
    // is the Detail an ImageViewController?
    if ([detail isKindOfClass:[ImageViewController class]]) {
        // yes ... we know how to update that!
        Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self prepareImageViewController:detail toDisplayPhoto:photo];
    }
}



*/

@end
