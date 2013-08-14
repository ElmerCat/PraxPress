//
//  AssetListViewController.h
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"


@interface AssetListViewController : NSViewController <NSTableViewDelegate>
@property BOOL awake;
@property Document *document;
@property BOOL isSelectedPane;
@property Source *source;
@property (strong) IBOutlet NSArrayController *assetArrayController;
@property (weak) IBOutlet NSButton *notSelectedButton;
@property (weak) IBOutlet NSButton *selectedButton;
@property (weak) IBOutlet NSSearchField *searchField;
- (void)filterPane;
- (IBAction)updateFilter:(id)sender;
- (IBAction)viewerButtonPressed:(id)sender;
- (IBAction)selectAssetListPane:(id)sender;
@property (strong) IBOutlet NSWindow *assetListViewer;
@property NSInteger viewerMode;
@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)templatesButtonPressed:(id)sender;

@property (weak) IBOutlet NSScrollView *detailScrollView;
@property (strong) IBOutlet NSView *defaultDetailView;
@property (strong) IBOutlet NSView *trackDetailView;

@end
