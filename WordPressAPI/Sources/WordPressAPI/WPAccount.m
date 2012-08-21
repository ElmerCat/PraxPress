//  Copyright (c) 2012 ElmerCat. All rights reserved.

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#endif

#import "WPAccount+Private.h"
#import "WPAccount.h"

#pragma mark Notifications

NSString * const WPAccountDidFailToGetAccessToken = @"WPAccountDidFailToGetAccessToken";

#pragma mark -

@implementation WPAccount

- (void)dealloc;
{

}

#pragma mark Accessors

- (NSString *)identifier;
{
    return self.oauthAccount.identifier;
}

@end
