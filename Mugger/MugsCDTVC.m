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
#import "ImageAnalysis.h"

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
    
    // Let's make sure to handle our action sheets and popovers
    [self dismissExistingActionSheet];
    [self dismissExistingPopover];
    self.mug = nil;
    self.library = nil;
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
    
    if ([mug.title length]) {
        cell.textLabel.text = mug.title;
    } else {
        cell.textLabel.text = @"Untitled";
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Mugger score: %@", mug.score];
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
            [actionSheet showFromBarButtonItem:self.addMugBarButton animated:YES];            
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
                self.mug = [Mug mugWithURL:url
                                   forUser:self.user
                    inManagedObjectContext:self.user.managedObjectContext];
                if (self.mug) {
                    // If split view, we present mug to detail view - otherwise push segue
                    if (![self presentMugToDetailView:self.mug]) {
                        [self performSegueWithIdentifier:@"Show Mugger From ImagePicker" sender:picker];
                    }
                }
            } else {
                NSLog(@"[%@ %@] Error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error description]);
                return;
            }
        }];
    if (self.popover) {
        [self dismissExistingPopover];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.popover) {
        [self dismissExistingPopover];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissExistingPopover];
}


#pragma mark - Navigation

// prepares the given ShowMuggerViewController to show the given mug
// used either when segueing to an ShowMuggerViewController
//   or when our UISplitViewController's Detail view controller is an ShowMuggerViewController

- (void)prepareShowMuggerViewController:(ShowMuggerViewController *)smvc toDisplayMug:(Mug *)mug
{
    smvc.mug = mug;
    smvc.title = [NSString stringWithFormat:@"Mug for %@", self.user.name];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[ShowMuggerViewController class]]) {
    
        Mug *mug;
        if ([segue.identifier isEqualToString:@"Show Mugger From ImagePicker"] &&
            [sender isKindOfClass:[UIImagePickerController class]]) {
            
            // Image picker has stored the mug to use for us temporarily
            mug = self.mug;
            self.mug = nil;
        } else if ([segue.identifier isEqualToString:@"Show Mugger From Mug Cell"] &&
                   [sender isKindOfClass:[UITableViewCell class]]) {
            // Mug can be found from table cell
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            if (indexPath) {
                mug = [self.fetchedResultsController objectAtIndexPath:indexPath];
            }
        }
        
        if (mug) {
            [self prepareShowMuggerViewController:segue.destinationViewController toDisplayMug:mug];
        }
    }
}


#pragma mark - UITableViewDelegate

// when a row is selected and we are in a UISplitViewController,
//   this updates the Detail ShowMuggerViewController (instead of segueing to it)
// knows how to find an ShowMuggerViewController inside a UINavigationController in the Detail too
// otherwise, this does nothing (because detail will be nil and not "isKindOfClass:" anything)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Mug *mug = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self presentMugToDetailView:mug];
}

// Returns YES if we successfully present mug to detail view
- (BOOL)presentMugToDetailView:(Mug *)mug
{
    // nil if not in UISplitViewController
    id detail = self.splitViewController.viewControllers[1];
    if ([detail isKindOfClass:[UINavigationController class]]) {
        detail = [((UINavigationController *)detail).viewControllers firstObject];
    }
    
    if ([detail isKindOfClass:[ShowMuggerViewController class]]) {
        [self prepareShowMuggerViewController:detail toDisplayMug:mug];
        return YES;
    }
    return NO;
}

// For allowing deletes
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES - we will be able to delete all rows
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // This check isn't strictly necessary since we only allow deletes, but doing it anyway
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Mug *mug = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        // Before deleting, we'll go one extra step and clear it out from detail (if applicable)
        id detail = self.splitViewController.viewControllers[1];
        if ([detail isKindOfClass:[UINavigationController class]]) {
            detail = [((UINavigationController *)detail).viewControllers firstObject];
        }
        
        if ([detail isKindOfClass:[ShowMuggerViewController class]]) {
            ShowMuggerViewController *smvc = (ShowMuggerViewController *)detail;
            if ([mug isEqual:smvc.mug]) {
                smvc.mug = nil;
            }
        }
        
        // Now clean!
        [mug.managedObjectContext deleteObject:mug];
    }
}

@end
