//
//  TrackView.m
//  PraxPress
//
//  Created by John Canfield on 7/30/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "TrackView.h"

@implementation TrackView

static void *TrackChange = &TrackChange;
static void *PraxChange = &PraxChange;

- (void)awakeFromNib {
    
//    NSLog(@"awakeFromNib TrackView");
    
    [self addObserver:self forKeyPath:@"self.objectValue.title" options:NSKeyValueObservingOptionNew context:TrackChange];
    [self addObserver:self forKeyPath:@"self.objectValue.purchase_title" options:NSKeyValueObservingOptionNew context:TrackChange];
    [self addObserver:self forKeyPath:@"self.objectValue.purchase_url" options:NSKeyValueObservingOptionNew context:TrackChange];
    
}

-(void)dealloc {
//    NSLog(@"dealloc TrackView");
    [self removeObserver:self forKeyPath:@"self.objectValue.title"];
    [self removeObserver:self forKeyPath:@"self.objectValue.purchase_title"];
    [self removeObserver:self forKeyPath:@"self.objectValue.purchase_url"];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if (context == TrackChange)
	{
        NSString *old;
        if([keyPath isEqualToString:@"self.objectValue.title"]) {
            old = [self.objectValue valueForKey:@"title_x"];
        //    NSLog(@"self.objectValue.title: %@", change[@"new"]);
            
        }
        else if([keyPath isEqualToString:@"self.objectValue.purchase_title"]) {
            old = [self.objectValue valueForKey:@"purchase_title_x"];
        //    NSLog(@"self.objectValue.purchase_title: %@", change[@"new"]);
            
        }
        else if([keyPath isEqualToString:@"self.objectValue.purchase_url"]) {
        //    NSLog(@"self.objectValue.purchase_url: %@", change[@"new"]);
            
        }
        else {
            NSLog(@"invalid TrackChange");
        }
        if ([old isEqualToString:change[@"new"]]) {
            [self.objectValue setValue:[NSNumber numberWithBool:FALSE] forKey:@"sync_mode"];
        }
        else{
            [self.objectValue setValue:[NSNumber numberWithBool:TRUE] forKey:@"sync_mode"];
            
 //           NSLog(@"SoundCloudController observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);

        }
        
    }
    else if (context == PraxChange)
	{
        NSLog(@"invalid PraxChange");
	}
    
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (IBAction)revertButtonClicked:(id)sender {
    NSString *old;
    old = [self.objectValue valueForKey:@"title_x"];
    [self.objectValue setValue:old forKey:@"title"];
    old = [self.objectValue valueForKey:@"purchase_title_x"];
    [self.objectValue setValue:old forKey:@"purchase_title"];
    old = [self.objectValue valueForKey:@"purchase_url_x"];
    [self.objectValue setValue:old forKey:@"purchase_url"];
    
    [self.objectValue setValue:[NSNumber numberWithBool:FALSE] forKey:@"sync_mode"];
    
}
- (IBAction)uploadButtonClicked:(id)sender {
    
    [self.soundCloudController uploadTrackData:[self objectValue]];
    
}

- (IBAction)refreshButtonClicked:(id)sender {
    
    [self.soundCloudController refreshTrack:self.objectValue];
    
    
}



-(BOOL) hasChanges {
    
    return [self.objectValue hasChanges];
}

- (void) layoutViewsForObjectModeAnimate:(BOOL)animate {
    
//    CGFloat largeControlsTargetAlpha = 0.0f;
//    CGFloat smallControlsTargetAlpha = 1.0f;
    CGFloat imageViewTargetSize = 20;

//    NSRect imageFrame = self.imageView.frame;
//    NSRect imageBounds = self.imageView.bounds;
    
    if ([[self.objectValue valueForKey:@"info_mode"] boolValue ] == TRUE) {
//        largeControlsTargetAlpha = 1.0f;
//        smallControlsTargetAlpha = 0.0f;
        imageViewTargetSize = 120;
//        imageFrame.size = CGSizeMake(120, 120);
//        imageBounds.size = CGSizeMake(120, 120);
    }
    else {
//        imageFrame.size = CGSizeMake(20, 20);
//        imageBounds.size = CGSizeMake(20, 20);
    }
    if (animate == TRUE) {
        [[self.imageViewWidthConstraint animator] setConstant:imageViewTargetSize];
        
    }
    else {
        [self.imageViewWidthConstraint setConstant:imageViewTargetSize];
        
    }
    
//    [[self.imageViewHeightConstraint animator] setConstant:imageViewTargetSize];

//    [[self.imageView animator] setFrame:imageFrame];
//    [[self.imageView animator] setBounds:imageBounds];
    

//    for (id control in @[_largeTitleField, _largeImageWell]) {
//        [[control animator] setAlphaValue:largeControlsTargetAlpha];
//    }
//    for (id control in @[_smallTitleField, _smallImageWell]) {
 //       [[control animator] setAlphaValue:smallControlsTargetAlpha];
//    }

    
     
}

- (IBAction)cellDoubleClickAction:(id)sender {
    
    BOOL newValue = [[self.objectValue valueForKey:@"info_mode"] boolValue] ? FALSE : TRUE;
    
    [self.objectValue setValue:[NSNumber numberWithBool:newValue] forKey:@"info_mode"];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    
    [self layoutViewsForObjectModeAnimate:TRUE];
    
    [sender noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[sender clickedRow]]];
    [NSAnimationContext endGrouping];
    
}


@end
