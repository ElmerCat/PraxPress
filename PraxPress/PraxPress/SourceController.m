//
//  SourceController.m
//  PraxPress
//
//  Created by John Canfield on 10/9/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "SourceController.h"

@implementation SourceController

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AssetController init");
        [[NSNotificationCenter defaultCenter] addObserverForName:NSOutlineViewSelectionDidChangeNotification object:self.sourceOutlineView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.selectedRowIndexes isEqualToIndexSet:[self.sourceOutlineView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet: self.selectedRowIndexes];
                self.selectedRowIndexes = [self.sourceOutlineView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.selectedRowIndexes];
                [self.sourceOutlineView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [self updateFetchPredicate];
            }
        }];
    }
    return self;
}

- (void)awakeFromNib {
       NSLog(@"SourceController awakeFromNib");
    

    
//    [NSBundle loadNibNamed:@"SourceView" owner:self];
}


- (IBAction)accountButtonClicked:(id)sender {
    ServiceView *view = (ServiceView *)[sender superview];
    
    Account *account = (Account *)[[view objectValue] account];
    
    [(AccountViewController *)[self.accountViewPopover contentViewController] setRepresentedObject:account];
    
    [self.accountViewPopover showRelativeToRect:[(NSButton *)sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (IBAction)filterButtonClicked:(id)sender {
    [self updateFetchPredicate];
}

- (void) updateFilterPredicate {
    
    BOOL orFlag = FALSE;
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:20];
    
    for (Source *source in self.sourceTreeController.selectedObjects) {
        
        if ((source.predicateFormat != nil) && (![source.predicateFormat isEqualToString:@""])) {
            if (orFlag) [string appendString:@" OR "];
            [string appendString:source.predicateFormat];
            orFlag = TRUE;
            
        }
         
    }
    
    if ([string length] > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:string];
        [self.assetsController setFilterPredicate:predicate];
    }
    else [self.assetsController setFilterPredicate:nil];
    
    
    [self.assetsController rearrangeObjects];
    
}

- (void) updateFetchPredicate {
    NSLog(@"SourceController updateFetchPredicate");
    
    BOOL orFlag = FALSE;
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:20];
    
    
    
    for (Source *source in self.sourceTreeController.selectedObjects) {
        
        
        if ([source.name isEqualToString:@"WordPress"]) {
            if (source.optionOne.boolValue == TRUE) {
                if (orFlag) [string appendString:@" OR "];
                [string appendString:@"type == \"post\""];
                orFlag = TRUE;
            }
            if (source.optionTwo.boolValue  == TRUE) {
                if (orFlag) [string appendString:@" OR "];
                [string appendString:@"type == \"page\""];
                orFlag = TRUE;
            }
        }
        
        else if ([source.name isEqualToString:@"SoundCloud"]) {
            if (source.optionOne.boolValue  == TRUE) {
                if (orFlag) [string appendString:@" OR "];
                [string appendString:@"type == \"track\""];
                orFlag = TRUE;
            }
            if (source.optionTwo.boolValue  == TRUE) {
                if (orFlag) [string appendString:@" OR "];
                [string appendString:@"type == \"playlist\""];
                orFlag = TRUE;
            }
        }
        
        
 
    }
    
    if ([string length] < 1) {
        
        [string setString:@"type == \"nothing\""];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:string];
    [self.assetsController setFetchPredicate:predicate];
    [self updateFilterPredicate];
    
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    NSManagedObject *source = [(NSTreeNode *)item representedObject];
    if ([source valueForKey:@"parent"]) {
        
        if ([[outlineView selectedRowIndexes] containsIndex:[outlineView rowForItem:item]] ) return 120;
        else return 20;
    }
    else return 20;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    NSManagedObject *source = [(NSTreeNode *)item representedObject];
    if ([source valueForKey:@"parent"]) return FALSE;
    else return TRUE;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    
    NSManagedObject *source = [(NSTreeNode *)item representedObject];
    if (![source valueForKey:@"parent"]) return [outlineView makeViewWithIdentifier:@"SourceView" owner:self];
    else return [outlineView makeViewWithIdentifier:@"ServiceView" owner:self];

    
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
*/}


@end
