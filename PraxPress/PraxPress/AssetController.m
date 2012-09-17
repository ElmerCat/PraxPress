//
//  AssetController.m
//  PraxPress
//
//  Created by John Canfield on 9/17/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AssetController.h"

@implementation AssetController
@synthesize assetsController;
@synthesize assetDetailWebView;
@synthesize assetDetailView;


- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"Asset init");
        //       [[NSSound soundNamed:@"Start"] play];
        
        //        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        //       [notificationCenter addObserver:self
        //                              selector:@selector(tracksNotification:)
        //                                  name:tracksNotificationName object:nil];
        //     [notificationCenter addObserver:self
        //                          selector:@selector(undoNotification:)
        //                            name:NSUndoManagerCheckpointNotification
        //                        object:[[document managedObjectContext] undoManager]];
    }
    return self;
}


- (void)awakeFromNib {
    NSLog(@"Asset awakeFromNib");
    
}

- (void)windowWillClose:(NSNotification *)notification {
    [[self.assetDetailWebView mainFrame] loadHTMLString:@"Prax" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
    Asset *asset = (([[self.assetsController selectedObjects] count] > 0) ? [self.assetsController selectedObjects][0] : [self.assetsController arrangedObjects][0]);
    if (([asset.type isEqualToString:@"post"])||([asset.type isEqualToString:@"page"])) {
        [self.assetDetailWebView setMainFrameURL:asset.purchase_url];
    }
    else {
        NSString *html = [Asset htmlStringForAsset:asset];
        [[self.assetDetailWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }

    
    
    
}




@end
