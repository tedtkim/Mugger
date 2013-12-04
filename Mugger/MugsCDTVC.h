//
//  MugsCDTVC.h
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import "User.h"

// Uses cell: "Mug Cell"
@interface MugsCDTVC : CoreDataTableViewController

// Model for this controller
@property (nonatomic, strong) User *user;

@end
