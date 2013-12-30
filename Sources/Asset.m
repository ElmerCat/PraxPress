//
//  Asset.m
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Asset.h"

@implementation Asset

@synthesize awake;
@dynamic artwork_url;
@dynamic asset_id;
@dynamic batchPosition;
@dynamic contents;
@dynamic date;
@dynamic comment_count;
@dynamic download_count;
@dynamic duration;
@dynamic favoritings_count;
@dynamic playback_count;

@dynamic edit_mode;
@dynamic genre;
@dynamic image;
@dynamic info_mode;
@dynamic permalink;
@dynamic playlistPosition;
@dynamic purchase_title;
@dynamic purchase_url;
@dynamic permalink_url;
@dynamic sharing;
@dynamic sync_mode;
@dynamic tag_list;
@dynamic title;
@dynamic type;
@dynamic sub_type;
@dynamic uri;
@dynamic metadata;
@dynamic playlistType;
@dynamic trackList;
@dynamic trackType;

@dynamic accountType;
@dynamic city;
@dynamic country;
@dynamic followers_count;
@dynamic followings_count;
@dynamic itemCount;
@dynamic oauthAccount;
@dynamic playlist_count;
@dynamic track_count;
@dynamic update_offset;
@dynamic user_id;
@dynamic username;
@dynamic source;

@dynamic account;
@dynamic serviceAccount;
@dynamic serviceAccounts;
@dynamic associatedItems;
@dynamic batchSources;
@dynamic categories;
@dynamic genreTags;
@dynamic tags;

-(BOOL)isSoundCloudAsset {
    if ([self.accountType isEqualToString:@"SoundCloud"]) return YES;
    else return NO;
}
-(BOOL)isTrack {
    if ([self.type isEqualToString:@"track"]) return YES;
    else return NO;
}
-(BOOL)isPlaylist {
    if ([self.type isEqualToString:@"playlist"]) return YES;
    else return NO;
}
-(BOOL)isWordPressAsset {
    if ([self.accountType isEqualToString:@"WordPress"]) return YES;
    else return NO;
}
-(BOOL)isPage {
    if (([self.type isEqualToString:@"page"])) return YES;
    else return NO;
}
-(BOOL)isPost {
    if (([self.type isEqualToString:@"post"])) return YES;
    else return NO;
}

- (void)addAssociatedItemsObject:(Asset *)value {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.associatedItems];
    [tempSet addObject:value];
    self.associatedItems = tempSet;
}

+(NSArray *)predicateDateAttributeTypeOperators {
    
    return [Asset predicateNumberAttributeTypeOperators];
}

+(NSArray *)predicateStringAttributeTypeOperators {
    
    return@[[NSNumber numberWithInt:NSMatchesPredicateOperatorType],
            [NSNumber numberWithInt:NSLikePredicateOperatorType],
            [NSNumber numberWithInt:NSBeginsWithPredicateOperatorType],
            [NSNumber numberWithInt:NSEndsWithPredicateOperatorType],
            [NSNumber numberWithInt:NSContainsPredicateOperatorType]
            ];
}

+(NSArray *)predicateNumberAttributeTypeOperators {
    
    return@[[NSNumber numberWithInt:NSLessThanPredicateOperatorType],
            [NSNumber numberWithInt:NSLessThanOrEqualToPredicateOperatorType],
            [NSNumber numberWithInt:NSGreaterThanPredicateOperatorType],
            [NSNumber numberWithInt:NSGreaterThanOrEqualToPredicateOperatorType],
            [NSNumber numberWithInt:NSEqualToPredicateOperatorType],
            [NSNumber numberWithInt:NSNotEqualToPredicateOperatorType]
            ];
}

