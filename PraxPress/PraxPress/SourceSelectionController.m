//
//  SourceSelectionController.m
//  PraxPress
//
//  Created by Elmer on 12/29/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "SourceSelectionController.h"

@interface SourceSelectionController ()

@end

@implementation SourceSelectionController



- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = TRUE;
        NSLog(@"SourceSelectionController awakeFromNib");
        [[NSNotificationCenter defaultCenter] addObserverForName:NSTableViewSelectionDidChangeNotification object:self.sourceTableView queue:nil usingBlock:^(NSNotification *aNotification){
            if (![self.selectedRowIndexes isEqualToIndexSet:[self.sourceTableView selectedRowIndexes]]) {
                NSMutableIndexSet *changedRowIndexes = [[NSMutableIndexSet alloc] initWithIndexSet: self.selectedRowIndexes];
                self.selectedRowIndexes = [self.sourceTableView selectedRowIndexes];
                [changedRowIndexes addIndexes:self.selectedRowIndexes];
                [self.sourceTableView noteHeightOfRowsWithIndexesChanged:changedRowIndexes];
                [self updateFetchPredicate];
            }
        }];

    }
}

- (IBAction)show:(id)sender {
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
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
    for (Source *source in self.sourceArrayController.selectedObjects) {
        
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
    
    BOOL orFlag = FALSE;
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:20];
    
    
    
    for (Source *source in self.sourceArrayController.selectedObjects) {
        
        
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

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
        
        if ([[tableView selectedRowIndexes] containsIndex:row] ) return 120;
        else return 30;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    return [tableView makeViewWithIdentifier:@"ServiceView" owner:self];
}





@end
