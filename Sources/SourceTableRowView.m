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

/*- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    
    
    NSColor *backgroundColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.5];
    
    Source *source = [[self viewAtColumn:0] objectValue];
    if (source.parent) {
        
        NSDictionary *accountSettings = [(Document *)self.window.delegate settingsForAccount:source.name];
        if (!accountSettings) {
            Source *parent = source.parent;
            while (parent) {
                accountSettings = [(Document *)self.window.delegate settingsForAccount:parent.name];
                if (accountSettings) break;
                parent = parent.parent;
            }
        }
        if (accountSettings) {
            NSData *data;
            data = accountSettings[@"sourceListRowBackgroundColor"];
            if (data) {
                backgroundColor = [NSUnarchiver unarchiveObjectWithData:data];
            }
        }
        
        [backgroundColor set];
        NSRect bounds = self.bounds;
        bounds.origin.x += 18;
        bounds.size.width -=18;
        const NSRect *rects = NULL;
        NSInteger count = 0;
        [self getRectsBeingDrawn:&rects count:&count];
        for (NSInteger i = 0; i < count; i++) {
            NSRect rect = NSIntersectionRect(bounds, rects[i]);
            NSRectFillUsingOperation(rect, NSCompositeSourceOver);
        }
    }
}
*/

/*- (void)drawSelectionInRect:(NSRect)dirtyRect {
    
    
    NSColor *primaryColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:1.0];
    NSColor *secondarySelectedControlColor = [[NSColor secondarySelectedControlColor] colorWithAlphaComponent:1.0];

    Source *source = [[self viewAtColumn:0] objectValue];
    NSDictionary *accountSettings = [(Document *)self.window.delegate settingsForAccount:source.name];
    if (!accountSettings) {
        Source *parent = source.parent;
        while (parent) {
            accountSettings = [(Document *)self.window.delegate settingsForAccount:parent.name];
            if (accountSettings) break;
            parent = parent.parent;
        }
    }
    
    if (accountSettings) {
        NSData *data;
        data = accountSettings[@"sourceListRowPrimaryColor"];
        if (data) {
            primaryColor = [NSUnarchiver unarchiveObjectWithData:data];
        }
        data = accountSettings[@"sourceListRowSecondaryColor"];
        if (data) {
            secondarySelectedControlColor = [NSUnarchiver unarchiveObjectWithData:data];
        }
    }
    
 
    switch (self.selectionHighlightStyle) {
        case NSTableViewSelectionHighlightStyleSourceList: {
            if (self.selected) {
                if (self.emphasized) {
                    [primaryColor set];
                } else {
                    [secondarySelectedControlColor set];
                }
                NSRect bounds = self.bounds;
                bounds.origin.x += 15;
                bounds.size.width -=25;
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
}*/

@end
