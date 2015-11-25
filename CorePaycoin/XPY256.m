// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPY256.h"
#import "XPYData.h"

// 1. Structs are already defined in the .h file.

// 2. Constants

const XPY160 XPY160Zero = {0,0,0,0,0};
const XPY256 XPY256Zero = {0,0,0,0};
const XPY512 XPY512Zero = {0,0,0,0,0,0,0,0};

const XPY160 XPY160Max = {0xffffffff,0xffffffff,0xffffffff,0xffffffff,0xffffffff};
const XPY256 XPY256Max = {0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL};
const XPY512 XPY512Max = {0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,
                          0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL,0xffffffffffffffffLL};

// Using ints assuming little-endian platform. 160-bit chunk actually begins with 82963d5e. Same thing about the rest.
// Digest::SHA512.hexdigest("CorePaycoin/XPY160Null")[0,2*20].scan(/.{8}/).map{|x| "0x" + x.scan(/../).reverse.join}.join(",")
// 82963d5edd842f1e6bd2b6bc2e9a97a40a7d8652
const XPY160 XPY160Null = {0x5e3d9682,0x1e2f84dd,0xbcb6d26b,0xa4979a2e,0x52867d0a};

// Digest::SHA512.hexdigest("CorePaycoin/XPY256Null")[0,2*32].scan(/.{16}/).map{|x| "0x" + x.scan(/../).reverse.join}.join(",")
// d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e
const XPY256 XPY256Null = {0x54e926e81f7a00d1LL,0xc3445f849515e209LL,0x98b5b685521d41b9LL,0x5e9a99a5bfaa8522LL};

// Digest::SHA512.hexdigest("CorePaycoin/XPY512Null")[0,2*64].scan(/.{16}/).map{|x| "0x" + x.scan(/../).reverse.join}.join(",")
// 62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f0363e01b5d7a53c4a2e5a76d283f3e4a04d28ab54849c6e3e874ca31128bcb759e1
const XPY512 XPY512Null = {0x6e6e8392dd64ce62LL,0x5236623fee3ed899LL,0xf27222c2f89c04f6LL,0x36f038178662b295LL,0x2e4a3ca5d7b5013eLL,0x4da0e4f383d2765aLL,0x873e6e9c8454ab28LL,0xe159b7bc2811a34cLL};


// 3. Comparison

BOOL XPY160Equal(XPY160 chunk1, XPY160 chunk2)
{
// Which one is faster: memcmp or word-by-word check? The latter does not need any loop or extra checks to compare bytes.
//    return memcmp(&chunk1, &chunk2, sizeof(chunk1)) == 0;
    return chunk1.words32[0] == chunk2.words32[0]
        && chunk1.words32[1] == chunk2.words32[1]
        && chunk1.words32[2] == chunk2.words32[2]
        && chunk1.words32[3] == chunk2.words32[3]
        && chunk1.words32[4] == chunk2.words32[4];
}

BOOL XPY256Equal(XPY256 chunk1, XPY256 chunk2)
{
    return chunk1.words64[0] == chunk2.words64[0]
        && chunk1.words64[1] == chunk2.words64[1]
        && chunk1.words64[2] == chunk2.words64[2]
        && chunk1.words64[3] == chunk2.words64[3];
}

BOOL XPY512Equal(XPY512 chunk1, XPY512 chunk2)
{
    return chunk1.words64[0] == chunk2.words64[0]
        && chunk1.words64[1] == chunk2.words64[1]
        && chunk1.words64[2] == chunk2.words64[2]
        && chunk1.words64[3] == chunk2.words64[3]
        && chunk1.words64[4] == chunk2.words64[4]
        && chunk1.words64[5] == chunk2.words64[5]
        && chunk1.words64[6] == chunk2.words64[6]
        && chunk1.words64[7] == chunk2.words64[7];
}

