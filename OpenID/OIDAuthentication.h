//
//  OIDAuthentication.h
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OIDAuthentication : NSObject

@property (nonatomic) NSString *identity;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *fullname;
@property (nonatomic) NSString *firstname;
@property (nonatomic) NSString *lastname;
@property (nonatomic) NSString *language;
@property (nonatomic) NSString *gender;

@end
