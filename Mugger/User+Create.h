//
//  User+Create.h
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "User.h"

@interface User (Create)

+ (BOOL)userNameExists:(NSString *)userName inManagedObjectContext:(NSManagedObjectContext *)context;

+ (User *)userWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
@end