NSComparisonResult XPY160Compare(XPY160 chunk1, XPY160 chunk2)
{
    int r = memcmp(&chunk1, &chunk2, sizeof(chunk1));
    
         if (r > 0) return NSOrderedDescending;
    else if (r < 0) return NSOrderedAscending;
    return NSOrderedSame;
}

NSComparisonResult XPY256Compare(XPY256 chunk1, XPY256 chunk2)
{
    int r = memcmp(&chunk1, &chunk2, sizeof(chunk1));
    
         if (r > 0) return NSOrderedDescending;
    else if (r < 0) return NSOrderedAscending;
    return NSOrderedSame;
}

NSComparisonResult XPY512Compare(XPY512 chunk1, XPY512 chunk2)
{
    int r = memcmp(&chunk1, &chunk2, sizeof(chunk1));
    
         if (r > 0) return NSOrderedDescending;
    else if (r < 0) return NSOrderedAscending;
    return NSOrderedSame;
}



// 4. Operations


// Inverse (b = ~a)
XPY160 XPY160Inverse(XPY160 chunk)
{
    chunk.words32[0] = ~chunk.words32[0];
    chunk.words32[1] = ~chunk.words32[1];
    chunk.words32[2] = ~chunk.words32[2];
    chunk.words32[3] = ~chunk.words32[3];
    chunk.words32[4] = ~chunk.words32[4];
    return chunk;
}

XPY256 XPY256Inverse(XPY256 chunk)
{
    chunk.words64[0] = ~chunk.words64[0];
    chunk.words64[1] = ~chunk.words64[1];
    chunk.words64[2] = ~chunk.words64[2];
    chunk.words64[3] = ~chunk.words64[3];
    return chunk;
}

XPY512 XPY512Inverse(XPY512 chunk)
{
    chunk.words64[0] = ~chunk.words64[0];
    chunk.words64[1] = ~chunk.words64[1];
    chunk.words64[2] = ~chunk.words64[2];
    chunk.words64[3] = ~chunk.words64[3];
    chunk.words64[4] = ~chunk.words64[4];
    chunk.words64[5] = ~chunk.words64[5];
    chunk.words64[6] = ~chunk.words64[6];
    chunk.words64[7] = ~chunk.words64[7];
    return chunk;
}

// Swap byte order
XPY160 XPY160Swap(XPY160 chunk)
{
    XPY160 chunk2;
    chunk2.words32[4] = OSSwapConstInt32(chunk.words32[0]);
    chunk2.words32[3] = OSSwapConstInt32(chunk.words32[1]);
    chunk2.words32[2] = OSSwapConstInt32(chunk.words32[2]);
    chunk2.words32[1] = OSSwapConstInt32(chunk.words32[3]);
    chunk2.words32[0] = OSSwapConstInt32(chunk.words32[4]);
    return chunk2;
}

XPY256 XPY256Swap(XPY256 chunk)
{
    XPY256 chunk2;
    chunk2.words64[3] = OSSwapConstInt64(chunk.words64[0]);
    chunk2.words64[2] = OSSwapConstInt64(chunk.words64[1]);
    chunk2.words64[1] = OSSwapConstInt64(chunk.words64[2]);
    chunk2.words64[0] = OSSwapConstInt64(chunk.words64[3]);
    return chunk2;
}

XPY512 XPY512Swap(XPY512 chunk)
{
    XPY512 chunk2;
    chunk2.words64[7] = OSSwapConstInt64(chunk.words64[0]);
    chunk2.words64[6] = OSSwapConstInt64(chunk.words64[1]);
    chunk2.words64[5] = OSSwapConstInt64(chunk.words64[2]);
    chunk2.words64[4] = OSSwapConstInt64(chunk.words64[3]);
    chunk2.words64[3] = OSSwapConstInt64(chunk.words64[4]);
    chunk2.words64[2] = OSSwapConstInt64(chunk.words64[5]);
    chunk2.words64[1] = OSSwapConstInt64(chunk.words64[6]);
    chunk2.words64[0] = OSSwapConstInt64(chunk.words64[7]);
    return chunk2;
}

