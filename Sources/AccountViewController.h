//
//  AccountViewController.h
//  PraxPress
//
//  Created by John Canfield on 10/10/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Document.h"

@interface AccountViewController : NSViewController

@property BOOL awake;
@property NSInteger selectionIndex;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTabView *tabView;

- (IBAction)showMetadataPopover:(id)sender;


@end
