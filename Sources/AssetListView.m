//
//  AssetListView.m
//  PraxPress
//
//  Created by Elmer on 6/24/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetListView.h"

@implementation AssetListView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"AssetListView initWithFrame");
        
//        [self addObserver:self forKeyPath:@"self.source" options:NSKeyValueObservingOptionNew context:0];
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"AssetListView dealloc");
//     [self removeObserver:self forKeyPath:@"self.source"];
}

/*- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"AssetListView observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"self.source"]) {
        if (!self.source) return;
        
        [self.assetArrayController setFetchPredicate:self.source.fetchPredicate];
        NSString *entityName = self.source.fetchEntity;
        if (!entityName.length) entityName = @"Asset";

        [self.assetArrayController setEntityName:entityName];
        [self.assetArrayController fetch:self];
        
        
    }
}*/



- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
