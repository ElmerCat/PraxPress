//
//  SourceInfoPanel.m
//  PraxPress
//
//  Created by Elmer on 11/21/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "SourceInfoPanel.h"

@interface SourceInfoPanel ()

@end

@implementation SourceInfoPanel

- (NSArray *)keyPathsToObserve {return @[@"self.assetListViewController.source"];}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        NSLog(@"SourceInfoPanel initWithWindowNibName:");
        
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
    }
    return self;
}


- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self.sourceNameField selectText:self];
    self.assetListViewController.sourceInfoPanelVisible = YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    self.assetListViewController.sourceInfoPanelVisible = NO;
}

- (void)awakeFromNib {
    NSLog(@"SourceInfoPanel awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        
        
        NSMutableArray *rowTemplates = [@[[[PraxPredicateEditorRowTemplate alloc] initWithCompoundTypes:@[@2, @1, @0]]] mutableCopy];
        
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"accountType"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"type"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithStringAttributeType] forAttributeType:NSStringAttributeType]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"sharing"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"track_type"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithDateAttributeType] forAttributeType:NSDateAttributeType]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithNumberAttributeType] forAttributeType:NSInteger64AttributeType]];
        
        self.predicateEditor.rowTemplates = rowTemplates;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSRuleEditorRowsDidChangeNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          
                                                          NSLog(@"SourceInfoPanel NSRuleEditorRowsDidChangeNotification");
                                                          
                                                          [self sizePanelForSource];
                                                          
                                                      }];
        [self.requiredTagsField setDelegate:self.assetListViewController.document.tagController];
        [self.excludedTagsField setDelegate:self.assetListViewController.document.tagController];
    }
}

- (void)sizePanelForSource {

    NSRect panelFrame = self.window.frame;
    panelFrame.origin.y += panelFrame.size.height;
    CGFloat extraHeight = (panelFrame.size.height - self.panelBoxHeight.constant);
    if ([self.source.type isEqualToString:@"SearchSource"]) {
        NSInteger rowCount = self.predicateEditor.numberOfRows;
        self.panelBoxHeight.constant = (rowCount * 25) + 75;
    }
    else if ([self.source.type isEqualToString:@"AssetSource"]) {
        self.panelBoxHeight.constant = 136;
    }
    else {
        self.panelBoxHeight.constant = 36;
    }
    panelFrame.size.height = (self.panelBoxHeight.constant + extraHeight);
    panelFrame.origin.y -= panelFrame.size.height;
    [self.window setFrame:panelFrame display:YES animate:YES];
    
}

- (void)dealloc {
    NSLog(@"SourceInfoPanel dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.assetListViewController.source"]) {
        if (![self isWindowLoaded]) {
            [self showWindow:self];
        }
        
        self.source = self.assetListViewController.source;
        if ([self.source.type isEqualToString:@"AssetSource"]) {
            self.sourceNameEditable = FALSE;
        }
        else self.sourceNameEditable = TRUE;
            
        if ([self.window isVisible]) {
            [self showSourceInfoPanel];
        }

    }
}

- (void)showSourceInfoPanel {
    
    NSView *view;
    [self sizePanelForSource];
    
    if ([self.source.type isEqualToString:@"SearchSource"]) {
        if (!self.source.fetchPredicate) {
            self.source.fetchPredicate = self.source.defaultPredicate;
        }
        view = self.searchSourceInfoView;
    }
    else if ([self.source.type isEqualToString:@"AssetSource"]) {
        view = self.accountSourceInfoView;
    }
    else {
        view = self.defaultSourceInfoView;
    }
    
    if (self.panelBox.contentView != view) {
        [self.panelBox setContentView:view];
    }

    if (![self.window isVisible]) {
        NSRect panelFrame = self.window.frame;
        NSPoint origin = [self.assetListViewController.document.sourceController.documentWindow frame].origin;
        NSRect newFrame = [self.assetListViewController.popUpButton bounds];
        newFrame = [self.assetListViewController.popUpButton convertRect:newFrame toView:nil];
        origin.x += newFrame.origin.x;
        origin.y += newFrame.origin.y;
      //  origin.x -= panelFrame.size.width;
        origin.y -= panelFrame.size.height;
        origin.y += 100;
        panelFrame.origin = origin;
        [self.window setFrame:panelFrame display:NO animate:NO];
        [self showWindow:self];
    }
    else [self.window makeKeyAndOrderFront:self];
}

- (IBAction)updateFilter:sender {
    [self.assetListViewController updateFilter:sender];
}

- (IBAction)loginButtonPressed:(id)sender {
    
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:self.source.serviceAccount.accountType];
    if ([oauthAccounts count] > 0) {
        self.source.serviceAccount.oauthAccount = oauthAccounts[0];
    } else {
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.self.source.serviceAccount.accountType
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           NSRect screen = [[NSScreen mainScreen] frame];
                                           NSRect frame = {(screen.size.width/2), (screen.size.height/2), 0, 0};
                                           [self.authorizationPanel.animator setFrame:frame display:YES];
                                           [self.authorizationPanel makeKeyAndOrderFront:self];
                                           [[self.authorizationWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                           frame.origin.x = screen.origin.x + 200;
                                           frame.origin.y  = screen.origin.y + 100;
                                           frame.size.width = screen.size.width - 400;
                                           frame.size.height = screen.size.height - 200;
                                           [self.authorizationPanel.animator setFrame:frame display:YES];
                                       }];
        
    }
    
}

- (IBAction)clearTags:(id)sender {
    self.source.requiredTags = [NSSet setWithArray:@[]];
    self.source.excludedTags = [NSSet setWithArray:@[]];
    self.source.requireAllTags = 0;
}

@end
