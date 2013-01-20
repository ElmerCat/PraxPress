//
//  PlaylistController.h
//  PraxPress
//
//  Created by Elmer on 1/18/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"



@interface PlaylistController : NSObject



@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSTableView *associatedAssetsTableView;
@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet NSArrayController *associatedAssetsController;
@property (weak) IBOutlet NSArrayController *batchAssetsController;
@property NSArray *_playlistSortDescriptors;
- (NSArray *)playlistSortDescriptors;

- (IBAction)addAssociatedAssetsToBatch:(id)sender;
- (IBAction)removeAssociatedAssetsFromBatch:(id)sender;
- (IBAction)changePlaylistOrder:(id)sender;
- (IBAction)setPlaylistTracksFromBatch:(id)sender;

@end
