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
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification object:self.requiredTagsTokenField queue:nil usingBlock:^(NSNotification *aNotification){
            
        }];
        
        
        [self.assetsTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"org.ElmerCat.PraxPress.Asset", nil]];
        self.showDetailView = NO;
        self.showCodeView = NO;
        self.showFilterTags = NO;
      //  self.filterKeyIndex = 101;
      //  self.filterKeyOption = 201;
        [self initializeFilterMenu];
        
        NSMutableArray *rowTemplates = [@[[[PraxPredicateEditorRowTemplate alloc] initWithCompoundTypes:@[@2, @1, @0]]] mutableCopy];
        
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"accountType"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"type"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithStringAttributeType] forAttributeType:NSStringAttributeType]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"sharing"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"track_type"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithDateAttributeType] forAttributeType:NSDateAttributeType]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithNumberAttributeType] forAttributeType:NSInteger64AttributeType]];
        
        self.predicateEditor.rowTemplates = rowTemplates;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSRuleEditorRowsDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                          NSLog(@"AssetListViewController NSRuleEditorRowsDidChangeNotification");
                                                          
                                                          [self resizePredicateBox];
                                                          
                                                      }];

        
        [self.requiredTagsTokenField setDelegate:self.document.tagController];
        [self.excludedTagsTokenField setDelegate:self.document.tagController];
        
//        CGFloat newPosition = [self.splitView maxPossiblePositionOfDividerAtIndex:0];
 //       [self.splitView setPosition:newPosition ofDividerAtIndex:0 animated:NO];
    }
}


#pragma mark ------

-(CGFloat)closedSourceBoxHeight {return 22;}

-(void)prepareViewForSource {
    self.renameSource = NO;
    if ([@"SearchSource" isEqualToString:self.source.type]) {
        self.editSearch = NO;
    }
    else {
        [self.predicateBoxHeight setConstant:0];
    }
    if ([@"BatchSource" isEqualToString:self.source.type]) {
        self.batchSubtract = NO;
        [self.batchBoxHeight setConstant:self.closedSourceBoxHeight];
    }
    else {
        [self.batchBoxHeight setConstant:0];
    }
    if ([@"AssetSource" isEqualToString:self.source.type]) {
        [self.accountBoxHeight setConstant:self.closedSourceBoxHeight];
    }
    else {
        [self.accountBoxHeight setConstant:0];
    }
    
    
    
}

-(void)resizePredicateBox {
    if (![@"SearchSource" isEqualToString:self.source.type]) [self.predicateBoxHeight setConstant:0];
    else if (self.editSearch) {
        NSInteger rowCount = self.predicateEditor.numberOfRows;
        if (rowCount < 2) rowCount = 2;
        CGFloat constant = (rowCount * self.predicateEditor.rowHeight);
        constant += 24;
        [self.predicateBoxHeight setConstant:constant];
    }
    else  [self.predicateBoxHeight setConstant:self.closedSourceBoxHeight];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayString {return [NSSet setWithArray:@[@"self.source.requiredTags", @"self.source.excludedTags"]]; }

- (void)filterAssets {
    
    if ((!self.source.filterString) || (!self.source.filterString.length)) {
        [self.assetArrayController setFilterPredicate:nil];
        [[self.searchField cell] setPlaceholderString:self.filterPlaceholderString];
    }
    else {
        NSString *string = [NSString stringWithFormat:@"%@ %@%@ \"%@\"", self.filterKey, self.filterOption, self.caseOption, self.source.filterString];
        if (self.source.filterNegate) string = [NSString stringWithFormat:@"NOT (%@)", string];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:string];
        [self.assetArrayController setFilterPredicate:predicate];
    }
}

- (void)tagFilterAssets {
    self.anySourceTags = ((self.source.excludedTags.count > 0) || (self.source.requiredTags.count > 0)) ? YES : NO;
    self.showFilterTags = self.anySourceTags;
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
    
    if (!self.isSelectedPane) {
        [self.document.sourceController toggleSourceList:self];
        self.isSelectedPane = YES;
    }
    else {
        for (NSInteger index = 1; (index < self.document.sourceController.sourceSplitView.subviews.count); index++) {
            AssetListView *view = self.document.sourceController.sourceSplitView.subviews[index];
            if ((self != view.controller) && (view.controller.isSelectedPane)) view.controller.isSelectedPane = NO;
        }
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.document.sourceController.sourceTreeController setSelectionIndexPath:[self.document.sourceController.sourceTreeController indexPathOfObject:self.source]];
        });

    }
}

