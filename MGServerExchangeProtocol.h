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

- (void)serverExchange:(id)serverExchange didParseResult:(id)result;
- (void)serverExchange:(id)serverExchange didFailWithError:(NSString *)error;

@end
