//  Copyright (c) 2012 ElmerCat. All rights reserved.

#if TARGET_OS_IPHONE
#import "NXOAuth2.h"
#else
#import <OAuth2Client/NXOAuth2.h>
#endif

#import "WPAccount.h"
#import "WPAccount+Private.h"
#import "WPConstants.h"

#import "WPRequest.h"

@interface WPRequest ()
@property (nonatomic, retain) NXOAuth2Request *oauthRequest;
@end

@implementation WPRequest

#pragma mark Class Methods

+ (id)   performMethod:(WPRequestMethod)aMethod
            onResource:(NSURL *)aResource
       usingParameters:(NSDictionary *)someParameters
           withAccount:(WPAccount *)anAccount
sendingProgressHandler:(WPRequestSendingProgressHandler)aProgressHandler
       responseHandler:(WPRequestResponseHandler)aResponseHandler;
{
    NSString *theMethod;
    switch (aMethod) {
        case WPRequestMethodPOST:
            theMethod = @"POST";
            break;
            
        case WPRequestMethodPUT:
            theMethod = @"PUT";
            break;
            
        case WPRequestMethodDELETE:
            theMethod = @"DELETE";
            break;
            
        case WPRequestMethodHEAD:
            theMethod = @"HEAD";
            break;
            
        default:
            theMethod = @"GET";
            break;
    }
    
    NSAssert1([[aResource scheme] isEqualToString:@"https"], @"Resource '%@' is invalid because the scheme is not 'https'.", aResource);
    
    NXOAuth2Request *request = [[NXOAuth2Request alloc] initWithResource:aResource method:theMethod parameters:someParameters];
    request.account = anAccount.oauthAccount;
    [request performRequestWithSendingProgressHandler:aProgressHandler
                                      responseHandler:aResponseHandler];
    return request;
}

+ (void)cancelRequest:(id)request;
{
    if ([request isKindOfClass:[NXOAuth2Request class]] ||
        [request isKindOfClass:[WPRequest class]]) {
        [request cancel];
    }
}


#pragma mark Lifecycle

- (id)init;
{
    NSAssert(NO, @"Please use the designated initializer");
    return nil;
}

- (id)initWithMethod:(WPRequestMethod)aMethod resource:(NSURL *)aResource;
{
    self = [super init];
    if (self) {
        
        NSString *theMethod;
        switch (aMethod) {
            case WPRequestMethodPOST:
                theMethod = @"POST";
                break;
                
            case WPRequestMethodPUT:
                theMethod = @"PUT";
                break;
                
            case WPRequestMethodDELETE:
                theMethod = @"DELETE";
                break;
                
            case WPRequestMethodHEAD:
                theMethod = @"HEAD";
                break;
                
            default:
                theMethod = @"GET";
                break;
        }
        
        oauthRequest = [[NXOAuth2Request alloc] initWithResource:aResource method:theMethod parameters:nil];
    }
    return self;
}


#pragma mark Accessors

@synthesize oauthRequest;

- (WPAccount *)account;
{
    if (self.oauthRequest.account) {
        return [[WPAccount alloc] initWithOAuthAccount:self.oauthRequest.account];
    } else {
        return nil;
    }
}

- (void)setAccount:(WPAccount *)account;
{
    self.oauthRequest.account = account.oauthAccount;
}

- (WPRequestMethod)requestMethod;
{
    NSString *aMethod = self.oauthRequest.requestMethod;
    
    if ([aMethod caseInsensitiveCompare:@"POST"]) {
        return WPRequestMethodPOST;
    } else if ([aMethod caseInsensitiveCompare:@"PUT"]) {
        return WPRequestMethodPUT;
    } else if ([aMethod caseInsensitiveCompare:@"DELETE"]) {
        return WPRequestMethodDELETE;
    } else if ([aMethod caseInsensitiveCompare:@"HEAD"]) {
        return WPRequestMethodHEAD;
    } else {
        NSAssert1([aMethod caseInsensitiveCompare:@"GET"], @"WPRequest only supports 'GET', 'PUT', 'POST' and 'DELETE' as request method. Underlying NXOAuth2Accound uses the request method %@", aMethod);
        return WPRequestMethodGET;
    }
}

- (void)setRequestMethod:(WPRequestMethod)requestMethod;
{
    NSString *theMethod;
    switch (requestMethod) {
        case WPRequestMethodPOST:
            theMethod = @"POST";
            break;
            
        case WPRequestMethodPUT:
            theMethod = @"PUT";
            break;
            
        case WPRequestMethodDELETE:
            theMethod = @"DELETE";
            break;
            
        case WPRequestMethodHEAD:
            theMethod = @"HEAD";
            break;
            
        default:
            theMethod = @"GET";
            break;
    }
    self.oauthRequest.requestMethod = theMethod;
}

- (NSURL *)resource;
{
    return self.oauthRequest.resource;
}

- (void)setResource:(NSURL *)resource;
{
    self.oauthRequest.resource = resource;
}

- (NSDictionary *)parameters;
{
    return self.oauthRequest.parameters;
}

- (void)setParameters:(NSDictionary *)parameters;
{
    self.oauthRequest.parameters = parameters;
}


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;
{
    return [self.oauthRequest signedURLRequest];
}


#pragma mark Perform Request

- (void)performRequestWithSendingProgressHandler:(WPRequestSendingProgressHandler)aSendingProgressHandler
                                 responseHandler:(WPRequestResponseHandler)aResponseHandler;
{
    [self.oauthRequest performRequestWithSendingProgressHandler:aSendingProgressHandler
                                                responseHandler:aResponseHandler];
}

- (void)cancel;
{
    [self.oauthRequest cancel];
}

@end
