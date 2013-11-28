//
//  Photo.h
//  Mugger
//
//  Created by Ted Kim on 11/27/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) User *topScoreUser;

@end