+(NSArray *)predicateLeftExpressionsWithKeys:(NSArray *)keys {
    NSMutableArray *items = @[].mutableCopy;
    for (NSString *key in keys) {
        [items addObject:[NSExpression expressionWithFormat:key]];
    }
    return items;
}
+(NSArray *)predicateRightExpressionsWithKeys:(NSArray *)keys {
    NSMutableArray *items = @[].mutableCopy;
    for (NSString *key in keys) {
        [items addObject:[NSExpression expressionForConstantValue:key]];
    }
    return items;
}

+(PraxPredicateEditorRowTemplate *)predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:(NSArray *)keys {
    
    NSArray *leftExpressions = [self predicateLeftExpressionsWithKeys:keys];
    NSArray *choices = [Asset assetKeysAndChoicesWithMultipleChoiceAttributeType][keys[0]];
    
    NSArray *rightExpressions;
    NSArray *operators;
    if (choices.count > 2) {
        rightExpressions = [self predicateRightExpressionsWithKeys:choices];
        operators = @[[NSNumber numberWithInt:NSEqualToPredicateOperatorType], [NSNumber numberWithInt:NSNotEqualToPredicateOperatorType]];
    }
    else {
        rightExpressions = @[[NSExpression expressionWithFormat:@"0"],[NSExpression expressionWithFormat:@"1"]];
        operators = @[[NSNumber numberWithInt:NSEqualToPredicateOperatorType], [NSNumber numberWithInt:NSNotEqualToPredicateOperatorType]];
    }
    
    PraxPredicateEditorRowTemplate *rowTemplate = [[PraxPredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions rightExpressions:rightExpressions modifier:0 operators:operators options:0];
    
    NSPopUpButton *popUpButton = [[rowTemplate templateViews] objectAtIndex:0];
    
    for (NSString *key in keys) {
        NSMenuItem *item = [popUpButton itemWithTitle:key];
        NSString *label = [Asset assetKeyLabels][key];
        if (item) [item setTitle:label];
        
    }
    popUpButton = [[rowTemplate templateViews] objectAtIndex:2];
    int index;
    for (index = 0; (index < rightExpressions.count); index++) {
        NSMenuItem *item = [popUpButton itemWithTitle:[NSString stringWithFormat:@"%d", index]];
        NSString *y = choices[index];
        if (item) [item setTitle:y];
        
        
    }
    
    
    
    return rowTemplate;
}

+(PraxPredicateEditorRowTemplate *)predicateEditorRowTemplateWithKeys:(NSArray *)keys forAttributeType:(NSAttributeType)attributeType {
    NSArray *leftExpressions = [self predicateLeftExpressionsWithKeys:keys];
    NSArray *operators;
    if (attributeType == NSStringAttributeType) operators = [Asset predicateStringAttributeTypeOperators];
    else if (attributeType == NSDateAttributeType) operators = [Asset predicateDateAttributeTypeOperators];
    else operators = [Asset predicateNumberAttributeTypeOperators];
    
    PraxPredicateEditorRowTemplate *rowTemplate = [[PraxPredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions rightExpressionAttributeType:attributeType modifier:0 operators:operators options:NSCaseInsensitiveSearch];
    
    NSPopUpButton *leftExpressionButton = [[rowTemplate templateViews] objectAtIndex:0];
    
    for (NSString *key in keys) {
        NSMenuItem *item = [leftExpressionButton itemWithTitle:key];
        if (item) [item setTitle:[Asset assetKeyLabels][key]];
        
    }
    
    NSControl *control = [[rowTemplate templateViews] lastObject];
    NSRect controlFrame = control.frame;
    if (attributeType == NSInteger64AttributeType) {
        controlFrame.size.width = 60.0f;
    }
    else if (attributeType == NSStringAttributeType) {
        controlFrame.size.width = 260.0f;
    }
    control.frame = controlFrame;
    [control setContinuous:YES];
    return rowTemplate;
}



- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"Asset init");
        
    }
    return self;
}

- (void)dealloc {
    //    NSLog(@"Asset dealloc");
    if (self.awake) {
        self.awake = FALSE;
        for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
        
    }
}

