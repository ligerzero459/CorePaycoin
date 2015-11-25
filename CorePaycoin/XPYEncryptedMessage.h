// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

@class XPYKey;

// Implementation of [ECIES](http://en.wikipedia.org/wiki/Integrated_Encryption_Scheme)
// compatible with [Bitcore ECIES](https://github.com/bitpay/bitcore-ecies) implementation.
@interface XPYEncryptedMessage : NSObject

// When encrypting, sender's keypair must contain a private key.
@property(nonatomic) XPYKey* senderKey;

// When decrypting, recipient's keypair must contain a private key.
@property(nonatomic) XPYKey* recipientKey;

- (NSData*) encrypt:(NSData*)plaintext;
- (NSData*) decrypt:(NSData*)ciphertext;

@end
