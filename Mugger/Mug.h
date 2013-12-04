//
//  Mug.h
//  Mugger
//
//  Created by Ted Kim on 12/4/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Mug : NSManagedObject

@property (nonatomic, retain) NSString * mugURL;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) User *topScoreForUser;
@property (nonatomic, retain) User *user;

@end
