//
//  MultipleChangePopover.m
//  PraxPress
//
//  Created by Elmer on 12/5/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "MultipleChangePopover.h"

@interface MultipleChangePopover ()

@end

@implementation MultipleChangePopover

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        

    }
    return self;
}


- (void)awakeFromNib {
    
    self.trimBeginningMatchString = @"";
    self.trimEndMatchString = @"";
    self.addToBeginningString = @"";
    self.addToEndString = @"";
    self.findString = @"";
    self.replaceString = @"";
}

- (IBAction)modifyTitles:(id)sender {
    self.changeKey = @"title";
    [self showModifyTextPopover:sender];
}

- (IBAction)modifyPermalinks:(id)sender {
    self.changeKey = @"permalink";
    [self showModifyTextPopover:sender];
}

- (IBAction)modifyContents:(id)sender {
    self.changeKey = @"contents";
    [self showModifyTextPopover:sender];
}

- (void)showModifyTextPopover:(id)sender {
    [[NSSound soundNamed:@"Start"] play];
    [self resetChioces];
    self.controller = [(PraxButton *)sender controller];
    [self.viewBox setContentView:self.modifyTextView];
    [self.popover showRelativeToRect:[(NSButton *)sender bounds] ofView:(NSButton *)sender preferredEdge:NSMaxXEdge];
}

- (IBAction)modifyTags:(id)sender {
    self.changeKey = @"tags";
    [[NSSound soundNamed:@"Start"] play];
    self.removeTags = NO;
    self.addTags = NO;
    self.tagsToAdd = [NSMutableSet setWithCapacity:1];
    self.tagsToRemove = [NSMutableSet setWithCapacity:1];
    self.controller = [(PraxButton *)sender controller];
    [self.viewBox setContentView:self.modifyTagsView];
    [self.popover showRelativeToRect:[(NSButton *)sender bounds] ofView:(NSButton *)sender preferredEdge:NSMaxXEdge];
}

- (IBAction)mergeTags:(id)sender {
    
    [[(NSButton *)sender window] makeFirstResponder:nil];
    NSMutableSet *tags = [NSMutableSet setWithCapacity:1];
    for (Asset *asset in self.controller.assetArrayController.selectedObjects) {
        [tags unionSet:asset.tags];
    }
    self.tagsToAdd = tags;
}

- (IBAction)removeAllTags:(id)sender {
    [[(NSButton *)sender window] makeFirstResponder:nil];
    NSMutableSet *tags = [NSMutableSet setWithCapacity:1];
    for (Asset *asset in self.controller.assetArrayController.selectedObjects) {
        [tags unionSet:asset.tags];
    }
    self.tagsToRemove = tags;
}
- (IBAction)changeTags:(id)sender {
    NSMutableSet *tags = [NSMutableSet setWithCapacity:1];
    [[(NSButton *)sender window] makeFirstResponder:nil];
    for (Asset *asset in self.controller.assetArrayController.selectedObjects) {
        [tags setSet:asset.tags];
        if (self.removeTags) {
            [tags minusSet:self.tagsToRemove];
        }
        if (self.addTags) {
            [tags unionSet:self.tagsToAdd];
        }
        asset.tags = tags.copy;
    }
    [[NSSound soundNamed:@"Connect"] play];
    [self.popover performClose:sender];

}

- (void)resetChioces {
    self.trimFromBeginning = NO;
    self.addToBeginning = NO;
    self.findAndReplace = NO;
    self.trimFromEnd = NO;
    self.addToEnd = NO;
    self.pasteTrimmedFromBeginning = NO;
    self.pasteTrimmedFromEnd = NO;
}

