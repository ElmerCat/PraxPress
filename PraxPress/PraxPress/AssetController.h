//
//  AssetController.h
//  PraxPress
//
//  Created by John Canfield on 9/17/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "Asset.h"

@interface AssetController : NSObject

@property (weak) IBOutlet NSArrayController *assetsController;
@property (weak) IBOutlet WebView *assetDetailWebView;
@property (weak) IBOutlet NSView *assetDetailView;


@end