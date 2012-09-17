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
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (IBAction)praxAction:(id)sender {
}

- (IBAction)stop:(id)sender {
    self.stop = TRUE;
}


- (IBAction)reloadFromServer:(id)sender {
    
     [self reloadAsset:[self.assetsController selectedObjects][0]];
    
}

- (void)reloadAsset:(Asset *)asset {
    
    NXOAuth2Account *account;
    NSURL *resource;
    NSDictionary *parameters;
    
    if (([asset.type isEqualToString:@"track"]) || ([asset.type isEqualToString:@"playlist"])) {
        account = [self.document scAccount];
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", asset.uri]];
        
        
    }
    else if (([asset.type isEqualToString:@"post"]) || ([asset.type isEqualToString:@"page"])) {
        account = [self.document wpAccount];
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
                                                  
                                                  [asset loadWordPressPostData:asset data:item];
    
                                                   
                                                  
                                              }
                                              
                                              [self.changedAssetsController rearrangeObjects];
                                                  
                                                  
                                              
                                          }
                                          self.busy = FALSE;

                                      }];
    
    
}

- (IBAction)uploadToServer:(id)sender {
    
    [self uploadAsset:[self.assetsController selectedObjects][0]];
}

- (void)uploadAsset:(Asset *)asset {
    NXOAuth2Account *account;
    NSURL *resource;
    NSDictionary *parameters;
    
    if (([asset.type isEqualToString:@"track"]) || ([asset.type isEqualToString:@"playlist"])) {
        account = [self.document scAccount];
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", asset.uri]];
        
        
    }
    else if (([asset.type isEqualToString:@"post"]) || ([asset.type isEqualToString:@"page"])) {
        account = [self.document wpAccount];
        resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", asset.uri, asset.asset_id]];
        parameters = @{@"title":asset.title, @"content":asset.contents, @"tags":@""};
        
    }
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:resource method:@"POST" parameters:parameters];
    request.account = account;
    
    
    if (!request.account) return;
    self.busy = TRUE;
    
    NSLog(@"updateMode POST request.account: %@ resource: %@  parameters: %@", request.account, resource, parameters);
    
    [request performRequestWithSendingProgressHandler:nil
                                      responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                          if (error) {
                                              [[NSSound soundNamed:@"Error"] play];
                                              NSLog(@"NXOAuth2Request POST error: %@ \nresource: %@ parameters: %@", [error localizedDescription], resource, parameters);
                                          }
                                          else {
                                              [[NSSound soundNamed:@"Connect"] play];

                                              [self reloadAsset:asset];
                                              
                                          }
                                          self.busy = FALSE;
                                          
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

    self.scAccount = [self.document scAccount];
    if (!self.scAccount) return;
    self.wpAccount = [self.document wpAccount];
    if (!self.wpAccount) return;

    else self.busy = TRUE;
    NSURL *resource;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    if (self.updateModeMultiple) [self.progressBar setIndeterminate:FALSE];
    else [self.progressBar setIndeterminate:TRUE];
    
    if (self.updateMode == UpdateModeSoundCloud) {
        [self.statusText setStringValue:@"Updating SoundCloud User Profile"];
        resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
    }
    else if (self.updateMode == UpdateModeWordPress) {
        [self.statusText setStringValue:@"Updating WordPress User Profile"];
        resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
    }
    else if (self.updateMode == UpdateModeWordPressSite) {
        [self.statusText setStringValue:@"Updating WordPress Site Information"];
        resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/sites/elmercat.org"];
    }
    else if (self.updateModeMultiple) {
        if (self.updateTypeWordPressPost) {
            [self.statusText setStringValue:@"Updating WordPress Posts"];
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
                [self.statusText setStringValue:@"Updating Tracks"];
                resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
            }
            else { // UpdateModeAssets
                [self.statusText setStringValue:@"Updating Playlists"];
                resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
            }
            parameters[@"limit"] = @"1";
            parameters[@"offset"] = [[NSNumber numberWithInteger:self.updateCount] stringValue];
        }
    }
    else { //  single item
        Asset *asset;
        if (self.updateTypeTrack) {
            asset = [self.tracksController selectedObjects][0];
            [self.statusText setStringValue:[NSString stringWithFormat:@"Updating Track: %@",[asset valueForKey:@"title"]]];
        }
        else if (self.updateTypePlaylist) {
            asset = [self.playlistsController selectedObjects][0];
            [self.statusText setStringValue:[NSString stringWithFormat:@"Updating Playlist: %@",[asset valueForKey:@"title"]]];
        }
        else {
            asset = [self.changedAssetsController arrangedObjects][0];
            [self.statusText setStringValue:[NSString stringWithFormat:@"Updating Asset: %@",[asset valueForKey:@"title"]]];
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
        [asset loadSoundCloudAccountData:data];
        self.updateMode = UpdateModeTracks;  // now, continue by updating tracks
        self.updateCount = 0;
        self.targetCount = [asset.track_count integerValue];
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateMode == UpdateModeWordPress) {
        asset = self.wordPressController.account;
        
        [asset loadWordPressAccountData:data];
        self.updateMode = UpdateModeWordPressSite;  // now, continue with blog information
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateMode == UpdateModeWordPressSite) {
        
        asset = self.wordPressController.account;
        [asset loadWordPressSiteData:data];
        self.updateMode = UpdateModeWordPressPosts;  // now, continue by getting the posts
        self.updateCount = 0;
        self.targetCount = [asset.track_count integerValue];
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
                [asset loadWordPressPostData:asset data:item];
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
                self.targetCount = [self.soundCloudController.account.playlist_count integerValue];
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