- (IBAction)updateFilter:sender {
    NSString *searchString = [self.searchField stringValue];
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", searchString];
        [self.assetArrayController setFilterPredicate:predicate];
    }
    else [self.assetArrayController setFilterPredicate:nil];
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

- (IBAction)clearFilterTags:(id)sender {
    self.source.requiredTags = [NSSet setWithArray:@[]];
    self.source.excludedTags = [NSSet setWithArray:@[]];
    self.source.requireAllTags = 0;
}

- (IBAction)showTags:(id)sender {
    if (self.document.tagController.tagsPanel.isVisible) [self.document.tagController.tagsPanel orderOut:sender];
    else {
        [self.document.tagController.tagsPanel makeKeyAndOrderFront:sender];
        if (!self.showFilterTags) self.showFilterTags = YES;
    }
}

- (IBAction)newSearchRule:(id)sender {
    
    if (self.predicateEditor.numberOfRows < 1) [self newCompoundRule:sender];
    else {
        [self.predicateEditor insertRowAtIndex:self.predicateEditor.numberOfRows withType:NSRuleEditorRowTypeSimple asSubrowOfRow:[self.predicateEditor parentRowForRow:(self.predicateEditor.numberOfRows - 1)] animate:YES];
    }
}

- (IBAction)newCompoundRule:(id)sender {
    [self.predicateEditor insertRowAtIndex:self.predicateEditor.numberOfRows withType:NSRuleEditorRowTypeCompound asSubrowOfRow:-1 animate:YES];
    [self.predicateEditor insertRowAtIndex:self.predicateEditor.numberOfRows withType:NSRuleEditorRowTypeSimple asSubrowOfRow:(self.predicateEditor.numberOfRows - 1) animate:YES];
}


#pragma mark - KeyValueObservation

- (NSArray *)keyPathsToObserve {return @[@"self.source",
                                         @"self.source.itemCount",
                                         @"self.source.batchAssets",
                                         @"self.source.fetchPredicate",
                                         @"self.source.filterString",
                                         @"self.source.filterKeyIndex",
                                         @"self.source.filterOptionIndex",
                                         @"self.source.filterCaseSensitive",
                                         @"self.source.filterNegate",
                                         
                                         @"self.document.interface.selectedSource",
                                       //  @"self.isSelectedPane",
                                         @"self.associatedController.source",
                                         
                                         @"self.changedAssetArrayController.arrangedObjects",
                                         @"self.assetArrayController.sortDescriptors",
                                         @"self.assetArrayController.selectionIndexes",
                                         @"self.associatedController.assetArrayController.selectionIndexes",
                                         @"self.source.requiredTags",
                                         @"self.source.requireAllTags",
                                         @"self.source.excludedTags",
                                         @"self.editSearch",
                                         @"self.showFilterTags",
                                         @"self.showDetailView",
                                         @"self.showCodeView",
                                         @"self.showSafariView",
                                         @"self.exportCode",
                                         @"self.formattedCode"];}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    
    if ([@[@"self.source", @"self.source.itemCount", @"self.source.batchAssets", @"self.source.fetchPredicate"] containsObject:keyPath]) {
        
        if (!self.isAssociatedPane) {
            [self reloadAssets];
            if ([@"self.source" isEqualToString:keyPath]) {
                
                [self prepareViewForSource];
                if (self.associatedController) self.associatedController.source = self.source;
                
                if (self.source == self.document.interface.selectedSource) self.isSelectedPane = YES;
                else self.isSelectedPane = NO;
                
                
            }
        }
    }

    else if ([@"self.document.interface.selectedSource" isEqualToString:keyPath]) {
        if (self.isSelectedPane) {
            for (NSInteger index = 1; (index < self.document.sourceController.sourceSplitView.subviews.count); index++) {
                AssetListView *view = self.document.sourceController.sourceSplitView.subviews[index];
                if ((self != view.controller) && (view.controller.source == self.document.interface.selectedSource)) {
                    self.isSelectedPane = NO;
                    return;
                }
            }
            self.source = self.document.interface.selectedSource;
        }
        else if (self.source == self.document.interface.selectedSource) self.isSelectedPane = YES;
        else self.isSelectedPane = NO;
    }
    
    
