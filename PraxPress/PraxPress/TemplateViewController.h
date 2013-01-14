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
#import "AssetController.h"
@class AssetController;

@interface TemplateViewController : NSViewController

@property (weak) IBOutlet Document *filesOwner;
@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet AssetController *assetController;

@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *assetBatchEditController;
@property (unsafe_unretained) IBOutlet NSTextView *formatText;
@property (weak) IBOutlet NSTextField *generatedCodeText;
@property (unsafe_unretained) IBOutlet NSPanel *previewFrameWindow;
@property (weak) IBOutlet WebView *previewWebView;

+ (NSString *)codeForTemplate:(NSString *)formatText withAssets:(NSArray *)assets;
- (IBAction)show:(id)sender;
- (IBAction)sync:(id)sender;
- (void)updateGeneratedCode;
- (IBAction)duplicate:(id)sender;
- (IBAction)addTemplate:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)exportTemplates:(id)sender;
- (IBAction)importTemplates:(id)sender;

@end
