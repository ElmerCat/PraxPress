//
//  AccountViewController.m
//  PraxPress
//
//  Created by John Canfield on 10/10/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "AccountViewController.h"

@interface AccountViewController ()

@end

@implementation AccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)logoutButtonClicked:(id)sender {
    [self.updateController logoutAccount:self.representedObject];
    [self.accountViewPopover performClose:self];
    
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self.synchronizePanel makeKeyAndOrderFront:self];
    [self.updateController refreshAccountData:self.representedObject];
    [self.accountViewPopover performClose:self];

}


@end
