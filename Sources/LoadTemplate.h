//
//  LoadTemplates.h
//  PraxPress
//
//  Created by John-Elmer on 1/20/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

@import Cocoa;
#import "AssetListViewController.h"

@interface LoadTemplate : NSViewController <NSTableViewDelegate>

@property (unsafe_unretained) IBOutlet AssetListViewController *controller;
@property (weak) IBOutlet NSPopover *popover;

@property (weak) IBOutlet NSArrayController *templatesArrayController;


- (IBAction)loadTemplate:(id)sender;

@end
