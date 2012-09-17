//
//  AssetDetailView.h
//  PraxPress
//
//  Created by John Canfield on 8/26/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <Cocoa/Cocoa.h>
#import "Asset.h"
@class Asset;


@interface AssetDetailView : NSViewController
@property (weak) IBOutlet WebView *assetDetailWebView;
@property (unsafe_unretained) IBOutlet NSPanel *assetDetailPanel;

-(void)clearWebView;
- (IBAction)edit:(id)sender;

@end
