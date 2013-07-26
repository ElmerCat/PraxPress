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
    
    parent = [Source addLibrarySource:@"Accounts" withSortOrder:@0 forType:@"AccountSource" inManagedObjectContext:moc];
    
    child = [Source addAccountSource:@"WordPress" rowHeight:@35 toParent:parent forEntity:@"Post" withPredicateString:@"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Posts" toParent:child forEntity:@"Post" withPredicateString:@"type == \"post\"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Pages" toParent:child forEntity:@"Post" withPredicateString:@"type == \"page\"" inManagedObjectContext:moc];
    child = [Source addAccountSource:@"SoundCloud" rowHeight:@35 toParent:parent forEntity:@"Asset" withPredicateString:@"(type == \"track\") OR (type == \"playlist\")" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Tracks" toParent:child forEntity:@"Track" withPredicateString:@"" inManagedObjectContext:moc];
    grandChild = [Source addSubAccountSource:@"Playlists (Sets)" toParent:child forEntity:@"Playlist" withPredicateString:@"" inManagedObjectContext:moc];
//    child = [Source addAccountSource:@"YouTube" rowHeight:@35 toParent:parent forEntity:@"Video" withPredicateString:@"" inManagedObjectContext:moc];
//    child = [Source addAccountSource:@"Flickr" rowHeight:@35 toParent:parent forEntity:@"Image" withPredicateString:@"" inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Searches" withSortOrder:@1 forType:@"SearchSource" inManagedObjectContext:moc];

    child = [Source addSearchSource:@"New Search" toParent:parent forEntity:@"Asset" withPredicateString:@"title BEGINSWITH[c] \"j\"" inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Batches" withSortOrder:@2 forType:@"BatchSource" inManagedObjectContext:moc];
    
    child = [Source addBatchSource:@"New Batch" toParent:parent withArrangedAssets:@[] inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Prax Assets" withSortOrder:@3 forType:@"PraxAssetSource" inManagedObjectContext:moc];
    
    child = [Source addPraxAssetSource:@"New Prax Asset" toParent:parent inManagedObjectContext:moc];
    
    parent = [Source addLibrarySource:@"Folders" withSortOrder:@4 forType:@"FolderSource" inManagedObjectContext:moc];
    child = [Source addFolderSource:@"New Folder" toParent:parent inManagedObjectContext:moc];
    
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
        
        [self.sourceListOutlineView registerForDraggedTypes:@[@"org.ElmerCat.PraxPress.Source"]];

        self.sourceListCellControllers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SourceListCellViews" bundle:[NSBundle mainBundle]];
        for (NSString *identifier in @[@"LibrarySource", @"AccountSource", @"SubAccountSource", @"WordPress", @"SearchSource", @"BatchSource", @"FolderSource"]) {
            [self.sourceListOutlineView registerNib:nib forIdentifier:identifier];
        }
        self.assetListViewControllers = [@[] mutableCopy];
        [self addAssetListPane:nil withSource:nil];
        
        NSRect frame = self.sourceListSubView.frame;
        frame.size.width = [[[NSUserDefaults standardUserDefaults] valueForKey:@"sourceListWidth"] doubleValue];
        if (frame.size.width < 50) {
            frame.size.width = 150;
        }
        [self.sourceListSubView setFrame:frame];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      //      NSTreeNode *item = [self.document.sourceTreeController nodeOfObject:parent];
            [self.sourceListOutlineView.animator expandItem:nil expandChildren:YES];
        });
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"SourceController windowWillClose notification: %@", notification);
    for (AssetListViewController *controller in self.assetListViewControllers) {
        if (controller.assetListViewer) {
            [controller.assetListViewer close];
            controller.assetListViewer = nil;
        }
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
//    self.selectedSource = controller.source;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.document.sourceTreeController setSelectionIndexPath:[self.document.sourceTreeController indexPathOfObject:controller.source]];
        
    });


}

- (void)closeAssetListPane:(AssetListViewController *)controller {
    if (self.assetListViewControllers.count > 1) {
        NSInteger index = [self.assetListViewControllers indexOfObject:controller];
        BOOL wasSelected = [(AssetListViewController *)self.assetListViewControllers[index] isSelectedPane];
        if (controller.assetListViewer) {
            [controller.assetListViewer close];
            controller.assetListViewer = nil;
        }
        [controller.view removeFromSuperview];
        [self.assetListViewControllers removeObjectAtIndex:index];
        if (self.assetListViewControllers.count < 2) self.hasMoreThanOneTab = NO;
        if (wasSelected) {
            if (index > 0) index -= 1;
            [self selectAssetListPane:self.assetListViewControllers[index]];
        }
    }
}