- (void)awakeFromFetch {
    
    if (!self.awake) {
        self.awake = TRUE;
        //        NSLog(@"Asset awakeFromFetch");
        
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
    }
    
}

- (void)awakeFromInsert {
    
    if (!self.awake) {
        self.awake = TRUE;
        //        NSLog(@"Asset awakeFromInsert");
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
    }
    
}


+(NSDictionary *)assetKeyLabels {
    return @{@"accountType": @"Account Type",
             @"artwork_url": @"Artwork URL",
             @"asset_id": @"Asset ID",
             @"city": @"City Placename",
             @"comment_count": @"Comment Count",
             @"contents": @"Description Contents",
             @"country": @"Country Name",
             @"date": @"Date",
             @"download_count": @"Download Count",
             @"duration": @"Duration in Milliseconds",
             @"favoritings_count": @"Favoritings Count",
             @"followers_count": @"Followers Count",
             @"followings_count": @"Followings Count",
             @"genre": @"Genre",
             @"itemCount": @"Item Count",
             @"permalink": @"Permalink",
             @"playback_count": @"Playback Count",
             @"playlist_count": @"Playlist Count",
             @"playlistType": @"Playlist Type",
             @"purchase_title": @"Purchase Link Title",
             @"purchase_url": @"Purchase Link URL",
             @"permalink_url": @"Permalink URL",
             @"sharing": @"Sharing Mode",
             @"sync_mode": @"Sync Mode",
             @"sub_type": @"Sub Type",
             @"tags": @"Tags",
             @"tag_list": @"Tag List",
             @"title": @"Title",
             @"track_count": @"Track Count",
             @"trackList": @"Track List",
             @"track_type": @"Track Type",
             @"type": @"Asset Type",
             @"uri": @"Resource URI",
             @"user_id": @"User ID",
             @"username": @"Username"};
}

+(NSArray *)assetKeysWithStringAttributeType {
    return @[@"artwork_url",
             //     @"asset_id",
             //      @"city",
             @"contents",
             //      @"country",
             @"genre",
             @"permalink",
             @"purchase_title",
             @"purchase_url",
             @"permalink_url",
             @"sub_type",
             @"tag_list",
             @"title",
             //  @"trackList",
             @"uri",
             @"user_id" //,
             //   @"username"
             ];
}

+(NSArray *)assetKeysWithNumberAttributeType {
    return @[@"comment_count",
             @"download_count",
             @"duration",
             @"favoritings_count",
             //    @"followers_count",
             //    @"followings_count",
             //    @"itemCount",
             @"playback_count",
             //    @"playlist_count",
             @"sync_mode"//,
             //    @"track_count"
             ];
}
- (NSArray *)numericKeys {
    return @[@"asset_id",
             @"comment_count",
             @"download_count",
             @"duration",
             @"favoritings_count",
             @"playback_count"];
}


+(NSDictionary *)assetKeysAndChoicesWithMultipleChoiceAttributeType {
    return @{@"type": @[@"post", @"page", @"track", @"playlist", @"image", @"video", @"account"],
             @"sharing": @[@"Public", @"Private"],
             @"accountType":@[@"SoundCloud", @"WordPress", @"Flickr", @"YouTube"],
             @"track_type":@[@"one", @"two", @"three", @"four"]};
}

+(NSArray *)assetKeysWithDateAttributeType {
    return @[@"date"];
}

+(NSArray *)assetKeysWithOtherAttributeType {
    return @[@"playlistType",
             @"tags",
             @"trackType",
             @"type"];
}

- (NSDictionary *)wordPressItemKeys {
    return @{
             @"title":@"title",
             @"date":@"modified",
             @"artwork_url":@"featured_image",
             @"permalink_url":@"URL",
             @"type":@"type",
             @"permalink":@"slug",
             @"contents":@"content",
             @"sub_type":@"format",
             @"sharing":@"status"};
}

