//
//  RequestController.m
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "RequestController.h"

@implementation RequestController


- (id)init {
    self = [super init];
    if (self) {
    NSLog(@"RequestController init");
        
 //       self.dataQueue = @[].mutableCopy;
        
//        self.responseHandlingQueue = dispatch_queue_create("responseHandlingQueue", DISPATCH_QUEUE_CONCURRENT);
        
        
 //       self.responseDataProcessingQueue = [[NSOperationQueue alloc] init];
        
    }

    [self reset];
    return self;
}

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = YES;
        NSLog(@"RequestController awakeFromNib");
        
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        [[NSNotificationCenter defaultCenter] addObserverForName:@"PraxDownloadResponseNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *responseAsset = (Asset *)[aNotification object];
            
            self.statusText = [NSString stringWithFormat:@"Processing %@", responseAsset.title];
            //NSLog(@"RequestController PraxDownloadResponseNotification: %@", responseAsset.title);
            
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
                else [self reset];
                
            } // @synchronized(self)
            
            if (uploadAsset) [self uploadAsset:uploadAsset];
            else if (downloadAsset) [self downloadAsset:downloadAsset];
            
        }];
        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification){
            NSLog(@"RequestController NXOAuth2AccountStoreAccountsDidChangeNotification");
            
            NXOAuth2Account *oauthAccount = [aNotification userInfo][NXOAuth2AccountStoreNewAccountUserInfoKey];
            if (oauthAccount) {
                if (self.authorizationPanel.isVisible) {
                    [self.authorizationPanel close];
                }
                if (self.pendingAssetToReload) {
                    [self downloadAsset:self.pendingAssetToReload];
                    self.pendingAssetToReload = nil;
                }
                else if (self.pendingAccountToReload) {
                    [self reloadAccount:self.pendingAccountToReload option:self.pendingOption replace:self.replace];
                    self.pendingAccountToReload = nil;
                }
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] queue:nil usingBlock:^(NSNotification *aNotification){
            NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
            
            [Prax presentAlert:[NSString stringWithFormat:@"RequestController NXOAuth2AccountStoreDidFailToRequestAccessNotification\n NXOAuth2AccountStoreErrorKey:%@", error] forController:self];
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
}

- (void)dealloc {
    NSLog(@"RequestController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)keyPathsToObserve {return @[@"self.pendingAssetsToReload",
                                         @"self.busy",
                                         @"self.statusText"];}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.statusText"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.updateControlsToolbarItem setLabel:self.statusText];
        });
        
    }
    else if ([keyPath isEqualToString:@"self.busy"]) {
        
        
    }
    else if ([keyPath isEqualToString:@"self.pendingAssetsToReload"]) {
        
        
    }
    else {
        NSLog(@"RequestController observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    }
}




- (IBAction)stop:(id)sender {
    self.stop = TRUE;
}


- (void)reset {
    if (!self.assetsToReload) self.assetsToReload = [NSMutableSet setWithCapacity:1];
    else [self.assetsToReload removeAllObjects];
    if (!self.assetsToUpload) self.assetsToUpload = [NSMutableSet setWithCapacity:1];
    else [self.assetsToUpload removeAllObjects];
    self.pendingAssetToReload = nil;
    self.pendingAccountToReload = nil;
    self.pendingOption = 0;
    
    self.determinate = NO;
    self.uploadAll = NO;
    self.reloadAll = NO;
    self.skipAll = NO;
    self.replace = NO;
    self.updateCount = 0;
    self.targetCount = 0;
    self.statusText = @"";
    self.resource = nil;
    self.busy = NO;
    self.stop = NO;
}

- (void)reloadAccount:(Account *)account option:(PRAXReloadOption)option replace:(BOOL)replace {
    if (self.stop) {
        [self reset];
        return;
    }

    if (option) account.updateOption = option;
    else account.updateOption = PRAXReloadOptionAccount;
    self.replace = replace;
    self.skipAll = replace;
    
    if (!account.oauthAccount) {
        if (![self authorizeAccount:account]) {
            [self reset];
            self.pendingAccountToReload = account;
            self.pendingOption = account.updateOption;
            self.replace = replace;
            return;
        }
    }
    NXOAuth2Request *request = [account requestForDownloadController:self];
    if (!request) return;
    self.busy = TRUE;
    self.statusText = [NSString stringWithFormat:@"Downloading %@ - %@", account.name, self.resource];
    
    [request performRequestWithSendingProgressHandler:^(unsigned long long sent, unsigned long long total) {
        NSLog(@"performRequestWithSendingProgressHandler sent=%llu total=%llu", sent, total);
        
    } responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [Prax presentAlert:[NSString stringWithFormat:@"NXOAuth2Request GET error: %@ \nresource: %@ \nparameters: %@", [error localizedDescription], self.resource, nil] forController:self];
            [self reset];
        }
        else [account handleReloadResponseData:data forController:self];
    }];
}

