//
//  Base64.h
//  TestOpenID
//
//  Created by masataka on 2013/04/26.
//

#import <Foundation/Foundation.h>

@interface Base64 : NSObject

+ (NSString *) base64EncodeData: (NSData *) objData;
+ (NSData *) base64DecodeString: (NSString *) strBase64;

@end
