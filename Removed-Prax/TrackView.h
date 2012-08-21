//
//  TrackView.h
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import "SoundCloudController.h"
#import "Track.h"
@class Document;
@class SoundCloudController;

@interface TrackView : NSTableCellView

@property (readonly) BOOL hasChanges;
@property (weak) IBOutlet SoundCloudController *soundCloudController;


@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
@property (weak) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;

@property (weak) IBOutlet NSTextField *titleField;

- (IBAction)revertButtonClicked:(id)sender;
- (IBAction)uploadButtonClicked:(id)sender;
- (IBAction)refreshButtonClicked:(id)sender;
- (void) layoutViewsForObjectModeAnimate:(BOOL)animate;
- (IBAction)cellDoubleClickAction:(id)sender;

@end
