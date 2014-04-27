//
//  LoadTemplates.m
//  PraxPress
//
//  Created by John-Elmer on 1/20/14.
//  Copyright (c) 2014 ElmerCat. All rights reserved.
//

#import "LoadTemplate.h"

@implementation LoadTemplate

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (IBAction)loadTemplate:(id)sender {
    [self.templatesArrayController setSelectionIndexes:nil];
    [self.popover showRelativeToRect:self.relativeView.bounds ofView:self.relativeView preferredEdge:NSMaxYEdge];
}

#pragma mark - <NSTableViewDelegate>

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    if (![self.popover isShown]) return;

    if (self.templatesArrayController.selectedObjects.count) {
        NSDictionary *template = self.templatesArrayController.selectedObjects[0];
        self.controller.source.templateHeaderCode = template[@"templateHeaderCode"];
        self.controller.source.templateItemsCode = template[@"templateItemsCode"];
        self.controller.source.templateRowCode = template[@"templateRowCode"];
        self.controller.source.templateFooterCode = template[@"templateFooterCode"];
        self.controller.source.templateItemsPerRow = template[@"templateItemsPerRow"];
    }

    [self.popover performClose:self];
    
    
}

@end