- (void)addBatchSource:(AssetListViewController *)controller withSource:(Source *)source {
    Source *batches = [[self.document.sourceTreeController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:2]] representedObject];
    NSArray *assets = @[];
    NSString *name = @"New Empty Batch";
    if (controller) {
        name = [NSString stringWithFormat:@"New Batch from %@", controller.source.name];
        assets = controller.assetArrayController.arrangedObjects;
        if (controller.assetArrayController.filterPredicate) assets = [assets filteredArrayUsingPredicate:controller.assetArrayController.filterPredicate];
    }
    Source *newBatch = [Source addBatchSource:name toParent:batches withArrangedAssets:assets inManagedObjectContext:self.document.managedObjectContext];
    [self addAssetListPane:controller withSource:newBatch];
    [self.document.managedObjectContext processPendingChanges];
    [self.document.sourceTreeController rearrangeObjects];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSTreeNode *item = [self.document.sourceTreeController nodeOfObject:batches];
        [self.sourceListOutlineView.animator expandItem:item expandChildren:NO];
        NSIndexPath *indexPath = [self.document.sourceTreeController indexPathOfObject:newBatch];
        [self.document.sourceTreeController setSelectionIndexPath:indexPath];

    });
    
}


- (void)addAssetListPane:(AssetListViewController *)controller withSource:(Source *)source {
    NSUInteger index = 0;
    if (controller) index = ([self.assetListViewControllers indexOfObject:controller] + 1);
    [self adjustSplitViewForNewPaneAtIndex:index];

    AssetListViewController *newController = [[AssetListViewController alloc] initWithNibName:@"AssetListView" bundle:nil];
    [self.assetListViewControllers insertObject:newController atIndex:index];
    newController.document = self.document;
    [self.sourceSplitView addSubview:newController.view positioned:NSWindowAbove relativeTo:self.sourceSplitView.subviews[index]];
    if (source) newController.source = source;
    else if (controller) newController.source = controller.source;
    if (self.assetListViewControllers.count > 1) self.hasMoreThanOneTab = YES;
    [self selectAssetListPane:newController];

}

/*- (NSArray *)assetsForSource:(Source *)source {
    
    if ([source.entity.name isEqualToString:@"BatchSource"]) {
        return [source.batchAssets array];
    }
    
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
    
}*/

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
    
    if (![outlineView isItemExpanded:item]) [outlineView.animator expandItem:item];
    else if ([[item representedObject] parent] == nil) [outlineView.animator collapseItem:item];
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
    
    if (!view) return;

    //    self.selectedSource = view.objectValue;
    
    AssetListViewController *controller = self.assetListViewControllers[self.selectedAssetListIndex];
    controller.source = view.objectValue;
    
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

- (IBAction)newListPaneWithSource:(id)sender {
    Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    [self addAssetListPane:nil withSource:source];
}

- (IBAction)newSourceItem:(id)sender {
    Source *clickedSource = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    Source *parent;
    NSString *entityName;
    
    if (clickedSource.folderType) {
        entityName = clickedSource.folderType;
        parent = clickedSource;
    }
    else {
        entityName = clickedSource.entity.name;
        parent = clickedSource.parent;
    }
    if ([entityName isEqualToString:@"BatchSource"]) {
        [self addBatchSource:nil withSource:nil];
        
    }
    else {
        Source *newSource = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.document.managedObjectContext];
        
        if ([entityName isEqualToString:@"SearchSource"]) newSource.name = @"New Search";
        else if ([entityName isEqualToString:@"PraxAssetSource"]) newSource.name = @"New Prax Asset";
        else newSource.name = [NSString stringWithFormat:@"New %@", entityName];
        newSource.parent = parent;
        newSource.rowHeight = @30;
        
        [self.document.managedObjectContext processPendingChanges];
        [self.document.sourceTreeController rearrangeObjects];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSTreeNode *item = [self.document.sourceTreeController nodeOfObject:parent];
            [self.sourceListOutlineView.animator expandItem:item expandChildren:YES];
        });
    }
}



