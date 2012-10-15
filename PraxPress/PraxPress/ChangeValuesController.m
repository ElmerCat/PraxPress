//
//  ChangeValuesController.m
//  PraxPress
//
//  Created by John Canfield on 10/8/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "ChangeValuesController.h"

@implementation ChangeValuesController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.assetBatchEditController removeObserver:self forKeyPath:@"arrangedObjects"];
    [self.assetsController removeObserver:self forKeyPath:@"selectedObjects"];
    [self removeObserver:self forKeyPath:@"keyValue"];
}

- (void)awakeFromNib {
    [self.assetBatchEditController addObserver:self
                                    forKeyPath:@"arrangedObjects"
                                       options:NSKeyValueObservingOptionNew
                                       context:NULL];
    
    [self.assetsController addObserver:self
                            forKeyPath:@"selectedObjects"
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
    
    else if(([keyPath isEqualToString:@"selectedObjects"])||([keyPath isEqualToString:@"keyValue"])) {
        
        if ([[self.assetsController selectedObjects] count] > 0) {
            
            self.selectedAsset = [self.assetsController selectedObjects][0];
            if (!self.selectedAsset)
                self.valueCopyText = @"Prax";
            else if (!self.keyValue)
                self.valueCopyText = @"Prax";
            
            else self.valueCopyText = [self.selectedAsset valueForKey:self.keyValue];
       
            
        }
        else self.valueCopyText = @"Prax";
        
        
        
    }
    
    // deal with other observations and/or invoke super...
    
}

- (IBAction)show:(id)sender
{
    
    [self.popover showRelativeToRect:[self.batchChangeTableView bounds] ofView:self.batchChangeTableView preferredEdge:NSMinYEdge];
}


- (IBAction)copy:(id)sender {
    [self.valueField setStringValue:[sender title]];
}


- (IBAction)change:(id)sender {
    for (Asset *asset in [self.assetBatchEditController arrangedObjects]) {
        [asset setValue:[self.valueField stringValue] forKey:self.keyValue];
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
