//
//  Tracks.m
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "SoundCloudController.h"

@implementation SoundCloudController
@synthesize userDisplayButton;
@synthesize tracksDisplayButton;
@synthesize playlistsDisplayButton;
@synthesize document;
@synthesize changePurchaseURL;
@synthesize changePurchaseTitle;
@synthesize progressImageWell;
@synthesize assetController;
@synthesize tracksBatchEditController;
@synthesize tracksTableView;
@synthesize batchEditTabView;
@synthesize tracksProgress;
@synthesize soundCloudAuthorizationWindow;
@synthesize webView;


NSString *tracksNotificationName = @"tracksNotification";


- (id)init
{
    self = [super init];
    if (self) {
 //       NSLog(@"Tracks init");
        [[NSSound soundNamed:@"Start"] play];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self
                               selector:@selector(tracksNotification:)
                                   name:tracksNotificationName object:nil];
        
        
   //     [notificationCenter addObserver:self
     //                          selector:@selector(undoNotification:)
       //                            name:NSUndoManagerCheckpointNotification
         //                        object:[[document managedObjectContext] undoManager]];
        
    }
    
    return self;
}


- (void)awakeFromNib {
    
    [tracksTableView setDoubleAction:@selector(tableDoubleClickAction:)];
        
}





- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [[document managedObjectContext] undoManager];
}

- (IBAction)stopDownload:(id)sender {
    _stopFlag = TRUE;
}


- (IBAction)download:(id)sender {
    
    NSManagedObjectContext *moc = [document managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"com.soundcloud.api"]];
    
    NSError *error = nil;
    NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
    
    if ([matchingItems count] < 1) {
        _account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
        [_account setValue:@"com.soundcloud.api" forKey:@"accountType"];
        
    }
    else {
        _account = matchingItems[0];
    }
    
    SCAccount *scAccount = [SCSoundCloud account];
    
    if (!scAccount) {
         
        [SCSoundCloud requestAccessWithPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
            [soundCloudAuthorizationWindow makeKeyAndOrderFront:sender];
            [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
        }];
    }
    
    else {
        
        _stopFlag = FALSE;
        
        [tracksProgress setIndeterminate:TRUE];
        [_account setValue:[NSNumber numberWithBool:TRUE] forKey:@"updating"];
        [_account setValue:[NSNumber numberWithInt:0] forKey:@"update_offset"];
        
        
        NSLog(@"praxAction scAccount:%@", scAccount);
        id obj = [SCRequest performMethod:SCRequestMethodGET
                               onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me.json"]
                          usingParameters:nil
                              withAccount:scAccount
                   sendingProgressHandler:nil
                          responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                              // Handle the response
                              if (error) {
                                  NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
                              } else {
                                  // Check the statuscode and parse the data
                                  NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                  
                                  [self loadAccountWithData:data];
                             }
                          }];
        
        NSLog(@"praxAction obj:%@", obj);
    }
}

- (void)loadAccountWithData:(NSData *)data {
    
    NSError *__autoreleasing *jsonError = NULL;
    
    NSDictionary *me = [NSJSONSerialization JSONObjectWithData:data options:0 error:jsonError];
    
    NSLog(@"me: %@", me);
    
    [_account setValue:me[@"username"] forKey:@"username"];
    [_account setValue:me[@"permalink"] forKey:@"permalink"];
    [_account setValue:me[@"playlist_count"] forKey:@"playlist_count"];
    [_account setValue:me[@"track_count"] forKey:@"track_count"];
    [_account setValue:me[@"description"] forKey:@"contents"];
    [_account setValue:me[@"city"] forKey:@"city"];
    [_account setValue:me[@"country"] forKey:@"country"];
    [_account setValue:me[@"website"] forKey:@"website"];
    [_account setValue:me[@"website_title"] forKey:@"website_title"];
    if (me[@"avatar_url"] != [NSNull null]) {
        NSString *avatar_url = me[@"avatar_url"];
        NSArray *a = [avatar_url componentsSeparatedByString:@"-large.jpg"];
        avatar_url = [NSString stringWithString:(NSString *)a[0]];
        [_account setValue:avatar_url forKey:@"avatar_url"];
        
        avatar_url = [avatar_url stringByAppendingString:@"-t500x500.jpg"];
        
        NSURL *url = [NSURL URLWithString:avatar_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        [_account setValue:[NSArchiver archivedDataWithRootObject:image] forKey:@"image"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:tracksNotificationName object:nil];
    });
    
}


