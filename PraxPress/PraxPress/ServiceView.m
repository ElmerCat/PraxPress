//
//  ServiceView.m
//  PraxPress
//
//  Created by John Canfield on 10/10/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "ServiceView.h"

@implementation ServiceView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

        NSLog(@"ServiceView initWithFrame");
}
    
    return self;
}


- (void)awakeFromNib {
    
    NSLog(@"awakeFromNib ServiceView");
    
    [self addObserver:self forKeyPath:@"self.objectValue.account.accountType" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.objectValue.account.track_count" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"self.objectValue.account.playlist_count" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
                                                      object:self.searchField
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                       [self updateFilter:self];
                                                   }];
    
}
-(void)dealloc {
    NSLog(@"dealloc ServiceView");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"self.objectValue.account.accountType"];
    [self removeObserver:self forKeyPath:@"self.objectValue.account.track_count"];
    [self removeObserver:self forKeyPath:@"self.objectValue.account.playlist_count"];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
        NSLog(@"ServiceView observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    
    if (([keyPath isEqualToString:@"self.objectValue.account.accountType"] ||
        [keyPath isEqualToString:@"self.objectValue.account.track_count"]) ||
        [keyPath isEqualToString:@"self.objectValue.account.playlist_count"]) {
        
        NSString *accountType = self.account.accountType;
        
        if ([accountType isEqualToString:@"SoundCloud"]){
            
            if ([keyPath isEqualToString:@"self.objectValue.account.accountType"]) {
                
                
                NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
                NSMenuItem *item;
                self.searchCategory = 1;
                [[self.searchField cell] setPlaceholderString:@"Title..."];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:1];
                [cellMenu insertItem:item atIndex:0];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Permalink..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:2];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:3];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:4];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Artwork URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:5];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Contents..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:6];
                [cellMenu insertItem:item atIndex:1];
                
                id searchCell = [self.searchField cell];
                [searchCell setSearchMenuTemplate:cellMenu];
                
            }
            
            
            self.checkOneTitle = [NSString stringWithFormat:@"%@ Tracks", self.account.track_count];
            self.checkTwoTitle = [NSString stringWithFormat:@"%@ Playlists", self.account.playlist_count];
        }
        else if ([accountType isEqualToString:@"WordPress"]){
            
            if ([keyPath isEqualToString:@"self.objectValue.account.accountType"]) {
                
                
                NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
                NSMenuItem *item;
                self.searchCategory = 1;
                [[self.searchField cell] setPlaceholderString:@"Title..."];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:1];
                [cellMenu insertItem:item atIndex:0];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Permalink..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:2];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:3];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:4];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Artwork URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:5];
                [cellMenu insertItem:item atIndex:1];

                item = [[NSMenuItem alloc] initWithTitle:@"Contents..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:6];
                [cellMenu insertItem:item atIndex:1];
                
                id searchCell = [self.searchField cell];
                [searchCell setSearchMenuTemplate:cellMenu];
               
            }
            
            
            
            self.checkOneTitle = [NSString stringWithFormat:@"%@ Posts", self.account.track_count];
            self.checkTwoTitle = [NSString stringWithFormat:@"%@ Pages", self.account.playlist_count];
        }
        else if ([accountType isEqualToString:@"Flickr"]){
            
            if ([keyPath isEqualToString:@"self.objectValue.account.accountType"]) {
                
                
                NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
                NSMenuItem *item;
                self.searchCategory = 1;
                [[self.searchField cell] setPlaceholderString:@"Title..."];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:1];
                [cellMenu insertItem:item atIndex:0];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Permalink..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:2];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:3];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:4];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Artwork URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:5];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Contents..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:6];
                [cellMenu insertItem:item atIndex:1];
                
                id searchCell = [self.searchField cell];
                [searchCell setSearchMenuTemplate:cellMenu];
             
            }
            
            
            
            self.checkOneTitle = [NSString stringWithFormat:@"%@ Photos", self.account.track_count];
            self.checkTwoTitle = [NSString stringWithFormat:@"%@ Sets", self.account.playlist_count];
        }
        else if ([accountType isEqualToString:@"YouTube"]){

            if ([keyPath isEqualToString:@"self.objectValue.account.accountType"]) {
                
                NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:@"Search Menu"];
                NSMenuItem *item;
                self.searchCategory = 1;
                [[self.searchField cell] setPlaceholderString:@"Title..."];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:1];
                [cellMenu insertItem:item atIndex:0];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Permalink..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:2];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase Title..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:3];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Purchase URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:4];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Artwork URL..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:5];
                [cellMenu insertItem:item atIndex:1];
                
                item = [[NSMenuItem alloc] initWithTitle:@"Contents..." action:@selector(setSearchCategoryFrom:) keyEquivalent:@""];
                [item setTarget:self];
                [item setTag:6];
                [cellMenu insertItem:item atIndex:1];
                
                id searchCell = [self.searchField cell];
                [searchCell setSearchMenuTemplate:cellMenu];
                
            }
            
            
            self.checkOneTitle = [NSString stringWithFormat:@"%@ Videos", self.account.track_count];
            self.checkTwoTitle = [NSString stringWithFormat:@"%@ Playlists", self.account.playlist_count];
        }
     
        //else self.checkOneTitle = [NSString stringWithFormat:@"%@ Praxs", self.account.track_count];
        
    }

}

- (IBAction)setSearchCategoryFrom:(NSMenuItem *)menuItem {
    
    self.searchCategory = [menuItem tag];
    [[self.searchField cell] setPlaceholderString:[menuItem title]];
    [self updateFilter:self];
}


- (IBAction)updateFilter:sender {
    /*
     Create a predicate based on what is the current string in the
     search field and the value of searchCategory.
     */
    NSString *searchString = [self.searchField stringValue];
    NSPredicate *predicate;
    
    if ((searchString != nil) && (![searchString isEqualToString:@""])) {
        if (self.searchCategory == 1) {
            predicate = [NSPredicate predicateWithFormat:
                         @"title contains[cd] %@", searchString];
        }
        if (self.searchCategory == 2) {
            predicate = [NSPredicate predicateWithFormat:
                         @"permalink contains[cd] %@", searchString];
        }
        if (self.searchCategory == 3) {
            predicate = [NSPredicate predicateWithFormat:
                         @"purchase_title contains[cd] %@", searchString];
        }
        if (self.searchCategory == 4) {
            predicate = [NSPredicate predicateWithFormat:
                         @"purchase_url contains[cd] %@", searchString];
        }
        if (self.searchCategory == 5) {
            predicate = [NSPredicate predicateWithFormat:
                         @"artwork_url contains[cd] %@", searchString];
        }
        if (self.searchCategory == 6) {
            predicate = [NSPredicate predicateWithFormat:
                         @"contents contains[cd] %@", searchString];
        }
    }
    
    [self.objectValue setValue:[predicate predicateFormat] forKey:@"predicateFormat"];
    
    [self.sourceController updateFilterPredicate];
    
}
- (Account *)account {
    return [self.objectValue valueForKey:@"account"];
}

- (IBAction)praxButtonClicked:(id)sender {
    
     NSLog(@"ServiceView praxButtonClicked");   
    
}


/*- (void)drawRect:(NSRect)dirtyRect
{
    NSLog(@"ServiceView drawRect");
    // Drawing code here.
}
*/

@end
