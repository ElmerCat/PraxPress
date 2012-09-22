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
        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
                                                          object:self.changedAssetsTableView
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          if ([aNotification object] == self.changedAssetsTableView){
                                                              
                                                              NSLog(@"changedAssetsTableView NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                              if (self.changedAssetsController.selectedObjects.count > 0) {
                                                                  self.praxController.selectedAsset = [self.changedAssetsController selectedObjects][0];
                                                                  if ([self.praxController.assetDetailPanel isVisible])
                                                                      [self.praxController.assetDetailPanel makeKeyAndOrderFront:self];
                                                              }
                                                          }
                                                          
                                                          else NSLog(@"UpdateController NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];

        
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
        
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"cdb0237a5d0244d2f0528ae9da6ca41f"
                                                 secret:@"48d5ef73f4dd1281e5d41100ba58261a"
                                       authorizationURL:[NSURL URLWithString:@"https://soundcloud.com/connect"]
                                               tokenURL:[NSURL URLWithString:@"https://api.soundcloud.com/oauth2/token"]
                                            redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                         forAccountType:@"com.soundcloud.api"];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"493"
                                                 secret:@"Xkd4JjiFceH8OVFqEsaZtP5eGtONxnFP3Emq2mlQoiJBvw7HtpbHbniHmQdaXuhg"
                                       authorizationURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/authorize"]
                                               tokenURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/token"]
                                            redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                         forAccountType:@"com.wordpress.api"];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"PRAX"
                                                 secret:@"prax"
                                       authorizationURL:[NSURL URLWithString:@"http://elmercat.org/praxpress"]
                                               tokenURL:[NSURL URLWithString:@"https://prax.prax/oauth2/token"]
                                            redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                         forAccountType:@"YouTube"];
        
        [[NXOAuth2AccountStore sharedStore] setClientID:@"PRAX"
                                                 secret:@"prax"
                                       authorizationURL:[NSURL URLWithString:@"http://elmercat.org/praxpress"]
                                               tokenURL:[NSURL URLWithString:@"https://prax.prax/oauth2/token"]
                                            redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                         forAccountType:@"Flickr"];
        
        

        // YouTube developer key = "AI39si7b1wiC17l1KoIAB1maTGrjfVfeKEzm6yRElmdBiOlcj75NFktrwd4oBdY2CS1j54hVPmnWhY9KGj9NaBul3BL_nk_Vsg"
        
       
        
        
        
    }
    return self;
}


- (void)awakeFromNib {
        NSLog(@"UpdateController awakeFromNib");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NXOAuth2Account *) scAccount {
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"com.soundcloud.api"];
    if ([oauthAccounts count] > 0) {
        return oauthAccounts[0];
    } else {
        
        [self removeAccessForAccountType:@"com.soundcloud.api"];
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"com.soundcloud.api"
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           [self.document.authorizationWindow makeKeyAndOrderFront:self];
                                           [[self.document.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                       }];
        return nil;
    }
}

- (NXOAuth2Account *) wpAccount {
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"com.wordpress.api"];
    if ([oauthAccounts count] > 0) {
        return oauthAccounts[0];
    } else {
        
        [self removeAccessForAccountType:@"com.wordpress.api"];
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"com.wordpress.api"
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           [self.document.authorizationWindow makeKeyAndOrderFront:self];
                                           [[self.document.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                       }];
        return nil;
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
        return;
    }
        
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
        return;
    }
    
    [self reloadAsset:self.changedAssetsController.arrangedObjects[0]];
    
}


- (IBAction)reloadFromServer:(id)sender {
    if (self.busy) return;
    
     [self reloadAsset:[self.assetsController selectedObjects][0]];
    
}

