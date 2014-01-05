//
//  AssetListViewController.m
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetListViewController.h"

@implementation AssetListViewController

#pragma mark - Initialization

- (NSArray *)keyPathsToObserve {return @[@"self.changedAssetArrayController.arrangedObjects", @"self.assetArrayController.sortDescriptors", @"self.assetArrayController.selectionIndexes", @"self.associatedController.assetArrayController.selectionIndexes", @"self.isSelectedPane", @"self.source", @"self.source.batchAssets", @"self.source.fetchPredicate", @"self.source.requiredTags", @"self.document.interface.selectedSource", @"self.source.requireAllTags", @"self.source.itemCount", @"self.source.excludedTags", @"self.source.template", @"self.source.template.formatText", @"self.showDetailView", @"self.showCodeView", @"self.showSafariView", @"self.exportCode", @"self.formattedCode"];}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"AssetListViewController initWithNibName: %@", nibNameOrNil);

   /*     [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.detailScrollView queue:nil usingBlock:^(NSNotification *aNotification){
            NSRect documentRect = [self.detailScrollView.documentView bounds];
            NSRect scrollViewRect = self.detailScrollView.frame;
            if (scrollViewRect.size.width >= 500) {
                documentRect.size.width = (scrollViewRect.size.width - 2);
                [self.detailScrollView.documentView setFrame:documentRect];
            }
         }];
*/
    }
    return self;
}

- (void)dealloc {
    NSLog(@"AssetListViewController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}


- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AssetListViewController init");
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"AssetListViewController awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
        [self.assetsTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"org.ElmerCat.PraxPress.Asset", nil]];
        self.showDetailView = NO;
//        CGFloat newPosition = [self.splitView maxPossiblePositionOfDividerAtIndex:0];
 //       [self.splitView setPosition:newPosition ofDividerAtIndex:0 animated:NO];
    }
}


#pragma mark ------

- (void)tagFilterAssets {
    NSMutableSet *excludedAssets = [NSMutableSet setWithCapacity:1];
    NSMutableSet *requiredAssets = [NSMutableSet setWithCapacity:1];
    NSMutableOrderedSet *tagFilteredAssets  = self.assets.mutableCopy;
    if (self.source.requiredTags.count > 0) {
        
        if (self.source.requireAllTags.boolValue) {
            BOOL multiple = NO;
            for (Tag *tag in self.source.requiredTags) {
                if (multiple) {
                    [requiredAssets intersectSet:tag.assets];
                }
                else {
                    [requiredAssets unionSet:tag.assets];
                    multiple = YES;
                }
            }
        }
        else {
            for (Tag *tag in self.source.requiredTags) {
                [requiredAssets unionSet:tag.assets];
            }
        }
        [tagFilteredAssets intersectSet:requiredAssets];
        
    }
    
    for (Tag *tag in self.source.excludedTags) {
        [excludedAssets unionSet:tag.assets];
    }
    [tagFilteredAssets minusSet:excludedAssets];
    [self.assetArrayController setContent:[tagFilteredAssets array]];
}

- (void)loadAssociatedItems {
    if (!self.associatedController.source) return;
    NSMutableOrderedSet *associatedItems = [NSMutableOrderedSet orderedSetWithCapacity:1];
    self.isPlaylist = NO;
    
    if ([self.associatedController.assetArrayController.selectedObjects count] > 0) {
        for (Asset *selectedAsset in self.associatedController.assetArrayController.selectedObjects) {
            [associatedItems unionOrderedSet:selectedAsset.associatedItems];
            if ([self.associatedController.assetArrayController.selectedObjects count] == 1) {
                if ([[selectedAsset valueForKey:@"type"] isEqualToString:@"playlist"]) {
                    self.isPlaylist = YES;
                }
            }
        }
        [self.assetArrayController setContent:[associatedItems array]];
    }
    
}

- (void)removeAssociatedItems:(NSArray *)items fromAssets:(NSArray *)assets {
    if (assets.count) {
        for (Asset *asset in assets) {
            if ((![asset.type isEqualToString:@"playlist"]) || (!items.count)) {
                [[NSSound soundNamed:@"Error"] play];
                return;
            }
            NSMutableOrderedSet *associatedItems = asset.associatedItems.mutableCopy;
            for (Asset *item in items) {
                
                [associatedItems removeObject:item];
            }
            asset.associatedItems = associatedItems;
        }
    }
}

