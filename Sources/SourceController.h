//
//  SourceController.h
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "Source.h"
#import "AssetListViewController.h"
//#import "AssetListView.h"
#import "SourcePopovers.h"
#import "SourceInfoPanel.h"

@class SourcePopovers;
@class AssetListViewController;

@interface SourceController : NSObject
@property BOOL awake;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSToolbar *documentToolbar;
@property (unsafe_unretained) IBOutlet NSWindow *documentWindow;
//@property Source *selectedSource;
@property Source *allItemsSource;
@property (weak) IBOutlet NSSplitView *sourceSplitView;
@property (weak) IBOutlet NSView *sourceListSubView;
@property NSMutableArray *assetListViewControllers;
@property NSInteger selectedAssetListIndex;
@property NSInteger allItemsCount;
@property BOOL hasMoreThanOneTab;
@property (readonly) BOOL sourceListVisible;
@property (weak) IBOutlet NSPopover *sourcePopover;
@property (unsafe_unretained) IBOutlet SourcePopovers *sourcePopovers;
@property NSMapTable *sourceListCellControllers;
@property (weak) IBOutlet NSOutlineView *sourceListOutlineView;

+ (void)initForDocument:(Document *)document;
- (void)loadInterface;
- (void)windowWillClose:(NSNotification *)notification;


- (IBAction)clearTags:(id)sender;


- (IBAction)newListPaneWithSource:(id)sender;
- (IBAction)newSourceItem:(id)sender;
- (IBAction)newSourceFolder:(id)sender;
- (IBAction)delete:(id)sender;

- (IBAction)newPraxAsset:(id)sender;
- (IBAction)toggleSourceList:(id)sender;
- (IBAction)filterSelectedPane:(id)sender;
- (IBAction)toolbarItemSelected:(id)sender;
- (IBAction)sourceDetailsButtonPressedRightEdge:(id)sender;
- (IBAction)sourceDetailsButtonPressedBottomEdge:(id)sender;
- (void)doubleClickedSource;

- (void)removeAssets:(NSArray *)assets fromSource:(Source *)source;
- (void)addBatchSource:(AssetListViewController *)controller withAssets:(NSArray *)assets;
- (void)addBatchSource:(AssetListViewController *)controller withSource:(Source *)source;
- (void)addAssetListPane:(AssetListViewController *)controller withSource:(Source *)source;
- (void)closeAssetListPane:(AssetListViewController *)controller;
- (void)showAssociatedItems:(AssetListViewController *)controller;
- (void)selectAssetListPane:(AssetListViewController *)controller;

@end

@interface NSTreeController (Additions)
- (NSTreeNode*)nodeOfObject:(id)anObject;
- (NSIndexPath*)indexPathOfObject:(id)anObject;
@end