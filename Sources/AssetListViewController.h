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


@interface AssetListViewController : NSViewController <NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *assetsTableView;
@property BOOL awake;
@property Document *document;
@property AssetListViewController *associatedController;
@property BOOL isAssociatedPane;
@property BOOL isPlaylist;
@property BOOL isSelectedPane;
@property Source *source;
@property NSOrderedSet *assets;

@property NSString *appleScriptSource;
@property NSAppleScript *appleScript;
- (NSDictionary *)toolTips;
@property int playback_count, favoritings_count, download_count, comment_count, duration;


@property (weak) IBOutlet NSButton *notSelectedButton;
@property (weak) IBOutlet NSButton *selectedButton;
@property (weak) IBOutlet NSSearchField *searchField;
@property (strong) IBOutlet NSArrayController *assetArrayController;
@property (strong) IBOutlet NSArrayController *changedAssetArrayController;
- (void)filterPane;
- (IBAction)updateFilter:(id)sender;
- (IBAction)selectAssetListPane:(id)sender;
- (IBAction)exportFormattedCode:(id)sender;
- (IBAction)writeFormattedCode:(id)sender;
@property (weak) IBOutlet NSBox *detailViewBox;
@property (strong) IBOutlet NSView *trackDetailView;
@property (strong) IBOutlet NSView *playlistDetailView;
@property (strong) IBOutlet NSView *soundCloudDetailView;
@property (strong) IBOutlet NSView *wordPressDetailView;
@property (strong) IBOutlet NSView *defaultDetailView;
@property (strong) IBOutlet NSView *noSelectionView;

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NSScrollView *assetListPane;
@property (weak) IBOutlet NSView *detailViewPane;
@property (weak) IBOutlet NSView *codeViewPane;
@property (weak) IBOutlet NSView *webViewPane;
@property (weak) IBOutlet NSPopUpButton *popUpButton;

@property BOOL showDetailView;
@property BOOL showCodeView;
@property BOOL showWebView;
@property BOOL showSafariView;
@property NSString *formattedCode;
@property NSMutableArray *tags;

@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (void)doubleClickedArrayObjects:(NSArray *)arrayObjects;

- (IBAction)templatesButtonPressed:(id)sender;
@property (weak) IBOutlet AssetMetadataPopover *assetMetadataPopover;
- (void)openBrowserWithURLString:(NSString *)string;
- (void)showMetadataPopover:(NSDictionary *)metadata sender:(id)sender;
- (void)showTags:(NSSet *)tags sender:(id)sender;

@end
