//
//  batchController.h
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
#import "Asset.h"
#import "UpdateController.h"
#import "TemplateViewController.h"
#import "AssetDetailController.h"

@class Document;
@class PostEditor;
@class SoundCloudController;
@class WordPressController;
@class TemplateViewController;

@interface BatchController : NSObject <NSPopoverDelegate>

@property (weak) IBOutlet Document *document;
@property Asset *selectedAsset;

- (NSPredicate *)batchEditFilterPredicate;
@property BOOL batchChangePurchaseTitle;
@property BOOL batchChangePurchaseURL;
@property BOOL batchChangeTitleSubstrings;
@property NSArray *_batchSortDescriptors;
- (NSArray *)batchSortDescriptors;


@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSArrayController *associatedAssetsController;
@property (weak) IBOutlet NSArrayController *batchAssetsController;


@property (weak) IBOutlet NSTableView *batchAssetsTableView;
@property (weak) IBOutlet NSTableView *assetsTableView;
@property (weak) IBOutlet NSScrollView *assetsScrollView;
//@property (weak) IBOutlet NSPopover *assetDetailPopover;

//@property (weak) IBOutlet NSPopover *templatePopover;
@property (unsafe_unretained) IBOutlet NSPanel *previewFrameWindow;

- (NSArray *)itemsWithViewPosition:(int)value;
- (NSArray *)itemsWithNonTemporaryViewPosition;
- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value;
- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue;
- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value;
- (void)renumberViewPositions;
- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate;

- (IBAction)clearBatch:(id)sender;


- (NSPredicate *)changedAssetsFilterPredicate;

- (IBAction)addAssetBatchButtonClicked:(id)sender;
- (IBAction)removeAssetBatchButtonClicked:(id)sender;


@end
