//
//  RequestController.m
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "RequestController.h"

@implementation RequestController

- (NSArray *)keyPathsToObserve {return @[@"self.document.changedAssetsController.arrangedObjects", @"self.statusText"];}

- (id)init {
    self = [super init];
    if (self) {
    NSLog(@"RequestController init");
        
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
        self.responseDataProcessingQueue = [[NSOperationQueue alloc] init];
        [[NSNotificationCenter defaultCenter] addObserverForName:@"PraxDownloadResponseNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *responseAsset = (Asset *)[aNotification object];

            NSLog(@"RequestController PraxDownloadResponseNotification: %@", responseAsset.title);
            
            Asset *uploadAsset = nil;
            Asset *downloadAsset = nil;
            @synchronized(self) {
                if (self.assetsToUpload.count > 0) {
                    self.busy = TRUE;
                    uploadAsset = self.assetsToUpload.anyObject;
                    [self.assetsToUpload removeObject:uploadAsset];
                }
                else if (self.assetsToReload.count > 0) {
                    self.busy = TRUE;
                    downloadAsset = self.assetsToReload.anyObject;
                    [self.assetsToReload removeObject:downloadAsset];
                }
                else self.busy = FALSE;
                
            } // @synchronized(self)
            
            if (uploadAsset) [self uploadAsset:uploadAsset];
            else if (downloadAsset) [self downloadAsset:downloadAsset];
            
        }];

        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                          object:[NXOAuth2AccountStore sharedStore]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSLog(@"RequestController NXOAuth2AccountStoreAccountsDidChangeNotification");
                                                          // Update your UI
                                                          //          if ([SCSoundCloud account]) {
                                                          [self.document.authorizationWindow close];
                                                          //          }
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                          object:[NXOAuth2AccountStore sharedStore]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                          
                                                          NSLog(@"RequestController NXOAuth2AccountStoreDidFailToRequestAccessNotification error:%@", error);
                                                          
                                                          // Do something with the error
                                                      }];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"493"
                                                 secret:@"Xkd4JjiFceH8OVFqEsaZtP5eGtONxnFP3Emq2mlQoiJBvw7HtpbHbniHmQdaXuhg"
                                       authorizationURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/authorize"]
                                               tokenURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/token"]
                                            redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/wordpress/redirect/"]
                                         forAccountType:@"WordPress"];
        
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"cdb0237a5d0244d2f0528ae9da6ca41f"
                                                 secret:@"48d5ef73f4dd1281e5d41100ba58261a"
                                       authorizationURL:[NSURL URLWithString:@"https://soundcloud.com/connect"]
                                               tokenURL:[NSURL URLWithString:@"https://api.soundcloud.com/oauth2/token"]
                                            redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                         forAccountType:@"SoundCloud"];
        

        // YouTube developer key = "AI39si7b1wiC17l1KoIAB1maTGrjfVfeKEzm6yRElmdBiOlcj75NFktrwd4oBdY2CS1j54hVPmnWhY9KGj9NaBul3BL_nk_Vsg"
        
/*        [[NXOAuth2AccountStore sharedStore] setClientID:@"PRAX1234"
                                                 secret:@"prax4321"
                                       authorizationURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/auth"]
                                               tokenURL:[NSURL URLWithString:@"https://elmercat.org/oauth2/token1234"]
                                            redirectURL:[NSURL URLWithString:@"praxpress://elmercat.org/redirect/youtube"]
                                         forAccountType:@"YouTube"];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"655714d0dd3e55f1c5e8437af00228f8"
                                                 secret:@"9fc17d4240498d56"
                                       authorizationURL:[NSURL URLWithString:@"http://flickr.com/services/auth/"]
                                               tokenURL:[NSURL URLWithString:@"http://www.flickr.com/services/oauth/request_token"]
                                            redirectURL:[NSURL URLWithString:@"praxpress://elmercat.org/redirect/flickr"]
                                         forAccountType:@"Flickr"];
  */
        
    }

    [self reset];
    return self;
}

- (void)awakeFromNib {
        NSLog(@"RequestController awakeFromNib");
    
/*    [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
                                                      object:self.changedAssetsTableView
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      if ([aNotification object] == self.changedAssetsTableView){
                                                          
                                                          NSLog(@"changedAssetsTableView NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                 //         if (self.changedAssetsController.selectedObjects.count > 0) {
                                                  //            self.batchController.selectedAsset = [self.changedAssetsController selectedObjects][0];
                                                  //            if ([self.batchController.assetDetailPanel isVisible])
                                                  //                [self.batchController.assetDetailPanel makeKeyAndOrderFront:self];
                                                  //        }
                                                      }
                                                      
                                                      else NSLog(@"RequestController NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                      
                                                      
                                                  }];
  */  

}

