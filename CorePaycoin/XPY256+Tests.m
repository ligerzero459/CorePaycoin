// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPY256+Tests.h"
#import "XPY256.h"
#import "XPYData.h"

void XPY256TestChunkSize()
{
    NSCAssert(sizeof(XPY160) == 20, @"160-bit struct should by 160 bit long");
    NSCAssert(sizeof(XPY256) == 32, @"256-bit struct should by 256 bit long");
    NSCAssert(sizeof(XPY512) == 64, @"512-bit struct should by 512 bit long");
}

void XPY256TestNull()
{
    NSCAssert([NSStringFromXPY160(XPY160Null) isEqual:@"82963d5edd842f1e6bd2b6bc2e9a97a40a7d8652"], @"null hash should be correct");
    NSCAssert([NSStringFromXPY256(XPY256Null) isEqual:@"d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"], @"null hash should be correct");
    NSCAssert([NSStringFromXPY512(XPY512Null) isEqual:@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f0363e01b5d7a53c4a2e5a76d283f3e4a04d28ab54849c6e3e874ca31128bcb759e1"], @"null hash should be correct");
}

void XPY256TestOne()
{
    XPY256 one = XPY256Zero;
    one.words64[0] = 1;
    NSCAssert([NSStringFromXPY256(one) isEqual:@"0100000000000000000000000000000000000000000000000000000000000000"], @"");
}

void XPY256TestEqual()
{
    NSCAssert(XPY256Equal(XPY256Null, XPY256Null), @"equal");
    NSCAssert(XPY256Equal(XPY256Zero, XPY256Zero), @"equal");
    NSCAssert(XPY256Equal(XPY256Max,  XPY256Max),  @"equal");
    
    NSCAssert(!XPY256Equal(XPY256Zero, XPY256Null), @"not equal");
    NSCAssert(!XPY256Equal(XPY256Zero, XPY256Max),  @"not equal");
    NSCAssert(!XPY256Equal(XPY256Max,  XPY256Null), @"not equal");
}

void XPY256TestCompare()
{
    NSCAssert(XPY256Compare(XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
                            XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedSame, @"ordered same");

    NSCAssert(XPY256Compare(XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f035"),
                            XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedAscending, @"ordered asc");
    
    NSCAssert(XPY256Compare(XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f037"),
                            XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedDescending, @"ordered asc");

    NSCAssert(XPY256Compare(XPY256FromNSString(@"61ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
                            XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedAscending, @"ordered same");

    NSCAssert(XPY256Compare(XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
                            XPY256FromNSString(@"61ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSOrderedDescending, @"ordered same");

}

void XPY256TestInverse()
{
    XPY256 chunk = XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036");
    XPY256 chunk2 = XPY256Inverse(chunk);
    
    NSCAssert(!XPY256Equal(chunk, chunk2), @"not equal");
    NSCAssert(XPY256Equal(chunk, XPY256Inverse(chunk2)), @"equal");
    
    NSCAssert(chunk2.words64[0] == ~chunk.words64[0], @"bytes are inversed");
    NSCAssert(chunk2.words64[1] == ~chunk.words64[1], @"bytes are inversed");
    NSCAssert(chunk2.words64[2] == ~chunk.words64[2], @"bytes are inversed");
    NSCAssert(chunk2.words64[3] == ~chunk.words64[3], @"bytes are inversed");
    
    NSCAssert(XPY256Equal(XPY256Zero, XPY256AND(chunk, chunk2)), @"(a & ~a) == 000000...");
    NSCAssert(XPY256Equal(XPY256Max, XPY256OR(chunk, chunk2)), @"(a | ~a) == 111111...");
    NSCAssert(XPY256Equal(XPY256Max, XPY256XOR(chunk, chunk2)), @"(a ^ ~a) == 111111...");
}

void XPY256TestSwap()
{
    XPY256 chunk = XPY256FromNSString(@"62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036");
    XPY256 chunk2 = XPY256Swap(chunk);
    NSCAssert([XPYReversedData(NSDataFromXPY256(chunk)) isEqual:NSDataFromXPY256(chunk2)], @"swap should reverse all bytes");
    
    NSCAssert(chunk2.words64[0] == OSSwapConstInt64(chunk.words64[3]), @"swap should reverse all bytes");
    NSCAssert(chunk2.words64[1] == OSSwapConstInt64(chunk.words64[2]), @"swap should reverse all bytes");
    NSCAssert(chunk2.words64[2] == OSSwapConstInt64(chunk.words64[1]), @"swap should reverse all bytes");
    NSCAssert(chunk2.words64[3] == OSSwapConstInt64(chunk.words64[0]), @"swap should reverse all bytes");
}

void XPY256TestAND()
{
    NSCAssert(XPY256Equal(XPY256AND(XPY256Max,  XPY256Max),  XPY256Max),  @"1 & 1 == 1");
    NSCAssert(XPY256Equal(XPY256AND(XPY256Max,  XPY256Zero), XPY256Zero), @"1 & 0 == 0");
    NSCAssert(XPY256Equal(XPY256AND(XPY256Zero, XPY256Max),  XPY256Zero), @"0 & 1 == 0");
    NSCAssert(XPY256Equal(XPY256AND(XPY256Zero, XPY256Null), XPY256Zero), @"0 & x == 0");
    NSCAssert(XPY256Equal(XPY256AND(XPY256Null, XPY256Zero), XPY256Zero), @"x & 0 == 0");
    NSCAssert(XPY256Equal(XPY256AND(XPY256Max,  XPY256Null), XPY256Null), @"1 & x == x");
    NSCAssert(XPY256Equal(XPY256AND(XPY256Null, XPY256Max),  XPY256Null), @"x & 1 == x");
}

void XPY256TestOR()
{
    NSCAssert(XPY256Equal(XPY256OR(XPY256Max,  XPY256Max),  XPY256Max),  @"1 | 1 == 1");
    NSCAssert(XPY256Equal(XPY256OR(XPY256Max,  XPY256Zero), XPY256Max),  @"1 | 0 == 1");
    NSCAssert(XPY256Equal(XPY256OR(XPY256Zero, XPY256Max),  XPY256Max),  @"0 | 1 == 1");
    NSCAssert(XPY256Equal(XPY256OR(XPY256Zero, XPY256Null), XPY256Null), @"0 | x == x");
    NSCAssert(XPY256Equal(XPY256OR(XPY256Null, XPY256Zero), XPY256Null), @"x | 0 == x");
    NSCAssert(XPY256Equal(XPY256OR(XPY256Max,  XPY256Null), XPY256Max),  @"1 | x == 1");
    NSCAssert(XPY256Equal(XPY256OR(XPY256Null, XPY256Max),  XPY256Max),  @"x | 1 == 1");
}

void XPY256TestXOR()
{
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Max,  XPY256Max),  XPY256Zero),  @"1 ^ 1 == 0");
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Max,  XPY256Zero), XPY256Max),  @"1 ^ 0 == 1");
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Zero, XPY256Max),  XPY256Max),  @"0 ^ 1 == 1");
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Zero, XPY256Null), XPY256Null), @"0 ^ x == x");
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Null, XPY256Zero), XPY256Null), @"x ^ 0 == x");
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Max,  XPY256Null), XPY256Inverse(XPY256Null)),  @"1 ^ x == ~x");
    NSCAssert(XPY256Equal(XPY256XOR(XPY256Null, XPY256Max),  XPY256Inverse(XPY256Null)),  @"x ^ 1 == ~x");
}

