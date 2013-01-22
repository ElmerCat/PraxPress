//
//  Asset.m
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Asset.h"
#import "UpdateController.h"

@implementation Asset

@synthesize awake;
@dynamic artwork_url;
@dynamic asset_id;
@dynamic batchPosition;
@dynamic contents;
@dynamic date;
@dynamic edit_mode;
@dynamic genre;
@dynamic image;
@dynamic info_mode;
@dynamic permalink;
@dynamic playlistPosition;
@dynamic purchase_title;
@dynamic purchase_url;
@dynamic sharing;
@dynamic sync_mode;
@dynamic tag_list;
@dynamic title;
@dynamic type;
@dynamic sub_type;
@dynamic uri;
@dynamic updateOption;
@dynamic metadata;
@dynamic playlistType;
@dynamic trackList;
@dynamic trackType;
@dynamic tags;

@dynamic account;
@dynamic associatedItems;

#pragma mark Accessors

-(NSInteger)reloadOptionAccount {return 1;}
-(NSInteger)reloadOptionSite {return 2;}
-(NSInteger)reloadOptionTracks {return 3;}
-(NSInteger)reloadOptionPlaylists {return 4;}
-(NSInteger)reloadOptionPosts {return 5;}


-(BOOL)isSoundCloudAsset {
    if ((self.isTrack)||(self.isPlaylist)) return YES;
    else return NO;
}
-(BOOL)isTrack {
    if ([self.entity.name isEqualToString:@"Track"]) return YES;
    else return NO;
}
-(BOOL)isPlaylist {
    if ([self.entity.name isEqualToString:@"Playlist"]) return YES;
    else return NO;
}
-(BOOL)isWordPressAsset {
    if ([self.entity.name isEqualToString:@"Post"]) return YES;
    else return NO;
}
-(BOOL)isPage {
    if (([self.type isEqualToString:@"page"])) return YES;
    else return NO;
}
-(BOOL)isPost {
    if (([self.type isEqualToString:@"post"])) return YES;
    else return NO;
}
-(BOOL)isAccount {
    if ([self.entity.name isEqualToString:@"Account"]) return YES;
    else return NO;
}


- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"Asset init");
  
    }
    return self;
}

