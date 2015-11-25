// Oleg Andreev <oleganza@gmail.com>

#import "XPYKeychain.h"
#import "XPYData.h"
#import "XPYKey.h"
#import "XPYCurvePoint.h"
#import "XPYBigNumber.h"
#import "XPYBase58.h"
#import "XPYAddress.h"
#import "XPYNetwork.h"

#define CHECK_IF_CLEARED if (_cleared) { [[NSException exceptionWithName:@"XPYKeychain: instance was already cleared." reason:@"" userInfo:nil] raise]; }

#define XPYKeychainMainnetPrivateVersion 0x0488ADE4
#define XPYKeychainMainnetPublicVersion  0x0488B21E

#define XPYKeychainTestnetPrivateVersion 0x04358394
#define XPYKeychainTestnetPublicVersion  0x043587CF

@interface XPYKeychain ()
@property(nonatomic, readwrite) NSMutableData* chainCode;
@property(nonatomic, readwrite) NSMutableData* extendedPublicKeyData;
@property(nonatomic, readwrite) NSMutableData* extendedPrivateKeyData;
@property(nonatomic, readwrite) NSData* identifier;
@property(nonatomic, readwrite) uint32_t fingerprint;
@property(nonatomic, readwrite) uint32_t parentFingerprint;
@property(nonatomic, readwrite) uint32_t index;
@property(nonatomic, readwrite) uint8_t depth;
@property(nonatomic, readwrite) BOOL hardened;

@property(nonatomic) NSMutableData* privateKey;
@property(nonatomic) NSMutableData* publicKey;
@end

@implementation XPYKeychain {
    BOOL _cleared;
}

- (void)dealloc
{
    [self clear];
}

- (void) clear
{
    XPYDataClear(_chainCode);
    XPYDataClear(_extendedPublicKeyData);
    XPYDataClear(_extendedPrivateKeyData);
    XPYDataClear(_privateKey);
    XPYDataClear(_publicKey);
    _cleared = YES;
}


- (id) initWithSeed:(NSData*)seed {
    return [self initWithSeed:seed network:nil];
}

- (id) initWithSeed:(NSData*)seed network:(XPYNetwork*)network {
    if (self = [super init]) {
        if (!seed) return nil;

        NSMutableData* hmac = XPYHMACSHA512([@"Paycoin seed" dataUsingEncoding:NSASCIIStringEncoding], seed);
        _privateKey = XPYDataRange(hmac, NSMakeRange(0, 32));
        _chainCode  = XPYDataRange(hmac, NSMakeRange(32, 32));
        XPYDataClear(hmac);

        _network = network;
    }
    return self;
}

- (id) initWithExtendedKey:(NSString*)extkey
{
    return [self initWithExtendedKeyDataInternal:XPYDataFromBase58Check(extkey)];
}

- (id) initWithExtendedKeyData:(NSData*)data {
    return [self initWithExtendedKeyDataInternal:data];
}

- (id) initWithExtendedKeyDataInternal:(NSData*)extendedKeyData
{
    if (self = [super init])
    {
        if (extendedKeyData.length != 78) return nil;

        const uint8_t* bytes = extendedKeyData.bytes;
        uint32_t version = OSSwapBigToHostInt32(*((uint32_t*)bytes));

        uint32_t keyprefix = bytes[45];
        
        if (version == XPYKeychainMainnetPrivateVersion ||
            version == XPYKeychainTestnetPrivateVersion) {
            // Should have 0-prefixed private key (1 + 32 bytes).
            if (keyprefix != 0) return nil;
            _privateKey = XPYDataRange(extendedKeyData, NSMakeRange(46, 32));
        }
        else if (version == XPYKeychainMainnetPublicVersion ||
                 version == XPYKeychainTestnetPublicVersion) {
            // Should have a 33-byte public key with non-zero first byte.
            if (keyprefix == 0) return nil;
            _publicKey = XPYDataRange(extendedKeyData, NSMakeRange(45, 33));
        }
        else {
            // Unknown version.
            return nil;
        }

        // If it's a testnet key, remember the network.
        // Otherwise, keep it nil so we don't do extra work if it's not needed.
        if (version == XPYKeychainTestnetPrivateVersion ||
            version == XPYKeychainTestnetPublicVersion) {
            _network = [XPYNetwork testnet];
        }

        _depth = *(bytes + 4);
        _parentFingerprint = OSSwapBigToHostInt32(*((uint32_t*)(bytes + 5)));
        _index = OSSwapBigToHostInt32(*((uint32_t*)(bytes + 9)));
        
        if ((0x80000000 & _index) != 0)
        {
            _index = (~0x80000000) & _index;
            _hardened = YES;
        }
        
        _chainCode = XPYDataRange(extendedKeyData,NSMakeRange(13, 32));
    }
    return self;
}


