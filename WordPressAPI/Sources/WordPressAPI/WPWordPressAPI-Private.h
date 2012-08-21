//
//  WPWordPressAPI-Private.h
//  WordPressAPI
//
//  Created by Ullrich Schäfer on 05.01.11.
//  Copyright 2011 nxtbgthng. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "WPWordPressAPI.h"
#else
#import <WordPressAPI/WPWordPressAPI.h>
#endif


@class WPWordPressAPIAuthentication;


@interface WPWordPressAPI (Private)

@property (nonatomic, readonly) WPWordPressAPIAuthentication *authentication;

@end