- (NSDictionary *)soundCloudItemKeys {
    return @{
             @"comment_count":@"comment_count",
             @"contents":@"description",
             @"date":@"created_at",
             @"download_count":@"download_count",
             @"duration":@"duration",
             @"favoritings_count":@"favoritings_count",
             @"genre":@"genre",
             @"permalink":@"permalink",
             @"permalink_url":@"permalink_url",
             @"playback_count":@"playback_count",
             @"purchase_title":@"purchase_title",
             @"purchase_url":@"purchase_url",
             @"sharing":@"sharing",
             @"title":@"title",
             @"type":@"kind",
             @"uri":@"uri"
             };
}

- (NSDictionary *)soundCloudTrackKeys {
    return @{@"sub_type":@"track_type"};
}

- (NSDictionary *)soundCloudPlaylistKeys {
    return @{@"sub_type":@"playlist_type"};
}

- (NSArray *)protectedKeys {
    return @[@"title",
             @"purchase_url",
             @"purchase_title",
             @"permalink",
             @"permalink_url",
             @"genre",
             @"contents",
             @"sharing",
             @"sub_type"];
}

- (NSArray *)keyPathsToObserve {return @[@"self.edit_mode",
                                         @"self.title",
                                         @"self.purchase_title",
                                         @"self.purchase_url",
                                         @"self.permalink_url",
                                         @"self.sub_type",
                                         @"self.sharing",
                                         @"self.genre",
                                         @"self.permalink",
                                         @"self.tag_list",
                                         @"self.trackList",
                                         @"self.tags",
                                         @"self.genreTags",
                                         @"self.categories",
                                         @"self.associatedItems",
                                         @"self.contents"
                                         ];}


- (NSString *)metadataKeyForKey:(NSString *)key {
    NSString *metadataKey;
    if ([self.accountType isEqualToString:@"WordPress"]) {
        metadataKey = [self wordPressItemKeys][key];
    }
    else {
        metadataKey = [self soundCloudItemKeys][key];
        if (!metadataKey.length) {
            if ([self.type isEqualToString:@"track"]) {
                metadataKey = [self soundCloudTrackKeys][key];
            }
            else if ([self.type isEqualToString:@"playlist"]) {
                metadataKey = [self soundCloudPlaylistKeys][key];
            }
            
        }
    }
    return metadataKey;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //   NSLog(@"Asset observeValueForKeyPath:%@", keyPath);

    NSString *key = [keyPath substringFromIndex:5];

    if ([key isEqualToString:@"edit_mode"]) {
        
  //      [[NSNotificationCenter defaultCenter] postNotificationName:@"BatchAssetChangedNotification" object:self];
    }
    
    else {
        if ([key isEqualToString:@"associatedItems"]) {
            if (![self.type isEqualToString:@"playlist"]) {
                return;
            }
        }
        else if ([[self protectedKeys] containsObject:key]) {
            if ([self isInSync]) {
                if (self.sync_mode.boolValue) {
                    self.sync_mode = @NO;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
                }
            }
            else {
                if (!self.sync_mode.boolValue) {
                    self.sync_mode = @YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
                }
            }
            return;
        }
        
      //  [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
        
        if ([key isEqualToString:@"genreTags"]) {
            if (self.genreTags.count) {
                Tag *genre = [self.genreTags allObjects][0];
                self.genre = genre.name;
            }
            else self.genre = @"";
        }
        else if ([key isEqualToString:@"tags"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetTagsChangedNotification" object:self];
        }
    }
}



-(NXOAuth2Request *)requestForReloadController:(RequestController *)controller {  // return a request, configured as required for account type
    
    controller.parameters = [NSDictionary dictionary];
    
    if ((!self.account) || (![self.account oauthReady:controller.document])) return nil;
    
    
    if (self.isSoundCloudAsset) {
        controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
 //       if (self.isTrack) controller.statusText = [NSString stringWithFormat:@"Downloading SoundCloud Track ---- %@", self.title];
 //       else controller.statusText = [NSString stringWithFormat:@"Downloading SoundCloud Playlist ---- %@", self.title];
    }
    
    else if (self.isWordPressAsset) {
        controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
        controller.parameters = @{@"context":@"edit"};
//        if (self.isPost) controller.statusText = [NSString stringWithFormat:@"Downloading WordPress Post ---- %@", self.title];
//        else controller.statusText = [NSString stringWithFormat:@"Downloading WordPress Page ---- %@", self.title];
    }
    else return nil;
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"GET" parameters:controller.parameters];
    request.account = self.account.oauthAccount;
    if (!request.account) return nil;
    else return request;
    
    
    
    
}

