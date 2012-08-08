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
@synthesize soundCloudController;
@synthesize soundCloudAuthorizationWindow;
@synthesize webView;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
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
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSLog(@"PraxDocument NXOAuth2AccountStoreAccountsDidChangeNotification");

                                                      // Update your UI
                                                      if ([SCSoundCloud account]) {
                                                          [soundCloudAuthorizationWindow close];
                                                          
                                                          
                                                      }
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      
                                                      NSLog(@"PraxDocument NXOAuth2AccountStoreDidFailToRequestAccessNotification error:%@", error);

                                                      // Do something with the error
                                                      
                                                      
                                                  }];
    
    // YouTube developer key = "AI39si7b1wiC17l1KoIAB1maTGrjfVfeKEzm6yRElmdBiOlcj75NFktrwd4oBdY2CS1j54hVPmnWhY9KGj9NaBul3BL_nk_Vsg"
    
    [[NXOAuth2AccountStore sharedStore] setClientID:@"493"
                                             secret:@"Xkd4JjiFceH8OVFqEsaZtP5eGtONxnFP3Emq2mlQoiJBvw7HtpbHbniHmQdaXuhg"
                                   authorizationURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/authorize"]
                                           tokenURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/token"]
                                        redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                     forAccountType:@"WordPress"];
    
    [SCSoundCloud  setClientID:@"cdb0237a5d0244d2f0528ae9da6ca41f"
                        secret:@"48d5ef73f4dd1281e5d41100ba58261a"
                   redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]];
    
    
//    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    
    /* register our special protocol with webkit */
	[SpecialProtocol registerSpecialProtocol];
    

}

- (IBAction)praxAction:(id)sender{
    NSLog(@"praxAction");
    for (NXOAuth2Account *account in [[NXOAuth2AccountStore sharedStore] accounts]) {
        // Do something with the account
        
        NSLog(@"praxAction account:%@", account);
    };
    
}

- (IBAction)wordPressAction:(id)sender {
    


    
    
    
    
/*

    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"WordPress"];
    if ([accounts count] > 0) {
        NXOAuth2Account *account = accounts[0];
        NSLog(@"praxAction account:%@", account);
        
        [NXOAuth2Request performMethod:@"GET"
                            onResource:[NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1/me"]
                       usingParameters:nil
                           withAccount:account
                   sendProgressHandler:^(unsigned long long bytesSend, unsigned long long bytesTotal) {
                       
                       NSLog(@"sendProgressHandler bytesSend:%llu bytesTotal:%llu", bytesSend, bytesTotal);
                       // e.g., update a progress indicator
                   }
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       
                       NSLog(@"responseHandler response:%@ responseData:%@ error:%@", response, responseData, error);
                       NSError *__autoreleasing *jsonError = NULL;
                       NSDictionary *me = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:jsonError];
                       
                       NSLog(@"me: %@", me);
                       // Process the response
                       
                       
                   }];
        
    }
    else {
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"WordPress"
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           [soundCloudAuthorizationWindow makeKeyAndOrderFront:sender];
                                           [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                       }];
 
        
    }
  */  
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
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
