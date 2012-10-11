//
//  ReplaceSubstringsController.h
//  PraxPress
//
//  Created by John Canfield on 10/9/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Asset.h"

@interface ReplaceSubstringsController : NSViewController
@property (weak) IBOutlet NSArrayController *assetBatchEditController;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSTableView *batchChangeTableView;
@property NSString *batchCount;
@property NSString *keyValue;
@property Asset *selectedAsset;

- (IBAction)cancel:(id)sender;
- (IBAction)change:(id)sender;
- (IBAction)show:(id)sender;

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSComboBox *keyField;
@property (weak) IBOutlet NSTextField *replaceField;
@property (weak) IBOutlet NSTextField *withField;


@end
