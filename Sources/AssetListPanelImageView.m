
#import "AssetListPanelImageView.h"

@implementation AssetListPanelImageView

- (id)initWithCoder:(NSCoder *)coder {

    self=[super initWithCoder:coder];
    if ( self ) {

        [self registerForDraggedTypes:@[@"org.ElmerCat.PraxPress.Source"]];
    }
    return self;
}

#pragma mark - Destination Operations

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info {

    if ([[info draggingPasteboard] canReadItemWithDataConformingToTypes:@[@"org.ElmerCat.PraxPress.Source"]]) {
        
        self.highlight=YES;
        
        [self setNeedsDisplay: YES];
        [info enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
                                          forView:self
                                          classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
                                    searchOptions:nil
                                       usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
                                           [draggingItem setDraggingFrame:self.bounds contents:[[[draggingItem imageComponents] objectAtIndex:0] contents]];
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
    return [[info draggingPasteboard] canReadItemWithDataConformingToTypes:@[@"org.ElmerCat.PraxPress.Source"]];

}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)info {
    
    AssetListViewController *controller;
    if ([[info draggingSource] isKindOfClass:[AssetListPanelImageView class]]) controller = [[info draggingSource] controller];
    if ([self isEqual:controller]) return NO;
    
    NSURL *objectURL = [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:@"org.ElmerCat.PraxPress.Source"]];
    NSManagedObjectID *objectID = [self.controller.document.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectURL];
    Source *source = (Source *)[self.controller.document.managedObjectContext existingObjectWithID:objectID error:NULL];
    
    [self.controller.document.sourceController moveSource:source fromController:controller toController:self.controller];
    
    
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

    if (self.controller.isAssociatedPane) return;
    
//    NSURL *sourceURL = [self.controller.source.objectID URIRepresentation];
// 	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sourceURL];
    NSPasteboardItem *pasteboardItem = [NSPasteboardItem new];
    
    [pasteboardItem setDataProvider:self forTypes:self.sourceDraggingTypes];
    
//	[pasteboardItem setData:data forType:@"org.ElmerCat.PraxPress.Source"];

    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pasteboardItem];
    NSRect draggingRect = self.bounds;
    NSImage *dragImage = [[NSImage alloc] initWithData:[self.superview dataWithPDFInsideRect:[self.superview bounds]]];
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
    
    
    if ( [type compare: NSPasteboardTypeTIFF] == NSOrderedSame ) {
        
        //       [sender setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
        
    } else if ( [type compare: NSPasteboardTypePDF] == NSOrderedSame ) {
        
        //            [sender setData:[self.view dataWithPDFInsideRect:[self.view bounds]] forType:NSPasteboardTypePDF];
        
    } else if ( [type compare:@"org.ElmerCat.PraxPress.Source"] == NSOrderedSame ) {
        NSURL *sourceURL = [self.controller.source.objectID URIRepresentation];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sourceURL];
        [item setData:data forType:@"org.ElmerCat.PraxPress.Source"];

    } else if ( [type compare:@"public.image"] == NSOrderedSame ) {
        
        NSLog(@"%@", type);
        
    } else if ( [type compare:@"public.utf8-plain-text"] == NSOrderedSame ) {
        
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type];
        
    } else if ( [type compare:@"public.text"] == NSOrderedSame ) {
        
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type];
        
    } else if ( [type compare:@"public.html"] == NSOrderedSame ) {
        
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type];
        
    } else if ( [type compare:NSPasteboardTypeString] == NSOrderedSame ) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type];
        
    } else if ( [type compare:NSPasteboardTypeString] == NSOrderedSame ) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type];
        
    } else if ( [type compare:NSPasteboardTypeHTML] == NSOrderedSame ) {
        [item setString:[NSString stringWithFormat:@"%@", self.controller.source.name] forType:type];
        
    }
    else {
        
        NSLog(@"%@", type);
    }
    
    
}

@end
