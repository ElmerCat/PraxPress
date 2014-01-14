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

+ (void)initForDocument:(Document *)document {
    NSLog(@"SourceController initForDocument: %@", document);
    
    Source *parent;
    Source *child;
    
    parent = [Source addLibrarySource:@"LIBRARY" withSortOrder:@0 forType:@"AssetSource" inManagedObjectContext:document.managedObjectContext];
    
    child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:document.managedObjectContext];
    child.parent = parent;
    child.type = @"AssetSource";
    child.name = @"All Items";
    child.rowHeight = @30;
    
    document.interface.selectedSource = child;
    

    parent = [Source addLibrarySource:@"SEARCHES" withSortOrder:@1 forType:@"SearchSource" inManagedObjectContext:document.managedObjectContext];

    [Source addSearchSource:@"New Search" toParent:parent forEntity:@"Asset" withPredicateString:@"title BEGINSWITH[c] \"j\"" inManagedObjectContext:document.managedObjectContext];
//    child = [Source addSearchSource:@"New Search" toParent:parent forEntity:@"Asset" withPredicateString:@"title BEGINSWITH[c] \"j\"" inManagedObjectContext:document.managedObjectContext];
    
    parent = [Source addLibrarySource:@"PRAXLISTS" withSortOrder:@2 forType:@"BatchSource" inManagedObjectContext:document.managedObjectContext];
    
    [Source addBatchSource:@"New Empty PraxList" toParent:parent withArrangedAssets:@[] inManagedObjectContext:document.managedObjectContext];
    //child = [Source addBatchSource:@"New Empty PraxList" toParent:parent withArrangedAssets:@[] inManagedObjectContext:document.managedObjectContext];
    
    parent = [Source addLibrarySource:@"FOLDERS" withSortOrder:@3 forType:@"FolderSource" inManagedObjectContext:document.managedObjectContext];
    [Source addFolderSource:@"New Folder" toParent:parent inManagedObjectContext:document.managedObjectContext];
    //child = [Source addFolderSource:@"New Folder" toParent:parent inManagedObjectContext:document.managedObjectContext];
    
    parent = [Source addLibrarySource:@"PRAX ASSETS" withSortOrder:@4 forType:@"PraxAssetSource" inManagedObjectContext:document.managedObjectContext];
    
    [Source addPraxAssetSource:@"New Prax Asset" toParent:parent inManagedObjectContext:document.managedObjectContext];
    //child = [Source addPraxAssetSource:@"New Prax Asset" toParent:parent inManagedObjectContext:document.managedObjectContext];
    
    
    parent = [Source addLibrarySource:@"" withSortOrder:@5 forType:@"AssetSource" inManagedObjectContext:document.managedObjectContext];
    parent.rowHeight = @0;
    child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:document.managedObjectContext];
    child.parent = parent;
    child.type = @"AssetSource";
    child.name = @"Changed Items";
    child.fetchPredicate = [NSPredicate predicateWithFormat:@"sync_mode != 0"];
    //    child.sortOrder = @9999;
    child.rowHeight = @35;
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"SourceController init");
        [[NSNotificationCenter defaultCenter] addObserverForName:@"AssetChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
        //    Asset *asset = (Asset *)[aNotification object];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
                [self.document.changedAssetsController rearrangeObjects];
                NSInteger count = [self.document.changedAssetsController.arrangedObjects count];
                if (count) {
                    [self.sourceListOutlineView expandItem:[self.sourceTreeController nodeOfObject:self.changedItemsSource.parent]];
                }
                else {
                    [self.sourceListOutlineView collapseItem:[self.sourceTreeController nodeOfObject:self.changedItemsSource.parent]];
                }
                self.changedItemsSource.itemCount = [NSNumber numberWithInteger:count];
            });
        }];
        
    }
    return self;
}

