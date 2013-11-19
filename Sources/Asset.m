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
@dynamic updateOption;
@dynamic metadata;
@dynamic playlistType;
@dynamic trackList;
@dynamic trackType;
@dynamic tags;

@dynamic account;
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

@dynamic associatedItems;
- (void)addAssociatedItemsObject:(Asset *)value {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.associatedItems];
    [tempSet addObject:value];
    self.associatedItems = tempSet;
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



+(NSArray *)assetKeysWithStringAttributeType {
    return @[@"artwork_url",
             @"asset_id",
             @"city",
             @"contents",
             @"country",
             @"genre",
             @"permalink",
             @"purchase_title",
             @"purchase_url",
             @"permalink_url",
             @"sub_type",
             @"tag_list",
             @"title",
             @"trackList",
             @"uri",
             @"user_id",
             @"username"];
}

+(NSArray *)assetKeysWithNumberAttributeType {
    return @[@"comment_count",
             @"download_count",
             @"duration",
             @"favoritings_count",
             @"followers_count",
             @"followings_count",
             @"itemCount",
             @"playback_count",
             @"playlist_count",
             @"sync_mode",
             @"track_count"];
}

+(NSDictionary *)assetKeysAndChoicesWithMultipleChoiceAttributeType {
    return @{@"type": @[@"post", @"page", @"track", @"playlist", @"image", @"video"],
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

#pragma mark Accessors

-(BOOL)isSoundCloudAsset {
    if ((self.isTrack)||(self.isPlaylist)) return YES;
    else return NO;
}
-(BOOL)isTrack {
    if ([self.entity.name isEqualToString:@"Track"]) return YES;
    else return NO;
}
-(BOOL)isPlaylist {
    if ([self.entity.name isEqualToString:@"Playlist"]) return YES;
    else return NO;
}
-(BOOL)isWordPressAsset {
    if ([self.entity.name isEqualToString:@"Post"]) return YES;
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
-(BOOL)isAccount {
    if ([self.entity.name isEqualToString:@"Account"]) return YES;
    else return NO;
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
        NSLog(@"Asset awakeFromInsert");
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
    }
    
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
                                         @"self.associatedItems",
                                         @"self.contents"
                                         ];}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //   NSLog(@"Asset observeValueForKeyPath:%@", keyPath);
    
    if ([keyPath isEqualToString:@"self.edit_mode"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BatchAssetChangedNotification" object:self];
    }
    else {
        if ([keyPath isEqualToString:@"self.associatedItems"]) {
            if (![self.type isEqualToString:@"playlist"]) {
                return;
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
        if ([keyPath isEqualToString:@"self.tags"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetTagsChangedNotification" object:self];
        }
        
    }
    
}



- (BOOL)oauthReady:(Document *)document {
    
    if (!self.oauthAccount) {
        NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:self.accountType];
        if ([oauthAccounts count] > 0) {
            self.oauthAccount = oauthAccounts[0];
        } else {
            
            [self removeAccessForAccountType:self.accountType];
            
            [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.accountType
                                           withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                               [document.authorizationWindow makeKeyAndOrderFront:self];
                                               [[document.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                           }];
            return FALSE;
        }
    }
    return TRUE;
    
}

- (void)removeAccessForAccountType:(NSString *)accountType {
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:accountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
}


-(void)loadWordPressPageCount:(NSDictionary *)data {
    NSLog(@"loadWordPressPageCount: %@", data);
    
    self.playlist_count = data[@"found"];
    int posts = [self.track_count intValue];
    int pages = [self.playlist_count intValue];
    posts -= pages;
    self.track_count = [NSNumber numberWithInt:posts];
    self.sync_mode = [NSNumber numberWithBool:FALSE];
}


-(void)loadWordPressAccountData:(NSDictionary *)data {
    NSLog(@"loadWordPressAccountData: %@", data);
    [self setValue:data forKey:@"metadata"];
    NSDictionary *meta = data[@"meta"];
    self.uri = meta[@"links"][@"site"];
    
    NSDictionary *keys = @{
                           @"user_id":@"ID",
                           @"username":@"username",
                           @"asset_id":@"primary_blog",
                           @"city":@"email",
                           @"title":@"display_name",
                           @"country":@"profile_URL",
                           @"purchase_title":@"display_name"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
    if (data[@"avatar_URL"] != [NSNull null]) {
        NSString *artwork_url = data[@"avatar_URL"];
        //     NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        //     artwork_url = [NSString stringWithString:(NSString *)a[0]];
        self.artwork_url = artwork_url;
        
        //     artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image =  [NSArchiver archivedDataWithRootObject:image];
    }
}
-(void)loadWordPressSiteData:(NSDictionary *)data {
    NSLog(@"loadWordPressSiteData: %@", data);
    
    NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
    [metadata addEntriesFromDictionary:data];
    [self setValue:metadata forKey:@"metadata"];
    
    NSDictionary *keys = @{
                           @"itemCount":@"post_count",
                           @"contents":@"description",
                           @"permalink_url":@"URL",
                           @"purchase_title":@"name" };
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
}
-(void)loadSoundCloudAccountData:(NSDictionary *)data {
    
    [self setValue:data forKey:@"metadata"];
    
    NSDictionary *keys = @{
                           @"asset_id":@"id",
                           @"uri":@"uri",
                           
                           @"city":@"city",
                           @"country":@"country",
                           @"contents":@"description",
                           //   @"discogs_name":@"discogs_name",
                           @"followers_count":@"followers_count",
                           @"followings_count":@"followings_count",
                           @"title":@"full_name",
                           //   @"myspace_name":@"myspace_name",
                           //   @"permalink":@"permalink",
                           @"permalink":@"permalink_url",
                           @"playlist_count":@"playlist_count",
                           @"favoritings_count":@"public_favorites_count",
                           @"track_count":@"track_count",
                           @"username":@"username",
                           @"purchase_url":@"website",
                           @"purchase_title":@"website_title"};
    
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    
    if (data[@"avatar_url"] != [NSNull null]) {
        NSString *artwork_url = data[@"avatar_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        self.artwork_url = artwork_url;
        
        artwork_url = [artwork_url stringByAppendingString:@"-large.jpg"]; //t500x500
        //     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        self.image =  [NSArchiver archivedDataWithRootObject:image];
        //       });
    }
    self.sync_mode = [NSNumber numberWithBool:FALSE];
    
}




-(NXOAuth2Request *)requestForReloadController:(RequestController *)controller option:(PRAXReloadOption)option {  // return a request, configured as required for account type
    
    controller.parameters = [NSDictionary dictionary];
    self.updateOption = [NSNumber numberWithUnsignedInteger:option];
    
    if ([self.entity.name isEqualToString:@"Account"]) {
        
        if (![(Asset *)self oauthReady:controller.document]) return nil;
        
        
        if ([[(Asset *)self accountType] isEqualToString:@"SoundCloud"]) {
            if (option == PRAXReloadOptionAccount) {
                controller.statusText = @"Downloading SoundCloud User Profile";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me.json"];
            }
            else if (option == PRAXReloadOptionTracks) {
                controller.statusText = @"Downloading SoundCloud Tracks";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"];
                controller.parameters = @{@"limit":@"10", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = [[(Asset *)self track_count] integerValue];
                
                
            }
            else if (option == PRAXReloadOptionPlaylists) {
                controller.statusText = @"Downloading SoundCloud Playlists";
                controller.resource = [NSURL URLWithString:@"https://api.soundcloud.com/me/playlists.json"];
                controller.parameters = @{@"limit":@"10", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = [[(Asset *)self playlist_count] integerValue];
                
            }
            else return nil;
            
            
            
        }
        else if ([[(Asset *)self accountType] isEqualToString:@"WordPress"]) {
            if (option == PRAXReloadOptionAccount) {
                controller.statusText = @"Downloading WordPress User Profile";
                controller.resource = [NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"];
            }
            else if (option == PRAXReloadOptionSite) {
                controller.statusText = @"Downloading WordPress SiteData";
                controller.resource = [NSURL URLWithString:self.uri];
            }
            else if (option == PRAXReloadOptionPosts) {
                controller.statusText = @"Downloading WordPress Posts";
                controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/", self.uri]];
                controller.parameters = @{@"status":@"any", @"type":@"any", @"context":@"edit", @"number":@"10", @"offset":[[NSNumber numberWithInteger:controller.updateCount] stringValue]};
                controller.targetCount = [[(Asset *)self itemCount] integerValue];
            }
            else return nil;
        }
        
        else if ([self.account.accountType isEqualToString:@"Flickr"]) {
            controller.statusText = @"Downloading Flickr User Profile";
            controller.resource = [NSURL URLWithString:@"https://public-api.Flickr.com/rest/v1/me"];
        }
        
        else if ([self.account.accountType isEqualToString:@"YouTube"]) {
            controller.statusText = @"Downloading YouTube User Profile";
            controller.resource = [NSURL URLWithString:@"https://public-api.YouTube.com/rest/v1/me"];
        }
        else return nil;
        
        NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"GET" parameters:controller.parameters];
        request.account = [(Asset *)self oauthAccount];
        if (!request.account) return nil;
        else return request;
    }
    else {
        
        if (![self.account oauthReady:controller.document]) return nil;
        
        
        if (self.isSoundCloudAsset) {
            controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@.json", self.uri]];
            if (self.isTrack) controller.statusText = [NSString stringWithFormat:@"Downloading SoundCloud Track ---- %@", self.title];
            else controller.statusText = [NSString stringWithFormat:@"Downloading SoundCloud Playlist ---- %@", self.title];
        }
        
        else if (self.isWordPressAsset) {
            controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
            controller.parameters = @{@"context":@"edit"};
            if (self.isPost) controller.statusText = [NSString stringWithFormat:@"Downloading WordPress Post ---- %@", self.title];
            else controller.statusText = [NSString stringWithFormat:@"Downloading WordPress Page ---- %@", self.title];
        }
        else return nil;
        
        NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"GET" parameters:controller.parameters];
        request.account = self.account.oauthAccount;
        if (!request.account) return nil;
        else return request;
        
    }
    
    
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
            else {
                NSString *value = ([self valueForKey:key]) ? [self valueForKey:key] : @"";
                [parameters setObject:value forKey:asset_key];
            }
        }
        
        if (self.isTrack) {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"track[track_type]"];
            controller.statusText = [NSString stringWithFormat:@"Uploading SoundCloud Track ---- %@", self.title];
        }
        else {
            [parameters setObject:[self valueForKey:@"sub_type"] forKey:@"playlist[playlist_type]"];
            
            
            NSMutableArray *tracks = [NSMutableArray array];
            
            for (Asset *track in self.associatedItems) {
                [tracks addObject:track.asset_id.stringValue];
            }
            
            [parameters setObject:tracks forKey:@"playlist[tracks][][id]"];
            controller.statusText = [NSString stringWithFormat:@"Uploading SoundCloud Playlist ---- %@", self.title];
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
        
        
        controller.resource = [NSURL URLWithString:[NSString stringWithFormat:@"%@/posts/%@", self.uri, self.asset_id]];
        controller.parameters = parameters;
        if (self.isPost) controller.statusText = [NSString stringWithFormat:@"Uploading WordPress Post ---- %@", self.title];
        else controller.statusText = [NSString stringWithFormat:@"Uploading WordPress Page ---- %@", self.title];
        request = [[NXOAuth2Request alloc] initWithResource:controller.resource method:@"POST" parameters:controller.parameters];
        
    }
    
    else return nil;  // invalid Asset type
    
    controller.statusText = [NSString stringWithFormat:@"Uploading %@ Asset %@", self.account.accountType, self.permalink];
    request.account = self.account.oauthAccount;
    
    return request;
    
}

-(BOOL)handleReloadResponseData:(NSData *)responseData forController:(RequestController *)controller {
    
    
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:0];
//    NSLog(@"data: %@", data);
    
    
    if ([self.entity.name isEqualToString:@"Account"]) {
        
        if ([[(Asset *)self accountType] isEqualToString:@"SoundCloud"]) {
            
            if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionAccount) {
                [(Asset *)self loadSoundCloudAccountData:data];
                if (controller.reloadAll) {
                    [controller reloadAsset:self option:PRAXReloadOptionTracks];
                }
                else [controller reset];
            }
            
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionTracks) {
                Asset *asset;
                for (NSDictionary *item in data) {
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
                    NSArray *matchingItems = [controller.document.managedObjectContext executeFetchRequest:request error:nil];
                    if ([matchingItems count] < 1) {
                        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:controller.document.managedObjectContext];
                        asset.asset_id = [NSNumber numberWithInt:[item[@"id"] intValue]];
                        asset.batchPosition = [NSNumber numberWithInt:-1];
                    }
                    else asset = matchingItems[0];
                    asset.account = (Asset *)self;
                    asset.accountType = [(Asset *)self accountType];
                    
                    controller.determinate = YES;
                    controller.updateCount = controller.updateCount + 1;
                    [asset loadSoundCloudItemData:item];
                    [controller.document.tagController loadAssetTags:asset data:item];
                    asset.sync_mode = [NSNumber numberWithBool:FALSE];
                    [controller.document.changedAssetsController fetch:self];
                    
                }
                
                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAsset:self option:self.updateOption.unsignedIntegerValue];
                }
                else if (controller.reloadAll) {
                    controller.updateCount = 0;
                    controller.determinate = NO;
                    [controller reloadAsset:self option:PRAXReloadOptionPlaylists];
                }
                else [controller reset];
                
            }
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionPlaylists) {
                
                Asset *asset;
                for (NSDictionary *item in data) {
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"id"]]];
                    NSArray *matchingItems = [controller.document.managedObjectContext executeFetchRequest:request error:nil];
                    if ([matchingItems count] < 1) {
                        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:controller.document.managedObjectContext];
                        asset.asset_id = [NSNumber numberWithInt:[item[@"id"] intValue]];
                        asset.batchPosition = [NSNumber numberWithInt:-1];
                        
                    }
                    else asset = matchingItems[0];
                    asset.account = (Asset *)self;
                    asset.accountType = [(Asset *)self accountType];

                    controller.determinate = YES;
                    controller.updateCount = controller.updateCount + 1;
                    [asset loadSoundCloudItemData:item];
                    [asset loadPlaylistsAsset:asset data:item];
                    [controller.document.tagController loadAssetTags:asset data:item];
                    asset.sync_mode = [NSNumber numberWithBool:FALSE];
                    [controller.document.changedAssetsController fetch:self];
                    
                }
                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAsset:self option:self.updateOption.unsignedIntegerValue];
                }
                else [controller reset];
            }
            else return NO; // invalid option
        }
        
        
        else if ([[(Asset *)self accountType] isEqualToString:@"WordPress"]) {
            
            if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionAccount) {
                [(Asset *)self loadWordPressAccountData:data];
                if (controller.reloadAll) {
                    [controller reloadAsset:self option:PRAXReloadOptionSite];
                }
                else [controller reset];
            }
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionSite) {
                [(Asset *)self loadWordPressSiteData:data];
                if (controller.reloadAll) {
                    [controller reloadAsset:self option:PRAXReloadOptionPosts];
                }
                else [controller reset];
            }
            else if (self.updateOption.unsignedIntegerValue == PRAXReloadOptionPosts) {
                Asset *asset;
                for (NSDictionary *item in data[@"posts"]) {
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", item[@"ID"]]];
                    NSArray *matchingItems = [controller.document.managedObjectContext executeFetchRequest:request error:nil];
                    if ([matchingItems count] < 1) {
                        asset = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:controller.document.managedObjectContext];
                        asset.asset_id = [NSNumber numberWithInt:[item[@"ID"] intValue]];
                        asset.batchPosition = [NSNumber numberWithInt:-1];
                    }
                    else asset = matchingItems[0];
                    asset.account = (Asset *)self;
                    asset.accountType = [(Asset *)self accountType];

                    controller.determinate = YES;
                    controller.updateCount = controller.updateCount + 1;
                    [asset loadWordPressPostData:item];
                    [controller.document.tagController loadAssetTags:asset data:item];
                    asset.sync_mode = [NSNumber numberWithBool:FALSE];
                    [controller.document.changedAssetsController fetch:self];
                    
                }
                
                if (controller.updateCount < controller.targetCount) {
                    [controller reloadAsset:self option:self.updateOption.unsignedIntegerValue];
                }
                else [controller reset];
            }
            else return NO; // invalid option
        }
    }
    else {
        if (self.isSoundCloudAsset) {
            [self loadSoundCloudItemData:data];
            if (self.isPlaylist) [self loadPlaylistsAsset:self data:data];
        }
        else if (self.isWordPressAsset)[self loadWordPressPostData:data];
        else return NO; // invalid option
        
        [controller.document.tagController loadAssetTags:self data:data];
        self.sync_mode = [NSNumber numberWithBool:FALSE];
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
        else {
//            [controller reset];
        }
    }
    return YES;
    
}

