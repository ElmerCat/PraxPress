//
//  SourceController+Delegation.m
//  PraxPress
//
//  Created by John-Elmer on 1/1/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import "SourceController+Delegation.h"

@implementation SourceController (Delegation)

#pragma mark - <NSOutlineViewDelegate>


/*- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
 
 NSManagedObject *object = [item representedObject];
 NSURL *objectURL = [object.objectID URIRepresentation];
 return [NSKeyedArchiver archivedDataWithRootObject:objectURL];
 }
 
 
 - (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
 
 NSURL *objectURL;
 @try {
 objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)object];
 }
 @catch (NSException *exception) {
 NSLog(@"NSKeyedUnarchiver exception %@", exception);
 return nil;
 }
 NSManagedObjectID *objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
 NSManagedObject *item = [self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
 NSLog(@"item: %@", item);
 return item;
 }*/



//- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
//    return [[SourceTableRowView alloc] init];
//}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    
    Source *source = [item representedObject];
    
    if (source.parent == nil) {
        if (![outlineView isItemExpanded:item]) [outlineView.animator expandItem:item];
        else [outlineView.animator collapseItem:item];
        return NO;
    }
    NSInteger index = [self.sources indexOfObject:source];
    if (index == NSNotFound) return YES;
    else {
        [self selectAssetListPane:self.panes[index]];
        return NO;
    }
}

/*- (void)outlineView:(NSOutlineView *)outlineView didSelectItem:(id)item {
 if (![outlineView isItemExpanded:item]) [outlineView expandItem:item];
 else [outlineView collapseItem:item];
 
 }*/

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [self.sourceListOutlineView selectedRow];
    if (row < 0) return;
    NSTableCellView *view = [self.sourceListOutlineView viewAtColumn:0 row:row makeIfNecessary:FALSE];
    if (!view) return;
    Source *deselectedSource = self.document.interface.selectedSource;
    [self.previousSources insertObject:deselectedSource atIndex:0];
    NSInteger index = [self.sources indexOfObject:view.objectValue];
    if (index == NSNotFound) {
        NSIndexSet *sourceIndexes = [self.sources indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return (obj == deselectedSource);
        }];
        
        [sourceIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            AssetListViewController *controller = self.panes[idx];
            controller.source = view.objectValue;
            [self.sources replaceObjectAtIndex:idx withObject:view.objectValue];
        }];
    }
    self.document.interface.selectedSource = view.objectValue;
    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return ([[item representedObject] parent] == nil);
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    Source *source = [item representedObject];
    NSNumber *height = source.rowHeight;
    if (!height) return 50;
    else return height.doubleValue;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSView *view = [outlineView makeViewWithIdentifier:[[item representedObject] valueForKey:@"name"] owner:self];
    if (!view) view = [outlineView makeViewWithIdentifier:[[item representedObject] valueForKey:@"type"] owner:self];
    if (!view) view = [outlineView makeViewWithIdentifier:@"AssetSource" owner:self];
    return view;
}


- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    Source *source = [item representedObject];
    if (!source.parent) return nil;
    if (([source.type isEqualToString:@"AccountSource"] || [source.parent.type isEqualToString:@"AccountSource"])) return nil;
    
    if (!([source.parent.type isEqualToString:@"FolderSource"] || [source.parent.type isEqualToString:@"LibrarySource"])) return nil;
    
    
    NSURL *sourceURL = [source.objectID URIRepresentation];
 	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sourceURL];
    NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
	[pasteboardItem setData:data forType:@"org.ElmerCat.PraxPress.Source"];
    return pasteboardItem;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    
	if (![[info draggingSource] isEqualTo:self.sourceListOutlineView]) return NSDragOperationNone;
    
    Source *proposedParent = [item representedObject];
    if (!([proposedParent.type isEqualToString:@"FolderSource"] || [proposedParent.type isEqualToString:@"LibrarySource"])) return NSDragOperationNone;
    
    NSData *data = [[info draggingPasteboard] dataForType:@"org.ElmerCat.PraxPress.Source"];
    NSURL *objectURL;
    @try {
        objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        NSLog(@"NSKeyedUnarchiver exception %@", exception);
        return NSDragOperationNone;
    }
    NSManagedObjectID *objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
    Source *source = (Source *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
    
    if ([source isEqualTo:proposedParent]) return NSDragOperationNone;
    if ([source.parent isEqualTo:proposedParent]) return NSDragOperationNone;
    
    if ([source.type isEqualToString:@"FolderSource"]) {
        
        //   if (![source.folderType isEqualToString:proposedParent.folderType]) return NSDragOperationNone;
        if (!([source.parent.type isEqualToString:@"FolderSource"] || [source.parent.type isEqualToString:@"LibrarySource"])) return NSDragOperationNone;
    }
    if ([proposedParent.type isEqualToString:@"LibrarySource"]) {
        if (![proposedParent.folderType isEqualToString:source.type]) return NSDragOperationNone;
    }
    //    else if (![source.type isEqualToString:proposedParent.folderType]) return NSDragOperationNone;
    
    return (NSDragOperationEvery);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {
    Source *destination = [item representedObject];
    
    if ([destination.type isEqualToString:@"FolderSource"] || [destination.type isEqualToString:@"LibrarySource"]) {
        
        NSURL *objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:@"org.ElmerCat.PraxPress.Source"]];
        
        NSManagedObjectID *objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
        Source *source = (Source *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
        
        
        if ([source isEqualTo:destination]) return NO;
        
        //        if ([source.type isEqualToString:@"FolderSource"] || [source.type isEqualToString:@"LibrarySource"]) {
        //            if (![source.folderType isEqualToString:destination.folderType]) return NO;
        //        }
        //        else if (![source.type isEqualToString:destination.folderType]) return NO;
        
        
        Source *destinationParent = destination.parent;
        while (destinationParent) {
            if ([destinationParent isEqualTo:source]) {
                return NO;
            }
            destinationParent = destinationParent.parent;
        }
        
        source.parent = destination;
        [self.sourceTreeController rearrangeObjects];
        return YES;
        
    }
 
 	return NO;
}


