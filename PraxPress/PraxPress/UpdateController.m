//
//  UpdateController.m
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "UpdateController.h"

@implementation UpdateController
@synthesize assetsController;

- (id)init {
    self = [super init];
    if (self) {
    //    NSLog(@"UpdateController init");
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateNotification:)
                                                     name:@"updateNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(responseNotification:)
                                                     name:@"responseNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                          object:[NXOAuth2AccountStore sharedStore]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSLog(@"UpdateController NXOAuth2AccountStoreAccountsDidChangeNotification");
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
                                                          
                                                          NSLog(@"UpdateController NXOAuth2AccountStoreDidFailToRequestAccessNotification error:%@", error);
                                                          
                                                          // Do something with the error
                                                      }];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"PRAX1234"
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
        
       
        
        
        
    }
    return self;
}


- (void)awakeFromNib {
        NSLog(@"UpdateController awakeFromNib");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
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
                                                      
                                                      else NSLog(@"UpdateController NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                      
                                                      
                                                  }];
    

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    self.updateCount = 0;
    self.targetCount = [self.changedAssetsController.arrangedObjects count];
    
    if (self.targetCount < 1) return;

    self.uploadChangedItems = TRUE;
    
    [self uploadChangedAssets];
}

-(void)uploadChangedAssets {

    if ([self.changedAssetsController.arrangedObjects count] < 1) {
        self.uploadChangedItems = FALSE;
        self.busy = FALSE;
        [self.synchronizePanel close];
        return;
    }
    else if ((self.targetCount - self.updateCount) > 1) [self.progressBar setIndeterminate:FALSE];
    else [self.progressBar setIndeterminate:TRUE];
    
    [self uploadAsset:self.changedAssetsController.arrangedObjects[0]];
    
}

- (IBAction)reloadChangedItems:(id)sender {
    if (self.busy) return;
    self.updateCount = 0;
    self.targetCount = [self.changedAssetsController.arrangedObjects count];
    
    if (self.targetCount < 1) return;
    
    self.reloadChangedItems = TRUE;
    
    [self reloadChangedAssets];

    
}

-(void)reloadChangedAssets {
    
    if ([self.changedAssetsController.arrangedObjects count] < 1) {
        self.reloadChangedItems = FALSE;
        self.busy = FALSE;
        [self.synchronizePanel close];
        return;
    }
    else if ((self.targetCount - self.updateCount) > 1) [self.progressBar setIndeterminate:FALSE];
    else [self.progressBar setIndeterminate:TRUE];
    
    [self reloadAsset:self.changedAssetsController.arrangedObjects[0]];
    
}



- (IBAction)reloadFromServer:(id)sender {
    if (self.busy) return;
    
     [self reloadAsset:[self.batchController selectedAsset]];
    
}

- (void)reloadAsset:(Asset *)asset {
    
    NSURL *resource;
    NSDictionary *parameters;
    
    if (![asset.account oauthReady:self.document]) return;

    
    if ([asset.account.accountType isEqualToString:@"SoundCloud"]) {
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", asset.uri]];
    }
    
    else if ([asset.account.accountType isEqualToString:@"WordPress"]) {
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", asset.uri, asset.asset_id]];
        parameters = @{@"context":@"edit"};
    }
    else return;
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:resource method:@"GET" parameters:parameters];
    request.account = asset.account.oauthAccount;
    if (!request.account) return;
    self.busy = TRUE;
    NSLog(@"updateMode GET request.account: %@ resource: %@ ", request.account, resource);
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], resource, nil);
                                              self.busy = FALSE;
                                          }
                                          else {
                                              NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                              NSDictionary *item;
                                              if (([asset.type isEqualToString:@"track"]) || ([asset.type isEqualToString:@"playlist"])) {
                                                  item = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
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
                                              [self.changedAssetsController rearrangeObjects];
                                              self.updateCount += 1;
                                              if (self.reloadChangedItems) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self reloadChangedAssets];
                                                  });
                                              }
                                              else if (self.uploadChangedItems) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self uploadChangedAssets];
                                                  });
                                              }
                                              else {
                                                  
                                                  self.busy = FALSE;
                                                  [self.synchronizePanel close];
                                              }
                                          }
                                      }];
}

- (IBAction)uploadToServer:(id)sender {
    if (self.busy) return;
    [self.progressBar setIndeterminate:TRUE];
    [self uploadAsset:self.batchController.selectedAsset];
}

- (void)uploadAsset:(Asset *)asset {
    if (self.stop) {
        self.busy = FALSE;
        [self.synchronizePanel close];
        self.stop = FALSE;
        return;
    }
    
    NXOAuth2Request *request = [asset updateRequest:self];
    if (!request) return;
    
    self.busy = TRUE;
    
    NSLog(@"request.account: %@ resource: %@  parameters: %@", request.account, self.resource, self.parameters);
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, self.parameters);
                                              self.busy = FALSE;

                                          }
                                          else {
                                              [[NSSound soundNamed:@"Connect"] play];

                                              [self reloadAsset:asset];
                                          }
                                      }];
}