-(NXOAuth2Request *)requestForUploadController:(RequestController *)controller {  // return a request, configured as required for account type
    
    
    if (![self.account oauthReady:controller.document]) return nil; // not authorized yet
    NXOAuth2Request *request;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    if (self.isSoundCloudAsset) {
        
        for (NSString *key in @[@"title", @"purchase_title", @"purchase_url", @"contents", @"sharing", @"genre", @"permalink", @"tag_list"]) {
            
            NSString *asset_key = (self.isTrack) ? [NSString stringWithFormat:@"track[%@]", key] : [NSString stringWithFormat:@"playlist[%@]", key];
            if ([key isEqualToString:@"tag_list"]) {
                NSMutableString *value = [[NSMutableString alloc] init];
                NSRange range;
                for (Tag *tag in self.tags) {
                    if (value.length > 0) [value appendString:@" "];
                    range = [tag.name rangeOfString:@" "];
                    if (range.location != NSNotFound) [value appendFormat:@"\"%@\"", tag.name];
                    else [value appendString:tag.name];
                }
                [parameters setObject:[value description] forKey:asset_key];
            }
            else if ([key isEqualToString:@"genre"]) {
                
                if (self.genreTags.count) {
                    Tag *genre = [self.genreTags allObjects][0];
                    [parameters setObject:genre.name forKey:asset_key];
                }
                else [parameters setObject:@"" forKey:asset_key];
            }
            else {
                NSString *value = ([self valueForKey:key]) ? [self valueForKey:key] : @"";
                [parameters setObject:value forKey:asset_key];
            }
        }
        
        if (self.isTrack) {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"track[track_type]"];
    //        controller.statusText = [NSString stringWithFormat:@"Uploading SoundCloud Track ---- %@", self.title];
        }
        else {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"playlist[playlist_type]"];
            
            
            NSMutableArray *tracks = [NSMutableArray array];
            
            for (Asset *track in self.associatedItems) {
                [tracks addObject:track.asset_id.stringValue];
            }
            
            [parameters setObject:tracks forKey:@"playlist[tracks][][id]"];
     //       controller.statusText = [NSString stringWithFormat:@"Uploading SoundCloud Playlist ---- %@", self.title];
        }
        
        if (!self.asset_id) {  // uploading a new Asset
            if (self.isPlaylist) {
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/me/playlists.json"]];
                
            }
            else {
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/me/tracks.json"]];
                
            }
            controller.parameters = parameters;
            request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"POST" parameters:controller.parameters];
        }
        
        else {
            controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
            controller.parameters = parameters;
            request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"PUT" parameters:controller.parameters];
        }
    }
    
    else if (self.isWordPressAsset) {
        
        
        [parameters setObject:self.title forKey:@"title"];
        [parameters setObject:self.contents forKey:@"content"];
        [parameters setObject:self.sub_type forKey:@"format"];
        [parameters setObject:self.sharing forKey:@"status"];
        
        NSMutableString *tags = [[NSMutableString alloc] init];
        for (Tag *tag in self.tags) {
            if (tags.length > 0) [tags appendString:@","];
            [tags appendString:tag.name];
        }
        [parameters setObject:[tags description] forKey:@"tags"];

        
        controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
        controller.parameters = parameters;
   //     if (self.isPost) controller.statusText = [NSString stringWithFormat:@"Uploading WordPress Post ---- %@", self.title];
  //      else controller.statusText = [NSString stringWithFormat:@"Uploading WordPress Page ---- %@", self.title];
        request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"POST" parameters:controller.parameters];
        
    }
    
    else return nil;  // invalid Asset type
    
 //   controller.statusText = [NSString stringWithFormat:@"Uploading %@ Asset %@", self.serviceAccount.accountType, self.permalink];
    request.account = self.account.oauthAccount;
    
    return request;
    
}


