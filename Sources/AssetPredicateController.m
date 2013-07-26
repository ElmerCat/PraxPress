//
//  AssetPredicateController.m
//  PraxPress
//
//  Created by Elmer on 1/10/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetPredicateController.h"

@interface AssetPredicateController ()

@end

@implementation AssetPredicateController

#define DEFAULT_PREDICATE @"title CONTAINS[cd] \"\" AND (type == \"track\" OR type == \"playlist\" OR type == \"post\" OR type == \"page\")"

- (void)awakeFromNib {
    if (!self.awake) {
        self.awake = TRUE;
        NSLog(@"AssetPredicateController awakeFromNib");
        [[NSNotificationCenter defaultCenter] addObserverForName:NSRuleEditorRowsDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                          NSLog(@"AssetPredicateController NSRuleEditorRowsDidChangeNotification");
                                                          
                                                 /*         NSArray *rows = self.predicateEditor.rowTemplates;
                                                          
                                                          NSLog(@"self.predicateEditor.rowTemplates %@", rows);
                                                          
                                                          for (NSPredicateEditorRowTemplate *row in rows) {
                                                              NSArray *views = row.templateViews;
                                                              NSLog(@"row.templateViews %@", views);
                                                              
                                                              for (NSView *view in views) {
                                                                  if ([view isKindOfClass:[NSTextField class]]) {
                                                                      NSRect bounds = view.bounds;
                                                                      bounds.size.width = 40;
                                                                      [view setBounds:bounds];
                                                                      NSTextField *textfield = (NSTextField *)view;
                                                                      [textfield setBackgroundColor:[NSColor greenColor]];
                                                                
                                                                  }
                                                              }
                                                              
                                                              
                                                          }
                                                  */
                                                          if (!self.predicateEditor.numberOfRows) [self.popover close];
                                                             
                                                          //   if ([aNotification object] == self.postEditorPanel) {
                                                          //      [self.postEditor loadWebView];
                                                          // }
                                                          //        else NSLog(@"UpdateController NSWindowDidResignKeyNotification aNotification: %@", aNotification);
                                                          
                                                          
                                                      }];
    }
    
}


- (IBAction)show:(id)sender {
    if (!self.predicate) self.predicate = [NSPredicate predicateWithFormat:DEFAULT_PREDICATE];

    [self.popover showRelativeToRect:[self.assetsTableView bounds] ofView:self.assetsTableView preferredEdge:NSMaxXEdge];
}


- (IBAction)predicateSelector:(id)sender {
    
    if (![self.predicate.predicateFormat isEqualToString:DEFAULT_PREDICATE]) {
        [self.assetsController setFilterPredicate:self.predicate];
    }
}



@end
