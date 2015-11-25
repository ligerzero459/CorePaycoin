// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYProcessor.h"
#import "XPYNetwork.h"
#import "XPYBlock.h"
#import "XPYBlockHeader.h"
#import "XPYTransaction.h"
#import "XPYTransactionInput.h"
#import "XPYTransactionOutput.h"

NSString* const XPYProcessorErrorDomain = @"XPYProcessorErrorDomain";

@implementation XPYProcessor

- (id) init
{
    if (self = [super init])
    {
        self.network = [XPYNetwork mainnet];
    }
    return self;
}


// Macros to prepare NSError object and check with delegate if the error should cause failure or not.

#define REJECT_BLOCK_WITH_ERROR(ERROR_CODE, MESSAGE, ...) { \
    NSError* error = [NSError errorWithDomain:XPYProcessorErrorDomain code:(ERROR_CODE) \
                                     userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:MESSAGE, __VA_ARGS__] }]; \
    if ([self shouldRejectBlock:block withError:error]) { \
        [self notifyDidRejectBlock:block withError:error]; \
        *errorOut = error; \
        return NO; \
    } \
}

#define REJECT_BLOCK_WITH_DOS(ERROR_CODE, DOS_LEVEL, MESSAGE, ...) { \
    NSError* error = [NSError errorWithDomain:XPYProcessorErrorDomain code:ERROR_CODE \
                                     userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:MESSAGE, __VA_ARGS__], @"DoS": @(DOS_LEVEL) }]; \
    if ([self shouldRejectBlock:block withError:error]) { \
        [self notifyDidRejectBlock:block withError:error]; \
        *errorOut = error; \
        return NO; \
    } \
}


// Attempts to process the block. Returns YES on success, NO and error on failure.
- (BOOL) processBlock:(XPYBlock*)block error:(NSError**)errorOut
{
    if (!self.dataSource)
    {
        @throw [NSException exceptionWithName:@"Cannot process block" reason:@"-[XPYProcessor dataSource] is nil." userInfo:nil];
    }
    
    // 1. Check for duplicate blocks
    
    NSData* hash = block.blockHash;
    
    if ([self.dataSource blockExistsWithHash:hash])
    {
        REJECT_BLOCK_WITH_ERROR(XPYProcessorErrorDuplicateBlock, NSLocalizedString(@"Already have block %@", @""), hash);
    }
    
    if ([self.dataSource orphanBlockExistsWithHash:hash])
    {
        REJECT_BLOCK_WITH_ERROR(XPYProcessorErrorDuplicateOrphanBlock, NSLocalizedString(@"Already have orphan block %@", @""), hash);
    }
    
    
    
    return YES;
}


// Attempts to add transaction to "memory pool" of unconfirmed transactions.
- (BOOL) processTransaction:(XPYTransaction*)transaction error:(NSError**)errorOut
{
    
    // TODO: ...
    
    return NO;
}



#pragma mark - Helpers


- (BOOL) shouldRejectBlock:(XPYBlock*)block withError:(NSError*)error
{
    return (![self.delegate respondsToSelector:@selector(processor:shouldRejectBlock:withError:)] ||
            [self.delegate processor:self shouldRejectBlock:block withError:error]);
}

- (void) notifyDidRejectBlock:(XPYBlock*)block withError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(processor:didRejectBlock:withError:)])
    {
        [self.delegate processor:self didRejectBlock:block withError:error];
    }
}


@end
