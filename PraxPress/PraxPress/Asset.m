//
//  Asset.m
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Asset.h"

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

@dynamic accountType;
@dynamic city;
@dynamic country;
@dynamic username;
@dynamic followers_count;
@dynamic followings_count;
@dynamic playlist_count;
@dynamic track_count;
@dynamic update_offset;
@dynamic user_id;

@dynamic account;
@dynamic tracks;
@dynamic playlists;

-(void)loadWordPressSiteData:(NSDictionary *)data {
    NSLog(@"loadWordPressSiteData: %@", data);
    self.track_count = data[@"post_count"];
    self.title = data[@"description"];
}

-(void)loadWordPressAccountData:(NSDictionary *)data {
    NSLog(@"loadWordPressAccountData: %@", data);
    self.user_id = data[@"ID"];
    self.asset_id = data[@"primary_blog"];
    self.title = data[@"description"];
    self.username = data[@"display_name"];
    self.permalink = data[@"username"];
    
    if (data[@"avatar_URL"] != [NSNull null]) {
        NSString *artwork_url = data[@"avatar_URL"];
        //     NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        //     artwork_url = [NSString stringWithString:(NSString *)a[0]];
        self.artwork_url = artwork_url;
        
        //     artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image =  [NSArchiver archivedDataWithRootObject:image];
    }
    
}
-(void)loadSoundCloudAccountData:(NSDictionary *)data {
    self.title = data[@"full_name"];
    self.asset_id = data[@"id"];
    self.username = data[@"username"];
    self.permalink = data[@"permalink"];
    self.playlist_count = data[@"playlist_count"];
    self.track_count = data[@"track_count"];
    self.followers_count = data[@"followers_count"];
    self.followings_count = data[@"followings_count"];
    self.contents = data[@"description"];
    self.city = data[@"city"];
    self.country = data[@"country"];
    self.purchase_url = data[@"website"];
    self.purchase_title = data[@"website_title"];
    if (data[@"avatar_url"] != [NSNull null]) {
        NSString *artwork_url = data[@"avatar_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        self.artwork_url = artwork_url;
        
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        //     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image =  [NSArchiver archivedDataWithRootObject:image];
        //       });
    }
}




-(void)loadWordPressPostData:(Asset *)asset data:(NSDictionary *)data {
    
    self.title = data[@"title"];
    self.purchase_url = data[@"URL"];
    self.type = data[@"type"];
    self.permalink = data[@"slug"];
    self.contents = data[@"content"];
    
    self.uri = data[@"meta"][@"links"][@"site"];
    
    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
}
-(void)loadSoundCloudItemData:(NSDictionary *)data {
    
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
    if (data[@"artwork_url"] != [NSNull null]) {
        NSString *artwork_url = data[@"artwork_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        self.artwork_url = artwork_url;
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //original
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image = [NSArchiver archivedDataWithRootObject:image];
        //        [self.progressImageWell setImage:image];
    }
    self.permalink = data[@"permalink"];
    self.uri = data[@"uri"];
    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
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