-(BOOL)loadAssetData:(NSDictionary *)data forController:(RequestController *)controller {
    [self setValue:data forKey:@"metadata"];
    
    if (self.isSoundCloudAsset) {
        [self loadAssetData:self.metadata withKeys:[self soundCloudItemKeys] forController:controller];
        
        if (self.date.length > 16) {
            self.date = [self.date substringToIndex:16];
        }
        
        if (self.isPlaylist) {
            [self loadAssetData:self.metadata withKeys:[self soundCloudPlaylistKeys] forController:controller];
        }
        else if (self.isTrack) {
            [self loadAssetData:self.metadata withKeys:[self soundCloudTrackKeys] forController:controller];
        }
        
        
        if (data[@"artwork_url"] != [NSNull null]) {
            NSString *artwork_url = data[@"artwork_url"];
            NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
            artwork_url = [NSString stringWithString:(NSString *)a[0]];
            self.artwork_url = artwork_url;
            artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //original
            NSURL *url = [NSURL URLWithString:artwork_url];
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            self.image = [NSArchiver archivedDataWithRootObject:image];
        }
        
        if (self.isPlaylist) {
            Asset *subAsset;
            NSArray *subItems;
            self.associatedItems = nil;
            subItems = data[@"tracks"];
            NSMutableString *trackList = [[NSMutableString alloc] init];
            for (NSDictionary *subItem in subItems) {
                NSLog(@"subItem asset_id: %@", subItem[@"id"]);
                if (trackList.length > 0) [trackList appendString:@","];
                [trackList appendString:[subItem[@"id"] stringValue]];
                subAsset = [NSManagedObject entity:@"Asset" withKey:@"asset_id" matchingStringValue:subItem[@"id"] inManagedObjectContext:self.managedObjectContext];
                if (!subAsset) {
                    NSLog(@"Error: - No matching Asset - subItem asset_id: %@", subItem[@"id"]);
                }
                else {
                    [self addAssociatedItemsObject:subAsset];
                }
            }
            self.trackList = trackList.description;
        }
        
    }
    else if (self.isWordPressAsset) {
        [self loadAssetData:self.metadata withKeys:[self wordPressItemKeys] forController:controller];
        if (self.date.length > 16) {
            self.date = [self.date stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
            self.date = [self.date substringToIndex:16];
        }
        
        self.uri = data[@"meta"][@"links"][@"site"];
        
        if (![self.artwork_url isEqualToString:@""]) {
            NSURL *url = [NSURL URLWithString:self.artwork_url];
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            self.image = [NSArchiver archivedDataWithRootObject:image];
        }
        
    }
    else return NO; // invalid option
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [controller.updateControlsToolbarItem setLabel:[NSString stringWithFormat:@"Processing %@ - %@", self.account.name, self.title]];
    });
    
    
    [controller.document.tagController loadAssetTags:self data:data];
//    self.sync_mode = [NSNumber numberWithBool:FALSE];
    [controller.document.changedAssetsController fetch:self];
    
    if (controller.reloadAll) {
        controller.updateCount += 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller reloadChangedAssets];
        });
    }
    else if (controller.uploadAll) {
        controller.updateCount += 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller uploadChangedAssets];
        });
    }
//    else {
        //            [controller reset];
  //  }
    //    }
    if (controller.replace) self.sync_mode = @NO;
    return YES;
    
}


