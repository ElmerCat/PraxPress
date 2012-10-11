//
//  AccountViewController.h
//  PraxPress
//
//  Created by John Canfield on 10/10/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UpdateController.h"

@interface AccountViewController : NSViewController

- (IBAction)refreshButtonClicked:(id)sender;
- (IBAction)logoutButtonClicked:(id)sender;

@property (weak) IBOutlet UpdateController *updateController;
@property (unsafe_unretained) IBOutlet NSPanel *synchronizePanel;
@property (weak) IBOutlet NSPopover *accountViewPopover;

@end
