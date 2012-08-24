//
//  UpdateController.m
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "UpdateController.h"

@implementation UpdateController

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

- (IBAction)stopDownload:(id)sender {
    self.stopFlag = TRUE;
}


- (void)updateNotification:(NSNotification *)notification {   // start, continue, finish, or cancel the current running update
    NSLog(@"updateNotification self.updateMode:%u", self.updateMode);
    if (self.stopFlag) {
        self.busy = FALSE;
        self.stopFlag = FALSE;
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
        asset = [self loadSoundCloudAccountData:data];
        self.updateMode = UpdateModeTracks;  // now, continue by updating tracks
        self.updateCount = 0;
        self.targetCount = [asset.track_count integerValue];
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateMode == UpdateModeWordPress) {
        asset = [self loadWordPressAccountData:data];
        self.updateMode = UpdateModeWordPressSite;  // now, continue with blog information
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateMode == UpdateModeWordPressSite) {
        asset = [self loadWordPressSiteData:data];
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
                [self loadWordPressPostData:asset data:item];
            }
            else {
                [self loadCommonAsset:asset data:item];
                if ([asset.entity.name isEqualToString:@"Playlist"]) {
                    [self loadPlaylistsAsset:asset data:item];
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
            [self loadCommonAsset:asset data:data];
            if ([asset.entity.name isEqualToString:@"Playlist"]) {
                [self loadPlaylistsAsset:asset data:data];
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

-(Asset *)loadWordPressSiteData:(NSDictionary *)data {
    Asset *asset;
    asset = self.wordPressController.account;
    NSLog(@"loadWordPressSiteData: %@ asset: %@", data, asset);
    asset.track_count = data[@"post_count"];
    asset.title = data[@"description"];

    
    return asset;

}

-(Asset *)loadWordPressAccountData:(NSDictionary *)data {
    Asset *asset;
    asset = self.wordPressController.account;
    NSLog(@"loadWordPressAccountData: %@ asset: %@", data, asset);
    asset.user_id = data[@"ID"];
    asset.asset_id = data[@"primary_blog"];
    asset.title = data[@"description"];
    asset.username = data[@"display_name"];
    asset.permalink = data[@"username"];
    
    if (data[@"avatar_URL"] != [NSNull null]) {
        NSString *artwork_url = data[@"avatar_URL"];
   //     NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
   //     artwork_url = [NSString stringWithString:(NSString *)a[0]];
        asset.artwork_url = artwork_url;
        
   //     artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        asset.image =  [NSArchiver archivedDataWithRootObject:image];
    }
    
    /*
    asset.title = data[@"full_name"];
    asset.permalink = data[@"permalink"];
    asset.playlist_count = data[@"playlist_count"];
    asset.track_count = data[@"track_count"];
    asset.followers_count = data[@"followers_count"];
    asset.followings_count = data[@"followings_count"];
    asset.contents = data[@"description"];
    asset.city = data[@"city"];
    asset.country = data[@"country"];
    asset.purchase_url = data[@"website"];
    asset.purchase_title = data[@"website_title"];
     */
    
    return asset;
}
-(Asset *)loadSoundCloudAccountData:(NSDictionary *)data {
    Asset *asset;
    asset = self.soundCloudController.account;
    asset.title = data[@"full_name"];
    asset.asset_id = data[@"id"];
    asset.username = data[@"username"];
    asset.permalink = data[@"permalink"];
    asset.playlist_count = data[@"playlist_count"];
    asset.track_count = data[@"track_count"];
    asset.followers_count = data[@"followers_count"];
    asset.followings_count = data[@"followings_count"];
    asset.contents = data[@"description"];
    asset.city = data[@"city"];
    asset.country = data[@"country"];
    asset.purchase_url = data[@"website"];
    asset.purchase_title = data[@"website_title"];
    if (data[@"avatar_url"] != [NSNull null]) {
        NSString *artwork_url = data[@"avatar_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        asset.artwork_url = artwork_url;
        
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        //     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        asset.image =  [NSArchiver archivedDataWithRootObject:image];
        //       });
    }
    return asset;
}
-(void)loadWordPressPostData:(Asset *)asset data:(NSDictionary *)data {
    
    asset.title = data[@"title"];
    asset.purchase_url = data[@"URL"];
    asset.purchase_title = data[@"type"];
    asset.permalink = data[@"slug"];
    asset.contents = data[@"content"];

    asset.uri = data[@"meta"][@"links"][@"site"];
    
    asset.sync_mode = [NSNumber numberWithBool:FALSE];
    
}
-(void)loadCommonAsset:(Asset *)asset data:(NSDictionary *)data {
    asset.title = data[@"title"];
    
    if (data[@"purchase_url"] != [NSNull null]) {
        asset.purchase_url = data[@"purchase_url"];
    }
    else {
        asset.purchase_url = nil;
    }
    if (data[@"purchase_title"] != [NSNull null]) {
        asset.purchase_title = data[@"purchase_title"];
    }
    else {
        asset.purchase_title = nil;
    }
    if (data[@"artwork_url"] != [NSNull null]) {
        NSString *artwork_url = data[@"artwork_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        asset.artwork_url = artwork_url;
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //original
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        asset.image = [NSArchiver archivedDataWithRootObject:image];
        [self.progressImageWell setImage:image];
    }
    asset.permalink = data[@"permalink"];
    asset.uri = data[@"uri"];
    asset.sync_mode = [NSNumber numberWithBool:FALSE];
    
}
-(void)loadPlaylistsAsset:(Asset *)asset data:(NSDictionary *)data {
    Asset *subAsset;
    NSArray *subItems;
    NSError *error = nil;
    NSManagedObjectContext *moc = [self.document managedObjectContext];
    
    
    asset.tracks = nil;
    subItems = data[@"tracks"];
    for (NSDictionary *subItem in subItems) {
        NSLog(@"subItem asset_id: %@", subItem[@"id"]);
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", subItem[@"id"]]];
        NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
        
        if ([matchingItems count] < 1) {
            NSLog(@"Error: - No matching Asset - subItem asset_id: %@", subItem[@"id"]);
        }
        else {
            subAsset = matchingItems[0];
            [asset addTracksObject:subAsset];
        }
    }
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
