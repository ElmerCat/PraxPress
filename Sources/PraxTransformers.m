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
    
    id transformer = [[PraxArrayIsPlaylistTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsPlaylistTransformer"];
    transformer = [[PraxArrayIsNotPlaylistTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsNotPlaylistTransformer"];
    transformer = [[PraxArrayArePlaylistsTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayArePlaylistsTransformer"];
    transformer = [[PraxArrayIsTrackTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsTrackTransformer"];
    transformer = [[PraxArrayIsNotTrackTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsNotTrackTransformer"];
    transformer = [[PraxArrayAreTracksTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayAreTracksTransformer"];
    transformer = [[PraxArrayAreSoundCloudTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayAreSoundCloudTransformer"];
    transformer = [[PraxArrayAreWordPressTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayAreWordPressTransformer"];
    transformer = [[PraxArrayAreDifferentTypes alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayAreDifferentTypes"];
    transformer = [[PraxArrayAreDifferentAccountTypes alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayAreDifferentAccountTypes"];
    transformer = [[PraxArrayIsPostTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsPostTransformer"];
    transformer = [[PraxArrayIsPageTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsPageTransformer"];

    transformer = [[PraxNumberIsZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxPredicateToStringTransformer"];
    transformer = [[PraxNumberIsNotZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxNumberIsNotZeroTransformer"];
    transformer = [[PraxNumberIsNotZeroTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxNumberIsNotZeroTransformer"];
    transformer = [[PraxAssetStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxAssetStringTransformer"];

    transformer = [[PraxMillisecondsToDurationTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxMillisecondsToDurationTransformer"];

}

@end

@implementation PraxMillisecondsToDurationTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSString *)transformedValue:(id)value {
    
    if ([value respondsToSelector: @selector(intValue)]) {
        int milliseconds = [value intValue];
        int msecs = (milliseconds % 1000);
        int secs = (milliseconds / 1000);
        if (secs < 60) {
            return [NSString stringWithFormat:@"%d.%03d", secs, msecs];
        }

        else {
            
        }
        int hours = floor(milliseconds / 3600000);
        int mins = floor((milliseconds % 3600000) / (1000 * 60));
        secs = floor(((milliseconds % 3600000) % (1000 * 60)) / 1000);
        return [NSString stringWithFormat:@"%d:%02d:%02d", hours, mins, secs];
    }
    else return nil;
}

@end

@implementation PraxArrayIsPlaylistTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] == 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            if ([[asset valueForKey:@"type"] isEqualToString:@"playlist"]) {
                return [NSNumber numberWithBool:YES];
            }
        }
    }
    return [NSNumber numberWithBool:NO];
}

@end

@implementation PraxArrayIsNotPlaylistTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] == 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            if ([[asset valueForKey:@"type"] isEqualToString:@"playlist"]) {
                return [NSNumber numberWithBool:NO];
            }
        }
    }
    return [NSNumber numberWithBool:YES];
}

@end

@implementation PraxArrayIsTrackTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] == 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            if ([[asset valueForKey:@"type"] isEqualToString:@"track"]) {
                return [NSNumber numberWithBool:YES];
            }
        }
    }
    return [NSNumber numberWithBool:NO];
}
@end

@implementation PraxArrayIsNotTrackTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] == 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            if ([[asset valueForKey:@"type"] isEqualToString:@"track"]) {
                return [NSNumber numberWithBool:NO];
            }
        }
    }
    return [NSNumber numberWithBool:YES];
}
@end

@implementation PraxArrayIsPostTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] == 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            if ([[asset valueForKey:@"type"] isEqualToString:@"post"]) {
                return [NSNumber numberWithBool:YES];
            }
        }
    }
    return [NSNumber numberWithBool:NO];
}
@end

@implementation PraxArrayIsPageTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] == 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            if ([[asset valueForKey:@"type"] isEqualToString:@"page"]) {
                return [NSNumber numberWithBool:YES];
            }
        }
    }
    return [NSNumber numberWithBool:NO];
}
@end

@implementation PraxArrayArePlaylistsTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 1) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"type"] isEqualToString:@"playlist"]) {
                    return [NSNumber numberWithBool:NO];
                }
            }
            return [NSNumber numberWithBool:YES];
        }
    }
    return [NSNumber numberWithBool:NO];
}

