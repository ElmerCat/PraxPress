//  Copyright (c) 2012 ElmerCat. All rights reserved.

#import <Foundation/Foundation.h>

#pragma mark Notifications

extern NSString * const WPWordPressAccountDidChangeNotification;
extern NSString * const WPWordPressDidFailToRequestAccessNotification;


#pragma mark Handler

typedef void(^WPPreparedAuthorizationURLHandler)(NSURL *preparedURL);


#pragma mark -

@class WPAccount;

@interface WPWordPress : NSObject

#pragma mark Accessors

+ (WPAccount *)account;


#pragma mark Manage Accounts

+ (void)requestAccessWithPreparedAuthorizationURLHandler:(WPPreparedAuthorizationURLHandler)aPreparedAuthorizationURLHandler;
+ (void)removeAccess;


#pragma mark Configuration

+ (void)setClientID:(NSString *)aClientID
             secret:(NSString *)aSecret
        redirectURL:(NSURL *)aRedirectURL;

#pragma mark OAuth2 Flow

+ (BOOL)handleRedirectURL:(NSURL *)URL;

@end