- (void)awakeFromNib {
    if (!self.awake) {
        NSLog(@"SourceController awakeFromNib");
        self.awake = TRUE;
        [self.sourceListOutlineView registerForDraggedTypes:@[@"org.ElmerCat.PraxPress.Source"]];
        [self.sourceListOutlineView setDoubleAction:@selector(doubleClickedSource)];
        [self.sourceListOutlineView setTarget:self];
    }
}


- (void)loadInterface {

    if (self.interfaceLoaded) return;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Source"];
    NSError *error;
    [request setPredicate:[NSPredicate predicateWithFormat:@"name = \"All Items\""]];
    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
    if (matchingItems.count) self.allItemsSource = matchingItems[0];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name = \"Changed Items\""]];
    matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
    if (matchingItems.count) self.changedItemsSource = matchingItems[0];

    request = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
    self.allItemsCount = [self.document.managedObjectContext countForFetchRequest:request error:nil];
    if (!self.document.interface.selectedSource) self.document.interface.selectedSource = self.allItemsSource;
    [self addPaneWithSource:self.document.interface.selectedSource afterPane:nil associated:NO select:YES];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.sourceSplitView.animator setPosition:self.document.interface.sourceListWidth.doubleValue ofDividerAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetChangedNotification" object:self];
        self.interfaceLoaded = YES;
    });
}

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"SourceController windowWillClose notification: %@", notification);
    //    for (AssetListViewController *controller in self.panes) {
    //      if (controller.assetListViewer) {
    //        [controller.assetListViewer close];
    //            controller.assetListViewer = nil;
    //       }
    //  }
}

#pragma mark - Pane Control

- (void)addPaneAfterPane:(AssetListView *)pane {
    for (NSInteger index = 1; (index < self.sourceSplitView.subviews.count); index++) {
        AssetListView *view = self.sourceSplitView.subviews[index];
        if (view.controller.source == nil) {
            return;
        }
    }
    //    [self.sourceTreeController setSelectionIndexPath:[self.sourceTreeController indexPathOfObject:nil]];
    [self addPaneWithSource:nil afterPane:pane associated:NO select:NO];
}

- (void)addPaneWithSource:(Source *)source afterPane:(AssetListView *)pane associated:(BOOL)associated select:(BOOL)select {
    for (NSInteger index = 1; (index < self.sourceSplitView.subviews.count); index++) {
        AssetListView *view = self.sourceSplitView.subviews[index];
        if ((view.controller.source == source) && (!associated)) {
            return;
        }
    }
    
    AssetListViewController *controller = [[AssetListViewController alloc] initWithNibName:@"AssetListView" bundle:nil];
    controller.document = self.document;
    if (associated) {
        pane.controller.associatedController = controller;
        controller.associatedController = pane.controller;
        controller.isAssociatedPane = YES;
    }
    [self.sourceSplitView addSubview:controller.view positioned:NSWindowAbove relativeTo:pane];
    self.hasMoreThanOneTab = (self.sourceSplitView.subviews.count > 1) ? YES : NO;
    controller.source = source;
    if (select) [self.sourceTreeController setSelectionIndexPath:[self.sourceTreeController indexPathOfObject:source]];
}

- (void)showAssociatedItems:(AssetListViewController *)controller {
    if (!controller.associatedController) {
        [self addPaneWithSource:controller.source afterPane:controller.assetListView associated:YES select:NO];
    }
    else [self closeAssetListPane:controller.associatedController];
    
}

- (void)movePane:(AssetListView *)pane toPane:(AssetListView *)toPane {

    NSMutableOrderedSet *panes = [NSMutableOrderedSet orderedSetWithArray:self.sourceSplitView.subviews];
    NSIndexSet *indexes;
    NSInteger fromIndex = [panes indexOfObject:pane];
    NSInteger toIndex = [panes indexOfObject:toPane];
    
    if (pane.controller.isAssociatedPane) return;
    else if (pane.controller.associatedController) indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(fromIndex, 2)];
    else indexes = [NSIndexSet indexSetWithIndex:fromIndex];
    
    if (toPane.controller.associatedController) {
        if (fromIndex < toIndex) toIndex++;
    }
    if (pane.controller.associatedController) {
        if (fromIndex < toIndex) toIndex--;
    }
    
    [panes moveObjectsAtIndexes:indexes toIndex:toIndex];
    [self.sourceSplitView setSubviews:[panes array]];

}

