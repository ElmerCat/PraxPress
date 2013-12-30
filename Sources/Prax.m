//
//  Prax.m
//  PraxPress
//
//  Created by Elmer on 12/29/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Prax.h"

@implementation Prax

+ (void)presentAlert:(NSString *)text forController:(id)controller {
    [[NSSound soundNamed:@"Error"] play];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:text];
    [alert runModal];
}

+ (NSInteger)confirmAlert:(NSString *)title withText:(NSString *)text andInformativeText:(NSString *)informativeText forController:(id)controller {
    [[NSSound soundNamed:@"Error"] play];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:text];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:title];
    return [alert runModal];
}


@end
