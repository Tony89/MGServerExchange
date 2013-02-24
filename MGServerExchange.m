//
//  MGServerExchange.m
//  Pashadelic
//
//  Created by Виталий Гоженко on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MGServerExchange.h"
#import "JSONKit.h"
#import "Reachability.h"
#import "MGAppDelegate.h"

@interface MGServerExchange (Private)
- (BOOL)checkInternetConnection;
@end


@implementation MGServerExchange
@synthesize result, delegate, errorDescription, functionPath;

- (id)initWithDelegate:(id<MGServerExchangeDelegate>)initDelegate
{
	self = [super init];
	
	if (self) {
		delegate = initDelegate;
		responseData = [NSMutableData data];
	}
	return self;
}

- (BOOL)parseResponseData
{
	NSString *string = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	if (self.debugMode) {
		NSLog(@"%@\n%@", self.URLString, string);
	}
	self.result = [string objectFromJSONStringWithParseOptions:JKParseOptionUnicodeNewlines];
	
	if (!self.result) {
		NSLog(@"%@\n%@", self.URLString, string);
		if (self.HTTPStatusCode != 0) {
			errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Server error %d", nil), self.HTTPStatusCode];
		} else {
			errorDescription = NSLocalizedString(@"Error while parsing server response", nil);
		}
		return NO;
	}
	
	return YES;
}

- (NSString *)serverAddress
{
	return @"";
}

- (NSString *)login
{
	return @"";
}

- (NSString *)password
{
	return @"";
}

- (BOOL)debugMode
{
	return NO;
}

- (BOOL)parseResult
{	
	return YES;
}

- (NSURL *)URL
{
	return [NSURL URLWithString:self.URLString];
}

- (NSString *)URLString
{
	return [NSString stringWithFormat:@"%@%@", self.serverAddress, self.functionPath];
}

- (NSStringEncoding)dataEncoding
{
	return NSUTF8StringEncoding;
}

- (void)requestToPostFunctionWithString:(NSString *)post timeoutInterval:(NSTimeInterval)interval
{
	self.HTTPStatusCode = 0;
	if (![self checkInternetConnection]) return;
	[self incrementInternetActivitiesCount];
	
	NSData *postData = [post dataUsingEncoding:self.dataEncoding allowLossyConversion:YES];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:self.URL];
	[request setHTTPMethod:@"POST"];
	[self setHeadersForHTTPRequest:request];
	[request setHTTPBody:postData];	
	request.timeoutInterval = interval;
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)requestToPostFunctionWithString:(NSString *)post
{
	[self requestToPostFunctionWithString:post timeoutInterval:120];
}

- (void)requestToPutFunctionWithString:(NSString *)put
{
	self.HTTPStatusCode = 0;
	if (![self checkInternetConnection]) return;
	[self incrementInternetActivitiesCount];
	
	NSData *putData = [put dataUsingEncoding:self.dataEncoding allowLossyConversion:YES];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:self.URL];
	[request setHTTPMethod:@"PUT"];
	[self setHeadersForHTTPRequest:request];
	[request setHTTPBody:putData];
	request.timeoutInterval = 120;
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)requestToGetFunctionWithString:(NSString *)get
{
	self.HTTPStatusCode = 0;
	if (![self checkInternetConnection]) return;
	[self incrementInternetActivitiesCount];
	
	NSString *fullURL = self.URLString;
	if (get) {
		fullURL = [fullURL stringByAppendingString:get];
	}
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:[fullURL stringByAddingPercentEscapesUsingEncoding:self.dataEncoding]]];
	[request setHTTPMethod:@"GET"];
	[self setHeadersForHTTPRequest:request];
	request.timeoutInterval = 120;
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)requestToDeleteFunction
{
	self.HTTPStatusCode = 0;
	if (![self checkInternetConnection]) return;
	[self incrementInternetActivitiesCount];

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:self.URL];
	[request setHTTPMethod:@"DELETE"];
	[self setHeadersForHTTPRequest:request];
	request.timeoutInterval = 120;
	[NSURLConnection connectionWithRequest:request delegate:self];
}

+ (BOOL)isInternetReachable
{
	ATReachability *reachability = [ATReachability reachabilityForInternetConnection];
	if (reachability.currentReachabilityStatus == NotReachable) {
		return NO;
	} else {
		return YES;
	}
}

- (void)setHeadersForHTTPRequest:(NSMutableURLRequest *)request
{
}

- (BOOL)checkInternetConnection
{
	if (![MGServerExchange isInternetReachable]) {
		self.HTTPStatusCode = -1;
		[self.delegate serverExchange:self didFailWithError:kMGNoInternetMessage];
		return NO;
	} else {
		return YES;
	}
}

- (void)incrementInternetActivitiesCount
{
	if ([[UIApplication sharedApplication].delegate isKindOfClass:[MGAppDelegate class]]) {
		MGAppDelegate *appDelegate = (MGAppDelegate *) [UIApplication sharedApplication].delegate;
		appDelegate.internetActivitiesCount++;
	}
}

- (void)decrementInternetActivitiesCount
{
	if ([[UIApplication sharedApplication].delegate isKindOfClass:[MGAppDelegate class]]) {
		MGAppDelegate *appDelegate = (MGAppDelegate *) [UIApplication sharedApplication].delegate;
		appDelegate.internetActivitiesCount--;
	}
}


#pragma mark - Connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
		[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
		
	} else {
		if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic] && challenge.previousFailureCount < 2) {
			NSURLCredential *credentials = [[NSURLCredential alloc] initWithUser:self.login password:self.password persistence:NSURLCredentialPersistenceForSession];
			[[challenge sender] useCredential:credentials forAuthenticationChallenge:challenge];
			
		} else {
			[[challenge sender] cancelAuthenticationChallenge:challenge];			
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self decrementInternetActivitiesCount];
	[delegate serverExchange:self didFailWithError:error.localizedDescription];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{	
	[self decrementInternetActivitiesCount];
	if (![self parseResponseData]) {
		responseData = [NSMutableData data];
		[delegate serverExchange:self didFailWithError:errorDescription];
		return;
	}
	
	if (![self parseResult]) {
		[delegate serverExchange:self didFailWithError:errorDescription];
	} else {
		[delegate serverExchange:self didParseResult:result];
	}
	responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.HTTPStatusCode = [(NSHTTPURLResponse *)response statusCode];
}

@end
