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

- (NSArray *)keyPathsToObserve {return @[@"self.changedAssetArrayController.arrangedObjects", @"self.assetArrayController.sortDescriptors", @"self.assetArrayController.selectionIndexes", @"self.associatedController.assetArrayController.selectionIndexes", @"self.isSelectedPane", @"self.source", @"self.source.batchAssets", @"self.source.fetchPredicate", @"self.source.requiredTags", @"self.source.interface", @"self.source.requireAllTags", @"self.source.excludedTags", @"self.source.template", @"self.source.template.formatText", @"self.showDetailView", @"self.showCodeView", @"self.showSafariView", @"self.exportCode", @"self.formattedCode"];}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"AssetListViewController initWithNibName: %@", nibNameOrNil);

   /*     [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.detailScrollView queue:nil usingBlock:^(NSNotification *aNotification){
            NSRect documentRect = [self.detailScrollView.documentView bounds];
            NSRect scrollViewRect = self.detailScrollView.frame;
            if (scrollViewRect.size.width >= 500) {
                documentRect.size.width = (scrollViewRect.size.width - 2);
                [self.detailScrollView.documentView setFrame:documentRect];
            }
         }];
*/
    }
    return self;
}

- (void)dealloc {
    NSLog(@"AssetListViewController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

- (void)tagFilterAssets {
    NSMutableSet *excludedAssets = [NSMutableSet setWithCapacity:1];
    NSMutableSet *requiredAssets = [NSMutableSet setWithCapacity:1];
    NSMutableOrderedSet *tagFilteredAssets  = self.assets.mutableCopy;
    if (self.source.requiredTags.count > 0) {
        
        if (self.source.requireAllTags.boolValue) {
            BOOL multiple;
            for (Tag *tag in self.source.requiredTags) {
                if (multiple) {
                    [requiredAssets intersectSet:tag.assets];
                }
                else {
                    [requiredAssets unionSet:tag.assets];
                    multiple = YES;
                }
            }
        }
        else {
            for (Tag *tag in self.source.requiredTags) {
                [requiredAssets unionSet:tag.assets];
            }
        }
        [tagFilteredAssets intersectSet:requiredAssets];
        
    }
    
    for (Tag *tag in self.source.excludedTags) {
        [excludedAssets unionSet:tag.assets];
    }
    [tagFilteredAssets minusSet:excludedAssets];
    [self.assetArrayController setContent:[tagFilteredAssets array]];
}

- (void)loadAssociatedItems {
    if (!self.associatedController.source) return;
    NSMutableOrderedSet *associatedItems = [NSMutableOrderedSet orderedSetWithCapacity:1];
    self.isPlaylist = NO;
    
    if ([self.associatedController.assetArrayController.selectedObjects count] > 0) {
        for (Asset *selectedAsset in self.associatedController.assetArrayController.selectedObjects) {
            [associatedItems unionOrderedSet:selectedAsset.associatedItems];
            if ([self.associatedController.assetArrayController.selectedObjects count] == 1) {
                if ([[selectedAsset valueForKey:@"type"] isEqualToString:@"playlist"]) {
                    self.isPlaylist = YES;
                }
            }
        }
        [self.assetArrayController setContent:[associatedItems array]];
    }
    
}

- (void)removeAssociatedItems:(NSArray *)items fromAssets:(NSArray *)assets {
    if (assets.count) {
        for (Asset *asset in assets) {
            if ((![asset.type isEqualToString:@"playlist"]) || (!items.count)) {
                [[NSSound soundNamed:@"Error"] play];
                return;
            }
            NSMutableOrderedSet *associatedItems = asset.associatedItems.mutableCopy;
            for (Asset *item in items) {
                
                [associatedItems removeObject:item];
            }
            asset.associatedItems = associatedItems;
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
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
        [self.assetsTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"PraxItemsDropType", nil]];
        CGFloat newPosition = [self.splitView maxPossiblePositionOfDividerAtIndex:0];
        [self.splitView setPosition:newPosition ofDividerAtIndex:0 animated:NO];
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

- (void)updateFormattedCode:sender {
    @synchronized(self) {
        if (self.updatingFormattedCode) return;
        else self.updatingFormattedCode = YES;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSString *newFormattedCode = @"";
        if (self.exportCode) {
            
            if ((self.source) && ([self.assetArrayController.selectedObjects count] > 0)) {
                newFormattedCode = [TemplateController codeForTemplate:self.source.template.formatText withAssets:self.assetArrayController.selectedObjects];
            }
        }
        if (![newFormattedCode isEqualToString:self.formattedCode]) {
            self.formattedCode = newFormattedCode;
        }
        self.updatingFormattedCode = NO;
    });

    
}

- (IBAction)exportFormattedCode:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"html"]];
    [panel setAllowsOtherFileTypes:YES];
    [panel setMessage:@"Export Code to File"];
    if (self.source.exportURL) {
        [panel setDirectoryURL:[self.source.exportURL URLByDeletingLastPathComponent]];
        [panel setNameFieldStringValue:[self.source.exportURL lastPathComponent]];
    }
    [panel beginSheetModalForWindow:self.document.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            
            self.source.exportURL = panel.URL;
            self.appleScript = nil;
            [self writeFormattedCode];
            }

    }];
}

