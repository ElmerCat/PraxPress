//
//  WidgetViewController.m
//  PraxPress
//
//  Created by Elmer on 12/11/13.
//  Copyright (c) 2013 ElmerCat. All rights reserved.
//

#import "WidgetViewController.h"

@implementation WidgetViewController

- (NSArray *)textChoices {
    return @[@"Title", @"URI"];
}
- (NSArray *)textOptions {
    return @[@"Default", @"Upper Case", @"Lower Case", @"Capitalize"];
}


- (NSArray *)playerTypes {
    return @[@{@"key" : @"HTML5", @"value" : @"HTML5 Player"},
             @{@"key" : @"flash", @"value" : @"Standard Flash Player"},
             @{@"key" : @"artwork", @"value" : @"Artwork Flash Player"},
             @{@"key" : @"tiny", @"value" : @"Tiny Flash Player"}];
}

- (NSArray *)imageOptions {
    return @[@{@"key" : @"", @"value" : @"Original Size"},
             @{@"key" : @"t500x500", @"value" : @"500 x 500"},
             @{@"key" : @"crop", @"value" : @"400 x 400"},
             @{@"key" : @"t300x300", @"value" : @"300 x 300"},
             @{@"key" : @"large", @"value" : @"100 x 100"},
             @{@"key" : @"t67x67", @"value" : @"67 x 67"},
             @{@"key" : @"badge", @"value" : @"47 x 47"},
             @{@"key" : @"small", @"value" : @"32 x 32"},
             @{@"key" : @"tiny", @"value" : @"20 x 20"},
             @{@"key" : @"mini", @"value" : @"16 x 16"}];
}

+ (NSSet *)keyPathsForValuesAffectingPlayerHeightEditable {return [NSSet setWithObject:@"self.playerTypeIndex"]; }
- (BOOL)playerHeightEditable {
    if (self.playerTypeIndex > 1) return NO;
    else return YES;
}

- (void)awakeFromNib{
    if (!self.awake) {
        self.awake = TRUE;
        NSLog(@"WidgetViewController awakeFromNib");
        
        for (NSString *keyPath in self.keyPathsToObserve) [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:0];
  //      [self.imageOptionsController setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"key" ascending:YES]]];
        
    }


}
- (void)dealloc {
    for (NSString *keyPath in self.keyPathsToObserve) [self removeObserver:self forKeyPath:keyPath];
}

