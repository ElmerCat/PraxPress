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

@property (nonatomic, retain) NSString * artwork_url;
@property (nonatomic, retain) NSNumber * asset_id;
@property (nonatomic, retain) NSNumber * batchPosition;
@property (nonatomic, retain) NSString * contents;
@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSNumber * edit_mode;
@property (nonatomic, retain) NSString * genre;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSNumber * info_mode;
@property (nonatomic, retain) NSString * permalink;
@property (nonatomic, retain) NSString * purchase_title;
@property (nonatomic, retain) NSString * purchase_url;
@property (nonatomic, retain) NSNumber * sync_mode;
@property (nonatomic, retain) NSString * tag_list;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * uri;
@property (nonatomic, retain) NSDictionary *metadata;


 // Account
@property (nonatomic, retain) Account *account;

// Tracks and Playlists

@property (nonatomic, retain) NSSet *associatedItems;
@end

@interface Asset (CoreDataGeneratedAccessors)

- (void)addAssociatedItemsObject:(Asset *)value;
- (void)removeAssociatedItemsObject:(Asset *)value;
- (void)addAssociatedItems:(NSSet *)values;
- (void)removeAssociatedItems:(NSSet *)values;

-(NXOAuth2Request *)updateRequest:(UpdateController *)sender;

-(void)loadWordPressPostData:(NSDictionary *)data;
-(NSImage *)loadSoundCloudItemData:(NSDictionary *)data;
-(void)loadPlaylistsAsset:(Asset *)asset data:(NSDictionary *)data;
+(NSString *)htmlStringForAsset:(Asset *)asset;

@end

