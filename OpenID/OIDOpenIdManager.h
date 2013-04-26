//
//  OIDOpenIdManager.h
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OIDEndpoint.h"
#import "OIDAssociation.h"
#import "OIDAuthentication.h"

@interface OIDOpenIdManager : NSObject

@property (nonatomic) NSString *returnTo;
@property (nonatomic) NSString *realm;
@property (nonatomic) int timeOut;

- (BOOL)lookupEndpoint:(NSString*)nameOrUrl callback:(void ((^)(OIDEndpoint*)))callback;
- (BOOL)lookupAssociation:(OIDEndpoint*)endpoint callback:(void ((^)(OIDAssociation*)))callback;
- (NSString*)getAuthenticationUrl:(OIDEndpoint*)endpoint association:(OIDAssociation*)association;
- (OIDAuthentication*)authentication:(NSURLRequest*)request key:(NSData*)key alias:(NSString*)alias;

@end