- (void)undoNotification:(NSNotification *)notification
{
    NSObject *notificationObject = [notification object];
    NSLog(@"undoNotification notification: %@ notificationObject: %@", notification, notificationObject);
}


- (void)refreshTrack:(Track *)track {
    _stopFlag = FALSE;
    
    NSManagedObjectContext *moc = [document managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"com.soundcloud.api"]];
    
    NSError *error = nil;
    NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
    
    if ([matchingItems count] < 1) {
        _account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
        [_account setValue:@"com.soundcloud.api" forKey:@"accountType"];
        
    }
    else {
        _account = matchingItems[0];
    }
    
    SCAccount *scAccount = [SCSoundCloud account];
    if (scAccount) {
        [tracksProgress setIndeterminate:TRUE];
        [_account setValue:[NSNumber numberWithBool:TRUE] forKey:@"updating"];
        [_account setValue:[_account valueForKey:@"track_count"] forKey:@"update_offset"];
        NSString *url = [NSString stringWithFormat:@"https://api.soundcloud.com/tracks/%@.json", [track valueForKey:@"asset_id"]];
        id obj = [SCRequest performMethod:SCRequestMethodGET
                               onResource:[NSURL URLWithString:url]
                          usingParameters:@{@"limit":@"1", @"offset":[[_account valueForKey:@"update_offset"] stringValue]}
                              withAccount:scAccount
                   sendingProgressHandler:nil
                          responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                              // Handle the response
                              if (error) {
                                  NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
                              } else {
                                  // Check the statuscode and parse the data
                                  NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                  
                                  [self loadTrackWithData:data];
                                  
                              }
                          }];
        
        NSLog(@"praxAction obj:%@", obj);
    }
    
    
}


- (void)uploadTrackData:(Track *)track {
    _stopFlag = FALSE;
    
    NSManagedObjectContext *moc = [document managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"com.soundcloud.api"]];
    
    NSError *error = nil;
    NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
    
    if ([matchingItems count] < 1) {
        _account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
        [_account setValue:@"com.soundcloud.api" forKey:@"accountType"];
        
    }
    else {
        _account = matchingItems[0];
    }
    
    SCAccount *scAccount = [SCSoundCloud account];
    if (scAccount) {
        [tracksProgress setIndeterminate:TRUE];
        [_account setValue:[NSNumber numberWithBool:TRUE] forKey:@"updating"];
        [_account setValue:[_account valueForKey:@"track_count"] forKey:@"update_offset"]; // flag to finish updating
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
        
        for (NSString *key in @[@"title", @"purchase_title", @"purchase_url"]) {
            
            NSString *key_x = [NSString stringWithFormat:@"%@_x", key];
            NSString *track_key = [NSString stringWithFormat:@"track[%@]", key];
            
            if (![[track valueForKey:key] isEqualToString:[track valueForKey:key_x]]) {
                [parameters setObject:[track valueForKey:key] forKey:track_key];
            }
        }
        
        
        NSLog(@"praxAction parameters:%@", parameters);
        
        id obj2 = [SCRequest performMethod:SCRequestMethodPUT
                                onResource:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.soundcloud.com/tracks/%@", [track valueForKey:@"asset_id"]]]
                           usingParameters:parameters
                               withAccount:scAccount
                    sendingProgressHandler:nil
                           responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                               // Handle the response
                               if (error) {
                                   NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
                               } else {
                                   
                                   // Check the statuscode and parse the data
                        //           NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                   
                                   NSLog(@"responseHandler response statusCode: %ld", [(NSHTTPURLResponse *)response statusCode]);
                                   
                       //            NSError *__autoreleasing *jsonError = NULL;
                       //            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments + NSJSONReadingMutableLeaves + NSJSONReadingMutableContainers) error:jsonError];
                                   
                                //   NSLog(@"responseHandler jsonError:%@", jsonError);
                                   
                           //        NSLog(@"responseHandler responseObject:%@", responseObject);
                                   
                                   
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [self refreshTrack:track];
                                   });
                                   
                               }
                               
                           }];
        
        
        
        NSLog(@"praxAction obj2:%@", obj2);
        
        
    }
    
    
}


