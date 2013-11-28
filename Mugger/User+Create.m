//
//  User+Create.m
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "User+Create.h"

@implementation User (Create)

+ (BOOL)userNameExists:(NSString *)userName inManagedObjectContext:(NSManagedObjectContext *)context
{
    if ([userName length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@", userName];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];

        if (error || !matches) {
            // handle error
        } else if (![matches count]) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;

}

+ (User *)userWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user = nil;
    
    if ([name length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (error || !matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                 inManagedObjectContext:context];
            user.name = name;
            user.topScore = 0;
        } else {
            user = [matches lastObject];
        }
    }
    
    return user;
}

@end
