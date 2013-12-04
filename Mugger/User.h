//
//  User.h
//  Mugger
//
//  Created by Ted Kim on 12/4/13.
//  Copyright (c) 2013 CS193p. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Mug;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * topScore;
@property (nonatomic, retain) NSSet *mugs;
@property (nonatomic, retain) Mug *topScoreMug;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addMugsObject:(Mug *)value;
- (void)removeMugsObject:(Mug *)value;
- (void)addMugs:(NSSet *)values;
- (void)removeMugs:(NSSet *)values;

@end