-(BOOL)handleReloadResponseData:(NSData *)responseData forController:(RequestController *)controller {
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:0];
    if (!data) return NO;
    //    NSLog(@"data: %@", data);
    return [self loadAssetData:data forController:controller];
}


-(BOOL)isInSync {
    for (NSString *key in [self protectedKeys]) {
        if (![self isInSyncForKey:key]) return NO;
    }
    return YES;
}
-(BOOL)isInSyncForKey:(NSString *)key {
    NSString *value = [self valueForKey:key];
    NSString *metaValue = self.metadata[[self metadataKeyForKey:key]];
    if (metaValue == value) return YES;
    if (([metaValue respondsToSelector:@selector(length)]) &&([value respondsToSelector:@selector(length)])) {
        return [value isEqualToString:metaValue];
    }
    else return NO;
}


-(void)loadAssetData:(NSDictionary *)data withKeys:(NSDictionary *)keys forController:(RequestController *)controller {
    
    for (NSString *key in keys) {
        if ([self isInSyncForKey:key]) continue;
        
        if ([[self protectedKeys] containsObject:key]) {
            if ((!controller.replace) && (controller.skipAll)) {
                self.sync_mode = @YES;
                continue;
            }
            if (!controller.replace) {
                NSInteger __block result;
 //               dispatch_sync(dispatch_get_main_queue(), ^{
                    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@\n\nUpdate this Item with value from %@ Server?\n\nChange Value for %@", self.title, self.account.name, key] defaultButton:@"Skip this Item" alternateButton:[NSString stringWithFormat:@"Change to Value from %@",self.account.name] otherButton:@"Stop Downloading" informativeTextWithFormat:@"Old Value: %@\nNew Value: %@", [self valueForKey:key], self.metadata[keys[key]]];
                    [alert setAccessoryView:controller.alertAccessoryView];
                    result = [alert runModal];
 //               });
                
                if (result == NSAlertDefaultReturn) {
                    self.sync_mode = @YES;
                    continue;
                }
                else if (result == NSAlertAlternateReturn) {
                    if (controller.skipAll) controller.replace = YES;
                }
                else if (result == NSAlertOtherReturn) {
                    controller.stop = @YES;
                    return;
                }

            }
        }
        if ((!self.metadata[keys[key]]) || (self.metadata[keys[key]] == [NSNull null])) {
            if ([[self numericKeys] containsObject:key])[self setValue:0 forKey:key];
            else [self setValue:@"" forKey:key];
        }
        else [self setValue:self.metadata[keys[key]] forKey:key];
//        if ([[self protectedKeys] containsObject:key]) self.sync_mode = @NO;
    }
}


/*
 
 
 - (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error {
 BOOL result = [super validateValue:value forKey:key error:error];
 
 NSLog(@"Asset validateValue:%@ forKey:%@ error:%@", *value, key, *error);
 
 
 return result;
 
 }
 - (BOOL)validateGenre:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateGenre %@", *value);
 
 *error = [NSError errorWithDomain:@"PraxPress Error" code:7 userInfo:nil];
 
 return NO;
 }
 
 
 - (BOOL)validateForUpdate:(NSError **)error {
 BOOL result = [super validateForUpdate:error];
 
 NSLog(@"Asset validateForUpdate");
 
 
 return result;
 }
 
 - (BOOL)validateSharing:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateSharing %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateSub_type:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateSub_type %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateTitle:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTitle %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateGenre:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateGenre %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validatePermalink:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validatePermalink %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validatePurchase_title:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTitle %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validatePurchase_url:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTitle %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateTag_list:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateTag_list %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (BOOL)validateContents:(id *)value error:(NSError **)error {
 
 NSLog(@"Asset validateContents %@", *value);
 [self setAssetChanged:self];
 
 
 return YES;
 }
 
 - (void)setAssetChanged:(Asset *)asset {
 
 asset.sync_mode = [NSNumber numberWithBool:TRUE];
 //    [self.changedAssetsController rearrangeObjects];
 
 } */





@end
