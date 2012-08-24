//
//  PostEditor.m
//  PraxPress
//
//  Created by John Canfield on 8/22/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "PostEditor.h"

@implementation PostEditor

- (void) loadWebView {
    [[self.postEditorWebView mainFrame] loadHTMLString:[self.postEditorText string] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

@end