- (void)downloadAsset:(Asset *)asset {
    if (self.stop) {
        [self reset];
        return;
    }
    if ([asset isInSync]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PraxDownloadResponseNotification" object:asset];
        return;
    }
    NXOAuth2Request *request = [asset requestForReloadController:self];
    if (!request) return;
    self.busy = TRUE;
    self.statusText = [NSString stringWithFormat:@"Downloading %@", asset.title];
    [request performRequestWithSendingProgressHandler:^(unsigned long long sent, unsigned long long total) {
        NSLog(@"performRequestWithSendingProgressHandler sent=%llu total=%llu", sent, total);
    } responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            [Prax presentAlert:[NSString stringWithFormat:@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil] forController:self];
            [self reset];
        }
        //       dispatch_async(self.responseHandlingQueue, ^{
        [asset handleReloadResponseData:data forController:self];
        //       });
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PraxDownloadResponseNotification" object:asset];
        
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
    self.statusText = [NSString stringWithFormat:@"Uploading %@", asset.title];
    [request performRequestWithSendingProgressHandler:^(unsigned long long sent, unsigned long long total) {
        NSLog(@"performRequestWithSendingProgressHandler sent=%llu total=%llu", sent, total);
        
    } responseHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [Prax presentAlert:[NSString stringWithFormat:@"NXOAuth2Request error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, self.parameters] forController:self];
            [self reset];
        }
        else {
            [[NSSound soundNamed:@"Connect"] play];
            
            if ([asset.asset_id.stringValue isEqualToString:@"0"]) {
                
            }
            else {
                [self.assetsToReload addObject:asset];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PraxDownloadResponseNotification" object:asset];
            }
            
            
        }
    }];
}


- (BOOL)authorizeAccount:(Account *)account {
    
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:account.name];
    if ([oauthAccounts count] > 0) {
        account.oauthAccount = oauthAccounts[0];
        return YES;
    } else {
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:account.name
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           NSRect screen = [[NSScreen mainScreen] frame];
                                           NSRect frame = {(screen.size.width/2), (screen.size.height/2), 0, 0};
                                           [self.authorizationPanel.animator setFrame:frame display:YES];
                                           [self.authorizationPanel makeKeyAndOrderFront:self];
                                           [[self.authorizationWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                           frame.origin.x = screen.origin.x + 200;
                                           frame.origin.y  = screen.origin.y + 100;
                                           frame.size.width = screen.size.width - 400;
                                           frame.size.height = screen.size.height - 200;
                                           [self.authorizationPanel.animator setFrame:frame display:YES];
                                       }];
        
        return NO;
    }
}

- (void)start {
    if (self.stop) {
        [self reset];
        return;
    }
    Asset *asset = nil;
    BOOL upload = FALSE;
    @synchronized(self) {
        if(self.busy) return;
        if (self.assetsToUpload.count > 0) {
            upload = TRUE;
            asset = self.assetsToUpload.anyObject;
        }
        else if (self.assetsToReload.count > 0) {
            self.replace = YES;
            asset = self.assetsToReload.anyObject;
        }
        if (upload) [self.assetsToUpload removeObject:asset];
        else [self.assetsToReload removeObject:asset];
        self.busy = TRUE;
        
    } // @synchronized(self)
    
    if (!asset.account.oauthAccount) {
        self.pendingAssetToReload = asset;
        if (![self authorizeAccount:asset.account]) {
            return;
        }
    }

    if ((asset) && (asset.account.oauthAccount)) {
        if (upload) [self uploadAsset:asset];
        else [self downloadAsset:asset];
    }
}


- (void)uploadAssetsForClient:(id)client {
    if (self.busy) return;
    
    [self.document.documentWindow makeFirstResponder:nil];

    if ([client isKindOfClass:[AssetListViewController class]]) {
        
        for (Asset *asset in [[(AssetListViewController *)client assetArrayController] selectedObjects]) {
            if (asset.sync_mode.boolValue) [self.assetsToUpload addObject:asset];
        }
        
    }
    else {
        [Prax presentAlert:@"uploadAssetsForClient NOT isKindOfClass:[AssetListViewController class]" forController:self];
    }
    if (self.assetsToUpload.count > 0) [self start];
    
}

- (void)reloadAssetsForClient:(id)client {
    if (self.busy) return;
    if ([client isKindOfClass:[AssetListViewController class]]) {
        
        for (Asset *asset in [[(AssetListViewController *)client assetArrayController] selectedObjects]) {
            if (asset.sync_mode.boolValue) [self.assetsToReload addObject:asset];
        }
        
    }
    else {
        [Prax presentAlert:@"reloadAssetsForClient NOT isKindOfClass:[AssetListViewController class]" forController:self];
    }
    if (self.assetsToReload.count > 0) [self start];
    
}

@end
