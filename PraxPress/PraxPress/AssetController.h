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

@interface AssetController : NSObject

@property BOOL awake;
@property (weak) IBOutlet Document *document;
@property NSMapTable *assetDetailControllers;
@property NSIndexSet *selectedRowIndexes;
@property NSInteger assetsViewMode;
@property NSInteger associatedAssetsViewMode;
@property NSInteger batchAssetsViewMode;
@property NSInteger changedAssetsViewMode;

@property (weak) IBOutlet UpdateController *updateController;
@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *batchAssetsController;
@property (weak) IBOutlet NSArrayController *associatedAssetsController;
@property (weak) IBOutlet NSArrayController *changedAssetsController;

@property (weak) IBOutlet WebView *assetDetailWebView;
@property (weak) IBOutlet NSTableView *assetsTableView;
@property (weak) IBOutlet NSTableView *batchAssetsTableView;
@property (weak) IBOutlet NSTableView *changedAssetsTableView;
@property (weak) IBOutlet NSTableView *associatedAssetsTableView;
@property (weak) IBOutlet NSPopover *playlistViewPopover;


@property (weak) IBOutlet NSPopUpButton *sortPopupButton;
@property (weak) IBOutlet NSButton *sortDirectionButton;

- (IBAction)assetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)changedAssetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)batchAssetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)associatedAssetsTableViewModeSelectorClicked:(id)sender;
- (IBAction)sortAssets:(id)sender;

- (void)assetTableDoubleClicked:(NSArray *)selectedObjects;

@end
