// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYOutpoint.h"
#import "XPYTransaction.h"
#import "XPYHashID.h"

@implementation XPYOutpoint

- (id) initWithHash:(NSData*)hash index:(uint32_t)index
{
    if (hash.length != 32) return nil;
    if (self = [super init])
    {
        _txHash = hash;
        _index = index;
    }
    return self;
}

- (id) initWithTxID:(NSString*)txid index:(uint32_t)index
{
    NSData* hash = XPYHashFromID(txid);
    return [self initWithHash:hash index:index];
}

- (NSString*) txID
{
    return XPYIDFromHash(self.txHash);
}

- (void) setTxID:(NSString *)txID
{
    self.txHash = XPYHashFromID(txID);
}

- (NSUInteger) hash
{
    const NSUInteger* words = _txHash.bytes;
    return words[0] + self.index;
}

- (BOOL) isEqual:(XPYOutpoint*)object
{
    return [self.txHash isEqual:object.txHash] && self.index == object.index;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[XPYOutpoint alloc] initWithHash:_txHash index:_index];
}

@end
