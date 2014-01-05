//
//  Widget.h
//  PraxPress
//
//  Created by Elmer on 12/11/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Asset.h"

@class Asset;

@interface Widget : NSObject

+ (NSString *)marker;
+ (NSArray *)playerBooleanOptions;
+ (NSDictionary *)defaultPlayerBooleanOptions;
+ (NSArray *)playerStringOptions;
+ (NSArray *)playerSizeOptions;
+ (NSDictionary *)defaultPlayerStringOptions;
+ (NSDictionary *)defaultPlayerSizes;
+ (NSString *)stringValueForOption:(NSString *)option inString:(NSString *)string;

+ (NSString *)newWidgetCompletionString;
+ (BOOL)stringContainsWidget:(NSString *)string;
+ (NSString *)editingStringFromObject:(id)representedObject;
+ (NSArray *)templateFormatArrayFromObject:(id)representedObject;
+ (Widget *)widgetFromString:(NSString *)string;
+ (NSString *)displayStringForEditingString:(NSString *)string;
+ (NSString *)keyStringFromEditingString:(NSString *)editingString;
+ (NSString *)keyStringFromDisplayString:(NSString *)displayString;
+ (NSString *)optionStringFromEditingString:(NSString *)editingString;
+ (NSString *)stringWithTemplate:(NSString *)template forAsset:(Asset *)asset wordPress:(BOOL)wordPress;

@property NSString *editingString;
@property (readonly) NSString *displayString;
@property (readonly) NSString *keyString;
@property (readonly) NSString *optionString;


@end
