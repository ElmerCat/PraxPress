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
- (IBAction)selectAssetListPane:(id)sender;
@property (weak) IBOutlet NSSearchField *searchField;
- (void)filterPane;
- (IBAction)updateFilter:(id)sender;

@property (weak) IBOutlet NSScrollView *detailScrollView;
@property (strong) IBOutlet NSView *defaultDetailView;
@property (strong) IBOutlet NSView *trackDetailView;

@end
