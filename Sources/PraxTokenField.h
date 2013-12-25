//
//  PraxTokenField.h
//  PraxPress
//
//  Created by Elmer on 12/9/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PraxTokenField : NSTokenField

@property NSInteger maxTokens;
@property BOOL existingTokensOnly;

@end
