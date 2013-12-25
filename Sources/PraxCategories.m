//
//  NSArray+PraxCategories.m
//  PraxPress
//
//  Created by Elmer on 7/28/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "PraxCategories.h"

@implementation NSArray (PraxCategories)

- (id)firstObjectWithKey:(NSString *)key equalToString:(NSString *)string {
    NSUInteger index = [self indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL *stop) {
        if ([object[key] isEqualToString:string]) {
            return YES;
        }
        else return NO;
    }];
    if (index == NSNotFound) return nil;
    else return self[index];
}
- (NSString *)praxPressListType {
    NSInteger count = self.count;

    if (count < 1) {
        return @"no-selection";
    }
    else if (count == 1) {
        Asset *asset = self[0];
        return asset.type;
    }
    else {
        Asset *asset = self[0];
        NSString *type = asset.type;
        NSString *accountType = asset.accountType;
        
        while (count > 1) {
            count--;
            asset = self[count];
            if (![[asset valueForKey:@"type"] isEqualToString:type]) {

                while (count > 0) {
                    asset = self[count];
                    if (![[asset valueForKey:@"accountType"] isEqualToString:accountType]) {
                        return @"default";
                    }
                    count--;
                }
                return accountType;
            }
        }
        return [NSString stringWithFormat:@"%@s", type];
    }
}

@end

@implementation NSManagedObject (PraxCategories)

+ (id)entity:(NSString *)entity withKey:(NSString *)key matchingStringValue:(NSString *)stringValue inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", key, stringValue]];
    NSArray *matchingItems = [managedObjectContext executeFetchRequest:request error:nil];
    if ([matchingItems count] > 0) return matchingItems[0];
    else return nil;
    
}


@end




@implementation AlphaColorWell

- (void)activate:(BOOL)exclusive
{
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
    [super activate:exclusive];
}

- (void)deactivate
{
    [super deactivate];
    [[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
}

@end