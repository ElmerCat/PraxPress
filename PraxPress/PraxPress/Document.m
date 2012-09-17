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
    
    [PraxTransformers load];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSLog(@"PraxDocument NXOAuth2AccountStoreAccountsDidChangeNotification");
                                                      // Update your UI
                                            //          if ([SCSoundCloud account]) {
                                                          [self.authorizationWindow close];
                                             //          }
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
    
    [[NXOAuth2AccountStore sharedStore] setClientID:@"cdb0237a5d0244d2f0528ae9da6ca41f"
                                             secret:@"48d5ef73f4dd1281e5d41100ba58261a"
                                   authorizationURL:[NSURL URLWithString:@"https://soundcloud.com/connect"]
                                           tokenURL:[NSURL URLWithString:@"https://api.soundcloud.com/oauth2/token"]
                                        redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                     forAccountType:@"com.soundcloud.api"];
    
    [[NXOAuth2AccountStore sharedStore] setClientID:@"493"
                                             secret:@"Xkd4JjiFceH8OVFqEsaZtP5eGtONxnFP3Emq2mlQoiJBvw7HtpbHbniHmQdaXuhg"
                                   authorizationURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/authorize"]
                                           tokenURL:[NSURL URLWithString:@"https://public-api.wordpress.com/oauth2/token"]
                                        redirectURL:[NSURL URLWithString:@"special://elmercat.org/praxpress/redirect/"]
                                     forAccountType:@"com.wordpress.api"];
    
    
    /* register our special protocol with webkit */
	[SpecialProtocol registerSpecialProtocol];
    

}

- (void)dealloc {
    NSLog(@"Document dealloc");
}
- (void)windowWillClose:(NSNotification *)notification {
    NSLog(@"Document windowWillClose notification: %@", notification);    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)removeAccessForAccountType:(NSString *)accountType {
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:accountType];
    for (NXOAuth2Account *account in accounts) {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
}


- (NXOAuth2Account *) scAccount {
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"com.soundcloud.api"];
    if ([oauthAccounts count] > 0) {
        return oauthAccounts[0];
    } else {
        
        [self removeAccessForAccountType:@"com.soundcloud.api"];
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"com.soundcloud.api"
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           [self.authorizationWindow makeKeyAndOrderFront:self];
                                           [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                       }];
        return nil;
    }
}

- (NXOAuth2Account *) wpAccount {
    NSArray *oauthAccounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"com.wordpress.api"];
    if ([oauthAccounts count] > 0) {
        return oauthAccounts[0];
    } else {
        
        [self removeAccessForAccountType:@"com.wordpress.api"];
        
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"com.wordpress.api"
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           [self.authorizationWindow makeKeyAndOrderFront:self];
                                           [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                       }];
        return nil;
    }
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

@end
