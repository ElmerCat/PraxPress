//
//  AccountController.m
//  PraxPress
//
//  Created by Elmer on 12/26/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AccountController.h"

@implementation AccountController

+ (void)initForDocument:(Document *)document {
    NSLog(@"AccountController initForDocument: %@", document);

    NSArray *services = @[@{@"name":@"SoundCloud", @"enabled":@YES},
                          @{@"name":@"WordPress", @"enabled":@YES},
                          @{@"name":@"Flickr", @"enabled":@NO},
                          @{@"name":@"YouTube", @"enabled":@NO}];
    Account *account;
    for (NSDictionary *service in services) {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:document.managedObjectContext];
        account.name = service[@"name"];
        account.enabled = service[@"enabled"];
    }
}

- (IBAction)showAccounts:(id)sender {
    if (self.accountsPanel.isVisible) [self.accountsPanel orderOut:sender];
    else [self.accountsPanel makeKeyAndOrderFront:sender];
}

- (void)activateAccount:(Account *)account {
    
    account.active = @YES;
    Source *child = [NSManagedObject entity:@"Source" withKey:@"name" matchingStringValue:account.name inManagedObjectContext:self.document.managedObjectContext];
    if (child) return;
    
    Source *parent = [NSManagedObject entity:@"Source" withKey:@"name" matchingStringValue:@"LIBRARY" inManagedObjectContext:self.document.managedObjectContext];
    if (parent) {
        child = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
        child.type = @"AssetSource";
        child.parent = parent;
        child.account = account;
        child.name = account.name;
        child.fetchPredicate = [NSPredicate predicateWithFormat:@"accountType == %@", account.name];
        child.rowHeight = @30;
        if ([account.name isEqualToString:@"WordPress"]) {
            Source *grandChild = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
            grandChild.type = @"AssetSource";
            grandChild.name = @"Posts";
            grandChild.parent = child;
            grandChild.account = account;
            grandChild.fetchPredicate = [NSPredicate predicateWithFormat:@"type == \"post\""];
            grandChild.rowHeight = @20;
            
            grandChild = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
            grandChild.type = @"AssetSource";
            grandChild.name = @"Pages";
            grandChild.parent = child;
            grandChild.account = account;
            grandChild.fetchPredicate = [NSPredicate predicateWithFormat:@"type == \"page\""];
            grandChild.rowHeight = @20;
            
            grandChild = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
            grandChild.type = @"AssetSource";
            grandChild.name = @"Images";
            grandChild.parent = child;
            grandChild.account = account;
            grandChild.fetchPredicate = [NSPredicate predicateWithFormat:@"accountType == %@ AND type == \"image\"", account.name];
            grandChild.rowHeight = @20;
        }
        else if ([account.name isEqualToString:@"SoundCloud"]) {
            Source *grandChild = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
            grandChild.type = @"AssetSource";
            grandChild.name = @"Tracks";
            grandChild.parent = child;
            grandChild.account = account;
            grandChild.fetchPredicate = [NSPredicate predicateWithFormat:@"type == \"track\""];
            grandChild.rowHeight = @20;
            
            grandChild = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
            grandChild.type = @"AssetSource";
            grandChild.name = @"Playlists";
            grandChild.parent = child;
            grandChild.account = account;
            grandChild.fetchPredicate = [NSPredicate predicateWithFormat:@"type == \"playlist\""];
            grandChild.rowHeight = @20;
            
            grandChild = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:self.document.managedObjectContext];
            grandChild.type = @"AssetSource";
            grandChild.name = @"Images";
            grandChild.parent = child;
            grandChild.account = account;
            grandChild.fetchPredicate = [NSPredicate predicateWithFormat:@"accountType == %@ AND type == \"image\"", account.name];
            grandChild.rowHeight = @20;
        }
        else if ([account.name isEqualToString:@"YouTube"]) {
        }
        else if ([account.name isEqualToString:@"Flickr"]) {
        }
    }
    [self.document.sourceController.sourceTreeController rearrangeObjects];
}


- (IBAction)nextButtonPressed:(id)sender {
    if (self.document.requestController.busy) {
        [[NSSound soundNamed:@"Error"] play];
        return;
    }
    
    //    [self.accountsPanel orderOut:sender];
    if (self.accountArrayController.selectedObjects.count) {
        Account *account = self.accountArrayController.selectedObjects[0];
        
        if (account.active.boolValue) {
            NSInteger result = [Prax confirmAlert:[NSString stringWithFormat:@"Deactivate %@ Account", account.name] withText:[NSString stringWithFormat:@"Are you sure you wish to deactivate your %@ account on %@ for this PraxPress document?", account.username, account.name] andInformativeText:[NSString stringWithFormat:@"After deactivating your account, all of the items' information will still be in the PraxPress document, but you'll be unable to upload any changes to %@", account.name] forController:self];
            if (result == NSAlertSecondButtonReturn) {
                NSArray *nXOAuth2Accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:account.name];
                for (NXOAuth2Account *nXOAuth2Account in nXOAuth2Accounts) {
                    [[NXOAuth2AccountStore sharedStore] removeAccount:nXOAuth2Account];
                }
                account.oauthAccount = nil;
                account.active = @NO;
                [[NSSound soundNamed:@"Connect"] play];
            }
            
            return;
            
        }
        else {
            [self activateAccount:account];
        }
        
    }
}

- (IBAction)downloadNew:(id)sender {
    [self downloadAccountReplace:NO];
}

- (IBAction)synchronizeDown:(id)sender {
    [self downloadAccountReplace:YES];
}

- (void)downloadAccountReplace:(BOOL)replace {
    if (self.document.requestController.busy) {
        [[NSSound soundNamed:@"Error"] play];
        return;
    }
    [self.accountsPanel orderOut:self];
    Account *account = self.accountArrayController.selectedObjects[0];
    if (!account.active.boolValue) [self activateAccount:account];
    [self.document.requestController reloadAccount:account option:PRAXReloadOptionAccount replace:replace];
}

- (IBAction)synchronizeUp:(id)sender {
    if (self.document.requestController.busy) {
        [[NSSound soundNamed:@"Error"] play];
        return;
    }
    [[NSSound soundNamed:@"Error"] play];
    
}

@end
