//
//  SourceController.h
//  PraxPress
//
//  Created by Elmer on 6/22/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "Source.h"
#import "SourceTableRowView.h"
#import "AssetListViewController.h"
#import "AssetListView.h"
#import "SourcePopovers.h"
@class SourcePopovers;

@interface SourceController : NSObject
@property BOOL awake;
@property (weak) IBOutlet Document *document;
@property (weak) IBOutlet NSToolbar *documentToolbar;
@property (weak) IBOutlet NSSplitView *sourceSplitView;
@property (weak) IBOutlet NSView *sourceListSubView;
@property (weak) IBOutlet NSPopover *sourcePopover;
@property (unsafe_unretained) IBOutlet SourcePopovers *sourcePopovers;
@property NSMapTable *sourceListCellControllers;
@property (weak) IBOutlet NSOutlineView *sourceListOutlineView;

+ (void)initWithType:(NSString *)typeName inManagedObjectContext:(NSManagedObjectContext *)moc;

-(void)reset;
- (IBAction)toolbarItemSelected:(id)sender;
- (IBAction)sourceDetailsButtonPressedRightEdge:(id)sender;
- (IBAction)sourceDetailsButtonPressedBottomEdge:(id)sender;

@end