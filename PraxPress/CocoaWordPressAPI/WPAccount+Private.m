//  Copyright (c) 2012 ElmerCat. All rights reserved.

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#endif

#import "WPWordPress.h"
#import "WPRequest.h"
#import "WPConstants.h"

#import "WPAccount+Private.h"

#pragma mark Notifications

NSString * const WPAccountDidChangeUserInfo = @"WPAccountDidChangeUserInfo";

#pragma mark -

@implementation WPAccount (Private)

- (id)initWithOAuthAccount:(NXOAuth2Account *)anAccount;
{
    self = [super init];
    if (self) {
        oauthAccount = anAccount;
    }
    return self;
}

- (NXOAuth2Account *)oauthAccount;
{
    return oauthAccount;
}

- (void)setOauthAccount:(NXOAuth2Account *)anOAuthAccount;
{
    oauthAccount = anOAuthAccount;
}

- (NSDictionary *)userInfo;
{
    return (NSDictionary *)self.oauthAccount.userData;
}

- (void)setUserInfo:(NSDictionary *)userInfo;
{
    self.oauthAccount.userData = userInfo;
}

@end
