//
//  SourceController.m
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "SourceController.h"
#import "Source.h"

@implementation SourceController



+ (void)initWithType:(NSString *)typeName inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSLog(@"SourceController initWithType");
    
    Source *parent;
    Source *child;
    Source *grandChild;
    
    parent = [Source addLibrarySource:@"Accounts" withSortOrder:@0 inManagedObjectContext:moc];
    
    child = [Source addAccountSource:@"WordPress" rowHeight:@35 toParent:parent forEntity:@"Post" withPredicateString:@"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Posts" toParent:child forEntity:@"Post" withPredicateString:@"type == \"post\"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Pages" toParent:child forEntity:@"Post" withPredicateString:@"type == \"page\"" inManagedObjectContext:moc];
    child = [Source addAccountSource:@"SoundCloud" rowHeight:@35 toParent:parent forEntity:@"Asset" withPredicateString:@"type BEGINSWITH[c] \"SoundCloud\"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Tracks" toParent:child forEntity:@"Track" withPredicateString:@"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Playlists (Sets)" toParent:child forEntity:@"Playlist" withPredicateString:@"" inManagedObjectContext:moc];
    child = [Source addAccountSource:@"YouTube" rowHeight:@35 toParent:parent forEntity:@"Video" withPredicateString:@"" inManagedObjectContext:moc];
    child = [Source addAccountSource:@"Flickr" rowHeight:@35 toParent:parent forEntity:@"Image" withPredicateString:@"" inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Searches" withSortOrder:@1 inManagedObjectContext:moc];

    child = [Source addSearchSource:@"New Search" toParent:parent forEntity:@"Asset" withPredicateString:@"title BEGINSWITH[c] \"j\"" inManagedObjectContext:moc];
    child = [Source addFolderSource:@"Search Folder" toParent:parent inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Search Sub Folder" toParent:child inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Search Sub Folder" toParent:child inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Search Sub Folder" toParent:child inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Batches" withSortOrder:@2 inManagedObjectContext:moc];
    
    child = [Source addBatchSource:@"New Batch" toParent:parent withArrangedAssets:@[] inManagedObjectContext:moc];
    child = [Source addFolderSource:@"Batch Folder" toParent:parent inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Batch Sub Folder" toParent:child inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Batch Sub Folder" toParent:child inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Batch Sub Folder" toParent:child inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Prax Assets" withSortOrder:@3 inManagedObjectContext:moc];
    
    child = [Source addPraxAssetSource:@"New Prax Asset" toParent:parent inManagedObjectContext:moc];
    child = [Source addFolderSource:@"Prax Folder" toParent:parent inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Prax Sub Folder" toParent:child inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Prax Sub Folder" toParent:child inManagedObjectContext:moc];
    grandChild = [Source addFolderSource:@"Prax Sub Folder" toParent:child inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Changed Items" withSortOrder:@4 inManagedObjectContext:moc];
    
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"SourceController init");
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"SourceController awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        self.selectedAssetListIndex = -1;
        
        self.sourceListCellControllers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SourceListCellViews" bundle:[NSBundle mainBundle]];
        for (NSString *identifier in @[@"LibrarySource", @"AccountSource", @"SubAccountSource", @"WordPress", @"SearchSource", @"BatchSource", @"FolderSource", @"ChangedSource"]) {
            [self.sourceListOutlineView registerNib:nib forIdentifier:identifier];
        }
        self.assetListViewControllers = [@[] mutableCopy];
        [self addAssetListPane:nil];
        
        NSRect frame = self.sourceListSubView.frame;
        frame.size.width = [[[NSUserDefaults standardUserDefaults] valueForKey:@"sourceListWidth"] doubleValue];
        if (frame.size.width < 50) {
            frame.size.width = 150;
        }
        [self.sourceListSubView setFrame:frame];
    }
}

- (void)selectAssetListPane:(AssetListViewController *)controller {
    NSInteger index = [self.assetListViewControllers indexOfObject:controller];
    if (index != self.selectedAssetListIndex) {
        self.selectedAssetListIndex = index;
    }
    else [self toggleSourceList:self];
    
    for (int i = 0; (i < self.assetListViewControllers.count); i++) {
        if (i == self.selectedAssetListIndex) [self.assetListViewControllers[i] setIsSelectedPane:YES];
        else [self.assetListViewControllers[i] setIsSelectedPane:NO];
    }
}

