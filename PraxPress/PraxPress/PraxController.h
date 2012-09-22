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
#import "UpdateController.h"
#import "Template.h"

@class Document;
@class PostEditor;
@class SoundCloudController;
@class WordPressController;

@interface PraxController : NSObject
@property (weak) IBOutlet NSButton *postsButton;
@property (weak) IBOutlet NSButton *pagesButton;
@property (weak) IBOutlet NSButton *tracksButton;
@property (weak) IBOutlet NSButton *playlistsButton;

@property Asset *selectedAsset;

@property BOOL batchChange;
@property BOOL replaceSubstrings;
@property (weak) IBOutlet NSComboBox *batchChangeKeyField;
@property (weak) IBOutlet NSTextField *batchChangeValueField;
@property (weak) IBOutlet NSButton *batchChangeCopyButton;
@property NSString *batchChangeKey;
@property NSString *replaceSubstringsKey;
@property (weak) IBOutlet NSTextField *replaceSubstringsFromField;
@property (weak) IBOutlet NSTextField *replaceSubstringsToField;
@property (readonly) NSString *batchChangeCopyValue;
- (IBAction)batchChangeCopy:(id)sender;
- (IBAction)batchChangeValues:(id)sender;
- (IBAction)batchReplaceSubstrings:(id)sender;

@property BOOL batchChangePurchaseTitle;
@property BOOL batchChangePurchaseURL;
@property BOOL batchChangeTitleSubstrings;
@property NSArray *_batchSortDescriptors;
- (NSArray *)batchSortDescriptors;

@property (weak) IBOutlet NSTableView *assetBatchEditTable;

@property (weak) IBOutlet NSArrayController *assetsController;
@property (unsafe_unretained) IBOutlet NSPanel *assetDetailPanel;
@property (weak) IBOutlet NSTableView *assetTableView;
//@property (weak) IBOutlet NSPopover *assetDetailPopover;

//@property (weak) IBOutlet NSPopover *templatePopover;
@property (weak) IBOutlet NSArrayController *templateController;
@property (unsafe_unretained) IBOutlet NSPanel *templatePanel;
@property (unsafe_unretained) IBOutlet NSPanel *previewFrameWindow;

- (NSArray *)itemsWithViewPosition:(int)value;
- (NSArray *)itemsWithNonTemporaryViewPosition;
- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value;
- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue;
- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value;
- (void)renumberViewPositions;
- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate;

- (IBAction)clearBatch:(id)sender;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSArrayController *assetBatchEditController;

@property (weak) IBOutlet SoundCloudController *soundCloudController;
@property (weak) IBOutlet WordPressController *wordPressController;
@property (weak) IBOutlet NSTableView *templateTableView;

@property (unsafe_unretained) IBOutlet NSPanel *playlistEditorPanel;

- (NSPredicate *)changedAssetsFilterPredicate;

- (IBAction)addAssetBatchButtonClicked:(id)sender;
- (IBAction)removeAssetBatchButtonClicked:(id)sender;
- (IBAction)filterButtonClicked:(id)sender;

@end
