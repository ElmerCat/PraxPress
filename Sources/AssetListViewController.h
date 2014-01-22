//
//  AssetListViewController.h
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "AssetListView.h"
#import "NSSplitView+DMAdditions.h"
#import "AssetMetadataPopover.h"
#import "MultipleChangePopover.h"

@class Source;
@class Document;
@class CodeController;
@class SourceInfoPanel;
@class MultipleChangePopover;
@class AssetListView;

@interface AssetListViewController : NSViewController <NSTableViewDelegate, NSSplitViewDelegate, NSTokenFieldDelegate, NSPasteboardItemDataProvider>

#pragma mark - Instance Variables

@property BOOL awake;
@property Document *document;
@property Source *source;
@property AssetListViewController *associatedController;
@property (strong) IBOutlet CodeController *codeController;

@property SourceInfoPanel *sourceInfoPanel;
@property NSOrderedSet *assets;

@property int playback_count, favoritings_count, download_count, comment_count, duration;

#pragma mark - Interface State

@property BOOL sourceInfoPanelVisible;
@property BOOL isAssociatedPane;
@property BOOL isBatch;
@property BOOL isPlaylist;
@property BOOL isSelectedPane;
@property BOOL renameSource;
@property BOOL editSearch;
@property BOOL batchSubtract;

@property BOOL showDetailView;
@property BOOL showCodeView;

@property BOOL showFilterTags;
@property BOOL anySourceTags;

@property BOOL reloadingAssets;

- (void)loadAssociatedItems;
- (void)tagFilterAssets;

#pragma mark - IBOutlets

@property (weak) IBOutlet NSButton *sourceButton;
@property (strong) IBOutlet NSArrayController *assetArrayController;
@property (strong) IBOutlet NSArrayController *changedAssetArrayController;
@property (weak) IBOutlet NSTableView *assetsTableView;
@property (strong) IBOutlet AssetListView *assetListView;

@property (weak) IBOutlet NSPredicateEditor *predicateEditor;
@property (weak) IBOutlet NSPopUpButton *popUpButton;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet PraxTokenField *requiredTagsTokenField;
@property (weak) IBOutlet PraxTokenField *excludedTagsTokenField;
@property (strong) IBOutlet NSMenu *filterMenu;
@property (weak) IBOutlet NSMenu *filterByKeyMenu;
@property (weak) IBOutlet NSMenu *filterOptionMenu
;
@property (weak) IBOutlet AssetMetadataPopover *assetMetadataPopover;
@property (strong) IBOutlet MultipleChangePopover *multipleChangePopover;

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSView *codeViewPane;
@property (weak) IBOutlet NSScrollView *assetListPane;
@property (weak) IBOutlet NSView *detailViewPane;
@property (strong) IBOutlet NSView *assetDetailView;
@property (weak) IBOutlet NSBox *detailViewBox;
@property (strong) IBOutlet NSView *noSelectionView;

@property (weak) IBOutlet NSLayoutConstraint *changedBoxHeight;
@property (weak) IBOutlet NSLayoutConstraint *tagsBoxHeight;
@property (weak) IBOutlet NSLayoutConstraint *predicateBoxHeight;
@property (weak) IBOutlet NSLayoutConstraint *batchBoxHeight;
@property (weak) IBOutlet NSLayoutConstraint *accountBoxHeight;



#pragma mark - IBActions

- (void)doubleClickedArrayObjects:(NSArray *)arrayObjects;
- (IBAction)showSourceInfoPanel:(id)sender;
- (IBAction)filterButtonClicked:(id)sender;
- (IBAction)menuSelector:(id)sender;

- (IBAction)updateFilter:(id)sender;
- (IBAction)selectAssetListPane:(id)sender;

- (IBAction)newSearchRule:(id)sender;
- (IBAction)newCompoundRule:(id)sender;

- (IBAction)clearFilterTags:(id)sender;
- (IBAction)showTags:(id)sender;

- (void)openBrowserWithURLString:(NSString *)string;
- (void)showMetadataPopover:(NSDictionary *)metadata sender:(id)sender;
- (void)showTags:(NSSet *)tags sender:(id)sender;

@end