- (void)filterPane {
    [self.searchField selectText:self];
    
}

- (void)updateFormattedCode:sender {
    @synchronized(self) {
        if (self.updatingFormattedCode) return;
        else self.updatingFormattedCode = YES;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSString *newFormattedCode = @"";
        if (self.exportCode) {
            
            if ((self.source) && ([self.assetArrayController.selectedObjects count] > 0)) {
                newFormattedCode = [TemplateController codeForTemplate:self.source.template.formatText withAssets:self.assetArrayController.selectedObjects];
            }
        }
        if (![newFormattedCode isEqualToString:self.formattedCode]) {
            self.formattedCode = newFormattedCode;
        }
        self.updatingFormattedCode = NO;
    });

    
}

- (void)initAppleScript {
    self.appleScriptSource = [NSString stringWithFormat:@"tell application \"Safari\"\rset theURL to \"%@\"\rset foundTab to false\rset windowCount to number of window\rrepeat with theWindow from 1 to windowCount\rtry\rset tabCount to number of tabs in window theWindow\rif (tabCount > 0) then\rrepeat with theTab from 1 to tabCount\rset tabName to name of tab theTab of window theWindow\rif (exists URL of tab theTab of window theWindow) then\rset tabURL to URL of tab theTab of window theWindow\rif (tabURL = theURL) then\rset foundTab to true\rend if\rend if\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rend if\rend try\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rif (foundTab = true) then\rset URL of tab theTab of window theWindow to theURL\relse\rmake new document at end of documents with properties {URL:theURL}\rend if\rend tell", self.exportCodeURL.absoluteString];
    self.appleScript = nil;
    self.appleScript = [[NSAppleScript alloc] initWithSource:self.appleScriptSource];
}

- (void)writeFormattedCode {
    if (!self.document.exportCodeDirectory) return;
    
    if (!self.exportCodeURL) {
        NSString *filename = [self.source.name lowercaseString];
        filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        self.exportCodeURL = [self.document.exportCodeDirectory URLByAppendingPathComponent:filename];
        self.exportCodeURL = [self.exportCodeURL URLByAppendingPathExtension:@"html"];
    }

    NSError *error;
    [self.exportCodeURL startAccessingSecurityScopedResource];
    BOOL ok = [self.formattedCode writeToURL:self.exportCodeURL atomically:YES
                                            encoding:NSUnicodeStringEncoding error:&error];
    [self.exportCodeURL stopAccessingSecurityScopedResource];
    if (!ok) {
        NSString *text = [NSString stringWithFormat:@"Error writing file\nself.source.exportURL.path: %@\nlocalizedFailureReason: %@", self.source.exportURL.path, [error localizedFailureReason]];
        [Prax presentAlert:text forController:self];
        self.document.exportCodeDirectory = nil;
        if (!self.document.exportCodeDirectory) {
            self.showSafariView = NO;
            self.exportCode = NO;
            [Prax presentAlert:@"self.document.exportCodeDirectory is nil" forController:self];
        }
        else [self writeFormattedCode];
        
    }
    else {
        if ((self.showSafariView) && (![self.formattedCode isEqualToString:@""])) {
            if (!self.appleScript) [self initAppleScript];
            NSDictionary *errorInfo;
            if (![self.appleScript executeAndReturnError:&errorInfo]) {
                [Prax presentAlert:[NSString stringWithFormat:@"showSafariView AppleScript error: %@", errorInfo] forController:self];
            }
            
        }
    }
}

- (void)showTags:(NSSet *)tags sender:(id)sender {
    NSLog(@"tags %@", [tags description]);
    
}

- (void)openBrowserWithURLString:(NSString *)string {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:string]];
}

- (void)showMetadataPopover:(NSDictionary *)metadata sender:(id)sender {
    NSLog(@"metadata %@", [metadata description]);
    [self.assetMetadataPopover showPopoverRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge withDictionary:metadata];
}


#pragma mark - IBActions


- (IBAction)selectAssetListPane:(id)sender {
    [self.document.sourceController selectAssetListPane:self];
    //    self.isSelectedPane = YES;
}

- (IBAction)updateFilter:sender {
    NSString *searchString = [self.searchField stringValue];
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", searchString];
        [self.assetArrayController setFilterPredicate:predicate];
    }
    else [self.assetArrayController setFilterPredicate:nil];
}

