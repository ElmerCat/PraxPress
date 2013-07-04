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

//- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = TRUE;
        NSLog(@"SourceSelectionController awakeFromNib");

    }
}

- (IBAction)show:(id)sender {
    [self.popover showRelativeToRect:[self.assetsTableView bounds] ofView:self.assetsTableView preferredEdge:NSMinXEdge];
}


- (IBAction)accountButtonClicked:(id)sender {
    NSTableCellView *view = (NSTableCellView *)[sender superview];
    Asset *account = (Asset *)[view objectValue];
    [(AccountViewController *)[self.accountViewPopover contentViewController] setRepresentedObject:account];
    [self.accountViewPopover showRelativeToRect:[(NSButton *)sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
        if ([[tableView selectedRowIndexes] containsIndex:row] ) return 62;
        else return 62;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [tableView makeViewWithIdentifier:@"ServiceView" owner:self];
}





@end
