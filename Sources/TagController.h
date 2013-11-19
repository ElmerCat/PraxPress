//
//  TagController.h
//  PraxPress
//
//  Created by Elmer on 1/16/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#import "Asset.h"
#import "Tag.h"

@interface TagController : NSObject

@property BOOL awake;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSTableView *tagsTableView;
@property (weak) IBOutlet NSTokenField *excludedTagsTokenField;
@property (weak) IBOutlet NSArrayController *tagsArrayController;

- (void)loadAssetTags:(Asset *)asset data:(NSDictionary *)data;
+ (void)setAssetTagList:(Asset *)asset;

@end
