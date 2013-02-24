//
//  MGServerExchange.h
//  Pashadelic
//
//  Created by Виталий Гоженко on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGServerExchangeProtocol.h"

#define kMGNoInternetMessage		NSLocalizedString(@"Please check internet connection.", nil)

@interface MGServerExchange : NSObject
<NSURLConnectionDataDelegate>
{
	NSMutableData *responseData;
}

@property (nonatomic) int HTTPStatusCode;
@property (strong, nonatomic) id result;
@property (strong, nonatomic) NSString *errorDescription;
@property (strong, nonatomic) NSString *functionPath;
@property (weak, nonatomic) id<MGServerExchangeDelegate>delegate;


- (id)initWithDelegate:(id <MGServerExchangeDelegate>)initDelegate;

- (BOOL)parseResponseData;
- (BOOL)parseResult;

- (void)incrementInternetActivitiesCount;
- (void)decrementInternetActivitiesCount;


- (void)requestToPostFunctionWithString:(NSString *)post timeoutInterval:(NSTimeInterval)interval;
- (void)requestToPostFunctionWithString:(NSString *)post;
- (void)requestToPutFunctionWithString:(NSString *)put;
- (void)requestToGetFunctionWithString:(NSString *)get;
- (void)setHeadersForHTTPRequest:(NSMutableURLRequest *)request;
- (void)requestToDeleteFunction;

- (NSURL *)URL;
- (NSString *)URLString;
+ (BOOL)isInternetReachable;

- (BOOL)debugMode;
- (NSStringEncoding)dataEncoding;
- (NSString *)login;
- (NSString *)password;
- (NSString *)serverAddress;

@end
