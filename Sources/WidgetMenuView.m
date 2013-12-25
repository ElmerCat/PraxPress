//
//  WidgetMenuView.m
//  PraxPress
//
//  Created by Elmer on 12/11/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "WidgetMenuView.h"

@implementation WidgetMenuView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (!self.isHidden) {
        [super drawRect:dirtyRect];
    }
	
    // Drawing code here.
}

- (void)menuWillOpen:(NSMenu *)menu {
    
    NSMenuItem *item = [menu itemAtIndex:0];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.widgetViewController showWidgetViewPopover:self];
    });
    
}

@end