#pragma mark - Properties


- (XPYNetwork*) network {
    if (!_network) {
        _network = [XPYNetwork mainnet];
    }
    return _network;
}

// deprecated
- (XPYKey*) rootKey
{
    return self.key;
}

- (NSString*) extendedPrivateKey
{
    CHECK_IF_CLEARED;
    return XPYBase58CheckStringWithData([self extendedPrivateKeyDataInternal]);
}

- (NSString*) extendedPublicKey
{
    CHECK_IF_CLEARED;
    return XPYBase58CheckStringWithData([self extendedPublicKeyDataInternal]);
}


- (XPYKey*) key
{
    CHECK_IF_CLEARED;

    if (_privateKey)
    {
        XPYKey* key = [[XPYKey alloc] initWithPrivateKey:_privateKey];
        key.publicKeyCompressed = YES;
        return key;
    }
    else
    {
        return [[XPYKey alloc] initWithPublicKey:self.publicKey];
    }
}

- (NSData*) extendedPrivateKeyData { return [self extendedPrivateKeyDataInternal]; }

- (NSData*) extendedPrivateKeyDataInternal
{
    CHECK_IF_CLEARED;

    if (!_privateKey) return nil;
    
    if (!_extendedPrivateKeyData)
    {
        uint32_t version = [self.network isMainnet] ? XPYKeychainMainnetPrivateVersion : XPYKeychainTestnetPrivateVersion;
        NSMutableData* data = [self extendedKeyPrefixWithVersion:version];
        
        uint8_t padding = 0;
        [data appendBytes:&padding length:1];
        [data appendData:_privateKey];
        
        _extendedPrivateKeyData = data;
    }
    return _extendedPrivateKeyData;
}

- (NSData*) extendedPublicKeyData { return [self extendedPublicKeyDataInternal]; }

- (NSData*) extendedPublicKeyDataInternal
{
    CHECK_IF_CLEARED;

    if (!_extendedPublicKeyData)
    {
        NSData* pubkey = self.publicKey;
        
        if (!pubkey) return nil;

        uint32_t version = [self.network isMainnet] ? XPYKeychainMainnetPublicVersion : XPYKeychainTestnetPublicVersion;
        NSMutableData* data = [self extendedKeyPrefixWithVersion:version];
        
        [data appendData:pubkey];
        
        _extendedPublicKeyData = data;
    }
    return _extendedPublicKeyData;
}

- (NSMutableData*) extendedKeyPrefixWithVersion:(uint32_t)version
{
    CHECK_IF_CLEARED;

    NSMutableData* data = [NSMutableData data];
    
    version = OSSwapHostToBigInt32(version);
    [data appendBytes:&version length:sizeof(version)];
    
    [data appendBytes:&_depth length:1];
    
    uint32_t parentfp = OSSwapHostToBigInt32(_parentFingerprint);
    [data appendBytes:&parentfp length:sizeof(parentfp)];
    
    uint32_t childindex = OSSwapHostToBigInt32(_hardened ? (0x80000000 | _index) : _index);
    [data appendBytes:&childindex length:sizeof(childindex)];
    
    [data appendData:_chainCode];
    
    return data;
}

- (NSData*) identifier
{
    CHECK_IF_CLEARED;

    if (!_identifier)
    {
        _identifier = XPYHash160(self.publicKey);
    }
    return _identifier;
}

- (uint32_t) fingerprint
{
    CHECK_IF_CLEARED;

    if (_fingerprint == 0)
    {
        const uint32_t* words = self.identifier.bytes;
        _fingerprint = OSSwapBigToHostInt32(words[0]);
    }
    return _fingerprint;
}

- (NSData*) publicKey
{
    CHECK_IF_CLEARED;

    if (!_publicKey)
    {
        _publicKey = [[[XPYKey alloc] initWithPrivateKey:_privateKey] compressedPublicKey];
    }
    return _publicKey;
}

- (BOOL) isPrivate
{
    CHECK_IF_CLEARED;
    return !!_privateKey;
}

- (BOOL) isHardened
{
    CHECK_IF_CLEARED;
    return _hardened;
}

