//
//  NSArray+PraxCategories.m
//  PraxPress
//
//  Created by Elmer on 7/28/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "PraxCategories.h"

@implementation NSArray (PraxCategories)

-(id)firstObjectWithKey:(NSString *)key equalToString:(NSString *)string {
    NSUInteger index = [self indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop) {
        if ([object[key] isEqualToString:string]) {
            return YES;
        }
        else return NO;
    }];
    if (index == NSNotFound) return nil;
    else return self[index];
}

@end


@implementation AlphaColorWell

- (void)activate:(BOOL)exclusive
{
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    [super activate:exclusive];
}

- (void)deactivate
{
    [super deactivate];
    [[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
}

@end