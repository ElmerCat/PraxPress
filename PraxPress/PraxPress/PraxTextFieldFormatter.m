//
//  PraxTextFieldFormatter.m
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "PraxTextFieldFormatter.h"

@implementation PraxTextFieldFormatter

- (NSString *)stringForObjectValue:(id)anObject {
    if (anObject) return anObject;
    else return nil;
    
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {

    if ([string length] > self.maxLength) {
        [[NSSound soundNamed:@"Error"] play];
        if (anObject) *anObject = [string substringToIndex:self.maxLength];
    }
    else if (anObject) *anObject = string;

    return TRUE;
}



@end