- (void)tracksNotification:(NSNotification *)notification
{
    NSObject *notificationObject = [notification object];
    NSLog(@"tracksNotification %@", notificationObject);
    
    int update_offset = [[_account valueForKey:@"update_offset"] intValue];
    int track_count = [[_account valueForKey:@"track_count"] intValue];

    if ((track_count > update_offset) && (_stopFlag == FALSE)) {
        
        SCAccount *scAccount = [SCSoundCloud account];
        if (scAccount) {
            
            [tracksProgress setIndeterminate:FALSE];
            id obj2 = [SCRequest performMethod:SCRequestMethodGET
                                    onResource:[NSURL URLWithString:@"https://api.soundcloud.com/me/tracks.json"]
                               usingParameters:@{@"limit":@"1", @"offset":[[_account valueForKey:@"update_offset"] stringValue]}
                                   withAccount:scAccount
                        sendingProgressHandler:nil
                               responseHandler:^(NSURLResponse *response, NSData *data, NSError *error){
                                   // Handle the response
                                   if (error) {
                                       NSLog(@"Ooops, something went wrong: %@", [error localizedDescription]);
                                   } else {
                                       // Check the statuscode and parse the data
                                       //        NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, data, error);
                                       
                                       [self loadTracksWithData:data];
                                       
                                   }
                               }];
            
            NSLog(@"praxAction obj2:%@", obj2);
        }
    }
    else {
        [_account setValue:[NSNumber numberWithBool:FALSE] forKey:@"updating"];
        
    }
}

- (void)loadTracksWithData:(NSData *)data {
    
    NSError *__autoreleasing *jsonError = NULL;
    NSArray *tracks = [NSJSONSerialization JSONObjectWithData:data options:0 error:jsonError];
    
    NSLog(@"tracks: %@", tracks);
    
    NSError *error = nil;
    NSManagedObject *scTrack = nil;
    
    for (NSDictionary *track in tracks) {
        NSLog(@"asset_id: %@", track[@"id"]);
        
        NSManagedObjectContext *moc = [document managedObjectContext];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", track[@"id"]]];
        NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
        
        if ([matchingItems count] < 1) {
            scTrack = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:moc];
            [scTrack setValue:track[@"id"] forKey:@"asset_id"];
        }
        else {
            scTrack = matchingItems[0];
        }
        
        [scTrack setValue:track[@"title"] forKey:@"title"];
        [scTrack setValue:track[@"title"] forKey:@"title_x"];
        
        if (track[@"purchase_url"] != [NSNull null]) {
            [scTrack setValue:track[@"purchase_url"] forKey:@"purchase_url"];
            [scTrack setValue:track[@"purchase_url"] forKey:@"purchase_url_x"];
        }
        if (track[@"purchase_title"] != [NSNull null]) {
            [scTrack setValue:track[@"purchase_title"] forKey:@"purchase_title"];
            [scTrack setValue:track[@"purchase_title"] forKey:@"purchase_title_x"];
        }
        
        
        if (track[@"artwork_url"] != [NSNull null]) {
            NSString *artwork_url = track[@"artwork_url"];
            NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
            artwork_url = [NSString stringWithString:(NSString *)a[0]];
            [scTrack setValue:artwork_url forKey:@"artwork_url"];
            artwork_url = [artwork_url stringByAppendingString:@"-original.jpg"];
            NSURL *url = [NSURL URLWithString:artwork_url];
            NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
            [progressImageWell setImage:image];
            [scTrack setValue:[NSArchiver archivedDataWithRootObject:image] forKey:@"image"];
        }
        [scTrack setValue:track[@"uri"] forKey:@"uri"];
        [scTrack setValue:FALSE forKey:@"sync_mode"];
        
        int update_offset = ([[_account valueForKey:@"update_offset"] intValue] + 1);
        [_account setValue:[NSNumber numberWithInt:update_offset] forKey:@"update_offset"];
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:tracksNotificationName object:nil];
    });
    
}
- (void)loadTrackWithData:(NSData *)data {
    
    NSError *__autoreleasing *jsonError = NULL;
    NSDictionary *track = [NSJSONSerialization JSONObjectWithData:data options:0 error:jsonError];
    
    NSLog(@"track: %@", track);
    
    NSError *error = nil;
    NSManagedObject *scTrack = nil;
    
    NSLog(@"asset_id: %@", track[@"id"]);
    
    NSManagedObjectContext *moc = [document managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"asset_id", track[@"id"]]];
    NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
    
    if ([matchingItems count] < 1) {
        scTrack = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:moc];
        [scTrack setValue:track[@"id"] forKey:@"asset_id"];
    }
    else {
        scTrack = matchingItems[0];
    }
    
    [scTrack setValue:track[@"title"] forKey:@"title"];
    [scTrack setValue:track[@"title"] forKey:@"title_x"];
    
    if (track[@"purchase_url"] != [NSNull null]) {
        [scTrack setValue:track[@"purchase_url"] forKey:@"purchase_url"];
        [scTrack setValue:track[@"purchase_url"] forKey:@"purchase_url_x"];
    }
    if (track[@"purchase_title"] != [NSNull null]) {
        [scTrack setValue:track[@"purchase_title"] forKey:@"purchase_title"];
        [scTrack setValue:track[@"purchase_title"] forKey:@"purchase_title_x"];
    }
    
    
    if (track[@"artwork_url"] != [NSNull null]) {
        NSString *artwork_url = track[@"artwork_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        [scTrack setValue:artwork_url forKey:@"artwork_url"];
        artwork_url = [artwork_url stringByAppendingString:@"-original.jpg"];
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        [progressImageWell setImage:image];
        [scTrack setValue:[NSArchiver archivedDataWithRootObject:image] forKey:@"image"];
    }
    [scTrack setValue:track[@"uri"] forKey:@"uri"];
    [scTrack setValue:FALSE forKey:@"sync_mode"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:tracksNotificationName object:nil];
    });
    
}
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    Track *obj = [[self.assetController arrangedObjects] objectAtIndex:row];
    return [[obj valueForKey:@"info_mode"] boolValue] ? 120.0 : 20.0;
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    TrackView *view;
    Track *asset = [[assetController arrangedObjects] objectAtIndex:row];
    NSLog(@"asset.entity.name: %@", asset.entity.name);

    if ([asset.entity.name isEqualToString:@"Account"]) {
        NSLog(@"UserView");
        view = [tableView makeViewWithIdentifier:@"UserView" owner:self];
    }
    else {
        NSLog(@"TrackView");
        view = [tableView makeViewWithIdentifier:@"TrackView" owner:self];
    }
    [view layoutViewsForObjectModeAnimate:FALSE];
    return view;
}


