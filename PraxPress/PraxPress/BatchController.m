//
//  PraxController.m
//  PraxPress
//
//  Created by John Canfield on 8/24/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "BatchController.h"

@implementation BatchController

NSString *PraxItemsDropType = @"PraxItemsDropType";
int temporaryViewPosition = -1;
int startViewPosition = -2;
int endViewPosition = -3;

#define temporaryViewPositionNum [NSNumber numberWithInt:temporaryViewPosition]
#define startViewPositionNum [NSNumber numberWithInt:startViewPosition]
#define endViewPositionNum [NSNumber numberWithInt:endViewPosition]

+ (NSSet *)keyPathsForValuesAffectingBatchChangeCopyValue {
    return [NSSet setWithObjects:@"self.batchChangeKey", @"self.selectedAsset", nil];
}


- (NSPredicate *)batchEditFilterPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(edit_mode == YES) AND (entity.name != \"Account\")"];
    return predicate;
}



- (id)init {
    self = [super init];
    if (self) {
        //    NSLog(@"BatchController init");
        
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
        

        
/*        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                       //   if ([aNotification object] == self.postEditorPanel) {
                                                        //      [self.postEditor loadWebView];
                                                         // }
                                                          //        else NSLog(@"UpdateController NSWindowDidResignKeyNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];*/
/*        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                          NSSet *set = [NSSet setWithObjects:self.trackEditorPanel, self.playlistEditorPanel, self.postEditorPanel, self.previewFrameWindow, nil];
                                                          if ([set containsObject:[aNotification object]])[[aNotification object] close];
                                                          
                                                          else if ([aNotification object] == self.postsWindow) {
                                                              if ([[self.postsController arrangedObjects] count] > 0) {
                                                                  self.selectedAsset = (([[self.postsController selectedObjects] count] > 0) ? [self.postsController selectedObjects][0] : [self.postsController arrangedObjects][0]);
                                                              }
                                                          }
                                                          else if ([aNotification object] == self.tracksWindow) {
                                                              if ([[self.tracksController arrangedObjects] count] > 0) {
                                                                  self.selectedAsset = (([[self.tracksController selectedObjects] count] > 0) ? [self.tracksController selectedObjects][0] : [self.tracksController arrangedObjects][0]);
                                                              }
                                                          }
                                                          else if ([aNotification object] == self.playlistsWindow) {
                                                              if ([[self.playlistsController arrangedObjects] count] > 0) {
                                                                  self.selectedAsset = (([[self.playlistsController selectedObjects] count] > 0) ? [self.playlistsController selectedObjects][0] : [self.playlistsController arrangedObjects][0]);
                                                              }
                                                          }
                                                          //        else NSLog(@"UpdateController NSWindowDidResignKeyNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }]; */
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
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
/*        [[NSNotificationCenter defaultCenter] addObserverForName:NSTextDidChangeNotification
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    //   NSLog(@"UpdateController awakeFromNib");
    
    [self.batchAssetsTableView registerForDraggedTypes:[NSArray arrayWithObjects:PraxItemsDropType, nil]];
    [self.batchAssetsTableView setSortDescriptors:self.batchSortDescriptors];
    
}

- (NSPredicate *)changedAssetsFilterPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync_mode == YES"];
    return predicate;
}

- (IBAction)clearBatch:(id)sender {
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES"];
    NSArray *items = [self itemsUsingFetchPredicate:fetchPredicate];
    for (Asset *asset in items) asset.edit_mode = [NSNumber numberWithBool:FALSE];
    [self.batchAssetsController rearrangeObjects];
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
	[pasteboard declareTypes:[NSArray arrayWithObject:PraxItemsDropType] owner:self];
	[pasteboard setData:data forType:PraxItemsDropType];
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
	NSData *rowData = [pasteboard dataForType:PraxItemsDropType];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    
	NSArray *allItemsArray = [self.batchAssetsController arrangedObjects];
	NSMutableArray *draggedItemsArray = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    
	NSUInteger currentItemIndex;
	NSRange range = NSMakeRange( 0, [rowIndexes lastIndex] + 1 );
	while([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
	{
		Asset *thisItem = [allItemsArray objectAtIndex:currentItemIndex];
        
		[draggedItemsArray addObject:thisItem];
	}
    
	int count;
	for( count = 0; count < [draggedItemsArray count]; count++ )
	{
		Asset *currentItemToMove = [draggedItemsArray objectAtIndex:count];
		[currentItemToMove setValue:temporaryViewPositionNum forKey:@"batchPosition"];
	}
    
	int tempRow;
	if( row == 0 )
		tempRow = -1;
	else
		tempRow = row;
    
	NSArray *startItemsArray = [self itemsWithViewPositionBetween:0 and:tempRow];
	NSArray *endItemsArray = [self itemsWithViewPositionGreaterThanOrEqualTo:row];
    
	int currentViewPosition;
    
	currentViewPosition = [self renumberViewPositionsOfItems:startItemsArray startingAt:0];
    
	currentViewPosition = [self renumberViewPositionsOfItems:draggedItemsArray startingAt:currentViewPosition];
    
	currentViewPosition = [self renumberViewPositionsOfItems:endItemsArray startingAt:currentViewPosition];
    
	return YES;
}

- (NSArray *)itemsWithViewPosition:(int)value
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES && batchPosition == %i", value];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithNonTemporaryViewPosition
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES && batchPosition >= 0"];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithViewPositionGreaterThanOrEqualTo:(int)value
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES && batchPosition >= %i", value];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (NSArray *)itemsWithViewPositionBetween:(int)lowValue and:(int)highValue
{
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(edit_mode == YES) && ((batchPosition >= %i) && (batchPosition <= %i))", lowValue, highValue];
    
	return [self itemsUsingFetchPredicate:fetchPredicate];
}

- (int)renumberViewPositionsOfItems:(NSArray *)array startingAt:(int)value
{
	int currentViewPosition = value;
    
	int count = 0;
    
	if( array && ([array count] > 0) )
	{
		for( count = 0; count < [array count]; count++ )
		{
			Asset *currentObject = [array objectAtIndex:count];
			[currentObject setValue:[NSNumber numberWithInt:currentViewPosition] forKey:@"batchPosition"];
			currentViewPosition++;
		}
	}
    
	return currentViewPosition;
}

- (void)renumberViewPositions
{
	NSArray *startItems = [self itemsWithViewPosition:startViewPosition];
    
	NSArray *existingItems = [self itemsWithNonTemporaryViewPosition];
    
	NSArray *endItems = [self itemsWithViewPosition:endViewPosition];
    
	int currentViewPosition = 0;
    
	if( startItems && ([startItems count] > 0) )
		currentViewPosition = [self renumberViewPositionsOfItems:startItems startingAt:currentViewPosition];
    
	if( existingItems && ([existingItems count] > 0) )
		currentViewPosition = [self renumberViewPositionsOfItems:existingItems startingAt:currentViewPosition];
    
	if( endItems && ([endItems count] > 0) )
		currentViewPosition = [self renumberViewPositionsOfItems:endItems startingAt:currentViewPosition];
    [self.batchAssetsController rearrangeObjects];
}



- (NSArray *)itemsUsingFetchPredicate:(NSPredicate *)fetchPredicate
{
    NSManagedObjectContext *moc = [self.document managedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
    [fetchRequest setPredicate:fetchPredicate];
    NSError *error = nil;
    NSArray *arrayOfItems;
	[fetchRequest setSortDescriptors:self.batchSortDescriptors];
	arrayOfItems = [moc executeFetchRequest:fetchRequest error:&error];
    
	return arrayOfItems;
}


 - (IBAction)addAssetBatchButtonClicked:(id)sender {
    NSArray *items = [self.assetsController arrangedObjects];
    Asset *item;
    for (NSInteger row = 0; row < [items count]; row++) {
        item = items[row];
        [item setValue:[NSNumber numberWithBool:TRUE] forKey:@"edit_mode"];
        //  NSLog(@"item: %@", item);
    }
    [self.batchAssetsController rearrangeObjects];
}

- (IBAction)removeAssetBatchButtonClicked:(id)sender {
    NSArray *items = [self.assetsController arrangedObjects];
    Asset *item;
    for (NSInteger row = 0; row < [items count]; row++) {
        item = items[row];
        [item setValue:[NSNumber numberWithBool:FALSE] forKey:@"edit_mode"];
        //  NSLog(@"item: %@", item);
    }
    [self.batchAssetsController rearrangeObjects];
}




@end
