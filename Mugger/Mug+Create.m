//
//  Mug+Create.m
//  Mugger
//
//  Created by Ted Kim on 11/29/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "Mug+Create.h"

@implementation Mug (Create)

+ (Mug *)mugWithURL:(NSURL *)mugURL forUser:(User *)user inManagedObjectContext:(NSManagedObjectContext *)context
{
    Mug *mug = nil;
    if (mugURL && user) {
        NSLog(@"Adding new mug using non-nil mugURL: %@ and user: %@", mugURL, user);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Mug"];
        request.predicate = [NSPredicate predicateWithFormat:@"(mugURL = %@) AND (user = %@)", [mugURL absoluteString], user];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (error || !matches || ([matches count] > 1)) {
            // handle error
            NSLog(@"Error at add new mug! matches: %@, error: %@", matches, error);
        } else if (![matches count]) {
            mug = [NSEntityDescription insertNewObjectForEntityForName:@"Mug"
                                                inManagedObjectContext:context];
            mug.mugURL = [mugURL absoluteString];
            mug.user = user;
            NSLog(@"Added new mug successfully, using mug.mugURL = %@!", mug.mugURL);
        } else {
            NSLog(@"Found existing match for this at add new mug!");
            mug = [matches lastObject];
        }
    }
    return mug;
}

+ (NSString *)uniqueFileNameWithTitle:(NSString *)title withExtension:(NSString *)extension
{
    // Extenstion string is like @".png"
    
    NSDate *time = [NSDate date];
    NSDateFormatter* df = [NSDateFormatter new];
    [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss"];
    NSString *timeString = [df stringFromDate:time];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@%@", title, timeString, extension];
    
    return fileName;
}

@end