- (void)tableDoubleClickAction:(id)sender {
    
    TrackView *cellView = [sender viewAtColumn:[sender clickedColumn] row:[sender clickedRow] makeIfNecessary:TRUE];
    [cellView cellDoubleClickAction:(id)sender];
    
}

- (IBAction)infoModeButtonClicked:(id)sender {
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    
    TrackView *cellView = (TrackView *)[sender superview];
    [cellView layoutViewsForObjectModeAnimate:TRUE];
    
    NSInteger row = [tracksTableView rowForView:cellView];
    [tracksTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
    [NSAnimationContext endGrouping];
    
    
}

- (IBAction)editModeButtonClicked:(id)sender {
    
    [tracksBatchEditController rearrangeObjects];
    
}

- (NSPredicate *)batchEditFilterPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"edit_mode == YES"];
    return predicate;
}

- (IBAction)userButtonClicked:(id)sender {
    NSPredicate *predicate;
    if ([sender state] == 1)  {
        if (([playlistsDisplayButton state] + [tracksDisplayButton state]) == 2) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Playlist\" OR entity.name == \"Account\""];
        }
        else {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Account\""];
            [tracksDisplayButton setState:FALSE];
            [playlistsDisplayButton setState:FALSE];
        }
    }
    else {
        if (([playlistsDisplayButton state] + [tracksDisplayButton state]) == 2) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Playlist\""];
        }
        else if ([playlistsDisplayButton state] == 1) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Playlist\""];
        }
        else {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\""];
            [tracksDisplayButton setState:TRUE];
        }
    }
    [assetController setFetchPredicate:predicate];
    [assetController rearrangeObjects];
}

