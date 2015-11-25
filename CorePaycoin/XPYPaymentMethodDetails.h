// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYUnitsAndLimits.h"

@class XPYNetwork;
@class XPYAssetID;
@class XPYPaymentMethodDetailsItem;
@class XPYPaymentMethodAcceptedAsset;
@interface XPYPaymentMethodDetails : NSObject

// Mainnet or testnet. Default is mainnet.
@property(nonatomic, readonly, nonnull) XPYNetwork* network;

// Payment items for the customer.
@property(nonatomic, readonly, nonnull)  NSArray* /* [XPYPaymentMethodDetailsItem] */ items;

// Secure location (usually https) where a PaymentMethod message (see below) may be sent to obtain a PaymentRequest.
// The payment_url specified in the PaymentMethodDetails should remain valid at least until the PaymentMethodDetails expires
// (or as long as possible if the PaymentMethodDetails does not expire).
@property(nonatomic, readonly, nullable) NSURL* paymentMethodURL;

// Date when the PaymentRequest was created.
@property(nonatomic, readonly, nonnull) NSDate* date;

// Date after which the PaymentRequest should be considered invalid.
@property(nonatomic, readonly, nullable) NSDate* expirationDate;

// Plain-text (no formatting) note that should be displayed to the customer, explaining what this PaymentRequest is for.
@property(nonatomic, readonly, nullable) NSString* memo;

// Arbitrary data that may be used by the merchant to identify the PaymentRequest.
// May be omitted if the merchant does not need to associate Payments with PaymentRequest or
// if they associate each PaymentRequest with a separate payment address.
@property(nonatomic, readonly, nullable) NSData* merchantData;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;

@end



@interface  XPYPaymentMethodDetailsItem : NSObject

@property(nonatomic, readonly, nullable) NSString* itemType;
@property(nonatomic, readonly) BOOL optional;
@property(nonatomic, readonly, nullable) NSData* itemIdentifier;
@property(nonatomic, readonly) XPYAmount amount;
@property(nonatomic, readonly, nonnull) NSArray* /* [XPYPaymentMethodAcceptedAsset] */ acceptedAssets;
@property(nonatomic, readonly, nullable) NSString* memo;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end



@interface  XPYPaymentMethodAcceptedAsset : NSObject

@property(nonatomic, readonly, nullable) NSString* assetType; // XPYAssetTypePaycoin or XPYAssetTypeOpenAssets
@property(nonatomic, readonly, nullable) XPYAssetID* assetID; // nil if type is "paycoin".
@property(nonatomic, readonly, nullable) NSString* assetGroup;
@property(nonatomic, readonly) double multiplier;
@property(nonatomic, readonly) XPYAmount minAmount;
@property(nonatomic, readonly) XPYAmount maxAmount;

// Binary serialization in protocol buffer format.
@property(nonatomic, readonly, nonnull) NSData* data;

- (nullable id) initWithData:(nullable NSData*)data;
@end


