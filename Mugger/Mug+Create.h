//
//  Mug+Create.h
//  Mugger
//
//  Created by Ted Kim on 11/29/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import "Mug.h"

@interface Mug (Create)

+ (Mug *)mugWithURL:(NSURL *)mugURL forUser:(User *)user inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSString *)uniqueFileNameWithTitle:(NSString *)title withExtension:(NSString *)extension;

@end
