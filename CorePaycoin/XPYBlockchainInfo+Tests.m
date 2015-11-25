// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYBlockchainInfo+Tests.h"
#import "XPYAddress.h"
#import "XPYTransactionOutput.h"

@implementation XPYBlockchainInfo (Tests)

+ (void) runAllTests
{
    [self testUnspentOutputs];
}

+ (void) testUnspentOutputs
{
    // our donations address with some outputs: 1CXPYGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG
    // some temp address without outputs: 1LKF45kfvHAaP7C4cF91pVb3bkAsmQ8nBr

    {
        NSError* error = nil;
        NSArray* outputs = [[[XPYBlockchainInfo alloc] init] unspentOutputsWithAddresses:@[ [XPYAddress addressWithString:@"1LKF45kfvHAaP7C4cF91pVb3bkAsmQ8nBr"] ] error:&error];
        
        NSAssert([outputs isEqual:@[]], @"should return an empty array");
        NSAssert(!error, @"should have no error");
    }

    
    {
        NSError* error = nil;
        NSArray* outputs = [[[XPYBlockchainInfo alloc] init] unspentOutputsWithAddresses:@[ [XPYAddress addressWithString:@"1CXPYGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG"] ] error:&error];
        
        NSAssert(outputs.count > 0, @"should return non-empty array");
        NSAssert([outputs.firstObject isKindOfClass:[XPYTransactionOutput class]], @"should contain XPYTransactionOutput objects");
        NSAssert(!error, @"should have no error");
    }
}

@end
