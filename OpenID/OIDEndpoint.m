//
//  OIDEndpoint.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "OIDEndpoint.h"

@interface OIDEndpoint ()

@property (nonatomic) NSString *url;
@property (nonatomic) NSString *alias;
@property (nonatomic) NSTimeInterval expired;

@end

@implementation OIDEndpoint

- (id)initWithUrl:(NSString*)url alias:(NSString*)alias maxAge:(long)maxAgeInMilliSeconds
{
    self = [super init];
    if (self) {
        _url = url;
        _alias = alias;
        _expired = [NSDate timeIntervalSinceReferenceDate] + maxAgeInMilliSeconds / 1000.0;
    }
    return self;
}

- (BOOL)isExpired
{
    return [NSDate timeIntervalSinceReferenceDate] >= _expired;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return true;
    }
    if ([object isKindOfClass:[OIDEndpoint class]]) {
        return [[(OIDEndpoint*)object url] isEqualToString:self.url];
    }
    return false;
}

- (NSUInteger)hash
{
    return _url.hash;
}

- (NSString *)description
{
    NSMutableString *sb = [NSMutableString string];
    [sb appendFormat:@"Endpoint [uri:%@, expired:%@]", _url,
     [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:_expired]
                                    dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]];
    return sb;
}

@end
