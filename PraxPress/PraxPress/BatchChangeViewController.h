//
//  BatchChangeViewController.h
//  PraxPress
//
//  Created by John Canfield on 10/8/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BatchChangeViewController : NSViewController
- (IBAction)cancelBatchChange:(id)sender;
@property (weak) IBOutlet NSPopover *batchChangePopover;

@end
