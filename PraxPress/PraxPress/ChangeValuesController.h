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
@property (weak) IBOutlet NSPopUpButton *changeOptionsPopUpButton;
@property (strong) IBOutlet NSArrayController *changeOptionsController;
@property (strong) IBOutlet NSArrayController *sharingTypesController;
@property (strong) IBOutlet NSArrayController *trackSubTypesController;
@property (strong) IBOutlet NSArrayController *playlistSubTypesController;

@property BOOL prefixWith;
@property NSString *prefixWithString;
@property BOOL appendWith;
@property NSString *appendWithString;
@property BOOL changeTo;
@property NSString *changeToString;
@property BOOL findReplace;
@property NSString *findString;
@property NSString *replaceString;
@property BOOL removeTags;
@property NSString *removeTagsString;
@property BOOL removeAllTags;
@property BOOL addTags;
@property NSString *addTagsString;
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
@property BOOL didShowPopover;
@property (weak) IBOutlet NSButton *valueCopyButton;
@property (weak) IBOutlet NSComboBox *keyField;
@property (weak) IBOutlet NSTextField *valueField;


@end
