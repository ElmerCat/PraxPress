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

@class SoundCloudController;
@class TagController;

@interface Document : NSPersistentDocument

@property (strong) IBOutlet TagController *tagController;
@property (weak) IBOutlet NSArrayController *templatesController;
@property (weak) IBOutlet NSArrayController *tagsController;
@property NSArray *templateSortDescriptors;
@property (strong) NSArray *scTracks;
@property (weak) IBOutlet NSOutlineView *sourceOutlineView;
@property (weak) IBOutlet NSTableView *assetTableView;

@property (strong) IBOutlet NSWindow *authorizationWindow;
@property (weak) IBOutlet WebView *webView;

+ (NSString*) callerKey;
- (void)callbackFromSpecialRequest:(NSURLRequest *)request;


@end


