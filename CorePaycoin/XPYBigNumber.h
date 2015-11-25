// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import <openssl/bn.h>

// Paycoin-flavoured big number wrapping OpenSSL BIGNUM.
// It is doing byte ordering like paycoind does to stay compatible.
// XPYBigNumber is immutable. XPYMutableBigNumber is its mutable counterpart.
// -copy always returns immutable instance, like in other Cocoa containers.
@class XPYBigNumber;
@class XPYMutableBigNumber;

@interface XPYBigNumber : NSObject <NSCopying, NSMutableCopying>

@property(nonatomic, readonly) uint32_t compact; // compact representation used for the difficulty target
@property(nonatomic, readonly) uint32_t uint32value;
@property(nonatomic, readonly) int32_t int32value;
@property(nonatomic, readonly) uint64_t uint64value;
@property(nonatomic, readonly) int64_t int64value;
@property(nonatomic, readonly) NSString* hexString;
@property(nonatomic, readonly) NSString* decimalString;
@property(nonatomic, readonly) NSData* signedLittleEndian;
@property(nonatomic, readonly) NSData* unsignedBigEndian;

// Deprecated. Use `-signedLittleEndian` instead.
@property(nonatomic, readonly) NSData* littleEndianData DEPRECATED_ATTRIBUTE;

// Deprecated. Use `-unsignedBigEndian` instead.
@property(nonatomic, readonly) NSData* unsignedData DEPRECATED_ATTRIBUTE;

// Pointer to an internal BIGNUM value. You should not modify it.
// To modify, use [[bn mutableCopy] mutableBIGNUM] methods.
@property(nonatomic, readonly) const BIGNUM* BIGNUM;

@property(nonatomic, readonly) BOOL isZero;
@property(nonatomic, readonly) BOOL isOne;


// XPYBigNumber returns always the same object for these constants.
// XPYMutableBigNumber returns a new object every time.
+ (instancetype) zero;        //  0
+ (instancetype) one;         //  1
+ (instancetype) negativeOne; // -1

- (id) init;
- (id) initWithCompact:(uint32_t)compact;
- (id) initWithUInt32:(uint32_t)value;
- (id) initWithInt32:(int32_t)value;
- (id) initWithUInt64:(uint64_t)value;
- (id) initWithInt64:(int64_t)value;
- (id) initWithSignedLittleEndian:(NSData*)data;
- (id) initWithUnsignedBigEndian:(NSData*)data;
- (id) initWithLittleEndianData:(NSData*)data DEPRECATED_ATTRIBUTE;
- (id) initWithUnsignedData:(NSData*)data DEPRECATED_ATTRIBUTE;


// Initialized with OpenSSL representation of bignum.
- (id) initWithBIGNUM:(const BIGNUM*)bignum;

// Inits with setString:base:
- (id) initWithString:(NSString*)string base:(NSUInteger)base;

// Same as initWithString:base:16
- (id) initWithHexString:(NSString*)hexString DEPRECATED_ATTRIBUTE;

// Same as initWithString:base:10
- (id) initWithDecimalString:(NSString*)decimalString;

- (NSString*) stringInBase:(NSUInteger)base;

// Re-declared copy and mutableCopy to provide exact return type.
- (XPYBigNumber*) copy;
- (XPYMutableBigNumber*) mutableCopy;

// TODO: maybe add support for hash, figure out what the heck is that.
//void set_hash(hash_digest load_hash);
//hash_digest hash() const;

// Returns MIN(self, other)
- (XPYBigNumber*) min:(XPYBigNumber*)other;

// Returns MAX(self, other)
- (XPYBigNumber*) max:(XPYBigNumber*)other;


- (BOOL) less:(XPYBigNumber*)other;
- (BOOL) lessOrEqual:(XPYBigNumber*)other;
- (BOOL) greater:(XPYBigNumber*)other;
- (BOOL) greaterOrEqual:(XPYBigNumber*)other;


// Divides receiver by another bignum.
// Returns an array of two new XPYBigNumber instances: @[ quotient, remainder ]
- (NSArray*) divmod:(XPYBigNumber*)other;

// Destroys sensitive data and sets the value to 0.
// It is also called on dealloc.
// This method is available for both mutable and immutable numbers by design.
- (void) clear;

@end


@interface XPYMutableBigNumber : XPYBigNumber

@property(nonatomic, readwrite) uint32_t compact; // compact representation used for the difficulty target
@property(nonatomic, readwrite) uint32_t uint32value;
@property(nonatomic, readwrite) int32_t int32value;
@property(nonatomic, readwrite) uint64_t uint64value;
@property(nonatomic, readwrite) int64_t int64value;
@property(nonatomic, readwrite) NSString* hexString;
@property(nonatomic, readwrite) NSString* decimalString;
@property(nonatomic, readwrite) NSData* signedLittleEndian;
@property(nonatomic, readwrite) NSData* unsignedBigEndian;
@property(nonatomic, readwrite) NSData* littleEndianData DEPRECATED_ATTRIBUTE;
@property(nonatomic, readwrite) NSData* unsignedData DEPRECATED_ATTRIBUTE;

@property(nonatomic, readonly) BIGNUM* mutableBIGNUM;

// XPYBigNumber returns always the same object for these constants.
// XPYMutableBigNumber returns a new object every time.
+ (instancetype) zero;        //  0
+ (instancetype) one;         //  1
+ (instancetype) negativeOne; // -1

// Supports bases from 2 to 36. For base 2 allows optional 0b prefix, base 16 allows optional 0x prefix. Spaces are ignored.
- (void) setString:(NSString*)string base:(NSUInteger)base;

// Operators modify the receiver and return self.
// To create a new instance z = x + y use copy method: z = [[x copy] add:y]
- (instancetype) add:(XPYBigNumber*)other; // +=
- (instancetype) add:(XPYBigNumber*)other mod:(XPYBigNumber*)mod;
- (instancetype) subtract:(XPYBigNumber*)other; // -=
- (instancetype) subtract:(XPYBigNumber*)other mod:(XPYBigNumber*)mod;
- (instancetype) multiply:(XPYBigNumber*)other; // *=
- (instancetype) multiply:(XPYBigNumber*)other mod:(XPYBigNumber*)mod;
- (instancetype) divide:(XPYBigNumber*)other; // /=
- (instancetype) mod:(XPYBigNumber*)other; // %=
- (instancetype) lshift:(unsigned int)shift; // <<=
- (instancetype) rshift:(unsigned int)shift; // >>=
- (instancetype) inverseMod:(XPYBigNumber*)mod; // (a^-1) mod n

@end
