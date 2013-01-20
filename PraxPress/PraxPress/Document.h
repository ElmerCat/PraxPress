//
//  Document.h
//  PraxPress
//
//  Created by John Canfield on 7/28/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Foundation/NSError.h>

#import <OAuth2Client/NXOAuth2.h>
//#import <SoundCloudAPI/SCAPI.h>
//#import <CocoaWordPressAPI/WPAPI.h>
//#import "SoundCloudController.h"

#import "PraxTransformers.h"
#import "Asset.h"
#import "Account.h"

#import "TagController.h"
#import "UpdateController.h"

@class SoundCloudController;
@class TagController;

@interface Document : NSPersistentDocument

@property (strong) IBOutlet TagController *tagController;
@property (strong) IBOutlet UpdateController *updateController;

@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSArrayController *associatedAssetsController;
@property (weak) IBOutlet NSArrayController *batchAssetsController;

@property (weak) IBOutlet NSArrayController *templatesController;
@property (weak) IBOutlet NSArrayController *tagsController;

@property NSArray *templateSortDescriptors;
@property (strong) NSArray *scTracks;

@property (weak) IBOutlet NSOutlineView *sourceOutlineView;

@property (weak) IBOutlet NSTableView *assetsTableView;
@property (weak) IBOutlet NSTableView *batchAssetsTableView;
@property (weak) IBOutlet NSTableView *changedAssetsTableView;
@property (weak) IBOutlet NSTableView *associatedAssetsTableView;

@property (strong) IBOutlet NSWindow *authorizationWindow;
@property (weak) IBOutlet WebView *webView;

+ (NSString*) callerKey;
- (void)callbackFromSpecialRequest:(NSURLRequest *)request;


@end


