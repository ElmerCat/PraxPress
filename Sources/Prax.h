//
//  Prax.h
//  PraxPress
//
//  Created by Elmer on 12/29/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Prax : NSObject


+ (void)presentAlert:(NSString *)text forController:(id)controller;
+ (NSInteger)confirmAlert:(NSString *)title withText:(NSString *)text andInformativeText:(NSString *)informativeText forController:(id)controller;

@end
