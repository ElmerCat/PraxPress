//
//  Document+DocumentUserInterface.m
//  PraxPress
//
//  Created by Elmer on 7/16/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "Document+DocumentUserInterface.h"

@implementation Document (DocumentUserInterface)

- (IBAction)displayAccountsPreferences:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PraxDefaultsDisplayNotification" object:@"Accounts"];

}







- (NSString *)toolTipStats {
    return @"Duration\rPlayback Count\rFavorites\rDownloads\rComments";
}
- (NSString *)toolTipPermalink {
    return @"Permalink Slug";
}
- (NSString *)toolTipReload {
    return @"Reload - Cancel changes and re-download data from server";
}
- (NSString *)toolTipUpload {
    return @"Upload - Save changes and upload data to server";
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    SEL action = [item action];

    if (action == @selector(closeAssetListPane:)) {
        return [self.sourceController validateMenuItem:item];
    }
    
    else if (action == @selector(toggleSourceList:)) {
        if (([[item title] isEqualToString:@"Show Source List"]) && (self.sourceController.sourceListVisible)) {
            [item setHidden:YES];
            return NO;
        }
        else if (([[item title] isEqualToString:@"Hide Source List"]) && (!self.sourceController.sourceListVisible)) {
            [item setHidden:YES];
            return NO;
        }
        else {
            [item setHidden:NO];
            return YES;
        }
    }
    else {
        return [super validateMenuItem:item];
    }
}



- (IBAction)closeAssetListPane:(id)sender {
    [self.sourceController closeAssetListPane:sender];
}

- (IBAction)toggleTagsPanel:(id)sender {
    [self.tagController toggleTagsPanel:sender];
}

- (IBAction)toggleSourceList:(id)sender {
    [self.sourceController toggleSourceList:sender];
}

- (IBAction)newPraxAsset:(id)sender {
    [self.sourceController newPraxAsset:sender];
}

- (IBAction)praxButtonPressed:(id)sender {
    
    
    NSArray *safaris = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.Safari"];
    if (safaris.count > 0) {
        NSRunningApplication *runningSafariApplication = safaris[0];
        [runningSafariApplication activateWithOptions:0];
    }
    
    if (!self.safariDocument) {
        SafariApplication *safari = [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
        
        self.safariDocument = [safari open:[NSURL URLWithString:@"/Library/Webserver/Documents/prax/index.html"]];
        
        
    }
    
/*    if ([[safari windows] count] == 0)
    {
        NSLog(@"No window found. Creating a new one.");
        SafariDocument *newDoc = [[[safari classForScriptingClass:@"document"] alloc] init];
        [[safari windows] addObject:newDoc];
    }
    else
    {
        NSLog(@"Seems we already have a safari window");
        SafariTab *newTab = [[[safari classForScriptingClass:@"tab"] alloc] init];
        [[[safari windows] objectAtIndex:0] addObject:newTab];
    }
    
 
    NSLog(@"praxButtonPressed");
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"plist"]];
    [panel setMessage:@"Export PraxPress User Defaults to File"];
    [panel setNameFieldStringValue:@"PraxPress-Defaults"];
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [dictionary writeToURL:panel.URL atomically:YES];
        }
    }];
*/
}


/*- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
 {
 SEL theAction = [anItem action];
 
 if (theAction == @selector(toggleSourceList:)) {
 if (([[item title] isEqualToString:@"Show Source List"]) && (self.sourceController.sourceListVisible)) return NO;
 else if (([[item title] isEqualToString:@"Hide Source List"]) && (!self.sourceController.sourceListVisible)) return NO;
 else return YES;
 }
 else {
 if (theAction == @selector(paste:)) {
 if ( ) {
 return YES;
 }
 return NO;
 }
 else {
 //
 }
 }
 // Subclass of NSDocument, so invoke super's implementation
 return [super validateUserInterfaceItem:anItem];
 }*/


/*-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
 NSLog(@"validateToolbarItem: %@", toolbarItem);
 
 BOOL enable = NO;
 if ([[toolbarItem itemIdentifier] isEqual:NSToolbarShowColorsItemIdentifier]) {
 // We will return YES (enable the save item)
 // only when the document is dirty and needs saving
 enable = [self isDocumentEdited];
 } else if ([[toolbarItem itemIdentifier] isEqual:NSToolbarPrintItemIdentifier]) {
 // always enable print for this window
 enable = NO;
 }
 else if ([[toolbarItem itemIdentifier] isEqual:@"PraxButton"]) {
 enable = YES;
 }
 
 return enable;
 }*/



@end