- (IBAction)logout:(id)sender {
    if (self.busy) return;
    
    self.account = [(NSTableCellView *)[(NSButton *)sender superview] objectValue];
    
    [self removeAccessForAccountType:self.account.accountType];
    self.account.oauthAccount = nil;
}



- (void)logoutAccount:(Account *)account {

    self.account = account;
    
    [self removeAccessForAccountType:self.account.accountType];
    self.account.oauthAccount = nil;
}



- (void)refreshAccountData:(Account *)account {
    
    if (self.busy) return;
    
    self.account = account;
    
    if (![self.account oauthReady:self.document]) {
        [self.synchronizePanel close];
        return;
    }
    
    if ([self.account.accountType isEqualToString:@"SoundCloud"]) {
        self.statusText = @"Downloading SoundCloud User Profile";
        self.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
        
    }
    else if ([self.account.accountType isEqualToString:@"WordPress"]) {
        self.statusText = @"Downloading WordPress User Profile";
        self.resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
    }
    
    /*  else if ([self.account.accountType isEqualToString:@"Flickr]) {
     self.statusText = @"Downloading Flickr User Profile";
     self.resource = [NSURL URLWithString:@"https://public-api.Flickr.com/rest/v1/me"];
     }
     */
    /*  else if ([self.account.accountType isEqualToString:@"YouTube]) {
     self.statusText = @"Downloading YouTube User Profile";
     self.resource = [NSURL URLWithString:@"https://public-api.YouTube.com/rest/v1/me"];
     }
     */
    
    else {
        [self.synchronizePanel close];
        return;
        
    }
    self.busy = TRUE;
    [self.progressBar setIndeterminate:TRUE];
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:self.resource method:@"GET" parameters:nil];
    request.account = self.account.oauthAccount;

    [request performRequestWithSendingProgressHandler:nil responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
        if (error) {
            [[NSSound soundNamed:@"Error"] play];
            NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil);
            self.busy = FALSE;
            
        }
        else {
            NSError *__autoreleasing *jsonError = NULL;
            NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
            NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
            
            if ([self.account.accountType isEqualToString:@"SoundCloud"]) {
                
                [self.account loadSoundCloudAccountData:data];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    
                    self.statusText = @"Downloading Tracks";
                    self.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
                    self.updateCount = 0;
                    self.targetCount = [self.account.track_count integerValue];
                    [self.progressBar setIndeterminate:FALSE];
                    
                    [self performTracksGetRequest];
                });
                
            }
            else if ([self.account.accountType isEqualToString:@"WordPress"]) {
                [self.account loadWordPressAccountData:data];
                
                self.statusText = @"Downloading WordPress SiteData";
                self.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://public-api.wordpress.com/rest/v1/sites/%@", self.account.asset_id]];
                
                [request setResource:self.resource];
                
                [request performRequestWithSendingProgressHandler:nil responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                    if (error) {
                        [[NSSound soundNamed:@"Error"] play];
                        NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil);
                    }
                    else {
                        NSError *__autoreleasing *jsonError = NULL;
                        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                        NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
                        [self.account loadWordPressSiteData:data];
                        
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        self.statusText = @"Downloading WordPress Posts";
                        self.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://public-api.wordpress.com/rest/v1/sites/%@/posts/", self.account.asset_id]];
                        
                        [request setResource:self.resource];
                        
                        
                        [request setParameters:@{@"status":@"any", @"type":@"page", @"number":@"1"}];

                        
                        [request performRequestWithSendingProgressHandler:nil responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                            if (error) {
                                [[NSSound soundNamed:@"Error"] play];
                                NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil);
                            }
                            else {
                                NSError *__autoreleasing *jsonError = NULL;
                                NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                                NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
                                
                                
                                [self.account loadWordPressPageCount:data];
                                
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                self.statusText = @"Downloading WordPress Posts";
                                self.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://public-api.wordpress.com/rest/v1/sites/%@/posts/", self.account.asset_id]];
                                
                                
                                
                                
                                
                                self.updateCount = 0;
                                self.targetCount = [self.account.track_count integerValue];
                                [self.progressBar setIndeterminate:FALSE];
                                
                                
                                [self performPostsGetRequest];
                            });
                            
                            
                        }];
                        
                    });
                    
                    
                }];
            }
        }
    }];
    
}

