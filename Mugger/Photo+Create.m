//
//  Photo+Create.m
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "Photo+Create.h"

@implementation Photo (Create)

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
