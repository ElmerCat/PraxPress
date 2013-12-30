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
#import "AccountViewController.h"
#import "RequestController.h"
#import "AssetMetadataPopover.h"
#import "TemplateViewController.h"
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
@property (strong) IBOutlet NSWindow *praxPressWindow;

@property Interface *interface;
@property PraxAssetTagStringTransformer *patsTransformer;
@property (strong) IBOutlet NSTreeController *sourceTreeController;
@property (weak) IBOutlet NSOutlineView *sourceOutlineView;
@property (strong) IBOutlet NSPanel *templatesPanel;
@property SafariDocument *safariDocument;

@property (strong) IBOutlet AccountController *accountController;
@property (strong) IBOutlet TemplateController *templateController;
@property (strong) IBOutlet SourceController *sourceController;
@property (strong) IBOutlet NSArrayController *changedAssetsController;

@property (strong) IBOutlet TagController *tagController;
@property (strong) IBOutlet RequestController *requestController;
@property (strong) IBOutlet NSPanel *tagsPanel;

@property NSArray *sharingTypes;
@property NSArray *trackSubTypes;
@property NSArray *playlistSubTypes;
@property NSPredicate *changedAssetFilterPredicate;

@property NSArray *templateSortDescriptors;
@property (strong) NSArray *scTracks;

@property NSArray *accountsSettings;
- (NSDictionary *)settingsForAccount:(NSString *)name;
- (NSInteger)presentAlert:(NSString *)text forController:(id)controller options:(NSArray *)options;

+ (NSString*) callerKey;
- (void)callbackFromSpecialRequest:(NSURLRequest *)request;

@end


