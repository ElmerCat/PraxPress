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
@property (nonatomic, retain) NSNumber * sourceListWidth;


@property (nonatomic, retain) Source *selectedSource;
@property (nonatomic, retain) NSOrderedSet *sources;
@end

@interface Interface (CoreDataGeneratedAccessors)

- (void)insertObject:(Source *)value inSourcesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSourcesAtIndex:(NSUInteger)idx;
- (void)insertSources:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSourcesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSourcesAtIndex:(NSUInteger)idx withObject:(Source *)value;
- (void)replaceSourcesAtIndexes:(NSIndexSet *)indexes withSources:(NSArray *)values;
- (void)addSourcesObject:(Source *)value;
- (void)removeSourcesObject:(Source *)value;
- (void)addSources:(NSOrderedSet *)values;
- (void)removeSources:(NSOrderedSet *)values;
@end
