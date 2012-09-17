//
//  TemplateController.h
//  PraxPress
//
//  Created by John Canfield on 9/16/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "Asset.h"

@interface TemplateController : NSObject


@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *assetBatchEditController;
@property (unsafe_unretained) IBOutlet NSTextView *startingFormatText;
@property (unsafe_unretained) IBOutlet NSTextView *blockFormatText;
@property (unsafe_unretained) IBOutlet NSTextView *endingFormatText;
@property (weak) IBOutlet NSTextField *generatedCodeText;
@property (unsafe_unretained) IBOutlet NSPanel *previewFrameWindow;
@property (weak) IBOutlet WebView *previewWebView;

- (void)updateGeneratedCode;
- (IBAction)preview:(id)sender;

@end
