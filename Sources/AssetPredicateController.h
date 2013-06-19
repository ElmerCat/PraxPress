//
//  AssetPredicateController.h
//  PraxPress
//
//  Created by Elmer on 1/10/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AssetPredicateController : NSViewController

@property BOOL awake;
@property NSPredicate *predicate;

@property (weak) IBOutlet NSPredicateEditor *predicateEditor;
@property (weak) IBOutlet NSScrollView *predicateScrollView;
@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSTableView *assetsTableView;
@property (weak) IBOutlet NSPopover *popover;

//- (void) updateFilterPredicate;

//- (IBAction)filterButtonClicked:(id)sender;
- (IBAction)predicateSelector:(id)sender;
- (IBAction)show:(id)sender;


@end