- (IBAction)newSourceFolder:(id)sender {
    Source *clickedSource = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    Source *parent;
    if ([clickedSource.entity.name isEqualToString:@"FolderSource"]) parent = clickedSource.parent;
    else {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"LibrarySource"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", @"Folders"]];
        NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:nil];
        if ([matchingItems count] > 0) parent = matchingItems[0];
    }
    
    Source *newFolder = [NSEntityDescription insertNewObjectForEntityForName:@"FolderSource" inManagedObjectContext:self.document.managedObjectContext];
    
    newFolder.name = [NSString stringWithFormat:@"Folder with %@", clickedSource.name];
    newFolder.parent = parent;
    clickedSource.parent = newFolder;
    newFolder.rowHeight = @30;
    
    [self.document.managedObjectContext processPendingChanges];
    [self.document.sourceTreeController rearrangeObjects];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSIndexPath *indexPath = [self.document.sourceTreeController indexPathOfObject:newFolder];
        [self.document.sourceTreeController setSelectionIndexPath:indexPath];
        NSTreeNode *item = [self.document.sourceTreeController nodeOfObject:parent];
        [self.sourceListOutlineView.animator expandItem:item];
        item = [self.document.sourceTreeController nodeOfObject:newFolder];
        [self.sourceListOutlineView.animator expandItem:item];
    });

}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    
    SEL action = [item action];
    
    if (action == @selector(delete:)) {
        Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
        NSArray *dontDelete = @[@"LibrarySource", @"AccountSource", @"SubAccountSource"];
        for (NSString *entityName in dontDelete) {
            if ((!source) || ([entityName isEqualToString:source.entity.name])) {
                [item setHidden:YES];
                return NO;
            }
        }
        [item setTitle:[NSString stringWithFormat:@"Delete %@", source.name]];
        [item setHidden:NO];
        return YES;
    }
    
    else if (action == @selector(newListPaneWithSource:)) {
        Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
        if ((!source) || ([source.entity.name isEqualToString:@"LibrarySource"])) {
            [item setHidden:YES];
            return NO;
        }
        
        [item setTitle:[NSString stringWithFormat:@"Open New List Pane with %@", source.name]];
        [item setHidden:NO];
        return YES;
    }
    
    else if (action == @selector(newSourceItem:)) {
        Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
        
        if ((!source) || ([source.name isEqualToString:@"Accounts"])) {
            [item setHidden:YES];
            return NO;
        }

        NSArray *dontShow = @[@"FolderSource", @"AccountSource", @"SubAccountSource"];
        for (NSString *entityName in dontShow) {
            if ([entityName isEqualToString:source.entity.name]) {
                [item setHidden:YES];
                return NO;
            }
        }
        NSString *title;
        if (source.folderType) title = source.folderType;
        else title = source.entity.name;
        if ([title isEqualToString:@"SearchSource"]) title = @"Search";
        else if ([title isEqualToString:@"BatchSource"]) title = @"Batch";
        else if ([title isEqualToString:@"PraxAssetSource"]) title = @"Prax Asset";
        else if ([title isEqualToString:@"FolderSource"]) title = @"Folder";
        title = [NSString stringWithFormat:@"New %@", title];
        [item setTitle:title];
        [item setHidden:NO];
        return YES;
    }
    
    else if (action == @selector(newSourceFolder:)) {
        Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];

        if ((!source) || ([source.name isEqualToString:@"Accounts"])) {
            [item setHidden:YES];
            return NO;
        }
        
        NSArray *dontShow = @[@"LibrarySource", @"FolderSource", @"AccountSource", @"SubAccountSource"];
        for (NSString *entityName in dontShow) {
            if ([entityName isEqualToString:source.entity.name]) {
                [item setHidden:YES];
                return NO;
            }
        }
        [item setTitle:[NSString stringWithFormat:@"New Folder with %@", source.name]];
        [item setHidden:NO];
        return YES;
    }
    
    else {
        [item setHidden:NO];
        return YES;
    }
}



- (IBAction)delete:(id)sender {
    
    Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete this Source item?" defaultButton:@"Cancel" alternateButton:@"Delete" otherButton:nil informativeTextWithFormat:@"The Source item: %@ will be deleted if you press Delete!", source.name];
    if (![alert runModal]) {
        
        [self.document.managedObjectContext deleteObject:source];
        [self.document.managedObjectContext processPendingChanges];
        [self.document.sourceTreeController rearrangeObjects];
        
    }
}

- (IBAction)newPraxAsset:(id)sender {

    NSString *folderType = @"PraxAssetSource";
    NSArray *librarySources = (NSArray *)[self.document.sourceTreeController.arrangedObjects childNodes];
    
    NSUInteger index = [librarySources indexOfObjectPassingTest:^BOOL(NSTreeNode *obj, NSUInteger idx, BOOL *stop) {
        if ([[(Source *)obj.representedObject entity].name isEqualToString:@"LibrarySource"] && [[(Source *)obj.representedObject folderType] isEqualToString:folderType]) return YES;
        else return NO;
    }];
    if (index != NSNotFound) {
        Source *parent = [(NSTreeNode *)librarySources[index] representedObject];
        [Source addPraxAssetSource:@"New Prax Asset" toParent:parent inManagedObjectContext:self.document.managedObjectContext];
        [self.document.sourceTreeController rearrangeObjects];
    }
}




