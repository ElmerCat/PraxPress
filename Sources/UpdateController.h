//
//  UpdateController.h
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Document.h"

@class TagController;

@interface UpdateController : NSObject


@property NSDictionary *parameters;
@property NSURL *resource;
@property NSString *statusText;
@property NSInteger updateCount;
@property NSInteger targetCount;
@property BOOL stop;
@property BOOL busy;
@property BOOL determinate;
@property BOOL uploadAll;
@property BOOL reloadAll;
- (void)reset;

@property (strong) Asset *targetAsset;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet TagController *tagController;

@property (unsafe_unretained) IBOutlet NSPanel *synchronizePanel;

@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSImageView *progressImageWell;


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