#pragma mark - <NSSplitViewDelegate>


//- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
//    NSLog(@"splitView:resizeSubviewsWithOldSize: %f %f", oldSize.height, oldSize.width);
    
//}

//- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
//    if ([subview isEqual:self.sourceListSubView]) return NO;
//    else if (subview.frame.size.width <= self.assetListMinWidth) return NO;
//    else return YES;
//}



- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    double sourceListWidth = [self.sourceSplitView positionOfDividerAtIndex:0];
    if (sourceListWidth < 10) [self.document.documentToolbar setSelectedItemIdentifier:nil];
    else [self.self.document.documentToolbar setSelectedItemIdentifier:@"Sources"];
    
    if (sourceListWidth > 150) {
        self.document.interface.sourceListWidth = [NSNumber numberWithDouble:sourceListWidth];
    }

}


- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
    //    NSLog(@"splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:%ld", (long)dividerIndex);
//    [self toggleSourceList:splitView];
    return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if ([subview isEqual:self.sourceListSubView]) return YES;
    else return NO;
}

- (BOOL)dontadjustSplitViewForNewPaneAtIndex:(NSUInteger)index {
    NSUInteger panes = self.sourceSplitView.subviews.count;
    
    NSWindow *window = self.document.documentWindow;
    
    CGFloat width = ((self.assetListMinWidth * panes) + self.sourceListMinWidth);
    if (width > window.frame.size.width) {
        NSRect frame = window.frame;
        frame.size.width = width;
        [window setFrame:frame display:YES];
        return YES;
    }
    else return NO;
}

/*

- (CGFloat)assetListMinWidthForDividerIndex:(NSInteger)dividerIndex {
    CGFloat width = 0;
    if (![self.sourceSplitView isSubviewCollapsed:self.sourceListSubView]) {
        width += self.sourceListSubView.frame.size.width;
    }
    width += (self.assetListMinWidth * dividerIndex);
    return width;
}

- (CGFloat)assetListMaxWidthForDividerIndex:(NSInteger)dividerIndex {
    NSUInteger panes = self.sourceSplitView.subviews.count;
    CGFloat maxWidth = self.sourceSplitView.frame.size.width;
    for (NSUInteger i = (panes - 1); i > dividerIndex; i--) {
        maxWidth -= self.assetListMinWidth;
    }
    return maxWidth;
}
*/
- (CGFloat)sourceListMinWidth {return 150;}

- (CGFloat)praxsplitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat max = [splitView maxPossiblePositionOfDividerAtIndex:dividerIndex] - self.assetListMinWidth;
    if (proposedMax > max) return max;
    else return proposedMax;
    
}

- (CGFloat)assetListMinWidth {return 50;}
- (CGFloat)praxsplitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat min = 0;
    if (dividerIndex == 0) min = self.sourceListMinWidth;
    else min = [splitView minPossiblePositionOfDividerAtIndex:dividerIndex] + self.assetListMinWidth;
    if (proposedMin < min) return min;
    else return proposedMin;
    
}

/*- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
 NSLog(@"constrainSplitPosition %f dividerIndex %ld", (CGFloat)proposedPosition, (long)dividerIndex);
 NSUInteger panes = self.sourceSplitView.subviews.count;
 CGFloat maxWidth = self.sourceSplitView.frame.size.width;
 for (NSUInteger i = (panes - 2); i > dividerIndex; i--) {
 maxWidth -= self.assetListMinWidth;
 }
 
 //   for (NSUInteger i = (panes - 2); i > dividerIndex; i--) {
 //        NSView *view = self.sourceSplitView.subviews[i+1];
 //        maxWidth -= view.frame.size.width;
 //    }
 
 maxWidth -= self.assetListMinWidth;
 CGFloat minWidth = 0;
 if (dividerIndex == 0) minWidth = self.sourceListMinWidth;
 else minWidth = [self assetListMinWidthForDividerIndex:dividerIndex];
 if (proposedPosition < minWidth) return minWidth;
 if (proposedPosition > maxWidth) return maxWidth;
 else return proposedPosition;
 
 }*/

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    NSRect effectiveRect = proposedEffectiveRect;
    // effectiveRect.origin.x -= 2.0;
    if (splitView.isVertical) {
        effectiveRect.origin.x -= 10.0;
        effectiveRect.size.width += 20.0;
    }
    else {
        effectiveRect.origin.y -= 5.0;
        effectiveRect.size.height += 10.0;
    }
    
    
    
    return effectiveRect;
}



@end
