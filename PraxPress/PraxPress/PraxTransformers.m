//
//  PraxTransformers.m
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "PraxTransformers.h"

@implementation PraxNumberIsZeroTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    float number = 0;
    
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(floatValue)]) {
        number = [value floatValue];
    }
    if (number == 0.0f) {
        return [NSNumber numberWithBool:YES];
    }
    else {
        return [NSNumber numberWithBool:NO];
        
    }
}
@end

@implementation PraxNumberIsNotZeroTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    float number = 0;
    
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(floatValue)]) {
        number = [value floatValue];
    }
    if (number != 0.0f) {
        return [NSNumber numberWithBool:YES];
    }
    else {
        return [NSNumber numberWithBool:NO];
        
    }
}
@end
