//
//  PraxDefaultsController.m
//  PraxPress
//
//  Created by John-Elmer on 1/13/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import "PraxDefaultsController.h"

@implementation PraxDefaultsController

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = YES;
        NSLog(@"PraxDefaultsController awakeFromNib");
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"PraxDefaultsDisplayNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            [self.panel makeKeyAndOrderFront:self];
            id identifier = aNotification.object;
            [self.tabView selectTabViewItemWithIdentifier:identifier];
            [self.toolbar setSelectedItemIdentifier:identifier];
            
        }];

        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Defaults" withExtension:@"plist"]];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        [self.toolbar setSelectedItemIdentifier:@"General"];
        [self.templatesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    }
}

#pragma mark - IBActions


- (IBAction)selectPane:(id)sender {
    NSString *identifier = [sender itemIdentifier];
    [self.tabView selectTabViewItemWithIdentifier:identifier];
}

- (IBAction)duplicateTemplate:(id)sender {
    if (self.templatesArrayController.selectedObjects.count) {
        NSMutableDictionary *template = [self.templatesArrayController.selectedObjects[0] mutableCopy];
        template[@"name"] = [template[@"name"] stringByAppendingString:@" - Copy "];

        NSDictionary *anotherTemplate = [self.templatesArrayController.arrangedObjects firstObjectWithKey:@"name" equalToString:template[@"name"]];
        while (anotherTemplate) {
            template[@"name"] = [template[@"name"] stringByAppendingString:@"X"];
            anotherTemplate = [self.templatesArrayController.arrangedObjects firstObjectWithKey:@"name" equalToString:template[@"name"]];
        }

        
        [self.templatesArrayController addObject:template];
        [self.templatesArrayController setSelectedObjects:@[template]];
    }
}

- (IBAction)exportTemplates:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"prax-templates"]];
    [panel setAllowsOtherFileTypes:YES];
    [panel setMessage:@"Export Templates to File"];
    [panel setNameFieldStringValue:@"Templates"];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray *templates = self.templatesArrayController.arrangedObjects;
            [NSKeyedArchiver archiveRootObject:templates toFile:panel.URL.path];
        }
    }];

}

-(NSArray *)templateKeys {
    return @[@"name",
             @"templateHeaderCode",
             @"templateItemsCode",
             @"templateRowCode",
             @"templateFooterCode",
             @"templateItemsPerRow"]; }

- (IBAction)importTemplates:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowedFileTypes:@[@"prax-templates"]];
    [panel setExtensionHidden:YES];
    [panel setMessage:@"Import Templates from File"];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [panel URLs][0];
            NSMutableArray *templates = [self.templatesArrayController.arrangedObjects mutableCopy];
            NSArray *importTemplates = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
            for (NSDictionary *importTemplate in importTemplates) {
                NSMutableDictionary *template = [templates firstObjectWithKey:@"name" equalToString:importTemplate[@"name"]];
                if (template) {
                    NSInteger result;
                    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"%@\n\nReplace Template?", importTemplate[@"name"]] defaultButton:@"Skip this Item" alternateButton:[NSString stringWithFormat:@"Replace Template %@",importTemplate[@"name"]] otherButton:@"Stop Importing" informativeTextWithFormat:@""];
//                    [alert setAccessoryView:controller.alertAccessoryView];
                    result = [alert runModal];
                    if (result == NSAlertDefaultReturn) continue;
                    else if (result == NSAlertOtherReturn) return;
                    else if (result == NSAlertAlternateReturn) {
                        for (NSString *key in self.templateKeys) {
                            template[key] = importTemplate[key]; } }
                }
                else {
                    template = @{}.mutableCopy;
                    for (NSString *key in self.templateKeys) {
                        template[key] = importTemplate[key]; }
                    [templates addObject:template];
                }
            }
            [[NSUserDefaults standardUserDefaults] setObject:templates forKey:@"templates"];
        }
    }];

}

#pragma mark - <NSTableViewDelegate>

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    
    
}



#pragma mark - <NSTextFieldDelegate>

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    NSString *name = [fieldEditor string];
    if ([self.templatesArrayController isSelectedItemStringValue:name uniqueForKey:@"name"]) return YES;
    [[NSSound soundNamed:@"Error"] play];
    [fieldEditor setString:[name stringByAppendingString:@" - Copy"]];
    return NO;
}


@end
