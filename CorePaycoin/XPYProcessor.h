// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

@class XPYBlock;
@class XPYTransaction;
@class XPYProcessor;
@class XPYNetwork;

extern NSString* const XPYProcessorErrorDomain;

typedef NS_ENUM(NSUInteger, XPYProcessorError) {
    
    // Block already stored in the blockchain (on mainchain or sidechain)
    XPYProcessorErrorDuplicateBlock,
    
    // Block already stored as orphan
    XPYProcessorErrorDuplicateOrphanBlock,
    
    // Block has timestamp below last downloaded checkpoint.
    XPYProcessorErrorTimestampBeforeLastCheckpoint,
    
    // Proof of work is below the minimum possible since the last checkpoint.
    XPYProcessorErrorBelowCheckpointProofOfWork,
    
};

// Data source implements actual storage for blocks, block headers and transactions.
@protocol XPYProcessorDataSource <NSObject>
@required

// Returns a block in the blockchain (mainchain or sidechain), or nil if block is missing.
- (XPYBlock*) blockWithHash:(NSData*)hash;

// Returns YES if the block exists in the blockchain (mainchain or sidechain).
- (BOOL) blockExistsWithHash:(NSData*)hash;

// Returns orphan block with the given hash (or nil if block is not stored among orphans).
- (XPYBlock*) orphanBlockWithHash:(NSData*)hash;

// Returns YES if orphan block exists.
- (BOOL) orphanBlockExistsWithHash:(NSData*)hash;

@end



// Delegate allows to handle errors and selectively ignore them for testing purposes.
@protocol XPYProcessorDelegate <NSObject>
@optional

// For some error codes, userInfo[@"DoS"] contains level of DoS punishment.
// If this method returns NO, error is ignored and processing continues.
- (BOOL) processor:(XPYProcessor*)processor shouldRejectBlock:(XPYBlock*)block withError:(NSError*)error;

// Sent when processing stopped because of an error.
- (void) processor:(XPYProcessor*)processor didRejectBlock:(XPYBlock*)block withError:(NSError*)error;

@end



// Processor implements validation and processing of the incoming blocks and unconfirmed transactions.
// It defers storage to data source which takes care of storing and retrieving all objects efficiently.
@interface XPYProcessor : NSObject

// Network (mainnet/testnet) that should be used by processor.
// Default is mainnet.
@property(nonatomic) XPYNetwork* network;

// Data source provides block headers, blocks, and transactions during the process of verification.
// Should not be nil when processing blocks and transactions.
@property(nonatomic, weak) id<XPYProcessorDataSource> dataSource;

// Delegate allows fine-grained control of errors that happen. Can be nil.
@property(nonatomic, weak) id<XPYProcessorDelegate> delegate;

// Attempts to process the block. Returns YES on success, NO and error on failure.
// Make sure to set dataSource before calling this method.
// See ProcessBlock() in paycoind.
- (BOOL) processBlock:(XPYBlock*)block error:(NSError**)errorOut;

// Attempts to add transaction to "memory pool" of unconfirmed transactions.
// Make sure to set dataSource before calling this method.
// See AcceptToMemoryPool() in paycoind.
- (BOOL) processTransaction:(XPYTransaction*)transaction error:(NSError**)errorOut;

@end
