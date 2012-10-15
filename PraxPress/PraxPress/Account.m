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


-(void)loadWordPressSiteData:(NSDictionary *)data {
    NSLog(@"loadWordPressSiteData: %@", data);
    
    NSDictionary *keys = @{
    @"track_count":@"post_count",
    @"title":@"description"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
}

-(void)loadWordPressPageCount:(NSDictionary *)data {
    NSLog(@"loadWordPressPageCount: %@", data);
    
    self.playlist_count = data[@"found"];
    int posts = [self.track_count intValue];
    int pages = [self.playlist_count intValue];
    posts -= pages;
    self.track_count = [NSNumber numberWithInt:posts];
}


-(void)loadWordPressAccountData:(NSDictionary *)data {
    NSLog(@"loadWordPressAccountData: %@", data);
    
    NSDictionary *keys = @{
    @"user_id":@"ID",
    @"asset_id":@"primary_blog",
    @"title":@"description",
    @"username":@"display_name",
    @"permalink":@"username"};
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
-(void)loadSoundCloudAccountData:(NSDictionary *)data {
    
    NSDictionary *keys = @{
    @"title":@"full_name",
    @"asset_id":@"id",
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
}




@end
