//
//  Tag.h
//  PraxPress
//
//  Created by Elmer on 1/16/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Asset;
@class Source;

@interface Tag : NSManagedObject
@property (nonatomic, retain) NSNumber * isWPCategory;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * slug;

@property (nonatomic, retain) NSSet *assets;
@property (nonatomic, retain) Source *excludedSources;
@property (nonatomic, retain) NSSet *requiredSources;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addAssetsObject:(Asset *)value;
- (void)removeAssetsObject:(Asset *)value;
- (void)addAssets:(NSSet *)values;
- (void)removeAssets:(NSSet *)values;

- (void)addRequiredSourcesObject:(Source *)value;
- (void)removeRequiredSourcesObject:(Source *)value;
- (void)addRequiredSources:(NSSet *)values;
- (void)removeRequiredSources:(NSSet *)values;

@end
