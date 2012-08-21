//
//  UpdateController.m
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "UpdateController.h"

@implementation UpdateController
@synthesize generatedCodeText;

NSString *PraxItemsDropType = @"PraxItemsDropType";
int temporaryViewPosition = -1;
int startViewPosition = -2;
int endViewPosition = -3;

#define temporaryViewPositionNum [NSNumber numberWithInt:temporaryViewPosition]
#define startViewPositionNum [NSNumber numberWithInt:startViewPosition]
#define endViewPositionNum [NSNumber numberWithInt:endViewPosition]

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
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          if ((([aNotification object] == self.trackEditorPanel)||([aNotification object] == self.playlistEditorPanel))|| ([aNotification object] == self.previewFrameWindow)){
                                                              [[aNotification object] close];
                                                          }
                                                          else if ([aNotification object] == self.tracksWindow) {
                                                              if ([[self.tracksController arrangedObjects] count] > 0) {
                                                                  self.lastSelectedAsset = (([[self.tracksController selectedObjects] count] > 0) ? [self.tracksController selectedObjects][0] : [self.tracksController arrangedObjects][0]);
                                                              }
                                                          }
                                                          else if ([aNotification object] == self.playlistsWindow) {
                                                              if ([[self.playlistsController arrangedObjects] count] > 0) {
                                                                  self.lastSelectedAsset = (([[self.playlistsController selectedObjects] count] > 0) ? [self.playlistsController selectedObjects][0] : [self.playlistsController arrangedObjects][0]);
                                                              }
                                                          }
                                                          //        else NSLog(@"UpdateController NSWindowDidResignKeyNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          if ([aNotification object] == self.formatCodeTableView){
                                                              [self updateGeneratedCode];
                                                          }
                                                      else NSLog(@"UpdateController NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                     //     NSLog(@"UpdateController NSControlTextDidChangeNotification aNotification: %@", aNotification);
                                                          
                                                          Asset *asset;
                                                          if (([[aNotification object] window] == self.trackEditorPanel)||([aNotification object] == self.tracksTableView)) {
                                                    //          NSLog(@"controlTextDidChange trackEditorPanel || tracksTableView");
                                                              asset = [self.tracksController selectedObjects][0];
                                                              asset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else if (([[aNotification object] window] == self.playlistEditorPanel)||([aNotification object] == self.playlistsTableView)) {
                                                              NSLog(@"controlTextDidChange playlistEditorPanel || playlistsTableView");
                                                              asset = [self.playlistsController selectedObjects][0];
                                                              asset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else NSLog(@"controlTextDidChange something else");
                                                        
                                                      }];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)awakeFromNib {
 //   NSLog(@"UpdateController awakeFromNib");

    [self.assetBatchEditTable registerForDraggedTypes:[NSArray arrayWithObjects:PraxItemsDropType, nil]];
    [self.assetBatchEditTable setSortDescriptors:self.batchSortDescriptors];
    
}


- (void)textDidChange:(NSNotification *)aNotification {
    
    if ((([aNotification object] == self.startingFormatText)||([aNotification object] == self.blockFormatText))|| ([aNotification object] == self.endingFormatText)){
        [self updateGeneratedCode];
    }
    
}

- (NSPredicate *)changedAssetsFilterPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync_mode == YES"];
    return predicate;
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
    else if ((self.updateMode <= UpdateModeDone) || (self.updateMode > UpdateModePlaylists)) {
        // [[self.document managedObjectContext] processPendingChanges];
        //     [[self.document managedObjectContext] save:nil];
        self.updateMode = UpdateModeIdle;
        self.busy = FALSE;
        return;
    }
    else if ((self.updateMode == UpdateModeUploadingTrack)|| (self.updateMode == UpdateModeUploadingPlaylist)) { // when waiting for upload response
        return;
    }
