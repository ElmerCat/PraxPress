//
//  Asset.h
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account;

@interface Asset : NSManagedObject

@property (nonatomic, retain) NSString * artwork_url;
@property (nonatomic, retain) NSNumber * asset_id;
@property (nonatomic, retain) NSString * contents;
@property (nonatomic, retain) NSNumber * edit_mode;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSNumber * info_mode;
@property (nonatomic, retain) NSString * permalink;
@property (nonatomic, retain) NSString * purchase_title;
@property (nonatomic, retain) NSString * purchase_url;
@property (nonatomic, retain) NSNumber * sync_mode;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uri;
@property (nonatomic, retain) NSNumber * batchPosition;

 // Account
@property (nonatomic, retain) Account *account;
@property (nonatomic, retain) NSString * accountType;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * followers_count;
@property (nonatomic, retain) NSNumber * followings_count;
@property (nonatomic, retain) NSNumber * playlist_count;
@property (nonatomic, retain) NSNumber * track_count;
@property (nonatomic, retain) NSNumber * update_offset;
@property (nonatomic, retain) NSNumber * user_id;

// Tracks and Playlists
@property (nonatomic, retain) NSSet *tracks;
@property (nonatomic, retain) NSSet *playlists;
@end

@interface Asset (CoreDataGeneratedAccessors)

- (void)addPlaylistsObject:(Asset *)value;
- (void)removePlaylistsObject:(Asset *)value;
- (void)addPlaylists:(NSSet *)values;
- (void)removePlaylists:(NSSet *)values;

- (void)addTracksObject:(Asset *)value;
- (void)removeTracksObject:(Asset *)value;
- (void)addTracks:(NSSet *)values;
- (void)removeTracks:(NSSet *)values;

@end