- (void)reloadAsset:(Asset *)asset {
    NXOAuth2Account *account;
    NSURL *resource;
    NSDictionary *parameters;
    if (([asset.type isEqualToString:@"track"]) || ([asset.type isEqualToString:@"playlist"])) {
        account = self.scAccount;
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", asset.uri]];
    }
    else if (([asset.type isEqualToString:@"post"]) || ([asset.type isEqualToString:@"page"])) {
        account = self.wpAccount;
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", asset.uri, asset.asset_id]];
        parameters = @{@"context":@"edit"};
    }
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:resource method:@"GET" parameters:parameters];
    request.account = account;
    if (!request.account) return;
    self.busy = TRUE;
    NSLog(@"updateMode GET request.account: %@ resource: %@ ", request.account, resource);
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], resource, nil);
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
                                          }
                                          
                                          if (self.reloadChangedItems = TRUE) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self reloadChangedAssets];
                                              });
                                          }
                                          else if (self.uploadChangedItems = TRUE) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self uploadChangedAssets];
                                              });
                                          }
                                          else self.busy = FALSE;
                                      }];
}

- (IBAction)uploadToServer:(id)sender {
    if (self.busy) return;
    [self uploadAsset:[self.assetsController selectedObjects][0]];
}

- (void)uploadAsset:(Asset *)asset {
    if (self.stop) {
        self.busy = FALSE;
        self.stop = FALSE;
        return;
    }
    
    NXOAuth2Request *request = [asset updateRequest:self];
    if (!request) return;
    
    self.busy = TRUE;
    [self.progressBar setIndeterminate:TRUE];
    
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


- (IBAction)refreshAllData:(id)sender {
    if (self.busy) return;
    
    self.account = [(NSTableCellView *)[(NSButton *)sender superview] objectValue];
//    NSLog(@"account: %@", account);
    
    if (![self.account oauthReady:self.document]) return;
        
    
    
    if ([self.account.accountType isEqualToString:@"com.soundcloud.api"]) {
        self.statusText = @"Updating SoundCloud User Profile";
        self.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
        
    }
    else if ([self.account.accountType isEqualToString:@"com.wordpress.api"]) {
        self.statusText = @"Updating WordPress User Profile";
        self.resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
    }
    
    else return;
    
    self.busy = TRUE;
    [self.progressBar setIndeterminate:TRUE];
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:self.resource method:@"GET" parameters:nil];
    request.account = self.account.oauthAccount;

    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], self.resource, nil);
                                              self.busy = FALSE;

                                          }
                                          else {
                                              NSError *__autoreleasing *jsonError = NULL;
                                              NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                                              NSLog(@"responseHandler resource:%@ data:%@", self.resource, data);
                                              
                                              if ([self.account.accountType isEqualToString:@"com.soundcloud.api"]) {
                                                   
                                                  [self.account loadSoundCloudAccountData:data];
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      
                                                       
                                                      self.statusText = @"Updating Tracks";
                                                      self.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
                                                      self.updateCount = 0;
                                                      self.targetCount = [self.account.track_count integerValue];
                                                      [self.progressBar setIndeterminate:FALSE];
                                                      
                                                      [self performTracksGetRequest];
                                                  });
                                                  
                                              }
                                              else if ([self.account.accountType isEqualToString:@"com.wordpress.api"]) {
                                                  [self.account loadWordPressAccountData:data];
                                                  
                                                  self.statusText = @"Updating WordPress SiteData";
                                                  self.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://public-api.wordpress.com/rest/v1/sites/%@", self.account.asset_id]];
                                                  
                                                  [request setResource:self.resource];
                                                  
                                                  [request performRequestWithSendingProgressHandler:nil
                                                                                    responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
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
                                                                                            
                                                                                            self.statusText = @"Updating WordPress Posts";
                                                                                            self.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://public-api.wordpress.com/rest/v1/sites/%@/posts/", self.account.asset_id]];
                                                                                            
                                                                                            
                                                                                            self.updateCount = 0;
                                                                                            self.targetCount = [self.account.track_count integerValue];
                                                                                            [self.progressBar setIndeterminate:FALSE];
                                                                                            
                                                                                            
                                                                                           
                                                                                            
                                                                                            
                                                                                            
                                                                                            
                                                                                            
                                                                                            
                                                                                            
                                                                                            [self performPostsGetRequest];
                                                                                        });
                                                                                        

                                                                                    }];
                                              }
                                          }
                                      }];

}

- (void) performPostsGetRequest {
    
    if (self.stop) {
        self.busy = FALSE;
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
                                                      
                                                      self.statusText = @"Updating Playlists";
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
                                              }
                                              else {
                                                  
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self performPlaylistsGetRequest];
                                                  });
                                                  
                                                  
                                              }
                                          }
                                      }];
    
    
}