/*
    if (self.updateMode == UpdateModeSoundCloud) { // login if needed
        self.scAccount = [self.document scAccount];
        if (!self.scAccount) return;
    }
    else if (self.updateMode == UpdateModeWordPress) { // login if needed
        self.wpAccount = [self.document wpAccount];
        if (!self.wpAccount) return;
    }
*/
    self.scAccount = [self.document scAccount];
    if (!self.scAccount) return;
    self.wpAccount = [self.document wpAccount];
    if (!self.wpAccount) return;

    else self.busy = TRUE;
    NSURL *resource;
    NSDictionary *parameters = nil;
    
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
    else if (self.updateModeMultiple) {
        if (self.updateTypeTrack) {
            [self.statusText setStringValue:@"Updating Tracks"];
            resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
        }
        else { // UpdateModeAssets
            [self.statusText setStringValue:@"Updating Playlists"];
            resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
        }
        parameters = @{@"limit":@"1", @"offset":[[NSNumber numberWithInteger:self.updateCount] stringValue]};
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
    if (self.updateMode == UpdateModeWordPress) {
        request.account = self.wpAccount;
    }
    else {
        request.account = self.scAccount;
    }
        
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
//    NSLog(@"responseNotification self.updateMode:%u jsonData:%@", self.updateMode, jsonData);
    NSError *__autoreleasing *jsonError = NULL;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:jsonError];
 //   				NSLog(@"jsonError: %@  data: %@", *jsonError, data);
