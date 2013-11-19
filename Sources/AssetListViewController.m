//
//  AssetListViewController.m
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetListViewController.h"

@interface AssetListViewController ()

@end

@implementation AssetListViewController

- (NSArray *)keyPathsToObserve {return @[@"self.assetArrayController.sortDescriptors", @"self.assetArrayController.selectionIndexes", @"self.associatedController.assetArrayController.selectionIndexes", @"self.isSelectedPane", @"self.source", @"self.tags", @"self.source.fetchPredicate", @"self.source.requiredTags", @"self.source.requireAllTags", @"self.source.excludedTags", @"self.source.template", @"self.source.template.formatText", @"self.showDetailView", @"self.showCodeView", @"self.showWebView", @"self.showSafariView", @"self.formattedCode", @"self.webView.estimatedProgress"];}

- (NSDictionary *)toolTips {return @{@"stats":@"Duration\rPlayback Count\rFavorites\rDownloads\rComments", @"permalink":@"Permalink Slug", @"reload":@"Reload - Cancel changes and re-download data from server", @"upload":@"Upload - Save changes and upload data to server"};}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"AssetListViewController initWithNibName: %@", nibNameOrNil);

        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.source"]) {
        self.appleScript = nil;
    }
    
    if ([keyPath isEqualToString:@"self.tags"]) {
       
        
    }
    
    
