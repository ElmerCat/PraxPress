//
//  AssetDetailController.m
//  PraxPress
//
//  Created by Elmer on 1/10/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "AssetDetailController.h"

@interface AssetDetailController ()

@end

@implementation AssetDetailController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
            NSLog(@"AssetDetailController initWithWindow");
        [self addObserver:self forKeyPath:@"self.templateName" options:NSKeyValueObservingOptionNew context:0];
    }
    
    return self;
}
-(void)dealloc {
    NSLog(@"dealloc AssetDetailController");
    [self removeObserver:self forKeyPath:@"self.templateName"];
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.templateName"]) {
        [[NSUserDefaults standardUserDefaults] setObject:self.templateName forKey:@"assetDetailTemplate"];
        [self loadWebView];
    }
    else {
        NSLog(@"Template observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);
    }
}


- (void)windowDidLoad {
    
    [super windowDidLoad];
    NSLog(@"AssetDetailController windowDidLoad");

    self.templateName = [[NSUserDefaults standardUserDefaults] objectForKey:@"assetDetailTemplate"];
    [self loadWebView];
    
}

- (void)loadWebView {
    
    NSString *formatText;
    for (Template *template in self.filesOwner.templatesController.arrangedObjects) {
        if ([template.name isEqualToString:self.templateName]) {
            formatText = template.formatText;
            break;
        }
    }
    NSString *html = [TemplateViewController codeForTemplate:formatText withAssets:@[self.asset]];
    [[self.webView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    [self.codeTextView setString:html];
}


- (BOOL)windowShouldClose:(id)sender {
    
    NSLog(@"AssetDetailController windowShouldClose");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AssetDetailClosedNotification" object:self.asset];

    return YES;
    
}


- (IBAction)showTemplatesPopover:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowTemplatesNotification" object:sender];
}


- (IBAction)showMetadataPopover:(id)sender {
    
    [self.filesOwner.assetMetadataPopover showPopoverRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge withDictionary:self.asset.metadata];
    
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {return TRUE;}
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {return FALSE;}


@end
