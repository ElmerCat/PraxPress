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

@class PostEditor;
@class SoundCloudController;
@class WordPressController;
@class TemplateViewController;

@interface BatchController : NSObject

@property NSString *templateName;
@property (unsafe_unretained) IBOutlet NSWindow *batchViewWindow;
@property (weak) IBOutlet WebView *webView;
@property (unsafe_unretained) IBOutlet NSTextView *codeTextView;


@property (weak) IBOutlet Document *document;
@property Asset *selectedAsset;


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

- (IBAction)clearBatch:(id)sender;

- (IBAction)addAssetsToBatch:(id)sender;
- (IBAction)removeAssetsFromBatch:(id)sender;

@property (weak) IBOutlet NSPopUpButton *sortPopupButton;
@property BOOL sortAscending;
@property NSString *sortKey;
@property NSInteger sortKeyTag;
- (IBAction)sortAssetsKey:(id)sender;
- (IBAction)sortAssetsDirection:(id)sender;


@end
