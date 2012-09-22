//
//  Tracks.m
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "SoundCloudController.h"

@implementation SoundCloudController

NSString *tracksNotificationName = @"tracksNotification";

-(Asset *)account {
    if (! _userAccount) {
        NSManagedObjectContext *moc = [self.document managedObjectContext];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"com.soundcloud.api"]];
        NSError *error = nil;
        NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
        if ([matchingItems count] < 1) {
            [moc processPendingChanges]; 
            [[moc undoManager] disableUndoRegistration];
            _userAccount = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
            [_userAccount setValue:@"com.soundcloud.api" forKey:@"accountType"];
            [moc processPendingChanges];
            [[moc undoManager] enableUndoRegistration];
        }
        else _userAccount = matchingItems[0];
    }
    return _userAccount;
}

- (id)init {
    self = [super init];
    if (self) {
 //       NSLog(@"SoundCloudController init");
 //       [[NSSound soundNamed:@"Start"] play];

//        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
 //       [notificationCenter addObserver:self
 //                              selector:@selector(tracksNotification:)
 //                                  name:tracksNotificationName object:nil];
    //     [notificationCenter addObserver:self
     //                          selector:@selector(undoNotification:)
       //                            name:NSUndoManagerCheckpointNotification
         //                        object:[[document managedObjectContext] undoManager]];
    }
    return self;
}


- (void)awakeFromNib {
    
    [self.tracksTableView setDoubleAction:@selector(tableDoubleClickAction:)];
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender {
    return [[self.document managedObjectContext] undoManager];
}

- (void)undoNotification:(NSNotification *)notification {
    NSObject *notificationObject = [notification object];
    NSLog(@"undoNotification notification: %@ notificationObject: %@", notification, notificationObject);
}

- (IBAction)refresh:(id)sender {
    self.updateController.updateMode = UpdateModeSoundCloud;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}

- (IBAction)upload:(id)sender {
    self.updateController.updateMode = UpdateModeAssets;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}

- (IBAction)logout:(id)sender {
    [[NSSound soundNamed:@"Connect"] play];
//    [self.removeAccessForAccountType:@"com.soundcloud.api"];
    
}

- (IBAction)refreshTrack:(id)sender {
    self.updateController.updateMode = UpdateModeTrack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}

- (IBAction)uploadTrack:(id)sender {
    self.updateController.updateMode = UpdateModeUploadTrack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}
- (IBAction)refreshPlaylist:(id)sender {
    self.updateController.updateMode = UpdateModePlaylist;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}

- (IBAction)uploadPlaylist:(id)sender {
    self.updateController.updateMode = UpdateModeUploadPlaylist;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}

- (IBAction)editModeButtonClicked:(id)sender {
    
    [self.assetBatchEditController rearrangeObjects];
    
}


- (NSPredicate *)batchEditFilterPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"edit_mode == YES"];
    return predicate;
}

- (IBAction)addTracksBatchButtonClicked:(id)sender {
    NSArray *items = [self.tracksController arrangedObjects];
    Asset *item;
    for (NSInteger row = 0; row < [items count]; row++) {
        item = items[row];
        [item setValue:[NSNumber numberWithBool:TRUE] forKey:@"edit_mode"];
        //  NSLog(@"item: %@", item);
    }
    [self.assetBatchEditController rearrangeObjects];
}

- (IBAction)removeTracksBatchButtonClicked:(id)sender {
    NSArray *items = [self.tracksController arrangedObjects];
    Asset *item;
    for (NSInteger row = 0; row < [items count]; row++) {
        item = items[row];
        [item setValue:[NSNumber numberWithBool:FALSE] forKey:@"edit_mode"];
        //  NSLog(@"item: %@", item);
    }
    [self.assetBatchEditController rearrangeObjects];
}

- (IBAction)addPlaylistsBatchButtonClicked:(id)sender {
    NSArray *items = [self.playlistsController arrangedObjects];
    Asset *item;
    for (NSInteger row = 0; row < [items count]; row++) {
        item = items[row];
        [item setValue:[NSNumber numberWithBool:TRUE] forKey:@"edit_mode"];
        //  NSLog(@"item: %@", item);
    }
    [self.assetBatchEditController rearrangeObjects];
}

- (IBAction)removePlaylistsBatchButtonClicked:(id)sender {
    NSArray *items = [self.playlistsController arrangedObjects];
    Asset *item;
    for (NSInteger row = 0; row < [items count]; row++) {
        item = items[row];
        [item setValue:[NSNumber numberWithBool:FALSE] forKey:@"edit_mode"];
        //  NSLog(@"item: %@", item);
    }
    [self.assetBatchEditController rearrangeObjects];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    id identifier = [tabViewItem identifier];
    [self.batchEditTabView selectTabViewItemWithIdentifier:identifier];
}




@end
