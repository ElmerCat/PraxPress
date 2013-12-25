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
#import "Asset.h"
#import "Tag.h"
#import "TagController.h"
#import "AssetListViewController.h"

@class PostEditor;
@class TagController;

@interface RequestController : NSObject

@property NSOperationQueue *responseDataProcessingQueue;

@property NSDictionary *parameters;
@property NSURL *resource;
@property NSString *statusText;
@property NSInteger updateCount;
@property NSInteger targetCount;


- (void)reloadAssetsForClient:(id)client;
@property NSMutableSet *assetsToReload;
- (void)uploadAssetsForClient:(id)client;
@property NSMutableSet *assetsToUpload;


@property BOOL stop;
@property BOOL busy;
@property BOOL determinate;
@property BOOL uploadAll;
@property BOOL reloadAll;
- (void)reset;
@property (weak) IBOutlet NSToolbarItem *updateControlsToolbarItem;

@property (strong) Asset *targetAsset;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet TagController *tagController;

@property (unsafe_unretained) IBOutlet NSPanel *authorizationPanel;
@property (weak) IBOutlet WebView *authorizationWebView;

- (IBAction)uploadChangedItems:(id)sender;
- (IBAction)reloadChangedItems:(id)sender;
- (IBAction)stop:(id)sender;

- (void)reloadAllAssetData:(Asset *)asset;
- (void)reloadAssetAccountData:(Asset *)asset;
- (void)reloadAssetSiteData:(Asset *)asset;
- (void)reloadAssetPostsData:(Asset *)asset;
- (void)reloadAssetTracksData:(Asset *)asset;
- (void)reloadAssetPlaylistsData:(Asset *)asset;

- (void)reloadAsset:(Asset *)asset;
- (void)reloadAsset:(Asset *)asset option:(NSUInteger)option;
- (void)uploadAsset:(Asset *)asset;
- (void)reloadChangedAssets;
- (void)uploadChangedAssets;
- (void)logoutAccount:(Asset *)account;

@end
