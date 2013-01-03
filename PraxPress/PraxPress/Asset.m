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
@dynamic purchase_title;
@dynamic purchase_url;
@dynamic sharing;
@dynamic sync_mode;
@dynamic tag_list;
@dynamic title;
@dynamic type;
@dynamic sub_type;
@dynamic uri;
@dynamic metadata;
@dynamic playlistType;
@dynamic trackType;



@dynamic account;
@dynamic associatedItems;

/*- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"Asset init");
  
    }
    return self;
}

- (void)dealloc {
    NSLog(@"Asset dealloc");

    [self removeObserver:self forKeyPath:@"self.title"];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    NSLog(@"Asset awakeFromNib");
    
    
}
*/
 
- (void)awakeFromFetch {
 //   NSLog(@"Asset awakeFromFetch");
 
    [self addObserver:self forKeyPath:@"self.edit_mode" options:NSKeyValueObservingOptionNew context:NULL];

    [self addObserver:self forKeyPath:@"self.title" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.purchase_title" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.purchase_url" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.sub_type" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.sharing" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.genre" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.permalink" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.tag_list" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.contents" options:NSKeyValueObservingOptionNew context:NULL];
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
 //   NSLog(@"Asset observeValueForKeyPath:%@", keyPath);
    
    if ([keyPath isEqualToString:@"self.edit_mode"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BatchAssetChangedNotification" object:self];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
    }
    
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



-(NXOAuth2Request *)updateRequest:(UpdateController *)sender {  // return a request, configured as required for account type
    
    if (![self.account oauthReady:sender.document]) return nil; // not authorized yet
    NXOAuth2Request *request;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];

    if ([self.account.accountType isEqualToString:@"SoundCloud"]) {
        sender.statusText = @"Updating SoundCloud Asset";
        sender.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
        for (NSString *key in @[@"title", @"purchase_title", @"purchase_url", @"sharing", @"genre", @"permalink"]) {
            
            NSString *asset_key = ([self.entity.name isEqualToString:@"Track"]) ? [NSString stringWithFormat:@"track[%@]", key] : [NSString stringWithFormat:@"playlist[%@]", key];
            NSString *value = ([self valueForKey:key]) ? [self valueForKey:key] : @"";
            [parameters setObject:value forKey:asset_key];
        }
        if ([self.entity.name isEqualToString:@"Track"]) {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"track[track_type]"];
        }
        else {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"playlist[playlist_type]"];
       }
        sender.parameters = parameters;
        
        request = [[NXOAuth2Request alloc] initWithResource:sender.resource method:@"PUT" parameters:sender.parameters];
    }
    
    else if ([self.account.accountType isEqualToString:@"WordPress"]) {
        sender.statusText = @"Updating WordPress Asset";
        sender.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
        
        [parameters setObject:self.title forKey:@"title"];
        [parameters setObject:self.contents forKey:@"content"];
        
        sender.parameters = parameters;
        request = [[NXOAuth2Request alloc] initWithResource:sender.resource method:@"POST" parameters:sender.parameters];
        
    }
    
    else return nil;  // invalid account type
    
    sender.account = self.account;
    request.account = self.account.oauthAccount;
    
    return request;

}


-(void)loadWordPressPostData:(NSDictionary *)data {
    
    NSDictionary *keys = @{@"title":@"title", @"purchase_url":@"URL", @"type":@"type", @"permalink":@"slug", @"contents":@"content"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
    self.uri = data[@"meta"][@"links"][@"site"];
    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
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
    
    self.type = ([self.entity.name isEqualToString:@"Playlist"]) ? @"playlist" : @"track";
    
    if ([self.entity.name isEqualToString:@"Playlist"]) {
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
    
    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
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
    for (NSDictionary *subItem in subItems) {
        NSLog(@"subItem asset_id: %@", subItem[@"id"]);
        
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
}

+ (NSString *)htmlStringForAsset:(Asset *)asset {
    NSString *html = @"<html><body>Prax</body></html>";
    if (([asset.type isEqualToString:@"post"])||([asset.type isEqualToString:@"page"])) {
        html = asset.contents;
    }
    else if ([asset.type isEqualToString:@"track"]) {
        html = [NSString stringWithFormat:@"<html><body>%@<br/> <object height=\"250\" width=\"250\"> <param name=\"movie\" value=\"http://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/tracks/%@&amp;auto_play=true&amp;buying=false&amp;sharing=false&amp;download=false&amp;player_type=artwork&amp;color=ff7700\"></param> <param name=\"allowscriptaccess\" value=\"always\"></param> <embed allowscriptaccess=\"always\" height=\"300\" src=\"http://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/tracks/%@&amp;auto_play=true&amp;buying=false&amp;sharing=false&amp;download=false&amp;player_type=artwork&amp;color=ff7700\" type=\"application/x-shockwave-flash\" width=\"250\"></embed> </object>    </body></html>", asset.title, asset.asset_id, asset.asset_id];
        
    }
    else if ([asset.type isEqualToString:@"playlist"]) {
        html = [NSString stringWithFormat:@"<html><body> <object height=\"250\" width=\"250\"> <param name=\"movie\" value=\"http://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/playlists/%@&amp;auto_play=true&amp;buying=false&amp;sharing=false&amp;download=false&amp;player_type=artwork&amp;color=ff7700\"></param> <param name=\"allowscriptaccess\" value=\"always\"></param> <embed allowscriptaccess=\"always\" height=\"300\" src=\"http://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/playlists/%@&amp;auto_play=true&amp;buying=false&amp;sharing=false&amp;download=false&amp;player_type=artwork&amp;color=ff7700\" type=\"application/x-shockwave-flash\" width=\"250\"></embed> </object>    </body></html>", asset.asset_id, asset.asset_id];
    }
    return html;
}



@end
