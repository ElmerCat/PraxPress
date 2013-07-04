//
//  AssetListViewController.h
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AssetListViewController : NSViewController
@property BOOL awake;
@property (nonatomic, retain) NSArray *assets;
@property (strong) IBOutlet NSArrayController *assetListArrayController;

@end
