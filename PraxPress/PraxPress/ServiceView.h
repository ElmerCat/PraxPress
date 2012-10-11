//
//  ServiceView.h
//  PraxPress
//
//  Created by John Canfield on 10/10/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Account.h"
#import "SourceController.h"
@class SourceController;

@interface ServiceView : NSTableCellView
@property (readonly) Account *account;
@property NSString *checkOneTitle;
@property NSString *checkTwoTitle;
@property NSString *checkThreeTitle;
@property NSString *checkFourTitle;

@property IBOutlet SourceController *sourceController;
@property IBOutlet NSSearchField *searchField;
@property NSInteger searchCategory;

- (IBAction)setSearchCategoryFrom:(NSMenuItem *)menuItem;
- (IBAction)updateFilter:sender;

- (IBAction)praxButtonClicked:(id)sender;

@end