- (void)closeAssetListPane:(AssetListViewController *)controller {
    if (self.assetListViewControllers.count > 1) {
        NSInteger index = [self.assetListViewControllers indexOfObject:controller];
            BOOL wasSelected = [(AssetListViewController *)self.assetListViewControllers[index] isSelectedPane];
            [controller.view removeFromSuperview];
            [self.assetListViewControllers removeObjectAtIndex:index];
            if (self.assetListViewControllers.count < 2) self.hasMoreThanOneTab = NO;
            if (wasSelected) {
                if (index > 0) index -= 1;
                [self selectAssetListPane:self.assetListViewControllers[index]];
            }
    }
}

- (void)addAssetListPane:(AssetListViewController *)controller {
    NSUInteger index = 0;
    if (controller) index = ([self.assetListViewControllers indexOfObject:controller] + 1);
    [self adjustSplitViewForNewPaneAtIndex:index];

    AssetListViewController *newController = [[AssetListViewController alloc] initWithNibName:@"AssetListView" bundle:nil];
    [self.assetListViewControllers insertObject:newController atIndex:index];
    newController.document = self.document;
    [self.sourceSplitView addSubview:newController.view positioned:NSWindowAbove relativeTo:self.sourceSplitView.subviews[index]];
    if (controller) newController.source = controller.source;
    if (self.assetListViewControllers.count > 1) self.hasMoreThanOneTab = YES;
    [self selectAssetListPane:newController];

}

- (NSArray *)assetsForSource:(Source *)source {
    
    NSString *entityName = source.fetchEntity;
    if (!entityName.length) entityName = @"Asset";
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [request setPredicate:source.fetchPredicate];
    NSArray *matchingItems;
    @try {
        NSLog(@"SourceController @try");
        matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"SourceController NSException *exception: %@", exception);
    }
    @finally {
        NSLog(@"SourceController @finally");
    }

    return matchingItems;
    
}

- (IBAction)sourceDetailsButtonPressedRightEdge:(id)sender {
    Source *source = (Source *)[(NSTableCellView *)[sender superview] objectValue];
    if ((source == self.sourcePopovers.source) && (self.sourcePopover.isShown)) [self.sourcePopover close];
    else [self.sourcePopovers showPopoverForSource:source sender:sender preferredEdge:NSMaxXEdge];
}
- (IBAction)sourceDetailsButtonPressedBottomEdge:(id)sender {
    Source *source = (Source *)[(NSTableCellView *)[sender superview] objectValue];
    if ((source == self.sourcePopovers.source) && (self.sourcePopover.isShown)) [self.sourcePopover close];
    else [self.sourcePopovers showPopoverForSource:source sender:sender preferredEdge:NSMinYEdge];
}


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



-(NSArray *)sortDescriptors {
    return @[[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:TRUE]];
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
    return [[SourceTableRowView alloc] init];
    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    
    if([self.sourcePopover isShown]) [self.sourcePopover close];
    
    if (![outlineView isItemExpanded:item]) [outlineView expandItem:item];
    else if ([[item representedObject] parent] == nil) [outlineView collapseItem:item];
    return (!([[item representedObject] parent] == nil));
    
}

/*- (void)outlineView:(NSOutlineView *)outlineView didSelectItem:(id)item {
    if (![outlineView isItemExpanded:item]) [outlineView expandItem:item];
    else [outlineView collapseItem:item];
    
}*/

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [self.document.sourceOutlineView selectedRow];
    if (row < 0) return;
    
    NSTableCellView *view = [self.document.sourceOutlineView viewAtColumn:0 row:row makeIfNecessary:FALSE];
    Source *source = view.objectValue;
    
    AssetListViewController *controller = self.assetListViewControllers[self.selectedAssetListIndex];
    controller.source = source;
    
//    NSView *assetListView = [self.sourceSplitView viewWithTag:1];
    
 //   assetListView.assetListViewController.source = source;
    
    
 //   Source *soure = [[self.document.sourceOutlineView viewAtColumn:0 row:[self.document.sourceOutlineView selectedRow] makeIfNecessary:FALSE] representedObject];
    
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return ([[item representedObject] parent] == nil);
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    Source *source = [item representedObject];
    
    return source.rowHeight.doubleValue;
    
/*    if (source.parent == nil) {
        
        return 30;
        
    }
    else {
        return 40;
        
    }*/
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    Source *source = [item representedObject];
    NSString *cellType = source.entity.name;
    if ([cellType isEqualToString:@"AccountSource"]) {
        cellType = source.account.accountType;
    }
    return [outlineView makeViewWithIdentifier:cellType owner:self];
}



-(void)reset {
    
}

