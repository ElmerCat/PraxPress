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

@property (weak) IBOutlet Document *document;

- (void)loadAssetTags:(Asset *)asset;

@end
