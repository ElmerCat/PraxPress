//
//  TemplateViewController.m
//  PraxPress
//
//  Created by John-Elmer on 1/14/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import "CodeController.h"

@implementation CodeController

#pragma mark - Initialization

- (void)awakeFromNib {
    NSLog(@"TemplateViewController awakeFromNib");
    if (!self.awake) {
        self.awake = YES;
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
        [self.templateBox setContentView:self.templateView];

    }
}

- (void)dealloc {
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}


#pragma mark ------

/*- (IBAction)exportFormattedCode:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"html"]];
    [panel setAllowsOtherFileTypes:YES];
    [panel setMessage:@"Export Code to File"];
    if (self.controller.source.exportURL) {
        [panel setDirectoryURL:[self.controller.source.exportURL URLByDeletingLastPathComponent]];
        [panel setNameFieldStringValue:[self.controller.source.exportURL lastPathComponent]];
    }
    [panel beginSheetModalForWindow:self.controller.document.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            
            self.controller.source.exportURL = panel.URL;
            self.appleScript = nil;
            [self writeFormattedCode];
        }
        
    }];
}*/


- (void)update {
    @synchronized(self) {
        if (self.updating) return;
        else self.updating = YES;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        if (self.controller.showCodeView) {
            
            NSMutableString *code = @"".mutableCopy;
            if ((self.controller.source.templateHeaderCode) && (self.controller.source.templateHeaderCode.length)) [code appendString:self.controller.source.templateHeaderCode];
            if (((self.controller.source) && ([self.controller.assetArrayController.selectedObjects count] > 0)) && ((self.controller.source.templateItemsCode) && (self.controller.source.templateItemsCode.length))) {
                NSInteger rowItems = 0;
                for (Asset *asset in self.controller.assetArrayController.selectedObjects) {
                    [code appendString:[Widget stringWithTemplate:self.controller.source.templateItemsCode forAsset:asset wordPress:NO]];
                    if (self.controller.source.templateItemsPerRow.integerValue > 1) {
                        rowItems++;
                        if (rowItems >= self.controller.source.templateItemsPerRow.integerValue) {
                            rowItems = 0;
                            if ((self.controller.source.templateRowCode) && (self.controller.source.templateRowCode.length)) [code appendString:self.controller.source.templateRowCode];
                        }
                    }
                }
            }
            if ((self.controller.source.templateFooterCode) && (self.controller.source.templateFooterCode.length)) [code appendString:self.controller.source.templateFooterCode];
            if (![code isEqualToString:self.pageCode]) {
                self.pageCode = code.copy;
            }
        }
        
        self.needsUpdate = NO;
        self.updating = NO;
    });
    
    
}

- (void)initAppleScript {    
    
    self.appleScriptSource = [NSString stringWithFormat:@"tell application \"Safari\"\rset theURL to \"%@\"\rset foundTab to false\rset windowCount to number of window\rrepeat with theWindow from 1 to windowCount\rtry\rset tabCount to number of tabs in window theWindow\rif (tabCount > 0) then\rrepeat with theTab from 1 to tabCount\rset tabName to name of tab theTab of window theWindow\rif (exists URL of tab theTab of window theWindow) then\rset tabURL to URL of tab theTab of window theWindow\rif (tabURL = theURL) then\rset foundTab to true\rend if\rend if\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rend if\rend try\rif (foundTab = true) then\rexit repeat\rend if\rend repeat\rif (foundTab = true) then\rset URL of tab theTab of window theWindow to theURL\relse\rmake new document at end of documents with properties {URL:theURL}\ractivate\rend if\rend tell", self.exportCodeURL.absoluteString];
    self.appleScript = nil;
    self.appleScript = [[NSAppleScript alloc] initWithSource:self.appleScriptSource];
}

- (void)writePageCode {
    if (!self.controller.source) return;
    if (!self.controller.document.exportCodeDirectory) return;
    
    if (!self.exportCodeURL) {
        NSString *filename = [self.controller.source.name lowercaseString];
        filename = [filename stringByReplacingOccurrencesOfString:@" " withString:@"-"];
        self.exportCodeURL = [self.controller.document.exportCodeDirectory URLByAppendingPathComponent:filename];
        self.exportCodeURL = [self.exportCodeURL URLByAppendingPathExtension:@"html"];
    }
    
    NSError *error;
    [self.exportCodeURL startAccessingSecurityScopedResource];
    BOOL ok = [self.pageCode writeToURL:self.exportCodeURL atomically:YES
                                    encoding:NSUnicodeStringEncoding error:&error];
    [self.exportCodeURL stopAccessingSecurityScopedResource];
    if (!ok) {
        NSString *text = [NSString stringWithFormat:@"Error writing file\nself.source.exportURL.path: %@\nlocalizedFailureReason: %@", self.controller.source.exportURL.path, [error localizedFailureReason]];
        [Prax presentAlert:text forController:self];
        self.controller.document.exportCodeDirectory = nil;
        if (!self.controller.document.exportCodeDirectory) {
            self.showSafariView = NO;
            [Prax presentAlert:@"self.document.exportCodeDirectory is nil" forController:self];
        }
        else [self writePageCode];
        
    }
    else {
        if ((self.showSafariView) && (![self.pageCode isEqualToString:@""])) {
            if (!self.appleScript) [self initAppleScript];
            NSDictionary *errorInfo;
            if (![self.appleScript executeAndReturnError:&errorInfo]) {
                [Prax presentAlert:[NSString stringWithFormat:@"showSafariView AppleScript error: %@", errorInfo] forController:self];
            }
            
        }
    }
}


#pragma mark - IBActions

