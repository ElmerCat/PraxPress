//
//  SaveTemplate.m
//  PraxPress
//
//  Created by John-Elmer on 1/20/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import "SaveTemplate.h"

@interface SaveTemplate ()

@end

@implementation SaveTemplate

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}
- (void)dealloc {
    NSLog(@"SaveTemplate dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}


- (void)awakeFromNib {
    NSLog(@"SaveTemplate awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
    }
}

#pragma mark - KeyValueObservation

- (NSArray *)keyPathsToObserve {return @[@"self.templateName"];}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"SaveTemplate observeValueForKeyPath: %@", keyPath);
    
    if ([@"self.templateName" isEqualToString:keyPath]) {
        self.canSave = NO;
        self.canReplace = NO;
        if (self.templateName.length) {
            NSDictionary *template = [self.templatesArrayController.arrangedObjects firstObjectWithKey:@"name" equalToString:self.templateName];
            if (template) self.canReplace = YES;
            else self.canSave = YES;
        }
    }
}

#pragma mark - IBActions


- (IBAction)saveTemplate:(id)sender {
    [self.templatesArrayController setSelectionIndexes:nil];
    self.templateName = @"";
    [self.popover showRelativeToRect:self.relativeView.bounds ofView:self.relativeView preferredEdge:NSMaxYEdge];
}

- (IBAction)save:(id)sender {
    NSMutableDictionary *template = [self.templatesArrayController.arrangedObjects firstObjectWithKey:@"name" equalToString:self.templateName];
    if (!template) {
        template = @{}.mutableCopy;
        template[@"name"] = self.templateName;
        template[@"templateHeaderCode"] = self.controller.source.templateHeaderCode;
        template[@"templateItemsCode"] = self.controller.source.templateItemsCode;
        template[@"templateRowCode"] = self.controller.source.templateRowCode;
        template[@"templateFooterCode"] = self.controller.source.templateFooterCode;
        template[@"templateItemsPerRow"] = self.controller.source.templateItemsPerRow;
        [self.templatesArrayController addObject:template];
    }
    [self.popover performClose:self];
}

- (IBAction)replace:(id)sender {
    NSMutableDictionary *template = [self.templatesArrayController.arrangedObjects firstObjectWithKey:@"name" equalToString:self.templateName];
    if (template) {
        template[@"templateHeaderCode"] = self.controller.source.templateHeaderCode;
        template[@"templateItemsCode"] = self.controller.source.templateItemsCode;
        template[@"templateRowCode"] = self.controller.source.templateRowCode;
        template[@"templateFooterCode"] = self.controller.source.templateFooterCode;
        template[@"templateItemsPerRow"] = self.controller.source.templateItemsPerRow;
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.templatesArrayController.arrangedObjects forKey:@"templates"];

    [self.popover performClose:self];
}


#pragma mark - <NSTableViewDelegate>

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if (![self.popover isShown]) return;
    
    if (self.templatesArrayController.selectedObjects.count) {
        NSDictionary *template = self.templatesArrayController.selectedObjects[0];
        self.templateName = template[@"name"];
        
    }
}


@end
