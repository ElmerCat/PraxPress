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
            [self.document.tagsController rearrangeObjects];
            
                    NSLog(@"TagController AssetTagsChangedNotification: %@", asset.sync_mode);
            
        }];
    }
    return self;
}

- (void)loadAssetTags:(Asset *)asset {
    NSString *tag_list = asset.tag_list;
    NSArray *tagArray = [TagController arrayFromTagString:tag_list];
    NSError *error;
    Tag *tag;
    
    for (NSString *tagString in tagArray) {
       
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", tagString]];
        NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
        if ([matchingItems count] < 1) {
            tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
            tag.name = tagString;
            
        }
        else tag = matchingItems[0];
        [asset addTagsObject:tag];

    }
    NSLog(@"Asset: %@", asset);
    
    
//    tag_list = [TagController tagStringFromArray:tagArray];
    
    
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

@end
