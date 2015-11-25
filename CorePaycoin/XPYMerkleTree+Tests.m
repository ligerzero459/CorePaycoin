// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYData.h"
#import "XPYMerkleTree+Tests.h"

@implementation XPYMerkleTree (Tests)

+ (void) runAllTests {

    {
        XPYMerkleTree* tree = [[XPYMerkleTree alloc] initWithHashes:nil];
        NSAssert(tree == nil, @"Empty tree is not allowed");
    }

    {
        XPYMerkleTree* tree = [[XPYMerkleTree alloc] initWithHashes:@[]];
        NSAssert(tree == nil, @"Empty tree is not allowed");
    }

    {
        NSData* a = XPYDataFromHex(@"5df6e0e2761359d30a8275058e299fcc0381534545f55cf43e41983f5d4c9456");
        XPYMerkleTree* tree = [[XPYMerkleTree alloc] initWithHashes:@[a]];
        NSAssert([tree.merkleRoot isEqual:a], @"One-hash tree should have the root == that hash");
    }

    {
        NSData* a = XPYDataFromHex(@"9c2e4d8fe97d881430de4e754b4205b9c27ce96715231cffc4337340cb110280");
        NSData* b = XPYDataFromHex(@"0c08173828583fc6ecd6ecdbcca7b6939c49c242ad5107e39deb7b0a5996b903");
        NSData* r = XPYDataFromHex(@"7de236613dd3d9fa1d86054a84952f1e0df2f130546b394a4d4dd7b76997f607");
        XPYMerkleTree* tree = [[XPYMerkleTree alloc] initWithHashes:@[a, b]];
        NSAssert([tree.merkleRoot isEqual:r], @"Two-hash tree should have the root == Hash(a+b)");
    }

    {
        NSData* a = XPYDataFromHex(@"9c2e4d8fe97d881430de4e754b4205b9c27ce96715231cffc4337340cb110280");
        NSData* b = XPYDataFromHex(@"0c08173828583fc6ecd6ecdbcca7b6939c49c242ad5107e39deb7b0a5996b903");
        NSData* c = XPYDataFromHex(@"80903da4e6bbdf96e8ff6fc3966b0cfd355c7e860bdd1caa8e4722d9230e40ac");
        NSData* r = XPYDataFromHex(@"5b7534123197114fa7e7459075f39d89ffab74b5c3f31fad48a025b931ff5a01");
        XPYMerkleTree* tree = [[XPYMerkleTree alloc] initWithHashes:@[a, b, c]];
        NSAssert([tree.merkleRoot isEqual:r], @"Root(a,b,c) == Hash(Hash(a+b)+Hash(c+c))");
    }

}

@end
