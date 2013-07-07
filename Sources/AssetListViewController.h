//
//  AssetListViewController.h
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"


@interface AssetListViewController : NSViewController
@property BOOL awake;
@property Document *document;
@property BOOL selected;
@property Source *source;
@property (strong) IBOutlet NSArrayController *assetArrayController;

@end
