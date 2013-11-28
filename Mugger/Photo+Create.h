//
//  Photo+Create.h
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "Photo.h"

@interface Photo (Create)

+ (void)addPhotoWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSString *)uniqueFileNameWithTitle:(NSString *)title withExtension:(NSString *)extension;

@end