- (IBAction)tracksButtonClicked:(id)sender {
    NSPredicate *predicate;
    
    if ([sender state] == 1)  {
        
        if (([playlistsDisplayButton state] + [userDisplayButton state]) == 2) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Playlist\" OR entity.name == \"Account\""];
        }
        else if ([playlistsDisplayButton state] == 1) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Playlist\""];
        }
//        else if ([userDisplayButton state] == 1) {
  //          predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Account\""];
    //    }
        else {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\""];
            [userDisplayButton setState:FALSE];
        }
        
    }
    else {
        if (([playlistsDisplayButton state] + [userDisplayButton state]) == 2) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Playlist\" OR entity.name == \"Account\""];
        }
        else if ([playlistsDisplayButton state] == 1) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Playlist\""];
        }
        else {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Account\""];
            [userDisplayButton setState:TRUE];
        }
    }
    [assetController setFetchPredicate:predicate];
    [assetController rearrangeObjects];
}

- (IBAction)playlistsButtonClicked:(id)sender {
    NSPredicate *predicate;
    
    if ([sender state] == 1)  {
        
        if (([tracksDisplayButton state] + [userDisplayButton state]) == 2) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Playlist\" OR entity.name == \"Account\""];
        }
        else if ([tracksDisplayButton state] == 1) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Playlist\""];
        }
//        else if ([userDisplayButton state] == 1) {
//            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Account\" OR entity.name == \"Playlist\""];
//        }
        else {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Playlist\""];
            [userDisplayButton setState:FALSE];
        }
        
    }
    else {
        if (([tracksDisplayButton state] + [userDisplayButton state]) == 2) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\" OR entity.name == \"Account\""];
        }
        else if ([tracksDisplayButton state] == 1) {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Track\""];
        }
        else {
            predicate = [NSPredicate predicateWithFormat: @"entity.name == \"Account\""];
            [userDisplayButton setState:TRUE];
        }
    }
    [assetController setFetchPredicate:predicate];
    [assetController rearrangeObjects];
}


- (IBAction)addBatchButtonClicked:(id)sender {
    NSArray *tracks = [self.assetController arrangedObjects];
    NSManagedObject *track;
    for (NSInteger row = 0; row < [tracks count]; row++) {
        track = tracks[row];
        [track setValue:[NSNumber numberWithBool:TRUE] forKey:@"edit_mode"];
        //  NSLog(@"track: %@", track);
    }
    [tracksBatchEditController rearrangeObjects];
}

- (IBAction)removeBatchButtonClicked:(id)sender {
    NSArray *tracks = [self.assetController arrangedObjects];
    NSManagedObject *track;
    for (NSInteger row = 0; row < [tracks count]; row++) {
        track = tracks[row];
        [track setValue:[NSNumber numberWithBool:FALSE] forKey:@"edit_mode"];
        //  NSLog(@"track: %@", track);
    }
    [tracksBatchEditController rearrangeObjects];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    id identifier = [tabViewItem identifier];
    [batchEditTabView selectTabViewItemWithIdentifier:identifier];
}


- (IBAction)copyPurchaseTitle:(id)sender {
    [changePurchaseTitle setStringValue:[sender title]];
}

- (IBAction)copyPurchaseURL:(id)sender {
    [changePurchaseURL setStringValue:[sender title]];
}

- (IBAction)expandView:(id)sender {
    NSInteger expand = [sender state];
    BOOL flag = (expand == 0) ? FALSE : TRUE;
    
    NSLog(@"expand: %ld", expand);
    NSLog(@"flag: %hhd", flag);
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    
    NSMutableIndexSet *rows = [[NSMutableIndexSet alloc] init];
    NSArray *tracks = [self.assetController arrangedObjects];
    NSManagedObject *track;
    TrackView *cellView;
    for (NSInteger row = 0; row < [tracks count]; row++) {
        track = tracks[row];
        [track setValue:[NSNumber numberWithBool:flag] forKey:@"info_mode"];
        cellView = [tracksTableView viewAtColumn:0 row:row makeIfNecessary:NO];
        if (cellView) {
            [cellView layoutViewsForObjectModeAnimate:TRUE];
        }
        [rows addIndex:row];
        
        //  NSLog(@"track: %@", track);
    }
    [tracksTableView noteHeightOfRowsWithIndexesChanged:rows];

    [NSAnimationContext endGrouping];
}


@end
