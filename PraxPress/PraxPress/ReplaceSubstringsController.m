//
//  ReplaceSubstringsController.m
//  PraxPress
//
//  Created by John Canfield on 10/9/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "ReplaceSubstringsController.h"

@interface ReplaceSubstringsController ()

@end

@implementation ReplaceSubstringsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.assetBatchEditController removeObserver:self forKeyPath:@"arrangedObjects"];
    [self removeObserver:self forKeyPath:@"keyValue"];
}


- (void)awakeFromNib {
    [self.assetBatchEditController addObserver:self
                                    forKeyPath:@"arrangedObjects"
                                       options:NSKeyValueObservingOptionNew
                                       context:NULL];
    
    [self addObserver:self
           forKeyPath:@"keyValue"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if([keyPath isEqualToString:@"arrangedObjects"]) {
        
        self.batchCount = [NSString stringWithFormat:@"Change All %lu Items in Batch", [self.assetBatchEditController.arrangedObjects count]];
    }
    
    
    // deal with other observations and/or invoke super...
    
}

- (IBAction)show:(id)sender
{
    
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}



- (IBAction)change:(id)sender {

    for (Asset *asset in [self.assetBatchEditController arrangedObjects]) {
        
        [asset setValue:[[asset valueForKey:self.keyValue] stringByReplacingOccurrencesOfString:[self.replaceField stringValue] withString:[self.withField stringValue]] forKey:self.keyValue ];
        asset.sync_mode = [NSNumber numberWithBool:TRUE];
        
    }
    self.keyValue = nil;
    [self.changedAssetsController rearrangeObjects];
    [self.popover performClose:sender];
    
}


- (IBAction)cancel:(id)sender {
    [self.popover performClose:sender];
}

@end