//    else if ([@"self.isSelectedPane" isEqualToString:keyPath]) {
        //        CGFloat selectedPaneAlpha = 0;
        //        CGFloat notSelectedPaneAlpha = 1;
 //       if (self.isSelectedPane) {
            //            selectedPaneAlpha = 1;
            //            notSelectedPaneAlpha = 0;
  //      }
   // }
    
    
    else if ([keyPath isEqualToString:@"self.changedAssetArrayController.arrangedObjects"]) {
        if ([(NSArray *)self.changedAssetArrayController.arrangedObjects count]) {
            [self.changedBoxHeight.animator setConstant:50];
        }
        else {
            [self.changedBoxHeight.animator setConstant:21];
        }
        
    }
    
    else if ([@[@"self.source.filterString", @"self.source.filterNegate", @"self.source.filterCaseSensitive", @"self.source.filterOptionIndex", @"self.source.filterKeyIndex"] containsObject:keyPath]) {
        
        [self filterAssets];
        
    }
    else if ([keyPath isEqualToString:@"self.showFilterTags"]) {
        if (self.showFilterTags) {
            [self.tagsBoxHeight.animator setConstant:22];
        }
        else {
            [self.tagsBoxHeight.animator setConstant:0];
        }
    }
    
    else if ([keyPath isEqualToString:@"self.showCodeView"]) {
        if (self.showCodeView) {
            [self.splitView.animator setPosition:([self.splitView minPossiblePositionOfDividerAtIndex:0] + 130) ofDividerAtIndex:0];
        }
        else {
            [self.splitView.animator setPosition:[self.splitView minPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
        }
    }
    
    
    else if ([keyPath isEqualToString:@"self.editSearch"]) {
        [self resizePredicateBox];
    }
    
    else if ([keyPath isEqualToString:@"self.showDetailView"]) {
        CGFloat newPosition = [self.splitView maxPossiblePositionOfDividerAtIndex:1];
        if (self.showDetailView) newPosition -= 200;
        [self.splitView.animator setPosition:newPosition ofDividerAtIndex:1];
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
        
        self.codeController.needsUpdate = YES;
        
    }
    else if ([@[@"self.source.excludedTags", @"self.source.requiredTags", @"self.source.requireAllTags"] containsObject:keyPath]) {
        [self tagFilterAssets];
    }
}

- (void) reloadAssets {
    if (!self.source) return;
    
    
    @synchronized(self) {
        if (self.reloadingAssets) return;
        else self.reloadingAssets = YES;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
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
            [self filterAssets];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                self.codeController.needsUpdate = YES;
            });
        }
        
        self.reloadingAssets = NO;
    });
    
}


#pragma mark - Filter Menu

- (NSArray *)filterKeys {
    return @[@{@"key": @"title", @"title" : @"Title", @"tag" : @101},
             @{@"key": @"genre", @"title" : @"Genre", @"tag" : @102},
             @{@"key": @"permalink", @"title" : @"Permalink", @"tag" : @103},
             @{@"key": @"contents", @"title" : @"Contents / Description", @"tag" : @104},
             @{@"key": @"permalink_title", @"title" : @"Link Title", @"tag" : @105},
             @{@"key": @"permalink_url", @"title" : @"Link URL", @"tag" : @106},
             @{@"key": @"prax", @"title" : @"Prax 107", @"tag" : @107},
             @{@"key": @"prax", @"title" : @"Prax 108", @"tag" : @108} ];
}

- (NSArray *)filterOptions {
    return @[@{@"key": @"BEGINSWITH", @"title" : @" Begins with", @"negativeTitle" : @" does NOT Begin with", @"tag" : @201},
             @{@"key": @"CONTAINS", @"title" : @" Contains", @"negativeTitle" : @" does NOT Contain", @"tag" : @202},
             @{@"key": @"ENDSWITH", @"title" : @" Ends with", @"negativeTitle" : @" does NOT End with", @"tag" : @203},
             @{@"key": @"MATCHES", @"title" : @" Matches", @"negativeTitle" : @" does NOT Match", @"tag" : @204} ];
}

