//
//  Tracks.h
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OAuth2Client/NXOAuth2.h>
#import <SoundCloudAPI/SCAPI.h>
#import <WebKit/WebKit.h>
#import "Document.h"
#import "TrackView.h"
#import "Track.h"
@class Document;

@interface SoundCloudController : NSObject

@property (weak) IBOutlet Document *document;
@property (strong) NSManagedObject *account;
@property BOOL stopFlag;
//@property BOOL uploadTitleFlag;
//@property BOOL uploadPurchaseTitleFlag;
//@property BOOL uploadPurchaseURLFlag;
@property BOOL batchChangePurchaseTitle;
@property BOOL batchChangePurchaseURL;
@property (weak) IBOutlet NSTextField *changePurchaseURL;
@property (weak) IBOutlet NSTextField *changePurchaseTitle;
- (IBAction)copyPurchaseTitle:(id)sender;
- (IBAction)copyPurchaseURL:(id)sender;

@property (weak) IBOutlet NSImageView *progressImageWell;
@property (weak) IBOutlet NSArrayController *assetController;
@property (weak) IBOutlet NSArrayController *tracksBatchEditController;

@property (weak) IBOutlet NSTableView *tracksTableView;
@property (weak) IBOutlet NSTabView *batchEditTabView;

@property (weak) IBOutlet NSProgressIndicator *tracksProgress;
@property (unsafe_unretained) IBOutlet NSWindow *soundCloudAuthorizationWindow;
@property (weak) IBOutlet WebView *webView;

@property (readonly) NSPredicate *batchEditFilterPredicate;

@property (weak) IBOutlet NSButton *userDisplayButton;
@property (weak) IBOutlet NSButton *tracksDisplayButton;
@property (weak) IBOutlet NSButton *playlistsDisplayButton;

- (IBAction)userButtonClicked:(id)sender;
- (IBAction)tracksButtonClicked:(id)sender;
- (IBAction)playlistsButtonClicked:(id)sender;
- (IBAction)addBatchButtonClicked:(id)sender;
- (IBAction)removeBatchButtonClicked:(id)sender;

- (IBAction)expandView:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)stopDownload:(id)sender;
- (void)loadAccountWithData:(NSData *)data;
- (void)loadTracksWithData:(NSData *)data;
- (void)loadTrackWithData:(NSData *)data;
- (void)uploadTrackData:(Track *)track;
- (void)refreshTrack:(Track *)track;
- (void)tracksNotification:(NSNotification *)notification;
- (IBAction)editModeButtonClicked:(id)sender;
- (IBAction)infoModeButtonClicked:(id)sender;
- (IBAction)tableDoubleClickAction:(id)sender;
@end
