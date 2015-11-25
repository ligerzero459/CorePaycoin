// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYData.h"

// This category is for user's convenience only.
// For documentation look into XPYData.h.
// If you link CorePaycoin library without categories enabled, nothing will break.
// This is also used in unit tests in CorePaycoin.
@interface NSData (XPYData)

// Core hash functions
- (NSData*) SHA1;
- (NSData*) SHA256;
- (NSData*) XPYHash256;  // SHA256(SHA256(self)) aka Hash or Hash256 in PaycoinQT

#if XPYDataRequiresOpenSSL
- (NSData*) RIPEMD160;
- (NSData*) XPYHash160; // RIPEMD160(SHA256(self)) aka Hash160 in PaycoinQT
#endif

// Formats data as a lowercase hex string
- (NSString*) hex;
- (NSString*) uppercaseHex;

- (NSString*) hexString DEPRECATED_ATTRIBUTE;
- (NSString*) hexUppercaseString DEPRECATED_ATTRIBUTE;


// Encrypts/decrypts data using the key.
// IV should either be nil or at least 128 bits long
+ (NSMutableData*) encryptData:(NSData*)data key:(NSData*)key iv:(NSData*)initializationVector;
+ (NSMutableData*) decryptData:(NSData*)data key:(NSData*)key iv:(NSData*)initializationVector;

@end
