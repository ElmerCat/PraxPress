//
//  Document+DocumentUserInterface.h
//  PraxPress
//
//  Created by Elmer on 7/16/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document.h"

@interface Document (DocumentUserInterface)
- (NSString *)toolTipStats;
- (NSString *)toolTipPermalink;
- (NSString *)toolTipReload;
- (NSString *)toolTipUpload;

- (IBAction)displayAccountsPreferences:(id)sender;
- (IBAction)praxButtonPressed:(id)sender;

@end
