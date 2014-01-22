//
//  TemplateController.m
//  PraxPress
//
//  Created by Elmer on 7/21/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "TemplateController.h"

@implementation TemplateController


//- (NSArray *)keyPathsToObserve {return @[@"self.templatesController.selectionIndexes", @"self.assetListView", @"self.assetListView.source", @"self.assetListView.source.template"];}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"TemplateController init");
//        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"TemplateController awakeFromNib");
    if (!self.awake) {
        self.awake = YES;
//        [self.templatesController setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
        
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    self.assetListView = nil;
    
}
- (void)dealloc {
    NSLog(@"TemplateController dealloc");
//    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

/*- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"TemplateController observeValueForKeyPath: %@", keyPath);
    
    if ([keyPath isEqualToString:@"self.templatesController.selectionIndexes"]) {
        if (self.assetListView) {
            if (self.assetListView.source) {
                if ([self.templatesController.selectionIndexes count] > 0) {
                    Template *selectedTemplate = self.templatesController.selectedObjects[0];
                    if ([selectedTemplate isNotEqualTo:self.assetListView.source.template]) {
                        self.assetListView.source.template = selectedTemplate;
                    }
                        

                }
            }
        }
    }
    else {
        if (self.assetListView) {
            if (self.assetListView.source) {
                if (self.assetListView.source.template) {
                    Template *selectedTemplate = self.templatesController.selectedObjects[0];
                    if ([selectedTemplate isNotEqualTo:self.assetListView.source.template]) {
                        [self.templatesController setSelectedObjects:@[self.assetListView.source.template]];
                    }

                }
            }
        }
    }
}
*/


+ (NSString *)codeForTemplate:(NSString *)formatText withAssets:(NSArray *)assets {
    
    NSMutableString *code = @"".mutableCopy;
    if ([formatText respondsToSelector: @selector(length)]) {
        if (([assets count] > 0) &&  ([formatText length] > 0)){
            for (Asset *asset in assets) {
                [code appendString:[Widget stringWithTemplate:formatText forAsset:asset wordPress:NO]];
            }
        }
    }

    //   NSLog(@"code: %@", code);
    return code;
}



- (IBAction)importTemplates:(id)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowedFileTypes:@[@"prax-templates"]];
    [panel setExtensionHidden:YES];
    [panel setMessage:@"Import Templates from File"];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [panel URLs][0];
            
            NSMutableDictionary *templates = [NSMutableDictionary dictionaryWithCapacity:10];
            for (Template *template in self.templatesController.arrangedObjects) {
//                templates[template.name] = template.formatText;
            }
            
            NSArray *importTemplates = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
            for (NSDictionary *importTemplate in importTemplates) {
                NSString *text = templates[importTemplate[@"name"]];
                if (text.length <= 0) {
//                    Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.document.managedObjectContext];
//                    template.name = importTemplate[@"name"];
//                    template.formatText = importTemplate[@"formatText"];
//                    [self.templatesController rearrangeObjects];
                }
            }
        }
    }];
}

- (IBAction)exportTemplates:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"prax-templates"]];
    [panel setAllowsOtherFileTypes:YES];
    [panel setMessage:@"Export Templates to File"];
    [panel setNameFieldStringValue:@"Templates"];
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSMutableArray *templates = [NSMutableArray arrayWithCapacity:10];
            for (Template *template in self.templatesController.arrangedObjects) {
//                [templates addObject:@{@"name":template.name, @"formatText":template.formatText}];
            }
            [NSKeyedArchiver archiveRootObject:templates toFile:panel.URL.path];
        }
    }];
}

- (IBAction)addTemplate:(id)sender {
//    Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.document.managedObjectContext];
//    template.name = @"NEW Template";
//    template.formatText = @"<div>$$$title$$$</div>";
 //   [self.templatesController rearrangeObjects];
//    [self.tableView scrollRowToVisible:self.templatesController.selectionIndex];
    
}

- (IBAction)duplicate:(id)sender {
    if (self.templatesController.selectedObjects.count > 0) {
//        Template *selectedTemplate = self.templatesController.selectedObjects[0];
        
//        Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.document.managedObjectContext];
        
//        template.name = [NSString stringWithFormat:@"%@ COPY", selectedTemplate.name];
//        template.formatText = selectedTemplate.formatText;
//        [self.templatesController rearrangeObjects];
//        [self.tableView scrollRowToVisible:self.templatesController.selectionIndex];
    }
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedPosition < 100) return 100;
    else if (proposedPosition > (splitView.frame.size.width - 100)) return splitView.frame.size.width - 100;
    else return proposedPosition;
}


- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{

    NSMutableArray *returnTokens = @[].mutableCopy;
    for (id representedObject in tokens) {
        [returnTokens addObjectsFromArray:[Widget templateFormatArrayFromObject:representedObject]];
    }
    return returnTokens;
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
    return [[representedObject className] isEqualToString:@"Widget"];
    
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject {
    NSLog(@"menuForRepresentedObject:%@",representedObject);

    NSMenu *menu = [[NSMenu alloc] init];
    if ([menu respondsToSelector: @selector(_setHasPadding:onEdge:)])
    {
        [menu _setHasPadding: NO onEdge: 1];
        [menu _setHasPadding: NO onEdge: 3];
    }    NSMenuItem *item;
    
    item = [[NSMenuItem alloc] init];
    [item setView:self.widgetMenuView];
    [item setRepresentedObject:representedObject];
    [menu addItem:item];
    [menu setDelegate:self.widgetViewController];
    return menu;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {
    if ([[representedObject className] isEqualToString:@"Widget"]) {
        return NSDefaultTokenStyle;
    }
    return NSPlainTextTokenStyle;
}


- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {

    if ([[representedObject className] isEqualToString:@"Widget"]) {
        return [(Widget *)representedObject displayString];
    }
    else return representedObject;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
    
    if ([[representedObject className] isEqualToString:@"Widget"]) {
        return [(Widget *)representedObject editingString];
    }
    else return representedObject;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
    NSArray *array = [Widget templateFormatArrayFromObject:editingString];
    if (array.count == 1) return array[0];
    else {
        NSMutableString *string = @"".mutableCopy;
        for (id object in array) {
            if ([[object className] isEqualToString:@"Widget"]) {
                [string appendString:[(Widget *)object editingString]];
            }
            else [string appendString:object];
       }
        return string;
    }
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard {
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pboard writeObjects:@[[[NSValueTransformer valueTransformerForName:@"PraxWidgetStringTransformer"] reverseTransformedValue:objects]]];
    return YES;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
    
    
    NSRange occurance = [substring rangeOfString:@"$" options:NSBackwardsSearch range:NSMakeRange((substring.length - 1), 1)];
    if (occurance.length) {
        return @[[NSString stringWithFormat:@"%@%@", substring, [Widget newWidgetCompletionString]]];
    }
    else return @[];
}

@end
