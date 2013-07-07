//
//  Source.h
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
@class Asset;

@interface Source : NSManagedObject

+(Source *)addLibrarySource:(NSString*)name withSortOrder:(NSNumber*)sortOrder inManagedObjectContext:(NSManagedObjectContext*)moc;
+(Source *)addAccountSource:(NSString*)name rowHeight:(NSNumber*)rowHeight toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc;
+(Source *)addSubAccountSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc;
+(Source *)addSearchSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc;
+(Source *)addFolderSource:(NSString*)name toParent:(Source*)parent inManagedObjectContext:(NSManagedObjectContext*)moc;
+(Source *)addBatchSource:(NSString*)name toParent:(Source*)parent withArrangedAssets:(NSArray*)assets inManagedObjectContext:(NSManagedObjectContext*)moc;
+(Source *)addPraxAssetSource:(NSString*)name toParent:(Source*)parent inManagedObjectContext:(NSManagedObjectContext*)moc;

-(NSArray *)childrenArray;
-(NSInteger)subItemLabelCount;
-(NSPredicate *)defaultPredicate;
-(NSPredicate *)defaultPredicateForAsset:(Asset *)asset;

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * iconName;
@property (nonatomic, retain) NSString * fetchEntity;
@property (nonatomic, retain) NSPredicate *fetchPredicate;
@property (nonatomic, retain) NSString *filterString;
@property (nonatomic, retain) NSString *filterKey;
@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSNumber * rowHeight;

@property (nonatomic, retain) Asset *account;
@property (nonatomic, retain) Source *parent;
@property (nonatomic, retain) NSOrderedSet *children;
@property (nonatomic, retain) NSOrderedSet *batchAssets;

@end

@interface Source (CoreDataGeneratedAccessors)

- (void)insertObject:(Asset *)value inBatchAssetsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBatchAssetsAtIndex:(NSUInteger)idx;
- (void)insertBatchAssets:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBatchAssetsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBatchAssetsAtIndex:(NSUInteger)idx withObject:(Asset *)value;
- (void)replaceBatchAssetsAtIndexes:(NSIndexSet *)indexes withBatchAssets:(NSArray *)values;
- (void)addBatchAssetsObject:(Asset *)value;
- (void)removeBatchAssetsObject:(Asset *)value;
- (void)addBatchAssets:(NSOrderedSet *)values;
- (void)removeBatchAssets:(NSOrderedSet *)values;

- (void)insertObject:(NSManagedObject *)value inChildrenAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)idx;
- (void)insertChildren:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChildrenAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)values;
- (void)addChildrenObject:(NSManagedObject *)value;
- (void)removeChildrenObject:(NSManagedObject *)value;
- (void)addChildren:(NSOrderedSet *)values;
- (void)removeChildren:(NSOrderedSet *)values;
@end
