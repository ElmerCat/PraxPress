//  Copyright (c) 2012 ElmerCat. All rights reserved.

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#import <Cocoa/Cocoa.h>
#endif

#import "WPConstants.h"

#import "WPWordPress+Private.h"


@implementation WPWordPress (Private)

+ (id)shared;
{
    static WPWordPress *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [WPWordPress new];
    });
    return shared;
}

#pragma mark Configuration


+ (NSDictionary *)configuration;
{
    NSDictionary *configuration = [[NXOAuth2AccountStore sharedStore] configurationForAccountType:kWPAccountType];
    
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    
    [config setObject:[configuration objectForKey:kNXOAuth2AccountStoreConfigurationClientID] forKey:kWPConfigurationClientID];
    [config setObject:[configuration objectForKey:kNXOAuth2AccountStoreConfigurationSecret] forKey:kWPConfigurationSecret];
    [config setObject:[configuration objectForKey:kNXOAuth2AccountStoreConfigurationRedirectURL] forKey:kWPConfigurationRedirectURL];
    
    [config setObject:[configuration objectForKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL] forKey:kWPConfigurationAuthorizeURL];
    
    
    [config setObject:[configuration objectForKey:kWPConfigurationAPIURL] forKey:kWPConfigurationAPIURL];
    
    return config;
}

#pragma mark Manage Accounts


- (void)requestAccessWithUsername:(NSString *)username password:(NSString *)password;
{
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:kWPAccountType username:username password:password];
}

@end
