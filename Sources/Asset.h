//
//  Asset.h
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <OAuth2Client/NXOAuth2.h>

@class Account;
@class UpdateController;
@interface Asset : NSManagedObject

enum {
    PRAXReloadOptionAccount = 1,
    PRAXReloadOptionSite,
    PRAXReloadOptionTracks,
    PRAXReloadOptionPlaylists,
    PRAXReloadOptionPosts
};
typedef NSUInteger PRAXReloadOption;



@property BOOL awake;
@property (nonatomic, retain) NSString * artwork_url;
@property (nonatomic, retain) NSNumber * asset_id;
@property (nonatomic, retain) NSNumber * batchPosition;
@property (nonatomic, retain) NSString * contents;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSNumber * comment_count;
@property (nonatomic, retain) NSNumber * download_count;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * favoritings_count;
@property (nonatomic, retain) NSNumber * playback_count;

@property (nonatomic, retain) NSNumber * edit_mode;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSNumber * info_mode;
@property (nonatomic, retain) NSString * permalink;
@property (nonatomic, retain) NSNumber * playlistPosition;
@property (nonatomic, retain) NSString * purchase_title;
@property (nonatomic, retain) NSString * purchase_url;
@property (nonatomic, retain) NSString * sharing;
@property (nonatomic, retain) NSNumber * sync_mode;
@property (nonatomic, retain) NSString * tag_list;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * sub_type;
@property (nonatomic, retain) NSString * uri;
@property (nonatomic, retain) NSNumber * updateOption;
@property (nonatomic, retain) NSMutableDictionary *metadata;
@property (nonatomic, retain) NSString * playlistType;
@property (nonatomic, retain) NSString * trackList;
@property (nonatomic, retain) NSString * trackType;

@property (nonatomic, retain) Account *account;

@property (readonly) BOOL isSoundCloudAsset;
@property (readonly) BOOL isTrack;
@property (readonly) BOOL isPlaylist;
@property (readonly) BOOL isWordPressAsset;
@property (readonly) BOOL isPage;
@property (readonly) BOOL isPost;
@property (readonly) BOOL isAccount;



-(NXOAuth2Request *)requestForUploadController:(UpdateController *)controller;
-(NXOAuth2Request *)requestForReloadController:(UpdateController *)controller option:(PRAXReloadOption)option;
-(BOOL)handleReloadResponseData:(NSData *)responseData forController:(UpdateController *)controller;

-(void)loadWordPressPostData:(NSDictionary *)data;
-(NSImage *)loadSoundCloudItemData:(NSDictionary *)data;
-(void)loadPlaylistsAsset:(Asset *)asset data:(NSDictionary *)data;

@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSSet *associatedItems;

@end

@interface Asset (CoreDataGeneratedAccessors)

- (void)addAssociatedItemsObject:(Asset *)value;
- (void)removeAssociatedItemsObject:(Asset *)value;
- (void)addAssociatedItems:(NSSet *)values;
- (void)removeAssociatedItems:(NSSet *)values;

- (void)addTagsObject:(NSManagedObject *)value;
- (void)removeTagsObject:(NSManagedObject *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end

