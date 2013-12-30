//
//  RequestController.h
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OAuth2Client/NXOAuth2.h>
#import "Document.h"
#import "Account.h"
#import "Asset.h"
#import "Tag.h"
#import "TagController.h"
#import "AssetListViewController.h"

@class Account;
@class Document;
@class PostEditor;
@class TagController;

@interface RequestController : NSObject

typedef NSUInteger PRAXReloadOption;

@property dispatch_queue_t responseHandlingQueue;

//@property NSOperationQueue *responseDataProcessingQueue;

@property NSDictionary *parameters;
@property NSURL *resource;
@property NSString *statusText;
@property NSInteger updateCount;
@property NSInteger targetCount;


- (void)reloadAssetsForClient:(id)client;
@property NSMutableSet *assetsToReload;
- (void)uploadAssetsForClient:(id)client;
@property NSMutableSet *assetsToUpload;
@property Asset *pendingAssetToReload;
@property Account *pendingAccountToReload;
@property PRAXReloadOption pendingOption;

@property NSMutableArray *dataQueue;

@property BOOL stop;
@property BOOL busy;
@property BOOL determinate;
@property BOOL uploadAll;
@property BOOL reloadAll;
@property BOOL skipAll;
@property BOOL replace;

- (void)reset;

@property (weak) IBOutlet NSToolbarItem *updateControlsToolbarItem;

//@property (strong) Asset *targetAsset;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet TagController *tagController;

@property (unsafe_unretained) IBOutlet NSPanel *authorizationPanel;
@property (weak) IBOutlet WebView *authorizationWebView;
@property (weak) IBOutlet NSView *alertAccessoryView;

- (IBAction)stop:(id)sender;

- (void)reloadAccount:(Account *)account option:(PRAXReloadOption)option replace:(BOOL)replace;

- (void)reloadChangedAssets;
- (void)uploadChangedAssets;

@end
