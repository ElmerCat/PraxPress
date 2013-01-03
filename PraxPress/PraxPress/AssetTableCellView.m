//
//  AssetTableCellView.m
//  PraxPress
//
//  Created by John Canfield on 12/25/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AssetTableCellView.h"

@implementation AssetTableCellView


  
/* - (void)awakeFromNib {
     NSLog(@"AssetTableCellView awakeFromNib");
     [self addObserver:self forKeyPath:@"self.objectValue.title" options:NSKeyValueObservingOptionNew context:NULL];
 
 }
 


- (void)dealloc {
    NSLog(@"AssetTableCellView dealloc");
    
    [self removeObserver:self forKeyPath:@"self.objectValue.title"];
    
    //    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"AssetTableCellView observeValueForKeyPath:%@", keyPath);
    
    
}

*/



/*- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
    [super setBackgroundStyle:style];
    
    // If the cell's text color is black, this sets it to white
//    [((NSCell *)self.descriptionField.cell) setBackgroundStyle:style];
    
    // Otherwise you need to change the color manually
    switch (style) {
        case NSBackgroundStyleLight:
            NSLog (@"NSBackgroundStyleLight");
//            [self.descriptionField setTextColor:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
            break;
            
        case NSBackgroundStyleDark:
        default:
            NSLog (@"NSBackgroundStyleDark");
//            [self.descriptionField setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
            break;
    }
}*/

- (void)layoutViewsForTable:(NSTableView *)table viewMode:(NSInteger)viewMode animated:(BOOL)animated {
//    NSLog (@"layoutViewsForTable viewMode:: %ld", viewMode);
    
//    NSInteger selectedRow = table.selectedRow;
//    NSInteger row = [table rowForView:(NSTableCellView *)self];

//    NSLog (@"layoutViewsForTable row:: %ld", row);
    
//    NSInteger newViewMode;
//    if ((row >= 0) && (row == selectedRow)) {
//        newViewMode = 4;
//    }
    
//    if (self.backgroundStyle == NSBackgroundStyleDark) newViewMode = 4;
//    else newViewMode = viewMode + 1;
    
//    if (self.viewMode != newViewMode) {
//        self.viewMode = newViewMode;
    
    
    CGFloat imageSize;
    if (viewMode == 0) {
        imageSize = 14;
        
    }
    else if (viewMode == 1) {
        imageSize = 50;
        
    }
    else {
        imageSize = 100;
        
    }
    
    NSView *subview = self.subviews[0];
    
    NSImageView *imageView = [subview viewWithTag:101];
    NSArray *constraints = imageView.constraints;
    for (NSLayoutConstraint *constraint in constraints) {
        if ((constraint.firstAttribute == NSLayoutAttributeHeight) || (constraint.firstAttribute == NSLayoutAttributeWidth)) {
            if (animated) {
                [[constraint animator] setConstant:imageSize];
            }
            else {
                [constraint setConstant:imageSize];
            }
            
        }
    }
    
 /*       if (animated) {
            [[self.imageWidth animator] setConstant:imageSize];
            [[self.imageHeight animator] setConstant:imageSize];
        }
        else {
            [self.imageWidth setConstant:imageSize];
            [self.imageHeight setConstant:imageSize];
        }
  */      
//    }
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
