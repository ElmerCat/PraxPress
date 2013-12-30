//
//  AccountController.h
//  PraxPress
//
//  Created by Elmer on 12/26/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"

@interface AccountController : NSObject

@property (weak) IBOutlet Document *document;
@property (unsafe_unretained) IBOutlet NSPanel *accountsPanel;
@property (weak) IBOutlet NSArrayController *accountArrayController;


+ (void)initForDocument:(Document *)document;

- (IBAction)showAccounts:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)downloadNew:(id)sender;
- (IBAction)synchronizeDown:(id)sender;
- (IBAction)synchronizeUp:(id)sender;

@end