void XPY256TestConcat()
{
    XPY512 concat = XPY512Concat(XPY256Null, XPY256Max);
    NSCAssert([NSStringFromXPY512(concat) isEqual:@"d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"
               "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"], @"should concatenate properly");
    
    concat = XPY512Concat(XPY256Max, XPY256Null);
    NSCAssert([NSStringFromXPY512(concat) isEqual:@"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
               "d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"], @"should concatenate properly");
    
}

void XPY256TestConvertToData()
{
    // TODO...
}

void XPY256TestConvertToString()
{
    // Too short string should yield null value.
    XPY256 chunk = XPY256FromNSString(@"000095409e215952"
                                       "85b6b5982285aabf"
                                       "a5999a5e845f44c3"
                                       "b9411d5d1007a1");
    NSCAssert(XPY256Equal(chunk, XPY256Null), @"too short string => null");
    
    chunk = XPY256FromNSString(@"000095409e215952"
                                "85b6b5982285aabf"
                                "a5999a5e845f44c3"
                                "b9411d5d1007a1b166");
    NSCAssert(chunk.words64[0] == OSSwapBigToHostConstInt64(0x000095409e215952), @"parse correctly");
    NSCAssert(chunk.words64[1] == OSSwapBigToHostConstInt64(0x85b6b5982285aabf), @"parse correctly");
    NSCAssert(chunk.words64[2] == OSSwapBigToHostConstInt64(0xa5999a5e845f44c3), @"parse correctly");
    NSCAssert(chunk.words64[3] == OSSwapBigToHostConstInt64(0xb9411d5d1007a1b1), @"parse correctly");
    
    NSCAssert([NSStringFromXPY256(chunk) isEqual:@"000095409e215952"
                                                  "85b6b5982285aabf"
                                                  "a5999a5e845f44c3"
                                                  "b9411d5d1007a1b1"], @"should serialize to the same string");
}


void XPY256RunAllTests()
{
    XPY256TestChunkSize();
    XPY256TestNull();
    XPY256TestOne();
    XPY256TestEqual();
    XPY256TestCompare();
    XPY256TestInverse();
    XPY256TestSwap();
    XPY256TestAND();
    XPY256TestOR();
    XPY256TestXOR();
    XPY256TestConcat();
    XPY256TestConvertToData();
    XPY256TestConvertToString();
}

