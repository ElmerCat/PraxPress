//
//  TemplateController.h
//  PraxPress
//
//  Created by Elmer on 7/21/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#import "Widget.h"
#import "WidgetViewController.h"
@class WidgetViewController;

@interface TemplateController : NSObject
@property BOOL awake;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSArrayController *templatesController;
@property (weak) IBOutlet NSTableView *tableView;
@property AssetListViewController *assetListView;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (unsafe_unretained) IBOutlet WidgetViewController *widgetViewController;
@property (weak) IBOutlet NSView *widgetMenuView;
@property (unsafe_unretained) IBOutlet NSPanel *panel;

+ (NSString *)codeForTemplate:(NSString *)formatText withAssets:(NSArray *)assets;

- (IBAction)addTemplate:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)exportTemplates:(id)sender;
- (IBAction)importTemplates:(id)sender;
@end
