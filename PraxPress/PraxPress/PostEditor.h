//
//  PostEditor.h
//  PraxPress
//
//  Created by John Canfield on 8/22/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Document.h"

@interface PostEditor : NSObject
@property (unsafe_unretained) IBOutlet NSTextView *postEditorText;
@property (weak) IBOutlet WebView *postEditorWebView;
- (void) loadWebView;
@end
