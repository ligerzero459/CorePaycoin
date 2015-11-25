// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYAddress.h"

@interface XPYAssetID : XPYAddress

+ (nullable instancetype) assetIDWithHash:(nullable NSData*)data;

+ (nullable instancetype) assetIDWithString:(nullable NSString*)string;

@end
