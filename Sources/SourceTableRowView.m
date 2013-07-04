//
//  SourceTableRowView.m
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "SourceTableRowView.h"

@implementation SourceTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    NSColor *primaryColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.5];
    NSColor *secondarySelectedControlColor = [[NSColor secondarySelectedControlColor] colorWithAlphaComponent:0.5];
    
    // Implement our own custom alpha drawing
    switch (self.selectionHighlightStyle) {
        case NSTableViewSelectionHighlightStyleSourceList: {
            if (self.selected) {
                if (self.emphasized) {
                    [primaryColor set];
                } else {
                    [secondarySelectedControlColor set];
                }
                NSRect bounds = self.bounds;
                const NSRect *rects = NULL;
                NSInteger count = 0;
                [self getRectsBeingDrawn:&rects count:&count];
                for (NSInteger i = 0; i < count; i++) {
                    NSRect rect = NSIntersectionRect(bounds, rects[i]);
                    NSRectFillUsingOperation(rect, NSCompositeSourceOver);
                }
            }
            break;
        }
        default: {
            // Do super's drawing
            [super drawSelectionInRect:dirtyRect];
            break;
        }
    }
}

@end