@end

@implementation PraxArrayAreTracksTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 1) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"type"] isEqualToString:@"track"]) {
                    return [NSNumber numberWithBool:NO];
                }
            }
            return [NSNumber numberWithBool:YES];
        }
    }
    return [NSNumber numberWithBool:NO];
}

@end

@implementation PraxArrayAreSoundCloudTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 1) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"AccountType"] isEqualToString:@"SoundCloud"]) {
                    return [NSNumber numberWithBool:NO];
                }
            }
            return [NSNumber numberWithBool:YES];
        }
    }
    return [NSNumber numberWithBool:NO];
}
@end

@implementation PraxArrayAreWordPressTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 1) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"AccountType"] isEqualToString:@"WordPress"]) {
                    return [NSNumber numberWithBool:NO];
                }
            }
            return [NSNumber numberWithBool:YES];
        }
    }
    return [NSNumber numberWithBool:NO];
}
@end

@implementation PraxArrayAreDifferentTypes
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        NSInteger count = [value count];
        if ([value count] > 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            NSString *string = asset.type;
            while (count > 1) {
                count--;
                asset = [(NSArray *)value objectAtIndex:count];
                if (![[asset valueForKey:@"type"] isEqualToString:string]) {
                    return [NSNumber numberWithBool:YES];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:NO];
}
@end

@implementation PraxArrayAreDifferentAccountTypes
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    if (value == nil) return nil;
    if ([value respondsToSelector: @selector(count)]) {
        NSInteger count = [value count];
        if ([value count] > 1) {
            Asset *asset = [(NSArray *)value objectAtIndex:0];
            NSString *string = asset.accountType;
            while (count > 1) {
                count--;
                asset = [(NSArray *)value objectAtIndex:count];
                if (![[asset valueForKey:@"accountType"] isEqualToString:string]) {
                    return [NSNumber numberWithBool:YES];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:NO];
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

@implementation PraxNumberIsOneTransformer

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
    if (number == 1.0f) {
        return [NSNumber numberWithBool:YES];
    }
    else {
        return [NSNumber numberWithBool:NO];
        
    }
}
@end

@implementation PraxNumberIsNotOneTransformer

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
    if (number == 1.0f) {
        return [NSNumber numberWithBool:NO];
    }
    else {
        return [NSNumber numberWithBool:YES];
        
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
+(PraxAssetTagStringTransformer *)loadForDocument:(Document *)document {
    PraxAssetTagStringTransformer *patsTransformer = [[PraxAssetTagStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:patsTransformer forName:@"PraxAssetTagStringTransformer"];
    patsTransformer.document = document;
    return patsTransformer;
}

+ (Class)transformedValueClass {
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation { return YES; }
- (NSArray *)transformedValue:(id)value {
    NSSet *tags = (NSSet *)value;
    NSMutableArray *array = [@[] mutableCopy];

//    NSMutableString *string = [[NSMutableString alloc] init];
    for (Tag *tag in tags) {
        [array addObject:tag];
//        if (string.length > 0) [string appendString:@","];
  //      [string appendString:tag.name];
    }
    return array;
}
- (id)reverseTransformedValue:(id)value {
    NSArray *array = (NSArray *)value;
    NSMutableSet *tags = [[NSMutableSet alloc] init];
    
    for (Tag *tag in array) {
/*        NSLog(@"%@", string);
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", string]];
        NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
        if ([matchingItems count] < 1) {
            tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
            tag.name = string;
            
        }
        else tag = matchingItems[0];*/
        [tags addObject:tag];
    }
    
    return tags.copy;
}

@end
