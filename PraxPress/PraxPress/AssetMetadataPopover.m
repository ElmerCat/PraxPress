//
//  AssetMetadataPopover.m
//  PraxPress
//
//  Created by Elmer on 1/13/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetMetadataPopover.h"

@interface AssetMetadataPopover ()

@end

@implementation AssetMetadataPopover

- (void)showPopoverRelativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge withDictionary:(NSDictionary *)dictionary {
    [self.popover showRelativeToRect:rect ofView:view preferredEdge:preferredEdge];
    [self.dictionaryController setContent:dictionary];
    
}


@end