- (IBAction)exportFormattedCode:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"html"]];
    [panel setAllowsOtherFileTypes:YES];
    [panel setMessage:@"Export Code to File"];
    if (self.source.exportURL) {
        [panel setDirectoryURL:[self.source.exportURL URLByDeletingLastPathComponent]];
        [panel setNameFieldStringValue:[self.source.exportURL lastPathComponent]];
    }
    [panel beginSheetModalForWindow:self.document.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            
            self.source.exportURL = panel.URL;
            self.appleScript = nil;
            [self writeFormattedCode];
        }
        
    }];
}

- (IBAction)filterButtonClicked:(id)sender {
    if ([self.sourceInfoPanel.window isVisible]) {
        [self.sourceInfoPanel.window close];
    }
    else {
        [self showSourceInfoPanel:sender];
    }
}

- (IBAction)showSourceInfoPanel:(id)sender {
    if (!self.sourceInfoPanel) {
        self.sourceInfoPanel = [[SourceInfoPanel alloc] initWithWindowNibName:@"SourceInfoPanel"];
        self.sourceInfoPanel.assetListViewController = self;
    }
    [self.sourceInfoPanel showSourceInfoPanel];
}

- (void)doubleClickedArrayObjects:(NSArray *)arrayObjects {
    if (self.showDetailView) {
        self.showDetailView = NO;
    }
    else {
        self.showDetailView = YES;
    }
}

- (IBAction)templatesButtonPressed:(id)sender {
    self.document.templateController.assetListView = self;
    [self.document.templateController.panel makeKeyAndOrderFront:self];
}

#pragma mark - KeyValueObservation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    
    
    if ([keyPath isEqualToString:@"self.changedAssetArrayController.arrangedObjects"]) {
        if ([(NSArray *)self.changedAssetArrayController.arrangedObjects count]) {
            [self.splitViewTopConstraint.animator setConstant:60];
        }
        else {
            [self.splitViewTopConstraint.animator setConstant:36];
        }
        
    }
    
    else if ([keyPath isEqualToString:@"self.document.interface.selectedSource"]) {
        if (self.source == self.document.interface.selectedSource) self.isSelectedPane = YES;
        else self.isSelectedPane = NO;
    }
    
    else if ([keyPath isEqualToString:@"self.isSelectedPane"]) {
        //        CGFloat selectedPaneAlpha = 0;
        //        CGFloat notSelectedPaneAlpha = 1;
        if (self.isSelectedPane) {
            //            selectedPaneAlpha = 1;
            //            notSelectedPaneAlpha = 0;
        }
    }
    
    else if ([keyPath isEqualToString:@"self.showDetailView"]) {
        CGFloat newPosition = [self.splitView maxPossiblePositionOfDividerAtIndex:0];
        if (self.showDetailView) newPosition -= 300;
        //  [[self.splitView animator] setPosition:newPosition ofDividerAtIndex:0];
        //  [self.splitView setPosition:newPosition ofDividerAtIndex:0 animated:YES];
        [self.splitView setPosition:newPosition ofDividerAtIndex:0];
    }
    
    else if ([keyPath isEqualToString:@"self.showSafariView"]) {
        if (self.showSafariView) {
            [self writeFormattedCode];
        }
    }
    
    else if ([keyPath isEqualToString:@"self.exportCode"]) {
        if (self.exportCode) {
            [self updateFormattedCode:self];
        }
        else self.showSafariView = NO;
    }
    
    else if ([keyPath isEqualToString:@"self.formattedCode"]) {
        if (self.exportCode) {
            [self writeFormattedCode];
        }
    }
    
    else if ([keyPath isEqualToString:@"self.assetArrayController.sortDescriptors"]) {
        if (self.isPlaylist) {
            if ([self.assetArrayController.sortDescriptors count] > 0) {
                Asset *playlist = self.associatedController.assetArrayController.selectedObjects[0];
                playlist.associatedItems = [[NSOrderedSet alloc] initWithArray:self.assetArrayController.arrangedObjects];
            }
        }
        
        else if ([self.source.type isEqualToString:@"BatchSource"]) {
            if ([self.assetArrayController.sortDescriptors count] > 0) {
                self.source.batchAssets = [[NSOrderedSet alloc] initWithArray:self.assetArrayController.arrangedObjects];
            }
        }
    }
    else if ([keyPath isEqualToString:@"self.associatedController.assetArrayController.selectionIndexes"]) {
        if (self.isAssociatedPane) {
            [self loadAssociatedItems];
            
        }
        
    }
    else if ([keyPath isEqualToString:@"self.assetArrayController.selectionIndexes"]) {
        
        NSString *listType = [self.assetArrayController.selectedObjects praxPressListType];
        NSView *detailView;
        
        if ([listType isEqualToString:@"no-selection"]) {
            detailView = self.noSelectionView;
        }
        else {
            detailView = self.assetDetailView;
        }
        if (self.detailViewBox.contentView != detailView) {
            [self.detailViewBox setContentView:detailView];
        }
        
        self.duration = self.playback_count = self.favoritings_count = self.download_count = self.comment_count = 0;
        
        if ((self.source) && ([self.assetArrayController.selectedObjects count] > 0)) {
            for (Asset *asset in self.assetArrayController.selectedObjects) {
                self.duration += asset.duration.intValue;
                self.playback_count += asset.playback_count.intValue;
                self.favoritings_count += asset.favoritings_count.intValue;
                self.download_count += asset.download_count.intValue;
                self.comment_count += asset.comment_count.intValue;
            }
        }
        
        [self updateFormattedCode:self];
        
    }
    else if ([@[@"self.source.excludedTags", @"self.source.requiredTags", @"self.source.requireAllTags"] containsObject:keyPath]) {
        [self tagFilterAssets];
    }
    else if ([@[@"self.source.itemCount", @"self.source", @"self.source.batchAssets", @"self.source.fetchPredicate"] containsObject:keyPath]) {
        
        if (!self.isAssociatedPane) {
            [self reloadAssets];
            if ([keyPath isEqualToString:@"self.source"]) {
                self.exportCodeURL = nil;
                self.appleScript = nil;
                
                if (self.source == self.document.interface.selectedSource) self.isSelectedPane = YES;
                else self.isSelectedPane = NO;

            }
        }
    }
    else if ([@[@"self.source.template", @"self.source.template.formatText"] containsObject:keyPath]) {
        [self updateFormattedCode:self];
    }
    
}

