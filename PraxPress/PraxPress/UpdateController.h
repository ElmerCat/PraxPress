//
//  UpdateController.h
//  PraxPress
//
//  Created by John Canfield on 8/11/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OAuth2Client/NXOAuth2.h>
#import "Asset.h"
#import "Account.h"
#import "BatchController.h"
#import "ServiceView.h"

@class Document;
@class PostEditor;
@class BatchController;

@interface UpdateController : NSObject

@property BOOL stop;
@property BOOL busy;
@property BOOL uploadChangedItems;
@property BOOL reloadChangedItems;

@property Account *account;
@property NSString *requestMethod;
@property NSDictionary *parameters;
@property NSURL *resource;
@property NSString *statusText;
@property NSInteger updateCount;
@property NSInteger targetCount;

@property (strong) Asset *targetAsset;

@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSArrayController *changedAssetsController;
@property (weak) IBOutlet NSTableView *changedAssetsTableView;
@property (weak) IBOutlet BatchController *batchController;
@property (weak) IBOutlet NSArrayController *assetsController;
@property (unsafe_unretained) IBOutlet NSPanel *synchronizePanel;

@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSImageView *progressImageWell;

- (IBAction)stop:(id)sender;
- (IBAction)logout:(id)sender;
- (void)reloadAsset:(Asset *)asset;
- (IBAction)reloadFromServer:(id)sender;
- (IBAction)uploadToServer:(id)sender;

- (IBAction)uploadChangedItems:(id)sender;
- (IBAction)reloadChangedItems:(id)sender;

- (void)refreshAccountData:(Account *)account;
- (void)logoutAccount:(Account *)account;

@end