- (XPYKeychain*) derivedKeychainAtIndex:(uint32_t)index
{
    return [self derivedKeychainAtIndex:index hardened:NO];
}

- (XPYKeychain*) derivedKeychainAtIndex:(uint32_t)index hardened:(BOOL)hardened
{
    return [self derivedKeychainAtIndex:index hardened:hardened factor:NULL];
}

- (XPYKeychain*) derivedKeychainAtIndex:(uint32_t)index hardened:(BOOL)hardened factor:(XPYBigNumber**)factorOut
{
    CHECK_IF_CLEARED;

    // As we use explicit parameter "hardened", do not allow higher bit set.
    if ((0x80000000 & index) != 0)
    {
        @throw [NSException exceptionWithName:@"XPYKeychain Exception"
                                       reason:@"Indexes >= 0x80000000 are invalid. Use hardened:YES argument instead." userInfo:nil];
        return nil;
    }
    
    if (!_privateKey && hardened)
    {
        // Not possible to derive hardened keychain without a private key.
        return nil;
    }

    XPYKeychain* derivedKeychain = [[XPYKeychain alloc] init];

    NSMutableData* data = [NSMutableData data];
    
    if (hardened)
    {
        uint8_t padding = 0;
        [data appendBytes:&padding length:1];
        [data appendData:_privateKey];
    }
    else
    {
        [data appendData:self.publicKey];
    }
    
    uint32_t indexBE = OSSwapHostToBigInt32(hardened ? (0x80000000 | index) : index);
    [data appendBytes:&indexBE length:sizeof(indexBE)];
    
    NSData* digest = XPYHMACSHA512(_chainCode, data);
    
    XPYBigNumber* factor = [[XPYBigNumber alloc] initWithUnsignedBigEndian:[digest subdataWithRange:NSMakeRange(0, 32)]];
    
    // Factor is too big, this derivation is invalid.
    if ([factor greaterOrEqual:[XPYCurvePoint curveOrder]])
    {
        return nil;
    }
    
    if (factorOut) *factorOut = factor;
    
    derivedKeychain.chainCode = XPYDataRange(digest, NSMakeRange(32, 32));
    
    if (_privateKey)
    {
        XPYMutableBigNumber* pkNumber = [[XPYMutableBigNumber alloc] initWithUnsignedBigEndian:_privateKey];
        [pkNumber add:factor mod:[XPYCurvePoint curveOrder]];
        
        // Check for invalid derivation.
        if ([pkNumber isEqual:[XPYBigNumber zero]]) return nil;
        
        NSData* pkData = pkNumber.unsignedBigEndian;
        derivedKeychain.privateKey = [pkData mutableCopy];
        
        XPYDataClear(pkData);
        [pkNumber clear];
    }
    else
    {
        XPYCurvePoint* point = [[XPYCurvePoint alloc] initWithData:_publicKey];
        [point addGeneratorMultipliedBy:factor];
        
        // Check for invalid derivation.
        if ([point isInfinity]) return nil;
        
        NSData* pointData = point.data;
        derivedKeychain.publicKey = [pointData mutableCopy];
        XPYDataClear(pointData);
        [point clear];
    }
    
    derivedKeychain.depth = _depth + 1;
    derivedKeychain.parentFingerprint = self.fingerprint;
    derivedKeychain.index = index;
    derivedKeychain.hardened = hardened;
    
    return derivedKeychain;
}

- (XPYKey*) keyAtIndex:(uint32_t)index
{
    return [self keyAtIndex:index hardened:NO];
}
- (XPYKey*) keyAtIndex:(uint32_t)index hardened:(BOOL)hardened
{
    return [self derivedKeychainAtIndex:index hardened:hardened].key;
}


