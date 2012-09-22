//
//  AssetController.m
//  PraxPress
//
//  Created by John Canfield on 9/17/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AssetController.h"

@implementation AssetController


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
    
    if (([self.praxController.selectedAsset.type isEqualToString:@"post"])||([self.praxController.selectedAsset.type isEqualToString:@"page"])) {
        [self.assetDetailWebView setMainFrameURL:self.praxController.selectedAsset.purchase_url];
    }
    else {
        NSString *html = [Asset htmlStringForAsset:self.praxController.selectedAsset];
        [[self.assetDetailWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }

    
    
    
}




@end
