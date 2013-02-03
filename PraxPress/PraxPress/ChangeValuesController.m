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
    [self.document.batchAssetsController removeObserver:self forKeyPath:@"arrangedObjects"];
    [self.document.assetsController removeObserver:self forKeyPath:@"selectedObjects"];
    [self removeObserver:self forKeyPath:@"keyValue"];
}

- (void)awakeFromNib {
    if (!self.changeOptions) {
        self.changeOptions = @[@{@"key":@"none", @"name":@"Choose the Value to change..."},
                               @{@"key":@"title", @"name":@"Title", @"prefixWith":@YES, @"appendWith":@YES, @"findReplace":@YES},
                               @{@"key":@"permalink", @"name":@"Permalink / Slug", @"prefixWith":@YES, @"appendWith":@YES, @"findReplace":@YES},
                               @{@"key":@"purchase_title", @"name":@"Buy Link Title (SoundCloud items only)", @"changeTo":@YES, @"prefixWith":@YES, @"appendWith":@YES, @"findReplace":@YES},
                               @{@"key":@"purchase_url", @"name":@"Buy Link URL (SoundCloud items only)", @"changeTo":@YES, @"prefixWith":@YES, @"appendWith":@YES, @"findReplace":@YES},
                               @{@"key":@"contents", @"name":@"Description / Contents", @"changeTo":@YES, @"prefixWith":@YES, @"appendWith":@YES, @"findReplace":@YES},
                               @{@"key":@"sub_type", @"name":@"Track Type / Playlist Type", @"changeSubType":@YES},
                               @{@"key":@"sharing", @"name":@"Sharing", @"changeSharing":@YES},
                               @{@"key":@"genre", @"name":@"Genre", @"changeTo":@YES, @"prefixWith":@YES, @"appendWith":@YES, @"findReplace":@YES},
                               @{@"key":@"tags", @"name":@"Tags", @"changeTags":@YES}];
        
    }
    
    [self.document.batchAssetsController addObserver:self
                                    forKeyPath:@"arrangedObjects"
                                       options:NSKeyValueObservingOptionNew
                                       context:NULL];
    
    [self.document.assetsController addObserver:self
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
        
        self.batchCount = [NSString stringWithFormat:@"Change All %lu Items in Batch", [self.document.batchAssetsController.arrangedObjects count]];
    }
    
    else if(([keyPath isEqualToString:@"selectedObjects"])||([keyPath isEqualToString:@"keyValue"])) {
        
        if ([[self.document.assetsController selectedObjects] count] > 0) {
            
            self.selectedAsset = [self.document.assetsController selectedObjects][0];
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


- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH[c] %@", substring]];
    
    NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:nil];
    if ([matchingItems count] > 0) {
        NSMutableArray *completions = [NSMutableArray arrayWithCapacity:10];
        for (Tag *tag in matchingItems) {
            [completions addObject:tag.name];
        }
        return completions;
    }
    else return nil;
}


- (IBAction)show:(id)sender
{
    
    [self.popover showRelativeToRect:[self.document.batchAssetsTableView bounds] ofView:self.document.batchAssetsTableView preferredEdge:NSMinXEdge];
}


- (IBAction)copy:(id)sender {
    [self.valueField setStringValue:[sender title]];
}


- (IBAction)change:(id)sender {
    for (Asset *asset in [self.document.batchAssetsController arrangedObjects]) {
        [asset setValue:[self.valueField stringValue] forKey:self.keyValue];
        asset.sync_mode = [NSNumber numberWithBool:TRUE];
        
    }
    self.keyValue = nil;
    [self.document.changedAssetsController rearrangeObjects];
    [self.popover performClose:sender];
    
}


- (IBAction)tagSelected:(id)sender {
    
    
    
}

- (void)resetChangeOptions {
    
    self.prefixWith = NO;
    self.appendWith = NO;
    self.changeTo = NO;
    self.findReplace = NO;
    self.removeTags = NO;
    self.removeAllTags = NO;
    self.addTags = NO;
    self.changeTrackSubType = NO;
    self.changePlaylistSubType = NO;
    
    
}

- (IBAction)changeOptionSelected:(id)sender {
    
    [self resetChangeOptions];
    
}

- (IBAction)cancel:(id)sender {
    [self.popover performClose:sender];
}
@end
