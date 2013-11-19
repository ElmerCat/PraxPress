//
//  Source.m
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Source.h"

@implementation Source
@dynamic iconName;
@dynamic name;
@dynamic children;
@dynamic parent;
@dynamic sortOrder;
@dynamic fetchEntity;
@dynamic rowHeight;
@dynamic folderType;
@dynamic exportURL;

@dynamic fetchPredicate;
@dynamic filterString;
@dynamic filterKey;
@dynamic account;
@dynamic batchAssets;
@dynamic template;
@dynamic excludedTags;
@dynamic requiredTags;
@dynamic requireAllTags;


- (NSArray *)childrenArray {
	return self.children.array;
}
- (NSInteger)subItemLabelCount {
    return @7;
}

-(NSPredicate *)defaultPredicate {
    return [NSPredicate predicateWithFormat:@"title CONTAINS[cd] \"*\""];
    
}

-(NSPredicate *)defaultPredicateForAsset:(Asset *)asset {
    return [NSPredicate predicateWithFormat:@"title CONTAINS[cd] \"\" AND (type == \"track\" OR type == \"playlist\" OR type == \"post\" OR type == \"page\")"];
    
}

+(Source *)addLibrarySource:(NSString*)name withSortOrder:(NSNumber*)sortOrder forType:(NSString*)folderType inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"LibrarySource" inManagedObjectContext:moc];
    child.name = name;
    child.sortOrder = sortOrder;
    child.folderType = folderType;
    child.rowHeight = @20;
    return child;
}

+(Source *)addAccountSource:(NSString*)name rowHeight:(NSNumber *)rowHeight toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"AccountSource" inManagedObjectContext:moc];
    child.name = name;
    child.parent = parent;
    child.fetchEntity = fetchEntity;
    if (fetchPredicate.length) child.fetchPredicate = [NSPredicate predicateWithFormat:fetchPredicate];
    Asset *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
    account.type = @"account";
    account.accountType = child.name;
    child.account = account;
    child.rowHeight = rowHeight;
    return child;
}

+(Source *)addSubAccountSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"SubAccountSource" inManagedObjectContext:moc];
    child.name = name;
    child.parent = parent;
    child.fetchEntity = fetchEntity;
    if (fetchPredicate.length) child.fetchPredicate = [NSPredicate predicateWithFormat:fetchPredicate];
    child.rowHeight = @20;
    return child;
}

+(Source *)addFolderSource:(NSString*)name toParent:(Source*)parent inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"FolderSource" inManagedObjectContext:moc];
    child.name = name;
    child.parent = parent;
    child.rowHeight = @30;
    return child;
}

+(Source *)addSearchSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"SearchSource" inManagedObjectContext:moc];
    child.name = name;
    child.parent = parent;
    child.fetchEntity = fetchEntity;
    if (fetchPredicate.length) child.fetchPredicate = [NSPredicate predicateWithFormat:fetchPredicate];
    else child.fetchPredicate = child.defaultPredicate;
    child.rowHeight = @30;
    return child;
}

+(Source *)addPraxAssetSource:(NSString*)name toParent:(Source*)parent inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"PraxAssetSource" inManagedObjectContext:moc];
    child.name = name;
    child.parent = parent;
    child.rowHeight = @30;
    return child;
}

+(Source *)addBatchSource:(NSString*)name toParent:(Source*)parent withArrangedAssets:(NSArray*)assets inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"BatchSource" inManagedObjectContext:moc];
    child.name = name;
    child.parent = parent;
    child.batchAssets =  [NSOrderedSet orderedSetWithArray:assets];
    child.rowHeight = @30;
    return child;
}

@end
