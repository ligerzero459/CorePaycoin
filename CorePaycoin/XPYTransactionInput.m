// Oleg Andreev <oleganza@gmail.com>

#import "XPYTransaction.h"
#import "XPYTransactionInput.h"
#import "XPYTransactionOutput.h"
#import "XPYScript.h"
#import "XPYProtocolSerialization.h"
#import "XPYData.h"
#import "XPYHashID.h"
#import "XPYOutpoint.h"

@interface XPYTransactionInput ()
@end

static const uint32_t XPYInvalidIndex = 0xFFFFFFFF; // aka "(unsigned int) -1" in PaycoinQT.
static const uint32_t XPYMaxSequence = 0xFFFFFFFF;


@implementation XPYTransactionInput

- (id) init
{
    if (self = [super init])
    {
        _previousHash = XPYZero256();
        _previousIndex = XPYInvalidIndex;
        _signatureScript = [[XPYScript alloc] init];
        _sequence = XPYMaxSequence; // max
        _value = -1;
    }
    return self;
}

// Parses tx input from a data buffer.
- (id) initWithData:(NSData*)data
{
    if (self = [self init])
    {
        if (![self parseData:data]) return nil;
    }
    return self;
}

// Read tx input from the stream.
- (id) initWithStream:(NSInputStream*)stream
{
    if (self = [self init])
    {
        if (![self parseStream:stream]) return nil;
    }
    return self;
}

// Constructs transaction input from a dictionary representation
- (id) initWithDictionary:(NSDictionary*)dictionary
{
    if (self = [self init])
    {
        NSString* prevHashString = (dictionary[@"prev_out"] ?: @{})[@"hash"];
        if (prevHashString) _previousHash = XPYReversedData(XPYDataFromHex(prevHashString));
        NSNumber* prevIndexNumber = (dictionary[@"prev_out"] ?: @{})[@"n"];
        if (prevIndexNumber) _previousIndex = prevIndexNumber.unsignedIntValue;
        
        if (dictionary[@"coinbase"])
        {
            _coinbaseData = XPYDataFromHex(dictionary[@"coinbase"]);
        }
        else
        {
            // PaycoinQT RPC creates {"asm": ..., "hex": ...} dictionary for this key instead of an ASM-like string like paycoin-ruby and paycoinjs.
            id scriptSig = dictionary[@"scriptSig"];
            
            if ([scriptSig isKindOfClass:[NSString class]])
            {
                _signatureScript = [[XPYScript alloc] initWithString:scriptSig];
            }
            else if ([scriptSig isKindOfClass:[NSDictionary class]])
            {
                if (scriptSig[@"hex"])
                {
                    _signatureScript = [[XPYScript alloc] initWithData:XPYDataFromHex(scriptSig[@"hex"])];
                }
                else if (scriptSig[@"asm"])
                {
                    _signatureScript = [[XPYScript alloc] initWithString:scriptSig[@"asm"]];
                }
            }
        }
        
        if (!_signatureScript)
        {
            return nil;
        }
        
        NSNumber* seqNumber = dictionary[@"sequence"];
        if (seqNumber) _sequence = [seqNumber unsignedIntValue];
        
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    XPYTransactionInput* txin = [[XPYTransactionInput alloc] init];
    txin.previousHash = [self.previousHash copy];
    txin.previousIndex = self.previousIndex;
    txin.signatureScript = [self.signatureScript copy];
    txin.sequence = self.sequence;

    txin.transaction = _transaction;
    txin.transactionOutput = _transactionOutput;
    txin.userInfo = _userInfo;

    return txin;
}

- (NSData*) data
{
    return [self computePayload];
}

- (NSData*) computePayload
{
    NSMutableData* payload = [NSMutableData data];
    
    [payload appendData:_previousHash];
    [payload appendBytes:&_previousIndex length:4];

    if (self.isCoinbase)
    {
        [payload appendData:[XPYProtocolSerialization dataForVarInt:self.coinbaseData.length]];
        [payload appendData:self.coinbaseData];
    }
    else
    {
        NSData* scriptData = _signatureScript.data;
        [payload appendData:[XPYProtocolSerialization dataForVarInt:scriptData.length]];
        [payload appendData:scriptData];
    }
    
    [payload appendBytes:&_sequence length:4];
    
    return payload;
}

- (XPYOutpoint*) outpoint
{
    return [[XPYOutpoint alloc] initWithHash:self.previousHash index:self.previousIndex];
}

- (void) setOutpoint:(XPYOutpoint *)outpoint
{
    self.previousHash = outpoint.txHash;
    self.previousIndex = outpoint.index;
}

- (NSString*) previousTransactionID
{
    return XPYIDFromHash(self.previousHash);
}

- (void) setPreviousTransactionID:(NSString *)previousTransactionID
{
    self.previousHash = XPYHashFromID(previousTransactionID);
}

// Returns a dictionary representation suitable for encoding in JSON or Plist.
- (NSDictionary*) dictionaryRepresentation
{
    return self.dictionary;
}

- (NSDictionary*) dictionary
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    dict[@"prev_out"] = @{
                        @"hash": XPYHexFromData(XPYReversedData(_previousHash)), // transaction hashes are reversed
                        @"n": @(_previousIndex),
                        };
    
    if ([self isCoinbase])
    {
        dict[@"coinbase"] = XPYHexFromData(_coinbaseData);
    }
    else
    {
        // Latest PaycoinQT does this: "scriptSig": {"asm": "assembly-style script with spaces and literal ops", "hex": "raw script in hex" }
        // Here and in paycoin-qt we use only "asm" style script.
        // (But we support reading PaycoinQT style in initWithDictionary:)
        dict[@"scriptSig"] = _signatureScript.string;
    }
    
    if (_sequence != XPYMaxSequence)
    {
        dict[@"sequence"] = [NSString stringWithFormat:@"%08x", _sequence];
    }
    return dict;
}








