//
//  Template.h
//  PraxPress
//
//  Created by Elmer on 1/14/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Template : NSManagedObject
@property (nonatomic, retain) NSString * formatText;
@property (nonatomic, retain) NSString * name;

@end
