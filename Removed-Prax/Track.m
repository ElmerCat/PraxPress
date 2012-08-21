//
//  Track.m
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Track.h"


@implementation Track

@dynamic title;
@dynamic artwork_url;
@dynamic uri;
@dynamic asset_id;
@dynamic info_mode;
@dynamic account;

@end




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

- (IBAction)download:(id)sender {
    
    
    SCAccount *scAccount = [SCSoundCloud account];
    
    if (scAccount) {
        
        _stopFlag = FALSE;
        
        [tracksProgress setIndeterminate:TRUE];
        [userAccountController.account setValue:[NSNumber numberWithBool:TRUE] forKey:@"updating"];
        [userAccountController.account setValue:[NSNumber numberWithInt:0] forKey:@"update_offset"];
        
        
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
    
    NSDictionary *asset = [NSJSONSerialization JSONObjectWithData:data options:0 error:jsonError];
    
    NSLog(@"asset: %@", asset);
    
    [userAccountController.account setValue:asset[@"full_name"] forKey:@"title"];
    [userAccountController.account setValue:asset[@"id"] forKey:@"asset_id"];
    [userAccountController.account setValue:asset[@"username"] forKey:@"username"];
    [userAccountController.account setValue:asset[@"permalink"] forKey:@"permalink"];
    [userAccountController.account setValue:asset[@"playlist_count"] forKey:@"playlist_count"];
    [userAccountController.account setValue:asset[@"track_count"] forKey:@"track_count"];
    [userAccountController.account setValue:asset[@"description"] forKey:@"contents"];
    [userAccountController.account setValue:asset[@"city"] forKey:@"city"];
    [userAccountController.account setValue:asset[@"country"] forKey:@"country"];
    [userAccountController.account setValue:asset[@"website"] forKey:@"purchase_url"];
    [userAccountController.account setValue:asset[@"website_title"] forKey:@"purchase_title"];
    if (asset[@"avatar_url"] != [NSNull null]) {
        NSString *artwork_url = asset[@"avatar_url"];
        NSArray *a = [artwork_url componentsSeparatedByString:@"-large.jpg"];
        artwork_url = [NSString stringWithString:(NSString *)a[0]];
        [userAccountController.account setValue:artwork_url forKey:@"artwork_url"];
        
        artwork_url = [artwork_url stringByAppendingString:@"-t500x500.jpg"];
        
        NSURL *url = [NSURL URLWithString:artwork_url];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
        [userAccountController.account setValue:[NSArchiver archivedDataWithRootObject:image] forKey:@"image"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:tracksNotificationName object:nil];
    });
    
}



@property (weak) IBOutlet NSButton *userDisplayButton;
@property (weak) IBOutlet NSButton *tracksDisplayButton;
@property (weak) IBOutlet NSButton *playlistsDisplayButton;

- (IBAction)tableDoubleClickAction:(id)sender;
- (IBAction)userButtonClicked:(id)sender;
- (IBAction)tracksButtonClicked:(id)sender;
- (IBAction)playlistsButtonClicked:(id)sender;
- (IBAction)expandView:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)infoModeButtonClicked:(id)sender;
