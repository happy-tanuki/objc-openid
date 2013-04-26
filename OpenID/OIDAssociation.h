//
//  OIDAssociation.h
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SESSION_TYPE_NO_ENCRYPTION @"no-encryption"

#define ASSOC_TYPE_HMAC_SHA1 @"HMAC-SHA1"

@interface OIDAssociation : NSObject

@property (nonatomic) NSString *sessionType;
@property (nonatomic) NSString *assocType;
@property (nonatomic) NSString *assocHandle;
@property (nonatomic) NSString *macKey;
@property (nonatomic, readonly) NSData *rawMacKey;

- (void)setMaxAge:(long) maxAgeInMilliseconds;
- (BOOL)isExpired;

@end
