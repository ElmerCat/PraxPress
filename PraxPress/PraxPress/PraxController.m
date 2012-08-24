//
//  PraxController.m
//  PraxPress
//
//  Created by John Canfield on 8/24/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "PraxController.h"

@implementation PraxController

NSString *PraxItemsDropType = @"PraxItemsDropType";
int temporaryViewPosition = -1;
int startViewPosition = -2;
int endViewPosition = -3;

#define temporaryViewPositionNum [NSNumber numberWithInt:temporaryViewPosition]
#define startViewPositionNum [NSNumber numberWithInt:startViewPosition]
#define endViewPositionNum [NSNumber numberWithInt:endViewPosition]

- (id)init {
    self = [super init];
    if (self) {
        //    NSLog(@"PraxController init");
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                          if ([aNotification object] == self.postEditorPanel) {
                                                              [self.postEditor loadWebView];
                                                          }
                                                          //        else NSLog(@"UpdateController NSWindowDidResignKeyNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                          NSSet *set = [NSSet setWithObjects:self.trackEditorPanel, self.playlistEditorPanel, self.postEditorPanel, self.previewFrameWindow, nil];
                                                          if ([set containsObject:[aNotification object]])[[aNotification object] close];
                                                          
                                                          else if ([aNotification object] == self.postsWindow) {
                                                              if ([[self.postsController arrangedObjects] count] > 0) {
                                                                  self.lastSelectedAsset = (([[self.postsController selectedObjects] count] > 0) ? [self.postsController selectedObjects][0] : [self.postsController arrangedObjects][0]);
                                                              }
                                                          }
                                                          else if ([aNotification object] == self.tracksWindow) {
                                                              if ([[self.tracksController arrangedObjects] count] > 0) {
                                                                  self.lastSelectedAsset = (([[self.tracksController selectedObjects] count] > 0) ? [self.tracksController selectedObjects][0] : [self.tracksController arrangedObjects][0]);
                                                              }
                                                          }
                                                          else if ([aNotification object] == self.playlistsWindow) {
                                                              if ([[self.playlistsController arrangedObjects] count] > 0) {
                                                                  self.lastSelectedAsset = (([[self.playlistsController selectedObjects] count] > 0) ? [self.playlistsController selectedObjects][0] : [self.playlistsController arrangedObjects][0]);
                                                              }
                                                          }
                                                          //        else NSLog(@"UpdateController NSWindowDidResignKeyNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          if ([aNotification object] == self.formatCodeTableView){
                                                              [self updateGeneratedCode];
                                                          }
                                                          else NSLog(@"UpdateController NSTableViewSelectionDidChangeNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          //     NSLog(@"UpdateController NSControlTextDidChangeNotification aNotification: %@", aNotification);
                                                          
                                                          Asset *asset;
                                                          if (([[aNotification object] window] == self.trackEditorPanel)||([aNotification object] == self.tracksTableView)) {
                                                              //          NSLog(@"controlTextDidChange trackEditorPanel || tracksTableView");
                                                              asset = [self.tracksController selectedObjects][0];
                                                              asset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else if (([[aNotification object] window] == self.playlistEditorPanel)||([aNotification object] == self.playlistsTableView)) {
                                                              NSLog(@"controlTextDidChange playlistEditorPanel || playlistsTableView");
                                                              asset = [self.playlistsController selectedObjects][0];
                                                              asset.sync_mode = [NSNumber numberWithBool:TRUE];
                                                              [self.changedAssetsController rearrangeObjects];
                                                          }
                                                          else NSLog(@"controlTextDidChange something else");
                                                          
                                                      }];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)awakeFromNib {
    //   NSLog(@"UpdateController awakeFromNib");
    
    [self.assetBatchEditTable registerForDraggedTypes:[NSArray arrayWithObjects:PraxItemsDropType, nil]];
    [self.assetBatchEditTable setSortDescriptors:self.batchSortDescriptors];
    
}


- (void)textDidChange:(NSNotification *)aNotification {
    
    if ((([aNotification object] == self.startingFormatText)||([aNotification object] == self.blockFormatText))|| ([aNotification object] == self.endingFormatText)){
        [self updateGeneratedCode];
    }
    
}

- (NSPredicate *)changedAssetsFilterPredicate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync_mode == YES"];
    return predicate;
}


- (void)postsTableDoubleClicked {
    [self.postEditorPanel makeKeyAndOrderFront:self];
}
- (void)tracksTableDoubleClicked {
    [self.trackEditorPanel makeKeyAndOrderFront:self];
}
- (void)playlistsTableDoubleClicked {
    [self.playlistEditorPanel makeKeyAndOrderFront:self];
}


- (IBAction)copyPurchaseTitle:(id)sender {
    [self.changePurchaseTitle setStringValue:[sender title]];
}

- (IBAction)copyPurchaseURL:(id)sender {
    [self.changePurchaseURL setStringValue:[sender title]];
}

- (IBAction)performBatchChanges:(id)sender {
    
    for (Asset *asset in [self.assetBatchEditController arrangedObjects]) {
        if (self.batchChangePurchaseTitle) {
            asset.purchase_title = [self.changePurchaseTitle stringValue];
            asset.sync_mode = [NSNumber numberWithBool:TRUE];
        }
        if (self.batchChangePurchaseURL) {
            asset.purchase_url = [self.changePurchaseURL stringValue];
            asset.sync_mode = [NSNumber numberWithBool:TRUE];
        }
        if (self.batchChangeTitleSubstrings) {
            asset.title = [asset.title stringByReplacingOccurrencesOfString:[self.changeTitleSubstringFrom stringValue] withString:[self.changeTitleSubstringTo stringValue]];
            asset.sync_mode = [NSNumber numberWithBool:TRUE];
        }
        
    }
    self.batchChangePurchaseTitle = FALSE;
    self.batchChangePurchaseURL = FALSE;
    self.batchChangeTitleSubstrings = FALSE;
    [self.changedAssetsController rearrangeObjects];
}

