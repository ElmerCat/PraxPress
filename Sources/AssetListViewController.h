//
//  AssetListViewController.h
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "NSSplitView+DMAdditions.h"
#import "AssetMetadataPopover.h"
#import "MultipleChangePopover.h"
@class SourceInfoPanel;
@class MultipleChangePopover;

@interface AssetListViewController : NSViewController <NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *assetsTableView;
@property BOOL awake;
@property Document *document;
@property AssetListViewController *associatedController;
@property SourceInfoPanel *sourceInfoPanel;
@property BOOL sourceInfoPanelVisible;
@property BOOL isAssociatedPane;
@property BOOL isPlaylist;
@property BOOL isSelectedPane;
@property Source *source;
@property NSOrderedSet *assets;

@property NSString *appleScriptSource;
@property NSAppleScript *appleScript;
@property int playback_count, favoritings_count, download_count, comment_count, duration;

@property (weak) IBOutlet NSSearchField *searchField;
@property (strong) IBOutlet NSArrayController *assetArrayController;
@property (strong) IBOutlet NSArrayController *changedAssetArrayController;
- (void)filterPane;
- (IBAction)updateFilter:(id)sender;
- (IBAction)selectAssetListPane:(id)sender;
@property (weak) IBOutlet NSBox *detailViewBox;
@property (strong) IBOutlet NSView *assetDetailView;
@property (strong) IBOutlet NSView *noSelectionView;

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSScrollView *assetListPane;
@property (weak) IBOutlet NSView *detailViewPane;
@property (weak) IBOutlet NSPopUpButton *popUpButton;

@property BOOL showDetailView;
@property BOOL showSafariView;
@property BOOL exportCode;
@property NSURL *exportCodeURL;
@property NSString *formattedCode;
@property BOOL updatingFormattedCode;

- (void)doubleClickedArrayObjects:(NSArray *)arrayObjects;
- (IBAction)showSourceInfoPanel:(id)sender;
- (IBAction)filterButtonClicked:(id)sender;

- (IBAction)templatesButtonPressed:(id)sender;
@property (weak) IBOutlet AssetMetadataPopover *assetMetadataPopover;
@property (strong) IBOutlet MultipleChangePopover *multipleChangePopover;

- (void)openBrowserWithURLString:(NSString *)string;
- (void)showMetadataPopover:(NSDictionary *)metadata sender:(id)sender;
- (void)showTags:(NSSet *)tags sender:(id)sender;

@end
