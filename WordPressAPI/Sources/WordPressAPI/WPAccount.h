//  Copyright (c) 2012 ElmerCat. All rights reserved.

#import <Foundation/Foundation.h>

#pragma mark Notifications

extern NSString * const WPAccountDidFailToGetAccessToken;

@class NXOAuth2Account;

@interface WPAccount : NSObject {
@private
    NXOAuth2Account *oauthAccount;
}

#pragma mark Accessors

@property (nonatomic, readonly) NSString *identifier;

@end
