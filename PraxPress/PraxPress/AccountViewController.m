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


- (void)awakeFromNib {
    
    if (!self.awake) {
        self.awake = TRUE;
        
        NSLog(@"AccountViewController awakeFromNib");
        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"NSPopoverWillShowNotification" object:self.popover queue:nil usingBlock:^(NSNotification *aNotification){
            NSLog(@"AccountViewController NSPopoverWillShowNotification");
            [self.tabView selectTabViewItemAtIndex:self.selectionIndex];
            
        }];
    }
}

- (IBAction)showMetadataPopover:(id)sender {
    
    [self.document.assetMetadataPopover showPopoverRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge withDictionary:[(Asset *)self.representedObject metadata]];
    
}



@end