- (IBAction)templateMode:(id)sender {
    NSInteger tag = [sender tag];
    if ((100 <= tag) && (101 >= tag)) {
        if (100 == tag) self.controller.source.templateMode = @0;
        if (101 == tag) self.controller.source.templateMode = @1;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger tag = item.tag;
    if ((100 <= tag) && (101 >= tag)) {
        NSInteger templateMode = self.controller.source.templateMode.integerValue;
        if (100 == tag) [item setState:((templateMode == 0) ? NSOnState : NSOffState)];
        else if (101 == tag) [item setState:((templateMode == 1) ? NSOnState : NSOffState)];
        return YES;
    }
    return NO;
}


#pragma mark - KeyValueObservation


- (NSArray *)keyPathsToObserve {return @[@"self.controller.showCodeView",
                                         @"self.needsUpdate", @"self.formatText",
                                         @"self.editingString", @"self.pageCode",
                                         @"self.controller.source",
                                         @"self.controller.source.templateHeaderCode",
                                         @"self.controller.source.templateItemsCode",
                                         @"self.controller.source.templateRowCode",
                                         @"self.controller.source.templateFooterCode",
                                         @"self.controller.source.templateItemsPerRow"]; }

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([@"self.needsUpdate" isEqualToString:keyPath]) {
        if (self.needsUpdate) [self update]; }
    
    else if ([@"self.controller.showCodeView" isEqualToString:keyPath]) {
        if (!self.controller.showCodeView) self.pageCode = @""; }
    
    else if ([@"self.controller.source" isEqualToString:keyPath]) {
        self.exportCodeURL = nil;
        self.appleScript = nil; }
    
    else if ([@"self.controller.source.templateItemsCode" isEqualToString:keyPath]) {
        NSString *itemsCode = self.controller.source.templateItemsCode;
        if (!itemsCode || !(itemsCode.length)) itemsCode = @"$$$title$$$\n";
        if (![itemsCode isEqualToString:self.formatText]) self.formatText = itemsCode;  }
    
    else if ([@"self.formatText" isEqualToString:keyPath]) {
        if ([self.editingString isEqualToString:self.formatText]) return;
        else self.editingString = self.formatText; }
    
    else if ([@"self.editingString" isEqualToString:keyPath]) {
        if ([self.editingString isEqualToString:self.formatText]) return;
        self.controller.source.templateItemsCode = self.editingString; }
    
    else if ([@"self.controller.source.templateItemsPerRow" isEqualToString:keyPath]) {
        if (self.controller.source.templateItemsPerRow.integerValue > 1) self.interRowMaxHeight.constant = 100;
        else self.interRowMaxHeight.constant = 0; }
    
    else if ([@[@"self.pageCode", @"self.showSafariView"] containsObject:keyPath]) {
        if (self.showSafariView) {
            [self writePageCode]; } }
    
//    else {
 //       NSLog(@"CodeController observeValueForKeyPath:%@\nobject:%@\nchange:%@\ncontext:%@", keyPath, object, change, context);
  //  }
    
    if ([@[@"self.controller.showCodeView",
           @"self.controller.source",
           @"self.controller.source.templateHeaderCode",
           @"self.controller.source.templateItemsCode",
           @"self.controller.source.templateRowCode",
           @"self.controller.source.templateFooterCode",
           @"self.controller.source.templateItemsPerRow"] containsObject:keyPath]) self.needsUpdate = YES;
}

#pragma mark - <NSSplitViewDelegate>
#pragma mark - <NSTableViewDelegate>


#pragma mark - <NSTokenFieldDelegate>

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    
    NSMutableArray *returnTokens = @[].mutableCopy;
    for (id representedObject in tokens) {
        [returnTokens addObjectsFromArray:[Widget templateFormatArrayFromObject:representedObject]];
    }
    return returnTokens;
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
    return [[representedObject className] isEqualToString:@"Widget"];
    
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject {
    NSLog(@"menuForRepresentedObject:%@",representedObject);
    
    NSMenu *menu = [[NSMenu alloc] init];
    if ([menu respondsToSelector: @selector(_setHasPadding:onEdge:)])
    {
        [menu _setHasPadding: NO onEdge: 1];
        [menu _setHasPadding: NO onEdge: 3];
    }    NSMenuItem *item;
    
    item = [[NSMenuItem alloc] init];
    [item setView:self.widgetMenuView];
    [item setRepresentedObject:representedObject];
    [menu addItem:item];
    [menu setDelegate:self.widgetViewController];
    return menu;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {
    if ([[representedObject className] isEqualToString:@"Widget"]) {
        return NSDefaultTokenStyle;
    }
    return NSPlainTextTokenStyle;
}


- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
    
    if ([[representedObject className] isEqualToString:@"Widget"]) {
        return [(Widget *)representedObject displayString];
    }
    else return representedObject;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    
    if ([[representedObject className] isEqualToString:@"Widget"]) {
        return [(Widget *)representedObject editingString];
    }
    else return representedObject;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    NSArray *array = [Widget templateFormatArrayFromObject:editingString];
    if (array.count == 1) return array[0];
    else {
        NSMutableString *string = @"".mutableCopy;
        for (id object in array) {
            if ([[object className] isEqualToString:@"Widget"]) {
                [string appendString:[(Widget *)object editingString]];
            }
            else [string appendString:object];
        }
        return string;
    }
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pboard writeObjects:@[[[NSValueTransformer valueTransformerForName:@"PraxWidgetStringTransformer"] reverseTransformedValue:objects]]];
    return YES;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
    
    
    NSRange occurance = [substring rangeOfString:@"$" options:NSBackwardsSearch range:NSMakeRange((substring.length - 1), 1)];
    if (occurance.length) {
        return @[[NSString stringWithFormat:@"%@%@", substring, [Widget newWidgetCompletionString]]];
    }
    else return @[];
}


@end