- (void) reloadAssets {
    if (!self.source) return;
    
    
    @synchronized(self) {
        if (self.reloadingAssets) return;
        else self.reloadingAssets = YES;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.isAssociatedPane) {
            [self loadAssociatedItems];
        }
        else {
            if ([self.source.type isEqualToString:@"BatchSource"]) {
                self.isBatch = YES;
                
                self.assets = [NSOrderedSet orderedSetWithOrderedSet:self.source.batchAssets];
                [self.assetsTableView setSortDescriptors:nil];
                
            }
            else {
                self.isBatch = NO;
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
                NSError *error;
                [request setPredicate:self.source.fetchPredicate];
                NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
                self.assets = [NSOrderedSet orderedSetWithArray:matchingItems];
            }
            if (self.source.itemCount.integerValue != self.assets.count) self.source.itemCount = [NSNumber numberWithInteger:self.assets.count];
            
            [self tagFilterAssets];
            
            //  [self.assetArrayController setContent:[self.assets array]];
            
            if ((self.source.filterString != nil) && (![self.source.filterString isEqualToString:@""])) {
                NSPredicate *predicate;
                if ((self.source.filterKey != nil) && (![self.source.filterKey isEqualToString:@""])) {
                    predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", self.source.filterKey, self.source.filterString];
                }
                else {
                    predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", self.source.filterString];
                }
                [self.assetArrayController setFilterPredicate:predicate];
            }
            else [self.assetArrayController setFilterPredicate:nil];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self updateFormattedCode:self];
            });
        }
        
        self.reloadingAssets = NO;
    });
    
}


#pragma mark - <NSSplitViewDelegate>


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

#pragma mark - <NSTableViewDelegate>


- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    Asset *asset = self.assetArrayController.arrangedObjects[row];
    NSURL *assetURL = [asset.objectID URIRepresentation];
 	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:assetURL];

    NSPasteboardItem *pasteboardItem = [NSPasteboardItem new];
    [pasteboardItem setDataProvider:self forTypes:self.assetDraggingTypes];

	[pasteboardItem setData:data forType:@"org.ElmerCat.PraxPress.Asset"];
    
