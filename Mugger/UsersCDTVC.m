//
//  UsersCDTVC.m
//  Mugger
//
//  Created by Ted Kim on 11/26/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "UsersCDTVC.h"
#import "MuggerDatabaseNames.h"
#import "ShowMuggerViewController.h"
#import "User+Create.h"
#import "Mug.h"
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

    if (user.topScoreMug) {
        Mug *mug = user.topScoreMug;
        cell.detailTextLabel.text = mug.subtitle;

        if (mug.thumbnailData) {
            cell.imageView.image = [UIImage imageWithData:mug.thumbnailData];
        } else {
            NSLog(@"[%@ %@] user.topScoreMug does not have thumbnailData", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
    }
    return cell;
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
        User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        // Before deleting, we'll go one extra step and clear it out from detail (if applicable)
        id detail = self.splitViewController.viewControllers[1];
        if ([detail isKindOfClass:[UINavigationController class]]) {
            detail = [((UINavigationController *)detail).viewControllers firstObject];
        }
        
        if ([detail isKindOfClass:[ShowMuggerViewController class]]) {
            ShowMuggerViewController *smvc = (ShowMuggerViewController *)detail;
            if ([user isEqual:smvc.mug.user]) {
                smvc.mug = nil;
            }
        }
        
        // Now clean!
        [user.managedObjectContext deleteObject:user];
    }
}

#pragma mark - New User

// Using UIAlertView to add new user
- (IBAction)addUserBarButtonSelected:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add New User" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
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

// prepares MugsCDTVC to show list of mugs for a given user, used either when
// segueing to an MugsCDTVC or when our UISplitViewController's Detail view
// controller is an MugsCDTVC
- (void)prepareMugsCDTVC:(MugsCDTVC *)cdtvc forUser:(User *)user
{
    cdtvc.user = user;
    cdtvc.title = [NSString stringWithFormat:@"%@'s Mugs", user.name];
    
    // Setup fetch request
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Mug"];
    request.predicate = [NSPredicate predicateWithFormat:@"user = %@", user];
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
        if (indexPath && [segue.identifier isEqualToString:@"Display User Mugs"]) {
            User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            if ([segue.destinationViewController isKindOfClass:[MugsCDTVC class]]) {
                [self prepareMugsCDTVC:segue.destinationViewController
                               forUser:user];
            }
        }
    }
}

@end
