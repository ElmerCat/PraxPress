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

- (NSArray *)keyPathsToObserve {return @[@"self.assetArrayController.selectionIndexes", @"self.isSelectedPane", @"self.source"];}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"AssetListViewController initWithNibName: %@", nibNameOrNil);

        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.detailScrollView queue:nil usingBlock:^(NSNotification *aNotification){
            NSRect documentRect = [self.detailScrollView.documentView bounds];
            NSRect scrollViewRect = self.detailScrollView.frame;
            if (scrollViewRect.size.width >= 500) {
                documentRect.size.width = (scrollViewRect.size.width - 2);
                [self.detailScrollView.documentView setFrame:documentRect];
            }
         }];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"AssetListViewController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"self.isSelectedPane"]) {
        CGFloat selectedPaneAlpha = 0;
        CGFloat notSelectedPaneAlpha = 1;
        if (self.isSelectedPane) {
            selectedPaneAlpha = 1;
            notSelectedPaneAlpha = 0;
        }
        [self.selectedButton.animator setAlphaValue:selectedPaneAlpha];
        [self.notSelectedButton.animator setAlphaValue:notSelectedPaneAlpha];
        
    }
    else if ([keyPath isEqualToString:@"self.source"]) {
        if (!self.source) return;
        [self.assetArrayController setFetchPredicate:self.source.fetchPredicate];
        NSString *entityName = self.source.fetchEntity;
        if (!entityName.length) entityName = @"Asset";
        [self.assetArrayController setEntityName:entityName];
        [self.assetArrayController fetch:self];
    }
    else if ([keyPath isEqualToString:@"self.assetArrayController.selectionIndexes"]) {
        
        if (self.assetArrayController.selectedObjects.count > 0) {
            Asset *asset = self.assetArrayController.selectedObjects[0];
            if ([asset.type isEqualToString:@"track"]) {
                [self.detailScrollView setDocumentView:self.trackDetailView];
                
            }
            else [self.detailScrollView setDocumentView:self.defaultDetailView];
     //       [self.trackDetailView setAutoresizingMask:NSViewWidthSizable];
      /*      NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.detailScrollView.documentView attribute:NSLayoutAttributeRight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeRight
                                                                         multiplier:1.0f constant:-20.0f];
            [self.detailScrollView.contentView addConstraint:constraint]; */
            
            NSPoint newScrollOrigin;
            // assume that the scrollview is an existing variable
            if ([[self.detailScrollView documentView] isFlipped]) {
                newScrollOrigin=NSMakePoint(0.0,0.0);
            } else {
                newScrollOrigin=NSMakePoint(0.0,NSMaxY([[self.detailScrollView documentView] frame])
                                            -NSHeight([[self.detailScrollView contentView] bounds]));
            }
            CGPoint setOrigin = CGPointMake(newScrollOrigin.x , newScrollOrigin.y + 172.0f);
            [[self.detailScrollView documentView] scrollPoint:setOrigin];

        }
        
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

- (IBAction)selectAssetListPane:(id)sender {
    [self.document.sourceController selectAssetListPane:self];
    
}

- (void)filterPane {
    [self.searchField selectText:self];
    
    
    
}

- (IBAction)updateFilter:sender {
    NSString *searchString = [self.searchField stringValue];
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", searchString];
        [self.assetArrayController setFilterPredicate:predicate];
    }
    else [self.assetArrayController setFilterPredicate:nil];
}


@end
