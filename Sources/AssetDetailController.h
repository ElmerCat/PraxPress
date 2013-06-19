//
//  AssetDetailController.h
//  PraxPress
//
//  Created by Elmer on 1/10/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"

@interface AssetDetailController : NSWindowController

@property (weak) Document *filesOwner;

@property NSString *templateName;
@property Asset *asset;
@property (weak) IBOutlet WebView *webView;
@property (unsafe_unretained) IBOutlet NSTextView *codeTextView;
- (IBAction)showMetadataPopover:(id)sender;
- (IBAction)showTemplatesPopover:(id)sender;



@end
