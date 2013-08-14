//
//  Document.h
//  PraxPress
//
//  Created by John Canfield on 7/28/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

@import Foundation;
@import Cocoa;
@import WebKit;
@import ScriptingBridge;
#import "Safari.h"

#import <OAuth2Client/NXOAuth2.h>

#import "PraxCategories.h"
#import "PraxTransformers.h"
#import "PraxPressDocument.h"
#import "Asset.h"
#import "Source.h"
#import "SourceController.h"
#import "TagController.h"
#import "AccountViewController.h"
#import "RequestController.h"
#import "AssetMetadataPopover.h"
#import "TemplateViewController.h"
#import "TemplateController.h"

@class TemplateController;
@class SourceController;
@class RequestController;

@interface Document : NSPersistentDocument
@property PraxPressDocument *praxPressDocument;
@property (strong) IBOutlet NSTreeController *sourceTreeController;
@property (weak) IBOutlet NSOutlineView *sourceOutlineView;
@property (strong) IBOutlet NSPanel *templatesPanel;
@property SafariDocument *safariDocument;

@property (strong) IBOutlet TemplateController *templateController;
@property (strong) IBOutlet SourceController *sourceController;
@property (weak) IBOutlet NSSplitView *leftSplitView;
@property (weak) IBOutlet NSView *assetsView;
@property (weak) IBOutlet NSView *changedAssetsView;

@property (strong) IBOutlet TagController *tagController;
@property (strong) IBOutlet RequestController *requestController;
@property (weak) IBOutlet NSToolbarItem *accountsToolbarButton;
@property (weak) IBOutlet NSPopover *accountViewPopover;
@property (weak) IBOutlet AssetMetadataPopover *assetMetadataPopover;

@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSArrayController *associatedAssetsController;
@property (weak) IBOutlet NSArrayController *batchAssetsController;

@property (weak) IBOutlet NSArrayController *templatesController;
@property (weak) IBOutlet NSArrayController *tagsController;

@property NSArray *sharingTypes;
@property NSArray *trackSubTypes;
@property NSArray *playlistSubTypes;

@property NSArray *templateSortDescriptors;
@property (strong) NSArray *scTracks;

@property (weak) IBOutlet NSTableView *assetsTableView;
@property (weak) IBOutlet NSTableView *batchAssetsTableView;
@property (weak) IBOutlet NSTableView *changedAssetsTableView;
@property (weak) IBOutlet NSTableView *associatedAssetsTableView;

@property (strong) IBOutlet NSWindow *authorizationWindow;
@property (weak) IBOutlet WebView *webView;

@property NSArray *accountsSettings;
- (NSDictionary *)settingsForAccount:(NSString *)name;

//-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem;
- (IBAction)selectAccount:(id)sender;


+ (NSString*) callerKey;
- (void)callbackFromSpecialRequest:(NSURLRequest *)request;

@end


