/*
 * Copyright 2010, 2011 nxtbgthng for WordPress Ltd.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 *
 * For more information and documentation refer to
 * http://soundcloud.com/api
 * 
 */

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#endif

#import "WPAccount.h"
#import "WPAccount+Private.h"
#import "WPRequest.h"
#import "WPConstants.h"

#import "WPWordPress+Private.h"
#import "WPWordPress.h"


#pragma mark Notifications

NSString * const WPWordPressAccountsDidChangeNotification = @"WPWordPressAccountsDidChangeNotification";
NSString * const WPWordPressAccountDidChangeNotification = @"WPWordPressAccountDidChangeNotification";
NSString * const WPWordPressDidFailToRequestAccessNotification = @"WPWordPressDidFailToRequestAccessNotification";

#pragma mark -


@interface WPWordPress ()

#pragma mark Notification Observer
- (void)accountStoreAccountsDidChange:(NSNotification *)aNotification;
- (void)accountStoreDidFailToRequestAccess:(NSNotification *)aNotification;
- (void)accountDidFailToGetAccessToken:(NSNotification *)aNotification;
@end

@implementation WPWordPress

+ (void)initialize;
{
    [WPWordPress shared];
}

- (id)init;
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountStoreAccountsDidChange:)
                                                     name:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountStoreDidFailToRequestAccess:)
                                                     name:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountDidFailToGetAccessToken:)
                                                     name:NXOAuth2AccountDidFailToGetAccessTokenNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Accessors

+ (WPAccount *)account;
{    
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kWPAccountType];
    if ([oauthAccounts count] > 0) {
        return [[WPAccount alloc] initWithOAuthAccount:[oauthAccounts objectAtIndex:0]];
    } else {
        return nil;
    }
}


#pragma mark Manage Accounts

+ (void)requestAccessWithPreparedAuthorizationURLHandler:(WPPreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
{
    [self removeAccess];
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:kWPAccountType
                                   withPreparedAuthorizationURLHandler:(WPPreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler];
}

+ (void)removeAccess;
{
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:kWPAccountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];        
    }
}


#pragma mark Configuration

+ (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
        redirectURL:(NSURL *)aRedirectURL;
{
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    
    [config setObject:aClientID forKey:kNXOAuth2AccountStoreConfigurationClientID];
    [config setObject:aSecret forKey:kNXOAuth2AccountStoreConfigurationSecret];
    [config setObject:aRedirectURL forKey:kNXOAuth2AccountStoreConfigurationRedirectURL];

    [config setObject:[NSURL URLWithString:kWPWordPressAuthURL] forKey:kNXOAuth2AccountStoreConfigurationAuthorizeURL];
    [config setObject:[NSURL URLWithString:kWPWordPressAccessTokenURL] forKey:kNXOAuth2AccountStoreConfigurationTokenURL];
    [config setObject:[NSURL URLWithString:kWPWordPressAPIURL] forKey:kWPConfigurationAPIURL];
    
    [[NXOAuth2AccountStore sharedStore] setConfiguration:config forAccountType:kWPAccountType];
}


#pragma mark OAuth2 Flow

+ (BOOL)handleRedirectURL:(NSURL *)URL;
{
    return [[NXOAuth2AccountStore sharedStore] handleRedirectURL:URL];
}

#pragma mark Notification Observer

- (void)accountStoreAccountsDidChange:(NSNotification *)aNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WPWordPressAccountDidChangeNotification
                                                        object:self];
}

- (void)accountStoreDidFailToRequestAccess:(NSNotification *)aNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WPWordPressDidFailToRequestAccessNotification
                                                        object:self
                                                      userInfo:aNotification.userInfo];
}

- (void)accountDidFailToGetAccessToken:(NSNotification *)aNotification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDidFailToGetAccessToken
                                                        object:aNotification.object];
}

@end
