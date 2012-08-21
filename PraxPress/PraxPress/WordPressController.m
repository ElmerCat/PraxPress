//
//  WordPressController.m
//  PraxPress
//
//  Created by John Canfield on 8/20/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "WordPressController.h"

@implementation WordPressController

-(Asset *)account {
    if (! _userAccount) {
        NSManagedObjectContext *moc = [self.document managedObjectContext];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"com.wordpress.api"]];
        NSError *error = nil;
        NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
        if ([matchingItems count] < 1) {
            [moc processPendingChanges];
            [[moc undoManager] disableUndoRegistration];
            _userAccount = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
            [_userAccount setValue:@"com.wordpress.api" forKey:@"accountType"];
            [moc processPendingChanges];
            [[moc undoManager] enableUndoRegistration];
        }
        else _userAccount = matchingItems[0];
    }
    return _userAccount;
}


- (IBAction)refresh:(id)sender {
    self.updateController.updateMode = UpdateModeWordPress;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateNotification" object:nil];
    });
}

- (IBAction)logout:(id)sender {
    [[NSSound soundNamed:@"Connect"] play];
    [self.document removeAccessForAccountType:@"com.wordpress.api"];
    
}



@end
