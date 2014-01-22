//
//  SaveTemplate.h
//  PraxPress
//
//  Created by John-Elmer on 1/20/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@import Cocoa;
#import "AssetListViewController.h"

@interface SaveTemplate : NSViewController <NSTableViewDelegate>
@property BOOL awake;

@property NSString *templateName;
@property BOOL canSave;
@property BOOL canReplace;

@property (unsafe_unretained) IBOutlet AssetListViewController *controller;
@property (weak) IBOutlet NSPopover *popover;


@property (weak) IBOutlet NSArrayController *templatesArrayController;


- (IBAction)saveTemplate:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)replace:(id)sender;

@end