- (NSArray *)keyPathsToObserve {return @[@"self.widgetKeyString",
                                         @"self.widgetOptionString",
                                         @"self.widget.editingString"];}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"Widget observeValueForKeyPath:%@\nobject:%@\nchange:%@\ncontext:%@", keyPath, object, change, context);

    if ([keyPath isEqualToString:@"self.widgetKeyString"]) {
        if ([self.widgetKeyString isEqualToString:@"image"]) {
            self.optionIndex = 1;
        }
        else if ([self.widgetKeyString isEqualToString:@"player"]) {
            self.optionIndex = 2;
        }
        else self.optionIndex = 0;
        return;
    }
    if ([keyPath isEqualToString:@"self.widgetOptionString"]) {
        if ([self.widgetKeyString isEqualToString:@"image"]) {
            self.imageOptionIndex = 0;
            self.width = @"";
            self.track_height = @"";
            if (!self.widgetOptionString.length) return;
            
            NSString *value = [Widget stringValueForOption:@"size" inString:self.widgetOptionString];
            if (value && value.length) {
                NSInteger index = 0;
                for (NSDictionary *option in self.imageOptions) {
                    if ([value isEqualToString:option[@"key"]]) {
                        self.imageOptionIndex = index;
                        break;
                    }
                    index++;
                }
            }
            value = [Widget stringValueForOption:@"width" inString:self.widgetOptionString];
            if (value && value.length) self.width = value;
            value = [Widget stringValueForOption:@"height" inString:self.widgetOptionString];
            if (value && value.length) self.track_height = value;
            
        }
        else if ([self.widgetKeyString isEqualToString:@"player"]) {
            self.playerTypeIndex = 0;
            
            for (NSString *option in [Widget playerStringOptions]) {
                NSString *value = [Widget stringValueForOption:option inString:self.widgetOptionString];
                if (value && value.length) {
                    [self setValue:value forKey:option];
                }
                else [self setValue:[Widget defaultPlayerStringOptions][option] forKey:option];
            }
            NSInteger index = 0;
            for (NSDictionary *option in self.playerTypes) {
                if ([self.type isEqualToString:option[@"key"]]) {
                    self.playerTypeIndex = index;
                    break;
                }
                index++;
            }

            NSString *value = [Widget stringValueForOption:@"width" inString:self.widgetOptionString];
            if (value && value.length) {
                [self setValue:value forKey:@"width"];
            }
            else self.width = [Widget defaultPlayerSizes][self.type][@"width"];
            
            if (self.playerHeightEditable) {
                for (NSString *option in @[@"track_height", @"playlist_height"]) {
                    value = [Widget stringValueForOption:option inString:self.widgetOptionString];
                    if (value && value.length) {
                        [self setValue:value forKey:option];
                    }
                    else [self setValue:[Widget defaultPlayerSizes][self.type][option] forKey:option];

                }
            }
            else if (self.playerTypeIndex == 2) { // artwork player
                self.track_height = self.width;
                self.playlist_height = self.width;
            }
            else {
                self.track_height = [Widget defaultPlayerSizes][self.type][@"track_height"];
                self.playlist_height = [Widget defaultPlayerSizes][self.type][@"playlist_height"];
            }
            
            for (NSString *option in [Widget playerBooleanOptions]) {
                [self setValue:[Widget defaultPlayerBooleanOptions][option] forKey:option];
            }
            if (!self.widgetOptionString.length) return;
            for (NSString *option in [Widget playerBooleanOptions]) {
                if ([self.widgetOptionString rangeOfString:[NSString stringWithFormat:@"%@=T", option] options:NSCaseInsensitiveSearch].length) {
                    [self setValue:@YES forKey:option];
                }
                if ([self.widgetOptionString rangeOfString:[NSString stringWithFormat:@"%@=F", option] options:NSCaseInsensitiveSearch].length) {
                    [self setValue:@NO forKey:option];
                }
            }
        }
        else {
            self.textOptionIndex = 0;
            if (!self.widgetOptionString.length) return;
            if ([self.widgetOptionString isEqualToString:@"u"]) {
                self.textOptionIndex = 1;
            }
            else if ([self.widgetOptionString isEqualToString:@"l"]) {
                self.textOptionIndex = 2;
            }
            else if ([self.widgetOptionString isEqualToString:@"c"]) {
                self.textOptionIndex = 3;
            }
        }
        
        
    }
    if ([keyPath isEqualToString:@"self.widget.editingString"]) {
        
        if (self.widgetFound) {
      //      self.widget.displayString = [Widget displayStringForEditingString:self.widget.editingString];
            
            NSMutableString *formatText = @"".mutableCopy;
            [formatText appendString:self.stringBeforeWidget];
            [formatText appendString:self.widget.editingString];
            [formatText appendString:self.stringAfterWidget];
            
            Template *template = self.document.templateController.templatesController.selectedObjects[0];
            template.formatText = formatText;
        }
    }
}

- (void)menuWillOpen:(NSMenu *)menu {
    [menu cancelTracking];
    
    self.widgetFound = NO;
    self.stringBeforeWidget = @"".mutableCopy;
    self.stringAfterWidget = @"".mutableCopy;

    NSMenuItem *item = [menu itemAtIndex:0];
    NSLog(@"%@",item.representedObject);
    self.widget = item.representedObject;
    
    NSArray *array = self.templateTokenField.objectValue;
    for (id object in array) {
        if (object == self.widget) self.widgetFound = YES;
        else if (self.widgetFound) [self.stringAfterWidget appendString:[Widget editingStringFromObject:object]];
        else [self.stringBeforeWidget appendString:[Widget editingStringFromObject:object]];
    }
    NSLog(@"self.stringBeforeWidget:%@",self.stringBeforeWidget);
    NSLog(@"self.stringAfterWidget:%@",self.stringAfterWidget);
    NSLog(@"widgetFound:%hhd",self.widgetFound);
    if (self.widgetFound) {
        self.widgetKeyString = self.widget.keyString;
        self.widgetOptionString = self.widget.optionString;
        self.widgetTextChoice = self.widget.displayString;
        
 //       dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
 //       dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self showWidgetViewPopover];
 //       });
    }
}

- (void)resizePopover {
    CGFloat height = 30;
    CGFloat width = 180;
    if ([self.widgetKeyString isEqualToString:@"image"]) {
        height = 52;
        width = 220;
    }
    else if ([self.widgetKeyString isEqualToString:@"player"]) {
        height = 230;
        width = 280;
    }
    [self.playerOptionBoxWidth setConstant:width];
    [self.playerOptionBoxHeight setConstant:height];
}

- (void)showWidgetViewPopover {
    NSPoint mousePoint = [self.document.templateController.panel mouseLocationOutsideOfEventStream];
    NSRect rect = NSMakeRect((mousePoint.x - 15), (mousePoint.y - 5), 1, 1);
    [self resizePopover];
    [self.popover showRelativeToRect:rect ofView:self.document.templateController.panel.contentView preferredEdge:NSMinYEdge];
}

