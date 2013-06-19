//
//  AssetController.m
//  PraxPress
//
//  Created by John Canfield on 9/17/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AssetController.h"


@implementation AssetController


- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AssetController init");
        
        self.sortAscending = YES;
        self.sortKey = @"title";
        self.sortKeyTag = 1;
    
        
        self.assetDetailControllers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"AssetDetailClosedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *asset = (Asset *)[aNotification object];
            [self.assetDetailControllers removeObjectForKey:asset];
            NSLog(@"BatchController AssetDetailClosedNotification: %@", asset.title);
            
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"AssetChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *asset = (Asset *)[aNotification object];
            
            if (!asset.sync_mode.boolValue) asset.sync_mode = [NSNumber numberWithBool:YES];
            [self.document.changedAssetsController rearrangeObjects];
            
    //        NSLog(@"AssetController AssetChangedNotification: %@", asset.sync_mode);
            
        }];
    
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.document.assetsTableView queue:nil usingBlock:^(NSNotification *aNotification){
             
            if (![self.assetsSelectedRowIndexes isEqualToIndexSet:[self.document.assetsTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:self.assetsSelectedRowIndexes];
                self.assetsSelectedRowIndexes = [self.document.assetsTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.assetsSelectedRowIndexes];
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.5];
                [changedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
                    if (row < [self.document.assetsTableView numberOfRows]) {
                        NSView *view = [self.document.assetsTableView viewAtColumn:0 row:row makeIfNecessary:YES];
                        if (view && [view isKindOfClass:[AssetTableCellView class]]) {
                            BOOL selected = [self.document.assetsTableView isRowSelected:row];
                            [(AssetTableCellView *)view setSelected:selected];
                            [(AssetTableCellView *)view layoutViewsForTable:self.document.assetsTableView viewMode:self.assetsViewMode animated:YES];
                        }
                    }
                }];
                [self.document.assetsTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [NSAnimationContext endGrouping];
            }
            
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.document.batchAssetsTableView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.batchAssetsSelectedRowIndexes isEqualToIndexSet:[self.document.batchAssetsTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:self.batchAssetsSelectedRowIndexes];
                self.batchAssetsSelectedRowIndexes = [self.document.batchAssetsTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.batchAssetsSelectedRowIndexes];
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.5];
                [changedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
                    if (row < [self.document.batchAssetsTableView numberOfRows]) {
                        NSView *view = [self.document.batchAssetsTableView viewAtColumn:0 row:row makeIfNecessary:YES];
                        if (view && [view isKindOfClass:[AssetTableCellView class]]) {
                            BOOL selected = [self.document.batchAssetsTableView isRowSelected:row];
                            [(AssetTableCellView *)view setSelected:selected];
                            [(AssetTableCellView *)view layoutViewsForTable:self.document.batchAssetsTableView viewMode:self.batchAssetsViewMode animated:YES];
                        }
                    }
                }];
                [self.document.batchAssetsTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [NSAnimationContext endGrouping];
            }

        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.document.associatedAssetsTableView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.associatedAssetsSelectedRowIndexes isEqualToIndexSet:[self.document.associatedAssetsTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:self.associatedAssetsSelectedRowIndexes];
                self.associatedAssetsSelectedRowIndexes = [self.document.associatedAssetsTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.associatedAssetsSelectedRowIndexes];
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.5];
                [changedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
                    if (row < [self.document.associatedAssetsTableView numberOfRows]) {
                        NSView *view = [self.document.associatedAssetsTableView viewAtColumn:0 row:row makeIfNecessary:YES];
                        if (view && [view isKindOfClass:[AssetTableCellView class]]) {
                            BOOL selected = [self.document.associatedAssetsTableView isRowSelected:row];
                            [(AssetTableCellView *)view setSelected:selected];
                            [(AssetTableCellView *)view layoutViewsForTable:self.document.associatedAssetsTableView viewMode:self.associatedAssetsViewMode animated:YES];
                        }
                    }
                }];
                [self.document.associatedAssetsTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [NSAnimationContext endGrouping];
            }
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.document.changedAssetsTableView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.changedAssetsSelectedRowIndexes isEqualToIndexSet:[self.document.changedAssetsTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet:self.changedAssetsSelectedRowIndexes];
                self.changedAssetsSelectedRowIndexes = [self.document.changedAssetsTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.changedAssetsSelectedRowIndexes];
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.5];
                [changedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
                    if (row < [self.document.changedAssetsTableView numberOfRows]) {
                        NSView *view = [self.document.changedAssetsTableView viewAtColumn:0 row:row makeIfNecessary:YES];
                        if (view && [view isKindOfClass:[AssetTableCellView class]]) {
                            BOOL selected = [self.document.changedAssetsTableView isRowSelected:row];
                            [(AssetTableCellView *)view setSelected:selected];
                            [(AssetTableCellView *)view layoutViewsForTable:self.document.changedAssetsTableView viewMode:self.changedAssetsViewMode animated:YES];
                        }
                    }
                }];
                [self.document.changedAssetsTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [NSAnimationContext endGrouping];
            }
        }];
        
    }
    return self;
}

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = TRUE;
        NSLog(@"AssetController awakeFromNib");
        self.assetDetailControllers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"AssetTableCellView" bundle:[NSBundle mainBundle]];
        for (NSTableView *tableView in @[self.document.assetsTableView, self.document.batchAssetsTableView, self.document.changedAssetsTableView, self.document.associatedAssetsTableView]) {
            for (NSString *identifier in @[@"trackTableCellView", @"playlistTableCellView", @"postTableCellView", @"pageTableCellView"]) {
                [tableView registerNib:nib forIdentifier:identifier];
            }
        }
    }
}
- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger tag = [item tag];
    if (tag < 100) {
        [item setState:((tag == self.sortKeyTag) ? NSOnState : NSOffState)];
    } else if (tag == 101) {
        [item setState:(self.sortAscending ? NSOnState : NSOffState)];
    } else if (tag == 102) {
        [item setState:(self.sortAscending ? NSOffState : NSOnState)];
    }
    return YES;
}

