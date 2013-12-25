//
//  WidgetMenuView.h
//  PraxPress
//
//  Created by Elmer on 12/11/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WidgetViewController.h"
@class WidgetViewController;
@interface WidgetMenuView : NSView <NSMenuDelegate>

@property id representedObject;
@property NSMenuItem *menuItem;
@property (weak) IBOutlet NSBox *topLeftCorner;
@property (weak) IBOutlet NSLayoutConstraint *widgetMenuWidth;
@property (unsafe_unretained) IBOutlet WidgetViewController *widgetViewController;

@end
