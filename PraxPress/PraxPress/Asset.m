//
//  Asset.m
//  PraxPress
//
//  Created by John Canfield on 8/15/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Asset.h"

@implementation Asset

- (id)init {
    self = [super init];
    if (self) {
               NSLog(@"Asset init");
        //       [[NSSound soundNamed:@"Start"] play];
        
        //        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        //       [notificationCenter addObserver:self
        //                              selector:@selector(tracksNotification:)
        //                                  name:tracksNotificationName object:nil];
        //     [notificationCenter addObserver:self
        //                          selector:@selector(undoNotification:)
        //                            name:NSUndoManagerCheckpointNotification
        //                        object:[[document managedObjectContext] undoManager]];
    }
    return self;
}


- (void)awakeFromNib {
    NSLog(@"Asset awakeFromNib");
    
}


@end
