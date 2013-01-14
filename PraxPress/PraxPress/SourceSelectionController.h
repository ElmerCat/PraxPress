//
//  SourceSelectionController.h
//  PraxPress
//
//  Created by Elmer on 12/29/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import "Source.h"
#import "ServiceView.h"
#import "AccountViewController.h"

@interface SourceSelectionController : NSViewController

@property BOOL awake;
@property NSIndexSet *selectedRowIndexes;
@property NSPredicate *predicate;

@property (weak) IBOutlet NSTableView *sourceTableView;
@property (weak) IBOutlet NSArrayController *sourceArrayController;
@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSPopover *accountViewPopover;
@property (weak) IBOutlet NSTableView *assetsTableView;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet Document *document;

- (IBAction)accountButtonClicked:(id)sender;
- (IBAction)show:(id)sender;


@end
