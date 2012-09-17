//
//  Template.h
//  PraxPress
//
//  Created by John Canfield on 8/26/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Template : NSManagedObject

@property (nonatomic, retain) NSString * blockFormatText;
@property (nonatomic, retain) NSString * endingFormatText;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * startingFormatText;

@end
