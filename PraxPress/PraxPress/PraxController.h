//
//  PraxController.h
//  PraxPress
//
//  Created by John Canfield on 8/24/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <OAuth2Client/NXOAuth2.h>
//#import <SoundCloudAPI/SCAPI.h>
#import "Document.h"
#import "SoundCloudController.h"
#import "WordPressController.h"
#import "Asset.h"
#import "PostEditor.h"
#import "UpdateController.h"

@class Document;
@class PostEditor;
@class SoundCloudController;
@class WordPressController;

@interface PraxController : NSObject

@property Asset *lastSelectedAsset;

@property BOOL batchChangePurchaseTitle;
@property BOOL batchChangePurchaseURL;
@property BOOL batchChangeTitleSubstrings;
@property NSArray *_batchSortDescriptors;
- (NSArray *)batchSortDescriptors;
@property (weak) IBOutlet NSTextField *changePurchaseURL;
@property (weak) IBOutlet NSTextField *changePurchaseTitle;
@property (weak) IBOutlet NSTextField *changeTitleSubstringFrom;
@property (weak) IBOutlet NSTextField *changeTitleSubstringTo;
@property (weak) IBOutlet NSTableView *assetBatchEditTable;


- (NSArray *)itemsWithViewPosition:(int)value;
- (NSArray *)itemsWithNonTemporaryViewPosition;
- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value;
- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue;
- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value;
- (void)renumberViewPositions;
- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate;


- (IBAction)copyPurchaseTitle:(id)sender;
- (IBAction)copyPurchaseURL:(id)sender;
- (IBAction)performBatchChanges:(id)sender;
- (IBAction)clearBatch:(id)sender;
- (IBAction)preview:(id)sender;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSArrayController *assetBatchEditController;

@property (weak) IBOutlet SoundCloudController *soundCloudController;
@property (weak) IBOutlet WordPressController *wordPressController;
@property (weak) IBOutlet PostEditor *postEditor;

@property (weak) IBOutlet NSArrayController *postsController;
@property (weak) IBOutlet NSArrayController *tracksController;
@property (weak) IBOutlet NSArrayController *playlistsController;
@property (weak) IBOutlet NSTableView *tracksTableView;
@property (weak) IBOutlet NSTableView *playlistsTableView;

@property (unsafe_unretained) IBOutlet NSPanel *postsWindow;
@property (unsafe_unretained) IBOutlet NSPanel *tracksWindow;
@property (unsafe_unretained) IBOutlet NSPanel *playlistsWindow;
@property (unsafe_unretained) IBOutlet NSPanel *previewFrameWindow;
@property (weak) IBOutlet WebView *previewWebView;
@property (weak) IBOutlet NSTextField *generatedCodeText;
@property (weak) IBOutlet NSTableView *formatCodeTableView;

@property (unsafe_unretained) IBOutlet NSTextView *startingFormatText;
@property (unsafe_unretained) IBOutlet NSTextView *blockFormatText;
@property (unsafe_unretained) IBOutlet NSTextView *endingFormatText;

@property (unsafe_unretained) IBOutlet NSPanel *postEditorPanel;
@property (unsafe_unretained) IBOutlet NSPanel *trackEditorPanel;
@property (unsafe_unretained) IBOutlet NSPanel *playlistEditorPanel;

- (NSPredicate *)changedAssetsFilterPredicate;


@end
