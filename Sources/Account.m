//
//  Account.m
//  PraxPress
//
//  Created by Elmer on 12/26/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Account.h"

@implementation Account
@synthesize updateOption;
@synthesize updateOffset;

@dynamic accountID;
@dynamic accountURI;
@dynamic active;
@dynamic enabled;
@dynamic image;
@dynamic itemCount;
@dynamic metadata;
@dynamic name;
@dynamic oauthAccount;
@dynamic stringA;
@dynamic stringB;
@dynamic stringC;
@dynamic stringD;
@dynamic subCountA;
@dynamic subCountB;
@dynamic subCountC;
@dynamic subCountD;
@dynamic userID;
@dynamic username;
@dynamic websiteURL;

@dynamic assets;
@dynamic sources;

- (void)removeAccessForAccountType:(NSString *)accountType {
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:accountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
}


- (BOOL)oauthReady:(Document *)document {
    
    if (!self.oauthAccount) {
        NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:self.name];
        if ([oauthAccounts count] > 0) {
            self.oauthAccount = oauthAccounts[0];
            self.active = @YES;
        } else {
            
            [self removeAccessForAccountType:self.name];
            
            [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.name
                                           withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                               //        [document.authorizationWindow makeKeyAndOrderFront:self];
                                               //         [[document.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                           }];
            return FALSE;
        }
    }
    return TRUE;
    
}


-(NXOAuth2Request *)requestForDownloadController:(RequestController *)controller {  // return a request, configured as required for account type
    
    controller.parameters = [NSDictionary dictionary];
    if (![self oauthReady:controller.document]) return nil;
        
        
        if ([self.name isEqualToString:@"SoundCloud"]) {
            if (self.updateOption == PRAXReloadOptionAccount) {
                controller.statusText = @"Downloading SoundCloud User Profile";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
            }
            else if (self.updateOption == PRAXReloadOptionTracks) {
                controller.statusText = @"Downloading SoundCloud Tracks";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
                controller.parameters = @{@"limit":@"17", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = self.subCountA.integerValue;
                
                
            }
            else if (self.updateOption == PRAXReloadOptionPlaylists) {
                controller.statusText = @"Downloading SoundCloud Playlists";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
                controller.parameters = @{@"limit":@"17", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = self.subCountB.integerValue;
            }
            else return nil;
        }
        else if ([self.name isEqualToString:@"WordPress"]) {
            if (self.updateOption == PRAXReloadOptionAccount) {
                controller.statusText = @"Downloading WordPress User Profile";
                controller.resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
            }
            else if (self.updateOption == PRAXReloadOptionSite) {
                controller.statusText = @"Downloading WordPress SiteData";
                controller.resource = [NSURL URLWithString:self.accountURI];
            }
            else if (self.updateOption == PRAXReloadOptionPosts) {
                controller.statusText = @"Downloading WordPress Posts";
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/", self.accountURI]];
                controller.parameters = @{@"status":@"any", @"type":@"any", @"context":@"edit", @"number":@"17", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = self.itemCount.integerValue;
            }
            else return nil;
        }
        
        else if ([self.name isEqualToString:@"Flickr"]) {
            controller.statusText = @"Downloading Flickr User Profile";
            controller.resource = [NSURL URLWithString:@"https://public-api.Flickr.com/rest/v1/me"];
        }
        
        else if ([self.name isEqualToString:@"YouTube"]) {
            controller.statusText = @"Downloading YouTube User Profile";
            controller.resource = [NSURL URLWithString:@"https://public-api.YouTube.com/rest/v1/me"];
        }
        else return nil;
        
        NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"GET" parameters:controller.parameters];
        request.account = self.oauthAccount;
        if (!request.account) return nil;
        else return request;
}

-(void)handleReloadResponseData:(NSData *)responseData forController:(RequestController *)controller {
    
    
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:0];
    //    NSLog(@"data: %@", data);
    
    if ([self.name isEqualToString:@"SoundCloud"]) {
        
        if (self.updateOption == PRAXReloadOptionAccount) {
            [self loadSoundCloudAccountData:data];
            [controller reloadAccount:self option:PRAXReloadOptionTracks replace:controller.replace];
            return;
        }

        controller.determinate = YES;
        for (NSDictionary *item in data) {

            dispatch_async(controller.responseHandlingQueue, ^{
                [self handleReloadData:item forController:controller];
            });
            
            controller.updateCount = controller.updateCount + 1;
        }
        [self updateSourceCountsForDocument:controller.document];
        if (controller.updateCount < controller.targetCount) {
            [controller reloadAccount:self option:self.updateOption replace:controller.replace];
            return;
        }

        
        if (self.updateOption == PRAXReloadOptionTracks) {
                controller.updateCount = 0;
                controller.determinate = NO;
                [controller reloadAccount:self option:PRAXReloadOptionPlaylists replace:controller.replace];
        }
        else if (self.updateOption == PRAXReloadOptionPlaylists) {
            [controller reset];
        }
        else return; // invalid option
    }
    
    
    else if ([self.name isEqualToString:@"WordPress"]) {
        
        if (self.updateOption == PRAXReloadOptionAccount) {
            [self loadWordPressAccountData:data];
            [controller reloadAccount:self option:PRAXReloadOptionSite replace:controller.replace];
        }
        else if (self.updateOption == PRAXReloadOptionSite) {
            [self loadWordPressSiteData:data];
            [controller reloadAccount:self option:PRAXReloadOptionPosts replace:controller.replace];
        }
        else if (self.updateOption == PRAXReloadOptionPosts) {
            if ([(NSNumber *)data[@"found"] integerValue] < 1) {
                [controller reset];
            }
            else {
//                Asset *asset;
//                for (NSDictionary *item in data[@"posts"]) {
                    
                controller.determinate = YES;
                for (NSDictionary *item in data[@"posts"]) {
                    
         //           dispatch_async(controller.responseHandlingQueue, ^{
                        [self handleReloadData:item forController:controller];
         //           });
                    
                    controller.updateCount = controller.updateCount + 1;
                }
                [self updateSourceCountsForDocument:controller.document];

                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAccount:self option:self.updateOption replace:controller.replace];
                }
                else [controller reset];
            }
        }
    }
    return;
}