//    NSString *testString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
//    NSLog(@"testString: %@", testString);
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
        self.updateMode = UpdateModeDone;
  //      self.updateMode = UpdateModeTracks;  // now, continue by updating tracks
  //      self.updateCount = 0;
  //      self.targetCount = [asset.track_count integerValue];
        asset.sync_mode = [NSNumber numberWithBool:FALSE];
    }
    else if (self.updateModeMultiple) {
        NSString *entity = (self.updateTypeTrack) ? @"Track" : @"Playlist";
        for (NSDictionary *item in data) {
            NSLog(@"asset_id: %@", item[@"id"]);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
            [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
            NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
            if ([matchingItems count] < 1) {
                asset = [NSEntityDescription insertNewObjectForEntityForName:entity inManagedObjectContext:moc];
                asset.asset_id = item[@"id"];
                asset.batchPosition = [NSNumber numberWithInt:-1];

            }
            else asset = matchingItems[0];
            [self loadCommonAsset:asset data:item];
            if ([asset.entity.name isEqualToString:@"Playlist"]) {
                [self loadPlaylistsAsset:asset data:item];
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
            NSLog(@"updateMode resource: %@ parameters:%@", resource, parameters);
            
            NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:resource method:@"PUT" parameters:parameters];
            if (self.updateMode == UpdateModeWordPress) {
                request.account = self.wpAccount;
            }
            else {
                request.account = self.scAccount;
            }
            
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

-(Asset *)loadWordPressAccountData:(NSDictionary *)data {
    Asset *asset;
    asset = self.wordPressController.account;
    NSLog(@"loadWordPressAccountData: %@ asset: %@", data, asset);
    asset.user_id = data[@"ID"];
    asset.asset_id = data[@"primary_blog"];
    asset.title = data[@"display_name"];
    asset.username = data[@"username"];
    
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
-(void)loadCommonAsset:(Asset *)asset data:(NSDictionary *)data {
    asset.title = data[@"title"];
    asset.title_x = data[@"title"];
    
    if (data[@"purchase_url"] != [NSNull null]) {
        asset.purchase_url = data[@"purchase_url"];
        asset.purchase_url_x = data[@"purchase_url"];
    }
    else {
        asset.purchase_url = nil;
        asset.purchase_url_x = nil;
    }
    if (data[@"purchase_title"] != [NSNull null]) {
        asset.purchase_title = data[@"purchase_title"];
        asset.purchase_title_x = data[@"purchase_title"];
    }
    else {
        asset.purchase_title = nil;
        asset.purchase_title_x = nil;
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
    return ((self.updateMode == UpdateModeTracks)||(self.updateMode == UpdateModePlaylists)) ? TRUE : FALSE;
}
-(BOOL)updateModeUpload {
    return (((self.updateMode == UpdateModeUploadTrack)||(self.updateMode == UpdateModeUploadPlaylist))||(self.updateMode == UpdateModeAssets))? TRUE : FALSE;
}
-(BOOL)updateTypeTrack {
    return (((self.updateMode == UpdateModeTrack)||(self.updateMode == UpdateModeTracks))||(self.updateMode == UpdateModeUploadTrack)) ? TRUE : FALSE;
}
-(BOOL)updateTypePlaylist {
    return (((self.updateMode == UpdateModePlaylist)||(self.updateMode == UpdateModePlaylists))||(self.updateMode == UpdateModeUploadPlaylist)) ? TRUE : FALSE;}

- (void)tracksTableDoubleClicked {
    [self.trackEditorPanel makeKeyAndOrderFront:self];
}
- (void)playlistsTableDoubleClicked {
    [self.playlistEditorPanel makeKeyAndOrderFront:self];
}


- (IBAction)copyPurchaseTitle:(id)sender {
    [self.changePurchaseTitle setStringValue:[sender title]];
}

- (IBAction)copyPurchaseURL:(id)sender {
    [self.changePurchaseURL setStringValue:[sender title]];
}

- (IBAction)performBatchChanges:(id)sender {
    
    for (Asset *asset in [self.assetBatchEditController arrangedObjects]) {
        if (self.batchChangePurchaseTitle) {
            asset.purchase_title = [self.changePurchaseTitle stringValue];
            asset.sync_mode = [NSNumber numberWithBool:TRUE];
        }
        if (self.batchChangePurchaseURL) {
            asset.purchase_url = [self.changePurchaseURL stringValue];
            asset.sync_mode = [NSNumber numberWithBool:TRUE];
        }
        if (self.batchChangeTitleSubstrings) {
            asset.title = [asset.title stringByReplacingOccurrencesOfString:[self.changeTitleSubstringFrom stringValue] withString:[self.changeTitleSubstringTo stringValue]];
            asset.sync_mode = [NSNumber numberWithBool:TRUE];
        }
        
    }
    self.batchChangePurchaseTitle = FALSE;
    self.batchChangePurchaseURL = FALSE;
    self.batchChangeTitleSubstrings = FALSE;
    [self.changedAssetsController rearrangeObjects];
}

- (IBAction)clearBatch:(id)sender {
    for (Asset *asset in [self.assetBatchEditController arrangedObjects]) {
        asset.edit_mode = [NSNumber numberWithBool:FALSE];
        [[NSSound soundNamed:@"Connect"] play];

//        NSLog(@"asset: %@", asset);
    }
    [self.assetBatchEditController rearrangeObjects];
}


- (IBAction)praxAction:(id)sender {
    NSLog(@"praxAction: - praxAction: - praxAction: - praxAction: - praxAction: - ");
    [[NSSound soundNamed:@"Error"] play];
    
}


- (NSString *)stringWithTemplate:(NSString *)template forAsset:(Asset *)asset {
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:1024];
    NSRange foundRange;
    NSRange sourceRange;
    sourceRange.location = 0;
    sourceRange.length = [template length];
    BOOL flag = FALSE;
    while (flag == FALSE) {
        foundRange = [template rangeOfString:@"$$$" options:0 range:sourceRange];
        if (foundRange.location == NSNotFound) {
            flag = TRUE;
            break;
        }
        
        sourceRange.length = (foundRange.location - sourceRange.location);
        [string appendString:[template substringWithRange:sourceRange]];
        
        sourceRange.location = (foundRange.location + 3);
        sourceRange.length = ([template length] - sourceRange.location);
        foundRange = [template rangeOfString:@"$$$" options:0 range:sourceRange];
        if (foundRange.location == NSNotFound) {
            flag = TRUE;
            
        }
        else {
            sourceRange.length = (foundRange.location - sourceRange.location);
            
            NSString *key = [template substringWithRange:sourceRange];
            
            [string appendString:[self valueOfItem:asset asStringForKey:key]];
            
            sourceRange.location = (foundRange.location + 3);
            sourceRange.length = ([template length] - sourceRange.location);
        }
    }
    [string appendString:[template substringWithRange:sourceRange]];
    return string;
}

- (NSString *)valueOfItem:(NSManagedObject *)item asStringForKey:(NSString *)key {
    NSEntityDescription *entity = [item entity];
    NSDictionary *attributesByName = [entity attributesByName];
    NSAttributeDescription *attribute = attributesByName[key];
    if (!attribute) {
        return @"---No Such Attribute Key---";
    }
    else if ([attribute attributeType] == NSUndefinedAttributeType) {
        return @"---Undefined Attribute Type---";
    }
    else if ([attribute attributeType] == NSStringAttributeType) {
        return [item valueForKey:key];
    }
    else if ([attribute attributeType] < NSDateAttributeType) { 
        return [[item valueForKey:key] stringValue];
    }
        // add more "else if" code as desired for other types
    
    else {
        return @"---Unacceptable Attribute Type---";
    }
}

- (IBAction)preview:(id)sender {
    
    NSMutableString *html = [[NSMutableString alloc] initWithCapacity:1024];
    if ([[self.startingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.startingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    NSArray *assets = [self.assetBatchEditController arrangedObjects];
    if (([assets count] > 0) &&  ([[self.blockFormatText string] length] > 0)){
        for (Asset *asset in assets) {
            [html appendString:[self stringWithTemplate:[self.blockFormatText string] forAsset:asset]];
        }
    }

    if ([[self.endingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.endingFormatText string] forAsset:self.lastSelectedAsset]];
    }

 //   NSLog(@"html: %@", html);
    
//    [self.generatedCodeText setStringValue:html];
    [[self.previewWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    [self.previewFrameWindow makeKeyAndOrderFront:self];
}

- (void)updateGeneratedCode {
    
    NSMutableString *html = [[NSMutableString alloc] initWithCapacity:1024];
    if ([[self.startingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.startingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    NSArray *assets = [self.assetBatchEditController arrangedObjects];
    if (([assets count] > 0) &&  ([[self.blockFormatText string] length] > 0)){
        for (Asset *asset in assets) {
            [html appendString:[self stringWithTemplate:[self.blockFormatText string] forAsset:asset]];
        }
    }
    
    if ([[self.endingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.endingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    //   NSLog(@"html: %@", html);
    
    [self.generatedCodeText setStringValue:html];
//    [[self.previewWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
//    [self.previewFrameWindow makeKeyAndOrderFront:self];
}


- (NSArray *)batchSortDescriptors {
	if( self._batchSortDescriptors == nil )
	{
		self._batchSortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"batchPosition" ascending:YES]];
	}
	return self._batchSortDescriptors;
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pasteboard declareTypes:[NSArray arrayWithObject:PraxItemsDropType] owner:self];
	[pasteboard setData:data forType:PraxItemsDropType];
	return YES;
}
- (NSDragOperation)tableView:(NSTableView*)table validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if( [info draggingSource] == self.assetBatchEditTable ) {
        NSArray *sortDescriptors = [self.assetBatchEditTable sortDescriptors];
        if ([sortDescriptors count] > 0) {
            if ([[sortDescriptors[0] key] isEqualToString:@"batchPosition"]) {
                if (operation == NSTableViewDropOn) [table setDropRow:row dropOperation:NSTableViewDropAbove];
                return NSDragOperationMove;
            }
        }
	}
    return NSDragOperationNone;
}
- (BOOL)tableView:(NSTableView *)table acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	NSData *rowData = [pasteboard dataForType:PraxItemsDropType];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
	NSArray *allItemsArray = [self.assetBatchEditController arrangedObjects];
	NSMutableArray *draggedItemsArray = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    
	NSUInteger currentItemIndex;
	NSRange range = NSMakeRange( 0, [rowIndexes lastIndex] + 1 );
	while([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
	{
		NSManagedObject *thisItem = [allItemsArray objectAtIndex:currentItemIndex];
        
		[draggedItemsArray addObject:thisItem];
	}
    
	int count;
	for( count = 0; count < [draggedItemsArray count]; count++ )
	{
		NSManagedObject *currentItemToMove = [draggedItemsArray objectAtIndex:count];
		[currentItemToMove setValue:temporaryViewPositionNum forKey:@"batchPosition"];
	}
    
	int tempRow;
	if( row == 0 )
		tempRow = -1;
	else
		tempRow = row;
    
	NSArray *startItemsArray = [self itemsWithViewPositionBetween:0 and:tempRow];
	NSArray *endItemsArray = [self itemsWithViewPositionGreaterThanOrEqualTo:row];
    
	int currentViewPosition;
    
	currentViewPosition = [self renumberViewPositionsOfItems:startItemsArray startingAt:0];
    
	currentViewPosition = [self renumberViewPositionsOfItems:draggedItemsArray startingAt:currentViewPosition];
    
	currentViewPosition = [self renumberViewPositionsOfItems:endItemsArray startingAt:currentViewPosition];
    
	return YES;
}

- (NSArray *)itemsWithViewPosition:(int)value
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES && batchPosition == %i", value];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithNonTemporaryViewPosition
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES && batchPosition >= 0"];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES && batchPosition >= %i", value];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(edit_mode == YES) && ((batchPosition >= %i) && (batchPosition <= %i))", lowValue, highValue];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value
{
	int currentViewPosition = value;
    
	int count = 0;
    
	if( array && ([array count] > 0) )
	{
		for( count = 0; count < [array count]; count++ )
		{
			NSManagedObject *currentObject = [array objectAtIndex:count];
			[currentObject setValue:[NSNumber numberWithInt:currentViewPosition] forKey:@"batchPosition"];
			currentViewPosition++;
		}
	}
    
	return currentViewPosition;
}

- (IBAction)praxReorderAction:(id)sender {
    [self renumberViewPositions];
}

- (void)renumberViewPositions
{
	NSArray *startItems = [self itemsWithViewPosition:startViewPosition];
    
	NSArray *existingItems = [self itemsWithNonTemporaryViewPosition];
    
	NSArray *endItems = [self itemsWithViewPosition:endViewPosition];
    
	int currentViewPosition = 0;
    
	if( startItems && ([startItems count] > 0) )
		currentViewPosition = [self renumberViewPositionsOfItems:startItems startingAt:currentViewPosition];
    
	if( existingItems && ([existingItems count] > 0) )
		currentViewPosition = [self renumberViewPositionsOfItems:existingItems startingAt:currentViewPosition];
    
	if( endItems && ([endItems count] > 0) )
		currentViewPosition = [self renumberViewPositionsOfItems:endItems startingAt:currentViewPosition];
    [self.assetBatchEditController rearrangeObjects];
}



- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate
{
    NSManagedObjectContext *moc = [self.document managedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
    [fetchRequest setPredicate:fetchPredicate];
    NSError *error = nil;
    NSArray *arrayOfItems;
	[fetchRequest setSortDescriptors:self.batchSortDescriptors];
	arrayOfItems = [moc executeFetchRequest:fetchRequest error:&error];
    
	return arrayOfItems;
}

//tableView:writeRowsWithIndexes:toPasteboard:	[newItem setValue:[NSNumber numberWithInt:-1] forKey:@"viewPosition"];



@end
