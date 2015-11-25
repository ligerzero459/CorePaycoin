// Oleg Andreev <oleganza@gmail.com>

#import "XPYBigNumber+Tests.h"
#import "XPYData.h"

@implementation XPYBigNumber (Tests)

+ (void) runAllTests
{
    NSAssert([[[XPYBigNumber alloc] init] isEqual:[XPYBigNumber zero]], @"default bignum should be zero");
    NSAssert(![[[XPYBigNumber alloc] init] isEqual:[XPYBigNumber one]], @"default bignum should not be one");
    NSAssert([@"0" isEqualToString:[[[XPYBigNumber alloc] init] stringInBase:10]], @"default bignum should be zero");
    NSAssert([[[XPYBigNumber alloc] initWithInt32:0] isEqual:[XPYBigNumber zero]], @"0 should be equal to itself");
    
    NSAssert([[XPYBigNumber one] isEqual:[XPYBigNumber one]], @"1 should be equal to itself");
    NSAssert([[XPYBigNumber one] isEqual:[[XPYBigNumber alloc] initWithUInt32:1]], @"1 should be equal to itself");
    
    NSAssert([[[XPYBigNumber one] stringInBase:16] isEqual:@"1"], @"1 should be correctly printed out");
    NSAssert([[[[XPYBigNumber alloc] initWithUInt32:1] stringInBase:16] isEqual:@"1"], @"1 should be correctly printed out");
    NSAssert([[[[XPYBigNumber alloc] initWithUInt32:0xdeadf00d] stringInBase:16] isEqual:@"deadf00d"], @"0xdeadf00d should be correctly printed out");
    
    NSAssert([[[[XPYBigNumber alloc] initWithUInt64:0xdeadf00ddeadf00d] stringInBase:16] isEqual:@"deadf00ddeadf00d"], @"0xdeadf00ddeadf00d should be correctly printed out");

    NSAssert([[[[XPYBigNumber alloc] initWithString:@"0b1010111" base:2] stringInBase:2] isEqual:@"1010111"], @"0b1010111 should be correctly parsed");
    NSAssert([[[[XPYBigNumber alloc] initWithString:@"0x12346789abcdef" base:16] stringInBase:16] isEqual:@"12346789abcdef"], @"0x12346789abcdef should be correctly parsed");
    
    {
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithUInt64:0xdeadf00ddeadbeef];
        NSData* data = bn.signedLittleEndian;
        NSAssert([@"efbeadde0df0adde00" isEqualToString:XPYHexFromData(data)], @"littleEndianData should be little-endian with trailing zero byte");
        XPYBigNumber* bn2 = [[XPYBigNumber alloc] initWithSignedLittleEndian:data];
        NSAssert([@"deadf00ddeadbeef" isEqualToString:bn2.hexString], @"converting to and from data should give the same result");
    }
    
    
    // Negative zero
    {
        XPYBigNumber* zeroBN = [XPYBigNumber zero];
        XPYBigNumber* negativeZeroBN = [[XPYBigNumber alloc] initWithSignedLittleEndian:XPYDataFromHex(@"80")];
        XPYBigNumber* zeroWithEmptyDataBN = [[XPYBigNumber alloc] initWithSignedLittleEndian:[NSData data]];
        
        //NSLog(@"negativeZeroBN.data = %@", negativeZeroBN.data);
        
        NSAssert(zeroBN, @"must exist");
        NSAssert(negativeZeroBN, @"must exist");
        NSAssert(zeroWithEmptyDataBN, @"must exist");
        
        //NSLog(@"negative zero: %lld", [negativeZeroBN int64value]);
        
        NSAssert([[[zeroBN mutableCopy] add:[[XPYBigNumber alloc] initWithInt32:1]] isEqual:[XPYBigNumber one]], @"0 + 1 == 1");
        NSAssert([[[negativeZeroBN mutableCopy] add:[[XPYBigNumber alloc] initWithInt32:1]] isEqual:[XPYBigNumber one]], @"0 + 1 == 1");
        NSAssert([[[zeroWithEmptyDataBN mutableCopy] add:[[XPYBigNumber alloc] initWithInt32:1]] isEqual:[XPYBigNumber one]], @"0 + 1 == 1");
        
        // In PaycoinQT script.cpp, there is check (bn != bnZero).
        // It covers negative zero alright because "bn" is created in a way that discards the sign.
        NSAssert(![zeroBN isEqual:negativeZeroBN], @"zero should != negative zero");
    }
    
    // Experiments:

    return;

    {
        //XPYBigNumber* bn = [XPYBigNumber zero];
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithUnsignedBigEndian:XPYDataFromHex(@"00")];
        NSLog(@"bn = %@ %@ (%@) 0x%@ b36:%@", bn, bn.unsignedBigEndian, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }

    {
        //XPYBigNumber* bn = [XPYBigNumber one];
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithUnsignedBigEndian:XPYDataFromHex(@"01")];
        NSLog(@"bn = %@ %@ (%@) 0x%@ b36:%@", bn, bn.unsignedBigEndian, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }

    {
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithUInt32:0xdeadf00dL];
        NSLog(@"bn = %@ (%@) 0x%@ b36:%@", bn, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }
    {
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithInt32:-16];
        NSLog(@"bn = %@ (%@) 0x%@ b36:%@", bn, bn.decimalString, [bn stringInBase:16], [bn stringInBase:36]);
    }
    
    {
        int base = 17;
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithString:@"123" base:base];
        NSLog(@"bn = %@", [bn stringInBase:base]);
    }
    {
        int base = 2;
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithString:@"0b123" base:base];
        NSLog(@"bn = %@", [bn stringInBase:base]);
    }

    {
        XPYBigNumber* bn = [[XPYBigNumber alloc] initWithUInt64:0xdeadf00ddeadbeef];
        NSData* data = bn.signedLittleEndian;
        XPYBigNumber* bn2 = [[XPYBigNumber alloc] initWithSignedLittleEndian:data];
        NSLog(@"bn = %@", [bn2 hexString]);
    }
}

@end
