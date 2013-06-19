//
//  NewPlaylistPopover.h
//  PraxPress
//
//  Created by Elmer on 1/19/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Asset.h"
#import "Document.h"

@interface NewPlaylistPopover : NSViewController

@property BOOL awake;
@property (weak) IBOutlet Document *filesOwner;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSArrayController *batchAssetsController;

@property Asset *asset;
- (IBAction)save:(id)sender;
- (IBAction)show:(id)sender;

@end
