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

#import "Prax.h"
#import "PraxCategories.h"
#import "PraxTransformers.h"
#import "Interface.h"
#import "Asset.h"
#import "Source.h"
#import "Interface.h"
#import "AccountController.h"
#import "SourceController.h"
#import "TagController.h"
#import "RequestController.h"
#import "AssetMetadataPopover.h"
#import "CodeController.h"
#import "TemplateController.h"

@class AccountController;
@class TemplateController;
@class SourceController;
@class RequestController;
@class PraxAssetTagStringTransformer;
@class Interface;

@interface Document : NSPersistentDocument {
    NSURL *_exportCodeDirectory;
}
@property NSURL *exportCodeDirectory;
- (IBAction)openExportCodeDirectory:(id)sender;

@property BOOL awake;

//@property (strong) IBOutlet NSWindow *documentWindow;

//@property (strong) IBOutlet NSWindow *praxPressWindow;



@property Interface *interface;
@property (strong) IBOutlet NSWindow *documentWindow;
@property (weak) IBOutlet NSToolbar *documentToolbar;

@property PraxAssetTagStringTransformer *patsTransformer;
//@property (strong) IBOutlet NSTreeController *sourceTreeController;
//@property (weak) IBOutlet NSOutlineView *sourceOutlineView;
//@property (strong) IBOutlet NSPanel *templatesPanel;
@property SafariDocument *safariDocument;

@property (strong) IBOutlet AccountController *accountController;
@property (strong) IBOutlet TemplateController *templateController;
@property (strong) IBOutlet SourceController *sourceController;
@property (strong) IBOutlet NSArrayController *changedAssetsController;

@property (strong) IBOutlet TagController *tagController;
@property (strong) IBOutlet RequestController *requestController;

@property NSArray *sharingTypes;
@property NSArray *trackSubTypes;
@property NSArray *playlistSubTypes;
@property NSPredicate *changedAssetFilterPredicate;

@property NSArray *templateSortDescriptors;
@property (strong) NSArray *scTracks;

@property NSArray *accountsSettings;
- (NSDictionary *)settingsForAccount:(NSString *)name;

+ (NSString*) callerKey;
- (void)callbackFromSpecialRequest:(NSURLRequest *)request;

@end