- (IBAction)closeAssetListPane:(id)sender {
    if (self.sourceSplitView.subviews.count < 3) {
        [[NSSound soundNamed:@"Error"] play];
        return;
    }
    
    AssetListViewController *controller;
    if ([sender isKindOfClass:[AssetListViewController class]]) {
        controller = sender;
    }
    else {
        for (NSInteger index = 1; (index < self.sourceSplitView.subviews.count); index++) {
            AssetListView *view = self.sourceSplitView.subviews[index];
            if (view.controller.source == self.document.interface.selectedSource) {
                controller = view.controller;
                break;
            }
        }
    }
    if (!controller) return;
    
    if (controller.associatedController) {
        if (controller.isAssociatedPane) {
            controller.source = nil;
            controller.associatedController.associatedController = nil;
        }
        else {
            [self closeAssetListPane:controller.associatedController];
            return;
        }
    }
    
    if ((controller.source == self.document.interface.selectedSource)) {
        NSInteger index = [self.sourceSplitView.subviews indexOfObject:controller.assetListView];
        AssetListView *newView;
        if (index == 1) newView = self.sourceSplitView.subviews[(index + 1)];
        else newView = self.sourceSplitView.subviews[(index - 1)];
        [self.sourceTreeController setSelectionIndexPath:[self.sourceTreeController indexPathOfObject:newView.controller.source]];
    }
    
    
    NSRect removedPanel = controller.view.frame;
    removedPanel = [controller.view convertRect:removedPanel toView:self.document.documentWindow.contentView];
    CGFloat removedWidth = removedPanel.size.width;
    
    [controller.view removeFromSuperview];
    
    NSRect windowFrame = self.document.documentWindow.frame;
    NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
    CGFloat excessWidth = windowFrame.size.width - visibleFrame.size.width;
    if (excessWidth > 0) {
        if (removedWidth > excessWidth) removedWidth = excessWidth;
        windowFrame.size.width -= removedWidth;
        [self.document.documentWindow setFrame:windowFrame display:YES animate:YES];
    }
    
    self.hasMoreThanOneTab = (self.sourceSplitView.subviews.count > 1) ? YES : NO;
}


#pragma mark - Source Control


- (void)removeAssets:(NSArray *)assets fromSource:(Source *)source {
    if (((!source) || (![source.type isEqualToString:@"BatchSource"])) || (!assets.count)) {
        [[NSSound soundNamed:@"Error"] play];
        return;
    }
    NSMutableOrderedSet *batchAssets = source.batchAssets.mutableCopy;
    for (Asset *asset in assets) {
        
        [batchAssets removeObject:asset];

    }
    source.batchAssets = batchAssets;
}


- (void)addBatchSource:(AssetListViewController *)controller withAssets:(NSArray *)assets {
    Source *parent = [[self.sourceTreeController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:2]] representedObject];
    if (!assets) assets = @[];
    if ((controller) && (assets.count)) self.sourceName = [NSString stringWithFormat:@"PraxList from %@", controller.source.name];
    else self.sourceName = @"New Empty PraxList";
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"Please choose a name for the new PraxList"];
    [alert setAccessoryView:self.sourceNameAccessoryView];
    [alert addButtonWithTitle:@"Add PraxList"];
    [alert addButtonWithTitle:@"Cancel"];
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {

    
        
        Source *newSource = [Source addBatchSource:self.sourceName toParent:parent withArrangedAssets:assets inManagedObjectContext:self.document.managedObjectContext];
        [self addPaneWithSource:newSource afterPane:controller.assetListView associated:NO select:YES];
        [self.document.managedObjectContext processPendingChanges];
        [self.sourceTreeController rearrangeObjects];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSTreeNode *item = [self.sourceTreeController nodeOfObject:parent];
            [self.sourceListOutlineView.animator expandItem:item expandChildren:NO];
            NSIndexPath *indexPath = [self.sourceTreeController indexPathOfObject:newSource];
            [self.sourceTreeController setSelectionIndexPath:indexPath];
            
        });
    }
   
}


