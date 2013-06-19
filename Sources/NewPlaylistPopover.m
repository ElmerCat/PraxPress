//
//  NewPlaylistPopover.m
//  PraxPress
//
//  Created by Elmer on 1/19/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "NewPlaylistPopover.h"

@interface NewPlaylistPopover ()

@end

@implementation NewPlaylistPopover

- (void)awakeFromNib {
    
    if (!self.awake) {
        self.awake = TRUE;
        
        NSLog(@"NewPlaylistPopover awakeFromNib");
        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"NSPopoverDidShowNotification" object:self.popover queue:nil usingBlock:^(NSNotification *aNotification){

            if (!self.asset) {
                
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"asset_id == 0"]];
                NSArray *matchingItems = [self.filesOwner.managedObjectContext executeFetchRequest:request error:nil];
                if ([matchingItems count] > 0) self.asset = matchingItems[0];
                else {
                    self.asset = [NSEntityDescription insertNewObjectForEntityForName:@"Playlist" inManagedObjectContext:self.filesOwner.managedObjectContext];
                    self.asset.title = @"New Playlist";
                    self.asset.purchase_title = @"Purchase Title";
                    self.asset.purchase_url = @"http://";
                    self.asset.permalink = @"new-playlist";
                    self.asset.sharing = @"private";
                    self.asset.sub_type = @"other";
                    self.asset.genre = @"Genre";
                    self.asset.type = @"playlist";
                }
                
            }
            
            if (!self.asset.account) {
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"SoundCloud"]];
                NSArray *matchingItems = [self.filesOwner.managedObjectContext executeFetchRequest:request error:nil];
                if ([matchingItems count] < 1) [[NSSound soundNamed:@"Error"] play];
                else self.asset.account = matchingItems[0];
            }
            
            NSMutableString *trackList = [[NSMutableString alloc] init];
            for (Asset *asset in self.batchAssetsController.arrangedObjects) {
                if (trackList.length > 0) [trackList appendString:@","];
                if ([asset.entity.name isEqualToString:@"Track"]) [trackList appendString:[asset.asset_id stringValue]];
            }
            if (trackList.length > 0) {
                self.asset.trackList = trackList.description;
            }
            else [self.popover performClose:self];

        }];

        
    }
}

-(void)dealloc {
    NSLog(@"dealloc NewPlaylistPopover");
    
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    NSLog(@"controlTextDidChange NewPlaylistPopover");
    //        if( amDoingAutoComplete ){
    //          return;
    //    } else {
    //      amDoingAutoComplete = YES;
    //      [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
    //}
}

- (IBAction)show:(id)sender {
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinXEdge];
}


- (IBAction)save:(id)sender {
    
    [TagController setAssetTagList:self.asset];
    
    [self.filesOwner.updateController uploadAsset:self.asset];
    

}


@end
