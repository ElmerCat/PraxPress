//
//  ChangeValuesController.h
//  PraxPress
//
//  Created by John Canfield on 10/8/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

@interface ChangeValuesController : NSViewController

@property (weak) IBOutlet Document *document;

@property NSArray *changeOptions;

@property BOOL prefixWith;
@property BOOL appendWith;
@property BOOL changeTo;
@property BOOL findReplace;
@property BOOL removeTags;
@property BOOL removeAllTags;
@property BOOL addTags;
@property BOOL changeTrackSubType;
@property BOOL changePlaylistSubType;


@property NSString *batchCount;
@property NSString *valueCopyText;
@property NSString *keyValue;
@property Asset *selectedAsset;

- (IBAction)tagSelected:(id)sender;
- (IBAction)changeOptionSelected:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)change:(id)sender;
- (IBAction)show:(id)sender;

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSButton *valueCopyButton;
@property (weak) IBOutlet NSComboBox *keyField;
@property (weak) IBOutlet NSTextField *valueField;


@end
