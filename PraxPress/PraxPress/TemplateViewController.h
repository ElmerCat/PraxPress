//
//  TemplateController.h
//  PraxPress
//
//  Created by John Canfield on 9/16/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "Document.h"
#import "Asset.h"
#import "Template.h"
#import "AssetController.h"
@class AssetController;

@interface TemplateViewController : NSViewController

@property (weak) IBOutlet Document *filesOwner;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet AssetController *assetController;

@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *templatesController;

+ (NSString *)codeForTemplate:(NSString *)formatText withAssets:(NSArray *)assets;
- (IBAction)show:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)addTemplate:(id)sender;
- (IBAction)exportTemplates:(id)sender;
- (IBAction)importTemplates:(id)sender;

@end
