//
//  OIDEndpoint.h
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_ALIAS @"ext1"

@interface OIDEndpoint : NSObject

@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSString *alias;

- (id)initWithUrl:(NSString*)url alias:(NSString*)alias maxAge:(long)maxAgeInMilliSeconds;
- (BOOL)isExpired;

@end