// Bitwise AND operation (a & b)
XPY160 XPY160AND(XPY160 chunk1, XPY160 chunk2)
{
    chunk1.words32[0] = chunk1.words32[0] & chunk2.words32[0];
    chunk1.words32[1] = chunk1.words32[1] & chunk2.words32[1];
    chunk1.words32[2] = chunk1.words32[2] & chunk2.words32[2];
    chunk1.words32[3] = chunk1.words32[3] & chunk2.words32[3];
    chunk1.words32[4] = chunk1.words32[4] & chunk2.words32[4];
    return chunk1;
}

XPY256 XPY256AND(XPY256 chunk1, XPY256 chunk2)
{
    chunk1.words64[0] = chunk1.words64[0] & chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] & chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] & chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] & chunk2.words64[3];
    return chunk1;
}

XPY512 XPY512AND(XPY512 chunk1, XPY512 chunk2)
{
    chunk1.words64[0] = chunk1.words64[0] & chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] & chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] & chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] & chunk2.words64[3];
    chunk1.words64[4] = chunk1.words64[4] & chunk2.words64[4];
    chunk1.words64[5] = chunk1.words64[5] & chunk2.words64[5];
    chunk1.words64[6] = chunk1.words64[6] & chunk2.words64[6];
    chunk1.words64[7] = chunk1.words64[7] & chunk2.words64[7];
    return chunk1;
}

// Bitwise OR operation (a | b)
XPY160 XPY160OR(XPY160 chunk1, XPY160 chunk2)
{
    chunk1.words32[0] = chunk1.words32[0] | chunk2.words32[0];
    chunk1.words32[1] = chunk1.words32[1] | chunk2.words32[1];
    chunk1.words32[2] = chunk1.words32[2] | chunk2.words32[2];
    chunk1.words32[3] = chunk1.words32[3] | chunk2.words32[3];
    chunk1.words32[4] = chunk1.words32[4] | chunk2.words32[4];
    return chunk1;
}

XPY256 XPY256OR(XPY256 chunk1, XPY256 chunk2)
{
    chunk1.words64[0] = chunk1.words64[0] | chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] | chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] | chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] | chunk2.words64[3];
    return chunk1;
}

XPY512 XPY512OR(XPY512 chunk1, XPY512 chunk2)
{
    chunk1.words64[0] = chunk1.words64[0] | chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] | chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] | chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] | chunk2.words64[3];
    chunk1.words64[4] = chunk1.words64[4] | chunk2.words64[4];
    chunk1.words64[5] = chunk1.words64[5] | chunk2.words64[5];
    chunk1.words64[6] = chunk1.words64[6] | chunk2.words64[6];
    chunk1.words64[7] = chunk1.words64[7] | chunk2.words64[7];
    return chunk1;
}

// Bitwise exclusive-OR operation (a ^ b)
XPY160 XPY160XOR(XPY160 chunk1, XPY160 chunk2)
{
    chunk1.words32[0] = chunk1.words32[0] ^ chunk2.words32[0];
    chunk1.words32[1] = chunk1.words32[1] ^ chunk2.words32[1];
    chunk1.words32[2] = chunk1.words32[2] ^ chunk2.words32[2];
    chunk1.words32[3] = chunk1.words32[3] ^ chunk2.words32[3];
    chunk1.words32[4] = chunk1.words32[4] ^ chunk2.words32[4];
    return chunk1;
}

XPY256 XPY256XOR(XPY256 chunk1, XPY256 chunk2)
{
    chunk1.words64[0] = chunk1.words64[0] ^ chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] ^ chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] ^ chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] ^ chunk2.words64[3];
    return chunk1;
}