//    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"self.isSelectedPane"]) {
        CGFloat selectedPaneAlpha = 0;
        CGFloat notSelectedPaneAlpha = 1;
        if (self.isSelectedPane) {
            selectedPaneAlpha = 1;
            notSelectedPaneAlpha = 0;
        }
        [self.selectedButton.animator setAlphaValue:selectedPaneAlpha];
        [self.notSelectedButton.animator setAlphaValue:notSelectedPaneAlpha];
        
    }
    else if ([keyPath isEqualToString:@"self.showDetailView"]) {
        [self updatePaneSizes:keyPath];
        
    }
    
    else if (([keyPath isEqualToString:@"self.showCodeView"])||([keyPath isEqualToString:@"self.showWebView"])) {
        [self updateFormattedCode:self];
        [self updatePaneSizes:keyPath];
        
        
    }
    else if ([keyPath isEqualToString:@"self.showSafariView"]) {
        if (self.showSafariView) {
            [self updateFormattedCode:self];
        }
    }
    
    else if ([keyPath isEqualToString:@"self.webView.estimatedProgress"]) {
        
        double estimatedProgress = [self.webView estimatedProgress];
        NSLog(@"AssetListViewController self.webView.estimatedProgress: %f", estimatedProgress);
        
        //      [self.progressIndicator setDoubleValue:self.webView.estimatedProgress];
        
    }
    else if ([keyPath isEqualToString:@"self.formattedCode"]) {
        if (self.showWebView) {
            [[self.webView mainFrame] loadHTMLString:self.formattedCode baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        }
        else [[self.webView mainFrame] loadHTMLString:@"" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        if (self.showSafariView) {
            [self writeFormattedCode:self];
        }
        
    }
    else if ([keyPath isEqualToString:@"self.assetArrayController.sortDescriptors"]) {
        if (self.isPlaylist) {
            if ([self.assetArrayController.sortDescriptors count] > 0) {
                Asset *playlist = self.associatedController.assetArrayController.selectedObjects[0];
                playlist.associatedItems = [[NSOrderedSet alloc] initWithArray:self.assetArrayController.arrangedObjects];
            }
        }

        else if ([self.source.entity.name isEqualToString:@"BatchSource"]) {
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
        
        if (([listType isEqualToString:@"track"]) || ([listType isEqualToString:@"tracks"])){
            detailView = self.trackDetailView;
        }
        else if (([listType isEqualToString:@"playlist"]) || ([listType isEqualToString:@"playlists"])) {
            detailView = self.playlistDetailView;
        }
        else if ([listType isEqualToString:@"SoundCloud"]) {
            detailView = self.soundCloudDetailView;
        }
        else if ((([listType isEqualToString:@"post"]) || ([listType isEqualToString:@"page"])) || ((([listType isEqualToString:@"posts"]) || ([listType isEqualToString:@"pages"])) || ([listType isEqualToString:@"WordPress"]))) {
            detailView = self.wordPressDetailView;
        }
        else if ([listType isEqualToString:@"no-selection"]) {
            detailView = self.noSelectionView;
        }
        else {
            detailView = self.defaultDetailView;
        }
        if (self.detailViewBox.contentView != detailView) {
            [self.detailViewBox setContentView:detailView];
        }
        
/*        if (self.assetArrayController.selectedObjects.count > 0) {
            Asset *asset = self.assetArrayController.selectedObjects[0];
            if ([asset.type isEqualToString:@"track"]) {
                [self.detailScrollView setDocumentView:self.trackDetailView];
                
            }
            else [self.detailScrollView setDocumentView:self.defaultDetailView];
            //       [self.trackDetailView setAutoresizingMask:NSViewWidthSizable];
            
            NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.detailScrollView.documentView attribute:NSLayoutAttributeRight
             relatedBy:NSLayoutRelationEqual
             toItem:self.view
             attribute:NSLayoutAttributeRight
             multiplier:1.0f constant:-20.0f];
             [self.detailScrollView.contentView addConstraint:constraint]; 
            
            NSPoint newScrollOrigin;
            // assume that the scrollview is an existing variable
            if ([[self.detailScrollView documentView] isFlipped]) {
                newScrollOrigin=NSMakePoint(0.0,0.0);
            } else {
                newScrollOrigin=NSMakePoint(0.0,NSMaxY([[self.detailScrollView documentView] frame])
                                            -NSHeight([[self.detailScrollView contentView] bounds]));
            }
            CGPoint setOrigin = CGPointMake(newScrollOrigin.x , newScrollOrigin.y + 172.0f);
            [[self.detailScrollView documentView] scrollPoint:setOrigin];
            
        }
    */
        self.duration = self.playback_count = self.favoritings_count = self.download_count = self.comment_count = 0;

        NSMutableArray *tagArray = [@[] mutableCopy];
        if ((self.source) && ([self.assetArrayController.selectedObjects count] > 0)) {
            for (Asset *asset in self.assetArrayController.selectedObjects) {
                self.duration += asset.duration.intValue;
                self.playback_count += asset.playback_count.intValue;
                self.favoritings_count += asset.favoritings_count.intValue;
                self.download_count += asset.download_count.intValue;
                self.comment_count += asset.comment_count.intValue;

            }
            
            Asset *asset = self.assetArrayController.selectedObjects[0];
            NSSet *tags = asset.tags;
            for (Tag *tag in tags) {
                [tagArray addObject:tag.name];
            }
        }
        self.tags = [tagArray mutableCopy];

        
        
        [self updateFormattedCode:self];
        
    }
    else {

        if ((([keyPath isEqualToString:@"self.source.excludedTags"]) || ([keyPath isEqualToString:@"self.source.requiredTags"])) || ([keyPath isEqualToString:@"self.source.requireAllTags"])) {
            NSMutableSet *excludedAssets = [NSMutableSet setWithCapacity:1];
            NSMutableSet *requiredAssets = [NSMutableSet setWithCapacity:1];
            NSMutableOrderedSet *tagFilteredAssets  = self.assets.mutableCopy;
            if (self.source.requiredTags.count > 0) {
                
                if (self.source.requireAllTags.boolValue) {
                    BOOL multiple;
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
        if (([keyPath isEqualToString:@"self.source"]) || ([keyPath isEqualToString:@"self.source.fetchPredicate"])) {
            if (!self.source) return;
        
            if (self.isAssociatedPane) {
                [self loadAssociatedItems];
            }
            else {
                if ([self.source.entity.name isEqualToString:@"BatchSource"]) {
                    
                    self.assets = [NSOrderedSet orderedSetWithOrderedSet:self.source.batchAssets];
                    [self.assetsTableView setSortDescriptors:nil];

                }
                else {
                    NSString *entityName = self.source.fetchEntity;
                    if (!entityName.length) entityName = @"Asset";
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
                    NSError *error;
                    [request setPredicate:self.source.fetchPredicate];
                    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
                    self.assets = [NSOrderedSet orderedSetWithArray:matchingItems];
                }
                [self.assetArrayController setContent:[self.assets array]];
                
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
            
           
            
        }
        if (([keyPath isEqualToString:@"self.source.template"]) || ([keyPath isEqualToString:@"self.source.template.formatText"])) {
            [self updateFormattedCode:self];
            
        }
    }
    
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
        [self updatePaneSizes:@""];
        [self.assetsTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"PraxItemsDropType", nil]];

        
    }
}

- (IBAction)selectAssetListPane:(id)sender {
    [self.document.sourceController selectAssetListPane:self];
    
}

- (void)filterPane {
    [self.searchField selectText:self];
    
    
    
}

- (IBAction)updateFilter:sender {
    NSString *searchString = [self.searchField stringValue];
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", searchString];
        [self.assetArrayController setFilterPredicate:predicate];
    }
    else [self.assetArrayController setFilterPredicate:nil];
}

- (void)updatePaneSizes:(NSString *)keyPath {

    CGFloat minPosition0 = 28;
    CGFloat maxPosition0 = [self.splitView maxPossiblePositionOfDividerAtIndex:0] - 20;
    CGFloat minPosition1 = [self.splitView minPossiblePositionOfDividerAtIndex:1];
    CGFloat maxPosition1 = ([self.splitView maxPossiblePositionOfDividerAtIndex:1] - 18);
    CGFloat maxPosition2 = ([self.splitView maxPossiblePositionOfDividerAtIndex:2] - 18);
    CGFloat position0 = [self.splitView positionOfDividerAtIndex:0];
    CGFloat position1 = [self.splitView positionOfDividerAtIndex:1];
    CGFloat position2 = [self.splitView positionOfDividerAtIndex:2];
    CGFloat newPosition0;
    CGFloat newPosition1;
    CGFloat newPosition2;
    
    if ([keyPath isEqualToString:@"self.showDetailView"]) {
        
        if (self.showDetailView) {
            newPosition0 = 200;
            if (newPosition0 > maxPosition0) {
                newPosition0 = maxPosition0;
            }
        }
        else {
            newPosition0 = minPosition0;
        }
        [[self.splitView animator] setPosition:newPosition0 ofDividerAtIndex:0];

        
    }
    else if ([keyPath isEqualToString:@"self.showCodeView"]) {
        if (self.showCodeView) {
            newPosition2 = (maxPosition2 - 100);
            if (!self.showWebView) {
                newPosition1 = (position1 - (position2 - newPosition2));
                [self.splitView setPosition:newPosition1 ofDividerAtIndex:1 animated:NO];
            }
            [self.splitView setPosition:newPosition2 ofDividerAtIndex:2 animated:NO];

        }
        else {
            newPosition2 = maxPosition2;
            [self.splitView setPosition:newPosition2 ofDividerAtIndex:2 animated:NO];
            if (!self.showWebView) {
                newPosition1 = (position1 + (newPosition2 - position2));
                [self.splitView setPosition:newPosition1 ofDividerAtIndex:1 animated:NO];
            }
        }
    }
    
    else if ([keyPath isEqualToString:@"self.showWebView"]) {
        if (self.showWebView) {
            
            newPosition1 = (maxPosition1 - ((position1 - position0) / 2));
            if (newPosition1 < minPosition1) {
                newPosition1 = minPosition1;
            }
        }
        else {
            newPosition1 = maxPosition1;
        }
        [self.splitView setPosition:newPosition1 ofDividerAtIndex:1 animated:NO];
    }
    else {
        newPosition2 = maxPosition2;
        newPosition1 = (newPosition2 - 21);
        [self.splitView setPosition:newPosition2 ofDividerAtIndex:2];
        [self.splitView setPosition:newPosition1 ofDividerAtIndex:1];
        [self.splitView setPosition:minPosition0 ofDividerAtIndex:0];
    }
    
    
}

- (void)updateFormattedCode:sender {
    
    NSString *newFormattedCode = @"";
    if (((self.showCodeView)||(self.showWebView)) || (self.showSafariView)) {
        
        if ((self.source) && ([self.assetArrayController.selectedObjects count] > 0)) {
            newFormattedCode = [TemplateController codeForTemplate:self.source.template.formatText withAssets:self.assetArrayController.selectedObjects];
        }
    }
    if (![newFormattedCode isEqualToString:self.formattedCode]) {
        self.formattedCode = newFormattedCode;
    }
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
            [self writeFormattedCode:sender];
            }

    }];
}

