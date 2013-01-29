//
//  AssetTableCellView.m
//  PraxPress
//
//  Created by John Canfield on 12/25/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AssetTableCellView.h"

@implementation AssetTableCellView

+(NSInteger)imageTopSelectedSpaceConstant {return 26;}
+(NSInteger)viewModeZeroRowHeight {return 40;}
+(NSInteger)viewModeZeroSelectedRowHeight {return 130;}
+(NSInteger)viewModeOneRowHeight {return 60;}
+(NSInteger)viewModeOneSelectedRowHeight {return 200;}
+(NSInteger)viewModeTwoRowHeight {return 100;}
+(NSInteger)viewModeTwoSelectedRowHeight {return 400;}


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
//            NSLog (@"NSBackgroundStyleLight");
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
//    NSLog (@"layoutViewsForTable asset.title=%@ viewMode: %ld  self.selected=%@", self.asset.title, viewMode, (self.selected ? @"YES" : @"NO"));
    
    NSInteger topSpaceConstant;
    if (self.selected) topSpaceConstant = [AssetTableCellView imageTopSelectedSpaceConstant];
    else topSpaceConstant = 0;
    if (animated) {
        [[self.imageTopConstraint animator] setConstant:topSpaceConstant];
    }
    else {
        [self.imageTopConstraint setConstant:topSpaceConstant];
    }

    CGFloat imageSize;
    if (viewMode == 0) {
        if (self.selected) {
            imageSize =  100;
        }
        else imageSize = 38;
    }
    else if (viewMode == 1) {
        if (self.selected) {
            imageSize =  100;
        }
        else imageSize = 50;
    }
    else {
        imageSize = 100;
    }
    
    //    [self.imageHeightConstraint setConstant:imageSize];
    //    [self.imageWidthConstraint setConstant:imageSize];
    NSView *boxSubview = self.subviews[0];
    
    CGFloat alpha = (self.selected) ? 1 : 0;
    for (int tag = 201; (tag < 250); tag++) {
        NSTextField *selectedOnlyField = [boxSubview viewWithTag:tag];
        if (selectedOnlyField) {
            if (animated) {
                [[selectedOnlyField animator] setAlphaValue:alpha];
            }
            else {
                [selectedOnlyField setAlphaValue:alpha];
            }
        }
        else break;
    }
    alpha = (self.selected) ? 0 : 1;
    for (int tag = 251; (tag < 300); tag++) {
        NSTextField *selectedOnlyField = [boxSubview viewWithTag:tag];
        if (selectedOnlyField) {
            if (animated) {
                [[selectedOnlyField animator] setAlphaValue:alpha];
            }
            else {
                [selectedOnlyField setAlphaValue:alpha];
            }
        }
        else break;
    }
    
/*    for (NSNumber *tag in @[@201,@202,@203,@204,@205,@206]) {
        NSTextField *selectedOnlyField = [boxSubview viewWithTag:tag.integerValue];
        if (selectedOnlyField) {
            if (animated) {
                [[selectedOnlyField animator] setAlphaValue:alpha];
            }
            else {
                [selectedOnlyField setAlphaValue:alpha];
            }
        }
    }*/    
    
    
    NSImageView *imageView = [boxSubview viewWithTag:101];
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
//    [self layoutSubtreeIfNeeded];
    
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
