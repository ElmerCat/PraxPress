//
//  TemplateController.m
//  PraxPress
//
//  Created by John Canfield on 9/16/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "TemplateViewController.h"

@implementation TemplateViewController
+ (NSSet *)keyPathsForValuesAffectingGeneratedCode {
    return [NSSet setWithObjects:@"self.assetBatchEditController.arrangedObjects", @"self.assetsController.selectedObjects", @"formatText", nil];
}

- (id)init {
    self = [super init];
    if (self) {
        NSLog(@"TemplateController init");
        
        
        //       [[NSSound soundNamed:@"Start"] play];
        
        //        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        //       [notificationCenter addObserver:self
        //                              selector:@selector(tracksNotification:)
        //                                  name:tracksNotificationName object:nil];
        //     [notificationCenter addObserver:self
        //                          selector:@selector(undoNotification:)
        //                            name:NSUndoManagerCheckpointNotification
        //                        object:[[filesOwner managedObjectContext] undoManager]];
    }
    return self;
}



- (void)awakeFromNib {
    
    if (!self.awake) {
        self.awake = TRUE;
        
        NSLog(@"TemplateController awakeFromNib");
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"ShowTemplatesNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
            [self show:[aNotification object]];
        }];
    }
}

-(void)dealloc {
    NSLog(@"dealloc TemplateController");
    [self removeObserver:self forKeyPath:@"self.assetsController.selectedObjects"];
    [self removeObserver:self forKeyPath:@"self.assetBatchEditController.arrangedObjects"];
    
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    NSLog(@"controlTextDidChange TemplateController");
//        if( amDoingAutoComplete ){
  //          return;
    //    } else {
      //      amDoingAutoComplete = YES;
      //      [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
        //}
}


- (IBAction)show:(id)sender {
    [self.popover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    
    NSArray *completions = @[@"$$$title$$$", @"$$$uri$$$"];

    return completions;
    
}

+ (NSString *)codeForTemplate:(NSString *)formatText withAssets:(NSArray *)assets {
    
    NSMutableString *code = [[NSMutableString alloc] initWithCapacity:1024];
    if (([assets count] > 0) &&  ([formatText length] > 0)){
                for (Asset *asset in assets) {
                    [code appendString:[TemplateViewController stringWithTemplate:formatText forAsset:asset]];
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
            NSString *value = [TemplateViewController valueOfItem:asset asStringForKey:key];
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
                    Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.filesOwner.managedObjectContext];
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

- (IBAction)duplicate:(id)sender {
    if (self.templatesController.selectedObjects.count > 0) {
        Template *selectedTemplate = self.templatesController.selectedObjects[0];
        
        Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.filesOwner.managedObjectContext];

        template.name = [NSString stringWithFormat:@"%@ COPY", selectedTemplate.name];
        template.formatText = selectedTemplate.formatText;
        [self.templatesController rearrangeObjects];
        [self.tableView scrollRowToVisible:self.templatesController.selectionIndex];
    }
}

- (IBAction)addTemplate:(id)sender {
    Template *template = [NSEntityDescription insertNewObjectForEntityForName:@"Template" inManagedObjectContext:self.filesOwner.managedObjectContext];
    template.name = @"NEW Template";
    template.formatText = @"<div>$$$title$$$</div>";
    [self.templatesController rearrangeObjects];
    [self.tableView scrollRowToVisible:self.templatesController.selectionIndex];
    
}


@end
