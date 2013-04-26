//
//  OIDOpenIdManager.m
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import "OIDOpenIdManager.h"

#import "OIDShortName.h"
#import "OIDUtil.h"

@interface OIDOpenIdManager ()

@property (nonatomic) OIDShortName *shortName;
@property (nonatomic) NSCache *endpointCache;
@property (nonatomic) NSCache *associationCache;

@property (nonatomic) NSString *assocQuery;
@property (nonatomic) NSString *authQuery;
@property (nonatomic) NSString *returnToUrlEncode;

@end

@implementation OIDOpenIdManager

- (id)init
{
    self = [super init];
    if (self) {
        _shortName = [[OIDShortName alloc] init];
        _endpointCache = [[NSCache alloc] init];
        _associationCache = [[NSCache alloc] init];
        
        _timeOut = 5000;
    }
    return self;
}

- (void)setReturnTo:(NSString *)returnTo
{
    _returnToUrlEncode = [OIDUtil urlEncode:returnTo];
    _returnTo = returnTo;
}

- (void)setRealm:(NSString *)realm
{
    _realm = [OIDUtil urlEncode:realm];
}

- (OIDAuthentication*)authentication:(NSURLRequest*)request key:(NSData*)key
{
    return [self authentication:request key:key alias:DEFAULT_ALIAS];
}

