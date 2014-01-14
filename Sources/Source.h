//
//  Source.h
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "AssetListViewController.h"

@class Account;
@class Asset;
@class Tag;
@class Template;
@class Interface;
@class AssetListViewController;

@interface Source : NSManagedObject

@property AssetListViewController *controller;


+(Source *)addLibrarySource:(NSString*)name withSortOrder:(NSNumber*)sortOrder forType:(NSString*)folderType inManagedObjectContext:(NSManagedObjectContext*)moc;
//+(Source *)addAccountSource:(NSString*)name rowHeight:(NSNumber*)rowHeight toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc;
//+(Source *)addSubAccountSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc;
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
@property (nonatomic, retain) NSURL * exportURL;
@property (nonatomic, retain) NSString *filterString;
@property (nonatomic, retain) NSNumber * filterKeyIndex;
@property (nonatomic, retain) NSNumber * filterOptionIndex;
@property (nonatomic, retain) NSNumber * filterCaseSensitive;
@property (nonatomic, retain) NSNumber * filterNegate;

@property (nonatomic, retain) NSArray *selectionIndexes;
@property (nonatomic, retain) NSArray *sortDescriptors;

@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSNumber * rowHeight;
@property (nonatomic, retain) NSString * folderType;

@property (nonatomic, retain) Asset *serviceAccount;
@property (nonatomic, retain) Source *parent;
@property (nonatomic, retain) NSOrderedSet *children;
@property (nonatomic, retain) NSOrderedSet *batchAssets;
@property (nonatomic, retain) Template *template;
@property (nonatomic, retain) NSSet *excludedTags;
@property (nonatomic, retain) NSSet *requiredTags;
@property (nonatomic, retain) NSNumber * requireAllTags;
@property (nonatomic, retain) NSNumber * itemCount;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Interface *interface;
@property (nonatomic, retain) Account *account;

@property (nonatomic, retain) Interface *interfaceSelection;
@property (nonatomic, retain) Interface *interfaceSource;

@property (nonatomic, retain) NSOrderedSet *selectedAssets;
@end

@interface Source (CoreDataGeneratedAccessors)

- (void)insertObject:(Asset *)value inSelectedAssetsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSelectedAssetsAtIndex:(NSUInteger)idx;
- (void)insertSelectedAssets:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSelectedAssetsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSelectedAssetsAtIndex:(NSUInteger)idx withObject:(Asset *)value;
- (void)replaceSelectedAssetsAtIndexes:(NSIndexSet *)indexes withSelectedAssets:(NSArray *)values;
- (void)addSelectedAssetsObject:(Asset *)value;
- (void)removeSelectedAssetsObject:(Asset *)value;
- (void)addSelectedAssets:(NSOrderedSet *)values;
- (void)removeSelectedAssets:(NSOrderedSet *)values;

- (void)addExcludedTagsObject:(Tag *)value;
- (void)removeExcludedTagsObject:(Tag *)value;
- (void)addExcludedTags:(NSSet *)values;
- (void)removeExcludedTags:(NSSet *)values;

- (void)addRequiredTagsObject:(Tag *)value;
- (void)removeRequiredTagsObject:(Tag *)value;
- (void)addRequiredTags:(NSSet *)values;
- (void)removeRequiredTags:(NSSet *)values;

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