- (void)addSearchSource:(AssetListViewController *)controller withSource:(Source *)source {
    Source *parent = [[self.sourceTreeController.arrangedObjects descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:1]] representedObject];
    NSString *fetchEntity = @"Asset";
    NSString *predicateString;
    if (source) {
         self.sourceName = [NSString stringWithFormat:@"New Search from %@", source.name];
        fetchEntity = source.fetchEntity;
        predicateString = source.fetchPredicate.predicateFormat;
    }
    else self.sourceName = @"New Search";
    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"Please choose a name for the new Search"];
    [alert setAccessoryView:self.sourceNameAccessoryView];
    [alert addButtonWithTitle:@"Add New Search"];
    [alert addButtonWithTitle:@"Cancel"];
    NSInteger result = [alert runModal];
    if (result == NSAlertFirstButtonReturn) {
        
        
        
        Source *newSource = [Source addSearchSource:self.sourceName toParent:parent forEntity:fetchEntity withPredicateString:predicateString inManagedObjectContext:self.document.managedObjectContext];
        newSource.requiredTags = source.requiredTags;
        newSource.excludedTags = source.excludedTags;
        newSource.requireAllTags = source.requireAllTags;
        newSource.filterKeyIndex = source.filterKeyIndex;
        newSource.filterString = source.filterString;
        [self addPaneWithSource:newSource afterPane:controller.assetListView associated:NO select:YES];
        
        [self.document.managedObjectContext processPendingChanges];
        [self.sourceTreeController rearrangeObjects];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSTreeNode *item = [self.sourceTreeController nodeOfObject:parent];
            [self.sourceListOutlineView.animator expandItem:item expandChildren:NO];
            NSIndexPath *indexPath = [self.sourceTreeController indexPathOfObject:newSource];
            [self.sourceTreeController setSelectionIndexPath:indexPath];
            
        });
    }
    
    
}

- (void)doubleClickedSource {
    NSInteger row = [self.sourceListOutlineView clickedRow];
    if (row >= 0) {
        NSTreeNode *item = [self.sourceListOutlineView itemAtRow:row];
        Source *source = [item representedObject];
        if (!source.parent) return;
        
        if (source.children.count) {
            if (![self.sourceListOutlineView isItemExpanded:item]) {
                 [self.sourceListOutlineView.animator expandItem:item expandChildren:NO];
                return;
            }
            else if ([source.type isEqualToString:@"FolderSource"]) {
                [self.sourceListOutlineView.animator collapseItem:item];
                return;
            }
        }
        if (self.previousSource) {
 //           Source *previousSource = self.previousSources[0];
   //         [self.previousSources removeObjectAtIndex:0];
            [self.sourceTreeController setSelectionIndexPath:[self.sourceTreeController indexPathOfObject:self.previousSource]];
            self.previousSource = source;

            
         //   AssetListViewController *controller = self.panes[[self.sources indexOfObject:source]];
         //   [self.sources replaceObjectAtIndex:[self.sources indexOfObject:source] withObject:previousSource];
         //   controller.source = previousSource;
            [self addPaneWithSource:source afterPane:nil associated:NO select:NO];
        }
    }
}

-(NSArray *)sortDescriptors {
    return @[[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:TRUE]];
}

-(BOOL)sourceListVisible {
    if ([self.sourceSplitView isSubviewCollapsed:self.sourceListSubView]) return NO;
    else if (self.sourceListSubView.frame.size.width < 10) return NO;
    else return YES;
}


