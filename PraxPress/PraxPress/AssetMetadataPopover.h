//
//  AssetMetadataPopover.h
//  PraxPress
//
//  Created by Elmer on 1/13/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AssetMetadataPopover : NSViewController

@property (weak) IBOutlet NSPopover *popover;
@property (strong) IBOutlet NSDictionaryController *dictionaryController;
- (void)showPopoverRelativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge withDictionary:(NSDictionary *)dictionary;

@end
