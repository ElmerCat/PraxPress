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
#import <SoundCloudAPI/SCAPI.h>
#import "SoundCloudController.h"
@class SoundCloudController;

@interface Document : NSPersistentDocument

@property (strong) IBOutlet SoundCloudController *soundCloudController;
@property (strong) NSArray *scTracks;

@property (strong) IBOutlet NSWindow *soundCloudAuthorizationWindow;
@property (weak) IBOutlet WebView *webView;

- (IBAction)praxAction:(id)sender;
- (IBAction)wordPressAction:(id)sender;
+ (NSString*) callerKey;
- (void)callbackFromSpecialRequest:(NSURLRequest *)request;
@end
