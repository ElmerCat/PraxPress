//
//  AssetDetailView.m
//  PraxPress
//
//  Created by John Canfield on 8/26/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AssetDetailView.h"

@implementation AssetDetailView
@synthesize assetDetailPanel;



- (void)awakeFromNib {
    NSLog(@"AssetDetailView awakeFromNib");
    [self addObserver:self
           forKeyPath:@"self.representedObject"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
}


- (void)dealloc {
    
    [self removeObserver:self forKeyPath:@"representedObject"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog(@"SOAsset observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    
    if ([keyPath isEqualToString:@"self.representedObject"]) {
        NSString *html = [Asset htmlStringForAsset:change[@"new"]];
        [[self.assetDetailWebView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
}

-(void)clearWebView {
    [[self.assetDetailWebView mainFrame] loadHTMLString:@"<html><body>Prax</body></html>" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

- (IBAction)edit:(id)sender {
    [self.assetDetailPanel makeKeyAndOrderFront:sender];
}

@end
