//
//  Tag.m
//  PraxPress
//
//  Created by Elmer on 1/16/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Tag.h"
#import "Asset.h"


@implementation Tag

@dynamic isWPCategory;
@dynamic name;
@dynamic slug;

@dynamic assets;
@dynamic categoriesAssets;
@dynamic excludedSources;
@dynamic genreAssets;
@dynamic requiredSources;

+ (NSArray *)arrayFromTagString:(NSString *)string {
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *substring;
    
    while (scanner.scanLocation < string.length) {
        
        // test if the first character is a quote
        unichar character = [string characterAtIndex:scanner.scanLocation];
        if (character == '"') {
            // skip the first quote and scan everything up to the next quote into a substring
            [scanner setScanLocation:(scanner.scanLocation + 1)];
            [scanner scanUpToString:@"\"" intoString:&substring];
            [scanner setScanLocation:(scanner.scanLocation + 1)];  // skip the second quote too
        }
        else {
            // scan everything up to the next space into the substring
            [scanner scanUpToString:@" " intoString:&substring];
        }
        // add the substring to the array
        [array addObject:substring];
        
        //if not at the end, skip the space character before continuing the loop
        if (scanner.scanLocation < string.length) [scanner setScanLocation:(scanner.scanLocation + 1)];
    }
    return array.copy;
}

+ (NSString *)tagStringFromArray:(NSArray *)array {
    
    NSMutableString *string = [[NSMutableString alloc] init];
    
    for (NSString *substring in array) {
        if (string.length > 0) {
            [string appendString:@","];
        }
        [string appendString:substring];
    }
    return string.description;
}



@end
