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

@dynamic image;
@dynamic edit_mode;
@dynamic info_mode;
@dynamic sync_mode;
@dynamic artwork_url;
@dynamic contents;
@dynamic date;
@dynamic permalink;
@dynamic purchase_title;
@dynamic purchase_url;
@dynamic title;
@dynamic type;
@dynamic uri;
@dynamic asset_id;
@dynamic batchPosition;

@dynamic account;
@dynamic tracks;
@dynamic playlists;

-(NXOAuth2Request *)updateRequest:(UpdateController *)sender {  // return a request, configured as required for account type
    
    if (![self.account oauthReady:sender.document]) return nil; // not authorized yet
    NXOAuth2Request *request;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];

    if ([self.account.accountType isEqualToString:@"SoundCloud"]) {
        sender.statusText = @"Updating SoundCloud Asset";
        sender.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
        for (NSString *key in @[@"title", @"purchase_title", @"purchase_url"]) {
            
            NSString *asset_key = ([self.entity.name isEqualToString:@"Track"]) ? [NSString stringWithFormat:@"track[%@]", key] : [NSString stringWithFormat:@"playlist[%@]", key];
            NSString *value = ([self valueForKey:key]) ? [self valueForKey:key] : @"";
            [parameters setObject:value forKey:asset_key];
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
    
    self.title = data[@"title"];
    self.purchase_url = data[@"URL"];
    self.type = data[@"type"];
    self.permalink = data[@"slug"];
    self.contents = data[@"content"];
    
    self.uri = data[@"meta"][@"links"][@"site"];
    
    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
}
-(NSImage *)loadSoundCloudItemData:(NSDictionary *)data {
    
    self.type = ([self.entity.name isEqualToString:@"Playlist"]) ? @"playlist" : @"track";
    
    self.title = data[@"title"];
    
    if (data[@"purchase_url"] != [NSNull null]) {
        self.purchase_url = data[@"purchase_url"];
    }
    else {
        self.purchase_url = nil;
    }
    if (data[@"purchase_title"] != [NSNull null]) {
        self.purchase_title = data[@"purchase_title"];
    }
    else {
        self.purchase_title = nil;
    }
    self.permalink = data[@"permalink"];
    self.uri = data[@"uri"];
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
    asset.tracks = nil;
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
            [asset addTracksObject:subAsset];
        }
    }
}

+ (NSString *)htmlStringForAsset:(Asset *)asset {
    NSString *html = @"<html><body>Prax</body></html>";
    if (([asset.type isEqualToString:@"post"])||([asset.type isEqualToString:@"page"])) {
        html = asset.contents;
    }
    else if ([asset.type isEqualToString:@"track"]) {
        html = [NSString stringWithFormat:@"<html><body> <object height=\"300\" width=\"300\"> <param name=\"movie\" value=\"https://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/tracks/%@&amp;auto_play=false&amp;player_type=artwork&amp;color=ff7700\"></param> <param name=\"allowscriptaccess\" value=\"always\"></param> <embed allowscriptaccess=\"always\" height=\"300\" src=\"https://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/tracks/%@&amp;auto_play=false&amp;player_type=artwork&amp;color=ff7700\" type=\"application/x-shockwave-flash\" width=\"300\"></embed> </object>    </body></html>", asset.asset_id, asset.asset_id];
        
    }
    else if ([asset.type isEqualToString:@"playlist"]) {
        html = [NSString stringWithFormat:@"<html><body> <object height=\"300\" width=\"300\"> <param name=\"movie\" value=\"https://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/playlists/%@&amp;auto_play=false&amp;player_type=artwork&amp;color=ff7700\"></param> <param name=\"allowscriptaccess\" value=\"always\"></param> <embed allowscriptaccess=\"always\" height=\"300\" src=\"https://player.soundcloud.com/player.swf?url=http://api.soundcloud.com/playlists/%@&amp;auto_play=false&amp;player_type=artwork&amp;color=ff7700\" type=\"application/x-shockwave-flash\" width=\"300\"></embed> </object>    </body></html>", asset.asset_id, asset.asset_id];
    }
    return html;
}



@end
