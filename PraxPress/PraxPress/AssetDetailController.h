//
//  AssetDetailController.h
//  PraxPress
//
//  Created by Elmer on 1/10/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "Asset.h"
#import "TemplateViewController.h"
#import "AssetMetadataPopover.h"

@interface AssetDetailController : NSWindowController

@property (weak) Document *filesOwner;
@property (weak) IBOutlet AssetMetadataPopover *assetMetadataPopover;

@property NSString *templateName;
@property Asset *asset;
@property (weak) IBOutlet WebView *webView;
- (IBAction)showMetadataPopover:(id)sender;
- (IBAction)showTemplatesPopover:(id)sender;



@end