- (void)updateNotification:(NSNotification *)notification {   // start, continue, finish, or cancel the current running update
    NSLog(@"updateNotification self.updateMode:%u", self.updateMode);
    if (self.stop) {
        self.busy = FALSE;
        self.stop = FALSE;
        return;
    }
    else if ((self.updateMode <= UpdateModeDone) || (self.updateMode >= UpdateModeError)) {
        // [[self.document managedObjectContext] processPendingChanges];
        //     [[self.document managedObjectContext] save:nil];
        self.updateMode = UpdateModeIdle;
        self.busy = FALSE;
        return;
    }
    else if (((self.updateMode == UpdateModeUploadingTrack)|| (self.updateMode == UpdateModeUploadingPlaylist))|| (self.updateMode == UpdateModeUploadingWordPressPost)) { // when waiting for upload response  UpdateModeUploadingWordPressPost
        return;
    }

    if (!self.scAccount) return;
    if (!self.wpAccount) return;

    else self.busy = TRUE;
    NSURL *resource;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    if (self.updateModeMultiple) [self.progressBar setIndeterminate:FALSE];
    else [self.progressBar setIndeterminate:TRUE];
    
    if (self.updateMode == UpdateModeSoundCloud) {
        self.statusText = @"Updating SoundCloud User Profile";
        resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
    }
    else if (self.updateMode == UpdateModeWordPress) {
        self.statusText = @"Updating WordPress User Profile";
        resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
    }
    else if (self.updateMode == UpdateModeWordPressSite) {
        self.statusText = @"Updating WordPress Site Information";
        resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/sites/elmercat.org"];
    }
    
    else if (self.updateModeMultiple) {
        if (self.updateTypeWordPressPost) {
            self.statusText = @"Updating WordPress Posts";
            resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/sites/elmercat.org/posts/"];
            parameters[@"context"] = @"edit";
            parameters[@"type"] = @"any";
            parameters[@"status"] = @"any";
            parameters[@"number"] = @"30";
            //parameters[@"page"] = [[NSNumber numberWithInteger:(self.updateCount + 1)] stringValue];
            parameters[@"offset"] = [[NSNumber numberWithInteger:self.updateCount] stringValue];
        }
        else {
            if (self.updateTypeTrack) {
                self.statusText = @"Updating Tracks";
                resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
            }
            else { // UpdateModeAssets
                self.statusText = @"Updating Playlists";
                resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
            }
            parameters[@"limit"] = @"1";
            parameters[@"offset"] = [[NSNumber numberWithInteger:self.updateCount] stringValue];
        }
    }
    else { //  single item
        Asset *asset;
        if (self.updateTypeTrack) {
            asset = [self.assetsController selectedObjects][0];
            self.statusText = [NSString stringWithFormat:@"Updating Track: %@",[asset valueForKey:@"title"]];
        }
        else if (self.updateTypePlaylist) {
            asset = [self.assetsController selectedObjects][0];
            self.statusText = [NSString stringWithFormat:@"Updating Playlist: %@",[asset valueForKey:@"title"]];
        }
        else {
            asset = [self.changedAssetsController arrangedObjects][0];
            self.statusText = [NSString stringWithFormat:@"Updating Asset: %@",[asset valueForKey:@"title"]];
        }
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", asset.uri]];
    }
    NSLog(@"updateMode resource: %@ parameters:%@", resource, parameters);
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:resource method:@"GET" parameters:parameters];
    if (self.updateServiceWordPress) {
        request.account = self.wpAccount;
    }
    else {
        request.account = self.scAccount;
    }
    NSLog(@"updateMode GET request.account: %@ resource: %@ parameters:%@", request.account, resource, parameters);
        
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request GET error: %@ \nresource: %@ parameters: %@", [error localizedDescription], resource, parameters);
                                              self.updateMode = UpdateModeError;
                                              [[NSNotificationCenter defaultCenter]
                                               postNotificationName:@"updateNotification" object:nil];
                                          }
                                          else {
                                              //        NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                              [[NSNotificationCenter defaultCenter]
                                               postNotificationName:@"responseNotification" object:nil userInfo:@{@"jsonData":data}];
                                          }
                                      }];
}

