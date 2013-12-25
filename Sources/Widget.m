//
//  Widget.m
//  PraxPress
//
//  Created by Elmer on 12/11/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Widget.h"

@implementation Widget

+ (NSString *)marker {
    return @"$$$";
}

+ (NSString *)newWidgetCompletionString {
    return @"$$title$$$";
}

+ (NSString *)defaultWidgetString {
    return @"$$$title$$$";
}

+ (NSArray *)playerBooleanOptions {
    return @[@"auto_play",
             @"buying",
             @"download",
             @"enable_api",
             @"liking",
             @"sharing",
             @"single_active",
             @"show_artwork",
             @"show_bpm",
             @"show_comments",
             @"show_playcount",
             @"show_user"];
}

+ (NSDictionary *)defaultPlayerBooleanOptions {
    return @{@"auto_play" : @NO,
             @"buying" : @NO,
             @"download" : @NO,
             @"enable_api" : @NO,
             @"liking" : @NO,
             @"sharing" : @NO,
             @"single_active" : @NO,
             @"show_artwork" : @NO,
             @"show_bpm" : @NO,
             @"show_comments" : @NO,
             @"show_playcount" : @NO,
             @"show_user" : @NO};
}

+ (NSArray *)playerStringOptions {
    return @[@"type",
             @"color",
             @"theme"];
}
+ (NSArray *)playerSizeOptions {
    return @[@"width",
             @"track_height",
             @"playlist_height"];
}
+ (NSDictionary *)defaultPlayerStringOptions {
    return @{@"type" : @"HTML5",
             @"color" : @"FF6600",
             @"theme" : @"000000"};
}
+ (NSDictionary *)defaultPlayerSizes {
    return @{@"HTML5" : @{@"width" : @"100%", @"track_height" : @"166", @"playlist_height" : @"400"},
             @"flash" : @{@"width" : @"100%", @"track_height" : @"81", @"playlist_height" : @"400"},
             @"artwork" : @{@"width" : @"300", @"track_height" : @"300", @"playlist_height" : @"300"},
             @"tiny" : @{@"width" : @"100%", @"track_height" : @"19", @"playlist_height" : @"19"}};
}
+ (NSDictionary *)displayStrings {
    return @{
            @" Insert Prax Widget " : @" Insert Prax Widget ",
            @"title" : @"Title",
            @"image" : @"Image",
            @"player" : @"Player",
            @"uri" : @"URI"
            };}

+ (NSString *)displayStringForEditingString:(NSString *)string {
    NSString *keyString = [self keyStringFromEditingString:string];
    if (self.displayStrings[keyString]) return self.displayStrings[keyString];
    else return @"Prax";
}

+ (NSString *)keyStringFromDisplayString:(NSString *)displayString {
    NSArray *keys = [self.displayStrings allKeysForObject:displayString];
    if (keys.count) return keys[0];
    else return @"prax";
}


+ (BOOL)stringContainsWidget:(NSString *)string {
    if (string.length < (([Widget marker].length * 2) + 1)) return NO;
    
    NSRange firstOccurrance = [string rangeOfString:[Widget marker]];
    if (firstOccurrance.length < [Widget marker].length) return NO;
    
    NSRange secondOccurance = [string rangeOfString:[Widget marker] options:nil range:NSMakeRange((firstOccurrance.location + firstOccurrance.length), (string.length - (firstOccurrance.location + firstOccurrance.length)))];
    if (secondOccurance.length < [Widget marker].length) return NO;
    if (secondOccurance.location <= (firstOccurrance.location + firstOccurrance.length)) return NO;
    return YES;
}

+ (NSString *)editingStringFromObject:(id)representedObject {
   if ([[representedObject className] isEqualToString:@"Widget"])
    {
        return [(Widget *)representedObject editingString];
    }
    if ([representedObject respondsToSelector:@selector(count)]) {
        NSMutableString *string = @"".mutableCopy;
        for (id object in representedObject) {
            [string appendString:[self editingStringFromObject:object]];
        }
        return string;
    }
   return representedObject;
}

