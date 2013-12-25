//
//  SourceInfoPanel.h
//  PraxPress
//
//  Created by Elmer on 11/21/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import "AssetListViewController.h"

@class AssetListViewController;
@class Source;

@interface SourceInfoPanel : NSWindowController

@property BOOL awake;
@property AssetListViewController *assetListViewController;
@property Source *source;
@property BOOL sourceNameEditable;
@property (weak) IBOutlet NSPredicateEditor *predicateEditor;
@property (weak) IBOutlet NSLayoutConstraint *panelBoxHeight;

@property (weak) IBOutlet NSTextField *sourceNameField;

@property (weak) IBOutlet NSBox *panelBox;
- (IBAction)updateFilter:sender;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)clearTags:(id)sender;
- (void)showSourceInfoPanel;
@property (strong) IBOutlet NSView *searchSourceInfoView;
@property (strong) IBOutlet NSView *defaultSourceInfoView;
@property (strong) IBOutlet NSView *soundCloudInfoView;
@property (strong) IBOutlet NSView *wordPressInfoView;
@property (strong) IBOutlet NSPanel *authorizationPanel;
@property (weak) IBOutlet WebView *authorizationWebView;
@property (strong) IBOutlet NSView *accountSourceInfoView;
@property (weak) IBOutlet NSTokenField *requiredTagsField;
@property (weak) IBOutlet NSTokenField *excludedTagsField;

@end
