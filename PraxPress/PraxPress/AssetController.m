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
        
        
        self.assetDetailControllers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"AssetDetailClosedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *asset = (Asset *)[aNotification object];
            [self.assetDetailControllers removeObjectForKey:asset];
            NSLog(@"BatchController AssetDetailClosedNotification: %@", asset.title);
            
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"AssetChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            Asset *asset = (Asset *)[aNotification object];
            
            if (!asset.sync_mode.boolValue) asset.sync_mode = [NSNumber numberWithBool:YES];
            [self.changedAssetsController rearrangeObjects];
            
    //        NSLog(@"AssetController AssetChangedNotification: %@", asset.sync_mode);
            
        }];
        
        
/*        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.assetTableView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.selectedRowIndexes isEqualToIndexSet:[self.assetTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet: self.selectedRowIndexes];
                self.selectedRowIndexes = [self.assetTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.selectedRowIndexes];
                
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.5];
                
                [changedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
                    NSView *view = [self.assetTableView viewAtColumn:0 row:row makeIfNecessary:YES];
                    if (view && [view isKindOfClass:[AssetTableCellView class]]) {
                        [(AssetTableCellView *)view layoutViewsForTable:self.assetTableView viewMode:self.viewMode animated:YES];
                    }
                }];
                

                [self.assetTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [NSAnimationContext endGrouping];
                

            }
        }]; */
        
        
    }
    return self;
}

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = TRUE;
        NSLog(@"AssetController awakeFromNib");
        self.assetDetailControllers = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"AssetTableCellView" bundle:[NSBundle mainBundle]];
        for (NSTableView *tableView in @[self.assetsTableView, self.batchAssetsTableView, self.changedAssetsTableView, self.associatedAssetsTableView]) {
            for (NSString *identifier in @[@"trackTableCellView", @"playlistTableCellView", @"postTableCellView", @"pageTableCellView"]) {
                [tableView registerNib:nib forIdentifier:identifier];
            }
        }
    }
}

- (IBAction)sortAssets:(id)sender {
    
    NSMenuItem *item = [self.sortPopupButton selectedItem];
    NSString *descriptor = item.title;
    BOOL ascendState = [self.sortDirectionButton state];
   // if ([descriptor isEqualToString:@"Genre"]) descriptor = @"genre";
   // else if ([descriptor isEqualToString:@"Date"]) descriptor = @"date";
  //  else if ([descriptor isEqualToString:@"Title"]) descriptor = @"title";
    
    [self.assetsTableView setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:descriptor ascending:ascendState]]];
    [self.assetsTableView scrollRowToVisible:[self.assetsTableView selectedRow]];
    
//    [self viewModeSelectorClicked:NULL];
    
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
    [self selectTableView:self.assetsTableView mode:self.assetsViewMode];
}
- (IBAction)changedAssetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.changedAssetsTableView mode:self.changedAssetsViewMode];
}
- (IBAction)batchAssetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.batchAssetsTableView mode:self.batchAssetsViewMode];
}
- (IBAction)associatedAssetsTableViewModeSelectorClicked:(id)sender {
    [self selectTableView:self.associatedAssetsTableView mode:self.associatedAssetsViewMode];
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
                [(AssetTableCellView *)view layoutViewsForTable:tableView viewMode:viewMode animated:NO];
            }
        }
    }];
    
    [tableView noteHeightOfRowsWithIndexesChanged:indexesToNoteHeightChanges];
    [tableView scrollRowToVisible:[tableView selectedRow]];
    [NSAnimationContext endGrouping];
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    NSInteger viewMode;
    if (tableView == self.changedAssetsTableView) {
        viewMode = self.changedAssetsViewMode;
    }
    else if (tableView == self.batchAssetsTableView) {
        viewMode = self.batchAssetsViewMode;
    }
    else if (tableView == self.associatedAssetsTableView) {
        viewMode = self.associatedAssetsViewMode;
    }
    else {  // self.assetsTableView
        viewMode = self.assetsViewMode;
    }
    
    if (viewMode == 0) return 14;
    else if (viewMode == 1) return 50;
    else return 800;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    Asset *asset;
    NSInteger viewMode;
    if (tableView == self.changedAssetsTableView) {
        asset = [self.changedAssetsController arrangedObjects][row];
        viewMode = self.changedAssetsViewMode;
    }
    else if (tableView == self.batchAssetsTableView) {
        asset = [self.batchAssetsController arrangedObjects][row];
        viewMode = self.batchAssetsViewMode;
    }
    else if (tableView == self.associatedAssetsTableView) {
        asset = [self.associatedAssetsController arrangedObjects][row];
        viewMode = self.associatedAssetsViewMode;
    }
    else {  // self.assetsTableView
        asset = [self.assetsController arrangedObjects][row];
        viewMode = self.assetsViewMode;
    }
    
 //   NSLog (@"viewForTableColumn: row: %ld", row);
    NSString *identifier = [NSString stringWithFormat:@"%@TableCellView", asset.type];
//    NSView *view = [tableView makeViewWithIdentifier:@"praxView" owner:self];
    NSView *view = [tableView makeViewWithIdentifier:identifier owner:self];
    
    if (view && [view isKindOfClass:[AssetTableCellView class]]) {
 //       NSLog (@"[view isKindOfClass:[AssetTableCellView class]] row: %ld", row);
        
 //       [(AssetTableCellView *)view setAsset:asset];
        [(AssetTableCellView *)view setUpdateController:self.updateController];
        [(AssetTableCellView *)view layoutViewsForTable:tableView viewMode:viewMode animated:NO];
    }

    if (view) return view;
    
    else return [tableView makeViewWithIdentifier:@"praxView" owner:self];
        
//        NSManagedObject *source = [(NSTreeNode *)item representedObject];
//        if (![source valueForKey:@"parent"]) return [outlineView makeViewWithIdentifier:@"SourceView" owner:self];
//        else return [outlineView makeViewWithIdentifier:@"ServiceView" owner:self];
        
        
        //    if ([item isKindOfClass:[ATDesktopFolderEntity class]]) {
        // Everything is setup in bindings
        //       return [outlineView makeViewWithIdentifier:@"SourceView" owner:self];
        /*    } else {
         NSView *result = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
         if ([result isKindOfClass:[ATTableCellView class]]) {
         ATTableCellView *cellView = (ATTableCellView *)result;
         // setup the color; we can't do this in bindings
         cellView.colorView.drawBorder = YES;
         cellView.colorView.backgroundColor = [item fillColor];
         }
         // Use a shared date formatter on the DateCell for better performance. Otherwise, it is encoded in every NSTextField
         if ([[tableColumn identifier] isEqualToString:@"DateCell"]) {
         [(id)result setFormatter:_sharedDateFormatter];
         }
         return result;
         }
         return nil;
         }
    */
    
    
    
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
