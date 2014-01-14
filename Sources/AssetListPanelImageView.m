
#import "AssetListPanelImageView.h"

@implementation AssetListPanelImageView

- (id)initWithCoder:(NSCoder *)coder {

    self=[super initWithCoder:coder];
    if ( self ) {

        [self registerForDraggedTypes:@[@"org.ElmerCat.PraxPress.Source", @"org.ElmerCat.PraxPress.AssetList"]];
    }
    return self;
}

#pragma mark - Destination Operations

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info {
    if (self.controller.isAssociatedPane) return NSDragOperationNone;
    
    if ([[info draggingSource] isKindOfClass:[AssetListPanelImageView class]]) {
        AssetListViewController *controller = [[info draggingSource] controller];
        if (controller == self.controller) return NSDragOperationNone;
        if (controller.isAssociatedPane) return NSDragOperationNone;
    }

    if ([[info draggingPasteboard] canReadItemWithDataConformingToTypes:@[@"org.ElmerCat.PraxPress.Source", @"org.ElmerCat.PraxPress.AssetList"]]) {
        
        self.highlight=YES;
        
        [self setNeedsDisplay: YES];
        [info enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                          forView:self
                                          classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
                                    searchOptions:nil
                                       usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
                                           [draggingItem setDraggingFrame:self.controller.view.bounds contents:[[[draggingItem imageComponents] objectAtIndex:0] contents]];
                                       }];
        
        return NSDragOperationMove;
    }
    
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {

    self.highlight=NO;
    
    [self setNeedsDisplay: YES];
}

-(void)drawRect:(NSRect)rect {

    [super drawRect:rect];
    
    if (self.controller.isSelectedPane) {

    }
    if (self.highlight) {
        [[NSColor grayColor] set];
        [NSBezierPath setDefaultLineWidth: 5];
        [NSBezierPath strokeRect: rect];
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)info {

    self.highlight=NO;
    
    [self setNeedsDisplay: YES];
    return [[info draggingPasteboard] canReadItemWithDataConformingToTypes:@[@"org.ElmerCat.PraxPress.Source", @"org.ElmerCat.PraxPress.AssetList"]];

}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)info {
    
    AssetListViewController *controller;
    if ([[info draggingSource] isKindOfClass:[AssetListPanelImageView class]]) controller = [[info draggingSource] controller];
    if ([self.controller isEqual:controller]) return NO;
    
//    controller = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:@"org.ElmerCat.PraxPress.AssetList"]];
    
    [self.controller.document.sourceController movePane:controller.assetListView toPane:self.controller.assetListView];
    
    return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame; {
    /*------------------------------------------------------
       delegate operation to set the standard window frame
    --------------------------------------------------------*/
        //get window frame size
    NSRect ContentRect=self.window.frame;
    
        //set it to the image frame size
    ContentRect.size=[[self image] size];
    
    return [NSWindow frameRectForContentRect:ContentRect styleMask: [window styleMask]];
};

#pragma mark - Source Operations

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            return (NSDragOperationCopy + NSDragOperationMove);
            break;
    }
}

- (NSArray *)sourceDraggingTypes {
    return @[@"org.ElmerCat.PraxPress.Source",
             @"org.ElmerCat.PraxPress.AssetList",
             @"public.utf8-plain-text",
             @"public.html",
             @"public.text",
             @"public.file-url",
           //  @"public.image",
          //   @"public.jpeg",
             @"public.tiff",
           //  @"public.png",
           //  @"com.adobe.pdf",
             NSPasteboardTypeString,
             NSPasteboardTypeHTML];
    
}

- (void)mouseDown:(NSEvent*)event {

//    if (self.controller.isAssociatedPane) return;
    
//    NSURL *sourceURL = [self.controller.source.objectID URIRepresentation];
// 	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sourceURL];
    NSPasteboardItem *pasteboardItem = [NSPasteboardItem new];
    
    [pasteboardItem setDataProvider:self forTypes:self.sourceDraggingTypes];
    
//	[pasteboardItem setData:data forType:@"org.ElmerCat.PraxPress.Source"];

    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pasteboardItem];
    NSRect draggingRect = [self.controller.view bounds];
    draggingRect.origin.x -= self.frame.origin.x;
    draggingRect.origin.y -= self.frame.origin.y;
    NSImage *dragImage = [[NSImage alloc] initWithData:[self.superview dataWithPDFInsideRect:[self.controller.view bounds]]];
    [draggingItem setDraggingFrame:draggingRect contents:dragImage];
    NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:@[draggingItem] event:event source:self];
    draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
    draggingSession.draggingFormation = NSDraggingFormationNone;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event  {
    return YES;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    NSLog(@"%@", type);
    
    
    if ([NSPasteboardTypeTIFF isEqualToString:type]) {
        
        //       [sender setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
        
    }
    else if ([NSPasteboardTypePDF isEqualToString:type]) {
        
        //            [sender setData:[self.view dataWithPDFInsideRect:[self.view bounds]] forType:NSPasteboardTypePDF];
        
    }
    else if ([@"org.ElmerCat.PraxPress.AssetList" isEqualToString:type]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.controller];
        [item setData:data forType:type]; }
    
    else if ([@"org.ElmerCat.PraxPress.Source" isEqualToString:type]) {
        NSURL *sourceURL = [self.controller.source.objectID URIRepresentation];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sourceURL];
        [item setData:data forType:type]; }
    
    else if ([@"public.utf8-plain-text" isEqualToString:type]) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type]; }
    else if ([@"public.text" isEqualToString:type]) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type]; }
    else if ([@"public.html" isEqualToString:type]) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type]; }
    else if ([NSPasteboardTypeString isEqualToString:type]) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type]; }
    else if ([NSPasteboardTypeHTML isEqualToString:type]) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type]; }
    else {
        
        NSLog(@"%@", type);
    }
    
    
}

@end
