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

    id transformer;

    transformer = [[PraxImageForStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxImageForStringTransformer"];
    
    transformer = [[PraxArrayNotTracksTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayNotTracksTransformer"];
    
    transformer = [[PraxArrayNotPlaylistsTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayNotPlaylistsTransformer"];
    
    transformer = [[PraxArrayNotSoundCloudTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayNotSoundCloudTransformer"];
    
    transformer = [[PraxArrayNotWordPressTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayNotWordPressTransformer"];

    transformer = [[PraxArrayIsNotPlaylistTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsNotPlaylistTransformer"];
    
    transformer = [[PraxArrayAreWordPressTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayAreWordPressTransformer"];

    transformer = [[PraxArrayIsPlaylistTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxArrayIsPlaylistTransformer"];
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
    
    transformer = [[PraxWidgetStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxWidgetStringTransformer"];
    transformer = [[PraxAssetStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxAssetStringTransformer"];
    transformer = [[PraxAssetGenreTagStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxAssetGenreTagStringTransformer"];
    transformer = [[PraxColorStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxColorStringTransformer"];

    transformer = [[PraxMillisecondsToDurationTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"PraxMillisecondsToDurationTransformer"];

}
@end

@implementation PraxImageForStringTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSImage *)transformedValue:(id)value {

    return [NSImage imageNamed:value];
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


@implementation PraxArrayNotTracksTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 0) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"type"] isEqualToString:@"track"]) {
                    return [NSNumber numberWithBool:YES];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:YES];
}
@end

@implementation PraxArrayNotPlaylistsTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 0) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"type"] isEqualToString:@"playlist"]) {
                    return [NSNumber numberWithBool:YES];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:YES];
}
@end

@implementation PraxArrayNotSoundCloudTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 0) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"AccountType"] isEqualToString:@"SoundCloud"]) {
                    return [NSNumber numberWithBool:YES];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:YES];
}
@end

@implementation PraxArrayNotWordPressTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation { return NO; }
- (NSNumber *)transformedValue:(id)value {
    
    if ([value respondsToSelector: @selector(count)]) {
        if ([value count] > 0) {
            for (Asset *asset in (NSArray *)value) {
                if (![[asset valueForKey:@"AccountType"] isEqualToString:@"WordPress"]) {
                    return [NSNumber numberWithBool:YES];
                }
            }
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:YES];
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

@implementation PraxSourceItemImageTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSImage *)transformedValue:(id)value {
    Source *source = (Source *)value;
    if ([source.name isEqualToString:@"All Items"]) return [[NSBundle mainBundle] imageForResource:@"PraxPress"];
    if ([source.name isEqualToString:@"Tracks"]) return [[NSBundle mainBundle] imageForResource:@"tracks"];
    if ([source.name isEqualToString:@"Playlists"]) return [[NSBundle mainBundle] imageForResource:@"playlists"];
    if ([source.name isEqualToString:@"Posts"]) return [[NSBundle mainBundle] imageForResource:@"WordPress"];
    if ([source.name isEqualToString:@"Pages"]) return [[NSBundle mainBundle] imageForResource:@"WordPress"];
    else return [NSImage imageNamed:source.name];
    return nil;
}

@end

@implementation PraxWidgetStringTransformer

+ (Class)transformedValueClass {
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation { return YES; }
- (NSArray *)transformedValue:(id)value {
    return [Widget templateFormatArrayFromObject:value];
}
- (id)reverseTransformedValue:(id)value {
    return [Widget editingStringFromObject:value];
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

@implementation PraxColorStringTransformer

+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation { return YES; }
- (NSColor *)transformedValue:(id)value {
    NSString *string = (NSString *)value;
    NSColor *color = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (string && string.length)
    {
        NSScanner *scanner = [NSScanner scannerWithString:string];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits
    
    color = [NSColor
              colorWithCalibratedRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
    return color;
    
}
- (id)reverseTransformedValue:(id)value {
    NSColor *color = (NSColor *)value;
    color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    unsigned char redByte = red * 0xff;
    unsigned char greenByte = green * 0xff;
    unsigned char blueByte = blue * 0xff;
    NSString *string = [NSString stringWithFormat:@"%02X%02X%02X", redByte, greenByte, blueByte];
    return string;
}

@end

@implementation PraxAssetGenreTagStringTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation { return NO; }
- (NSString *)transformedValue:(id)value {
    NSSet *tags = (NSSet *)value;
    if (tags.count > 0) {
        Tag *tag = tags.anyObject;
        return tag.name;
    }
    else return @"";
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
    for (Tag *tag in tags) {
        [array addObject:tag];
    }
    return array;
}
- (id)reverseTransformedValue:(id)value {
    NSArray *array = (NSArray *)value;
    NSMutableSet *tags = [[NSMutableSet alloc] init];
    for (id tag in array) {
        if ([[tag className] isEqualToString:@"Tag"]) [tags addObject:tag];
    }
    
    return tags.copy;
}

@end
