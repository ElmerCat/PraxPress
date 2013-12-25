//
//  WidgetViewController.h
//  PraxPress
//
//  Created by Elmer on 12/11/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "Document.h"
#import "Widget.h"
#import "WidgetMenuView.h"
#import "PraxTokenField.h"
@class WidgetMenuView;
@class PraxTokenField;
@class Widget;

@interface WidgetViewController : NSViewController <NSMenuDelegate>
@property BOOL awake;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet PraxTokenField *templateTokenField;
@property (weak) IBOutlet NSPopUpButton *popUpButton;
@property (weak) IBOutlet NSLayoutConstraint *playerOptionBoxHeight;
@property (weak) IBOutlet NSLayoutConstraint *playerOptionBoxWidth;

@property (weak) IBOutlet NSColorWell *colorColorWell;
@property (weak) IBOutlet NSColorWell *themeColorWell;

- (IBAction)closePopover:(id)sender;
@property NSInteger optionIndex;
@property (readonly) NSArray *textChoices;
@property (readonly) NSArray *textOptions;
@property (readonly) NSArray *imageOptions;
@property (readonly) NSArray *playerTypes;
@property (readonly) BOOL playerHeightEditable;

@property NSString *type;
@property NSString *width;
@property NSString *track_height;
@property NSString *playlist_height;

@property BOOL auto_play;
@property BOOL buying;
@property BOOL download;
@property BOOL enable_api;

@property BOOL liking;
@property BOOL sharing;
@property BOOL single_active;
@property BOOL show_artwork;
@property BOOL show_bpm;
@property BOOL show_comments;
@property BOOL show_playcount;
@property BOOL show_user;
@property NSString *color;
@property NSInteger default_width;
@property NSInteger default_height;
@property NSInteger start_track;
@property NSString *font;
@property NSString *text_download;
@property NSString *text_buy;
@property NSString *theme;



@property NSInteger textOptionIndex;
@property NSInteger imageOptionIndex;
@property NSInteger playerTypeIndex;
@property NSInteger scImageOptionIndex;
@property NSMutableString *stringBeforeWidget;
@property NSMutableString *stringAfterWidget;
@property BOOL widgetFound;
@property Widget *widget;
@property NSString *widgetKeyString;
@property NSString *widgetTextChoice;
@property NSString *widgetOptionString;
- (IBAction)optionSelected:(id)sender;
- (IBAction)textKeySelected:(id)sender;
- (IBAction)textOptionSelected:(id)sender;
- (IBAction)imageOptionSelected:(id)sender;
- (IBAction)playerOptionSelected:(id)sender;
- (IBAction)playerTypeSelected:(id)sender;

@property NSArray *widgetTypes;

@end