- (void)dealloc {
    NSLog(@"RequestController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.document.changedAssetsController.arrangedObjects"]) {
        NSInteger count = [self.document.changedAssetsController.arrangedObjects count];
        
        if ((count > 0) && (self.document.changedAssetsView.frame.size.height < 150)) {
            self.document.changedAssetsView.hidden = NO;
            
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:1];
            NSRect newCollapsingFrame = self.document.assetsView.frame;
            newCollapsingFrame.size.height = self.document.leftSplitView.frame.size.height-150;
            [[self.document.assetsView animator] setFrame:newCollapsingFrame];
            
            NSRect newExpandingFrame = self.document.changedAssetsView.frame;
            newExpandingFrame.size.height = 150;
            newExpandingFrame.origin.x = self.document.leftSplitView.frame.size.height-150;
            [[self.document.changedAssetsView animator] setFrame:newExpandingFrame];
            
            [NSAnimationContext endGrouping];
            
        }
        else if ([keyPath isEqualToString:@"self.statusText"]) {
            [self.updateControlsToolbarItem setLabel:self.statusText];
        }
        else if ((!count) && (self.document.changedAssetsView.frame.size.height > 0)) {
            
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:1];
            NSRect newExpandingFrame = self.document.assetsView.frame;
            newExpandingFrame.size.height =  self.document.leftSplitView.frame.size.height;
            [[self.document.assetsView animator] setFrame:newExpandingFrame];
            
            NSRect newCollapsingFrame = self.document.changedAssetsView.frame;
            newCollapsingFrame.size.height = 0.0f;
            newCollapsingFrame.origin.x = self.document.leftSplitView.frame.size.height;
            [[self.document.changedAssetsView animator] setFrame:newCollapsingFrame];

            [NSAnimationContext endGrouping];
            
        }       
    }
    else if ([keyPath isEqualToString:@"self.pendingAssetsToReload"]) {

    
    }
    else {
        NSLog(@"RequestController observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    }
}



- (void)removeAccessForAccountType:(NSString *)accountType {
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:accountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
}

- (IBAction)stop:(id)sender {
    self.stop = TRUE;
}

- (IBAction)uploadChangedItems:(id)sender {
    if (self.busy) return;
    self.targetCount = [self.document.changedAssetsController.arrangedObjects count];
    if (self.targetCount < 1) return;
    self.updateCount = 0;
    self.uploadAll = TRUE;
    [self uploadChangedAssets];
}

-(void)uploadChangedAssets {
    if ([self.document.changedAssetsController.arrangedObjects count] < 1) {
        [self reset];
        return;
    }
    else if ((self.targetCount - self.updateCount) > 1) self.determinate = YES;
    else self.determinate = NO;
    [self uploadAsset:self.document.changedAssetsController.arrangedObjects[0]];
}

- (IBAction)reloadChangedItems:(id)sender {
    if (self.busy) return;
    self.targetCount = [self.document.changedAssetsController.arrangedObjects count];
    if (self.targetCount < 1) return;
    self.updateCount = 0;
    self.reloadAll = TRUE;
    [self reloadChangedAssets];
}

-(void)reloadChangedAssets {
    if ([self.document.changedAssetsController.arrangedObjects count] < 1) {
        [self reset];
        return;
    }
    else if ((self.targetCount - self.updateCount) > 1) self.determinate = YES;
    else self.determinate = NO;
    [self reloadAsset:self.document.changedAssetsController.arrangedObjects[0]];
}


- (void)reset {
    if (!self.assetsToReload) self.assetsToReload = [NSMutableSet setWithCapacity:1];
    else [self.assetsToReload removeAllObjects];
    if (!self.assetsToUpload) self.assetsToUpload = [NSMutableSet setWithCapacity:1];
    else [self.assetsToUpload removeAllObjects];
    
    self.determinate = NO;
    self.uploadAll = NO;
    self.reloadAll = NO;
    self.updateCount = 0;
    self.targetCount = 0;
    self.statusText = @"";
    self.resource = nil;
    self.busy = NO;
    self.stop = NO;
    [self.updateControlsToolbarItem setLabel:@""];
}

- (void)reloadAllAssetData:(Asset *)asset {
    self.reloadAll = YES;
//    [self.document.accountViewPopover performClose:self];
    [self reloadAssetAccountData:asset];
}
- (void)reloadAssetAccountData:(Asset *)asset {
    [self reloadAsset:asset option:PRAXReloadOptionAccount];
}
- (void)reloadAssetSiteData:(Asset *)asset {
    [self reloadAsset:asset option:PRAXReloadOptionSite];
}
- (void)reloadAssetPostsData:(Asset *)asset {
    [self reloadAsset:asset option:PRAXReloadOptionPosts];
}
- (void)reloadAssetTracksData:(Asset *)asset {
    [self reloadAsset:asset option:PRAXReloadOptionTracks];
}
- (void)reloadAssetPlaylistsData:(Asset *)asset {
    [self reloadAsset:asset option:PRAXReloadOptionPlaylists];
}

- (void)reloadAsset:(Asset *)asset {
    [self reloadAsset:asset option:0];
}

- (void)downloadAsset:(Asset *)asset {
    if (self.stop) {
        [self reset];
        return;
    }
    NXOAuth2Request *request = [asset requestForReloadController:self option:0];
    if (!request) return;
    self.busy = TRUE;
    [self.updateControlsToolbarItem setLabel:@"Downloading"];
    
    NSLog(@"updateMode GET request.account: %@ resource: %@ ", request.account, self.resource);
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
  
                                          if (error) {
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil);
                                              [[NSSound soundNamed:@"Error"] play];
                                              [self reset];
                                          }
                                          [self.responseDataProcessingQueue addOperationWithBlock:^{
                                              if (![asset handleReloadResponseData:data forController:self]) {
                                                  [[NSSound soundNamed:@"Error"] play];
                                                  [self reset];
                                              }
                                          }];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"PraxDownloadResponseNotification" object:asset];

                                      }];
}

