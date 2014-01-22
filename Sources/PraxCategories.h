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

@interface NSArrayController (PraxCategories)
-(BOOL)isSelectedItemStringValue:(NSString *)string uniqueForKey:(NSString *)key;
@end

@interface NSManagedObject (PraxCategories)
+ (id)entity:(NSString *)entity withKey:(NSString *)key matchingStringValue:(NSString *)stringValue inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface AlphaColorWell : NSColorWell
@end

@interface NSMenu (secret)
- (void) _setHasPadding: (BOOL) pad onEdge: (int) whatEdge;
@end