+ (NSString *)stringWithTemplate:(NSString *)template forAsset:(Asset *)asset wordPress:(BOOL)wordPress {
    
    NSMutableString *string = @"".mutableCopy;
    NSArray *formatArray = [Widget templateFormatArrayFromObject:template];
    for (id object in formatArray) {
        if ([[object className] isEqualToString:@"Widget"]) {
            [string appendString:[(Widget *)object stringForAsset:asset wordPress:wordPress]];
        }
        else if ([object respondsToSelector:@selector(count)]) {
            NSMutableString *sstring = @"".mutableCopy;
            for (id oobject in object) {
                [sstring appendString:[Widget stringWithTemplate:oobject forAsset:asset wordPress:wordPress]];
            }
            [string appendString:sstring];
        }
        else  {
            [string appendString:object];
        }
   }
    return string;
}

- (NSString *)stringForAsset:(Asset *)asset wordPress:(BOOL)wordPress {
    NSMutableString *string = @"".mutableCopy;
    if ([self.keyString isEqualToString:@"image"]) {
        NSString *value = [Widget valueOfItem:asset asStringForKey:@"artwork_url"];
        if (value.length) {
            [string setString:@"<img"];
            NSString *option = [Widget stringValueForOption:@"width" inString:self.optionString];
            if (option && option.length) [string appendFormat:@" width=%@", option];
            option = [Widget stringValueForOption:@"height" inString:self.optionString];
            if (option && option.length) [string appendFormat:@" height=%@", option];
            [string appendString:@" src=\""];
            [string appendString:value];
            if ([[asset accountType] isEqualToString:@"SoundCloud"]) {
                option = [Widget stringValueForOption:@"size" inString:self.optionString];
                if (!option.length) [string appendString:@"-original.jpg"];
                else [string appendFormat:@"-%@.jpg", option];
            }
            [string appendString:@"\">"];
        }
    }
    else if ([self.keyString isEqualToString:@"player"]) {
        if ([[asset accountType] isEqualToString:@"SoundCloud"]) {
            NSString *uri = [Widget valueOfItem:asset asStringForKey:@"uri"];
            NSString *type = [Widget stringValueForOption:@"type" inString:self.optionString];
            if (!type.length) {
                type = [Widget defaultPlayerStringOptions][@"type"];
            }
            NSString *width = [Widget stringValueForOption:@"width" inString:self.optionString];
            if (!width.length) {
                width = [Widget defaultPlayerSizes][type][@"width"];
            }
            NSString *height;
            if ([type isEqualToString:@"artwork"]) {
                height = width;
                if ([self.optionString rangeOfString:@"show_artwork=T" options:NSCaseInsensitiveSearch].length) {
                    width = [[NSNumber numberWithInt:([width intValue] * 2)] stringValue];
                }
            }
            else if ([type isEqualToString:@"tiny"]) height = [Widget defaultPlayerSizes][type][@"track_height"];
            else {
                if ([asset.type isEqualToString:@"track"]) {
                    height = [Widget stringValueForOption:@"track_height" inString:self.optionString];
                    if (!height || !height.length) height = [Widget defaultPlayerSizes][type][@"track_height"];
                }
                else {
                    height = [Widget stringValueForOption:@"playlist_height" inString:self.optionString];
                    if (!height || !height.length) height = [Widget defaultPlayerSizes][type][@"playlist_height"];
                }
            }
            NSString *wordPressFlashPlayer = @"[soundcloud url=\"https://api.soundcloud.com/tracks/$$$uri$$$\" params=\"$$$parameters$$$\" width=\"$$$width$$$\" height=\"$$$height\" iframe=\"false\" /]";

            
            NSString *wordPressHTMLPlayer = @"[soundcloud url=\"$$$uri$$$\" params=\"$$$parameters$$$\" width=\"$$$width$$$\" height=\"$$$height\" iframe=\"true\" /]";
            
            NSString *soundCloudFlashPlayer = @"<object height=\"$$$height$$$\" width=\"$$$width$$$\"><param name=\"movie\" value=\"https://player.soundcloud.com/player.swf?url=$$$uri$$$&amp;$$$parameters$$$\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><param name=\"wmode\" value=\"transparent\"></param><embed wmode=\"transparent\" allowscriptaccess=\"always\" height=\"$$$height$$$\" width=\"$$$width$$$\" src=\"https://player.soundcloud.com/player.swf?url=$$$uri$$$&amp;$$$parameters$$$\"></embed></object>";
            
            NSString *soundCloudHTMLPlayer = @"<iframe width=\"$$$width$$$\" height=\"$$$height$$$\" scrolling=\"no\" frameborder=\"no\" src=\"https://w.soundcloud.com/player/?url=$$$uri$$$&amp;$$$parameters$$$\"></iframe>";
            
            if (wordPress) {
                if ([type isEqualToString:@"HTML5"]) [string setString:wordPressHTMLPlayer];
                else [string setString:wordPressFlashPlayer];
            }
            else {
                if ([type isEqualToString:@"HTML5"]) [string setString:soundCloudHTMLPlayer];
                else [string setString:soundCloudFlashPlayer];
            }
            
            NSMutableString *parameters = @"".mutableCopy;
            NSString *separator;
            if (wordPress) separator = @"&";
            else separator = @"&amp;";
            
            if (type.length) [parameters appendFormat:@"%@player_type=%@", separator, type];
            NSString *value = [Widget stringValueForOption:@"color" inString:self.optionString];
            if (value.length) [parameters appendFormat:@"%@color=%@", separator, value];
            value = [Widget stringValueForOption:@"theme" inString:self.optionString];
            if (value.length) [parameters appendFormat:@"%@theme_color=%@", separator, value];
            
            for (NSString *option in [Widget playerBooleanOptions]) {
                if ([self.optionString rangeOfString:[NSString stringWithFormat:@"%@=T", option] options:NSCaseInsensitiveSearch].length) {
                    [parameters appendFormat:@"%@%@=true", separator, option];
                }
                else { //if ([self.optionString rangeOfString:[NSString stringWithFormat:@"%@=F", option] options:NSCaseInsensitiveSearch].length) {
                    [parameters appendFormat:@"%@%@=false", separator, option];
                }
            }
            NSRange trim = [parameters rangeOfString:separator];
            if (trim.length && (trim.location == 0)) {
                [parameters deleteCharactersInRange:trim];
            }

            [string replaceOccurrencesOfString:@"$$$uri$$$" withString:uri options:nil range:NSMakeRange(0, string.length)];
            [string replaceOccurrencesOfString:@"$$$width$$$" withString:width options:nil range:NSMakeRange(0, string.length)];
            [string replaceOccurrencesOfString:@"$$$height$$$" withString:height options:nil range:NSMakeRange(0, string.length)];
            [string replaceOccurrencesOfString:@"$$$parameters$$$" withString:parameters options:nil range:NSMakeRange(0, string.length)];
        }
    }
    else {
        if ([self.optionString isEqualToString:@"u"]) {
            [string setString:[[Widget valueOfItem:asset asStringForKey:self.keyString] uppercaseString]];
        }
        else if ([self.optionString isEqualToString:@"l"]) {
            [string setString:[[Widget valueOfItem:asset asStringForKey:self.keyString] lowercaseString]];
        }
        else if ([self.optionString isEqualToString:@"c"]) {
            [string setString:[[Widget valueOfItem:asset asStringForKey:self.keyString] capitalizedString]];
        }
        else {
            [string setString:[Widget valueOfItem:asset asStringForKey:self.keyString]];
        }
    }
    return string;
}