- (void)reloadAsset:(Asset *)asset option:(PRAXReloadOption)option {
    if (self.stop) {
        [self reset];
        return;
    }
    NXOAuth2Request *request = [asset requestForReloadController:self option:option];
    if (!request) return;
    self.busy = TRUE;
    [self.updateControlsToolbarItem setLabel:@"Downloading"];
    
    //    NSLog(@"updateMode GET request.account: %@ resource: %@ ", request.account, self.resource);
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                          if (error) {
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil);
                                              [[NSSound soundNamed:@"Error"] play];
                                              [self reset];
                                          }
                                          else if (![asset handleReloadResponseData:data forController:self]) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              [self reset];
                                          }
                                      }];
}

- (void)uploadAsset:(Asset *)asset {
    if (self.stop) {
        [self reset];
        return;
    }
    
    NXOAuth2Request *request = [asset requestForUploadController:self];
    if (!request) return;
    
    self.busy = TRUE;
    
    NSLog(@"request.account: %@ resource: %@  parameters: %@", request.account, self.resource, self.parameters);
    
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                          if (error) {
                                              NSLog(@"NXOAuth2Request error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, self.parameters);
                                              [[NSSound soundNamed:@"Error"] play];
                                              [self reset];
                                          }
                                          else {
                                              [[NSSound soundNamed:@"Connect"] play];
                                              
                                              if ([asset.asset_id.stringValue isEqualToString:@"0"]) {
                                                  
/*                                                  NSString *stringX = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                  
                                                  id itemX = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:0];
                                                  NSError *error = nil;
                                            //      NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                                  NSDictionary *item;
                                                  if (([asset.type isEqualToString:@"track"]) || ([asset.type isEqualToString:@"playlist"])) {
                                                      item = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                      NSLog(@"item: %@", item);
                                                      [asset loadSoundCloudItemData:item];
                                                      if ([asset.entity.name isEqualToString:@"Playlist"]) {
                                                          [asset loadPlaylistsAsset:asset data:item];
                                                      }
                                                  }
                                                  else if (([asset.type isEqualToString:@"post"]) || ([asset.type isEqualToString:@"page"])) {
                                                      item = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
                                                      NSLog(@"item: %@", item);
                                                      [asset loadWordPressPostData:item];
                                                  }
                                                  [self.tagController loadAssetTags:asset];
                                                  asset.sync_mode = [NSNumber numberWithBool:FALSE];
  */                                                                                                  
                                              }
                                              
                                              else {
                                                  
                                          //        [self reloadAsset:asset];
                                                  [self.assetsToReload addObject:asset];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:@"PraxDownloadResponseNotification" object:asset];
                                              }
                                              
                                               
                                          }
                                      }];
}


- (void)logoutAccount:(Asset *)account {
    [self removeAccessForAccountType:account.accountType];
    account.oauthAccount = nil;
}

- (void)start {
    if (self.stop) {
        [self reset];
        return;
    }
    Asset *uploadAsset = nil;
    Asset *downloadAsset = nil;
    @synchronized(self) {
        if(self.busy) return;
        
        if (self.assetsToUpload.count > 0) {
            self.busy = TRUE;
            uploadAsset = self.assetsToUpload.anyObject;
            [self.assetsToUpload removeObject:uploadAsset];
        }
        else if (self.assetsToReload.count > 0) {
            self.busy = TRUE;
            downloadAsset = self.assetsToReload.anyObject;
            [self.assetsToReload removeObject:downloadAsset];
        }
        
    } // @synchronized(self)
    
    if (uploadAsset) [self uploadAsset:uploadAsset];
    else if (downloadAsset) [self downloadAsset:downloadAsset];
    else [self reset];
}


- (void)uploadAssetsForClient:(id)client {
    if ([client isKindOfClass:[AssetListViewController class]]) {
        
        for (Asset *asset in [[(AssetListViewController *)client assetArrayController] selectedObjects]) {
            if (asset.sync_mode.boolValue) [self.assetsToUpload addObject:asset];
        }
        
    }
    else {
        [[NSSound soundNamed:@"Error"] play];
    }
    if (self.assetsToUpload.count > 0) [self start];
    
}

- (void)reloadAssetsForClient:(id)client {
    if ([client isKindOfClass:[AssetListViewController class]]) {
        
        for (Asset *asset in [[(AssetListViewController *)client assetArrayController] selectedObjects]) {
            if (asset.sync_mode.boolValue) [self.assetsToReload addObject:asset];
        }
        
    }
    else {
        [[NSSound soundNamed:@"Error"] play];
    }
    if (self.assetsToReload.count > 0) [self start];
    
}

@end
