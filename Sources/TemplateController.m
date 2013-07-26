//
//  TemplateController.m
//  PraxPress
//
//  Created by Elmer on 7/21/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "TemplateController.h"

@implementation TemplateController


- (NSArray *)keyPathsToObserve {return @[@"self.templatesController.selectionIndexes", @"self.assetListView", @"self.assetListView.source", @"self.assetListView.source.template"];}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"TemplateController init");
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
        
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"TemplateController awakeFromNib");
    if (!self.awake) {
        self.awake = TRUE;
        
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    self.assetListView = nil;
    
}
- (void)dealloc {
    NSLog(@"TemplateController dealloc");
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {  
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



+ (NSString *)codeForTemplate:(NSString *)formatText withAssets:(NSArray *)assets {
    
    NSMutableString *code = [[NSMutableString alloc] initWithCapacity:1024];
    if (([assets count] > 0) &&  ([formatText length] > 0)){
        for (Asset *asset in assets) {
            [code appendString:[TemplateController stringWithTemplate:formatText forAsset:asset]];
        }
    }
    //   NSLog(@"code: %@", code);
    return code;
}

+ (NSString *)stringWithTemplate:(NSString *)template forAsset:(Asset *)asset {
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:1024];
    NSRange foundRange;
    NSRange sourceRange;
    sourceRange.location = 0;
    sourceRange.length = [template length];
    BOOL flag = FALSE;
    while (flag == FALSE) {
        foundRange = [template rangeOfString:@"$$$" options:0 range:sourceRange];
        if (foundRange.location == NSNotFound) {
            flag = TRUE;
            break;
        }
        
        sourceRange.length = (foundRange.location - sourceRange.location);
        [string appendString:[template substringWithRange:sourceRange]];
        
        sourceRange.location = (foundRange.location + 3);
        sourceRange.length = ([template length] - sourceRange.location);
        foundRange = [template rangeOfString:@"$$$" options:0 range:sourceRange];
        if (foundRange.location == NSNotFound) {
            flag = TRUE;
            
        }
        else {
            sourceRange.length = (foundRange.location - sourceRange.location);
            
            NSString *key = [template substringWithRange:sourceRange];
            NSString *value = [TemplateController valueOfItem:asset asStringForKey:key];
            if ([value length] > 0) [string appendString:value];
            sourceRange.location = (foundRange.location + 3);
            sourceRange.length = ([template length] - sourceRange.location);
        }
    }
    [string appendString:[template substringWithRange:sourceRange]];
    return string;
}

+ (NSString *)valueOfItem:(Asset *)item asStringForKey:(NSString *)key {
    NSEntityDescription *entity = [item entity];
    NSDictionary *attributesByName = [entity attributesByName];
    NSAttributeDescription *attribute = attributesByName[key];
    if (!attribute) {
        return @"---No Such Attribute Key---";
    }
    else if ([attribute attributeType] == NSUndefinedAttributeType) {
        return @"---Undefined Attribute Type---";
    }
    else if ([attribute attributeType] == NSStringAttributeType) {
        return [item valueForKey:key];
    }
    else if ([attribute attributeType] < NSDateAttributeType) {
        return [[item valueForKey:key] stringValue];
    }
    // add more "else if" code as desired for other types
    
    else {
        return @"---Unacceptable Attribute Type---";
    }
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
                templates[template.name] = template.formatText;
            }
            
            NSArray *importTemplates = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
            for (NSDictionary *importTemplate in importTemplates) {
                NSString *text = templates[importTemplate[@"name"]];
                if (text.length <= 0) {
                    Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.document.managedObjectContext];
                    template.name = importTemplate[@"name"];
                    template.formatText = importTemplate[@"formatText"];
                    [self.templatesController rearrangeObjects];
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
                [templates addObject:@{@"name":template.name, @"formatText":template.formatText}];
            }
            [NSKeyedArchiver archiveRootObject:templates toFile:panel.URL.path];
        }
    }];
}

- (IBAction)addTemplate:(id)sender {
    Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.document.managedObjectContext];
    template.name = @"NEW Template";
    template.formatText = @"<div>$$$title$$$</div>";
    [self.templatesController rearrangeObjects];
    [self.tableView scrollRowToVisible:self.templatesController.selectionIndex];
    
}

- (IBAction)duplicate:(id)sender {
    if (self.templatesController.selectedObjects.count > 0) {
        Template *selectedTemplate = self.templatesController.selectedObjects[0];
        
        Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.document.managedObjectContext];
        
        template.name = [NSString stringWithFormat:@"%@ COPY", selectedTemplate.name];
        template.formatText = selectedTemplate.formatText;
        [self.templatesController rearrangeObjects];
        [self.tableView scrollRowToVisible:self.templatesController.selectionIndex];
    }
}

@end
