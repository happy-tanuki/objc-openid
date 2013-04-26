//
//  OIDAssociation.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "OIDAssociation.h"

#import "Base64.h"

@interface OIDAssociation ()

@property (nonatomic) NSData *rawMacKey;
@property (nonatomic) NSTimeInterval expired;

@end

@implementation OIDAssociation

- (void)setMacKey:(NSString *)macKey
{
    _macKey = macKey;
    _rawMacKey = [Base64 base64DecodeString:macKey];
}

- (void)setMaxAge:(long) maxAgeInMilliseconds
{
    _expired = [NSDate timeIntervalSinceReferenceDate] + maxAgeInMilliseconds / 1000.0;
}

- (BOOL)isExpired
{
    return [NSDate timeIntervalSinceReferenceDate] >= _expired;
}

- (NSString *)description
{
    NSMutableString *sb = [NSMutableString string];
    [sb appendString:@"Association ["];
    [sb appendFormat:@"session_type:%@, ", _sessionType];
    [sb appendFormat:@"assoc_type:%@, ", _assocType];
    [sb appendFormat:@"assoc_handle:%@, ", _assocHandle];
    [sb appendFormat:@"mac_key:%@, ", _macKey];
    [sb appendFormat:@"expired:%@", [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:_expired] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]];
    [sb appendString:@"]"];
    return sb;
}

@end
