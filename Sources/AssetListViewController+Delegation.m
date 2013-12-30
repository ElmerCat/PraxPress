//
//  AssetListViewController+Delegation.m
//  PraxPress
//
//  Created by Elmer on 12/25/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetListViewController+Delegation.h"

@implementation AssetListViewController (Delegation)


/*- (CGFloat)assetListMinHeight {return 100;}
 - (CGFloat)detailViewMinHeight {return 50;}
 - (CGFloat)codeViewMinHeight {return 30;}
 - (CGFloat)webViewMinHeight {return 20;}
 
 
 - (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
 
 CGFloat min = 0;
 if (dividerIndex == 0) min = self.assetListMinHeight;
 else if (dividerIndex == 1) min = (self.detailViewMinHeight + self.assetListPane.frame.size.height);
 else if (dividerIndex == 2) min = (self.codeViewMinHeight + self.assetListPane.frame.size.height + self.detailViewPane.frame.size.height);
 else min = (self.webViewMinHeight + self.assetListPane.frame.size.height + self.detailViewPane.frame.size.height + self.codeViewPane.frame.size.height);
 
 if (proposedMin < min) return min;
 else return proposedMin;
 
 }
 */

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    NSRect effectiveRect = proposedEffectiveRect;
    // effectiveRect.origin.x -= 2.0;
    if (splitView.isVertical) {
        effectiveRect.origin.x -= 5.0;
        effectiveRect.size.width += 10.0;
    }
    //    else {
    //        effectiveRect.origin.y -= 5.0;
    //        effectiveRect.size.height += 10.0;
    //    }
    
    return effectiveRect;
}
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    if ([self.splitView isSubviewCollapsed:self.detailViewPane]) {
        if (self.showDetailView) self.showDetailView = NO;
    }
    else if (self.detailViewPane.frame.size.height < 10) {
        if (self.showDetailView) self.showDetailView = NO;
    }
    else {
        if (!self.showDetailView) self.showDetailView = YES;
    }
}


- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
    NSMutableArray * objects = [NSMutableArray array];
    NSArray * draggedObjects = [self.assetArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
    for (NSManagedObject * o in draggedObjects) {
        [objects addObject:[[o objectID] URIRepresentation]];
    }
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:objects];
	[pasteboard declareTypes:[NSArray arrayWithObject:@"PraxItemsDropType"] owner:self];
	[pasteboard setData:data forType:@"PraxItemsDropType"];
	return YES;
}
- (NSDragOperation)tableView:(NSTableView*)table validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([[[info draggingSource] delegate] isKindOfClass:[AssetListViewController class]]) {
        if (([self.source.type isEqualToString:@"BatchSource"]) || (self.isPlaylist)) {
            if (operation == NSTableViewDropOn) [table setDropRow:row dropOperation:NSTableViewDropAbove];
            return NSDragOperationMove;
        }
	}
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)table acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    
	NSPasteboard *pasteboard = [info draggingPasteboard];
	NSData *data = [pasteboard dataForType:@"PraxItemsDropType"];
	NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([objects count] > 0) {
        [self.assetsTableView setSortDescriptors:nil];
        NSMutableOrderedSet *arrangedAssets = [NSMutableOrderedSet orderedSetWithCapacity:1];
        NSArray *shiftedArray;
        if (row > 0) {
            [arrangedAssets addObjectsFromArray:[self.assetArrayController.arrangedObjects objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, row)]]];
        }
        if (row < [self.assetArrayController.arrangedObjects count]) {
            shiftedArray = [self.assetArrayController.arrangedObjects subarrayWithRange:NSMakeRange(row, ([self.assetArrayController.arrangedObjects count] - row))];
        }
        NSMutableOrderedSet *draggedAssets = [NSMutableOrderedSet orderedSetWithCapacity:1];
        NSManagedObjectID *objectID;
        Asset *asset;
        for (NSURL *objectURL in objects) {
            objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
            asset = (Asset *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
            NSLog(@"asset.title: %@", asset.title);
            if (self.isPlaylist) {
                if ([asset.type isEqualToString:@"track"]) [draggedAssets addObject:asset];
            }
            else [draggedAssets addObject:asset];
        }
        [arrangedAssets minusOrderedSet:draggedAssets];
        [arrangedAssets unionOrderedSet:draggedAssets];
        if (shiftedArray) [arrangedAssets addObjectsFromArray:shiftedArray];
        if (self.isPlaylist) {
            Asset *playlist = self.associatedController.assetArrayController.selectedObjects[0];
            playlist.associatedItems = arrangedAssets;
        }
        else if ([self.source.type isEqualToString:@"BatchSource"]) {
            self.source.batchAssets = arrangedAssets;
        }
        [self.assetArrayController setContent:[arrangedAssets array]];
        return YES;
    }
    else return NO;
}



- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    return [self.document.tagController tokenField:tokenField shouldAddObjects:tokens atIndex:index];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    return [self.document.tagController tokenField:tokenField displayStringForRepresentedObject:representedObject];
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    return [self.document.tagController tokenField:tokenField editingStringForRepresentedObject:representedObject];
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    return [self.document.tagController tokenField:tokenField representedObjectForEditingString:editingString];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex
    indexOfSelectedItem:(NSInteger *)selectedIndex {
    return [self.document.tagController tokenField:tokenField completionsForSubstring:substring indexOfToken:tokenIndex indexOfSelectedItem:selectedIndex];
}

@end
