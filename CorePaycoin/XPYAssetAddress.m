// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYAssetAddress.h"
#import "XPYData.h"
#import "XPYBase58.h"

@interface XPYAssetAddress ()
@property(nonatomic, readwrite) XPYAddress* paycoinAddress;
@end

// OpenAssets Address, e.g. akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy (corresponds to 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM)
@implementation XPYAssetAddress

#define XPYAssetAddressNamespace 0x13

+ (void) load {
    [XPYAddress registerAddressClass:self version:XPYAssetAddressNamespace];
}

+ (instancetype) addressWithPaycoinAddress:(XPYAddress*)XPYAddress {
    if (!XPYAddress) return nil;
    XPYAssetAddress* addr = [[self alloc] init];
    addr.paycoinAddress = XPYAddress;
    return addr;
}

+ (instancetype) addressWithString:(NSString*)string {
    NSMutableData* composedData = XPYDataFromBase58Check(string);
    uint8_t version = ((unsigned char*)composedData.bytes)[0];
    return [self addressWithComposedData:composedData cstring:[string cStringUsingEncoding:NSUTF8StringEncoding] version:version];
}

+ (instancetype) addressWithComposedData:(NSData*)composedData cstring:(const char*)cstring version:(uint8_t)version {
    if (!composedData) return nil;
    if (composedData.length < 2) return nil;

    if (version == XPYAssetAddressNamespace) { // same for testnet and mainnet
        XPYAddress* XPYAddr = [XPYAddress addressWithString:XPYBase58CheckStringWithData([composedData subdataWithRange:NSMakeRange(1, composedData.length - 1)])];
        return [self addressWithPaycoinAddress:XPYAddr];
    } else {
        return nil;
    }
}

- (NSMutableData*) dataForBase58Encoding {
    NSMutableData* data = [NSMutableData dataWithLength:1];
    char* buf = data.mutableBytes;
    buf[0] = XPYAssetAddressNamespace;
    [data appendData:[(XPYAssetAddress* /* cast only to expose the method that is defined in XPYAddress anyway */)self.paycoinAddress dataForBase58Encoding]];
    return data;
}

- (unsigned char) versionByte {
    return XPYAssetAddressNamespace;
}

- (BOOL) isTestnet {
    return self.paycoinAddress.isTestnet;
}

@end
