//
//  PraxController.m
//  PraxPress
//
//  Created by John Canfield on 8/24/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "BatchController.h"

@implementation BatchController


+ (NSSet *)keyPathsForValuesAffectingBatchChangeCopyValue {
    return [NSSet setWithObjects:@"self.batchChangeKey", @"self.selectedAsset", nil];
}

- (id)init {
    self = [super init];
    if (self) {
            NSLog(@"BatchController init");
        self.templateName = [[NSUserDefaults standardUserDefaults] objectForKey:@"batchViewTemplate"];

        [self addObserver:self forKeyPath:@"self.templateName" options:NSKeyValueObservingOptionNew context:0];
        [self addObserver:self forKeyPath:@"self.batchAssetsController.arrangedObjects" options:NSKeyValueObservingOptionNew context:0];
        

        
/*        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *aNotification) {
                                                          
            NSTableView *table = [aNotification object];
            if ( (table == self.assetsTableView) || (table == self.batchAssetsTableView) ){
                
                if (table.selectedRow >= 0) {
                    Asset *newSelectedAsset;
                    if (table == self.assetsTableView) {
                        newSelectedAsset = self.assetsController.arrangedObjects[table.selectedRow];
                    }
                    else if (table == self.batchAssetsTableView) {
                        newSelectedAsset = self.batchAssetsController.arrangedObjects[table.selectedRow];
                    }
                    
                    if (self.selectedAsset != newSelectedAsset) {
                        self.selectedAsset = newSelectedAsset;
                        //      [[self.selectedAssetWebView mainFrame] loadHTMLString:[Asset htmlStringForAsset:self.selectedAsset] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
                        
                        [self.associatedAssetsController setContent:self.selectedAsset.associatedItems];
                        
                    }
                    for (NSTableView *tableView in @[self.assetsTableView, self.batchAssetsTableView]) {
                        if (table != tableView) {
                            [tableView deselectAll:self];
                        }
                    }
                    
                    
                }
            }
            //   else if (table == self.templateTableView) [self.templateController updateGeneratedCode];
            
            else {} //NSLog(@"PraxController NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
            
            
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTextDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSLog(@"PraxController NSTextDidChangeNotification aNotification: %@", aNotification);
 
                                                          NSView *aView = [[aNotification object] superview];
                                                          NSScrollView *aScrollView = [aView enclosingScrollView];
                                                          if (aScrollView == self.assetScrollView) {
                                                              self.selectedAsset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else {
                                                              NSLog(@"textDidChange something else");
                                                          }
 
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPopUpButtonWillPopUpNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSLog(@"PraxController NSPopUpButtonWillPopUpNotification aNotification: %@", aNotification);
                                                          
                                                          NSView *aView = [[aNotification object] superview];
                                                          NSScrollView *aScrollView = [aView enclosingScrollView];
                                                          if (aScrollView == self.assetScrollView) {
                                                              self.selectedAsset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else {
                                                              NSLog(@"NSPopUpButtonWillPopUpNotification something else");
                                                          }
                                                          
                                                      }]; 
        [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          //     NSLog(@"UpdateController NSControlTextDidChangeNotification aNotification: %@", aNotification);
                                                          
                                                          if (([[aNotification object] window] == self.assetDetailPanel)||([aNotification object] == self.assetTableView)) {
                                                              NSLog(@"controlTextDidChange assetDetailPanel || assetTableView");
                                                              
                                                              self.selectedAsset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else {
                                                              NSView *aView = [[aNotification object] superview];
                                                              NSScrollView *aScrollView = [aView enclosingScrollView];
                                                              if (aScrollView == self.assetScrollView) {
                                                                  self.selectedAsset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                                  [self.changedAssetsController rearrangeObjects];
                                                              }
                                                              else {
                                                                  NSLog(@"controlTextDidChange something else");
                                                              }
                                                          }
                                                          
                                                      }];*/
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloc BatchController");
    [self removeObserver:self forKeyPath:@"self.templateName"];
    [self removeObserver:self forKeyPath:@"self.batchAssetsController.arrangedObjects"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
       NSLog(@"BatchController awakeFromNib");
    
    [self.batchAssetsTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"PraxItemsDropType", nil]];
    [self.batchAssetsTableView setSortDescriptors:self.batchSortDescriptors];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.batchViewWindow queue:nil usingBlock:^(NSNotification *aNotification) {
        if (aNotification.object == self.batchViewWindow) {
            NSLog(@"BatchController NSWindowDidBecomeKeyNotification aNotification: %@", aNotification);
            [self loadWebView];
            
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"BatchAssetChangedNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
        Asset *asset = (Asset *)[aNotification object];
        
        if (asset.edit_mode.boolValue) {
            asset.batchPosition = [NSNumber numberWithInt:([self.batchAssetsController.arrangedObjects count] - 1)];
        }
        else {
            
        }
        NSLog(@"BatchController BatchAssetChangedNotification: %@", asset.edit_mode);
        NSLog(@"self.batchAssetsController.arrangedObjects.count: %lu", [self.batchAssetsController.arrangedObjects count]);
        
    }];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.templateName"]) {
        [[NSUserDefaults standardUserDefaults] setObject:self.templateName forKey:@"batchViewTemplate"];
        [self loadWebView];
    }
    else if ([keyPath isEqualToString:@"self.batchAssetsController.arrangedObjects"]) {
        if (self.batchViewWindow.isVisible) {
            [self loadWebView];
            NSLog(@"BatchController observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
        }
    }
    else {
        NSLog(@"BatchController observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    }
}


- (void)windowDidLoad {
    
    NSLog(@"BatchController windowDidLoad");
    
    self.templateName = [[NSUserDefaults standardUserDefaults] objectForKey:@"batchViewTemplate"];
    [self loadWebView];
    
}

- (void)loadWebView {
    if (self.webView) {
        NSString *formatText;
        for (Template *template in self.document.templatesController.arrangedObjects) {
            if ([template.name isEqualToString:self.templateName]) {
                formatText = template.formatText;
                break;
            }
        }
        NSString *html = [TemplateViewController codeForTemplate:formatText withAssets:self.batchAssetsController.arrangedObjects];
        
        [[self.webView mainFrame] loadHTMLString:[html description] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        [self.codeTextView setString:[html description]];
    }
}

- (IBAction)clearBatch:(id)sender {
    NSArray *assets = [self.batchAssetsController.arrangedObjects copy];
    for (Asset *asset in assets) asset.edit_mode = [NSNumber numberWithBool:FALSE];
}

- (NSArray *)batchSortDescriptors {
	if( self._batchSortDescriptors == nil )
	{
		self._batchSortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"batchPosition" ascending:YES]];
	}
	return self._batchSortDescriptors;
}

- (BOOL)tableView:(NSTableView *)table writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pasteboard declareTypes:[NSArray arrayWithObject:@"PraxItemsDropType"] owner:self];
	[pasteboard setData:data forType:@"PraxItemsDropType"];
	return YES;
}
- (NSDragOperation)tableView:(NSTableView*)table validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (([info draggingSource] == self.batchAssetsTableView) || ([info draggingSource] == self.batchAssetsTableView)) {
        NSArray *sortDescriptors = [self.batchAssetsController sortDescriptors];
        if ([sortDescriptors count] > 0) {
            if ([[sortDescriptors[0] key] isEqualToString:@"batchPosition"]) {
                if (operation == NSTableViewDropOn) [table setDropRow:row dropOperation:NSTableViewDropAbove];
                return NSDragOperationMove;
            }
        }
	}
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)table acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];
	NSData *rowData = [pasteboard dataForType:@"PraxItemsDropType"];
	NSIndexSet *draggedItems = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
	NSArray *allItemsArray = [[self.batchAssetsController arrangedObjects] copy];
    NSMutableIndexSet *allItems = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [allItemsArray count])];
    NSMutableIndexSet *firstItems = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *lastItems = [NSMutableIndexSet indexSet];
    [allItems removeIndexes:draggedItems];
    [allItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < row) [firstItems addIndex:idx];
        else [lastItems addIndex:idx];
    }];
    
    __block NSUInteger newRow = 0;
    [firstItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Asset *asset = allItemsArray[idx];
        asset.batchPosition = [NSNumber numberWithInteger:newRow];
        newRow++;
    }];
    [draggedItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Asset *asset = allItemsArray[idx];
        asset.batchPosition = [NSNumber numberWithInteger:newRow];
        newRow++;
    }];
    [lastItems enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        Asset *asset = allItemsArray[idx];
        asset.batchPosition = [NSNumber numberWithInteger:newRow];
        newRow++;
    }];
  	return YES;
}


- (IBAction)addAssetsToBatch:(id)sender {
    for (Asset *asset in self.assetsController.arrangedObjects) {
        asset.edit_mode = @YES;
    }
}

- (IBAction)removeAssetsFromBatch:(id)sender {
    for (Asset *asset in self.assetsController.arrangedObjects) {
        asset.edit_mode = @NO;
    }
}




@end
