// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

// Change to 0 to disable code that requires OpenSSL (if you need some of these routines in your own project and you don't need OpenSSL)
#define XPYDataRequiresOpenSSL 1

// Securely overwrites memory buffer with a specified character.
void *XPYSecureMemset(void *v, unsigned char c, size_t n);

// Securely overwrites string with zeros.
void XPYSecureClearCString(char *s);

// Returns data with securely random bytes of the specified length. Uses /dev/random.
NSMutableData* XPYRandomDataWithLength(NSUInteger length);

// Returns random string with securely random bytes of the specified length. Uses /dev/random.
// Caller should use free() to release the memory occupied by the buffer.
void *XPYCreateRandomBytesOfLength(size_t length);

// Returns data produced by flipping the coin as proposed by Dan Kaminsky:
// https://gist.github.com/PaulCapestany/6148566
NSData* XPYCoinFlipDataWithLength(NSUInteger length);

// Creates data with zero-terminated string in UTF-8 encoding.
NSData* XPYDataWithUTF8CString(const char* utf8cstring);
NSData* XPYDataWithUTF8String(const char* utf8string) DEPRECATED_ATTRIBUTE; // will repurpose for NSString later.

// Init with hex string (lower- or uppercase, with optional 0x prefix)
NSData* XPYDataFromHex(NSString* hex);
NSData* XPYDataWithHexString(NSString* hexString) DEPRECATED_ATTRIBUTE;

// Init with zero-terminated hex string (lower- or uppercase, with optional 0x prefix)
NSData* XPYDataWithHexCString(const char* hexString);

// Converts data to a hex string
NSString* XPYHexFromData(NSData* data);
NSString* XPYUppercaseHexFromData(NSData* data); // more efficient than calling -uppercaseString on a lower-case result.

// Deprecated. Use XPYHexFromData and XPYUppercaseHexFromData instead.
NSString* XPYHexStringFromData(NSData* data) DEPRECATED_ATTRIBUTE;
NSString* XPYUppercaseHexStringFromData(NSData* data) DEPRECATED_ATTRIBUTE;

// Returns a copy of data with reversed byte order.
// This is useful in Paycoin: things get reversed here and there all the time.
NSData* XPYReversedData(NSData* data);

// Returns a reversed mutable copy so you wouldn't need to make another mutable copy from -reversedData
NSMutableData* XPYReversedMutableData(NSData* data);

// Reverses byte order in the internal buffer of mutable data object.
void XPYDataReverse(NSMutableData* data);

// If NSData is NSMutableData clears contents of the data to prevent leaks through swapping or buffer-overflow attacks. Returns YES.
// If NSData is actually an immutable data, does nothing and returns NO.
BOOL XPYDataClear(NSData* data);

// Returns a subdata with a given range.
// If range is invalid, returns nil.
NSMutableData* XPYDataRange(NSData* data, NSRange range);

// Core hash functions that we need.
// If the argument is nil, returns nil.
NSMutableData* XPYSHA1(NSData* data);
NSMutableData* XPYSHA256(NSData* data);
NSMutableData* XPYSHA512(NSData* data);
NSMutableData* XPYSHA256Concat(NSData* data1, NSData* data2); // SHA256(data1 || data2)
NSMutableData* XPYHash256(NSData* data); // == SHA256(SHA256(data)) (aka Hash() in PaycoinQT)
NSMutableData* XPYHash256Concat(NSData* data1, NSData* data2);  // SHA256(SHA256(data1 || data2))

// Standard HMAC-SHA256 and HMAC-SHA512 functions.
NSMutableData* XPYHMACSHA256(NSData* key, NSData* data);
NSMutableData* XPYHMACSHA512(NSData* key, NSData* data);

#if XPYDataRequiresOpenSSL
// RIPEMD160 today is provided only by OpenSSL. SHA1 and SHA2 are provided by CommonCrypto framework.
NSMutableData* XPYRIPEMD160(NSData* data);
NSMutableData* XPYHash160(NSData* data); // == RIPEMD160(SHA256(data)) (aka Hash160 in PaycoinQT)
#endif

// 160-bit zero string
NSMutableData* XPYZero160();

// 256-bit zero string
NSMutableData* XPYZero256();

// Pointer to a static array of zeros (256 bits long).
const unsigned char* XPYZeroString256();


// Hashes input with salt using specified number of rounds and the minimum amount of memory (rounded up to a whole number of 256-bit blocks).
// Actual number of hash function computations is a number of rounds multiplied by a number of 256-bit blocks.
// So rounds=1 for 256 Mb of memory would mean 8M hash function calculations (8M blocks by 32 bytes to form 256 Mb total).
// Uses SHA256 as an internal hash function.
// Password and salt are hashed before being placed in the first block.
// The whole memory region is hashed after all rounds to generate the result.
// Based on proposal by Sergio Demian Lerner http://bitslog.files.wordpress.com/2013/12/memohash-v0-3.pdf
// Returns a mutable data, so you can cleanup the memory when needed.
NSMutableData* XPYMemoryHardKDF256(NSData* password, NSData* salt, unsigned int rounds, unsigned int numberOfBytes);


// Hashes input with salt using specified number of rounds and the minimum amount of memory (rounded up to a whole number of 128-bit blocks)
NSMutableData* XPYMemoryHardAESKDF(NSData* password, NSData* salt, unsigned int rounds, unsigned int numberOfBytes);

// Probabilistic memory-hard KDF with 256-bit output and only one difficulty parameter - amount of memory.
// Actual amount of memory is rounded to a whole number of 256-bit blocks.
// Uses SHA512 as internal hash function.
// Computational time is proportional to amount of memory.
// Brutefore with half the memory raises amount of hash computations quadratically.
NSMutableData* XPYLocustKDF128(NSData* password, NSData* salt, unsigned int numberOfBytes);
NSMutableData* XPYLocustKDF160(NSData* password, NSData* salt, unsigned int numberOfBytes);
NSMutableData* XPYLocustKDF256(NSData* password, NSData* salt, unsigned int numberOfBytes);
NSMutableData* XPYLocustKDF512(NSData* password, NSData* salt, unsigned int numberOfBytes);

// Makes arbitrary-length output.
NSMutableData* XPYLocustKDF(NSData* password, NSData* salt, unsigned int numberOfBytes, unsigned int outputLength);
