//
//  Account.h
//  PraxPress
//
//  Created by John Canfield on 9/21/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <OAuth2Client/NXOAuth2.h>
#import "Asset.h"

@class Document;
@interface Account : Asset

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
@property (nonatomic, retain) id oauthAccount;


-(BOOL)oauthReady:(Document *)document;
-(void)loadWordPressAccountData:(NSDictionary *)data;
-(void)loadWordPressSiteData:(NSDictionary *)data;
-(void)loadWordPressPageCount:(NSDictionary *)data;
-(void)loadSoundCloudAccountData:(NSDictionary *)data;


@end

