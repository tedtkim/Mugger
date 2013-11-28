//
//  UsersCDTVC.h
//  Mugger
//
//  Created by Ted Kim on 11/26/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import "User.h"

// Uses cell "User Cell"
// Displays each user's top photo thumbnail and score

@interface UsersCDTVC : CoreDataTableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