+ (NSString *)valueOfItem:(Asset *)item asStringForKey:(NSString *)key {
    NSEntityDescription *entity = [item entity];
    NSDictionary *attributesByName = [entity attributesByName];
    NSAttributeDescription *attribute = attributesByName[key];
    if (!attribute) {
        return @"---No Such Attribute Key---";
    }
    else if ([attribute attributeType] == NSUndefinedAttributeType) {
        return @"---Undefined Attribute Type---";
    }
    else if ([attribute attributeType] == NSStringAttributeType) {
        return [item valueForKey:key];
    }
    else if ([attribute attributeType] < NSDateAttributeType) {
        return [[item valueForKey:key] stringValue];
    }
    // add more "else if" code as desired for other types
    
    else {
        return @"---Unacceptable Attribute Type---";
    }
}


+ (NSArray *)templateFormatArrayFromObject:(id)representedObject {
    if (!representedObject) return @[@""];
    if ([[representedObject className] isEqualToString:@"Widget"])
    {
        return @[representedObject];
    }
    if ([representedObject respondsToSelector:@selector(count)]) {
        NSMutableArray *array = @[].mutableCopy;
        for (id object in representedObject) {
            [array addObjectsFromArray:[self templateFormatArrayFromObject:object]];
        }
        return array;
    }
    NSString *string = representedObject;
    if (![self stringContainsWidget:string]) return @[string];
    NSMutableArray *array = @[].mutableCopy;
    NSRange firstOccurrance = [string rangeOfString:[Widget marker]];
    NSRange secondOccurance = [string rangeOfString:[Widget marker] options:nil range:NSMakeRange((firstOccurrance.location + firstOccurrance.length), (string.length - (firstOccurrance.location + firstOccurrance.length)))];

    if (firstOccurrance.location > 0) {
        [array addObject:[string substringToIndex:firstOccurrance.location]];
    }
    [array addObject:[Widget widgetFromString:[string substringWithRange:NSMakeRange(firstOccurrance.location, ((secondOccurance.location + secondOccurance.length) - firstOccurrance.location))]]];
    if (string.length > (secondOccurance.location + secondOccurance.length)) {
        [array addObjectsFromArray:[self templateFormatArrayFromObject:[string substringFromIndex:(secondOccurance.location + secondOccurance.length)]]];
    }
    return array;
}


