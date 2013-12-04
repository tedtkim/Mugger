//
//  ShowMuggerViewController.h
//  Mugger
//
//  Created by Ted Kim on 12/4/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Mug.h"

@interface ShowMuggerViewController : UIViewController

// Model for this controller
@property (nonatomic, strong) Mug *mug;

@end
