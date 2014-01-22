//
//  SourceController.h
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "Source.h"
#import "AssetListView.h"
#import "AssetListViewController.h"
//#import "AssetListView.h"
#import "SourceInfoPanel.h"

@class SourcePopovers;
@class AssetListViewController;

@interface SourceController : NSResponder <NSOutlineViewDelegate, NSSplitViewDelegate>

@property BOOL awake;
@property BOOL interfaceLoaded;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSTreeController *sourceTreeController;
@property (weak) IBOutlet NSView *scrolledDocumentView;


@property Source *allItemsSource;
@property Source *changedItemsSource;

@property (weak) IBOutlet NSSplitView *sourceSplitView;
@property (weak) IBOutlet NSView *sourceListSubView;
@property NSInteger allItemsCount;
@property BOOL hasMoreThanOneTab;
@property (readonly) BOOL sourceListVisible;
@property (weak) IBOutlet NSPopover *sourcePopover;
@property (unsafe_unretained) IBOutlet SourcePopovers *sourcePopovers;
@property (weak) IBOutlet NSOutlineView *sourceListOutlineView;
@property (weak) IBOutlet NSView *sourceNameAccessoryView;
@property NSString *sourceName;
@property (weak) IBOutlet NSLayoutConstraint *outlineViewWidthConstraint;

+ (void)initForDocument:(Document *)document;
- (void)loadInterface;
- (void)windowWillClose:(NSNotification *)notification;


//- (IBAction)clearTags:(id)sender;


- (IBAction)newListPaneWithSource:(id)sender;
- (IBAction)newSourceItem:(id)sender;
- (IBAction)newSourceFolder:(id)sender;
- (IBAction)delete:(id)sender;

- (IBAction)newPraxAsset:(id)sender;
- (IBAction)toggleSourceList:(id)sender;
- (IBAction)toolbarItemSelected:(id)sender;
//- (IBAction)sourceDetailsButtonPressedRightEdge:(id)sender;
//- (IBAction)sourceDetailsButtonPressedBottomEdge:(id)sender;
- (void)doubleClickedSource;
- (IBAction)closeAssetListPane:(id)sender;

@property Source *previousSource;

- (void)movePane:(AssetListView *)pane toPane:(AssetListView *)toPane;

- (void)removeAssets:(NSArray *)assets fromSource:(Source *)source;
- (void)addBatchSource:(AssetListViewController *)controller withAssets:(NSArray *)assets;
- (void)addSearchSource:(AssetListViewController *)controller withSource:(Source *)source;
- (void)showAssociatedItems:(AssetListViewController *)controller;

@end

@interface NSTreeController (Additions)
- (NSTreeNode*)nodeOfObject:(id)anObject;
- (NSIndexPath*)indexPathOfObject:(id)anObject;
@end