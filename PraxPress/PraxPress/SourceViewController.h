//
//  SourceViewController.h
//  PraxPress
//
//  Created by John Canfield on 10/9/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Source.h"
#import "ServiceView.h"
#import "AccountViewController.h"

@interface SourceViewController : NSViewController
@property (weak) IBOutlet NSTreeController *sourceTreeController;
@property (weak) IBOutlet NSArrayController *assetsController;
@property BOOL awake;

@property (weak) IBOutlet NSOutlineView *sourceOutlineView;

@property NSIndexSet *selectedRowIndexes;
@property (weak) IBOutlet NSPopover *accountViewPopover;

- (void) updateFilterPredicate;

- (IBAction)filterButtonClicked:(id)sender;
- (IBAction)accountButtonClicked:(id)sender;




@end
