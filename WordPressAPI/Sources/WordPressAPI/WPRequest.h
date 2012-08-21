//  Copyright (c) 2012 ElmerCat. All rights reserved.

#import <Foundation/Foundation.h>

typedef void(^WPRequestResponseHandler)(NSURLResponse *response, NSData *responseData, NSError *error);
typedef void(^WPRequestSendingProgressHandler)(unsigned long long bytesSend, unsigned long long bytesTotal);

enum WPRequestMethod {
    WPRequestMethodGET = 0,
    WPRequestMethodPOST,
    WPRequestMethodPUT,
    WPRequestMethodDELETE,
    WPRequestMethodHEAD
};
typedef enum WPRequestMethod WPRequestMethod;

@class NXOAuth2Request;
@class WPAccount;

@interface WPRequest : NSObject {
@private
    NXOAuth2Request *oauthRequest;
}


#pragma mark Class Methods

+ (id)   performMethod:(WPRequestMethod)aMethod
            onResource:(NSURL *)resource
       usingParameters:(NSDictionary *)parameters
           withAccount:(WPAccount *)account
sendingProgressHandler:(WPRequestSendingProgressHandler)progressHandler
       responseHandler:(WPRequestResponseHandler)responseHandler;

+ (void)cancelRequest:(id)request;


#pragma mark Initializer

- (id)initWithMethod:(WPRequestMethod)aMethod resource:(NSURL *)aResource;

#pragma mark Accessors

@property (nonatomic, readwrite, retain) WPAccount *account;

@property (nonatomic, assign) WPRequestMethod requestMethod;
@property (nonatomic, readwrite, retain) NSURL *resource;
@property (nonatomic, readwrite, retain) NSDictionary *parameters;


#pragma mark Signed NSURLRequest

- (NSURLRequest *)signedURLRequest;

#pragma mark Perform Request

//TODO Consider this
// - Why not to -performRequestWithSendingHandler:responseHandler: ?
// - Why Resource instead of URL ?
// - Need documentation in why there is no –addMultiPartData:withName:type:

- (void)performRequestWithSendingProgressHandler:(WPRequestSendingProgressHandler)progressHandler
                                 responseHandler:(WPRequestResponseHandler)responseHandler;

#pragma Cancel Request

- (void)cancel;

@end
