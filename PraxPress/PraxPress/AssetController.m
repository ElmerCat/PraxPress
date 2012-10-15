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
//        NSLog(@"AssetController init");
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.assetTableView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.selectedRowIndexes isEqualToIndexSet:[self.assetTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet: self.selectedRowIndexes];
                self.selectedRowIndexes = [self.assetTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.selectedRowIndexes];
                
                if ([[self.assetsController selectedObjects] count] > 0) {
                    Asset *asset = [self.assetsController selectedObjects][0];
                    [self.associatedItemsController setContent:asset.associatedItems];
                }

                [self.assetTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
            }
        }];
        
        
    }
    return self;
}

/*- (void)awakeFromNib {
    NSLog(@"AssetController awakeFromNib");
    
}*/

- (IBAction)sortAssets:(id)sender {
    
    NSMenuItem *item = [(NSPopUpButton *)sender selectedItem];
    NSString *descriptor = item.title;
    if ([descriptor isEqualToString:@"Genre"]) descriptor = @"genre";
    else if ([descriptor isEqualToString:@"Date"]) descriptor = @"date";
    else descriptor = @"title";
    
    [self.assetTableView setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:descriptor ascending:YES]]];
    
    
}

- (void)windowWillClose:(NSNotification *)notification {
    [[self.assetDetailWebView mainFrame] loadHTMLString:@"Prax" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
    
    if (([self.praxController.selectedAsset.type isEqualToString:@"post"])||([self.praxController.selectedAsset.type isEqualToString:@"page"])) {
        [self.assetDetailWebView setMainFrameURL:self.praxController.selectedAsset.purchase_url];
    }
    else {
        NSString *html = [Asset htmlStringForAsset:self.praxController.selectedAsset];
        [[self.assetDetailWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
}

 


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    if ([[tableView selectedRowIndexes] containsIndex:row]) return 120;
    else return 20;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    
    Asset *asset = [self.assetsController arrangedObjects][row];
    NSString *identifier = [NSString stringWithFormat:@"%@AssetView", asset.type];
    NSView *view = [tableView makeViewWithIdentifier:identifier owner:self];

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




- (IBAction)playlistButtonPressed:(id)sender {
    Asset *asset = [self.assetsController selectedObjects][0];
    [self.associatedItemsController setContent:asset.associatedItems];

    [self.playlistViewPopover showRelativeToRect:[(NSButton *)sender bounds] ofView:sender preferredEdge:NSMinYEdge];

}
@end