-(void)handleReloadData:(NSDictionary *)data forController:(RequestController *)controller {
    Asset *asset;
    NSString *assetID;
    if ([self.name isEqualToString:@"WordPress"]) {
        assetID = data[@"ID"];
    }
    else if ([self.name isEqualToString:@"SoundCloud"]) {
        assetID = data[@"id"];
    }
    else return; // invalid name
    
    asset = [NSManagedObject entity:@"Asset" withKey:@"asset_id" matchingStringValue:assetID inManagedObjectContext:controller.document.managedObjectContext];
    
    if (!asset) {
        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Asset" inManagedObjectContext:controller.document.managedObjectContext];
        asset.asset_id = [NSNumber numberWithInt:assetID.intValue];
        asset.batchPosition = [NSNumber numberWithInt:-1];
    }
    asset.account = self;
    asset.accountType = self.name;
    [asset loadAssetData:data forController:controller];
    return;
    
}


-(void)loadWordPressPageCount:(NSDictionary *)data {
    NSLog(@"loadWordPressPageCount: %@", data);
    
//    self.playlist_count = data[@"found"];
//    int posts = [self.track_count intValue];
//    int pages = [self.playlist_count intValue];
//    posts -= pages;
//    self.track_count = [NSNumber numberWithInt:posts];
//    self.sync_mode = [NSNumber numberWithBool:FALSE];
}


-(void)loadWordPressAccountData:(NSDictionary *)data {
    NSLog(@"loadWordPressAccountData: %@", data);
    [self setValue:data forKey:@"metadata"];

    self.accountURI = self.metadata[@"meta"][@"links"][@"site"];
    
    NSDictionary *keys = @{
                           @"userID":@"ID",
                           @"accountID":@"primary_blog",
                           @"username":@"display_name",
                           @"stringB":@"email",
                           @"stringC":@"username"
                           };
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:self.metadata[keys[key]] forKey:key];
    }

    if (self.metadata[@"avatar_URL"] != [NSNull null]) {
        self.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:self.metadata[@"avatar_URL"]]];
        
 //       NSURL *url = [NSURL URLWithString:self.stringA];
  //      NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
   //     self.image =  [NSArchiver archivedDataWithRootObject:image];
        
    }
}

-(void)loadWordPressSiteData:(NSDictionary *)data {
    NSLog(@"loadWordPressSiteData: %@", data);
    
    NSMutableDictionary *metadata = self.metadata.mutableCopy;
    [metadata addEntriesFromDictionary:data];
    [self setValue:metadata forKey:@"metadata"];
    
    NSDictionary *keys = @{
                           @"itemCount":@"post_count",
                           @"subCountD":@"subscribers_count",
                           @"stringA":@"name",
                           @"stringD":@"description",
                           @"websiteURL":@"URL"
                           };
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:self.metadata[keys[key]] forKey:key];
    }
    
}
-(void)loadSoundCloudAccountData:(NSDictionary *)data {
    
    [self setValue:data forKey:@"metadata"];
    
    NSDictionary *keys = @{
                           @"accountID":@"id",
                           @"accountURI":@"uri",
                           
                           @"stringC":@"city",
                          // @"country":@"country",
                           @"stringD":@"description",
                           //   @"discogs_name":@"discogs_name",
                           @"subCountC":@"followers_count",
                           @"subCountD":@"followings_count",
                          // @"title":@"full_name",
                           //   @"myspace_name":@"myspace_name",
                          // @"permalink":@"permalink",
                           @"websiteURL":@"permalink_url",
                           @"subCountB":@"playlist_count",
                         //  @"favoritings_count":@"public_favorites_count",
                           @"subCountA":@"track_count",
                           @"username":@"username",
                           @"stringB":@"website",
                           @"stringA":@"website_title"};
    
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:self.metadata[keys[key]] forKey:key];
    }
    
    if (self.metadata[@"avatar_url"] != [NSNull null]) {
        
        self.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:data[@"avatar_url"]]];

/*        NSString *artwork_url = data[@"avatar_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
 //       self.artwork_url = artwork_url;
        
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        //     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image =  [NSArchiver archivedDataWithRootObject:image];
        //       });
*/    }
//    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
}

-(void)updateSourceCountsForDocument:(Document *)document {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
    NSError *error;
    document.sourceController.allItemsSource.itemCount = [NSNumber numberWithInteger:[document.managedObjectContext countForFetchRequest:request error:&error]];
    for (Source *source in self.sources) {
        [request setPredicate:source.fetchPredicate];
        source.itemCount = [NSNumber numberWithInteger:[document.managedObjectContext countForFetchRequest:request error:&error]];
    }
}



@end
