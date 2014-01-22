//
//  PraxDefaultsController.h
//  PraxPress
//
//  Created by John-Elmer on 1/13/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PraxCategories.h"

@interface PraxDefaultsController : NSObject <NSTableViewDelegate, NSTextFieldDelegate>

@property BOOL awake;


@property (unsafe_unretained) IBOutlet NSPanel *panel;
@property (weak) IBOutlet NSToolbar *toolbar;
@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSArrayController *templatesArrayController;

- (IBAction)selectPane:(id)sender;

- (IBAction)duplicateTemplate:(id)sender;
- (IBAction)exportTemplates:(id)sender;
- (IBAction)importTemplates:(id)sender;

@end
