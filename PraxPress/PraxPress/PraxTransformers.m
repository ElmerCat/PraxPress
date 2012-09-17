//
//  PraxTransformers.m
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "PraxTransformers.h"

@implementation PraxTransformers

+(void)load {

    id transformer = [[PraxNumberIsZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxNumberIsZeroTransformer"];
    transformer = [[PraxNumberIsNotZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxNumberIsNotZeroTransformer"];
    transformer = [[PraxAssetStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxAssetStringTransformer"];
    
}

@end

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

@implementation PraxAssetStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSString *)transformedValue:(id)value {
    Asset *asset = (Asset *)value;
    
    return asset.type;
}

@end
