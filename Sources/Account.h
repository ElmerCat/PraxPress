//
//  Account.h
//  PraxPress
//
//  Created by Elmer on 12/26/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RequestController.h"
#import "Document.h"
#import "Asset.h"
#import "Source.h"

@class Document;
@class Asset;
@class RequestController;

@interface Account : NSManagedObject

enum {
    PRAXReloadOptionAccount = 1,
    PRAXReloadOptionSite,
    PRAXReloadOptionTracks,
    PRAXReloadOptionPlaylists,
    PRAXReloadOptionPosts
};
typedef NSUInteger PRAXReloadOption;

-(BOOL)oauthReady:(Document *)document;

-(NXOAuth2Request *)requestForDownloadController:(RequestController *)controller;
-(void)handleReloadResponseData:(NSData *)responseData forController:(RequestController *)controller;
-(BOOL)handleQueueData:(NSDictionary *)queueData forController:(RequestController *)controller;

-(void)loadWordPressAccountData:(NSDictionary *)data;
-(void)loadWordPressSiteData:(NSDictionary *)data;
-(void)loadWordPressPageCount:(NSDictionary *)data;
-(void)loadSoundCloudAccountData:(NSDictionary *)data;
-(void)updateSourceCountsForDocument:(Document *)document;

@property PRAXReloadOption updateOption;
@property NSInteger updateOffset;

@property (nonatomic, retain) NSNumber * accountID;
@property (nonatomic, retain) NSString * accountURI;
@property (nonatomic, retain) NSNumber * active;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSImage * image;
@property (nonatomic, retain) NSNumber * itemCount;
@property (nonatomic, retain) NSMutableDictionary * metadata;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NXOAuth2Account * oauthAccount;
@property (nonatomic, retain) NSString * stringA;
@property (nonatomic, retain) NSString * stringB;
@property (nonatomic, retain) NSString * stringC;
@property (nonatomic, retain) NSString * stringD;
@property (nonatomic, retain) NSNumber * subCountA;
@property (nonatomic, retain) NSNumber * subCountB;
@property (nonatomic, retain) NSNumber * subCountC;
@property (nonatomic, retain) NSNumber * subCountD;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * websiteURL;

@property (nonatomic, retain) NSSet *assets;
@property (nonatomic, retain) NSSet *sources;
@end

@interface Account (CoreDataGeneratedAccessors)

- (void)addSourcesObject:(Source *)value;
- (void)removeSourcesObject:(Source *)value;
- (void)addSources:(NSSet *)values;
- (void)removeSources:(NSSet *)values;

- (void)addAssetsObject:(Asset *)value;
- (void)removeAssetsObject:(Asset *)value;
- (void)addAssets:(NSSet *)values;
- (void)removeAssets:(NSSet *)values;


@end
