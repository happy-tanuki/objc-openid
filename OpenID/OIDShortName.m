//
//  OIDShortName.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "OIDShortName.h"

#import "OIDEndpoint.h"

@interface OIDShortName ()

@property (nonatomic) NSMutableDictionary *urlMap;
@property (nonatomic) NSMutableDictionary *aliasMap;

@end

@implementation OIDShortName

- (id)init
{
    self = [super init];
    if (self) {
        _urlMap = [NSMutableDictionary dictionary];
        _aliasMap = [NSMutableDictionary dictionary];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"openid-providers" ofType:@"plist"];
        NSArray *props = [NSArray arrayWithContentsOfFile:path];
        for (NSDictionary *prop in props) {
            NSString *key = [prop objectForKey:@"name"];
            NSString *alias = [prop objectForKey:@"alias"];
            NSString *url = [prop objectForKey:@"url"];
            if (key) {
                [_urlMap setObject:url forKey:key];
            }
            if (alias) {
                [_aliasMap setObject:alias forKey:key];
            }
        }
    }
    return self;
}

- (NSString*)lookupUrlByName:(NSString*)name
{
    return [_urlMap objectForKey:name];
}

- (NSString*)lookupAliasByName:(NSString*)name
{
    NSString *alias = [_aliasMap objectForKey:name];
    return alias == nil ? DEFAULT_ALIAS : alias;
}

@end
