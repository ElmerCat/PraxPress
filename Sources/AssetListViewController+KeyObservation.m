//
//  AssetListViewController+KeyObservation.m
//  PraxPress
//
//  Created by Elmer on 12/25/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetListViewController+KeyObservation.h"

@implementation AssetListViewController (KeyObservation)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    
    
    if ([keyPath isEqualToString:@"self.changedAssetArrayController.arrangedObjects"]) {
        if ([(NSArray *)self.changedAssetArrayController.arrangedObjects count]) {
            [self.splitViewTopConstraint.animator setConstant:60];
        }
        else {
            [self.splitViewTopConstraint.animator setConstant:36];
        }
        
    }
    
    else if ([keyPath isEqualToString:@"self.source.interface"]) {
        if (self.source.interface) self.isSelectedPane = YES;
        else self.isSelectedPane = NO;
    }
    
    else if ([keyPath isEqualToString:@"self.isSelectedPane"]) {
        //        CGFloat selectedPaneAlpha = 0;
        //        CGFloat notSelectedPaneAlpha = 1;
        if (self.isSelectedPane) {
            //            selectedPaneAlpha = 1;
            //            notSelectedPaneAlpha = 0;
        }
    }
    
    else if ([keyPath isEqualToString:@"self.showDetailView"]) {
        CGFloat newPosition = [self.splitView maxPossiblePositionOfDividerAtIndex:0];
        if (self.showDetailView) newPosition -= 300;
        //  [[self.splitView animator] setPosition:newPosition ofDividerAtIndex:0];
        //  [self.splitView setPosition:newPosition ofDividerAtIndex:0 animated:YES];
        [self.splitView setPosition:newPosition ofDividerAtIndex:0];
    }
    
    else if ([keyPath isEqualToString:@"self.showSafariView"]) {
        if (self.showSafariView) {
            [self writeFormattedCode];
        }
    }
    
    else if ([keyPath isEqualToString:@"self.exportCode"]) {
        if (self.exportCode) {
            [self updateFormattedCode:self];
        }
        else self.showSafariView = NO;
    }
    
    else if ([keyPath isEqualToString:@"self.formattedCode"]) {
        if (self.exportCode) {
            [self writeFormattedCode];
        }
    }
    
    else if ([keyPath isEqualToString:@"self.assetArrayController.sortDescriptors"]) {
        if (self.isPlaylist) {
            if ([self.assetArrayController.sortDescriptors count] > 0) {
                Asset *playlist = self.associatedController.assetArrayController.selectedObjects[0];
                playlist.associatedItems = [[NSOrderedSet alloc] initWithArray:self.assetArrayController.arrangedObjects];
            }
        }
        
        else if ([self.source.type isEqualToString:@"BatchSource"]) {
            if ([self.assetArrayController.sortDescriptors count] > 0) {
                self.source.batchAssets = [[NSOrderedSet alloc] initWithArray:self.assetArrayController.arrangedObjects];
            }
        }
    }
    else if ([keyPath isEqualToString:@"self.associatedController.assetArrayController.selectionIndexes"]) {
        if (self.isAssociatedPane) {
            [self loadAssociatedItems];
            
        }
        
    }
    else if ([keyPath isEqualToString:@"self.assetArrayController.selectionIndexes"]) {
        
        NSString *listType = [self.assetArrayController.selectedObjects praxPressListType];
        NSView *detailView;
        
        if ([listType isEqualToString:@"no-selection"]) {
            detailView = self.noSelectionView;
        }
        else {
            detailView = self.assetDetailView;
        }
        if (self.detailViewBox.contentView != detailView) {
            [self.detailViewBox setContentView:detailView];
        }
        
        self.duration = self.playback_count = self.favoritings_count = self.download_count = self.comment_count = 0;
        
        if ((self.source) && ([self.assetArrayController.selectedObjects count] > 0)) {
            for (Asset *asset in self.assetArrayController.selectedObjects) {
                self.duration += asset.duration.intValue;
                self.playback_count += asset.playback_count.intValue;
                self.favoritings_count += asset.favoritings_count.intValue;
                self.download_count += asset.download_count.intValue;
                self.comment_count += asset.comment_count.intValue;
            }
        }
        
        [self updateFormattedCode:self];
        
    }
    else if ([@[@"self.source.excludedTags", @"self.source.requiredTags", @"self.source.requireAllTags"] containsObject:keyPath]) {
        [self tagFilterAssets];
    }
    else if ([@[@"self.source", @"self.source.batchAssets", @"self.source.fetchPredicate"] containsObject:keyPath]) {
        [self reloadAssets];
        if ([keyPath isEqualToString:@"self.source"]) {
            self.exportCodeURL = nil;
            self.appleScript = nil;
        }
    }
    else if ([@[@"self.source.template", @"self.source.template.formatText"] containsObject:keyPath]) {
        [self updateFormattedCode:self];
    }
    
}

- (void) reloadAssets {
    if (!self.source) return;
    
    
    @synchronized(self) {
        if (self.reloadingAssets) return;
        else self.reloadingAssets = YES;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.isAssociatedPane) {
            [self loadAssociatedItems];
        }
        else {
            if ([self.source.type isEqualToString:@"BatchSource"]) {
                self.isBatch = YES;
                
                self.assets = [NSOrderedSet orderedSetWithOrderedSet:self.source.batchAssets];
                [self.assetsTableView setSortDescriptors:nil];
                
            }
            else {
                self.isBatch = NO;
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
                NSError *error;
                [request setPredicate:self.source.fetchPredicate];
                NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:&error];
                self.assets = [NSOrderedSet orderedSetWithArray:matchingItems];
            }
            self.source.itemCount = [NSNumber numberWithInteger:self.assets.count];
            
            [self tagFilterAssets];
            
            //  [self.assetArrayController setContent:[self.assets array]];
            
            if ((self.source.filterString != nil) && (![self.source.filterString isEqualToString:@""])) {
                NSPredicate *predicate;
                if ((self.source.filterKey != nil) && (![self.source.filterKey isEqualToString:@""])) {
                    predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", self.source.filterKey, self.source.filterString];
                }
                else {
                    predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", self.source.filterString];
                }
                [self.assetArrayController setFilterPredicate:predicate];
            }
            else [self.assetArrayController setFilterPredicate:nil];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self updateFormattedCode:self];
            });
        }
        
        self.reloadingAssets = NO;
    });

}

@end