-(BOOL)sourceListVisible {
    if ([self.sourceSplitView isSubviewCollapsed:self.sourceListSubView]) return NO;
    else if (self.sourceListSubView.frame.size.width < 10) return NO;
    else return YES;
    
    
    
}

- (IBAction)toggleSourceList:(id)sender {
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


- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    Source *source = [item representedObject];
    if (!source.parent) return nil;
    if (([source.entity.name isEqualToString:@"AccountSource"] || [source.parent.entity.name isEqualToString:@"AccountSource"])) return nil;

    if (!([source.parent.entity.name isEqualToString:@"FolderSource"] || [source.parent.entity.name isEqualToString:@"LibrarySource"])) return nil;

    
    NSURL *sourceURL = [source.objectID URIRepresentation];
 	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sourceURL];
    NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
	[pasteboardItem setData:data forType:@"org.ElmerCat.PraxPress.Source"];
    return pasteboardItem;
}


- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    
	if (![[info draggingSource] isEqualTo:self.sourceListOutlineView]) return NSDragOperationNone;

    Source *proposedParent = [item representedObject];
    if (!([proposedParent.entity.name isEqualToString:@"FolderSource"] || [proposedParent.entity.name isEqualToString:@"LibrarySource"])) return NSDragOperationNone;
        
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
    
    if ([source.entity.name isEqualToString:@"FolderSource"]) {
        
        //   if (![source.folderType isEqualToString:proposedParent.folderType]) return NSDragOperationNone;
        if (!([source.parent.entity.name isEqualToString:@"FolderSource"] || [source.parent.entity.name isEqualToString:@"LibrarySource"])) return NSDragOperationNone;
    }
    if ([proposedParent.entity.name isEqualToString:@"LibrarySource"]) {
        if (![proposedParent.folderType isEqualToString:source.entity.name]) return NSDragOperationNone;
    }
//    else if (![source.entity.name isEqualToString:proposedParent.folderType]) return NSDragOperationNone;
    
    return (NSDragOperationEvery);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {
    Source *destination = [item representedObject];
    
    if ([destination.entity.name isEqualToString:@"FolderSource"] || [destination.entity.name isEqualToString:@"LibrarySource"]) {
        
        NSURL *objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:@"org.ElmerCat.PraxPress.Source"]];
        
        NSManagedObjectID *objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
        Source *source = (Source *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];

        
        if ([source isEqualTo:destination]) return NO;

//        if ([source.entity.name isEqualToString:@"FolderSource"] || [source.entity.name isEqualToString:@"LibrarySource"]) {
//            if (![source.folderType isEqualToString:destination.folderType]) return NO;
//        }
//        else if (![source.entity.name isEqualToString:destination.folderType]) return NO;
        
        
        Source *destinationParent = destination.parent;
        while (destinationParent) {
            if ([destinationParent isEqualTo:source]) {
                return NO;
            }
            destinationParent = destinationParent.parent;
        }
        
        source.parent = destination;
        [self.document.sourceTreeController rearrangeObjects];
        return YES;
    
    }
  	return NO;
}


@end

@implementation NSTreeController (Additions)

- (NSTreeNode*)nodeOfObject:(id)anObject
{
    return [self nodeOfObject:anObject inNodes:(NSArray *)[[self arrangedObjects] childNodes]];
}

- (NSTreeNode*)nodeOfObject:(id)anObject inNodes:(NSArray*)nodes
{
    for(NSTreeNode* node in nodes)
    {
        if([[node representedObject] isEqual:anObject])
            return node;
        if([[node childNodes] count])
        {
            NSTreeNode* childNode = [self nodeOfObject:anObject inNodes:[node childNodes]];
            if(childNode)
                return childNode;
        }
    }
    return nil;
}

- (NSIndexPath*)indexPathOfObject:(id)anObject
{
    return [self indexPathOfObject:anObject inNodes:(NSArray *)[[self arrangedObjects] childNodes]];
}

- (NSIndexPath*)indexPathOfObject:(id)anObject inNodes:(NSArray*)nodes
{
    for(NSTreeNode* node in nodes)
    {
        if([[node representedObject] isEqual:anObject])
            return [node indexPath];
        if([[node childNodes] count])
        {
            NSIndexPath* path = [self indexPathOfObject:anObject inNodes:[node childNodes]];
            if(path)
                return path;
        }
    }
    return nil;
}
@end