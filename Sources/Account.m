//
//  Account.m
//  PraxPress
//
//  Created by John Canfield on 9/21/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Account.h"
#import "Asset.h"
#import "Document.h"

@implementation Account

@dynamic accountType;
@dynamic city;
@dynamic country;
@dynamic username;
@dynamic followers_count;
@dynamic followings_count;
@dynamic itemCount;
@dynamic playlist_count;
@dynamic track_count;
@dynamic update_offset;
@dynamic user_id;
@dynamic oauthAccount;


- (BOOL)oauthReady:(Document *)document {
    
    if (!self.oauthAccount) {
        NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:self.accountType];
        if ([oauthAccounts count] > 0) {
            self.oauthAccount = oauthAccounts[0];
        } else {
            
            [self removeAccessForAccountType:self.accountType];
            
            [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.accountType
                                           withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                               [document.authorizationWindow makeKeyAndOrderFront:self];
                                               [[document.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                           }];
            return FALSE;
        }
    }
    return TRUE;
    
}

- (void)removeAccessForAccountType:(NSString *)accountType {
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:accountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
}


-(void)loadWordPressPageCount:(NSDictionary *)data {
    NSLog(@"loadWordPressPageCount: %@", data);
    
    self.playlist_count = data[@"found"];
    int posts = [self.track_count intValue];
    int pages = [self.playlist_count intValue];
    posts -= pages;
    self.track_count = [NSNumber numberWithInt:posts];
    self.sync_mode = [NSNumber numberWithBool:FALSE];
}


-(void)loadWordPressAccountData:(NSDictionary *)data {
    NSLog(@"loadWordPressAccountData: %@", data);
    [self setValue:data forKey:@"metadata"];
    NSDictionary *meta = data[@"meta"];
    self.uri = meta[@"links"][@"site"];
    
    NSDictionary *keys = @{
    @"user_id":@"ID",
    @"username":@"username",
    @"asset_id":@"primary_blog",
    @"city":@"email",
    @"title":@"display_name",
    @"country":@"profile_URL",
    @"purchase_title":@"display_name"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
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
-(void)loadWordPressSiteData:(NSDictionary *)data {
    NSLog(@"loadWordPressSiteData: %@", data);

    NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
    [metadata addEntriesFromDictionary:data];
    [self setValue:metadata forKey:@"metadata"];
    
    NSDictionary *keys = @{
    @"itemCount":@"post_count",
    @"contents":@"description",
    @"purchase_url":@"URL",
    @"purchase_title":@"name" };
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
}
-(void)loadSoundCloudAccountData:(NSDictionary *)data {
    
    [self setValue:data forKey:@"metadata"];
    
    NSDictionary *keys = @{
    @"title":@"full_name",
    @"asset_id":@"id",
    @"uri":@"uri",
    @"username":@"username",
    @"permalink":@"permalink",
    @"playlist_count":@"playlist_count",
    @"track_count":@"track_count",
    @"contents":@"description",
    @"city":@"city",
    @"country":@"country",
    @"purchase_url":@"website",
    @"purchase_title":@"website_title"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
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
    self.sync_mode = [NSNumber numberWithBool:FALSE];

}




@end
