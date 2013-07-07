//
//  AssetListViewController.m
//  PraxPress
//
//  Created by Elmer on 6/23/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetListViewController.h"

@interface AssetListViewController ()

@end

@implementation AssetListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"AssetListViewController initWithNibName: %@", nibNameOrNil);

        [self addObserver:self forKeyPath:@"self.source" options:NSKeyValueObservingOptionNew context:0];

        // Initialization code here.
    }
    
    return self;
}



- (void)dealloc {
    NSLog(@"AssetListViewController dealloc");
    [self removeObserver:self forKeyPath:@"self.source"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"self.source"]) {
        if (!self.source) return;
        
        [self.assetArrayController setFetchPredicate:self.source.fetchPredicate];
        NSString *entityName = self.source.fetchEntity;
        if (!entityName.length) entityName = @"Asset";
        
        [self.assetArrayController setEntityName:entityName];
        [self.assetArrayController fetch:self];
        
        
    }
}



- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"AssetListViewController init");
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"AssetListViewController awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        
    }
}

@end
