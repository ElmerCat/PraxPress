//
//  TemplateController.m
//  PraxPress
//
//  Created by John Canfield on 9/16/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "TemplateController.h"

@implementation TemplateController
@synthesize startingFormatText;
@synthesize blockFormatText;
@synthesize endingFormatText;
@synthesize generatedCodeText;
+ (NSSet *)keyPathsForValuesAffectingGeneratedCode {
    return [NSSet setWithObjects:@"self.assetBatchEditController.arrangedObjects", @"self.assetsController.selectedObjects", @"startingFormatText", @"blockFormatText", @"endingFormatText", nil];
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
        //                        object:[[document managedObjectContext] undoManager]];
    }
    return self;
}



- (void)awakeFromNib {
    
    NSLog(@"TemplateController awakeFromNib");
    [self addObserver:self forKeyPath:@"self.assetsController.selectedObjects" options:NSKeyValueObservingOptionNew context:0];
    [self addObserver:self forKeyPath:@"self.assetBatchEditController.arrangedObjects" options:NSKeyValueObservingOptionNew context:0];
    
 
    NSDictionary *templateDefaults = @{@"templates":@[@{@"name":@"titles", @"startingFormatText":@"Titles\n", @"blockFormatText":@"$$$title$$$\n", @"endingFormatText":@"\n...PraxPress...\n"}]};
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:templateDefaults];
    
    
    
    [generatedCodeText setStringValue:@"Julie d'Prax"];
    
    //   [self.assetBatchEditTable registerForDraggedTypes:[NSArray arrayWithObjects:PraxItemsDropType, nil]];
    //   [self.assetBatchEditTable setSortDescriptors:self.batchSortDescriptors];
    
}

-(void)dealloc {
    NSLog(@"dealloc TemplateController");
    [self removeObserver:self forKeyPath:@"self.assetsController.selectedObjects"];
    [self removeObserver:self forKeyPath:@"self.assetBatchEditController.arrangedObjects"];
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (([keyPath isEqualToString:@"self.assetsController.selectedObjects"]) || ([keyPath isEqualToString:@"self.assetBatchEditController.arrangedObjects"])) {
        [self updateGeneratedCode];
        
    }
    else {
        NSLog(@"Template observeValueForKeyPath:%@ ofObject:%@ change:%@ context:?", keyPath, object, change);

    }
}

- (void)textDidChange:(NSNotification *)aNotification {
    [self updateGeneratedCode];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self updateGeneratedCode];
}

- (void)updateGeneratedCode {
    
    NSMutableString *code = [[NSMutableString alloc] initWithCapacity:1024];
    if (([[self.startingFormatText string] length] > 0) && ([[self.assetsController selectedObjects] count] > 0)){
        [code appendString:[self stringWithTemplate:[self.startingFormatText string] forAsset:[self.assetsController selectedObjects][0]]];
    }
    
    NSArray *assets = [self.assetBatchEditController arrangedObjects];
    if (([assets count] > 0) &&  ([[self.blockFormatText string] length] > 0)){
        for (Asset *asset in assets) {
            [code appendString:[self stringWithTemplate:[self.blockFormatText string] forAsset:asset]];
        }
    }
    
    if (([[self.endingFormatText string] length] > 0) && ([[self.assetsController selectedObjects] count] > 0)) {
        [code appendString:[self stringWithTemplate:[self.endingFormatText string] forAsset:[self.assetsController selectedObjects][0]]];
    }
    
    //   NSLog(@"code: %@", code);
    
    [generatedCodeText setStringValue:[code description]];
    
    //    [[self.previewWebView mainFrame] loadHTMLString:code baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    //    [self.previewFrameWindow makeKeyAndOrderFront:self];
}

- (NSString *)stringWithTemplate:(NSString *)template forAsset:(Asset *)asset {
    
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
            NSString *value = [self valueOfItem:asset asStringForKey:key];
            if ([value length] > 0) [string appendString:value];
            sourceRange.location = (foundRange.location + 3);
            sourceRange.length = ([template length] - sourceRange.location);
        }
    }
    [string appendString:[template substringWithRange:sourceRange]];
    return string;
}

- (NSString *)valueOfItem:(Asset *)item asStringForKey:(NSString *)key {
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



- (IBAction)preview:(id)sender {
    
    [[self.previewWebView mainFrame] loadHTMLString:[self.generatedCodeText stringValue] baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    [self.previewFrameWindow makeKeyAndOrderFront:self];
}


@end