// Parses the BIP32 path and derives the chain of keychains accordingly.
// Path syntax: (m?/)?([0-9]+'?(/[0-9]+'?)*)?
// The following paths are valid:
//
// "" (root key)
// "m" (root key)
// "/" (root key)
// "m/0'" (hardened child #0 of the root key)
// "/0'" (hardened child #0 of the root key)
// "0'" (hardened child #0 of the root key)
// "m/44'/1'/2'" (BIP44 testnet account #2)
// "/44'/1'/2'" (BIP44 testnet account #2)
// "44'/1'/2'" (BIP44 testnet account #2)
//
// The following paths are invalid:
//
// "m / 0 / 1" (contains spaces)
// "m/b/c" (alphabetical characters instead of numerical indexes)
// "m/1.2^3" (contains illegal characters)
- (XPYKeychain*) derivedKeychainWithPath:(NSString*)path {

    if (path == nil) return nil;

    if ([path isEqualToString:@"m"] ||
        [path isEqualToString:@"/"] ||
        [path isEqualToString:@""]) {
        return self;
    }

    XPYKeychain* kc = self;

    if ([path rangeOfString:@"m/"].location == 0) { // strip "m/" from the beginning.
        path = [path substringFromIndex:2];
    }
    for (NSString* chunk in [path componentsSeparatedByString:@"/"]) {
        if (chunk.length == 0) {
            continue;
        }
        BOOL hardened = NO;
        NSString* indexString = chunk;
        if ([chunk rangeOfString:@"'"].location == chunk.length - 1) {
            hardened = YES;
            indexString = [chunk substringToIndex:chunk.length - 1];
        }

        // Make sure the chunk is just a number
        NSInteger i = [indexString integerValue];
        if (i >= 0 && [@(i).stringValue isEqualToString:indexString]) {
            kc = [kc derivedKeychainAtIndex:(uint32_t)i hardened:hardened];
        } else {
            return nil;
        }
    }
    return kc;
}

- (XPYKey*) keyWithPath:(NSString*)path {
    return [self derivedKeychainWithPath:path].key;
}

- (XPYKeychain*) publicKeychain
{
    CHECK_IF_CLEARED;

    XPYKeychain* keychain = [[XPYKeychain alloc] init];
    
    keychain.chainCode = [self.chainCode mutableCopy];
    keychain.publicKey = [self.publicKey mutableCopy];
    keychain.parentFingerprint = self.parentFingerprint;
    keychain.index = self.index;
    keychain.depth = self.depth;
    keychain.hardened = self.hardened;
    
    return keychain;
}



// BIP44 methods.
// These methods are meant to be chained like so:
// ```
// invoiceAddress = [[rootKeychain.paycoinMainnetKeychain keychainForAccount:1] externalKeyAtIndex:123].address
// ```


// Returns a subchain with path m/44'/0'
- (XPYKeychain*) paycoinMainnetKeychain
{
    return [[self derivedKeychainAtIndex:44 hardened:YES] derivedKeychainAtIndex:0 hardened:YES];
}

// Returns a subchain with path m/44'/1'
- (XPYKeychain*) paycoinTestnetKeychain
{
    return [[self derivedKeychainAtIndex:44 hardened:YES] derivedKeychainAtIndex:1 hardened:YES];
}

// Returns a hardened derivation for the given account index.
// Equivalent to [keychain derivedKeychainAtIndex:accountIndex hardened:YES]
- (XPYKeychain*) keychainForAccount:(uint32_t)accountIndex
{
    return [self derivedKeychainAtIndex:accountIndex hardened:YES];
}

// Returns a key from an external chain (/0/i).
// XPYKey may be public-only if the receiver is public-only keychain.
- (XPYKey*) externalKeyAtIndex:(uint32_t)index
{
    return [[self derivedKeychainAtIndex:0 hardened:NO] keyAtIndex:index hardened:NO];
}

// Returns a key from an internal (change) chain (/1/i).
// XPYKey may be public-only if the receiver is public-only keychain.
- (XPYKey*) changeKeyAtIndex:(uint32_t)index
{
    return [[self derivedKeychainAtIndex:1 hardened:NO] keyAtIndex:index hardened:NO];
}



#pragma mark - Scanning methods.


// Scans child keys till one is found that matches the given address.
// Only XPYPublicKeyAddress and XPYPrivateKeyAddress are supported. For others nil is returned.
// Limit is maximum number of keys to scan. If no key is found, returns nil.
- (XPYKeychain*) findKeychainForAddress:(XPYAddress*)address hardened:(BOOL)hardened limit:(NSUInteger)limit
{
    return [self findKeychainForAddress:address hardened:hardened from:0 limit:limit];
}

