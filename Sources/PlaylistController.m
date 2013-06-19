//
//  PlaylistController.m
//  PraxPress
//
//  Created by Elmer on 1/18/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "PlaylistController.h"

@implementation PlaylistController


- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"PlaylistController init");
        
//        [self addObserver:self forKeyPath:@"self.document.associatedAssetsController.arrangedObjects" options:NSKeyValueObservingOptionNew context:0];
        [self addObserver:self forKeyPath:@"self.document.assetsController.selectionIndex" options:NSKeyValueObservingOptionNew context:0];
        
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc PlaylistController");
//    [self removeObserver:self forKeyPath:@"self.document.associatedAssetsController.arrangedObjects"];
    [self removeObserver:self forKeyPath:@"self.document.assetsController.selectionIndex"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    NSLog(@"PlaylistController awakeFromNib");
    
    [self.document.associatedAssetsTableView registerForDraggedTypes:@[@"PraxItemsDropType"]];
    [self.document.associatedAssetsTableView setSortDescriptors:self.playlistSortDescriptors];
    
//    [[NSNotificationCenter defaultCenter] addObserverForName:@"AssociatedAssetChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
  //      NSLog(@"AssociatedAssetChangedNotification aNotification: %@", aNotification);
        
    //}];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"self.document.associatedAssetsController.arrangedObjects"]) {
        NSLog(@"PlaylistController observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    
  
    }
    
    else if ([keyPath isEqualToString:@"self.document.assetsController.selectionIndex"]) {
        if (self.document.assetsController.selectionIndex != NSNotFound) {
            Asset *playlist = self.document.assetsController.arrangedObjects[self.document.assetsController.selectionIndex];
            if ([playlist.type isEqualToString:@"playlist"]) {
                NSSet *tracks = playlist.associatedItems;
                NSMutableDictionary *trackIndex = [NSMutableDictionary dictionaryWithCapacity:8];
                for (Asset *track in tracks) {
                    trackIndex[track.asset_id.stringValue] = track;
                }
                NSArray *trackIDs = [playlist.trackList componentsSeparatedByString:@","];
                int count = 0;
                for (NSString *trackID in trackIDs) {
                    Asset *track = trackIndex[trackID];
                    track.playlistPosition = [NSNumber numberWithInt:count];
                    count++;
                }
            }
        }
 //       [[NSNotificationCenter defaultCenter] postNotificationName:@"AssociatedAssetChangedNotification" object:self];
        
    }
    
    else {

    }
}





- (NSArray *)playlistSortDescriptors {
	if( self._playlistSortDescriptors == nil )
	{
		self._playlistSortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"playlistPosition" ascending:YES]];
	}
	return self._playlistSortDescriptors;
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pasteboard declareTypes:@[@"PraxItemsDropType"] owner:self];
	[pasteboard setData:data forType:@"PraxItemsDropType"];
	return YES;
}
- (NSDragOperation)tableView:(NSTableView*)table validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (([info draggingSource] == self.document.associatedAssetsTableView) || ([info draggingSource] == self.document.associatedAssetsTableView)) {
        NSArray *sortDescriptors = [self.document.associatedAssetsController sortDescriptors];
        if ([sortDescriptors count] > 0) {
            if ([[sortDescriptors[0] key] isEqualToString:@"playlistPosition"]) {
                if (operation == NSTableViewDropOn) [table setDropRow:row dropOperation:NSTableViewDropAbove];
                return NSDragOperationMove;
            }
        }
	}
    return NSDragOperationNone;
}
- (BOOL)tableView:(NSTableView *)table acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	NSData *rowData = [pasteboard dataForType:@"PraxItemsDropType"];
	NSIndexSet *draggedItems = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
	NSArray *allItemsArray = [[self.document.associatedAssetsController arrangedObjects] copy];
    NSMutableIndexSet *allItems = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [allItemsArray count])];
    NSMutableIndexSet *firstItems = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *lastItems = [NSMutableIndexSet indexSet];
    [allItems removeIndexes:draggedItems];
    [allItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < row) [firstItems addIndex:idx];
        else [lastItems addIndex:idx];
    }];
    
    __block NSUInteger newRow = 0;
    [firstItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Asset *asset = allItemsArray[idx];
        asset.playlistPosition = [NSNumber numberWithInteger:newRow];
        newRow++;
    }];
    [draggedItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Asset *asset = allItemsArray[idx];
        asset.playlistPosition = [NSNumber numberWithInteger:newRow];
        newRow++;
    }];
    [lastItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Asset *asset = allItemsArray[idx];
        asset.playlistPosition = [NSNumber numberWithInteger:newRow];
        newRow++;
    }];
    [self.document.associatedAssetsController rearrangeObjects];
    [self changePlaylistOrder:self];
  	return YES;
}



- (IBAction)changePlaylistOrder:(id)sender {
    
    Asset *playlist = self.document.assetsController.arrangedObjects[self.document.assetsController.selectionIndex];
    if ([playlist.type isEqualToString:@"playlist"]) {
        
        NSMutableArray *trackIDs = [NSMutableArray array];
        for (Asset *asset in self.document.associatedAssetsController.arrangedObjects) {
            [trackIDs addObject:asset.asset_id.stringValue];
        }
        NSString *trackList = [trackIDs componentsJoinedByString:@","];
        playlist.trackList = trackList;
    
    }
    
}


- (IBAction)setPlaylistTracksFromBatch:(id)sender {
    
    if (self.document.assetsController.selectionIndex != NSNotFound) {
        Asset *playlist = self.document.assetsController.arrangedObjects[self.document.assetsController.selectionIndex];
        if ([playlist.type isEqualToString:@"playlist"]) {
            
            NSMutableArray *trackIDs = [NSMutableArray array];
            NSMutableSet *tracks = [NSMutableSet set];
            int count = 0;
            for (Asset *asset in self.document.batchAssetsController.arrangedObjects) {
                if ([asset.entity.name isEqualToString:@"Track"]) {
                    [tracks addObject:asset];
                    asset.playlistPosition = [NSNumber numberWithInt:count];
                    [trackIDs addObject:asset.asset_id.stringValue];
                    count++;
                }
                
            }
            if (tracks.count) {
                NSString *trackList = [trackIDs componentsJoinedByString:@","];
                playlist.trackList = trackList;
                playlist.associatedItems = tracks;
            }
        }
    }
}


- (IBAction)addAssociatedAssetsToBatch:(id)sender {
    for (Asset *asset in self.document.associatedAssetsController.arrangedObjects) {
        asset.edit_mode = @YES;
    }
    [self.document.batchAssetsController rearrangeObjects];
}

- (IBAction)removeAssociatedAssetsFromBatch:(id)sender {
    for (Asset *asset in self.document.associatedAssetsController.arrangedObjects) {
        asset.edit_mode = @NO;
    }
    [self.document.batchAssetsController rearrangeObjects];
}






@end