- (void)responseNotification:(NSNotification *)notification {   // process the response data
    NSLog(@"responseNotification self.updateMode:%u", self.updateMode);
    NSData *jsonData = [notification userInfo][@"jsonData"];
    NSLog(@"responseNotification self.updateMode:%u jsonData:%@", self.updateMode, jsonData);
    NSError *__autoreleasing *jsonError = NULL;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:jsonError];
    
    NSLog(@"responseNotification: data: %@", data);
    NSString *testString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    NSLog(@"testString: %@", testString);
    Asset *asset;
    NSError *error = nil;
    NSManagedObjectContext *moc = [self.document managedObjectContext];

    if ((self.updateMode <= UpdateModeDone) || (self.updateMode > UpdateModePlaylists)) {
        self.updateMode = UpdateModeError;
    }
    else if (self.updateMode == UpdateModeSoundCloud) {
        
        asset = self.soundCloudController.account;
//        [asset loadSoundCloudAccountData:data];
        self.updateMode = UpdateModeTracks;  // now, continue by updating tracks
        self.updateCount = 0;
//        self.targetCount = [asset.track_count integerValue];
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateMode == UpdateModeWordPress) {
        asset = self.wordPressController.account;
        
//        [asset loadWordPressAccountData:data];
        self.updateMode = UpdateModeWordPressSite;  // now, continue with blog information
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateMode == UpdateModeWordPressSite) {
        
        asset = self.wordPressController.account;
//        [asset loadWordPressSiteData:data];
        self.updateMode = UpdateModeWordPressPosts;  // now, continue by getting the posts
        self.updateCount = 0;
//        self.targetCount = [asset.track_count integerValue];
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }

    else if (self.updateModeMultiple) {
        NSString *entity;
        if (self.updateTypeWordPressPost) {
            entity = @"Post";
            data = data[@"posts"];
        }
        else if (self.updateTypeTrack) entity = @"Track";
        else entity = @"Playlist";
        for (NSDictionary *item in data) {
            NSString *asset_id = (self.updateTypeWordPressPost) ? item[@"ID"] : item[@"id"];
            NSLog(@"asset_id: %@", asset_id);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
            [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", asset_id]];
            NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
            if ([matchingItems count] < 1) {
                asset = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:moc];
                asset.asset_id = [NSNumber numberWithInt:[asset_id intValue]];
                asset.batchPosition = [NSNumber numberWithInt:-1];

            }
            else asset = matchingItems[0];
            
            if (self.updateTypeWordPressPost) {
                [asset loadWordPressPostData:item];
            }
            else {
                
                [asset loadSoundCloudItemData:item];
                if ([asset.entity.name isEqualToString:@"Playlist"]) {
                    [asset loadPlaylistsAsset:asset data:item];
                }
            }
            self.updateCount = self.updateCount + 1;
        }
        if (self.updateCount >= self.targetCount) {
            if (self.updateMode == UpdateModeTracks) {
                self.updateMode = UpdateModePlaylists;  // now, continue by updating playlists
                self.updateCount = 0;
//                self.targetCount = [self.soundCloudController.account.playlist_count integerValue];
            }
            else self.updateMode = UpdateModeDone;
        }
        [self.changedAssetsController rearrangeObjects];
    }
    
    else {
        NSString *entity = ([data[@"kind"] isEqualToString:@"track"]) ? @"Track" : @"Playlist";

//        NSString *entity = (self.updateTypeTrack) ? @"Track" : @"Playlist";
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", data[@"id"]]];
        NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
        if ([matchingItems count] < 1) {
            NSLog(@"Error: - No matching Asset - asset_id: %@", data[@"id"]);
        }
        else asset = matchingItems[0];
        
        NSLog(@"asset.entity.name: %@", asset.entity.name);
        if (self.updateModeUpload) {
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
            for (NSString *key in @[@"title", @"purchase_title", @"purchase_url"]) {
                NSString *asset_key = ([asset.entity.name isEqualToString:@"Track"]) ? [NSString stringWithFormat:@"track[%@]", key] : [NSString stringWithFormat:@"playlist[%@]", key];
                NSString *value = ([asset valueForKey:key]) ? [asset valueForKey:key] : @"";
                if (![value isEqualToString:data[key]]) {
                    [parameters setObject:value forKey:asset_key];
                }
            }
            if ([parameters count] < 1) { // nothing to update, just refresh asset then
                if (self.updateMode == UpdateModeAssets) self.updateMode = UpdateModeAsset;
                else self.updateMode = (self.updateMode == UpdateModeUploadTrack) ? UpdateModeTrack : UpdateModePlaylist;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"updateNotification" object:nil];
                });
                return;
            }
            NSURL *resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", asset.uri]];
            
            NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:resource method:@"PUT" parameters:parameters];
            if (self.updateServiceWordPress) {
                request.account = self.wpAccount;
            }
            else {
                request.account = self.scAccount;
            }
            NSLog(@"updateMode PUT request.account: %@ resource: %@ parameters:%@", request.account, resource, parameters);
            
            [request performRequestWithSendingProgressHandler:nil
                                              responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                                  if (error) {
                                                      
                                                      [[NSSound soundNamed:@"Error"] play];
                                                      NSLog(@"SCRequestMethodPUT error: %@", [error localizedDescription]);
                                                      self.updateMode = UpdateModeError;
                                                      [[NSNotificationCenter defaultCenter]
                                                       postNotificationName:@"updateNotification" object:nil];
                                                  }
                                                  else {
                                                      NSLog(@"responseHandler response statusCode: %ld", [(NSHTTPURLResponse *)response statusCode]);
                                                      if (self.updateMode == UpdateModeAssets) self.updateMode = UpdateModeAsset;
                                                      else self.updateMode = (self.updateMode == UpdateModeUploadTrack) ? UpdateModeTrack : UpdateModePlaylist;
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [[NSNotificationCenter defaultCenter]
                                                           postNotificationName:@"updateNotification" object:nil];
                                                      });
                                                  }
                                              }];
            
        // self.updateMode = ([asset.entity.name isEqualToString:@"Track"]) ? UpdateModeUploadingTrack : UpdateModeUploadingPlaylist;
            return;
        }
        else { // not upload
            
            [asset loadSoundCloudItemData:data];
            if ([asset.entity.name isEqualToString:@"Playlist"]) {
                [asset loadPlaylistsAsset:asset data:data];
            }
            [self.changedAssetsController rearrangeObjects];
            if (self.updateMode == UpdateModeAsset) {
                self.updateMode = ([[self.changedAssetsController arrangedObjects] count] > 0) ? UpdateModeAssets : UpdateModeDone;
            }
            else self.updateMode = UpdateModeDone;
        }
        
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
    
}