- (void)toggleSourceList:(id)sender {
    NSRect frame = self.sourceListSubView.frame;
    
    if ([self.sourceSplitView isSubviewCollapsed:self.sourceListSubView]) {
        [self.sourceSplitView.animator setPosition:frame.size.width ofDividerAtIndex:0];
    }
    else {
        if (frame.size.width < 10) {
            
            frame.size.width = [[[NSUserDefaults standardUserDefaults] valueForKey:@"sourceListWidth"] doubleValue];
        }
        
        else {
            if (frame.size.width > 150) {
                [[NSUserDefaults standardUserDefaults] setValue:@(frame.size.width) forKey:@"sourceListWidth"];
            }
            frame.size.width = 0;
        }
        [self.sourceListSubView.animator setFrame:frame];
    }
    
}

- (IBAction)toolbarItemSelected:(id)sender {
    
    NSString *itemIdentifier = [sender itemIdentifier];
    if ([itemIdentifier isEqualToString:@"Sources"]) {
        [self toggleSourceList:sender];
        
    }
    else if ([itemIdentifier isEqualToString:@"Filter"]) {
            
        
    }
    
    
}
- (IBAction)filterSelectedPane:(id)sender {
    AssetListViewController *controller = self.assetListViewControllers[self.selectedAssetListIndex];
    [controller filterPane];
    
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    if ([self.sourceSplitView isSubviewCollapsed:self.sourceListSubView]) {
        [self.documentToolbar setSelectedItemIdentifier:nil];
    }
    else if (self.sourceListSubView.frame.size.width < 10) {
        [self.documentToolbar setSelectedItemIdentifier:nil];
    }
    else {
        [self.documentToolbar setSelectedItemIdentifier:@"Sources"];
    }
}


- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex {
//    NSLog(@"splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:%ld", (long)dividerIndex);
    [self toggleSourceList:splitView];
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    if ([subview isEqual:self.sourceListSubView]) return NO;
    else if (subview.frame.size.width <= self.assetListMinWidth) return NO;
    else return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    if ([subview isEqual:self.sourceListSubView]) return YES;
    else return NO;
}

- (BOOL)adjustSplitViewForNewPaneAtIndex:(NSUInteger)index {
    NSUInteger panes = self.sourceSplitView.subviews.count;

    
    CGFloat width = ((self.assetListMinWidth * panes) + self.sourceListMinWidth);
    if (width > self.documentWindow.frame.size.width) {
        NSRect frame = self.documentWindow.frame;
        frame.size.width = width;
        [self.documentWindow setFrame:frame display:YES];
        return YES;
    }
    else return NO;
}


- (CGFloat)sourceListMinWidth {return 150;}
- (CGFloat)assetListMinWidth {return 150;}

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


- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat max = [self assetListMaxWidthForDividerIndex:dividerIndex];
//    NSLog(@"constrainMaxCoordinate max:%f proposedMax:%f dividerIndex:%ld", max, proposedMax, (long)dividerIndex);
    if (proposedMax > max) return max;
    else return proposedMax;
    
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat min = 0;
    if (dividerIndex == 0) min = self.sourceListMinWidth;
    else min = [self assetListMinWidthForDividerIndex:dividerIndex];
//    NSLog(@"constrainMinCoordinate min:%f proposedMin:%f dividerIndex:%ld", min, proposedMin, (long)dividerIndex);
    if (proposedMin < min) return min;
    else return proposedMin;
    
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
//    NSLog(@"constrainSplitPosition dividerIndex %ld", (long)dividerIndex);
    NSUInteger panes = self.sourceSplitView.subviews.count;
    CGFloat maxWidth = self.sourceSplitView.frame.size.width;
    for (NSUInteger i = (panes - 2); i > dividerIndex; i--) {
        maxWidth -= self.assetListMinWidth;
    }

/*    for (NSUInteger i = (panes - 2); i > dividerIndex; i--) {
        NSView *view = self.sourceSplitView.subviews[i+1];
        maxWidth -= view.frame.size.width;
    }*/
    
    maxWidth -= self.assetListMinWidth;
    CGFloat minWidth = 0;
    if (dividerIndex == 0) minWidth = self.sourceListMinWidth;
    else minWidth = [self assetListMinWidthForDividerIndex:dividerIndex];
    if (proposedPosition < minWidth) return minWidth;
    if (proposedPosition > maxWidth) return maxWidth;
    else return proposedPosition;

}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
 NSRect effectiveRect = proposedEffectiveRect;
 // effectiveRect.origin.x -= 2.0;
 if (splitView.isVertical) {
 effectiveRect.origin.x -= 10.0;
 effectiveRect.size.width += 20.0;
 }
 else {
 effectiveRect.origin.y -= 10.0;
 effectiveRect.size.height += 20.0;
 }
 
 
 
 return effectiveRect;
 }


@end
