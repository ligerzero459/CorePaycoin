// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYAddress.h"

@interface XPYAssetAddress : XPYAddress
@property(nonatomic, readonly, nonnull) XPYAddress* paycoinAddress;
+ (nonnull instancetype) addressWithPaycoinAddress:(nonnull XPYAddress*)XPYAddress;
@end
