// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYUnitsAndLimits.h"

@class XPYAssetID;
@class XPYPaymentMethodItem;
@class XPYPaymentMethodAsset;
@class XPYPaymentMethodRejection;
@class XPYPaymentMethodRejectedAsset;

// Reply by the user: payment_method, methods per item, assets per method.
@interface  XPYPaymentMethod : NSObject

@property(nonatomic, nullable) NSData* merchantData;
@property(nonatomic, nullable) NSArray* /* [XPYPaymentMethodItem] */ items;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end





// Proposed method to pay for a given item
@interface  XPYPaymentMethodItem : NSObject

@property(nonatomic, nonnull) NSString* itemType;
@property(nonatomic, nullable) NSData* itemIdentifier;
@property(nonatomic, nullable) NSArray* /* [XPYPaymentMethodAsset] */ assets;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end





// Proposed asset and amount within XPYPaymentMethodItem.
@interface  XPYPaymentMethodAsset : NSObject

@property(nonatomic, nullable) NSString* assetType; // XPYAssetTypePaycoin or XPYAssetTypeOpenAssets
@property(nonatomic, nullable) XPYAssetID* assetID; // nil if type is "paycoin".
@property(nonatomic) XPYAmount amount;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end






// Rejection reply by the server: rejection summary and per-asset rejection info.


@interface  XPYPaymentMethodRejection : NSObject

@property(nonatomic, nullable) NSString* memo;
@property(nonatomic) uint64_t code;
@property(nonatomic, nullable) NSArray* /* [XPYPaymentMethodRejectedAsset] */ rejectedAssets;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end


@interface  XPYPaymentMethodRejectedAsset : NSObject

@property(nonatomic, nonnull) NSString* assetType;  // XPYAssetTypePaycoin or XPYAssetTypeOpenAssets
@property(nonatomic, nullable) XPYAssetID* assetID; // nil if type is "paycoin".
@property(nonatomic) uint64_t code;
@property(nonatomic, nullable) NSString* reason;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end

