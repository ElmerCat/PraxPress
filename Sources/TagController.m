//
//  TagController.m
//  PraxPress
//
//  Created by Elmer on 1/16/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "TagController.h"

@implementation TagController

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"TagController init");

        [[NSNotificationCenter defaultCenter] addObserverForName:@"AssetTagsChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *asset = (Asset *)[aNotification object];
            
            if (!asset.sync_mode.boolValue) asset.sync_mode = [NSNumber numberWithBool:YES];
            [self.tagsArrayController rearrangeObjects];
            
                    NSLog(@"TagController AssetTagsChangedNotification: %@", asset.sync_mode);
            
        }];
    }
    return self;
}
- (void)awakeFromNib {
    NSLog(@"TagController awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        [self.tagsArrayController setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
    }
}

- (IBAction)toggleTagsPanel:(id)sender {
    if (![self.tagsPanel isVisible]) [self.tagsPanel makeKeyAndOrderFront:sender];
    else [self.tagsPanel close];
}

- (IBAction)deleteSelectedTags:(id)sender {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Are you sure you want to delete the selected Tags?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Delete Tags"];
    if ([alert runModal] == NSAlertSecondButtonReturn) {

        for (Tag *tag in self.tagsArrayController.selectedObjects) {
            [self.document.managedObjectContext deleteObject:tag];
        }
        
    }
    
}

- (IBAction)mergeSelectedTags:(id)sender {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Are you sure you want to merge the selected Tags?"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Merge Tags"];
    if ([alert runModal] == NSAlertSecondButtonReturn) {

        Tag *selectedTag = self.tagsArrayController.selectedObjects[0];
        
        NSMutableSet *assets = [NSMutableSet setWithCapacity:1];
        for (Tag *tag in self.tagsArrayController.selectedObjects) {
            [assets unionSet:tag.assets];
            if (tag != selectedTag) [self.document.managedObjectContext deleteObject:tag];
        }
        selectedTag.assets = assets;
    }
}

- (IBAction)updateFilter:sender {
    NSString *searchString = [self.searchField stringValue];
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", searchString];
        [self.tagsArrayController setFilterPredicate:predicate];
    }
    else [self.tagsArrayController setFilterPredicate:nil];
}


- (void)loadAssetTags:(Asset *)asset data:(NSDictionary *)data {
    NSMutableSet *tags = [[NSMutableSet alloc] init];
    Tag *tag;

    if ([asset.accountType isEqualToString:@"WordPress"]) {
        NSDictionary *tagDictionary = data[@"tags" ];
        
        
        for (NSString *tagString __strong in tagDictionary) {
            tag = [self tagForString:tagString create:YES];
            if (tag) [tags addObject:tag];
        }
        
    
    
    }
    else { // SoundCloud
        NSString *tag_list = data[@"tag_list"];
        if (tag_list.length > 0) {
            NSArray *tagArray = [TagController arrayFromTagString:tag_list];
            for (NSString *tagString __strong in tagArray) {
                tag = [self tagForString:tagString create:YES];
                if (tag) [tags addObject:tag];
            }
        }
        NSString *genre = data[@"genre"];
        if (genre.length > 0) {
            tag = [self tagForString:genre create:YES];
            if (tag) asset.genreTags = [NSSet setWithObject:tag];
        }
        else asset.genreTags = nil;
    }
    asset.tags = tags;
}

- (Tag *)tagForString:(NSString *)string create:(BOOL)create {
    
    Tag *tag = nil;
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K MATCHES[cd] %@", @"name", string]];
    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
    if ([matchingItems count] > 0) {
        tag = matchingItems[0];
    }
    else if (create) {
        tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
        tag.name = string;
    }
    return tag;
}

+ (void)setAssetTagList:(Asset *)asset {
    
    NSMutableArray *tags = [NSMutableArray array];
    
    for (Tag *tag in asset.tags) {
        [tags addObject:tag.name];
    }
    asset.tag_list = [TagController tagStringFromArray:tags];
    
}



+ (NSArray *)arrayFromTagString:(NSString *)string {
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *substring;
    
    while (scanner.scanLocation < string.length) {
        
        // test if the first character is a quote
        unichar character = [string characterAtIndex:scanner.scanLocation];
        if (character == '"') {
            // skip the first quote and scan everything up to the next quote into a substring
            [scanner setScanLocation:(scanner.scanLocation + 1)];
            [scanner scanUpToString:@"\"" intoString:&substring];
            [scanner setScanLocation:(scanner.scanLocation + 1)];  // skip the second quote too
        }
        else {
            // scan everything up to the next space into the substring
            [scanner scanUpToString:@" " intoString:&substring];
        }
        // add the substring to the array
        [array addObject:substring];
        
        //if not at the end, skip the space character before continuing the loop
        if (scanner.scanLocation < string.length) [scanner setScanLocation:(scanner.scanLocation + 1)];
    }
    return array.copy;
}

+ (NSString *)tagStringFromArray:(NSArray *)array {
    
    NSMutableString *string = [[NSMutableString alloc] init];
    NSRange range;

    for (NSString *substring in array) {
        if (string.length > 0) {
            [string appendString:@" "];
        }
        range = [substring rangeOfString:@" "];
        if (range.location != NSNotFound) {
            [string appendFormat:@"\"%@\"", substring];
        }
        else [string appendString:substring];
    }
    return string.description;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    NSMutableArray *validTokens = @[].mutableCopy;
    for (id token in tokens) {
        if ([[token className] isEqualToString:@"Tag"]) [validTokens addObject:token];
    }
    if (validTokens.count == 0) return @[];
    
    NSInteger maxTokens = [(PraxTokenField *)tokenField maxTokens];
    
    if (maxTokens > 0) {
        if (maxTokens < validTokens.count) {
            [validTokens removeObjectsInRange:NSMakeRange(0, (validTokens.count - maxTokens))];
        }
        if (maxTokens < ([(NSArray *)tokenField.objectValue count] + validTokens.count)) {
            return @[];
        }
    }
    return validTokens;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {
    if ([[representedObject className] isEqualToString:@"Tag"]) {
        return NSDefaultTokenStyle;
    }
    else return NSPlainTextTokenStyle;
}


- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    if ([[representedObject className] isEqualToString:@"Tag"]) {
        return [(Tag *)representedObject name];
    }
    else return @"";
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    if ([[representedObject className] isEqualToString:@"Tag"]) {
        return [(Tag *)representedObject name];
    }
    else return nil;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    NSError *error;
    Tag *tag;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K MATCHES[cd] %@", @"name", editingString]];
    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
    if ([matchingItems count] < 1) {
        if ([(PraxTokenField *)tokenField existingTokensOnly]) return nil;
        tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
        tag.name = editingString;
    }
    else tag = matchingItems[0];
    return tag;
    
}
- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", substring]];
    
    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:nil];
    if ([matchingItems count] > 0) {
        NSMutableArray *completions = [NSMutableArray arrayWithCapacity:10];
        for (Tag *tag in matchingItems) {
            [completions addObject:tag.name];
        }
        return completions;
    }
    else {
        if ([(PraxTokenField *)tokenField existingTokensOnly]) [tokenField insertText:@","];
        
        return nil;
    }
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
    NSMutableString * tagString = [@"" mutableCopy];
    NSArray * draggedObjects = [self.tagsArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
    BOOL multiple;
    for (Tag * tag in draggedObjects) {
        if (multiple) [tagString appendString:@","];
        [tagString appendString:tag.name];
        multiple = YES;
    }
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pasteboard setString:tagString forType:NSStringPboardType];
	return YES;
}

@end
