// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYSignatureHashType.h"

@class XPYCurvePoint;
@class XPYPublicKeyAddress;
@class XPYPublicKeyAddressTestnet;
@class XPYPrivateKeyAddress;
@class XPYPrivateKeyAddressTestnet;

// XPYKey encapsulates EC public and private keypair (or only public part) on curve secp256k1.
// You can sign data and verify signatures.
// When instantiated with a public key, only signature verification is possible.
// When instantiated with a private key, all operations are available.
@interface XPYKey : NSObject

// Newly generated random key pair.
- (id) init;

// Instantiates a key without a secret counterpart.
// You can use -isValidSignature:hash:
- (id) initWithPublicKey:(NSData*)publicKey;

// Initializes public key using a point on elliptic curve secp256k1.
- (id) initWithCurvePoint:(XPYCurvePoint*)curvePoint;

// Instantiates a key with secret parameter (32 bytes).
- (id) initWithPrivateKey:(NSData*)privateKey;

// Instantiates with a WIF-encoded private key (52 bytes like 5znkrJzL5GTFCaXWufUCUaPzDmLj2Pe2pWtAcSzg4hRUVxS2XqHa).
// See also -initWithPrivateKeyAddress.
- (id) initWithWIF:(NSString*)wifString;

// Instantiates with a DER-encoded private key (279 bytes).
- (id) initWithDERPrivateKey:(NSData*)DERPrivateKey;

// These properties return mutable copy of data so you can clear it if needed.

// publicKey is compressed if -publicKeyCompressed is YES.
@property(nonatomic, readonly) NSMutableData* publicKey;

// These are returning explicitly compressed or uncompressed copies of the public key.
@property(nonatomic, readonly) NSMutableData* compressedPublicKey;
@property(nonatomic, readonly) NSMutableData* uncompressedPublicKey;

// 32-byte secret parameter. That's all you need to get full key pair on secp256k1
@property(nonatomic, readonly) NSMutableData* privateKey;

// DER-encoded private key (279-byte) that includes secret and all curve parameters.
@property(nonatomic, readonly) NSMutableData* DERPrivateKey;

// Base58-encoded private key (or nil if privkey is not available).
@property(nonatomic, readonly) NSString* WIF;
@property(nonatomic, readonly) NSString* WIFTestnet;

// When you set public key, this property reflects whether it is compressed or not.
// To set this property you must have private counterpart. Then, -publicKey will be compressed/uncompressed accordingly.
@property(nonatomic, getter=isPublicKeyCompressed) BOOL publicKeyCompressed;

// Returns public key as a point on secp256k1 curve.
@property(nonatomic, readonly) XPYCurvePoint* curvePoint;

// Verifies signature for a given hash with a public key.
- (BOOL) isValidSignature:(NSData*)signature hash:(NSData*)hash;

// Multiplies a public key of the receiver with a given private key and returns resulting curve point as XPYKey object (pubkey only).
// Pubkey compression flag is the same as on receiver.
- (XPYKey*) diffieHellmanWithPrivateKey:(XPYKey*)privkey;

// Returns a signature data for a 256-bit hash using private key.
// Returns nil if signing failed or a private key is not present.
- (NSData*) signatureForHash:(NSData*)hash;

// Same as above, but also appends a hash type byte to the signature.
- (NSData*) signatureForHash:(NSData*)hash hashType:(XPYSignatureHashType)hashType;
- (NSData*) signatureForHash:(NSData*)hash withHashType:(XPYSignatureHashType)hashType DEPRECATED_ATTRIBUTE;

// [RFC6979 implementation](https://tools.ietf.org/html/rfc6979).
// Returns 32-byte `k` nonce generated deterministically from the `hash` and the private key.
// Returns a mutable data to make it clearable.
- (NSMutableData*) signatureNonceForHash:(NSData*)hash;

// Clears all key data from memory making receiver invalid.
- (void) clear;


// XPYAddress Import/Export


// Instantiate with a private key in a form of address. Also takes care about compressing pubkey if needed.
- (id) initWithPrivateKeyAddress:(XPYPrivateKeyAddress*)privateKeyAddress;

// Public key hash.
// IMPORTANT: resulting address depends on whether `publicKeyCompressed` is YES or NO.
@property(nonatomic, readonly) XPYPublicKeyAddress* publicKeyAddress DEPRECATED_ATTRIBUTE;

// Public key hash.
// IMPORTANT: resulting address depends on whether `publicKeyCompressed` is YES or NO.
@property(nonatomic, readonly) XPYPublicKeyAddress* address;
@property(nonatomic, readonly) XPYPublicKeyAddressTestnet* addressTestnet;

// Returns address for a public key (Hash160(pubkey)).
@property(nonatomic, readonly) XPYPublicKeyAddress* uncompressedPublicKeyAddress;
@property(nonatomic, readonly) XPYPublicKeyAddress* compressedPublicKeyAddress;

// Private key encoded in sipa format (base58 with compression flag).
@property(nonatomic, readonly) XPYPrivateKeyAddress* privateKeyAddress;
@property(nonatomic, readonly) XPYPrivateKeyAddressTestnet* privateKeyAddressTestnet;





// Compact Signature
// 65 byte signature, which allows reconstructing the used public key.

// Returns a compact signature for 256-bit hash. Aka "CKey::SignCompact" in PaycoinQT.
// Initially used for signing text messages (see XPYKey+PaycoinSignedMessage).
- (NSData*) compactSignatureForHash:(NSData*)data;

// Verifies digest against given compact signature. On success returns a public key.
+ (XPYKey*) verifyCompactSignature:(NSData*)compactSignature forHash:(NSData*)hash;

// Verifies signature of the hash with its public key.
- (BOOL) isValidCompactSignature:(NSData*)signature forHash:(NSData*)hash;





// Paycoin Signed Message
// PaycoinQT-compatible textual message signing API



// Returns a signature for message prepended with "Paycoin Signed Message:\n" line.
- (NSData*) signatureForMessage:(NSString*)message;
- (NSData*) signatureForBinaryMessage:(NSData*)data;

// Verifies message against given signature. On success returns a public key.
+ (XPYKey*) verifySignature:(NSData*)signature forMessage:(NSString*)message;
+ (XPYKey*) verifySignature:(NSData*)signature forBinaryMessage:(NSData*)data;

// Verifies signature of the message with its public key.
- (BOOL) isValidSignature:(NSData*)signature forMessage:(NSString*)message;
- (BOOL) isValidSignature:(NSData*)signature forBinaryMessage:(NSData*)data;


// Canonical checks

// Used by PaycoinQT within OP_CHECKSIG to not relay transactions with non-canonical signature or a public key.
// Normally, signatures and pubkeys are encoded in a canonical form and majority of the transactions are good.
// Unfortunately, sometimes OpenSSL segfaults on some garbage data in place of a signature or a pubkey.
// Read more on that here: https://paycointalk.org/index.php?topic=8392.80

// Note: non-canonical pubkey could still be valid for EC internals of OpenSSL and thus accepted by Paycoin nodes.
+ (BOOL) isCanonicalPublicKey:(NSData*)data error:(NSError**)errorOut;

// Checks if the script signature is canonical.
// The signature is assumed to include hash type byte (see XPYSignatureHashType).
+ (BOOL) isCanonicalSignatureWithHashType:(NSData*)data verifyLowerS:(BOOL)verifyLowerS error:(NSError**)errorOut;

+ (BOOL) isCanonicalSignatureWithHashType:(NSData*)data verifyEvenS:(BOOL)verifyEvenS error:(NSError**)errorOut DEPRECATED_ATTRIBUTE;


@end

