//  Copyright (c) 2012 ElmerCat. All rights reserved.

#import <WordPressAPI/WPWordPressAPI.h>


@class WPWordPressAPIAuthentication;


@interface WPWordPressAPI (Private)

@property (nonatomic, readonly) WPWordPressAPIAuthentication *authentication;

@end
