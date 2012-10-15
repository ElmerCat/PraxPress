//
//  Source.h
//  PraxPress
//
//  Created by John Canfield on 10/10/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Account.h"

@interface Source : NSManagedObject


@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * optionFour;
@property (nonatomic, retain) NSNumber * optionOne;
@property (nonatomic, retain) NSNumber * optionThree;
@property (nonatomic, retain) NSNumber * optionTwo;
@property (nonatomic, retain) NSNumber * selected;
@property (nonatomic, retain) NSString * predicateFormat;
@property (nonatomic, retain) NSNumber * itemCount;

@property (nonatomic, retain) Account *account;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) NSManagedObject *parent;
@end

@interface Source (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(NSManagedObject *)value;
- (void)removeChildrenObject:(NSManagedObject *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
