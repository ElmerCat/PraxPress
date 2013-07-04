//
//  SourcePopovers.m
//  PraxPress
//
//  Created by Elmer on 6/28/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "SourcePopovers.h"

@interface SourcePopovers ()

@end

@implementation SourcePopovers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib {
    NSLog(@"SourcePopovers awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        
        NSArray *topLevelObjects;
        if ([[NSBundle mainBundle] loadNibNamed:@"SourcePopovers" owner:self topLevelObjects:&topLevelObjects]) {
            NSMutableDictionary *views = [@{} mutableCopy];
            for (id object in topLevelObjects) {
                if ([[object className] isEqualToString:@"NSView"])
                
                    views[[(NSView*)object identifier]] = object;
            }
            self.sourceAccountViews = views;
            
        }

        NSMutableArray *rowTemplates = [@[[[PraxPredicateEditorRowTemplate alloc] initWithCompoundTypes:@[@2, @1, @0]]] mutableCopy];
        
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithStringAttributeType] forAttributeType:NSStringAttributeType]];
        
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithNumberAttributeType] forAttributeType:NSInteger64AttributeType]];
        
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"sharing"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"track_type"]]];
        [rowTemplates addObject:[Asset predicateEditorRowTemplateForMultipleChoiceAttributeWithKeys:@[@"accountType"]]];
        
        [rowTemplates addObject:[Asset predicateEditorRowTemplateWithKeys:[Asset assetKeysWithDateAttributeType] forAttributeType:NSDateAttributeType]];
        
        
        self.searchPredicateEditor.rowTemplates = rowTemplates;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                          object:[NXOAuth2AccountStore sharedStore]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSLog(@"UpdateController NXOAuth2AccountStoreAccountsDidChangeNotification");
                                                          if (self.authorizationPanel.isVisible) {
                                                              [self.authorizationPanel close];
                                                          }
                                                      }];

     //   [self addObserver:self forKeyPath:@"self.source" options:NSKeyValueObservingOptionNew context:0];
    }
}

- (void)dealloc {
    NSLog(@"SourcePopovers dealloc");
   // [self removeObserver:self forKeyPath:@"self.source"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.source"]) {
        if (!self.source) return;
        
        NSView *view = nil;
        if ([self.source.entity.name isEqualToString:@"AccountSource"]) {
            view = self.sourceAccountViews[self.source.name];
        }
        else view = self.sourceAccountViews[self.source.entity.name];
        if (!view) {
            view = self.sourceAccountViews[@"Default"];
        }
        if (view) {
            if ([self.source.entity.name isEqualToString:@"SearchSource"]) {
                if (!self.source.fetchPredicate) {
                    self.source.fetchPredicate = self.source.defaultPredicate;
                }
            }
            
            [self.sourcePopoverScrollView setDocumentView:view];
            NSSize size = view.frame.size;
            size.height += 30;
            size.width += 30;
            [self.sourcePopover setContentSize:size];
        }
        
    }
}



/*-(void)popoverDidShow:(NSNotification *)notification {
    

}


- (void)popoverWillShow:(NSNotification *)notification {
    
}*/

- (void)showPopoverForSource:(Source *)source sender:(id)sender preferredEdge:(NSRectEdge)preferredEdge {
    
    self.source = source;
    NSView *view = nil;
    if ([source.entity.name isEqualToString:@"AccountSource"]) {
        view = self.sourceAccountViews[source.name];
    }
    else view = self.sourceAccountViews[source.entity.name];
    if (!view) {
        view = self.sourceAccountViews[@"Default"];
    }
    if (view) {
        if ([source.entity.name isEqualToString:@"SearchSource"]) {
            if (!source.fetchPredicate) {
                source.fetchPredicate = source.defaultPredicate;
            }
        }
        
        [self.sourcePopoverScrollView setDocumentView:view];
        NSSize size = view.frame.size;
        size.height += 30;
        size.width += 30;
        [self.sourcePopover showRelativeToRect:[(NSButton *)sender bounds] ofView:sender preferredEdge:preferredEdge];
        [self.sourcePopover setContentSize:size];
    }
    
    
}

- (IBAction)doneButtonPressed:(id)sender {
    [self.sourcePopover close];
    
}

- (IBAction)loginButtonPressed:(id)sender {
    
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:self.source.account.accountType];
    if ([oauthAccounts count] > 0) {
        self.source.account.oauthAccount = oauthAccounts[0];
    } else {
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:self.self.source.account.accountType
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
@end
