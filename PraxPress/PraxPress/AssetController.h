//
//  AssetController.h
//  PraxPress
//
//  Created by John Canfield on 9/17/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "Asset.h"
#import "PraxController.h"

@interface AssetController : NSObject

@property (weak) IBOutlet PraxController *praxController;
@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *associatedItemsController;
@property (weak) IBOutlet WebView *assetDetailWebView;
@property (weak) IBOutlet NSTableView *assetTableView;
@property NSIndexSet *selectedRowIndexes;
- (IBAction)playlistButtonPressed:(id)sender;
@property (weak) IBOutlet NSPopover *playlistViewPopover;

@end
