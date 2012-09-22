//
//  WordPressController.h
//  PraxPress
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "Document.h"
#import "UpdateController.h"
#import "Asset.h"
@class UpdateController;
@class Document;
@class Asset;

@interface WordPressController : NSObject

@property (strong) Asset *userAccount;
@property (readonly) Asset *account;
@property (readonly) NSPredicate *batchEditFilterPredicate;
@property (readonly) NSPredicate *updatedObjectsFilterPredicate;

@property (unsafe_unretained) IBOutlet NSWindow *authorizationWindow;
@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet UpdateController *updateController;

@property (weak) IBOutlet NSArrayController *postsController;
@property (weak) IBOutlet NSArrayController *tracksController;
@property (weak) IBOutlet NSArrayController *playlistsController;
@property (weak) IBOutlet NSArrayController *assetBatchEditController;
@property (weak) IBOutlet NSTableView *postsTableView;
@property (weak) IBOutlet NSTabView *batchEditTabView;

- (IBAction)refresh:(id)sender;
//- (IBAction)upload:(id)sender;
- (IBAction)logout:(id)sender;


- (IBAction)addPostsBatchButtonClicked:(id)sender;
- (IBAction)removePostsBatchButtonClicked:(id)sender;

//- (IBAction)refreshTrack:(id)sender;
//- (IBAction)uploadTrack:(id)sender;
//- (IBAction)refreshPlaylist:(id)sender;
//- (IBAction)uploadPlaylist:(id)sender;
//- (IBAction)addTracksBatchButtonClicked:(id)sender;
//- (IBAction)removeTracksBatchButtonClicked:(id)sender;
//- (IBAction)addPlaylistsBatchButtonClicked:(id)sender;
//- (IBAction)removePlaylistsBatchButtonClicked:(id)sender;
//- (IBAction)editModeButtonClicked:(id)sender;

@end
