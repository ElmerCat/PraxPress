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

- (NSArray *)keyPathsToObserve {return @[@"self.assetArrayController.selectionIndexes", @"self.isSelectedPane", @"self.source", @"self.source.fetchPredicate", @"self.source.template", @"self.source.template.formatText", @"self.viewerMode", @"self.source.formattedCode", @"self.webView.estimatedProgress"];}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"AssetListViewController initWithNibName: %@", nibNameOrNil);

        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self.detailScrollView queue:nil usingBlock:^(NSNotification *aNotification){
            NSRect documentRect = [self.detailScrollView.documentView bounds];
            NSRect scrollViewRect = self.detailScrollView.frame;
            if (scrollViewRect.size.width >= 500) {
                documentRect.size.width = (scrollViewRect.size.width - 2);
                [self.detailScrollView.documentView setFrame:documentRect];
            }
         }];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"AssetListViewController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog(@"AssetListViewController observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"self.isSelectedPane"]) {
        CGFloat selectedPaneAlpha = 0;
        CGFloat notSelectedPaneAlpha = 1;
        if (self.isSelectedPane) {
            selectedPaneAlpha = 1;
            notSelectedPaneAlpha = 0;
        }
        [self.selectedButton.animator setAlphaValue:selectedPaneAlpha];
        [self.notSelectedButton.animator setAlphaValue:notSelectedPaneAlpha];
        
    }
    else if ([keyPath isEqualToString:@"self.viewerMode"]) {
        [self updateFormattedCode:self];
        
    }
    else if ([keyPath isEqualToString:@"self.webView.estimatedProgress"]) {
        
        double estimatedProgress = [self.webView estimatedProgress];
        NSLog(@"AssetListViewController self.webView.estimatedProgress: %f", estimatedProgress);
    
  //      [self.progressIndicator setDoubleValue:self.webView.estimatedProgress];
        
    }
    else if ([keyPath isEqualToString:@"self.source.formattedCode"]) {
        if ([self.assetListViewer isVisible]) {
            [[self.webView mainFrame] loadHTMLString:self.source.formattedCode baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
        }
        
    }
    else if ([keyPath isEqualToString:@"self.assetArrayController.selectionIndexes"]) {
        
        if (self.assetArrayController.selectedObjects.count > 0) {
            Asset *asset = self.assetArrayController.selectedObjects[0];
            if ([asset.type isEqualToString:@"track"]) {
                [self.detailScrollView setDocumentView:self.trackDetailView];
                
            }
            else [self.detailScrollView setDocumentView:self.defaultDetailView];
            //       [self.trackDetailView setAutoresizingMask:NSViewWidthSizable];
            /*      NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.detailScrollView.documentView attribute:NSLayoutAttributeRight
             relatedBy:NSLayoutRelationEqual
             toItem:self.view
             attribute:NSLayoutAttributeRight
             multiplier:1.0f constant:-20.0f];
             [self.detailScrollView.contentView addConstraint:constraint]; */
            
            NSPoint newScrollOrigin;
            // assume that the scrollview is an existing variable
            if ([[self.detailScrollView documentView] isFlipped]) {
                newScrollOrigin=NSMakePoint(0.0,0.0);
            } else {
                newScrollOrigin=NSMakePoint(0.0,NSMaxY([[self.detailScrollView documentView] frame])
                                            -NSHeight([[self.detailScrollView contentView] bounds]));
            }
            CGPoint setOrigin = CGPointMake(newScrollOrigin.x , newScrollOrigin.y + 172.0f);
            [[self.detailScrollView documentView] scrollPoint:setOrigin];
            
        }
        if ((self.viewerMode) && ([self.assetListViewer isVisible])) [self updateFormattedCode:self];
        
    }
    else {
        if ((([keyPath isEqualToString:@"self.source"]) || ([keyPath isEqualToString:@"self.source.template"])) || ([keyPath isEqualToString:@"self.source.template.formatText"])) {
            if (!self.source) return;
            if ([self.assetArrayController.arrangedObjects count] > 0) {
                self.source.formattedCode = [TemplateController codeForTemplate:self.source.template.formatText withAssets:self.assetArrayController.arrangedObjects];
                //       [[self.webView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
            }
            else {
                self.source.formattedCode = @"";
                //       [[self.webView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
            }
            
            
            
        }
        if (([keyPath isEqualToString:@"self.source"]) || ([keyPath isEqualToString:@"self.source.fetchPredicate"])) {
            if (!self.source) return;
            
            if ([self.source.entity.name isEqualToString:@"BatchSource"]) {
                
                [self.assetArrayController setContent:[self.source.batchAssets array]];
            }
            else {
                [self.assetArrayController setFetchPredicate:self.source.fetchPredicate];
                NSString *entityName = self.source.fetchEntity;
                if (!entityName.length) entityName = @"Asset";
                [self.assetArrayController setEntityName:entityName];
                [self.assetArrayController fetch:self];
            }
            
            if ((self.source.filterString != nil) && (![self.source.filterString isEqualToString:@""])) {
                NSPredicate *predicate;
                if ((self.source.filterKey != nil) && (![self.source.filterKey isEqualToString:@""])) {
                    predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", self.source.filterKey, self.source.filterString];
                }
                else {
                    predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@", self.source.filterString];
                }
                [self.assetArrayController setFilterPredicate:predicate];
            }
            else [self.assetArrayController setFilterPredicate:nil];
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self updateFormattedCode:self];
            });
           
            
        }
        if (([keyPath isEqualToString:@"self.source.template"]) || ([keyPath isEqualToString:@"self.source.template.formatText"])) {
            [self updateFormattedCode:self];
            
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
    
    if ((self.source) && ([self.assetArrayController.arrangedObjects count] > 0)) {
        if (self.viewerMode) {
            if ([self.assetArrayController.selectedObjects count] > 0) {

                self.source.formattedCode = [TemplateController codeForTemplate:self.source.template.formatText withAssets:self.assetArrayController.selectedObjects];
            }
            else self.source.formattedCode = @"";
        }
        else self.source.formattedCode = [TemplateController codeForTemplate:self.source.template.formatText withAssets:self.assetArrayController.arrangedObjects];
    }
    else {
        self.source.formattedCode = @"";
    }
    
}

- (IBAction)viewerButtonPressed:(id)sender {
    [self.assetListViewer makeKeyAndOrderFront:self];
    [self updateFormattedCode:self];
}
- (IBAction)templatesButtonPressed:(id)sender {
    self.document.templateController.assetListView = self;
    [self.document.templatesPanel makeKeyAndOrderFront:self];
}
@end