XPY512 XPY512XOR(XPY512 chunk1, XPY512 chunk2)
{
    chunk1.words64[0] = chunk1.words64[0] ^ chunk2.words64[0];
    chunk1.words64[1] = chunk1.words64[1] ^ chunk2.words64[1];
    chunk1.words64[2] = chunk1.words64[2] ^ chunk2.words64[2];
    chunk1.words64[3] = chunk1.words64[3] ^ chunk2.words64[3];
    chunk1.words64[4] = chunk1.words64[4] ^ chunk2.words64[4];
    chunk1.words64[5] = chunk1.words64[5] ^ chunk2.words64[5];
    chunk1.words64[6] = chunk1.words64[6] ^ chunk2.words64[6];
    chunk1.words64[7] = chunk1.words64[7] ^ chunk2.words64[7];
    return chunk1;
}

XPY512 XPY512Concat(XPY256 chunk1, XPY256 chunk2)
{
    XPY512 result;
    *((XPY256*)(&result)) = chunk1;
    *((XPY256*)(((unsigned char*)&result) + sizeof(chunk2))) = chunk2;
    return result;
}


// 5. Conversion functions


// Conversion to NSData
NSData* NSDataFromXPY160(XPY160 chunk)
{
    return [[NSData alloc] initWithBytes:&chunk length:sizeof(chunk)];
}

NSData* NSDataFromXPY256(XPY256 chunk)
{
    return [[NSData alloc] initWithBytes:&chunk length:sizeof(chunk)];
}

NSData* NSDataFromXPY512(XPY512 chunk)
{
    return [[NSData alloc] initWithBytes:&chunk length:sizeof(chunk)];
}

// Conversion from NSData.
// If NSData is not big enough, returns XPYHash{160,256,512}Null.
XPY160 XPY160FromNSData(NSData* data)
{
    if (data.length < 160/8) return XPY160Null;
    XPY160 chunk = *((XPY160*)data.bytes);
    return chunk;
}

XPY256 XPY256FromNSData(NSData* data)
{
    if (data.length < 256/8) return XPY256Null;
    XPY256 chunk = *((XPY256*)data.bytes);
    return chunk;
}

XPY512 XPY512FromNSData(NSData* data)
{
    if (data.length < 512/8) return XPY512Null;
    XPY512 chunk = *((XPY512*)data.bytes);
    return chunk;
}


// Returns lowercase hex representation of the chunk

NSString* NSStringFromXPY160(XPY160 chunk)
{
    const int length = 20;
    char dest[2*length + 1];
    const unsigned char *src = (unsigned char *)&chunk;
    for (int i = 0; i < length; ++i)
    {
        sprintf(dest + i*2, "%02x", (unsigned int)(src[i]));
    }
    return [[NSString alloc] initWithBytes:dest length:2*length encoding:NSASCIIStringEncoding];
}

NSString* NSStringFromXPY256(XPY256 chunk)
{
    const int length = 32;
    char dest[2*length + 1];
    const unsigned char *src = (unsigned char *)&chunk;
    for (int i = 0; i < length; ++i)
    {
        sprintf(dest + i*2, "%02x", (unsigned int)(src[i]));
    }
    return [[NSString alloc] initWithBytes:dest length:2*length encoding:NSASCIIStringEncoding];
}

NSString* NSStringFromXPY512(XPY512 chunk)
{
    const int length = 64;
    char dest[2*length + 1];
    const unsigned char *src = (unsigned char *)&chunk;
    for (int i = 0; i < length; ++i)
    {
        sprintf(dest + i*2, "%02x", (unsigned int)(src[i]));
    }
    return [[NSString alloc] initWithBytes:dest length:2*length encoding:NSASCIIStringEncoding];
}

// Conversion from hex NSString (lower- or uppercase).
// If string is invalid or data is too short, returns XPYHash{160,256,512}Null.
XPY160 XPY160FromNSString(NSString* string)
{
    return XPY160FromNSData(XPYDataFromHex(string));
}

XPY256 XPY256FromNSString(NSString* string)
{
    return XPY256FromNSData(XPYDataFromHex(string));
}

XPY512 XPY512FromNSString(NSString* string)
{
    return XPY512FromNSData(XPYDataFromHex(string));
}



