//
//  UserAccountController.h
//  PraxPress
//
//  Created by John Canfield on 8/9/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"
#import "UpdateController.h"
@class Document;
@class SoundCloudController;
@class UpdateController;

@interface UserAccountController : NSObject

@property (strong) IBOutlet SoundCloudController *soundCloudController;
@property (weak) IBOutlet UpdateController *updateController;
@property (weak) IBOutlet Document *document;
@property (strong) NSManagedObject *userAccount;
@property (readonly) NSManagedObject *account;
- (IBAction)refresh:(id)sender;
@end
