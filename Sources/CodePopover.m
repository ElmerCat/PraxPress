//
//  CodePopover.m
//  PraxPress
//
//  Created by Elmer on 12/24/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "CodePopover.h"

@interface CodePopover ()

@end

@implementation CodePopover

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction)showCodePopover:(id)sender {
    [self.popover showRelativeToRect:self.relativeView.bounds ofView:self.relativeView preferredEdge:NSMinXEdge];
}

@end