- (void)dealloc {
//    NSLog(@"Asset dealloc");
    if (self.awake) {
        self.awake = FALSE;
        
        [self removeObserver:self forKeyPath:@"self.edit_mode"];
        [self removeObserver:self forKeyPath:@"self.title"];
        [self removeObserver:self forKeyPath:@"self.purchase_title"];
        [self removeObserver:self forKeyPath:@"self.purchase_url"];
        [self removeObserver:self forKeyPath:@"self.sub_type"];
        [self removeObserver:self forKeyPath:@"self.sharing"];
        [self removeObserver:self forKeyPath:@"self.genre"];
        [self removeObserver:self forKeyPath:@"self.permalink"];
        [self removeObserver:self forKeyPath:@"self.tag_list"];
        [self removeObserver:self forKeyPath:@"self.trackList"];
        [self removeObserver:self forKeyPath:@"self.tags"];
        [self removeObserver:self forKeyPath:@"self.contents"];
        
    }

    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
- (void)awakeFromNib {
    NSLog(@"Asset awakeFromNib");
    
    
}
*/
 
- (void)awakeFromFetch {
    
    if (!self.awake) {
        self.awake = TRUE;
//        NSLog(@"Asset awakeFromFetch");
        
        [self addObserver:self forKeyPath:@"self.edit_mode" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.title" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.purchase_title" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.purchase_url" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.sub_type" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.sharing" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.genre" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.permalink" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.tag_list" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.trackList" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.tags" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"self.contents" options:NSKeyValueObservingOptionNew context:NULL];
        
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
 //   NSLog(@"Asset observeValueForKeyPath:%@", keyPath);
    
    if ([keyPath isEqualToString:@"self.edit_mode"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BatchAssetChangedNotification" object:self];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
        if ([keyPath isEqualToString:@"self.tags"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetTagsChangedNotification" object:self];
        }

    }
    
}



-(NXOAuth2Request *)requestForReloadController:(UpdateController *)controller option:(PRAXReloadOption)option {  // return a request, configured as required for account type
    
    controller.parameters = [NSDictionary dictionary];
    self.updateOption = [NSNumber numberWithUnsignedInteger:option];
    
    if ([self.entity.name isEqualToString:@"Account"]) {
        
        if (![(Account *)self oauthReady:controller.document]) return nil;
        

        if ([[(Account *)self accountType] isEqualToString:@"SoundCloud"]) {
            if (option == PRAXReloadOptionAccount) {
                controller.statusText = @"Downloading SoundCloud User Profile";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
            }
            else if (option == PRAXReloadOptionTracks) {
                controller.statusText = @"Downloading SoundCloud Tracks";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
                controller.parameters = @{@"limit":@"10", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = [[(Account *)self track_count] integerValue];
                
 
            }
            else if (option == PRAXReloadOptionPlaylists) {
                controller.statusText = @"Downloading SoundCloud Playlists";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
                controller.parameters = @{@"limit":@"10", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = [[(Account *)self playlist_count] integerValue];
                
            }
            else return nil;

            
            
        }
        else if ([[(Account *)self accountType] isEqualToString:@"WordPress"]) {
            if (option == PRAXReloadOptionAccount) {
                controller.statusText = @"Downloading WordPress User Profile";
                controller.resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
            }
            else if (option == PRAXReloadOptionSite) {
                controller.statusText = @"Downloading WordPress SiteData";
                controller.resource = [NSURL URLWithString:self.uri];
            }
            else if (option == PRAXReloadOptionPosts) {
                controller.statusText = @"Downloading WordPress Posts";
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/", self.uri]];
                controller.parameters = @{@"status":@"any", @"type":@"any", @"context":@"edit", @"number":@"10", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = [[(Account *)self itemCount] integerValue];
            }
            else return nil;
        }
        
        else if ([self.account.accountType isEqualToString:@"Flickr"]) {
            controller.statusText = @"Downloading Flickr User Profile";
            controller.resource = [NSURL URLWithString:@"https://public-api.Flickr.com/rest/v1/me"];
        }
        
        else if ([self.account.accountType isEqualToString:@"YouTube"]) {
            controller.statusText = @"Downloading YouTube User Profile";
            controller.resource = [NSURL URLWithString:@"https://public-api.YouTube.com/rest/v1/me"];
        }
        else return nil;
        
        NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"GET" parameters:controller.parameters];
        request.account = [(Account *)self oauthAccount];
        if (!request.account) return nil;
        else return request;
    }
    else {
      
        if (![self.account oauthReady:controller.document]) return nil;
        
        
        if (self.isSoundCloudAsset) {
            controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
            if (self.isTrack) controller.statusText = [NSString stringWithFormat:@"Downloading SoundCloud Track ---- %@", self.title];
            else controller.statusText = [NSString stringWithFormat:@"Downloading SoundCloud Playlist ---- %@", self.title];
         }
        
        else if (self.isWordPressAsset) {
            controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
            controller.parameters = @{@"context":@"edit"};
            if (self.isPost) controller.statusText = [NSString stringWithFormat:@"Downloading WordPress Post ---- %@", self.title];
            else controller.statusText = [NSString stringWithFormat:@"Downloading WordPress Page ---- %@", self.title];
        }
        else return nil;
        
        NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"GET" parameters:controller.parameters];
        request.account = self.account.oauthAccount;
        if (!request.account) return nil;
        else return request;
        
    }
    

}



-(NXOAuth2Request *)requestForUploadController:(UpdateController *)controller {  // return a request, configured as required for account type
    
    
    if (![self.account oauthReady:controller.document]) return nil; // not authorized yet
    NXOAuth2Request *request;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    controller.statusText = [NSString stringWithFormat:@"Uploading %@ Asset %@", self.account.accountType, self.permalink];
    request.account = self.account.oauthAccount;
    
    if (self.isSoundCloudAsset) {
       
        for (NSString *key in @[@"title", @"purchase_title", @"purchase_url", @"sharing", @"genre", @"permalink", @"tag_list"]) {
            
            NSString *asset_key = (self.isTrack) ? [NSString stringWithFormat:@"track[%@]", key] : [NSString stringWithFormat:@"playlist[%@]", key];
            NSString *value = ([self valueForKey:key]) ? [self valueForKey:key] : @"";
            [parameters setObject:value forKey:asset_key];
        }
        
        if (self.isTrack) {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"track[track_type]"];
            controller.statusText = [NSString stringWithFormat:@"Uploading SoundCloud Track ---- %@", self.title];
        }
        else {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"playlist[playlist_type]"];
            
            NSArray *tracks = [self.trackList componentsSeparatedByString:@","];
            [parameters setObject:tracks forKey:@"playlist[tracks][][id]"];
            controller.statusText = [NSString stringWithFormat:@"Uploading SoundCloud Playlist ---- %@", self.title];
        }
        
        if (!self.asset_id) {  // uploading a new Asset
            if (self.isPlaylist) {
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/me/playlists.json"]];
                
            }
            else {
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/me/tracks.json"]];
                
            }
            controller.parameters = parameters;
            request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"POST" parameters:controller.parameters];
        }
        
        else {
            controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
            controller.parameters = parameters;
            request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"PUT" parameters:controller.parameters];
        }
    }
    
    else if (self.isWordPressAsset) {

        
        [parameters setObject:self.title forKey:@"title"];
        [parameters setObject:self.contents forKey:@"content"];
        
        
        controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
        controller.parameters = parameters;
        if (self.isPost) controller.statusText = [NSString stringWithFormat:@"Uploading WordPress Post ---- %@", self.title];
        else controller.statusText = [NSString stringWithFormat:@"Uploading WordPress Page ---- %@", self.title];
        request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"POST" parameters:controller.parameters];
        
    }
    
    else return nil;  // invalid Asset type
    
    return request;

}