- (void)initAppleScript {
    self.appleScriptSource = [NSString stringWithFormat:@"tell application \"Safari\"\rset theURL to \"file://%@\"\rset foundTab to false\rset windowCount to number of window\rrepeat with theWindow from 1 to windowCount\rtry\rset tabCount to number of tabs in window theWindow\rif (tabCount > 0) then\rrepeat with theTab from 1 to tabCount\rset tabName to name of tab theTab of window theWindow\rif (exists URL of tab theTab of window theWindow) then\rset tabURL to URL of tab theTab of window theWindow\rif (tabURL = theURL) then\rset foundTab to true\rend if\rend if\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rend if\rend try\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rif (foundTab = true) then\rset URL of tab theTab of window theWindow to theURL\relse\ropen location theURL\rend if\rend tell", self.source.exportURL.path];
    self.appleScript = nil;
    self.appleScript = [[NSAppleScript alloc] initWithSource:self.appleScriptSource];
}

- (IBAction)writeFormattedCode:(id)sender {
    NSError *error;
    BOOL ok = [self.formattedCode writeToFile:self.source.exportURL.path atomically:YES
                                            encoding:NSUnicodeStringEncoding error:&error];
    if (!ok) {
        // an error occurred
        NSLog(@"Error writing file at %@\n%@", self.source.exportURL.path, [error localizedFailureReason]);
        self.showSafariView = NO;
        [[NSSound soundNamed:@"Error"] play];
        [self exportFormattedCode:self];

    }
    else {
        if ((self.showSafariView) && (![self.formattedCode isEqualToString:@""])) {
            if (!self.appleScript) [self initAppleScript];
            NSDictionary *errorInfo;
            [self.appleScript executeAndReturnError:&errorInfo];
        }
    }
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
    [self.document.templatesPanel makeKeyAndOrderFront:self];
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
    else {
        effectiveRect.origin.y -= 5.0;
        effectiveRect.size.height += 10.0;
    }
    
    
    
    return effectiveRect;
}



- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    return [(Tag *)representedObject name];
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    return [(Tag *)representedObject name];
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    NSError *error;
    Tag *tag;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", editingString]];
    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
    if ([matchingItems count] < 1) {
        tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
        tag.name = editingString;
    }
    else tag = matchingItems[0];
    return tag;
    
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
        if (([self.source.entity.name isEqualToString:@"BatchSource"]) || (self.isPlaylist)) {
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
        else if ([self.source.entity.name isEqualToString:@"BatchSource"]) {
            self.source.batchAssets = arrangedAssets;
        }
        [self.assetArrayController setContent:[arrangedAssets array]];
        return YES;
    }
    else return NO;
}

@end
