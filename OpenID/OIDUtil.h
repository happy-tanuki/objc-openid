//
//  OIDUtil.h
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OIDUtil : NSObject

+ (void)httpRequest:(NSString*)url method:(NSString*)method accept:(NSString*)acceptType postData:(NSString*)postData timeout:(int)timeOut
           callback:(void ((^)(NSDictionary*)))callback;

+ (long)maxAge:(NSDictionary*)map;
+ (NSString*)content:(NSDictionary*)map;
+ (NSString*)content:(NSDictionary*)map data:(NSData*)data;
+ (NSString*)mid:(NSString*)str begin:(NSString*)begin end:(NSString*)end;

+ (NSString *)hmac_sha1:(NSData *)data key:(NSData*)key;

+ (NSString*)urlEncode:(NSString*)s;
+ (NSString *)urlDecode:(NSString *)s;
+ (NSMutableDictionary*)parseQuery:(NSString*)query;
+ (NSString*)buildQuery:(NSArray*)list;

@end