-(BOOL)handleReloadResponseData:(NSData *)responseData forController:(UpdateController *)controller {
    
    
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:0];
    NSLog(@"data: %@", data);
    
 
    if ([self.entity.name isEqualToString:@"Account"]) {

        if ([[(Account *)self accountType] isEqualToString:@"SoundCloud"]) {
            
            if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionAccount) {
                [(Account *)self loadSoundCloudAccountData:data];
                if (controller.reloadAll) {
                    [controller reloadAsset:self option:PRAXReloadOptionTracks];
                }
                else [controller reset];
            }

            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionTracks) {
                Asset *asset;
                for (NSDictionary *item in data) {
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
                    NSArray *matchingItems = [controller.document.managedObjectContext executeFetchRequest:request error:nil];
                    if ([matchingItems count] < 1) {
                        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:controller.document.managedObjectContext];
                        asset.asset_id = [NSNumber numberWithInt:[item[@"id"] intValue]];
                        asset.batchPosition = [NSNumber numberWithInt:-1];
                    }
                    else asset = matchingItems[0];
                    asset.account = (Account *)self;
                    
                    controller.determinate = YES;
                    controller.updateCount = controller.updateCount + 1;
                    [asset loadSoundCloudItemData:item];
                    [controller.document.tagController loadAssetTags:asset];
                    asset.sync_mode = [NSNumber numberWithBool:FALSE];
                    
                }
                
                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAsset:self option:self.updateOption.unsignedIntegerValue];
                }
                else if (controller.reloadAll) {
                    controller.updateCount = 0;
                    controller.determinate = NO;
                    [controller reloadAsset:self option:PRAXReloadOptionPlaylists];
                }
                else [controller reset];
                
            }
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionPlaylists) {
                
                Asset *asset;
                for (NSDictionary *item in data) {
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
                    NSArray *matchingItems = [controller.document.managedObjectContext executeFetchRequest:request error:nil];
                    if ([matchingItems count] < 1) {
                        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:controller.document.managedObjectContext];
                        asset.asset_id = [NSNumber numberWithInt:[item[@"id"] intValue]];
                        asset.batchPosition = [NSNumber numberWithInt:-1];
                        
                    }
                    else asset = matchingItems[0];
                    asset.account = self.account;
                    
                    controller.determinate = YES;
                    controller.updateCount = controller.updateCount + 1;
                    [asset loadSoundCloudItemData:item];
                    [asset loadPlaylistsAsset:asset data:item];
                    [controller.tagController loadAssetTags:asset];
                    asset.sync_mode = [NSNumber numberWithBool:FALSE];

                }
                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAsset:self option:self.updateOption.unsignedIntegerValue];
                }
                else [controller reset];
            }
            else return NO; // invalid option
        }

        
        else if ([[(Account *)self accountType] isEqualToString:@"WordPress"]) {
            
            if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionAccount) {
                [(Account *)self loadWordPressAccountData:data];
                if (controller.reloadAll) {
                    [controller reloadAsset:self option:PRAXReloadOptionSite];
                }
                else [controller reset];
            }
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionSite) {
                [(Account *)self loadWordPressSiteData:data];
                if (controller.reloadAll) {
                    [controller reloadAsset:self option:PRAXReloadOptionPosts];
                }
                else [controller reset];
            }
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionPosts) {
                Asset *asset;
                for (NSDictionary *item in data[@"posts"]) {
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"ID"]]];
                    NSArray *matchingItems = [controller.document.managedObjectContext executeFetchRequest:request error:nil];
                    if ([matchingItems count] < 1) {
                        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:controller.document.managedObjectContext];
                        asset.asset_id = [NSNumber numberWithInt:[item[@"ID"] intValue]];
                        asset.batchPosition = [NSNumber numberWithInt:-1];
                    }
                    else asset = matchingItems[0];
                    asset.account = (Account *)self;
                    
                    controller.determinate = YES;
                    controller.updateCount = controller.updateCount + 1;
                    [asset loadWordPressPostData:item];
                    [controller.document.tagController loadAssetTags:asset];
                    asset.sync_mode = [NSNumber numberWithBool:FALSE];
                    
                }
                
                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAsset:self option:self.updateOption.unsignedIntegerValue];
                }
                else [controller reset];
            }
            else return NO; // invalid option
        }
    }
    else {
        if (self.isSoundCloudAsset) {
            [self loadSoundCloudItemData:data];
            if (self.isPlaylist) [self loadPlaylistsAsset:self data:data];
        }
        else if (self.isWordPressAsset)[self loadWordPressPostData:data];
        else return NO; // invalid option
        
        [controller.tagController loadAssetTags:self];
        self.sync_mode = [NSNumber numberWithBool:FALSE];
        
        if (controller.reloadAll) {
            controller.updateCount += 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller reloadChangedAssets];
            });
        }
        else if (controller.uploadAll) {
            controller.updateCount += 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller uploadChangedAssets];
            });
        }
        else {
            [controller reset];
        }
    }
    return YES;
    
}

