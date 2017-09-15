//
//  OIDUtil.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "OIDUtil.h"

#import <CommonCrypto/CommonCrypto.h>
#import "Base64.h"

#define MAX_SIZE 10240
#define CONTENT @"Content"

@implementation OIDUtil

+ (void)httpRequest:(NSString*)url method:(NSString*)method accept:(NSString*)acceptType postData:(NSString*)postData timeout:(int)timeOut
           callback:(void ((^)(NSDictionary*)))callback
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]
                                                                cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                            timeoutInterval:(timeOut / 1000.0)];
    request.HTTPMethod = method;
    request.HTTPBody = [postData dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:acceptType forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Connection error: %@", error);
            return;
        }
        NSHTTPURLResponse *res = (NSHTTPURLResponse*)response;
        NSMutableDictionary *map = [NSMutableDictionary dictionaryWithDictionary:res.allHeaderFields];
        map[CONTENT] = data;

        if (res.statusCode == 200) {
            callback(map);
        } else {
            NSLog(@"Bad response code: %ld", (long)res.statusCode);
            NSLog(@"response body: %@", [self content:map]);
            return;
        }
    }];
}

+ (long)maxAge:(NSDictionary *)map
{
    NSString *cache = map[@"Cache-Control"];
    if (cache == nil)
        return 0L;
    NSUInteger pos = [cache rangeOfString:@"max-age="].location;
    if (pos != NSNotFound) {
        NSString *maxAge = [cache substringFromIndex:(pos + @"max-age=".length)];
        pos = [maxAge rangeOfString:@","].location;
        if (pos != NSNotFound)
            maxAge = [maxAge substringToIndex:pos];
        return [maxAge longLongValue] * 1000L;
    }
    return 0L;
}

+ (NSString*)content:(NSDictionary*)map
{
    return [self content:map data:map[CONTENT]];
}

+ (NSString*)content:(NSDictionary*)map data:(NSData*)data
{
    return [[NSString alloc] initWithData:data encoding:[self contentEncoding:map]];
}

+ (NSStringEncoding)contentEncoding:(NSDictionary*)map
{
    NSString *contentType = map[@"Content-Type"];
    if (contentType) {
        NSUInteger pos = [contentType rangeOfString:@"charset="].location;
        if (pos != NSNotFound) {
            NSString *charset = [contentType substringFromIndex:(pos + @"charset=".length)];
            for (const NSStringEncoding *encoding = [NSString availableStringEncodings]; *encoding != 0; encoding++) {
                if ([[NSString localizedNameOfStringEncoding:*encoding] isEqualToString:charset]) {
                    return *encoding;
                }
            }
        }
    }
    return NSUTF8StringEncoding;
}

/**
 * Get substring between start token and end token.
 */
+ (NSString*)mid:(NSString*)s begin:(NSString*)startToken end:(NSString*)endToken
{
    return [self mid:s begin:startToken end:endToken from:0];
}

/**
 * Get substring between start token and end token, searching from specific index.
 */
+ (NSString*)mid:(NSString*)s begin:(NSString*)startToken end:(NSString*)endToken from:(int)fromStart
{
    if (startToken==nil || endToken==nil)
        return nil;
    NSUInteger start = [s rangeOfString:startToken options:0 range:NSMakeRange(fromStart, s.length - fromStart)].location;
    if (start == NSNotFound)
        return nil;
    start += startToken.length;
    NSUInteger end = [s rangeOfString:endToken options:0 range:NSMakeRange(start, s.length - start)].location;
    if (end == NSNotFound)
        return nil;
    NSString *sub = [s substringWithRange:NSMakeRange(start, end - start)];
    return [sub stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}



+ (NSString *)hmac_sha1:(NSData *)data key:(NSData*)key
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];

    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA1, key.bytes, key.length);
    CCHmacUpdate(&ctx, data.bytes, data.length);
    CCHmacFinal(&ctx, digest);

    return [Base64 base64EncodeData:[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH]];
}

+ (NSString*)urlEncode:(NSString*)s
{
    return ((NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)s,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8)));
}

+ (NSString *)urlDecode:(NSString *)str
{
    return [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSMutableDictionary*)parseQuery:(NSString*)webdata
{
    NSMutableDictionary *chunks = [NSMutableDictionary dictionary];
    for (NSString *chunk in [webdata componentsSeparatedByString:@"&"]) {
        NSArray *keyValue = [chunk componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            chunks[[self urlDecode:keyValue[0]]] = [self urlDecode:keyValue[1]];
        }
    }
    return chunks;
}

/**
 * Build query string like "a=1&b=2&c=3".
 */
+ (NSString*)buildQuery:(NSArray*)list
{
    if (list.count > 0) {
        NSMutableString *sb = [NSMutableString stringWithCapacity:1024];
        for (NSString *s in list) {
            NSUInteger n = [s rangeOfString:@"="].location;
            if (n != NSNotFound) {
                [sb appendString:[s substringToIndex:(n + 1)]];
                [sb appendString:[self urlEncode:[s substringFromIndex:(n + 1)]]];
                [sb appendString:@"&"];
            }
        }
        // remove last '&':
        [sb deleteCharactersInRange:NSMakeRange(sb.length - 1, 1)];
        return sb;
    }
    return @"";
}

@end
