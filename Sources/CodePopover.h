//
//  CodePopover.h
//  PraxPress
//
//  Created by Elmer on 12/24/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CodePopover : NSViewController

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSView *relativeView;

- (IBAction)showCodePopover:(id)sender;

@end
