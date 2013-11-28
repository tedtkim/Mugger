//
//  UsersCDTVC.m
//  Mugger
//
//  Created by Ted Kim on 11/26/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "UsersCDTVC.h"
#import "MuggerDatabaseNames.h"
#import "User+Create.h"
#import "Photo.h"
#import "MugsCDTVC.h"

@interface UsersCDTVC () <UIAlertViewDelegate>

@end

@implementation UsersCDTVC

- (void)awakeFromNib
{
    self.title = @"Select a User";
    [[NSNotificationCenter defaultCenter] addObserverForName:MuggerDatabaseNamesNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[MuggerDatabaseNamesContext];
                                                  }];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"topScore"
                                                              ascending:NO
                                                               selector:@selector(localizedStandardCompare:)],
                                [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:YES
                                                               selector:@selector(localizedStandardCompare:)]];
    
    
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"User Cell"];
    
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = user.name;

    if (user.topScorePhoto) {
        Photo *photo = user.topScorePhoto;
        cell.detailTextLabel.text = photo.subtitle;

        if (photo.thumbnailData) {
            cell.imageView.image = [UIImage imageWithData:photo.thumbnailData];
        } else {
            NSLog(@"[%@ %@] user.topScorePhoto does not have thumbnailData", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
    }
    return cell;
}

#pragma mark - New User

// For adding new user
- (IBAction)addUserBarButtonSelected:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add New User" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.autoresizesSubviews = TRUE;
    UITextField *textField = [alert textFieldAtIndex:0];
    textField.placeholder = @"Unique user name";
    [alert show];
}

// Input validation, in case of user name conflicts
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *inputText = [[alertView textFieldAtIndex:0] text];
    if([inputText length] && self.managedObjectContext)
    {
        return ![User userNameExists:inputText inManagedObjectContext:self.managedObjectContext];
    }
    return NO;
}

// Save a new user
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Save"]) {
        NSString *inputText = [[alertView textFieldAtIndex:0] text];
        [User userWithName:inputText inManagedObjectContext:self.managedObjectContext];
    }
}


#pragma mark - Navigation

// prepares MugsCDTVC to show list of photos for a given user, used either when
// segueing to an MugsCDTVC or when our UISplitViewController's Detail view
// controller is an MugsCDTVC
- (void)prepareMugsCDTVC:(MugsCDTVC *)cdtvc forUser:(User *)user
{
    cdtvc.title = user.name;
    
    // Setup fetch request
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"photo.user = %@", user];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"score"
                                                              ascending:NO
                                                               selector:@selector(compare:)]];
    
    cdtvc.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                         managedObjectContext:self.managedObjectContext
                                                                           sectionNameKeyPath:nil
                                                                                    cacheName:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath && [segue.identifier isEqualToString:@"Display User Photos"]) {
            User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            if ([segue.destinationViewController isKindOfClass:[MugsCDTVC class]]) {
                [self prepareMugsCDTVC:segue.destinationViewController
                               forUser:user];
            }
        }
    }
}


/* TODO: Copied from Photomania

- (void)prepareViewController:(id)vc forSegue:(NSString *)segueIdentifer fromIndexPath:(NSIndexPath *)indexPath
{
    Photographer *photographer = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // note that we don't check the segue identifier here
    // probably fine ... hard to imagine any other way this class would segue to PhotosByPhotographerCDTVC
    if ([vc isKindOfClass:[PhotosByPhotographerCDTVC class]]) {
        PhotosByPhotographerCDTVC *pbpcdtvc =
        (PhotosByPhotographerCDTVC *)vc;
        pbpcdtvc.photographer = photographer;
        // we can also segue to a PhotosByPhotographerMapViewController
    } else if ([vc isKindOfClass:[PhotosByPhotographerMapViewController class]]) {
        PhotosByPhotographerMapViewController *pbpmapvc =
        (PhotosByPhotographerMapViewController *)vc;
        pbpmapvc.photographer = photographer;
        // or a PhotosByPhotographerImageViewController
    } else if ([vc isKindOfClass:[PhotosByPhotographerImageViewController class]]) {
        PhotosByPhotographerImageViewController *pbpivc =
        (PhotosByPhotographerImageViewController *)vc;
        pbpivc.photographer = photographer;
    }
}

// boilerplate
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    [self prepareViewController:segue.destinationViewController
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

// boilerplate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailvc = [self.splitViewController.viewControllers lastObject];
    if ([detailvc isKindOfClass:[UINavigationController class]]) {
        detailvc = [((UINavigationController *)detailvc).viewControllers firstObject];
        [self prepareViewController:detailvc
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}
*/
 
@end
