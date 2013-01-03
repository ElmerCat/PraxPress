//
//  AssetTableCellView.h
//  PraxPress
//
//  Created by John Canfield on 12/25/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AssetTableCellView : NSTableCellView


- (void)layoutViewsForTable:(NSTableView *)table viewMode:(NSInteger)viewMode animated:(BOOL)animated;

@end