- (IBAction)sortAssetsDirection:(id)sender {
    [sender setState:NSOnState];
    NSString *selectionTitle = [[self.sortPopupButton selectedItem] title];
    if ([selectionTitle isEqualToString:@"Ascending"]) self.sortAscending = YES;
    else if ([selectionTitle isEqualToString:@"Descending"]) self.sortAscending = NO;
    [self sortAssetsTable];
}

- (IBAction)sortAssetsKey:(id)sender {
    self.sortKeyTag = [sender tag];
    NSString *selectionTitle = [[self.sortPopupButton selectedItem] title];
    self.sortKey = selectionTitle;
    [self sortAssetsTable];
}

- (void)sortAssetsTable {
    [self.document.assetsTableView setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:self.sortKey ascending:self.sortAscending]]];
    [self.document.assetsTableView scrollRowToVisible:[self.document.assetsTableView selectedRow]];
}

/*- (void)windowWillClose:(NSNotification *)notification {
    [[self.assetDetailWebView mainFrame] loadHTMLString:@"Prax" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
    
    if (([self.batchController.selectedAsset.type isEqualToString:@"post"])||([self.batchController.selectedAsset.type isEqualToString:@"page"])) {
        [self.assetDetailWebView setMainFrameURL:self.batchController.selectedAsset.purchase_url];
    }
    else {
        NSString *html = [Asset htmlStringForAsset:self.batchController.selectedAsset];
        [[self.assetDetailWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
}
*/

- (IBAction)assetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.document.assetsTableView mode:self.assetsViewMode];
}
- (IBAction)changedAssetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.document.changedAssetsTableView mode:self.changedAssetsViewMode];
}
- (IBAction)batchAssetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.document.batchAssetsTableView mode:self.batchAssetsViewMode];
}
- (IBAction)associatedAssetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.document.associatedAssetsTableView mode:self.associatedAssetsViewMode];
}