#pragma mark MenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    
    SEL action = [item action];
    
    if (action == @selector(closeAssetListPane:)) {
        
        [item setTitle:[NSString stringWithFormat:@"Close %@ List Pane", self.document.interface.selectedSource.name]];
        if (self.sourceSplitView.subviews.count > 2) return YES;
        else return NO;
    }
    
    else if (action == @selector(delete:)) {
        Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
        NSArray *dontDelete = @[@"LibrarySource", @"AccountSource", @"SubAccountSource"];
        for (NSString *entityName in dontDelete) {
            if ((!source) || ([entityName isEqualToString:source.type])) {
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
        if ((!source) || ([source.type isEqualToString:@"LibrarySource"])) {
            [item setHidden:YES];
            return NO;
        }
        
        [item setTitle:[NSString stringWithFormat:@"Open New List Pane with %@", source.name]];
        [item setHidden:NO];
        return YES;
    }
    
    else if (action == @selector(newSourceItem:)) {
        Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
        
        if ((!source) || ([source.name isEqualToString:@"LIBRARY"])) {
            [item setHidden:YES];
            return NO;
        }

        NSArray *dontShow = @[@"FolderSource", @"AccountSource", @"SubAccountSource"];
        for (NSString *entityName in dontShow) {
            if ([entityName isEqualToString:source.type]) {
                [item setHidden:YES];
                return NO;
            }
        }
        NSString *title;
        if (source.folderType) title = source.folderType;
        else title = source.type;
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

        if ((!source) || ([source.name isEqualToString:@"LIBRARY"])) {
            [item setHidden:YES];
            return NO;
        }
        
        NSArray *dontShow = @[@"LibrarySource", @"FolderSource", @"AccountSource", @"SubAccountSource"];
        for (NSString *entityName in dontShow) {
            if ([entityName isEqualToString:source.type]) {
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



#pragma mark - IBActions

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


- (IBAction)clearTags:(id)sender {
    self.document.interface.selectedSource.requiredTags = [NSSet setWithArray:@[]];
    self.document.interface.selectedSource.excludedTags = [NSSet setWithArray:@[]];
    self.document.interface.selectedSource.requireAllTags = 0;
}

- (IBAction)newListPaneWithSource:(id)sender {
    Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    [self addPaneWithSource:source afterPane:nil associated:NO select:YES];
}

- (IBAction)newSourceItem:(id)sender {
    Source *clickedSource = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    Source *parent;
    NSString *sourceType;
    
    if (clickedSource.folderType) {
        sourceType = clickedSource.folderType;
        parent = clickedSource;
    }
    else {
        sourceType = clickedSource.type;
        parent = clickedSource.parent;
    }
    if ([sourceType isEqualToString:@"BatchSource"]) {
        [self addBatchSource:nil withAssets:@[]];
    }
    else {
        Source *newSource = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
        newSource.type = sourceType;
        if ([sourceType isEqualToString:@"SearchSource"]) newSource.name = @"New Search";
        else if ([sourceType isEqualToString:@"PraxAssetSource"]) newSource.name = @"New Prax Asset";
        else newSource.name = [NSString stringWithFormat:@"New %@", sourceType];
        newSource.parent = parent;
        newSource.rowHeight = @30;
        
        [self.document.managedObjectContext processPendingChanges];
        [self.sourceTreeController rearrangeObjects];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSTreeNode *item = [self.sourceTreeController nodeOfObject:parent];
            [self.sourceListOutlineView.animator expandItem:item expandChildren:YES];
        });
    }
}



- (IBAction)newSourceFolder:(id)sender {
    Source *clickedSource = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    Source *parent;
    if ([clickedSource.type isEqualToString:@"FolderSource"]) parent = clickedSource.parent;
    else {
        parent = [NSManagedObject entity:@"Source" withKey:@"name" matchingStringValue:@"Folders" inManagedObjectContext:self.document.managedObjectContext];
    }
    
    Source *newFolder = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
    
    newFolder.type = @"FolderSource";
    newFolder.name = [NSString stringWithFormat:@"Folder with %@", clickedSource.name];
    newFolder.parent = parent;
    clickedSource.parent = newFolder;
    newFolder.rowHeight = @30;
    
    [self.document.managedObjectContext processPendingChanges];
    [self.sourceTreeController rearrangeObjects];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSIndexPath *indexPath = [self.sourceTreeController indexPathOfObject:newFolder];
        [self.sourceTreeController setSelectionIndexPath:indexPath];
        NSTreeNode *item = [self.sourceTreeController nodeOfObject:parent];
        [self.sourceListOutlineView.animator expandItem:item];
        item = [self.sourceTreeController nodeOfObject:newFolder];
        [self.sourceListOutlineView.animator expandItem:item];
    });
    
}



- (IBAction)delete:(id)sender {
    
    Source *source = [[self.sourceListOutlineView itemAtRow:[self.sourceListOutlineView clickedRow]] representedObject];
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to delete this Source item?" defaultButton:@"Cancel" alternateButton:@"Delete" otherButton:nil informativeTextWithFormat:@"The Source item: %@ will be deleted if you press Delete!", source.name];
    if (![alert runModal]) {
        
        [self.document.managedObjectContext deleteObject:source];
        [self.document.managedObjectContext processPendingChanges];
        [self.sourceTreeController rearrangeObjects];
        
    }
}

- (IBAction)newPraxAsset:(id)sender {

    NSString *folderType = @"PraxAssetSource";
    NSArray *librarySources = (NSArray *)[self.sourceTreeController.arrangedObjects childNodes];
    
    NSUInteger index = [librarySources indexOfObjectPassingTest:^BOOL(NSTreeNode *obj, NSUInteger idx, BOOL *stop) {
        if ([[(Source *)obj.representedObject entity].name isEqualToString:@"LibrarySource"] && [[(Source *)obj.representedObject folderType] isEqualToString:folderType]) return YES;
        else return NO;
    }];
    if (index != NSNotFound) {
        Source *parent = [(NSTreeNode *)librarySources[index] representedObject];
        [Source addPraxAssetSource:@"New Prax Asset" toParent:parent inManagedObjectContext:self.document.managedObjectContext];
        [self.sourceTreeController rearrangeObjects];
    }
}




- (IBAction)toggleSourceList:(id)sender {
    
    if ([self.sourceSplitView isSubviewCollapsed:self.sourceListSubView]) {
        [self.sourceSplitView.animator setPosition:self.document.interface.sourceListWidth.doubleValue ofDividerAtIndex:0];
    }
    else {
        [self.sourceSplitView.animator setPosition:0 ofDividerAtIndex:0];
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
    return YES;
    //    NSInteger index = [self.sources indexOfObject:source];
    //    if (index == NSNotFound) return YES;
    //   else {
    //       [self selectAssetListPane:self.panes[index]];
    //       return NO;
    //  }
}

/*- (void)outlineView:(NSOutlineView *)outlineView didSelectItem:(id)item {
 if (![outlineView isItemExpanded:item]) [outlineView expandItem:item];
 else [outlineView collapseItem:item];
 
 }*/

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
//    AssetListViewController *controller;
  //  for (NSInteger index = 1; (index < self.sourceSplitView.subviews.count); index++) {
    //    AssetListView *view = self.sourceSplitView.subviews[index];
      //  if (view.controller.isSelectedPane) {
        //    controller = view.controller;
    //    }
   // }
    self.previousSource = self.document.interface.selectedSource;
    NSInteger row = [self.sourceListOutlineView selectedRow];
    if (row >= 0) {
        NSTableCellView *view = [self.sourceListOutlineView viewAtColumn:0 row:row makeIfNecessary:FALSE];
        if (!view) {
            [Prax presentAlert:@"(!view) [self.sourceListOutlineView viewAtColumn:0 row:row makeIfNecessary:FALSE]" forController:self];
            return;
        }
        self.document.interface.selectedSource = view.objectValue;
    }
    else self.document.interface.selectedSource = nil;
//    if (controller) controller.source = self.document.interface.selectedSource;

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

#pragma mark - <NSPasteboardWriting>

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
    
    if ((sourceListWidth > 150) && (self.interfaceLoaded)) {
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
