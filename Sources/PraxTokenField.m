//
//  PraxTokenField.m
//  PraxPress
//
//  Created by Elmer on 12/9/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "PraxTokenField.h"

@implementation PraxTokenField

- (BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder])
    {
        // If super became first responder, we can get the
        // field editor and manipulate its selection directly
        NSText * fieldEditor = [[self window] fieldEditor:YES forObject:self];
        [fieldEditor setSelectedRange:NSMakeRange([[fieldEditor string] length], 0)];
        return YES;
    }
    return NO;
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    [super textDidEndEditing:aNotification];
    NSText * fieldEditor = [[self window] fieldEditor:YES forObject:self];
    [fieldEditor setSelectedRange:NSMakeRange([[fieldEditor string] length], 0)];
}

@end
