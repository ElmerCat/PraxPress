//  Copyright (c) 2012 ElmerCat. All rights reserved.

#import <Foundation/Foundation.h>

#import "WPAccount.h"

#pragma mark Notifications

extern NSString * const WPAccountDidChangeUserInfoNotification;

#pragma mark -

@interface WPAccount (Private)

@property (nonatomic, readonly) NXOAuth2Account *oauthAccount;
@property (nonatomic, copy) NSDictionary *userInfo;
- (id)initWithOAuthAccount:(NXOAuth2Account *)account;

@end