+ (Widget *)widgetFromString:(NSString *)string {
    Widget *widget = [[Widget alloc] init];
    NSRange occurrance = [string rangeOfString:[Widget newWidgetCompletionString]];
    if (occurrance.length) {
        widget.editingString = [Widget defaultWidgetString];
    }
    else widget.editingString = string;
    return widget;
}

+ (NSString *)keyStringFromEditingString:(NSString *)editingString {
    NSString *keyString = [editingString stringByReplacingOccurrencesOfString:[Widget marker] withString:@""];
    NSRange firstOccurance = [keyString rangeOfString:@"["];
    if (firstOccurance.length) return [keyString substringToIndex:firstOccurance.location];
    else return keyString;
}

+ (NSString *)optionStringFromEditingString:(NSString *)editingString {
    NSRange firstOccurance = [editingString rangeOfString:@"["];
    if (firstOccurance.length) {
        NSString *optionString = [editingString substringFromIndex:(firstOccurance.location + 1)];
        NSRange secondOccurance = [optionString rangeOfString:@"]"];
        if (secondOccurance.length) return [optionString substringToIndex:secondOccurance.location];
    }
    return @"";
}

+ (NSString *)stringValueForOption:(NSString *)option inString:(NSString *)string {
    
    NSRange location = [string rangeOfString:[NSString stringWithFormat:@"%@=", option] options:NSCaseInsensitiveSearch];
    if (location.length) {
        NSString *value = [string substringFromIndex:(location.location + location.length)];
        NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@" ,"];
        location = [value rangeOfCharacterFromSet:separators options:nil];
        if (location.length) {
            value = [value substringToIndex:location.location];
        }
        return value;
    }
    else return nil;
}

+ (NSSet *)keyPathsForValuesAffectingDisplayString {return [NSSet setWithObject:@"self.editingString"]; }
+ (NSSet *)keyPathsForValuesAffectingKeyString {return [NSSet setWithObject:@"self.editingString"]; }
+ (NSSet *)keyPathsForValuesAffectingOptionString {return [NSSet setWithObject:@"self.editingString"]; }

- (NSString *)displayString {
    return [Widget displayStringForEditingString:self.editingString];
}
- (NSString *)keyString {
    return [Widget keyStringFromEditingString:self.editingString];
}
- (NSString *)optionString {
    return [Widget optionStringFromEditingString:self.editingString];
}

@end
