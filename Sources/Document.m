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
        
        self.sharingTypes = @[@{@"name":@"Private", @"value":@"private"},
                              @{@"name":@"Public", @"value":@"public"}];
        
        self.trackSubTypes = @[@{@"name":@"(none)", @"value":@""},
                               @{@"name":@"Other", @"value":@"other"},
                               @{@"name":@"One Shot Sample", @"value":@"sample"},
                               @{@"name":@"Sound Effect", @"value":@"sound effect"},
                               @{@"name":@"Loop", @"value":@"loop"},
                               @{@"name":@"Stem", @"value":@"stem"},
                               @{@"name":@"Work in Progress", @"value":@"in progress"},
                               @{@"name":@"Demo", @"value":@"demo"},
                               @{@"name":@"Podcast", @"value":@"podcast"},
                               @{@"name":@"Spoken", @"value":@"spoken"},
                               @{@"name":@"Recording", @"value":@"recording"},
                               @{@"name":@"Live", @"value":@"live"},
                               @{@"name":@"Remix", @"value":@"remix"},
                               @{@"name":@"Original", @"value":@"original"}];
        
        self.playlistSubTypes = @[@{@"name":@"(none)", @"value":@""},
                                  @{@"name":@"Album", @"value":@"album"},
                                  @{@"name":@"Archive", @"value":@"archive"},
                                  @{@"name":@"Compilation", @"value":@"compilation"},
                                  @{@"name":@"Demo", @"value":@"demo"},
                                  @{@"name":@"EP/Single", @"value":@"ep single"},
                                  @{@"name":@"Other", @"value":@"other"},
                                  @{@"name":@"Project Files", @"value":@"project files"},
                                  @{@"name":@"Sample Pack", @"value":@"sample pack"},
                                  @{@"name":@"Showcase", @"value":@"showcase"}];
        
    }
    self.changedAssetFilterPredicate = [NSPredicate predicateWithFormat:@"sync_mode != 0"];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NSUserDefaultsDidChangeNotification" object:nil queue:nil usingBlock:^(NSNotification *aNotification){
        self.accountsSettings = [[NSUserDefaults standardUserDefaults] valueForKey:@"accounts"];
    }];
     

    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"Document initWithType");
    self = [self init];
    [self setFileType:typeName];
    
    [self.managedObjectContext processPendingChanges];
    [[self.managedObjectContext undoManager] disableUndoRegistration];
    
    self.interface = [NSEntityDescription insertNewObjectForEntityForName:@"Interface" inManagedObjectContext:self.managedObjectContext];
    
    [SourceController initWithType:typeName inManagedObjectContext:self.managedObjectContext];
    
    
    [self.managedObjectContext processPendingChanges];
    [[self.managedObjectContext undoManager] enableUndoRegistration];
    [self saveDocument:self];
    
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
    //    return @"Document";
    return @"PraxPress";
}

/*- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    
}*/

- (void)awakeFromNib {
    NSLog(@"Document awakeFromNib");
    if (!self.interface) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Interface"];
        NSError *error;
        self.interface = [self.managedObjectContext executeFetchRequest:request error:&error][0];
    }
    
    [PraxTransformers load];
    self.patsTransformer = [PraxAssetTagStringTransformer loadForDocument:self];
    
    // YouTube developer key = "AI39si7b1wiC17l1KoIAB1maTGrjfVfeKEzm6yRElmdBiOlcj75NFktrwd4oBdY2CS1j54hVPmnWhY9KGj9NaBul3BL_nk_Vsg"
    
    /* register our special protocol with webkit */
	[SpecialProtocol registerSpecialProtocol];
    
}

/*- (void)dealloc {
 NSLog(@"Document dealloc");
 }*/

- (void)setExportCodeDirectory:(NSURL *)exportCodeDirectory {
    _exportCodeDirectory = exportCodeDirectory;
    if (_exportCodeDirectory) {
        NSError *error;
        [exportCodeDirectory startAccessingSecurityScopedResource];
        self.interface.exportCodeDirectory = [_exportCodeDirectory bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        [_exportCodeDirectory stopAccessingSecurityScopedResource];
    }
    else self.interface.exportCodeDirectory = nil;
}

- (NSURL *)exportCodeDirectory {
    if ((!_exportCodeDirectory) && self.interface.exportCodeDirectory) {
        NSError *error;
        BOOL isStale;
        self.exportCodeDirectory = [NSURL URLByResolvingBookmarkData:self.interface.exportCodeDirectory options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
    }
    if (!_exportCodeDirectory) [self openExportCodeDirectory:self];
    return _exportCodeDirectory;
}

- (IBAction)openExportCodeDirectory:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:FALSE];
    [panel setCanChooseDirectories:TRUE];
    [panel setCanCreateDirectories:TRUE];
    [panel setMessage:@"Please Choose A Folder For Exported Code HTML Files"];
    if (_exportCodeDirectory) [panel setDirectoryURL:_exportCodeDirectory];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            self.exportCodeDirectory = panel.URL;
        }
    }];
}

- (void)windowWillClose:(NSNotification *)notification {
//    NSLog(@"Document windowWillClose notification: %@", notification);
//    self.exportCodeDirectory = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.sourceController windowWillClose:notification];
    [self.templatesPanel performClose:self];
    //  [self.tagController windowWillClose:notification];
}

/*- (void)windowDidBecomeMain:(NSNotification *)notification {
 
 }*/

- (NSDictionary *)settingsForAccount:(NSString *)name {
    if (!self.accountsSettings) self.accountsSettings = [[NSUserDefaults standardUserDefaults] valueForKey:@"accounts"];
    
    return [self.accountsSettings firstObjectWithKey:@"name" equalToString:name];
    
}




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

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
    *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSServiceMiscellaneousError userInfo:@{NSLocalizedFailureReasonErrorKey:@"\n\nI'm sorry, but that feature is Not In Service at this time."}];
    return nil;
}

@end