#pragma mark - Serialization and parsing



- (BOOL) parseData:(NSData*)data
{
    if (!data) return NO;
    NSInputStream* stream = [NSInputStream inputStreamWithData:data];
    [stream open];
    BOOL result = [self parseStream:stream];
    [stream close];
    return result;
}

- (BOOL) parseStream:(NSInputStream*)stream
{
    if (!stream) return NO;
    if (stream.streamStatus == NSStreamStatusClosed) return NO;
    if (stream.streamStatus == NSStreamStatusNotOpen) return NO;
    
    // Read previousHash
    uint8_t hash[32] = {0};
    if ([stream read:(uint8_t*)hash maxLength:sizeof(hash)] != sizeof(hash)) return NO;
    _previousHash = [NSData dataWithBytes:hash length:sizeof(hash)];
    
    // Read previousIndex
    if ([stream read:(uint8_t*)(&_previousIndex) maxLength:sizeof(_previousIndex)] != sizeof(_previousIndex)) return NO;
    
    // Read signature script
    NSData* scriptdata = [XPYProtocolSerialization readVarStringFromStream:stream];
    if (!scriptdata) return NO;

    if ([self isCoinbase])
    {
        _coinbaseData = scriptdata;
    }
    else
    {
        _signatureScript = [[XPYScript alloc] initWithData:scriptdata];
    }
    
    // Read sequence
    if ([stream read:(uint8_t*)(&_sequence) maxLength:sizeof(_sequence)] != sizeof(_sequence)) return NO;
    
    return YES;
}


- (BOOL) isCoinbase
{
    return (_previousIndex == XPYInvalidIndex) &&
            _previousHash.length == 32 &&
            0 == memcmp(XPYZeroString256(), _previousHash.bytes, 32);
}



#pragma mark - Informational Properties



- (XPYAmount) value
{
    if (_value != -1) {
        return _value;
    }
    if (_transactionOutput) {
        return _transactionOutput.value;
    }
    return -1;
}


@end

