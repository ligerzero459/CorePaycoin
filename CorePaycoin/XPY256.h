// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// A set of ubiquitous types and functions to deal with fixed-length chunks of data
// (160-bit, 256-bit and 512-bit). These are relevant almost always to hashes,
// but there's no hash-specific about them.
// The purpose of these is to avoid dynamic memory allocations via NSData when
// we need to move exactly 32 bytes around.
//
// We don't call these XPYFixedData256 because these types are way too ubiquituous
// in CorePaycoin to have such an explicit name.
//
// Somewhat similar to uint256 in paycoind, but here we don't try
// to pretend that these are integers and then allow arithmetic on them
// and create a mess with the byte order.
// Use XPYBigNumber to do arithmetic on big numbers and convert
// to bignum format explicitly.
// XPYBigNumber has API for converting XPY256 to a big int.
//
// We also declare XPY160 and XPY512 for use with RIPEMD-160, SHA-1 and SHA-512 hashes.


// 1. Fixed-length types

struct private_XPY160
{
    // 160 bits can't be formed with 64-bit words, so we have to use 32-bit ones instead.
    uint32_t words32[5];
} __attribute__((packed));
typedef struct private_XPY160 XPY160;

struct private_XPY256
{
    // Since all modern CPUs are 64-bit (ARM is 64-bit starting with iPhone 5s),
    // we will use 64-bit words.
    uint64_t words64[4];
} __attribute__((aligned(1)));
typedef struct private_XPY256 XPY256;

struct private_XPY512
{
    // Since all modern CPUs are 64-bit (ARM is 64-bit starting with iPhone 5s),
    // we will use 64-bit words.
    uint64_t words64[8];
} __attribute__((aligned(1)));
typedef struct private_XPY512 XPY512;


// 2. Constants

// All-zero constants
extern const XPY160 XPY160Zero;
extern const XPY256 XPY256Zero;
extern const XPY512 XPY512Zero;

// All-one constants
extern const XPY160 XPY160Max;
extern const XPY256 XPY256Max;
extern const XPY512 XPY512Max;

// First 160 bits of SHA512("CorePaycoin/XPY160Null")
extern const XPY160 XPY160Null;

// First 256 bits of SHA512("CorePaycoin/XPY256Null")
extern const XPY256 XPY256Null;

// Value of SHA512("CorePaycoin/XPY512Null")
extern const XPY512 XPY512Null;


// 3. Comparison

BOOL XPY160Equal(XPY160 chunk1, XPY160 chunk2);
BOOL XPY256Equal(XPY256 chunk1, XPY256 chunk2);
BOOL XPY512Equal(XPY512 chunk1, XPY512 chunk2);

NSComparisonResult XPY160Compare(XPY160 chunk1, XPY160 chunk2);
NSComparisonResult XPY256Compare(XPY256 chunk1, XPY256 chunk2);
NSComparisonResult XPY512Compare(XPY512 chunk1, XPY512 chunk2);


// 4. Operations


// Inverse (b = ~a)
XPY160 XPY160Inverse(XPY160 chunk);
XPY256 XPY256Inverse(XPY256 chunk);
XPY512 XPY512Inverse(XPY512 chunk);

// Swap byte order
XPY160 XPY160Swap(XPY160 chunk);
XPY256 XPY256Swap(XPY256 chunk);
XPY512 XPY512Swap(XPY512 chunk);

// Bitwise AND operation (a & b)
XPY160 XPY160AND(XPY160 chunk1, XPY160 chunk2);
XPY256 XPY256AND(XPY256 chunk1, XPY256 chunk2);
XPY512 XPY512AND(XPY512 chunk1, XPY512 chunk2);

// Bitwise OR operation (a | b)
XPY160 XPY160OR(XPY160 chunk1, XPY160 chunk2);
XPY256 XPY256OR(XPY256 chunk1, XPY256 chunk2);
XPY512 XPY512OR(XPY512 chunk1, XPY512 chunk2);

// Bitwise exclusive-OR operation (a ^ b)
XPY160 XPY160XOR(XPY160 chunk1, XPY160 chunk2);
XPY256 XPY256XOR(XPY256 chunk1, XPY256 chunk2);
XPY512 XPY512XOR(XPY512 chunk1, XPY512 chunk2);

// Concatenation of two 256-bit chunks
XPY512 XPY512Concat(XPY256 chunk1, XPY256 chunk2);


// 5. Conversion functions


// Conversion to NSData
NSData* NSDataFromXPY160(XPY160 chunk);
NSData* NSDataFromXPY256(XPY256 chunk);
NSData* NSDataFromXPY512(XPY512 chunk);

// Conversion from NSData.
// If NSData is not big enough, returns XPYHash{160,256,512}Null.
XPY160 XPY160FromNSData(NSData* data);
XPY256 XPY256FromNSData(NSData* data);
XPY512 XPY512FromNSData(NSData* data);

// Returns lowercase hex representation of the chunk
NSString* NSStringFromXPY160(XPY160 chunk);
NSString* NSStringFromXPY256(XPY256 chunk);
NSString* NSStringFromXPY512(XPY512 chunk);

// Conversion from hex NSString (lower- or uppercase).
// If string is invalid or data is too short, returns XPYHash{160,256,512}Null.
XPY160 XPY160FromNSString(NSString* string);
XPY256 XPY256FromNSString(NSString* string);
XPY512 XPY512FromNSString(NSString* string);



