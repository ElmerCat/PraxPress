//
//  UserAccountController.m
//  PraxPress
//
//  Created by John Canfield on 8/9/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "UserAccountController.h"

@implementation UserAccountController

@synthesize updateController;
@synthesize document;

- (id)init
{
    self = [super init];
    if (self) {
        NSLog(@"UserAccountController init");
        [[NSSound soundNamed:@"Connect"] play];
        
//        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
//        [notificationCenter addObserver:self
//                               selector:@selector(tracksNotification:)
//                                   name:tracksNotificationName object:nil];
//
        
        //     [notificationCenter addObserver:self
        //                          selector:@selector(undoNotification:)
        //                            name:NSUndoManagerCheckpointNotification
        //                        object:[[document managedObjectContext] undoManager]];
        
    }
    
    return self;
}



- (void)awakeFromNib {
    
    NSLog(@"UserAccountController awakeFromNib");
    
    
   
}


-(NSManagedObject *)account {
    if (! _userAccount) {
        
        NSManagedObjectContext *moc = [document managedObjectContext];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
        [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", @"com.soundcloud.api"]];
        
        NSError *error = nil;
        NSArray *matchingItems = [moc executeFetchRequest:request error:&error];
        
        if ([matchingItems count] < 1) {
            _userAccount = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
            [self.account setValue:@"com.soundcloud.api" forKey:@"accountType"];
            
        }
        else {
            _userAccount = matchingItems[0];
        }
        
        
    }
    
    return _userAccount;
        
    
}


- (IBAction)refresh:(id)sender {
    
    if ([self.updateController startUpdateMode:UpdateModeUser]) {
        
        
    }
}



@end
