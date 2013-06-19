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
#import "UpdateController.h"
#import "BatchController.h"
#import "AssetTableCellView.h"
#import "AssetMetadataPopover.h"

@interface AssetController : NSObject

@property BOOL awake;
@property (weak) IBOutlet Document *document;
@property NSMapTable *assetDetailControllers;
@property NSIndexSet *assetsSelectedRowIndexes;
@property NSIndexSet *associatedAssetsSelectedRowIndexes;
@property NSIndexSet *batchAssetsSelectedRowIndexes;
@property NSIndexSet *changedAssetsSelectedRowIndexes;
@property NSInteger assetsViewMode;
@property NSInteger associatedAssetsViewMode;
@property NSInteger batchAssetsViewMode;
@property NSInteger changedAssetsViewMode;

@property (weak) IBOutlet AssetMetadataPopover *assetMetadataPopover;


- (IBAction)assetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)changedAssetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)batchAssetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)associatedAssetsTableViewModeSelectorClicked:(id)sender;

@property (weak) IBOutlet NSPopUpButton *sortPopupButton;
@property BOOL sortAscending;
@property NSString *sortKey;
@property NSInteger sortKeyTag;
- (IBAction)sortAssetsKey:(id)sender;
- (IBAction)sortAssetsDirection:(id)sender;

- (void)assetTableDoubleClicked:(NSArray *)selectedObjects;
- (void)showMetadataPopoverForAsset:(Asset *)asset sender:(id)sender;

@end
