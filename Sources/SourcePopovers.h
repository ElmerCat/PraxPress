//
//  SourcePopovers.h
//  PraxPress
//
//  Created by Elmer on 6/28/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

@import Foundation;
@import Cocoa;
@import WebKit;

#import "Source.h"
@class Source;
@interface SourcePopovers : NSViewController

@property BOOL awake;

@property (weak) IBOutlet Document *document;
@property NSDictionary *sourceAccountViews;
@property Source *source;
@property (weak) IBOutlet NSPopover *sourcePopover;
@property (weak) IBOutlet NSScrollView *sourcePopoverScrollView;
@property (weak) IBOutlet WebView *authorizationWebView;
@property (strong) IBOutlet NSPanel *authorizationPanel;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@property (weak) IBOutlet NSPredicateEditor *searchPredicateEditor;

- (void)showPopoverForSource:(Source *)source sender:(id)sender preferredEdge:(NSRectEdge)preferredEdge;

@end
