//
//  Template.h
//  PraxPress
//
//  Created by Elmer on 1/14/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"

@interface Template : NSManagedObject
@property (nonatomic, retain) NSString * formatText;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *sources;
@end

@interface Template (CoreDataGeneratedAccessors)

- (void)addSourcesObject:(Source *)value;
- (void)removeSourcesObject:(Source *)value;
- (void)addSources:(NSSet *)values;
- (void)removeSources:(NSSet *)values;

@end