-(NSString *)filterKey {
    NSInteger index = self.source.filterKeyIndex.integerValue;
    if ((index < 0) || (index >= self.filterKeys.count)) index = 0;
    return self.filterKeys[index][@"key"];
}

-(NSString *)filterKeyTitle {
    NSInteger index = self.source.filterKeyIndex.integerValue;
    if ((index < 0) || (index >= self.filterKeys.count)) index = 0;
    return self.filterKeys[index][@"title"];
}

-(NSString *)filterOption {
    NSInteger index = self.source.filterOptionIndex.integerValue;
    if ((index < 0) || (index >= self.filterOptions.count)) index = 0;
    return self.filterOptions[index][@"key"];
}

-(NSString *)filterPlaceholderString {
    NSInteger index = self.source.filterOptionIndex.integerValue;
    if ((index < 0) || (index >= self.filterOptions.count)) index = 0;
    NSString *string = [NSString stringWithFormat:@"%@", self.filterKeyTitle];
    if (self.source.filterNegate.boolValue) string = [string stringByAppendingString:self.filterOptions[index][@"negativeTitle"]];
    else string = [string stringByAppendingString:self.filterOptions[index][@"title"]];
    if (self.source.filterCaseSensitive.boolValue) string = [string stringByAppendingString:@"   . . .    (case sensitive)"];
    else string = [string stringByAppendingString:@"   . . .    (ignore case)"];
    return string;
}

-(NSString *)caseOption {
    if (self.source.filterCaseSensitive.boolValue) return @"";
    else return @"[cd]";
}

- (void)initializeFilterMenu {
    NSMenuItem *menuItem;
    for (NSDictionary *item in self.filterKeys) {
        menuItem = [[NSMenuItem alloc] initWithTitle:item[@"title"] action:@selector(menuSelector:) keyEquivalent:@""];
        [menuItem setTag:[item[@"tag"] integerValue]];
        [menuItem setTarget:self];
        [self.filterByKeyMenu addItem:menuItem];
    }
    for (NSDictionary *item in self.filterOptions) {
        menuItem = [[NSMenuItem alloc] initWithTitle:item[@"title"] action:@selector(menuSelector:) keyEquivalent:@""];
        [menuItem setTag:[item[@"tag"] integerValue]];
        [menuItem setTarget:self];
        [self.filterOptionMenu addItem:menuItem];
    }
    
}

- (IBAction)menuSelector:(id)sender {
    NSInteger tag = [sender tag];
    if ((101 <= tag) && (tag <= 199)) { // Filter key choices
        if ((self.source.filterKeyIndex.integerValue + 101) != tag) self.source.filterKeyIndex = [NSNumber numberWithInteger:(tag - 101)];
    }
    else if ((201 <= tag) && (tag <= 204)) { // Filter key options
        if ((self.source.filterOptionIndex.integerValue + 201) != tag) self.source.filterOptionIndex = [NSNumber numberWithInteger:(tag - 201)];
    }
    else if ((222 == tag) || (223 == tag)) self.source.filterCaseSensitive = [NSNumber numberWithBool:(!self.source.filterCaseSensitive.boolValue)];
    else if (224 == tag) self.source.filterNegate = [NSNumber numberWithBool:(!self.source.filterNegate.boolValue)];
    
    else if (300 == tag) self.showFilterTags = YES;
    else if (304 == tag) self.showFilterTags = NO;
}


- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger tag = [item tag];
    
    if (100 == tag) { // Filter by key submenu
        [item setTitle:[NSString stringWithFormat:@"%@", self.filterKeys[self.source.filterKeyIndex.integerValue][@"title"]]]; }
    
    else if ((101 <= tag) && (tag <= 199)) { // Filter key choices
        [item setState:(((tag - 101) == self.source.filterKeyIndex.integerValue) ? NSOnState : NSOffState)];
        if (tag > 106) return NO; }
    
    else if (200 == tag) { // Filter options submenu
        [item setTitle:[NSString stringWithFormat:@"%@", self.filterOptions[self.source.filterOptionIndex.integerValue][@"title"]]]; }
    
    else if ((201 <= tag) && (tag <= 204)) { // Filter key options
        [item setState:(((tag - 201) == self.source.filterOptionIndex.integerValue) ? NSOnState : NSOffState)]; }
    
    else if (222 == tag) [item setState:((self.source.filterCaseSensitive.boolValue) ? NSOnState : NSOffState)];
    else if (223 == tag) [item setState:((!self.source.filterCaseSensitive.boolValue) ? NSOnState : NSOffState)];
    else if (224 == tag) [item setState:((self.source.filterNegate.boolValue) ? NSOnState : NSOffState)];
    
    else if (300 == tag) return ((!self.source.requiredTags.count) && (!self.source.excludedTags.count));
    else if ((301 <= tag) && (tag <= 304)) {
        if ((!self.source.requiredTags.count) && (!self.source.excludedTags.count)) [item setHidden:YES];
        else {
            [item setHidden:NO];
            if (301 == tag) [item setState:((!self.source.requireAllTags.boolValue) ? NSOnState : NSOffState)];
            else if (302 == tag) [item setState:((self.source.requireAllTags.boolValue) ? NSOnState : NSOffState)];
            else if (303 == tag) [item setState:((self.source.excludedTags.count) ? NSOnState : NSOffState)];
        }
    }
    
    else if (99 != tag ) return NO;
        
    return YES;
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

/*- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    
    if (dividerIndex == 0) {
        CGFloat divider0Position = [splitView positionOfDividerAtIndex:0];
        CGFloat divider1Position = [splitView positionOfDividerAtIndex:1];
        CGFloat divider2Position = [splitView positionOfDividerAtIndex:2];
        
        CGFloat shortage = (self.controlPaneMinHeight - (divider1Position - divider0Position));
        
        NSLog(@"constrainSplitPosition\n dividerIndex=%ld pos0=%f pos1=%f, pos2=%f shortage=%f", (long)dividerIndex, divider0Position, divider1Position, divider2Position, shortage);
        
        
        if (shortage > 0) {
            shortage += divider1Position;
            [splitView setPosition:(divider1Position + shortage) ofDividerAtIndex:1];
            [splitView adjustSubviews];
        }
        
        
        
    }
    
    
    return proposedPosition;
    
}*/

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

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    if (self.assetListPane == subview) return YES;
    else return NO;
}


/*- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    
    CGFloat divider0Position = [splitView positionOfDividerAtIndex:0];
    CGFloat divider1Position = [splitView positionOfDividerAtIndex:1];
    CGFloat divider2Position = [splitView positionOfDividerAtIndex:2];
    
    CGFloat shortage = (self.controlPaneMinHeight - (divider1Position - divider0Position));
    
    NSLog(@"resizeSubviewsWithOldSize pos0=%f pos1=%f, pos2=%f shortage=%f", divider0Position, divider1Position, divider2Position, shortage);
    
    
    if (shortage > 0) {
        shortage += 20;
 //           [splitView setPosition:(divider1Position + shortage) ofDividerAtIndex:1];
    }
    

    
    [splitView adjustSubviews];
}*/

/*- (void)splitViewWillResizeSubviews:(NSNotification *)aNotification {
    NSDictionary *userInfo  = aNotification.userInfo;
    NSNumber *dividerIndex = userInfo[@"NSSplitViewDividerIndex"];
    NSLog(@"splitViewWillResizeSubviews NSSplitViewDividerIndex %@", dividerIndex);
    
}*/

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
    
//    NSDictionary *userInfo  = aNotification.userInfo;
 //   NSNumber *dividerIndex = userInfo[@"NSSplitViewDividerIndex"];
  //  NSLog(@"splitViewDidResizeSubviews NSSplitViewDividerIndex %@", dividerIndex);
    
    if ([self.splitView isSubviewCollapsed:self.detailViewPane]) {
        if (self.showDetailView) self.showDetailView = NO;
    }
    else if (self.detailViewPane.frame.size.height < 10) {
        if (self.showDetailView) self.showDetailView = NO;
    }
    else {
        if (!self.showDetailView) self.showDetailView = YES;
    }
    
    if ([self.splitView isSubviewCollapsed:self.codeViewPane]) {
        if (self.showCodeView) self.showCodeView = NO;
    }
    else if (self.codeViewPane.frame.size.height < 10) {
        if (self.showCodeView) self.showCodeView = NO;
    }
    else {
        if (!self.showCodeView) self.showCodeView = YES;
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