- (void) performPostsGetRequest {
    
    if (self.stop) {
        self.busy = FALSE;
        [self.synchronizePanel close];

        self.stop = FALSE;
        return;
    }
    
    NSDictionary *parameters = @{@"status":@"any", @"type":@"any", @"context":@"edit", @"number":@"10", @"offset":[[NSNumber numberWithInteger:self.updateCount] stringValue]};
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:self.resource method:@"GET" parameters:parameters];
    request.account = self.account.oauthAccount;
    
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, parameters);
                                              self.busy = FALSE;
                                          }
                                          else {
                                              
                                              NSError *__autoreleasing *jsonError = NULL;
                                              NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                                              NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
                                              data = data[@"posts"];
               
                                              Asset *asset;
                                              for (NSDictionary *item in data) {
                                                  
                                                  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
                                                  [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"ID"]]];
                                                  NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
                                                  if ([matchingItems count] < 1) {
                                                      asset = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:self.document.managedObjectContext];
                                                      asset.asset_id = [NSNumber numberWithInt:[item[@"ID"] intValue]];
                                                      asset.batchPosition = [NSNumber numberWithInt:-1];
                                                      
                                                  }
                                                  else asset = matchingItems[0];
                                                  asset.account = self.account;
                                                  
                                                  [asset loadWordPressPostData:item];
                                                  
                                                  self.updateCount = self.updateCount + 1;
                                                  [self.assetsController rearrangeObjects];
                                                  [self.changedAssetsController rearrangeObjects];
                                              }
                                              
                                              if (self.updateCount >= self.targetCount) {
                                                  
                                                  self.busy = FALSE;
                                                  [self.synchronizePanel close];

                                                  
                                              }
                                              else {
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self performPostsGetRequest];
                                                  });
                                                  
                                              }
                                          }
                                      }];
    
}

- (void) performTracksGetRequest {
    
    if (self.stop) {
        self.busy = FALSE;
        [self.synchronizePanel close];

        self.stop = FALSE;
        return;
    }
    
    NSDictionary *parameters = @{@"limit":@"10", @"offset":[[NSNumber numberWithInteger:self.updateCount] stringValue]};
    
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:self.resource method:@"GET" parameters:parameters];
    request.account = self.account.oauthAccount;
    
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, parameters);
                                              self.busy = FALSE;
                                          }
                                          else {
                                              
                                              NSError *__autoreleasing *jsonError = NULL;
                                              NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                                              NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
                                              
                                              
                                              Asset *asset;
                                              for (NSDictionary *item in data) {
                                                  
                                                  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
                                                  [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
                                                  NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
                                                  if ([matchingItems count] < 1) {
                                                      asset = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:self.document.managedObjectContext];
                                                      asset.asset_id = [NSNumber numberWithInt:[item[@"id"] intValue]];
                                                      asset.batchPosition = [NSNumber numberWithInt:-1];
                                                      
                                                  }
                                                  else asset = matchingItems[0];
                                                  asset.account = self.account;
                                                  
                                                  [self.progressImageWell setImage:[asset loadSoundCloudItemData:item]];

                                                  
                                                  //  if ([asset.entity.name isEqualToString:@"Playlist"]) {
                                                  //     [asset loadPlaylistsAsset:asset data:item];
                                                  // }
                                                  self.updateCount = self.updateCount + 1;
                                                  [self.assetsController rearrangeObjects];
                                                  [self.changedAssetsController rearrangeObjects];
                                              }
                                              
                                              if (self.updateCount >= self.targetCount) {
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      
                                                      self.statusText = @"Downloading Playlists";
                                                      self.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
                                                      self.updateCount = 0;
                                                      self.targetCount = [self.account.playlist_count integerValue];
                                                      
                                                      [self performPlaylistsGetRequest];
                                                  });
                                                  
                                              }
                                              else {
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self performTracksGetRequest];
                                                  });
                                                  
                                              }
                                          }
                                      }];
    
}


- (void) performPlaylistsGetRequest {
    
    if (self.stop) {
        self.busy = FALSE;
        [self.synchronizePanel close];
        
        self.stop = FALSE;
        return;
    }
    
    NSDictionary *parameters = @{@"limit":@"1", @"offset":[[NSNumber numberWithInteger:self.updateCount] stringValue]};
    
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:self.resource method:@"GET" parameters:parameters];
    request.account = self.account.oauthAccount;
    
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, parameters);
                                              self.busy = FALSE;
                                          }
                                          else {
                                              
                                              NSError *__autoreleasing *jsonError = NULL;
                                              NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                                              NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
                                              
                                              
                                              Asset *asset;
                                              for (NSDictionary *item in data) {
                                                  
                                                  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
                                                  [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
                                                  NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
                                                  if ([matchingItems count] < 1) {
                                                      asset = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:self.document.managedObjectContext];
                                                      asset.asset_id = [NSNumber numberWithInt:[item[@"id"] intValue]];
                                                      asset.batchPosition = [NSNumber numberWithInt:-1];
                                                      
                                                  }
                                                  else asset = matchingItems[0];
                                                  asset.account = self.account;
                                                  
                                                  [self.progressImageWell setImage:[asset loadSoundCloudItemData:item]];
                                                  [asset loadPlaylistsAsset:asset data:item];
                                                  self.updateCount = self.updateCount + 1;
                                              }
                                              [self.assetsController rearrangeObjects];
                                              [self.changedAssetsController rearrangeObjects];

                                              
                                              if (self.updateCount >= self.targetCount) {
                                                    
                                                  self.busy = FALSE;
                                                  [self.synchronizePanel close];
                                                  
                                              }
                                              else {
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self performPlaylistsGetRequest];
                                                  });
                                                  
                                                  
                                              }
                                          }
                                      }];
    
    
}


@end