- (void)selectTableView:(NSTableView *)tableView mode:(NSInteger)viewMode {
    // Reload the height for all non group rows
    NSMutableIndexSet *indexesToNoteHeightChanges = [NSMutableIndexSet indexSet];
    
    for (NSInteger row = 0; row < tableView.numberOfRows; row++) [indexesToNoteHeightChanges addIndex:row];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    
    [tableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        for (NSInteger i = 0; i < [tableView tableColumns].count; i++) {
            NSView *view = [tableView viewAtColumn:i row:row makeIfNecessary:NO];
            if (view && [view isKindOfClass:[AssetTableCellView class]]) {
                [(AssetTableCellView *)view layoutViewsForTable:tableView viewMode:viewMode animated:YES];
            }
        }
    }];
    
    [tableView noteHeightOfRowsWithIndexesChanged:indexesToNoteHeightChanges];
    [tableView scrollRowToVisible:[tableView selectedRow]];
    [NSAnimationContext endGrouping];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSLog(@"AssetController tableView:willDisplayCell:forTableColumn:row");
    
    
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    NSInteger viewMode;
    if (tableView == self.document.changedAssetsTableView) {
        viewMode = self.changedAssetsViewMode;
    }
    else if (tableView == self.document.batchAssetsTableView) {
        viewMode = self.batchAssetsViewMode;
    }
    else if (tableView == self.document.associatedAssetsTableView) {
        viewMode = self.associatedAssetsViewMode;
    }
    else {  // self.document.assetsTableView
        viewMode = self.assetsViewMode;
    }
    
    if (viewMode == 0) {
        if ([tableView isRowSelected:row]) {
            return [AssetTableCellView viewModeZeroSelectedRowHeight];
        }
        else return [AssetTableCellView viewModeZeroRowHeight];

    }
    
    else if (viewMode == 1) {
        if ([tableView isRowSelected:row]) {
            return [AssetTableCellView viewModeOneSelectedRowHeight];
        }
        else return [AssetTableCellView viewModeOneRowHeight];
    }
    else {
        if ([tableView isRowSelected:row]) {
            return [AssetTableCellView viewModeTwoSelectedRowHeight];
        }
        else return [AssetTableCellView viewModeTwoRowHeight];

    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    Asset *asset;
    NSInteger viewMode;
    if (tableView == self.document.changedAssetsTableView) {
        asset = [self.document.changedAssetsController arrangedObjects][row];
        viewMode = self.changedAssetsViewMode;
    }
    else if (tableView == self.document.batchAssetsTableView) {
        asset = [self.document.batchAssetsController arrangedObjects][row];
        viewMode = self.batchAssetsViewMode;
    }
    else if (tableView == self.document.associatedAssetsTableView) {
        asset = [self.document.associatedAssetsController arrangedObjects][row];
        viewMode = self.associatedAssetsViewMode;
    }
    else {  // self.document.assetsTableView
        asset = [self.document.assetsController arrangedObjects][row];
        viewMode = self.assetsViewMode;
    }
    
    NSString *identifier = [NSString stringWithFormat:@"%@TableCellView", asset.type];
    NSView *view = [tableView makeViewWithIdentifier:identifier owner:self];
    
    if (!view) {
        NSLog (@"!view tableView makeViewWithIdentifier:identifier: %@", identifier);
    }
    
    if (view && [view isKindOfClass:[AssetTableCellView class]]) {
        [(AssetTableCellView *)view setDocument:self.document];
        [(AssetTableCellView *)view setSelected:[tableView isRowSelected:row]];
        [(AssetTableCellView *)view layoutViewsForTable:tableView viewMode:viewMode animated:NO];
    }

    return view;
}

- (void)assetTableDoubleClicked:(NSArray *)selectedObjects {
    if (selectedObjects.count > 0) {
        Asset *asset = selectedObjects[0];
        AssetDetailController *assetDetailController = [self.assetDetailControllers objectForKey:asset];
        if (!assetDetailController) {
            assetDetailController = [[AssetDetailController alloc] initWithWindowNibName:@"AssetDetailController"];
            [self.assetDetailControllers setObject:assetDetailController forKey:asset];
            assetDetailController.asset = asset;
            assetDetailController.filesOwner = self.document;
            [assetDetailController showWindow:self];
        }
        else {
            [[assetDetailController window] makeKeyAndOrderFront:self];
        }
    }

}

- (void)showMetadataPopoverForAsset:(Asset *)asset sender:(id)sender {
    
    [self.assetMetadataPopover showPopoverRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge withDictionary:asset.metadata];
    
}

@end
