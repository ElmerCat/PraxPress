//
//  UpdateController.h
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OAuth2Client/NXOAuth2.h>
//#import <SoundCloudAPI/SCAPI.h>
#import "Document.h"
#import "SoundCloudController.h"
#import "WordPressController.h"
#import "Asset.h"
#import "PostEditor.h"
#import "PraxController.h"

@class Document;
@class PostEditor;
@class SoundCloudController;
@class WordPressController;

enum UpdateMode {
    UpdateModeIdle = 0,
    UpdateModeDone,
    UpdateModeWordPress,
    UpdateModeWordPressSite,
    UpdateModeWordPressPost,
    UpdateModeUploadWordPressPost,
    UpdateModeUploadingWordPressPost,
    UpdateModeWordPressPosts,
    UpdateModeAsset,
    UpdateModeAssets,
    UpdateModeSoundCloud,
    UpdateModeTrack,
    UpdateModeUploadTrack,
    UpdateModeUploadingTrack,
    UpdateModeTracks,
    UpdateModePlaylist,
    UpdateModeUploadPlaylist,
    UpdateModeUploadingPlaylist,
    UpdateModePlaylists,
    UpdateModeError
};
typedef enum UpdateMode UpdateMode;

@interface UpdateController : NSObject
- (IBAction)praxAction:(id)sender;

@property BOOL stopFlag;
@property BOOL busy;
@property UpdateMode updateMode;
@property NSInteger updateCount;
@property NSInteger targetCount;
@property (strong) NXOAuth2Account *scAccount;

@property (strong) NXOAuth2Account *wpAccount;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet SoundCloudController *soundCloudController;
@property (weak) IBOutlet WordPressController *wordPressController;
@property (weak) IBOutlet NSArrayController *postsController;
@property (weak) IBOutlet NSArrayController *tracksController;
@property (weak) IBOutlet NSArrayController *playlistsController;

@property (weak) IBOutlet NSTextField *statusText;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSImageView *progressImageWell;

- (IBAction)stopDownload:(id)sender;

@end