//    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pasteboardItem];
 //   NSRect draggingRect = self.bounds;
  //  NSImage *dragImage = [[NSImage alloc] initWithData:[self.superview dataWithPDFInsideRect:[self.superview bounds]]];
   // [draggingItem setDraggingFrame:draggingRect contents:dragImage];
    //NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:@[draggingItem] event:event source:self];
   // draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
  //  draggingSession.draggingFormation = NSDraggingFormationNone;
//}

    
    return pasteboardItem;
    
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard {
    NSMutableArray * objects = [NSMutableArray array];
    NSArray * draggedObjects = [self.assetArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
    for (NSManagedObject * o in draggedObjects) {
        [objects addObject:[[o objectID] URIRepresentation]];
    }
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:objects];
	[pasteboard declareTypes:self.assetDraggingTypes owner:self];
	[pasteboard setData:data forType:@"org.ElmerCat.PraxPress.Asset"];
//    [pasteboard setdataP]
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)table validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (([self.source.type isEqualToString:@"BatchSource"]) || (self.isAssociatedPane)) {
            if (operation == NSTableViewDropOn) [table setDropRow:row dropOperation:NSTableViewDropAbove];
            return NSDragOperationMove;
        }
    else return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView *)table acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    
    NSMutableArray *droppedAssets = @[].mutableCopy;
    
    for (NSPasteboardItem *item in [[info draggingPasteboard] pasteboardItems]) {
        NSData *data = [item dataForType:@"org.ElmerCat.PraxPress.Asset"];
        if (data) {
            NSURL *objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            if (objectURL) {
                NSManagedObjectID *objectID = objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
                if (objectID) {
                    Asset *asset = (Asset *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
                    if (asset) [droppedAssets addObject:[self.document.managedObjectContext existingObjectWithID:objectID error:NULL]];
                }
            }
        }
    }

    if (droppedAssets.count) {
        
        NSMutableOrderedSet *rearrangedAssets = [NSMutableOrderedSet orderedSetWithArray:self.assetArrayController.arrangedObjects];
        [self.assetsTableView setSortDescriptors:nil];
        NSInteger insertionRow = row;
        
        for (Asset *asset in droppedAssets) {
            
    //        if (!((self.isPlaylist) && (![asset.type isEqualToString:@"track"]))) {
                NSInteger oldRow = [rearrangedAssets indexOfObject:asset];
                if (oldRow < insertionRow) insertionRow--;
                [rearrangedAssets removeObject:asset];
                [rearrangedAssets insertObject:asset atIndex:insertionRow];
                insertionRow++;
    //        }
        }
        if (self.isPlaylist) {
            Asset *playlist = self.associatedController.assetArrayController.selectedObjects[0];
            playlist.associatedItems = rearrangedAssets;
        }
        else if (self.isAssociatedPane) {
            for (Asset *associatingAsset in self.associatedController.assetArrayController.selectedObjects) {
                
                associatingAsset.associatedItems = rearrangedAssets;
            }
        }
        else if ([self.source.type isEqualToString:@"BatchSource"]) {
            self.source.batchAssets = rearrangedAssets;
        }
        [self.assetArrayController setContent:[rearrangedAssets array]];
        return YES;
    }
    else return NO;
}

- (BOOL)praxtableView:(NSTableView *)table acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    
	NSPasteboard *pasteboard = [info draggingPasteboard];
	NSData *data = [pasteboard dataForType:@"org.ElmerCat.PraxPress.Asset"];
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


#pragma mark - <NSPasteboardWriting>

- (NSArray *)sourceDraggingTypes {
    return @[@"org.ElmerCat.PraxPress.Source",
             NSPasteboardTypeTIFF,
             //      @"public.file-url",
             //               @"public.url",
             //   @"public.jpeg",
             @"public.tiff"
             //             @"public.html",
             //             @"public.utf8-plain-text",
             //             @"public.text",
             //  @"public.png",
             //  @"com.adobe.pdf",
             //             NSPasteboardTypeString,
             //             NSPasteboardTypeHTML
             ];
    
}


- (NSArray *)assetDraggingTypes {
    return @[@"org.ElmerCat.PraxPress.Asset",
             NSPasteboardTypeTIFF,
             //      @"public.file-url",
             //               @"public.url",
             //   @"public.jpeg",
             @"public.tiff"
             //             @"public.html",
             //             @"public.utf8-plain-text",
             //             @"public.text",
             //  @"public.png",
             //  @"com.adobe.pdf",
             //             NSPasteboardTypeString,
             //             NSPasteboardTypeHTML
             ];
    
}


- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    
    NSLog(@"%@", type);
    
    NSData *data = [item dataForType:@"org.ElmerCat.PraxPress.Asset"];
	NSURL *objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSManagedObjectID *objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
    Asset *asset = (Asset *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
    
    
    if ([@"public.tiff" isEqualToString:type] || [NSPasteboardTypeTIFF isEqualToString:type]) {
        [item setData:[[NSUnarchiver unarchiveObjectWithData:[asset image]] TIFFRepresentation] forType:type]; }
    
    else if ([@"public.file-url" isEqualToString:type]) {
        [item setString:[NSString stringWithFormat:@"%@", asset.permalink_url] forType:type];
        
        
        
        return;
        
        
        
        NSURL *url = [NSURL URLWithString:asset.permalink_url];
        
        id propertyList = [url pasteboardPropertyListForType:(NSString *)kUTTypeFileURL];
        
        [item setPropertyList:propertyList forType:type];
        
    }
    
    else if ([@[@"public.utf8-plain-text",
                @"public.html",
                @"public.text"] containsObject:type]) {
        [item setString:[NSString stringWithFormat:@"%@", asset.title] forType:type]; }
    
    else {
        NSLog(@"Unable to provideDataForType: %@", type);
        
    }
    
    
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type {
    NSLog(@"%@", type);
    
    
    NSData *data = [sender dataForType:@"org.ElmerCat.PraxPress.Asset"];
	NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSManagedObjectID *objectID;
    Asset *asset;
    NSMutableString *string = @"PraxPress Items:".mutableCopy;
    
    for (NSURL *objectURL in objects) {
        objectID = [self.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
        asset = (Asset *)[self.document.managedObjectContext existingObjectWithID:objectID error:NULL];
        NSLog(@"asset.title: %@", asset.title);
        
        if ( [type compare: NSPasteboardTypeTIFF] == NSOrderedSame ) {
            
            //       [sender setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
            
        } else if ( [type compare: NSPasteboardTypePDF] == NSOrderedSame ) {
            
            //            [sender setData:[self.view dataWithPDFInsideRect:[self.view bounds]] forType:NSPasteboardTypePDF];
            
        } else if ( [type compare:@"org.ElmerCat.PraxPress.Asset"] == NSOrderedSame ) {
            NSLog(@"%@", type);
            
            
        } else if ( [type compare:@"public.text"] == NSOrderedSame ) {
            
            [string appendFormat:@"\n%@", asset.title];
            
        } else if ( [type compare:NSPasteboardTypeHTML] == NSOrderedSame ) {
            [string appendFormat:@"\n%@", asset.title];
            
            
        } else if ( [type compare:@"public.utf8-plain-text"] == NSOrderedSame ) {
            [string appendFormat:@"\n%@", asset.title];
        }
        else {
            NSLog(@"%@", type);
            
            
        }
        
    }
    [sender setString:string forType:type];
    
    
}


- (void)mouseDown:(NSEvent *)theEvent {
    // mouseInCloseBox and trackingCloseBoxHit are instance variables
//    if (mouseInCloseBox = NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], closeBox)) {
//        trackingCloseBoxHit = YES;
//        [self setNeedsDisplayInRect:closeBox];
//    }
//    else if ([theEvent clickCount] > 1) {
//        [[self window] miniaturize:self];
//        return;
//    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
//    NSPoint windowOrigin;
//    NSWindow *window = [self window];
    
//    if (trackingCloseBoxHit) {
//        mouseInCloseBox = NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], closeBox);
//        [self setNeedsDisplayInRect:closeBox];
//        return;
//    }
    
//    windowOrigin = [window frame].origin;
    
//    [window setFrameOrigin:NSMakePoint(windowOrigin.x + [theEvent deltaX], windowOrigin.y - [theEvent deltaY])];
}

- (void)mouseUp:(NSEvent *)theEvent {
//    if (NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], closeBox)) {
//        [self tryToCloseWindow];
//        return;
//    }
//    trackingCloseBoxHit = NO;
//    [self setNeedsDisplayInRect:closeBox];
}

//- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack {
    
    
//}

#pragma mark - <NSTokenFieldDelegate>


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
