//
//  MultipleChangePopover.h
//  PraxPress
//
//  Created by Elmer on 12/5/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AssetListViewController.h"
#import "WidgetViewController.h"
#import "PraxButton.h"
@class AssetListViewController;
@interface MultipleChangePopover : NSViewController


@property AssetListViewController *controller;
@property NSString *changeKey;

@property BOOL trimFromBeginning;
@property BOOL addToBeginning;
@property BOOL findAndReplace;
@property BOOL findCaseInsensitive;
@property BOOL trimFromEnd;
@property BOOL addToEnd;
@property BOOL pasteTrimmedFromBeginning;
@property BOOL pasteTrimmedFromEnd;
@property BOOL removeTags;
@property BOOL addTags;
@property NSInteger trimBeginningOption;
@property NSInteger trimBeginningCount;
@property NSInteger trimEndOption;
@property NSInteger trimEndCount;
@property NSInteger pasteBeginningOption;
@property NSInteger pasteEndOption;
@property NSInteger findReplaceOption;
@property NSString *trimBeginningMatchString;
@property NSString *trimEndMatchString;
@property NSString *addToBeginningString;
@property NSString *addToEndString;
@property NSString *findString;
@property NSString *replaceString;
@property NSMutableSet *tagsToRemove;
@property NSMutableSet *tagsToAdd;

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSBox *viewBox;
@property (weak) IBOutlet NSView *modifyTextView;
@property (weak) IBOutlet NSView *modifyTagsView;

- (IBAction)modifyTitles:(id)sender;
- (IBAction)modifyPermalinks:(id)sender;
- (IBAction)modifyContents:(id)sender;
- (IBAction)modifyTags:(id)sender;
- (IBAction)mergeTags:(id)sender;
- (IBAction)removeAllTags:(id)sender;
- (IBAction)changeText:(id)sender;
- (IBAction)changeTags:(id)sender;



@end
