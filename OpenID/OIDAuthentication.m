//
//  OIDAuthentication.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "OIDAuthentication.h"

@implementation OIDAuthentication

- (NSString *)description
{
    NSMutableString *sb = [NSMutableString string];
    [sb appendString:@"Authentication ["];
    [sb appendFormat:@"identity:%@, ", _identity];
    [sb appendFormat:@"email:%@, ", _email];
    [sb appendFormat:@"fullname:%@, ", _fullname];
    [sb appendFormat:@"language:%@, ", _language];
    [sb appendFormat:@"gender:%@", _gender];
    [sb appendString:@"]"];
    return sb;
}

@end
