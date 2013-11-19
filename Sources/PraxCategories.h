//
//  NSArray+PraxCategories.h
//  PraxPress
//
//  Created by Elmer on 7/28/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Asset.h"

@interface NSArray (PraxCategories)

- (id)firstObjectWithKey:(NSString *)key equalToString:(NSString *)string;
- (NSString *)praxPressListType;
@end


@interface AlphaColorWell : NSColorWell

@end

