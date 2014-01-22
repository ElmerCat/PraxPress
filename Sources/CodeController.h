//
//  TemplateViewController.h
//  PraxPress
//
//  Created by John-Elmer on 1/14/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#import "Widget.h"
#import "WidgetViewController.h"
@class WidgetViewController;
@class AssetListViewController;

@interface CodeController : NSObject <NSTableViewDelegate>

#pragma mark - Instance Variables

@property BOOL awake;
@property (unsafe_unretained) IBOutlet AssetListViewController *controller;
@property NSString *appleScriptSource;
@property NSAppleScript *appleScript;
@property NSURL *exportCodeURL;


#pragma mark - Interface State

@property BOOL showSafariView;
@property BOOL needsUpdate;
@property BOOL updating;
@property NSString *pageCode;
@property NSString *formatText;
@property NSString *editingString;

#pragma mark - IBOutlets

@property (weak) IBOutlet NSBox *templateBox;
@property (weak) IBOutlet NSView *templateView;
@property (unsafe_unretained) IBOutlet WidgetViewController *widgetViewController;
@property (weak) IBOutlet NSView *widgetMenuView;

@property (weak) IBOutlet NSLayoutConstraint *interRowMaxHeight;

#pragma mark - IBActions


@end