- (void)popoverWillClose:(NSNotification *)notification {
    [self.colorColorWell deactivate];
    [self.themeColorWell deactivate];
    [[NSColorPanel sharedColorPanel]performClose:self];
    self.widgetFound = NO;
}

//- (void)popoverDidShow:(NSNotification *)notification {
//}

- (IBAction)closePopover:(id)sender {
    [self.popover performClose:sender];
}
- (IBAction)textKeySelected:(id)sender {
    self.widgetKeyString = [Widget keyStringFromDisplayString:self.widgetTextChoice];
    [self updateEditingString];
}

- (IBAction)optionSelected:(id)sender {
    if (self.optionIndex == 0) {
        self.widgetKeyString = @"title";
    }
    else if (self.optionIndex == 1) {
        self.widgetKeyString = @"image";
    }
    else if (self.optionIndex == 2) {
        self.widgetKeyString = @"player";
    }
    self.widgetOptionString = @"";
    [self resizePopover];
    [self updateEditingString];
    self.widgetTextChoice = [Widget displayStringForEditingString:self.widget.editingString];
}

- (IBAction)textOptionSelected:(id)sender {
    if (self.textOptionIndex == 1) self.widgetOptionString = @"u";
    else if (self.textOptionIndex == 2) self.widgetOptionString = @"l";
    else if (self.textOptionIndex == 3) self.widgetOptionString = @"c";
    else self.widgetOptionString = @"";
    [self updateEditingString];
}

- (IBAction)imageOptionSelected:(id)sender {
    NSMutableString *options = @"".mutableCopy;
    NSDictionary *option = self.imageOptions[self.imageOptionIndex];
    NSString *value = option[@"key"];
    if (value.length) [options appendFormat:@"size=%@", value];
    if (self.width.length) [options appendFormat:@" width=%@", self.width];
    if (self.track_height.length) [options appendFormat:@" height=%@", self.track_height];
    NSRange trim = [options rangeOfString:@" "];
    if (trim.length && (trim.location == 0)) {
        [options deleteCharactersInRange:trim];
    }
    self.widgetOptionString = options;
    [self updateEditingString];
}

- (IBAction)playerTypeSelected:(id)sender {
    self.type = self.playerTypes[self.playerTypeIndex][@"key"];
    for (NSString *option in [Widget playerSizeOptions]) {
        [self setValue:[Widget defaultPlayerSizes][self.type][option] forKey:option];
    }
    [self playerOptionSelected:sender];
}

- (IBAction)playerOptionSelected:(id)sender {
    NSMutableString *options = @"".mutableCopy;
    
    if (self.playerTypeIndex == 2) { // artwork player height = width
        self.track_height = self.width;
        self.playlist_height = self.width;
    }
    for (NSString *option in [Widget playerStringOptions]) {
        NSString *value = [self valueForKey:option];
        if (value && value.length) {
            if (![value isEqualToString:[Widget defaultPlayerStringOptions][option]]) {
                [options appendFormat:@" %@=%@", option, [self valueForKey:option]];
            }
        }
    }
    if (![self.width isEqualToString:[Widget defaultPlayerSizes][self.type][@"width"]]) {
        [options appendFormat:@" width=%@", self.width];
    }
    if (self.playerHeightEditable) {
        for (NSString *option in @[@"track_height", @"playlist_height"]) {
            NSString *value = [self valueForKey:option];
            if (value && value.length) {
                if (![value isEqualToString:[Widget defaultPlayerSizes][self.type][option]]) {
                    [options appendFormat:@" %@=%@", option, [self valueForKey:option]];
                }
            }
        }
    }
    
    for (NSString *option in [Widget playerBooleanOptions]) {
        if ([[self valueForKey:option] boolValue] && (![[Widget defaultPlayerBooleanOptions][option] boolValue])) {
            [options appendFormat:@" %@=T", option];
        }
        else if ((![[self valueForKey:option] boolValue]) && [[Widget defaultPlayerBooleanOptions][option] boolValue]) {
            [options appendFormat:@" %@=F", option];
        }
    }

    NSRange trim = [options rangeOfString:@" "];
    if (trim.length && (trim.location == 0)) {
        [options deleteCharactersInRange:trim];
    }
    self.widgetOptionString = options;
    [self updateEditingString];
}

- (void)updateEditingString {
    NSMutableString *editingString = [Widget marker].mutableCopy;
    [editingString appendString:self.widgetKeyString];
    if (self.widgetOptionString.length) [editingString appendFormat:@"[%@]", self.widgetOptionString];
    [editingString appendString:[Widget marker]];
    self.widget.editingString = editingString;
}

@end
