//
//  Document.m
//  PraxPress
//
//  Created by John Canfield on 7/28/12.
//  Copyright (c) 2012 ElmerCat. All rights reserved.
//

#import "Document.h"
#import "SpecialProtocol.h"

@implementation Document


- (id)init
{
    self = [super init];
    if (self) {
        NSLog(@"Document init");
        self.templateSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    }
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"Document initWithType");
    self = [self init];
    [self setFileType:typeName];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    [moc processPendingChanges];
    [[moc undoManager] disableUndoRegistration];
    
    Account *account;
    
    for (NSString *name in @[@"WordPress", @"SoundCloud", @"YouTube", @"Flickr"]) {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
        account.accountType = name;
        
    }
    
    [moc processPendingChanges];
    [[moc undoManager] enableUndoRegistration];
    
    return self;
}

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError **)error {
//    NSLog(@"Document configurePersistentStoreCoordinatorForURL");
    NSMutableDictionary *options = nil;
    if (storeOptions != nil) options = [storeOptions mutableCopy];
    else options = [[NSMutableDictionary alloc] init];
    options[NSMigratePersistentStoresAutomaticallyOption] = [NSNumber numberWithBool:YES];
    options[NSInferMappingModelAutomaticallyOption] = [NSNumber numberWithBool:YES];
    return [super configurePersistentStoreCoordinatorForURL:url ofType:fileType modelConfiguration:configuration storeOptions:options error:error];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    [PraxTransformers loadForDocument:self];
    
    [self.assetsTableView setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES]]];
    
    // YouTube developer key = "AI39si7b1wiC17l1KoIAB1maTGrjfVfeKEzm6yRElmdBiOlcj75NFktrwd4oBdY2CS1j54hVPmnWhY9KGj9NaBul3BL_nk_Vsg"
    
    
    /* register our special protocol with webkit */
	[SpecialProtocol registerSpecialProtocol];
    

}

/*- (void)dealloc {
    NSLog(@"Document dealloc");
}*/

- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"Document windowWillClose notification: %@", notification);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
  //  [self.tagController windowWillClose:notification];
}

/*- (void)windowDidBecomeMain:(NSNotification *)notification {

 }*/


/* Called just before a webView attempts to load a resource.  Here, we look at the
 request and if it's destined for our special protocol handler we modify the request
 so that it contains an NSDictionary containing some information we want to share
 between the code in this file and the custom NSURLProtocol.  */
-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier
         willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
          fromDataSource:(WebDataSource *)dataSource {
    
    
    /* if this request will be handled by our special protocol... */
	if ( [SpecialProtocol canInitWithRequest:request] ) {
            
        /* create a NSDictionary containing any values we want to share between
         our webView/delegate object we are running in now and the protocol handler.
         Here, we'll put a referernce to ourself in there so we can access this
         object from the special protocol handler. */
		NSDictionary *specialVars = [NSDictionary dictionaryWithObject:self
                                                                forKey:[Document callerKey]];
        
        /* make a new mutable copy of the request so we can add a reference to our
         dictionary record. */
		NSMutableURLRequest *specialURLRequest = [request mutableCopy];
        
        /* call our category method to store away a reference to our dictionary. */
		[specialURLRequest setSpecialVars:specialVars];
		
        /* return the new modified request */
		return specialURLRequest;
        
	} else {
		return request;
	}
}



+ (NSString*) callerKey {
	return @"caller";
}
- (void)callbackFromSpecialRequest:(NSURLRequest *)request
{
	NSLog(@"callbackFromSpecialRequest %@ received %@", self, NSStringFromSelector(_cmd));
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSLog(@"validateToolbarItem: %@", toolbarItem);
    
    BOOL enable = NO;
    if ([[toolbarItem itemIdentifier] isEqual:NSToolbarShowColorsItemIdentifier]) {
        // We will return YES (enable the save item)
        // only when the document is dirty and needs saving
        enable = [self isDocumentEdited];
    } else if ([[toolbarItem itemIdentifier] isEqual:NSToolbarPrintItemIdentifier]) {
        // always enable print for this window
        enable = NO;
    }
    return enable;
}

- (IBAction)selectAccount:(id)sender {
    NSLog(@"selectAccount sender.tag: %ld", [(NSMenuItem *)sender tag]);
    NSString *accountType;
    NSInteger selectionIndex = [(NSMenuItem *)sender tag];
    switch (selectionIndex) {
        case 0:
            accountType = @"SoundCloud";
            break;
        case 1:
            accountType = @"WordPress";
            break;
        case 2:
            accountType = @"YouTube";
            break;
        case 3:
            accountType = @"Flickr";
            break;
        default:
            return;
            break;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @"accountType", accountType]];
    NSArray *matchingItems = [self.managedObjectContext executeFetchRequest:request error:nil];
    if ([matchingItems count] > 0) {
        Account *account = matchingItems[0];
        [(AccountViewController *)[self.accountViewPopover contentViewController] setRepresentedObject:account];
        [(AccountViewController *)[self.accountViewPopover contentViewController] setSelectionIndex:selectionIndex];
        [self.accountViewPopover showRelativeToRect:[[self.accountsToolbarButton view] bounds] ofView:[self.accountsToolbarButton view] preferredEdge:NSMaxXEdge];

    }

    
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {return TRUE;}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {return FALSE;}

/*- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    NSRect effectiveRect = proposedEffectiveRect;
   // effectiveRect.origin.x -= 2.0;
    if (splitView.isVertical) {
        effectiveRect.origin.x -= 10.0;
        effectiveRect.size.width += 10.0;
    }
    else {
        effectiveRect.origin.y -= 10.0;
        effectiveRect.size.height += 10.0;
    }
    

    
    return effectiveRect;
}*/

@end
