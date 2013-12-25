//
//  Interface.h
//  PraxPress
//
//  Created by Elmer on 12/17/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Source.h"

@interface Interface : NSManagedObject
@property (nonatomic, retain) NSData *exportCodeDirectory;

@property (nonatomic, retain) Source *selectedSource;

@end