- (IBAction)changeText:(id)sender {
    NSString *originalText;
    NSString *beginningTrimmedText;
    NSString *endTrimmedText;
    NSMutableString *newText;
    for (Asset *asset in self.controller.assetArrayController.selectedObjects) {
        newText = [@"" mutableCopy];
        
        originalText = [asset valueForKey:self.changeKey];

        if (self.trimFromBeginning) {
            NSInteger location;
            if (self.trimBeginningOption == 0) {
                location = self.trimBeginningCount;
            }
            else {
                if ([self.trimBeginningMatchString length] < 1) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:@"Trim from beginning match string cannot be blank"];
                    [alert runModal];
                    return;
                }
                NSRange range = [originalText rangeOfString:self.trimBeginningMatchString];
                if (range.location == NSNotFound) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:[NSString stringWithFormat:@"\"%@\"\n\nTrim from beginning match string not found in text:\n", self.trimBeginningMatchString]];
                    [alert setInformativeText:originalText];
                    [alert runModal];
                    return;
                }
                location = range.location;
                if (self.trimBeginningOption > 1) {
                    location += range.length;
                }
            }
            
            if ([originalText length] > location) {
                beginningTrimmedText = [originalText substringToIndex:location];
                originalText = [originalText substringFromIndex:location];
            }
            else {
                beginningTrimmedText = originalText;
                originalText = @"";
            }
        }
        
        if (self.addToBeginning) {
            if ([self.addToBeginningString length] < 1) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Add to beginning string cannot be blank"];
                [alert runModal];
                return;
            }
            [newText appendString:self.addToBeginningString];
            
        }
        
        [newText appendString:originalText];
        
        if (self.findAndReplace) {
            if ([self.findString length] < 1) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Find string cannot be blank"];
                [alert runModal];
                return;
            }
            NSRange range;
            NSStringCompareOptions options = 0;
            if (self.findCaseInsensitive) options |= NSCaseInsensitiveSearch;
            if (self.findReplaceOption == 1) options |= NSBackwardsSearch;
            range = [newText rangeOfString:self.findString options:options];
            if (range.location == NSNotFound) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:[NSString stringWithFormat:@"\"%@\"\n\nString not found in text:\n", self.findString]];
                [alert setInformativeText:newText];
                [alert runModal];
                return;
            }
            if (self.findReplaceOption == 2) {
                [newText replaceOccurrencesOfString:self.findString withString:self.replaceString options:nil range:NSMakeRange(0, [newText length])];
            }
            else {
                if (!self.replaceString) [newText deleteCharactersInRange:range];
                else [newText replaceCharactersInRange:range withString:self.replaceString];
            }
        }
        
        if (self.trimFromEnd) {
            NSInteger location;
            if (self.trimEndOption == 0) {
                location = ([newText length] - self.trimEndCount);
            }
            else {
                if ([self.trimEndMatchString length] < 1) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:@"Trim from end match string cannot be blank"];
                    [alert runModal];
                    return;
                }
                NSRange range = [newText rangeOfString:self.trimEndMatchString];
                if (range.location == NSNotFound) {
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:[NSString stringWithFormat:@"\"%@\"\n\nTrim from end match string not found in text:\n", self.trimEndMatchString]];
                    [alert setInformativeText:newText];
                    [alert runModal];
                    return;
                }
                location = range.location;
                if (self.trimEndOption > 1) {
                    location += range.length;
                }
            }
            if ([newText length] >= location) {
                endTrimmedText = [newText substringFromIndex:location];
                newText = [[newText substringToIndex:location] mutableCopy];
            }
            else {
                endTrimmedText = [newText copy];
                newText = [@"" mutableCopy];
            }
        }
        
        if (self.addToEnd) {
            if ([self.addToEndString length] < 1) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setMessageText:@"Add to end string cannot be blank"];
                [alert runModal];
                return;
            }
            [newText appendString:self.addToEndString];
        }
        
        if ((self.pasteTrimmedFromBeginning) && (self.trimFromBeginning)) {
            if (self.pasteBeginningOption == 0) [newText insertString:beginningTrimmedText atIndex:0];
            else [newText appendString:beginningTrimmedText];
        }
        
        if ((self.pasteTrimmedFromEnd) && (self.trimFromEnd)) {
            if (self.pasteEndOption == 0) [newText insertString:endTrimmedText atIndex:0];
            else [newText appendString:endTrimmedText];
            
        }
        
        [asset setValue:newText forKey:self.changeKey];
        
    }
   
    
    [[NSSound soundNamed:@"Error"] play];
    
    [self.popover performClose:sender];
}

@end
