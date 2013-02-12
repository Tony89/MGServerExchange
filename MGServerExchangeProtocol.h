//
//  MGServerExchangeDelegate.h
//  Pashadelic
//
//  Created by Виталий Гоженко on 10/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MGServerExchange;

@protocol MGServerExchangeDelegate <NSObject>

- (void)serverExchange:(MGServerExchange *)serverExchange didParseResult:(NSDictionary *)result;
- (void)serverExchange:(MGServerExchange *)serverExchange didFailWithError:(NSString *)error;

@end