-(BOOL)updateModeMultiple {
    return (((self.updateMode == UpdateModeTracks)||(self.updateMode == UpdateModePlaylists))||(self.updateMode == UpdateModeWordPressPosts)) ? TRUE : FALSE;
}
-(BOOL)updateModeUpload {
    return (((self.updateMode == UpdateModeUploadTrack)||(self.updateMode == UpdateModeUploadPlaylist))||(self.updateMode == UpdateModeAssets))? TRUE : FALSE;
}
-(BOOL)updateTypeWordPressPost {
    return (((self.updateMode == UpdateModeWordPressPost)||(self.updateMode == UpdateModeWordPressPosts))||(self.updateMode == UpdateModeUploadWordPressPost)) ? TRUE : FALSE;
}
-(BOOL)updateTypeTrack {
        return (((self.updateMode == UpdateModeTrack)||(self.updateMode == UpdateModeTracks))||(self.updateMode == UpdateModeUploadTrack)) ? TRUE : FALSE;
}
-(BOOL)updateTypePlaylist {
    return (((self.updateMode == UpdateModePlaylist)||(self.updateMode == UpdateModePlaylists))||(self.updateMode == UpdateModeUploadPlaylist)) ? TRUE : FALSE;}

-(BOOL)updateServiceWordPress {
    return (((self.updateMode == UpdateModeWordPress)||(self.updateMode == UpdateModeWordPressSite))||(self.updateMode == UpdateModeWordPressPosts)) ? TRUE : FALSE;}



@end
