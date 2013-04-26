//
//  OIDShortName.h
//  TestOpenID
//
//  Created by masataka on 2013/04/25.
//  Copyright (c) 2013 masataka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OIDShortName : NSObject

- (NSString*)lookupUrlByName:(NSString*)name;
- (NSString*)lookupAliasByName:(NSString*)name;

@end
