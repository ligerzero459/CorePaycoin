// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

@interface XPYMerkleTree : NSObject

// Returns the merkle root of the tree, a 256-bit hash.
@property(nonatomic, readonly) NSData* merkleRoot;

// Returns YES if the merkle tree has duplicate items in the tail that cause merkle root collision.
// See also CVE-2012-2459.
@property(nonatomic, readonly) BOOL hasTailDuplicates;

// Builds a merkle tree based on raw hashes.
- (id) initWithHashes:(NSArray*)hashes;

// Builds a merkle tree based on transaction hashes.
- (id) initWithTransactions:(NSArray* /* [XPYTransaction] */)transactions;

// Builds a merkle tree based on XPYHash256 hashes of each NSData item.
- (id) initWithDataItems:(NSArray* /* [NSData] */)dataItems;

@end
