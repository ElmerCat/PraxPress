//
//  Asset.h
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//



#import "Document.h"

#import "PraxPredicateEditorRowTemplate.h"

@class Document;
@class Source;
@class RequestController;

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
@property (nonatomic, retain) NSString * permalink_url;
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

@property (nonatomic, retain) Asset *account;

@property (nonatomic, retain) NSString * accountType;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * itemCount;
@property (nonatomic, retain) NSNumber * followers_count;
@property (nonatomic, retain) NSNumber * followings_count;
@property (nonatomic, retain) NSNumber * playlist_count;
@property (nonatomic, retain) NSNumber * track_count;
@property (nonatomic, retain) NSNumber * update_offset;

@property (nonatomic, retain) NSNumber * user_id;
@property (nonatomic, retain) id oauthAccount;
@property (nonatomic, retain) Source *source;




@property (readonly) BOOL isSoundCloudAsset;
@property (readonly) BOOL isTrack;
@property (readonly) BOOL isPlaylist;
@property (readonly) BOOL isWordPressAsset;
@property (readonly) BOOL isPage;
@property (readonly) BOOL isPost;
@property (readonly) BOOL isAccount;

+(NSDictionary *)assetKeyLabels;
+(NSArray *)assetKeysWithStringAttributeType;
+(NSArray *)assetKeysWithNumberAttributeType;
+(NSDictionary *)assetKeysAndChoicesWithMultipleChoiceAttributeType;
+(NSArray *)assetKeysWithDateAttributeType;
+(NSArray *)assetKeysWithOtherAttributeType;

+(PraxPredicateEditorRowTemplate *)predicateEditorRowTemplateWithKeys:(NSArray *)keys forAttributeType:(NSAttributeType)attributeType;
+(PraxPredicateEditorRowTemplate *)predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:(NSArray *)keys;

-(NXOAuth2Request *)requestForUploadController:(RequestController *)controller;
-(NXOAuth2Request *)requestForReloadController:(RequestController *)controller option:(PRAXReloadOption)option;
-(BOOL)handleReloadResponseData:(NSData *)responseData forController:(RequestController *)controller;


-(BOOL)oauthReady:(Document *)document;
-(void)loadWordPressAccountData:(NSDictionary *)data;
-(void)loadWordPressSiteData:(NSDictionary *)data;
-(void)loadWordPressPageCount:(NSDictionary *)data;
-(void)loadSoundCloudAccountData:(NSDictionary *)data;

-(void)loadWordPressPostData:(NSDictionary *)data;
-(NSImage *)loadSoundCloudItemData:(NSDictionary *)data;
-(void)loadPlaylistsAsset:(Asset *)asset data:(NSDictionary *)data;

@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSOrderedSet *associatedItems;
@end

@interface Asset (CoreDataGeneratedAccessors)

- (void)insertObject:(Asset *)value inAssociatedItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAssociatedItemsAtIndex:(NSUInteger)idx;
- (void)insertAssociatedItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAssociatedItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAssociatedItemsAtIndex:(NSUInteger)idx withObject:(Asset *)value;
- (void)replaceAssociatedItemsAtIndexes:(NSIndexSet *)indexes withAssociatedItems:(NSArray *)values;
- (void)addAssociatedItemsObject:(Asset *)value;
- (void)removeAssociatedItemsObject:(Asset *)value;
- (void)addAssociatedItems:(NSOrderedSet *)values;
- (void)removeAssociatedItems:(NSOrderedSet *)values;

- (void)addTagsObject:(NSManagedObject *)value;
- (void)removeTagsObject:(NSManagedObject *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end

