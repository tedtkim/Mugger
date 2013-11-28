//
//  MugsCDTVC.m
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "MugsCDTVC.h"
#import "Photo.h"


@implementation MugsCDTVC


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Photo Cell"];
    
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    if (photo.thumbnailData) {
        cell.imageView.image = [UIImage imageWithData:photo.thumbnailData];
    } else {
        NSLog(@"[%@ %@] photo does not have thumbnailData", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    }
    return cell;
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


#pragma mark - Navigation

// prepares the given ImageViewController to show the given photo
// used either when segueing to an ImageViewController
//   or when our UISplitViewController's Detail view controller is an ImageViewController

- (void)prepareImageViewController:(ImageViewController *)ivc toDisplayPhoto:(Photo *)photo
{
    ivc.imageURL = [NSURL URLWithString:photo.photoURL];
    ivc.title = photo.title;
    
    // Update recent photos
    [photo.managedObjectContext performBlock:^{
        photo.timeViewed = [NSDate date];
    }];
    
}

// In a story board-based application, you will often want to do a little preparation before navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath && [segue.identifier isEqualToString:@"Display Photo"]) {
            if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
                [self prepareImageViewController:segue.destinationViewController
                                  toDisplayPhoto:photo];
            }
        }
    }
}
*/

@end
