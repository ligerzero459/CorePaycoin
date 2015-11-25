// Oleg Andreev <oleganza@gmail.com>

#import "XPYData.h"
#import "XPYKey.h"
#import "XPYBigNumber.h"
#import "XPYCurvePoint+Tests.h"

@implementation XPYCurvePoint (Tests)

+ (void) runAllTests
{
    [self testPublicKey];
    [self testDiffieHellman];
}

+ (void) testPublicKey
{
    // Should be able to create public key N = n*G via XPYKey API as well as raw EC arithmetic using XPYCurvePoint.
    
    NSData* privateKeyData = XPYHash256([@"Private Key Seed" dataUsingEncoding:NSUTF8StringEncoding]);
    
    // 1. Make the pubkey using XPYKey API.
    
    XPYKey* key = [[XPYKey alloc] initWithPrivateKey:privateKeyData];
    
    
    // 2. Make the pubkey using XPYCurvePoint API.
    
    XPYBigNumber* bn = [[XPYBigNumber alloc] initWithUnsignedBigEndian:privateKeyData];
    
    XPYCurvePoint* generator = [XPYCurvePoint generator];
    XPYCurvePoint* pubkeyPoint = [[generator copy] multiply:bn];
    XPYKey* keyFromPoint = [[XPYKey alloc] initWithCurvePoint:pubkeyPoint];
    
    // 2.1. Test serialization
    
    NSAssert([pubkeyPoint isEqual:[[XPYCurvePoint alloc] initWithData:pubkeyPoint.data]], @"test serialization");
    
    // 3. Compare the two pubkeys.
    
    NSAssert([keyFromPoint isEqual:key], @"pubkeys should be equal");
    NSAssert([key.curvePoint isEqual:pubkeyPoint], @"points should be equal");
}

+ (void) testDiffieHellman
{
    // Alice: a, A=a*G. Bob: b, B=b*G.
    // Test shared secret: a*B = b*A = (a*b)*G.
    
    NSData* alicePrivateKeyData = XPYHash256([@"alice private key" dataUsingEncoding:NSUTF8StringEncoding]);
    NSData* bobPrivateKeyData = XPYHash256([@"bob private key" dataUsingEncoding:NSUTF8StringEncoding]);
    
//    NSLog(@"Alice privkey: %@", XPYHexFromData(alicePrivateKeyData));
//    NSLog(@"Bob privkey:   %@", XPYHexFromData(bobPrivateKeyData));
    
    XPYBigNumber* aliceNumber = [[XPYBigNumber alloc] initWithUnsignedBigEndian:alicePrivateKeyData];
    XPYBigNumber* bobNumber = [[XPYBigNumber alloc] initWithUnsignedBigEndian:bobPrivateKeyData];
    
//    NSLog(@"Alice number: %@", aliceNumber.hexString);
//    NSLog(@"Bob number:   %@", bobNumber.hexString);
    
    XPYKey* aliceKey = [[XPYKey alloc] initWithPrivateKey:alicePrivateKeyData];
    XPYKey* bobKey = [[XPYKey alloc] initWithPrivateKey:bobPrivateKeyData];
    
    NSAssert([aliceKey.privateKey isEqual:aliceNumber.unsignedBigEndian], @"");
    NSAssert([bobKey.privateKey isEqual:bobNumber.unsignedBigEndian], @"");
    
    XPYCurvePoint* aliceSharedSecret = [bobKey.curvePoint multiply:aliceNumber];
    XPYCurvePoint* bobSharedSecret   = [aliceKey.curvePoint multiply:bobNumber];
    
//    NSLog(@"(a*B).x = %@", aliceSharedSecret.x.decimalString);
//    NSLog(@"(b*A).x = %@", bobSharedSecret.x.decimalString);
    
    XPYBigNumber* sharedSecretNumber = [[aliceNumber mutableCopy] multiply:bobNumber mod:[XPYCurvePoint curveOrder]];
    XPYCurvePoint* sharedSecret = [[XPYCurvePoint generator] multiply:sharedSecretNumber];
    
    NSAssert([aliceSharedSecret isEqual:bobSharedSecret], @"Should have the same shared secret");
    NSAssert([aliceSharedSecret isEqual:sharedSecret], @"Multiplication of private keys should yield a private key for the shared point");
}


@end