- (XPYKeychain*) findKeychainForAddress:(XPYAddress*)address hardened:(BOOL)hardened from:(uint32_t)startIndex limit:(NSUInteger)limit
{
    CHECK_IF_CLEARED;

    if (!address) return nil;
    if (!self.isPrivate) return nil;
    
    if ([address isKindOfClass:[XPYPrivateKeyAddress class]])
    {
        XPYPrivateKeyAddress* privkeyAddress = (XPYPrivateKeyAddress*)address;
        XPYKey* key = privkeyAddress.key;
        NSMutableData* privkeyData = key.privateKey;
        
        XPYKeychain* result = nil;
        
        for (uint32_t i = startIndex; i < (startIndex + limit); i++)
        {
            XPYKeychain* keychain = [self derivedKeychainAtIndex:i hardened:hardened];
            
            if ([keychain.privateKey isEqual:privkeyData])
            {
                result = keychain;
                break;
            }
            
            [keychain clear];
        }
        
        [key clear];
        XPYDataClear(privkeyData);
        
        return result;
    }
    
    if ([address isKindOfClass:[XPYPublicKeyAddress class]])
    {
        NSData* hash160 = ((XPYPublicKeyAddress*)address).data;
        
        XPYKeychain* result = nil;
        
        for (uint32_t i = startIndex; i < (startIndex + limit); i++)
        {
            XPYKeychain* keychain = [self derivedKeychainAtIndex:i hardened:hardened];
            
            if ([keychain.identifier isEqual:hash160])
            {
                result = keychain;
                break;
            }
            
            [keychain clear];
        }
        
        return result;
    }
    
    return nil;
}


// Scans child keys till one is found that matches the given public key.
// Limit is maximum number of keys to scan. If no key is found, returns nil.
- (XPYKeychain*) findKeychainForPublicKey:(XPYKey*)pubkey hardened:(BOOL)hardened limit:(NSUInteger)limit
{
    return [self findKeychainForPublicKey:pubkey hardened:hardened from:0 limit:limit];
}

- (XPYKeychain*) findKeychainForPublicKey:(XPYKey*)pubkey hardened:(BOOL)hardened from:(uint32_t)startIndex limit:(NSUInteger)limit
{
    CHECK_IF_CLEARED;

    if (!pubkey) return nil;
    if (!self.isPrivate) return nil;
    
    NSData* data = pubkey.compressedPublicKey;
    
    XPYKeychain* result = nil;
    
    for (uint32_t i = startIndex; i < (startIndex + limit); i++)
    {
        XPYKeychain* keychain = [self derivedKeychainAtIndex:i hardened:hardened];
        
        if ([keychain.publicKey isEqual:data])
        {
            result = keychain;
            break;
        }
        
        [keychain clear];
    }
    
    XPYDataClear(data);
    
    return result;
}



#pragma mark - NSObject


- (id) copyWithZone:(NSZone *)zone
{
    CHECK_IF_CLEARED;

    XPYKeychain* keychain = [[XPYKeychain alloc] init];
    
    keychain.chainCode = [self.chainCode mutableCopy];
    keychain.privateKey = [self.privateKey mutableCopy];
    if (!_privateKey) keychain.publicKey = [self.publicKey mutableCopy];
    keychain.parentFingerprint = self.parentFingerprint;
    keychain.index = self.index;
    keychain.depth = self.depth;
    keychain.hardened = self.hardened;
    
    return keychain;
}

- (BOOL) isEqual:(XPYKeychain*)other
{
    CHECK_IF_CLEARED;

    if (self == other) return YES;
    
    if (self.isPrivate != other.isPrivate) return NO;
    if (self.fingerprint != other.fingerprint) return NO;
    if (self.parentFingerprint != other.parentFingerprint) return NO;
    if (self.index != other.index) return NO;
    if (self.hardened != other.hardened) return NO;
    
    if (self.isPrivate)
    {
        if (![self.privateKey isEqual:other.privateKey]) return NO;
    }
    else
    {
        if (![self.publicKey isEqual:other.publicKey]) return NO;
    }
    
    if (![self.chainCode isEqual:other.chainCode]) return NO;
    
    return YES;
}

- (NSUInteger) hash
{
    return self.fingerprint;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"<%@ %@>", [self class], self.extendedPublicKey];
}

- (NSString*) debugDescription
{
    return [NSString stringWithFormat:@"<%@:0x%p depth:%d index:%x%@ parentFingerprint:%x fingerprint:%x privkey:%@ pubkey:%@ chainCode:%@>", [self class], self,
            (int)_depth,
            _index,
            _hardened ? @" hardened:YES" : @"",
            _parentFingerprint,
            self.fingerprint,
            [XPYHexFromData(self.privateKey) substringToIndex:8],
            [XPYHexFromData(self.publicKey) substringToIndex:8],
            [XPYHexFromData(self.chainCode) substringToIndex:8]
            ];
}



@end


