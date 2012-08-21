//  Copyright (c) 2012 ElmerCat. All rights reserved.

#import "WPWordPress.h"

@interface WPWordPress (Private)

+ (WPWordPress *)shared;

#pragma mark Configuration

+ (NSDictionary *)configuration;

#pragma mark Manage Accounts

- (void)requestAccessWithUsername:(NSString *)username password:(NSString *)password;

@end
