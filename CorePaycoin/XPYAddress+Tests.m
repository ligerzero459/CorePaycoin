#import "NSData+XPYData.h"
#import "NS+XPYBase58.h"
#import "XPYAddress+Tests.h"

@implementation XPYAddress (Tests)

+ (void) runAllTests
{
    [self testPublicKeyAddress];
    [self testPrivateKeyAddress];
    [self testPrivateKeyAddressWithCompressedPoint];
    [self testScriptHashKeyAddress];
}

+ (void) testPublicKeyAddress
{
    XPYPublicKeyAddress* addr = [XPYPublicKeyAddress addressWithString:@"1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T"];
    NSAssert(addr, @"Address should be decoded");
    NSAssert([addr isKindOfClass:[XPYPublicKeyAddress class]], @"Address should be an instance of XPYPublicKeyAddress");
    NSAssert([@"c4c5d791fcb4654a1ef5e03fe0ad3d9c598f9827" isEqualToString:[addr.data hex]], @"Must decode hash160 correctly.");
    NSAssert([addr isEqual:addr.publicAddress], @"Address should be equal to its publicAddress");

    XPYPublicKeyAddress* addr2 = [XPYPublicKeyAddress addressWithData:XPYDataFromHex(@"c4c5d791fcb4654a1ef5e03fe0ad3d9c598f9827")];
    NSAssert(addr2, @"Address should be created");
    NSAssert([@"1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T" isEqualToString:addr2.string], @"Must encode hash160 correctly.");
}

+ (void) testPrivateKeyAddress
{
    XPYPrivateKeyAddress* addr = [XPYPrivateKeyAddress addressWithString:@"5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS"];
    NSAssert(addr, @"Address should be decoded");
    NSAssert([addr isKindOfClass:[XPYPrivateKeyAddress class]], @"Address should be an instance of XPYPrivateKeyAddress");
    NSAssert(!addr.isPublicKeyCompressed, @"Address should be not compressed");
    NSAssert([@"c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a" isEqualToString:addr.data.hex], @"Must decode secret key correctly.");
    NSAssert([[addr publicAddress].string isEqual:@"1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T"], @"must provide proper public address");
    
    XPYPrivateKeyAddress* addr2 = [XPYPrivateKeyAddress addressWithData:XPYDataFromHex(@"c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a")];
    NSAssert(addr2, @"Address should be created");
    NSAssert([@"5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS" isEqualToString:addr2.string], @"Must encode secret key correctly.");
}

+ (void) testPrivateKeyAddressWithCompressedPoint
{
    XPYPrivateKeyAddress* addr = [XPYPrivateKeyAddress addressWithString:@"L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu"];
    NSAssert(addr, @"Address should be decoded");
    NSAssert([addr isKindOfClass:[XPYPrivateKeyAddress class]], @"Address should be an instance of XPYPrivateKeyAddress");
    NSAssert(addr.isPublicKeyCompressed, @"Address should be compressed");
    NSAssert([@"c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a" isEqualToString:addr.data.hex], @"Must decode secret key correctly.");
    NSAssert([[addr publicAddress].string isEqual:@"1C7zdTfnkzmr13HfA2vNm5SJYRK6nEKyq8"], @"must provide proper public address");

    XPYPrivateKeyAddress* addr2 = [XPYPrivateKeyAddress addressWithData:XPYDataFromHex(@"c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a")];
    NSAssert(addr2, @"Address should be created");
    addr2.publicKeyCompressed = YES;
    NSAssert([@"L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu" isEqualToString:addr2.string], @"Must encode secret key correctly.");
    addr2.publicKeyCompressed = NO;
    NSAssert([@"5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS" isEqualToString:addr2.string], @"Must encode secret key correctly.");
}

+ (void) testScriptHashKeyAddress
{
    XPYScriptHashAddress* addr = [XPYScriptHashAddress addressWithString:@"3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8"];
    NSAssert(addr, @"Address should be decoded");
    NSAssert([addr isKindOfClass:[XPYScriptHashAddress class]], @"Address should be an instance of XPYScriptHashAddress");
    NSAssert([@"e8c300c87986efa84c37c0519929019ef86eb5b4" isEqualToString:addr.data.hex], @"Must decode hash160 correctly.");
    NSAssert([addr isEqual:addr.publicAddress], @"Address should be equal to its publicAddress");

    XPYScriptHashAddress* addr2 = [XPYScriptHashAddress addressWithData:XPYDataFromHex(@"e8c300c87986efa84c37c0519929019ef86eb5b4")];
    NSAssert(addr2, @"Address should be created");
    NSAssert([@"3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8" isEqualToString:addr2.string], @"Must encode hash160 correctly.");
}

@end
