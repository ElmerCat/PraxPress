//
//  Source.m
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Source.h"

@implementation Source

@synthesize awake;
@synthesize controller;

#pragma mark - Core Data Attributes

@dynamic exportURL;
@dynamic fetchEntity;
@dynamic fetchPredicate;
@dynamic filterCaseSensitive;
@dynamic filterKeyIndex;
@dynamic filterNegate;
@dynamic filterOptionIndex;
@dynamic filterString;
@dynamic folderType;
@dynamic iconName;
@dynamic itemCount;
@dynamic name;
@dynamic requireAllTags;
@dynamic rowHeight;
@dynamic selectionIndexes;
@dynamic sortDescriptors;
@dynamic sortOrder;
@dynamic templateFooterCode;
@dynamic templateHeaderCode;
@dynamic templateItemsCode;
@dynamic templateItemsPerRow;
@dynamic templateMode;
@dynamic templateRowCode;
@dynamic type;

#pragma mark - Core Data Relationships

@dynamic account;
@dynamic batchAssets;
@dynamic children;
@dynamic excludedTags;
@dynamic interfaceSelection;
@dynamic interfaceSource;
@dynamic parent;
@dynamic requiredTags;
@dynamic selectedAssets;

#pragma mark - Initialization

- (void)awakeFromInsert {
    
    if (!self.awake) {
        self.awake = YES;
/*
        NSMutableOrderedSet *templates = [NSMutableOrderedSet orderedSetWithCapacity:3];
        Template *template;
        NSDictionary *defaultTemplate;
        NSInteger type;
        
        type = PraxTemplateTypeHeader;
        defaultTemplate = [Template defaultTemplateForType:type];
        if (defaultTemplate) {
            template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.managedObjectContext];
            template.type = [NSNumber numberWithInteger:type];
            template.text = defaultTemplate[@"text"];
            [templates addObject:template];
        }
        
        type = PraxTemplateTypeItem;
        defaultTemplate = [Template defaultTemplateForType:type];
        if (defaultTemplate) {
            template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.managedObjectContext];
            template.type = [NSNumber numberWithInteger:type];
            template.text = defaultTemplate[@"text"];
            [templates addObject:template];
        }
        
        type = PraxTemplateTypeFooter;
        defaultTemplate = [Template defaultTemplateForType:type];
        if (defaultTemplate) {
            template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.managedObjectContext];
            template.type = [NSNumber numberWithInteger:type];
            template.text = defaultTemplate[@"text"];
            [templates addObject:template];
        }
        
        self.templates = templates.copy;
 */
 
    }
}




- (NSArray *)childrenArray {
	return self.children.array;
}

-(NSPredicate *)defaultPredicate {
    return [NSPredicate predicateWithFormat:@"title CONTAINS[cd] \"*\""];
    
}

-(NSPredicate *)defaultPredicateForAsset:(Asset *)asset {
    return [NSPredicate predicateWithFormat:@"title CONTAINS[cd] \"\" AND (type == \"track\" OR type == \"playlist\" OR type == \"post\" OR type == \"page\")"];
    
}

+(Source *)addLibrarySource:(NSString*)name withSortOrder:(NSNumber*)sortOrder forType:(NSString*)folderType inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"LibrarySource";
    child.name = name;
    child.sortOrder = sortOrder;
    child.folderType = folderType;
    child.rowHeight = @20;
    return child;
}

/*+(Source *)addAccountSource:(NSString*)name rowHeight:(NSNumber *)rowHeight toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"AccountSource";
    child.name = name;
    child.parent = parent;
    child.fetchEntity = fetchEntity;
    if (fetchPredicate.length) child.fetchPredicate = [NSPredicate predicateWithFormat:fetchPredicate];
    Asset *serviceAccount = [NSEntityDescription insertNewObjectForEntityForName:@"ServiceAccount" inManagedObjectContext:moc];
    serviceAccount.type = @"account";
    serviceAccount.accountType = child.name;
    serviceAccount.serviceAccount = serviceAccount;
    child.serviceAccount = serviceAccount;
    child.rowHeight = rowHeight;
    return child;
}

+(Source *)addSubAccountSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"SubAccountSource";
    child.name = name;
    child.parent = parent;
    child.fetchEntity = fetchEntity;
    if (fetchPredicate.length) child.fetchPredicate = [NSPredicate predicateWithFormat:fetchPredicate];
    child.rowHeight = @20;
    return child;
}
*/
+(Source *)addFolderSource:(NSString*)name toParent:(Source*)parent inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"FolderSource";
    child.name = name;
    child.parent = parent;
    child.rowHeight = @30;
    return child;
}

+(Source *)addSearchSource:(NSString*)name toParent:(Source*)parent forEntity:(NSString*)fetchEntity withPredicateString:(NSString*)fetchPredicate inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"SearchSource";
    child.name = name;
    child.parent = parent;
    child.fetchEntity = fetchEntity;
    if (fetchPredicate.length) child.fetchPredicate = [NSPredicate predicateWithFormat:fetchPredicate];
    else child.fetchPredicate = child.defaultPredicate;
    child.rowHeight = @30;
    return child;
}

+(Source *)addPraxAssetSource:(NSString*)name toParent:(Source*)parent inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"PraxAssetSource";
    child.name = name;
    child.parent = parent;
    child.rowHeight = @30;
    return child;
}

+(Source *)addBatchSource:(NSString*)name toParent:(Source*)parent withArrangedAssets:(NSArray*)assets inManagedObjectContext:(NSManagedObjectContext*)moc{
    Source *child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    child.type = @"BatchSource";
    child.name = name;
    child.parent = parent;
    child.batchAssets =  [NSOrderedSet orderedSetWithArray:assets];
    child.rowHeight = @30;
    return child;
}

@end