- (IBAction)clearBatch:(id)sender {
    NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"edit_mode == YES"];
    NSArray *items = [self itemsUsingFetchPredicate:fetchPredicate];
    for (Asset *asset in items) asset.edit_mode = [NSNumber numberWithBool:FALSE];
    [self.assetBatchEditController rearrangeObjects];
}


- (IBAction)praxAction:(id)sender {
    NSLog(@"praxAction: - praxAction: - praxAction: - praxAction: - praxAction: - ");
    [[NSSound soundNamed:@"Error"] play];
    
}


- (NSString *)stringWithTemplate:(NSString *)template forAsset:(Asset *)asset {
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:1024];
    NSRange foundRange;
    NSRange sourceRange;
    sourceRange.location = 0;
    sourceRange.length = [template length];
    BOOL flag = FALSE;
    while (flag == FALSE) {
        foundRange = [template rangeOfString:@"$$$" options:0 range:sourceRange];
        if (foundRange.location == NSNotFound) {
            flag = TRUE;
            break;
        }
        
        sourceRange.length = (foundRange.location - sourceRange.location);
        [string appendString:[template substringWithRange:sourceRange]];
        
        sourceRange.location = (foundRange.location + 3);
        sourceRange.length = ([template length] - sourceRange.location);
        foundRange = [template rangeOfString:@"$$$" options:0 range:sourceRange];
        if (foundRange.location == NSNotFound) {
            flag = TRUE;
            
        }
        else {
            sourceRange.length = (foundRange.location - sourceRange.location);
            
            NSString *key = [template substringWithRange:sourceRange];
            NSString *value = [self valueOfItem:asset asStringForKey:key];
            if ([value length] > 0) [string appendString:value];
            sourceRange.location = (foundRange.location + 3);
            sourceRange.length = ([template length] - sourceRange.location);
        }
    }
    [string appendString:[template substringWithRange:sourceRange]];
    return string;
}

- (NSString *)valueOfItem:(NSManagedObject *)item asStringForKey:(NSString *)key {
    NSEntityDescription *entity = [item entity];
    NSDictionary *attributesByName = [entity attributesByName];
    NSAttributeDescription *attribute = attributesByName[key];
    if (!attribute) {
        return @"---No Such Attribute Key---";
    }
    else if ([attribute attributeType] == NSUndefinedAttributeType) {
        return @"---Undefined Attribute Type---";
    }
    else if ([attribute attributeType] == NSStringAttributeType) {
        return [item valueForKey:key];
    }
    else if ([attribute attributeType] < NSDateAttributeType) {
        return [[item valueForKey:key] stringValue];
    }
    // add more "else if" code as desired for other types
    
    else {
        return @"---Unacceptable Attribute Type---";
    }
}

- (IBAction)preview:(id)sender {
    
    NSMutableString *html = [[NSMutableString alloc] initWithCapacity:1024];
    if ([[self.startingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.startingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    NSArray *assets = [self.assetBatchEditController arrangedObjects];
    if (([assets count] > 0) &&  ([[self.blockFormatText string] length] > 0)){
        for (Asset *asset in assets) {
            [html appendString:[self stringWithTemplate:[self.blockFormatText string] forAsset:asset]];
        }
    }
    
    if ([[self.endingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.endingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    //   NSLog(@"html: %@", html);
    
    //    [self.generatedCodeText setStringValue:html];
    [[self.previewWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    [self.previewFrameWindow makeKeyAndOrderFront:self];
}

- (void)updateGeneratedCode {
    
    NSMutableString *html = [[NSMutableString alloc] initWithCapacity:1024];
    if ([[self.startingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.startingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    NSArray *assets = [self.assetBatchEditController arrangedObjects];
    if (([assets count] > 0) &&  ([[self.blockFormatText string] length] > 0)){
        for (Asset *asset in assets) {
            [html appendString:[self stringWithTemplate:[self.blockFormatText string] forAsset:asset]];
        }
    }
    
    if ([[self.endingFormatText string] length] > 0) {
        [html appendString:[self stringWithTemplate:[self.endingFormatText string] forAsset:self.lastSelectedAsset]];
    }
    
    //   NSLog(@"html: %@", html);
    
    [self.generatedCodeText setStringValue:html];
    //    [[self.previewWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    //    [self.previewFrameWindow makeKeyAndOrderFront:self];
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
	if( [info draggingSource] == self.assetBatchEditTable ) {
        NSArray *sortDescriptors = [self.assetBatchEditTable sortDescriptors];
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
    
	NSArray *allItemsArray = [self.assetBatchEditController arrangedObjects];
	NSMutableArray *draggedItemsArray = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
    
	NSUInteger currentItemIndex;
	NSRange range = NSMakeRange( 0, [rowIndexes lastIndex] + 1 );
	while([rowIndexes getIndexes:&currentItemIndex maxCount:1 inIndexRange:&range] > 0)
	{
		NSManagedObject *thisItem = [allItemsArray objectAtIndex:currentItemIndex];
        
		[draggedItemsArray addObject:thisItem];
	}
    
	int count;
	for( count = 0; count < [draggedItemsArray count]; count++ )
	{
		NSManagedObject *currentItemToMove = [draggedItemsArray objectAtIndex:count];
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
			NSManagedObject *currentObject = [array objectAtIndex:count];
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
    [self.assetBatchEditController rearrangeObjects];
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

//tableView:writeRowsWithIndexes:toPasteboard:	[newItem setValue:[NSNumber numberWithInt:-1] forKey:@"viewPosition"];





@end
