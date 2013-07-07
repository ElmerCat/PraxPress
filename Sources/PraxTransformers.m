//
//  PraxTransformers.m
//  PraxPress
//
//  Created by John Canfield on 8/18/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "PraxTransformers.h"

@implementation PraxTransformers

+(void)loadForDocument:(Document *)document {
    
    id transformer = [[PraxNumberIsZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxPredicateToStringTransformer"];
    transformer = [[PraxNumberIsNotZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxNumberIsNotZeroTransformer"];
    transformer = [[PraxNumberIsNotZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxNumberIsNotZeroTransformer"];
    transformer = [[PraxAssetStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxAssetStringTransformer"];
    
    PraxAssetTagStringTransformer *patsTransformer = [[PraxAssetTagStringTransformer alloc] init];
    patsTransformer.document = document;
    [NSValueTransformer setValueTransformer:patsTransformer forName:@"PraxAssetTagStringTransformer"];
    
}

@end

@implementation PraxPredicateToStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSString *)transformedValue:(id)value {
    
    return [(NSPredicate*)value description];
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

@implementation PraxNumberIsGreaterThanOneTransformer

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
    if (number > 1.0f) {
        return [NSNumber numberWithBool:YES];
    }
    else {
        return [NSNumber numberWithBool:NO];
        
    }
}
@end

@implementation PraxIsSelectedImageTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSImage *)transformedValue:(id)value {
    if (([value respondsToSelector: @selector(boolValue)]) && ([value boolValue]))
        return [[NSBundle mainBundle] imageForResource:@"isSelectedImage"];
    else return [[NSBundle mainBundle] imageForResource:@"isNotSelectedImage"];
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

@implementation PraxAssetTagStringTransformer

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"PraxAssetTagStringTransformer init");
    }
    return self;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation { return YES; }
- (NSString *)transformedValue:(id)value {
    NSSet *tags = (NSSet *)value;
    NSMutableString *string = [[NSMutableString alloc] init];
    for (Tag *tag in tags) {
        if (string.length > 0) [string appendString:@","];
        [string appendString:tag.name];
    }
    return string;
}
- (id)reverseTransformedValue:(id)value {
    NSArray *array = (NSArray *)value;
    NSError *error;
    Tag *tag;
    NSMutableSet *tags = [[NSMutableSet alloc] init];
    
    for (NSString *string in array) {
        NSLog(@"%@", string);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", string]];
        NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
        if ([matchingItems count] < 1) {
            tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
            tag.name = string;
            
        }
        else tag = matchingItems[0];
        [tags addObject:tag];
    }
    
    return tags.copy;
}

@end
