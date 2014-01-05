//
//  PraxTableView.m
//  PraxPress
//
//  Created by John-Elmer on 1/3/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import "PraxTableView.h"

@implementation PraxTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}


- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            return (NSDragOperationCopy + NSDragOperationMove);
            break;
    }
}

@end