-(void)loadWordPressPostData:(NSDictionary *)data {
    [self setValue:data forKey:@"metadata"];
    
    NSDictionary *keys = @{@"title":@"title", @"purchase_url":@"URL", @"type":@"type", @"permalink":@"slug", @"contents":@"content"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
    self.uri = data[@"meta"][@"links"][@"site"];
    
}

-(NSImage *)loadSoundCloudItemData:(NSDictionary *)data {
    
    [self setValue:data forKey:@"metadata"];
    
    for (NSString *key in @[@"title", @"purchase_url", @"purchase_title", @"permalink", @"sharing", @"uri", @"genre", @"tag_list", @"duration"]) {
        if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[key] forKey:key];
    }
    
    
    NSDictionary *keys = @{@"date":@"created_at", @"contents":@"description"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
    if (self.isPlaylist) {
        self.type = @"playlist";
        for (NSString *key in @[@"playlist_type"]) {
            if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
            else [self setValue:data[key] forKey:@"sub_type"];
        }
    }
    else {
        self.type = @"track";
        for (NSString *key in @[@"track_type"]) {
            if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
            else [self setValue:data[key] forKey:@"sub_type"];
        }
    }
    
    
    if (data[@"artwork_url"] != [NSNull null]) {
        NSString *artwork_url = data[@"artwork_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        self.artwork_url = artwork_url;
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //original
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image = [NSArchiver archivedDataWithRootObject:image];
        return image;
    }
    else return nil;
}

-(void)loadPlaylistsAsset:(Asset *)asset data:(NSDictionary *)data {
    Asset *subAsset;
    NSArray *subItems;
    NSError *error = nil;
    asset.associatedItems = nil;
    subItems = data[@"tracks"];
    NSMutableString *trackList = [[NSMutableString alloc] init];
    for (NSDictionary *subItem in subItems) {
        NSLog(@"subItem asset_id: %@", subItem[@"id"]);
        if (trackList.length > 0) [trackList appendString:@","];
        [trackList appendString:[subItem[@"id"] stringValue]];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", subItem[@"id"]]];
        NSArray *matchingItems = [asset.managedObjectContext executeFetchRequest:request error:&error];
        
        if ([matchingItems count] < 1) {
            NSLog(@"Error: - No matching Asset - subItem asset_id: %@", subItem[@"id"]);
        }
        else {
            subAsset = matchingItems[0];
            [asset addAssociatedItemsObject:subAsset];
        }
    }
    self.trackList = trackList.description;
}


/*
 
 - (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error {
 BOOL result = [super validateValue:value forKey:key error:error];
 
 NSLog(@"Asset validateValue:%@ forKey:%@ error:%@", *value, key, *error);
 
 
 return result;
 
 }
 
 
 - (BOOL)validateForUpdate:(NSError **)error {
 BOOL result = [super validateForUpdate:error];
 
 NSLog(@"Asset validateForUpdate");
 
 
 return result;
 }
 
 - (BOOL)validateSharing:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateSharing %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateSub_type:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateSub_type %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateTitle:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTitle %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateGenre:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateGenre %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validatePermalink:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validatePermalink %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validatePurchase_title:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTitle %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validatePurchase_url:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTitle %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateTag_list:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTag_list %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateContents:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateContents %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (void)setAssetChanged:(Asset *)asset {
 
 asset.sync_mode = [NSNumber numberWithBool:TRUE];
 //    [self.changedAssetsController rearrangeObjects];
 
 } */





@end
