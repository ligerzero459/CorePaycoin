#import <Foundation/Foundation.h>

#import "XPY256+Tests.h"
#import "XPYData+Tests.h"
#import "XPYMnemonic+Tests.h"
#import "XPYBigNumber+Tests.h"
#import "XPYBase58+Tests.h"
#import "XPYAddress+Tests.h"
#import "XPYProtocolSerialization+Tests.h"
#import "XPYKey+Tests.h"
#import "XPYKeychain+Tests.h"
#import "XPYCurvePoint+Tests.h"
#import "XPYBlindSignature+Tests.h"
#import "XPYEncryptedBackup+Tests.h"
#import "XPYEncryptedMessage+Tests.h"
#import "XPYFancyEncryptedMessage+Tests.h"
#import "XPYScript+Tests.h"
#import "XPYTransaction+Tests.h"
#import "XPYBlockchainInfo+Tests.h"
#import "XPYPriceSource+Tests.h"
#import "XPYMerkleTree+Tests.h"
#import "XPYPaycoinURL+Tests.h"
#import "XPYCurrencyConverter+Tests.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        XPY256RunAllTests();
        [NSData runAllTests];
        [XPYMnemonic runAllTests];
        [XPYBigNumber runAllTests];
        XPYBase58RunAllTests();
        [XPYAddress runAllTests];
        [XPYProtocolSerialization runAllTests];
        [XPYKey runAllTests];
        [XPYCurvePoint runAllTests];
        [XPYKeychain runAllTests];
        [XPYBlindSignature runAllTests];
        [XPYEncryptedBackup runAllTests];
        [XPYEncryptedMessage runAllTests];
        [XPYFancyEncryptedMessage runAllTests];
        [XPYScript runAllTests];
        [XPYMerkleTree runAllTests];
        [XPYBlockchainInfo runAllTests];
        [XPYPriceSource runAllTests];
        [XPYPaycoinURL runAllTests];
        [XPYCurrencyConverter runAllTests];

        [XPYTransaction runAllTests]; // has some interactive features to ask for private key
        NSLog(@"All tests passed.");
    }
    return 0;
}

