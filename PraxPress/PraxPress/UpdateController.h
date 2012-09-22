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
#import "SoundCloudController.h"
#import "WordPressController.h"
#import "Asset.h"
#import "Account.h"
#import "PraxController.h"
#import "Template.h"

@class Document;
@class PostEditor;
@class PraxController;
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

- (NXOAuth2Account *) scAccount;
- (NXOAuth2Account *) wpAccount;

@property BOOL stop;
@property BOOL busy;
@property BOOL uploadChangedItems;
@property BOOL reloadChangedItems;

@property Account *account;
@property NSString *requestMethod;
@property NSDictionary *parameters;
@property NSURL *resource;
@property NSString *statusText;
@property UpdateMode updateMode;
@property NSInteger updateCount;
@property NSInteger targetCount;

@property (strong) Asset *targetAsset;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSTableView *changedAssetsTableView;
@property (weak) IBOutlet PraxController *praxController;
@property (weak) IBOutlet SoundCloudController *soundCloudController;
@property (weak) IBOutlet WordPressController *wordPressController;
@property (weak) IBOutlet NSArrayController *assetsController;

@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSImageView *progressImageWell;

- (IBAction)stop:(id)sender;
- (IBAction)reloadFromServer:(id)sender;
- (IBAction)uploadToServer:(id)sender;
- (IBAction)refreshAllData:(id)sender;
- (IBAction)uploadChangedItems:(id)sender;
- (IBAction)reloadChangedItems:(id)sender;

@end
