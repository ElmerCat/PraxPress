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
        // Add your subclass-specific initialization here.
        self.sourceSetup = 0;
        NSLog(@"Document init");
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
    
    NSManagedObject *source = [NSEntityDescription insertNewObjectForEntityForName:@"Source" inManagedObjectContext:moc];
    [source setValue:@"Services" forKey:@"name"];
    
    Account *account;
    NSManagedObject *service;
    
    for (NSString *name in @[@"WordPress", @"SoundCloud", @"YouTube", @"Flickr"]) {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc];
        account.accountType = name;
        
        service = [NSEntityDescription insertNewObjectForEntityForName:@"Service" inManagedObjectContext:moc];
        [service setValue:name forKey:@"name"];
        [service setValue:account forKey:@"account"];
        [service setValue:source forKey:@"parent"];
    }
    
    [moc processPendingChanges];
    [[moc undoManager] enableUndoRegistration];
    
    return self;
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
    
    [PraxTransformers load];
    
    [self.assetTableView setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES]]];
    
    // YouTube developer key = "AI39si7b1wiC17l1KoIAB1maTGrjfVfeKEzm6yRElmdBiOlcj75NFktrwd4oBdY2CS1j54hVPmnWhY9KGj9NaBul3BL_nk_Vsg"
    
    
    /* register our special protocol with webkit */
	[SpecialProtocol registerSpecialProtocol];
    

}

/*- (void)dealloc {
    NSLog(@"Document dealloc");
}*/

- (void)windowWillClose:(NSNotification *)notification {
//    NSLog(@"Document windowWillClose notification: %@", notification);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*- (void)windowDidBecomeMain:(NSNotification *)notification {
    if (self.sourceSetup < 2) {
        
        if ([self.sourceOutlineView numberOfRows] > 0) {
            self.sourceSetup += 1;
            [self.sourceOutlineView expandItem:[self.sourceOutlineView itemAtRow:0]];
         
        }
    }
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

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {return TRUE;}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {return TRUE;}

@end
