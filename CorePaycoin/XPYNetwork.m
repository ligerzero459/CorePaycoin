// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYNetwork.h"
#import "XPYBigNumber.h"
#import "XPYKey.h"

@implementation XPYNetwork {
    BOOL _isMainnet;
    BOOL _isTestnet;
}

- (id) initWithName:(NSString*)name {
    if (self = [self initWithName:name paymentProtocolName:nil]) {
    }
    return self;
}

- (id) initWithName:(NSString*)name paymentProtocolName:(NSString*)ppName {
    if (self = [super init]) {
        _name = name;
        _paymentProtocolName = ppName;
    }
    return self;
}

+ (XPYNetwork*) mainnet
{
    static XPYNetwork* network;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        network = [[XPYNetwork alloc] initWithName:@"mainnet" paymentProtocolName:@"main"];
        network->_isMainnet = YES;

        // TODO: set all parameters here.
        
    });
    return network;
}

+ (XPYNetwork*) testnet
{
    static XPYNetwork* network;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        network = [[XPYNetwork alloc] initWithName:@"testnet3" paymentProtocolName:@"test"];
        network->_isTestnet = YES;
        
        // TODO: set all parameters here.
        
    });
    return network;
}

- (BOOL) isMainnet {
    return _isMainnet;
}

- (BOOL) isTestnet {
    return _isTestnet;
}

- (NSString*) paymentProtocolName {
    return _paymentProtocolName ?: _name;
}


#pragma mark - Checkpoints


// Returns a checkpoint hash if it exists or nil if there is no checkpoint at such height.
- (NSData*) checkpointAtHeight:(int)height {
    for (NSArray* pair in self.checkpoints) {
        int h = [pair[0] intValue];
        if (h == height) {
            return pair[1];
        }
    }
    return nil;
}

// Returns height of checkpoint or -1 if there is no such checkpoint.
- (int) heightForCheckpoint:(NSData*)checkpointHash {
    if (!checkpointHash) return -1;
    
    for (NSArray* pair in self.checkpoints) {
        if ([pair[1] isEqual:checkpointHash]) {
            return [pair[0] intValue];
        }
    }
    return -1;
}



#pragma mark - NSCopying


- (id) copyWithZone:(NSZone *)zone
{
    XPYNetwork* network = [[XPYNetwork alloc] copy];
    
    network->_isTestnet      = _isTestnet;
    network.name             = self.name;
    network.genesisBlockHash = self.genesisBlockHash;
    network.defaultPort      = self.defaultPort;
    network.proofOfWorkLimit = [self.proofOfWorkLimit copy];
    network.checkpoints      = [self.checkpoints copy];
    
    return network;
}

@end