- (void)initAppleScript {
    self.appleScriptSource = [NSString stringWithFormat:@"tell application \"Safari\"\rset theURL to \"%@\"\rset foundTab to false\rset windowCount to number of window\rrepeat with theWindow from 1 to windowCount\rtry\rset tabCount to number of tabs in window theWindow\rif (tabCount > 0) then\rrepeat with theTab from 1 to tabCount\rset tabName to name of tab theTab of window theWindow\rif (exists URL of tab theTab of window theWindow) then\rset tabURL to URL of tab theTab of window theWindow\rif (tabURL = theURL) then\rset foundTab to true\rend if\rend if\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rend if\rend try\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rif (foundTab = true) then\rset URL of tab theTab of window theWindow to theURL\relse\rmake new document at end of documents with properties {URL:theURL}\rend if\rend tell", self.exportCodeURL.absoluteString];
    self.appleScript = nil;
    self.appleScript = [[NSAppleScript alloc] initWithSource:self.appleScriptSource];
}

- (void)writeFormattedCode {
    if (!self.document.exportCodeDirectory) return;
    
    if (!self.exportCodeURL) {
        NSString *filename = [self.source.name lowercaseString];
        filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        self.exportCodeURL = [self.document.exportCodeDirectory URLByAppendingPathComponent:filename];
        self.exportCodeURL = [self.exportCodeURL URLByAppendingPathExtension:@"html"];
    }

    NSError *error;
    [self.exportCodeURL startAccessingSecurityScopedResource];
    BOOL ok = [self.formattedCode writeToURL:self.exportCodeURL atomically:YES
                                            encoding:NSUnicodeStringEncoding error:&error];
    [self.exportCodeURL stopAccessingSecurityScopedResource];
    if (!ok) {
        NSString *text = [NSString stringWithFormat:@"Error writing file\nself.source.exportURL.path: %@\nlocalizedFailureReason: %@", self.source.exportURL.path, [error localizedFailureReason]];
        [Prax presentAlert:text forController:self];
        self.document.exportCodeDirectory = nil;
        if (!self.document.exportCodeDirectory) {
            self.showSafariView = NO;
            self.exportCode = NO;
            [Prax presentAlert:@"self.document.exportCodeDirectory is nil" forController:self];
        }
        else [self writeFormattedCode];
        
    }
    else {
        if ((self.showSafariView) && (![self.formattedCode isEqualToString:@""])) {
            if (!self.appleScript) [self initAppleScript];
            NSDictionary *errorInfo;
            if (![self.appleScript executeAndReturnError:&errorInfo]) {
                [Prax presentAlert:[NSString stringWithFormat:@"showSafariView AppleScript error: %@", errorInfo] forController:self];
            }
            
        }
    }
}

- (IBAction)filterButtonClicked:(id)sender {
    if ([self.sourceInfoPanel.window isVisible]) {
        [self.sourceInfoPanel.window close];
    }
    else {
        [self showSourceInfoPanel:sender];
    }
}

- (IBAction)showSourceInfoPanel:(id)sender {
    if (!self.sourceInfoPanel) {
        self.sourceInfoPanel = [[SourceInfoPanel alloc] initWithWindowNibName:@"SourceInfoPanel"];
        self.sourceInfoPanel.assetListViewController = self;
    }
    [self.sourceInfoPanel showSourceInfoPanel];
}

- (void)doubleClickedArrayObjects:(NSArray *)arrayObjects {
    if (self.showDetailView) {
        self.showDetailView = NO;
    }
    else {
        self.showDetailView = YES;
    }
}

- (IBAction)templatesButtonPressed:(id)sender {
    self.document.templateController.assetListView = self;
    [self.document.templatesPanel makeKeyAndOrderFront:self];
}
- (void)showTags:(NSSet *)tags sender:(id)sender {
    NSLog(@"tags %@", [tags description]);

}

- (void)openBrowserWithURLString:(NSString *)string {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:string]];
}

- (void)showMetadataPopover:(NSDictionary *)metadata sender:(id)sender {
    NSLog(@"metadata %@", [metadata description]);
    [self.assetMetadataPopover showPopoverRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge withDictionary:metadata];
}


@end