-(void)loadWordPressPostData:(NSDictionary *)data {
    [self setValue:data forKey:@"metadata"];
    
    NSDictionary *keys = @{@"title":@"title", @"date":@"modified", @"artwork_url":@"featured_image", @"permalink_url":@"URL", @"type":@"type", @"permalink":@"slug", @"contents":@"content", @"sub_type":@"format", @"sharing":@"status"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
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

-(NSImage *)loadSoundCloudItemData:(NSDictionary *)data {
    
    [self setValue:data forKey:@"metadata"];
    
    
    for (NSString *key in @[@"title", @"purchase_url", @"purchase_title", @"permalink", @"permalink_url", @"sharing", @"uri", @"genre",
                            @"favoritings_count", @"playback_count", @"comment_count", @"download_count", @"duration"]) {
        if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[key] forKey:key];
    }
    /*    if (self.isTrack) {
     for (NSString *key in @[@"title", @"purchase_url", @"purchase_title", @"permalink", @"sharing", @"uri", @"genre",
     @"favoritings_count", @"play_count", @"comment_count", @"download_count", @"tag_list", @"duration"]) {
     if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
     else [self setValue:data[key] forKey:key];
     }
     }
     if (self.isPlaylist) {
     for (NSString *key in @[@"title", @"purchase_url", @"purchase_title", @"permalink", @"sharing", @"uri", @"genre",
     @"favoritings_count", @"play_count", @"comment_count", @"download_count", @"tag_list", @"duration"]) {
     if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
     else [self setValue:data[key] forKey:key];
     }
     }
     */
    
    
    NSDictionary *keys = @{@"date":@"created_at", @"contents":@"description"};
    for (NSString *key in keys) {
        if (data[[keys objectForKey:key]] == [NSNull null]) [self setValue:@"" forKey:key];
        else [self setValue:data[[keys objectForKey:key]] forKey:key];
    }
    if (self.date.length > 16) {
        self.date = [self.date substringToIndex:16];
    }
    
    if (self.isPlaylist) {
        self.type = @"playlist";
        for (NSString *key in @[@"playlist_type"]) {
            if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
            else [self setValue:data[key] forKey:@"sub_type"];
        }
    }
    else {
        self.type = @"track";
        for (NSString *key in @[@"track_type"]) {
            if (data[key] == [NSNull null]) [self setValue:@"" forKey:key];
            else [self setValue:data[key] forKey:@"sub_type"];
        }
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
        return image;
    }
    
    else return nil;
}

-(void)loadPlaylistsAsset:(Asset *)asset data:(NSDictionary *)data {
    Asset *subAsset;
    NSArray *subItems;
    NSError *error = nil;
    asset.associatedItems = nil;
    subItems = data[@"tracks"];
    NSMutableString *trackList = [[NSMutableString alloc] init];
    for (NSDictionary *subItem in subItems) {
        NSLog(@"subItem asset_id: %@", subItem[@"id"]);
        if (trackList.length > 0) [trackList appendString:@","];
        [trackList appendString:[subItem[@"id"] stringValue]];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", subItem[@"id"]]];
        NSArray *matchingItems = [asset.managedObjectContext executeFetchRequest:request error:&error];
        
        if ([matchingItems count] < 1) {
            NSLog(@"Error: - No matching Asset - subItem asset_id: %@", subItem[@"id"]);
        }
        else {
            subAsset = matchingItems[0];
            [asset addAssociatedItemsObject:subAsset];
        }
    }
    self.trackList = trackList.description;
}


/*
 
 - (BOOL)validateValue:(id *)value forKey:(NSString *)key error:(NSError **)error {
 BOOL result = [super validateValue:value forKey:key error:error];
 
 NSLog(@"Asset validateValue:%@ forKey:%@ error:%@", *value, key, *error);
 
 
 return result;
 
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