- (OIDAuthentication*)authentication:(NSURLRequest*)request key:(NSData*)key alias:(NSString*)alias
{
    NSString *query = request.URL.query;
    if (query.length == 0) {
        query = [OIDUtil content:request.allHTTPHeaderFields data:request.HTTPBody];
    }
    
    // verify:
    NSDictionary *parameters = [OIDUtil parseQuery:query];
    NSString *identity = parameters[@"openid.identity"];
    if (! identity) {
        NSLog(@"Missing 'openid.identity'.");
        return nil;
    }
    if (parameters[@"openid.invalidate_handle"]) {
        NSLog(@"Invalidate handle.");
        return nil;
    }
    NSString *sig = parameters[@"openid.sig"];
    if (! sig) {
        NSLog(@"Missing 'openid.sig'.");
        return nil;
    }
    NSString *sign = parameters[@"openid.signed"];
    if (! sign) {
        NSLog(@"Missing 'openid.signed'.");
        return nil;
    }
    if (! [_returnTo isEqualToString:parameters[@"openid.return_to"]]) {
        NSLog(@"Bad 'openid.return_to'.");
        return nil;
    }
    
    // check sig:
    NSArray *params = [sign componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\\,"]];
    NSMutableString *sb = [NSMutableString string];
    for (NSString *param in params) {
        [sb appendString:param];
        [sb appendString:@":"];
        NSString *value = parameters[[@"openid." stringByAppendingString:param]];
        if (value) {
            [sb appendString:value];
        }
        [sb appendString:@"\n"];
    }
    NSString *hmac = [OIDUtil hmac_sha1:[sb dataUsingEncoding:NSUTF8StringEncoding] key:key];
    if (! [self safeEqual:hmac to:sig]) {
        NSLog(@"Verify signature failed.");
        return nil;
    }
    
    // set auth:
    OIDAuthentication *auth = [[OIDAuthentication alloc] init];
    auth.identity = identity;
    auth.email = parameters[[NSString stringWithFormat:@"openid.%@.value.email", alias]];
    auth.language = parameters[[NSString stringWithFormat:@"openid.%@.value.language", alias]];
    auth.gender = parameters[[NSString stringWithFormat:@"openid.%@.value.gender", alias]];
    auth.fullname = [self fullname:parameters alias:alias];
    auth.firstname = [self firstname:parameters alias:alias];
    auth.lastname = [self lastname:parameters alias:alias];
    return auth;
}

- (BOOL)safeEqual:(NSString*)s1 to:(NSString*)s2
{
    if (s1.length != s2.length)
        return false;
    int result = 0;
    for (int i=0; i<s1.length; i++) {
        int c1 = [s1 characterAtIndex:i];
        int c2 = [s2 characterAtIndex:i];
        result |= (c1 ^c2);
    }
    return result==0;
}

- (NSString*)lastname:(NSDictionary*)params alias:(NSString *)axa {
    NSString *name = params[[NSString stringWithFormat:@"openid.%@.value.lastname", axa]];
    // If lastname is not supported try to get it from the fullname
    if (name == nil) {
        name = params[[NSString stringWithFormat:@"openid.%@.value.fullname", axa]];
        if (name != nil) {
            int n = [name rangeOfString:@" " options:NSBackwardsSearch].location;
            if (n!=(-1))
                name = [name substringFromIndex:n + 1];
        }
    }
    return name;
}

- (NSString*)firstname:(NSDictionary*)params alias:(NSString*)axa {
    NSString *name = params[[NSString stringWithFormat:@"openid.%@.value.firstname", axa]];
    //If firstname is not supported try to get it from the fullname
    if (name == nil) {
        name = params[[NSString stringWithFormat:@"openid.%@.value.fullname", axa]];
        if (name != nil) {
            int n = [name rangeOfString:@" "].location;
            if (n!=(-1))
                name = [name substringToIndex:n];
        }
    }
    return name;
}

- (NSString*)fullname:(NSDictionary*)params alias:(NSString*)axa {
    // If fullname is not supported then get combined first and last name
    NSString *fname = params[[NSString stringWithFormat:@"openid.%@.value.fullname", axa]];
    if (fname == nil) {
        fname = params[[NSString stringWithFormat:@"openid.%@.value.firstname", axa]];
        if (fname != nil) {
            fname = [fname stringByAppendingString:@" "];
        }
        fname = [fname stringByAppendingString:params[[NSString stringWithFormat:@"openid.%@.value.lastname", axa]]];
    }
    return fname;
}

/**
 * Lookup end point by name or full URL.
 */
- (BOOL)lookupEndpoint:(NSString*)nameOrUrl callback:(void ((^)(OIDEndpoint*)))callback
{
    NSString *url = nil;
    NSString *alias = nil;
    if ([nameOrUrl hasPrefix:@"http://"] || [nameOrUrl hasPrefix:@"https://"]) {
        url = nameOrUrl;
    } else {
        url = [_shortName lookupUrlByName:nameOrUrl];
        if (url == nil) {
            NSLog(@"Cannot find OP URL by name: %@", nameOrUrl);
            return NO;
        }
        alias = [_shortName lookupAliasByName:nameOrUrl];
    }
    OIDEndpoint *endpoint = [_endpointCache objectForKey:url];
    if (endpoint != nil && ! [endpoint isExpired]) {
        callback(endpoint);
        return YES;
    }
    [self requestEndpoint:url alias:(alias == nil ? DEFAULT_ALIAS : alias) callback:^(OIDEndpoint *result) {
        [_endpointCache setObject:result forKey:result.url];
        callback(result);
    }];
    return YES;
}

- (BOOL)lookupAssociation:(OIDEndpoint*)endpoint callback:(void ((^)(OIDAssociation*)))callback
{
    OIDAssociation *assoc = [_associationCache objectForKey:endpoint];
    if (assoc != nil && ! [assoc isExpired]) {
        callback(assoc);
        return YES;
    }
    [self requestAssociation:endpoint callback:^(OIDAssociation *result) {
        [_associationCache setObject:result forKey:endpoint];
        callback(result);
    }];
    return YES;
}

- (NSString*)getAuthenticationUrl:(OIDEndpoint*)endpoint association:(OIDAssociation*)association
{
    NSMutableString *sb = [NSMutableString string];
    [sb appendString:endpoint.url];
    [sb appendString:([endpoint.url rangeOfString:@"?"].location != NSNotFound ? @"&" : @"?")];
    [sb appendString:[self authQuery:endpoint.alias]];
    [sb appendString:@"&openid.return_to="];
    [sb appendString:_returnToUrlEncode];
    [sb appendString:@"&openid.assoc_handle="];
    [sb appendString:association.assocHandle];
    if (_realm != nil) {
        [sb appendString:@"&openid.realm="];
        [sb appendString:_realm];
    }
    return sb;
}

- (void)requestEndpoint:(NSString*)url alias:(NSString*)alias callback:(void ((^)(OIDEndpoint*)))callback
{
    [OIDUtil httpRequest:url method:@"GET" accept:@"application/xrds+xml" postData:nil timeout:_timeOut callback:^(NSDictionary *map) {
        NSString *content = [OIDUtil content:map];
        callback([[OIDEndpoint alloc] initWithUrl:[OIDUtil mid:content begin:@"<URI>" end:@"</URI>"] alias:alias maxAge:[OIDUtil maxAge:map]]);
    }];
}

- (void)requestAssociation:(OIDEndpoint*)endpoint callback:(void ((^)(OIDAssociation*)))callback
{
    [OIDUtil httpRequest:endpoint.url method:@"POST" accept:@"*/*" postData:self.assocQuery timeout:_timeOut callback:^(NSDictionary *map) {
        NSString *content = [OIDUtil content:map];
        OIDAssociation *assoc = [[OIDAssociation alloc] init];
        for (NSString *newline in [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
            NSString *line = [newline stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            int pos = [line rangeOfString:@":"].location;
            if (pos != NSNotFound) {
                NSString *key = [line substringToIndex:pos];
                NSString *value = [line substringFromIndex:pos + 1];
                if ([@"session_type" isEqualToString:key])
                    assoc.sessionType = value;
                else if ([@"assoc_type" isEqualToString:key])
                    assoc.assocType = value;
                else if ([@"assoc_handle" isEqualToString:key])
                    assoc.assocHandle = value;
                else if ([@"mac_key" isEqualToString:key])
                    assoc.macKey = value;
                else if ([@"expires_in" isEqualToString:key]) {
                    long long maxAge = [value longLongValue];
                    assoc.maxAge = maxAge * 900L; // 90%
                }
            }
        }
        callback(assoc);
    }];
}

- (NSString*)authQuery:(NSString*)axa
{
    if (_authQuery != nil) {
        return _authQuery;
    }
    NSMutableArray *list = [NSMutableArray array];
    [list addObject:@"openid.ns=http://specs.openid.net/auth/2.0"];
    [list addObject:@"openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select"];
    [list addObject:@"openid.identity=http://specs.openid.net/auth/2.0/identifier_select"];
    [list addObject:@"openid.mode=checkid_setup"];
    [list addObject:[NSString stringWithFormat:@"openid.ns.%@=http://openid.net/srv/ax/1.0", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.mode=fetch_request", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.type.email=http://axschema.org/contact/email", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.type.fullname=http://axschema.org/namePerson", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.type.language=http://axschema.org/pref/language", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.type.firstname=http://axschema.org/namePerson/first", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.type.lastname=http://axschema.org/namePerson/last", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.type.gender=http://axschema.org/person/gender", axa]];
    [list addObject:[NSString stringWithFormat:@"openid.%@.required=email,fullname,language,firstname,lastname,gender", axa]];
    NSString *query = [OIDUtil buildQuery:list];
    _authQuery = query;
    return query;
}

- (NSString*)assocQuery
{
    if (_assocQuery != nil) {
        return _assocQuery;
    }
    NSMutableArray *list = [NSMutableArray array];
    [list addObject:@"openid.ns=http://specs.openid.net/auth/2.0"];
    [list addObject:@"openid.mode=associate"];
    [list addObject:[@"openid.session_type=" stringByAppendingString:SESSION_TYPE_NO_ENCRYPTION]];
    [list addObject:[@"openid.assoc_type=" stringByAppendingString:ASSOC_TYPE_HMAC_SHA1]];
    NSString *query = [OIDUtil buildQuery:list];
    _assocQuery = query;
    return query;
}

@end

