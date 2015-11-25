// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYAssetID.h"
#import "XPYAddressSubclass.h"

static const uint8_t XPYAssetIDVersionMainnet = 23; // "A" prefix
static const uint8_t XPYAssetIDVersionTestnet = 115;

@implementation XPYAssetID

+ (void) load {
    [XPYAddress registerAddressClass:self version:XPYAssetIDVersionMainnet];
    [XPYAddress registerAddressClass:self version:XPYAssetIDVersionTestnet];
}

#define XPYAssetIDLength 20

+ (instancetype) assetIDWithString:(NSString*)string {
    return [self addressWithString:string];
}

+ (instancetype) assetIDWithHash:(NSData*)data {
    if (!data) return nil;
    if (data.length != XPYAssetIDLength)
    {
        NSLog(@"+[XPYAssetID addressWithData] cannot init with hash %d bytes long", (int)data.length);
        return nil;
    }
    XPYAssetID* addr = [[self alloc] init];
    addr.data = [NSMutableData dataWithData:data];
    return addr;
}

+ (instancetype) addressWithComposedData:(NSData*)composedData cstring:(const char*)cstring version:(uint8_t)version {
    if (composedData.length != (1 + XPYAssetIDLength))
    {
        NSLog(@"XPYAssetID: cannot init with %d bytes (need 20+1 bytes)", (int)composedData.length);
        return nil;
    }
    XPYAssetID* addr = [[self alloc] init];
    addr.data = [[NSMutableData alloc] initWithBytes:((const char*)composedData.bytes) + 1 length:composedData.length - 1];
    return addr;
}

- (NSMutableData*) dataForBase58Encoding {
    NSMutableData* data = [NSMutableData dataWithLength:1 + XPYAssetIDLength];
    char* buf = data.mutableBytes;
    buf[0] = [self versionByte];
    memcpy(buf + 1, self.data.bytes, XPYAssetIDLength);
    return data;
}

- (uint8_t) versionByte {
#warning TODO: support testnet
    return XPYAssetIDVersionMainnet;
}


@end
