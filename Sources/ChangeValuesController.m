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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NSPopoverWillShowNotification" object:self.popover queue:nil usingBlock:^(NSNotification *aNotification){
        [self resetChangeOptions];
        [self.changeOptionsController setSelectionIndex:0];
        self.didShowPopover = NO;
        
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NSPopoverDidShowNotification" object:self.popover queue:nil usingBlock:^(NSNotification *aNotification){  // gets called twice every time popover does show
        if (!self.didShowPopover) self.didShowPopover = YES;
        else [self.changeOptionsPopUpButton performClick:self];
    }];

    
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
    [request setPredicate:[NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", substring]];
    
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
    
    NSString *key = [self.changeOptionsController.selection valueForKey:@"key"];

    NSMutableSet *tagsToRemove;
    NSMutableSet *tagsToAdd;
    if ([key isEqualToString:@"tags"]) {
        Tag *tag;
        if (self.removeTags) {
            tagsToRemove = [[NSMutableSet alloc] init];
            for (NSString *string in self.removeTagsArray) {
                NSLog(@"%@", string);
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", string]];
                NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:nil];
                if ([matchingItems count] < 1) {
                    tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
                    tag.name = string;
                }
                else tag = matchingItems[0];
                [tagsToRemove addObject:tag];
            }
        }
        if (self.addTags) {
            tagsToAdd = [[NSMutableSet alloc] init];
            for (NSString *string in self.addTagsArray) {
                NSLog(@"%@", string);
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"name", string]];
                NSArray *matchingItems = [self.document.managedObjectContext executeFetchRequest:request error:nil];
                if ([matchingItems count] < 1) {
                    tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:self.document.managedObjectContext];
                    tag.name = string;
                }
                else tag = matchingItems[0];
                [tagsToAdd addObject:tag];
            }
        }
    }
    
    for (Asset *asset in [self.document.batchAssetsController arrangedObjects]) {
        
        if (self.changeTo) {
            [asset setValue:self.changeToString forKey:key];
        }
        else if (((self.prefixWith)||(self.appendWith))||(self.findReplace)) {
            NSMutableString *value = ([asset valueForKey:key]) ? [NSMutableString stringWithString:[asset valueForKey:key]] : [NSMutableString stringWithString:@""];
            
            if (self.findReplace) {
                
                [value setString:[value stringByReplacingOccurrencesOfString:self.findString withString:self.replaceString]];
                
            }
            if (self.prefixWith) {
                [value insertString:self.prefixWithString atIndex:0];
                
            }
            if (self.appendWith) {
                [value appendString:self.appendWithString];
            }
            
            [asset setValue:value forKey:key];
            
        }
        else if ([key isEqualToString:@"sharing"]) {
            [asset setValue:[self.sharingTypesController.selection valueForKey:@"value"] forKey:key];
            
        }
        else if ([key isEqualToString:@"sub_type"]) {
            if ((self.changeTrackSubType) && (asset.isTrack)) {
                [asset setValue:[self.trackSubTypesController.selection valueForKey:@"value"] forKey:key];
            }
            else if ((self.changePlaylistSubType) && (asset.isPlaylist)) {
                [asset setValue:[self.playlistSubTypesController.selection valueForKey:@"value"] forKey:key];
            }
       }
        else if ([key isEqualToString:@"tags"]) {
            NSMutableSet *tags = [asset mutableSetValueForKey:key];
            if (self.removeTags) [tags minusSet:tagsToRemove];
            else if (self.removeAllTags) [tags removeAllObjects];
            if (self.addTags) [tags unionSet:tagsToAdd];
            asset.tags = [tags copy];
        }
        else {
            
        }
        
        
        
        
        
        
        
   //     [asset setValue:[self.valueField stringValue] forKey:self.keyValue];
   //     asset.sync_mode = [NSNumber numberWithBool:TRUE];
        
    }
  //  self.keyValue = nil;
  //  [self.document.changedAssetsController rearrangeObjects];
    [self.popover performClose:sender];
    
}


- (IBAction)tagSelected:(id)sender {
    
    
    
}

- (void)resetChangeOptions {
    self.prefixWith = NO;
    self.prefixWithString = @"";
    self.appendWith = NO;
    self.appendWithString = @"";
    self.changeTo = NO;
    self.changeToString = @"";
    self.findReplace = NO;
    self.findString = @"";
    self.replaceString = @"";
    self.removeTags = NO;
    self.removeTagsArray = nil;
    self.removeAllTags = NO;
    self.addTags = NO;
    self.addTagsArray = nil;
    self.changeTrackSubType = NO;
    self.changePlaylistSubType = NO;
    [self.trackSubTypesController setSelectionIndex:0];
    [self.playlistSubTypesController setSelectionIndex:0];
    [self.sharingTypesController setSelectionIndex:0];
}

- (IBAction)changeOptionSelected:(id)sender {
    
    [self resetChangeOptions];
    
}

- (IBAction)cancel:(id)sender {
    [self.popover performClose:sender];
}
@end
