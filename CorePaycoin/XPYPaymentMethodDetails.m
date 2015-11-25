// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYPaymentMethodDetails.h"
#import "XPYPaymentProtocol.h"
#import "XPYProtocolBuffers.h"
#import "XPYNetwork.h"
#import "XPYAssetType.h"
#import "XPYAssetID.h"

//message PaymentMethodDetails {
//    optional string        network            = 1 [default = "main"];
//    required string        payment_method_url = 2;
//    repeated PaymentItem   items              = 3;
//    required uint64        time               = 4;
//    optional uint64        expires            = 5;
//    optional string        memo               = 6;
//    optional bytes         merchant_data      = 7;
//}
typedef NS_ENUM(NSInteger, XPYPMDetailsKey) {
    XPYPMDetailsKeyNetwork            = 1,
    XPYPMDetailsKeyPaymentMethodURL   = 2,
    XPYPMDetailsKeyItems              = 3,
    XPYPMDetailsKeyTime               = 4,
    XPYPMDetailsKeyExpires            = 5,
    XPYPMDetailsKeyMemo               = 6,
    XPYPMDetailsKeyMerchantData       = 7,
};

@interface XPYPaymentMethodDetails ()
@property(nonatomic, readwrite) XPYNetwork* network;
@property(nonatomic, readwrite) NSArray* /* [XPYPaymentMethodRequestItem] */ items;
@property(nonatomic, readwrite) NSURL* paymentMethodURL;
@property(nonatomic, readwrite) NSDate* date;
@property(nonatomic, readwrite) NSDate* expirationDate;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSData* merchantData;
@property(nonatomic, readwrite) NSData* data;
@end

@implementation XPYPaymentMethodDetails

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* items = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPMDetailsKeyNetwork:
                    if (d) {
                        NSString* networkName = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                        if ([networkName isEqual:@"main"]) {
                            _network = [XPYNetwork mainnet];
                        } else if ([networkName isEqual:@"test"]) {
                            _network = [XPYNetwork testnet];
                        } else {
                            _network = [[XPYNetwork alloc] initWithName:networkName];
                        }
                    }
                    break;
                case XPYPMDetailsKeyPaymentMethodURL:
                    if (d) _paymentMethodURL = [NSURL URLWithString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
                    break;
                case XPYPMDetailsKeyItems: {
                    if (d) {
                        XPYPaymentMethodDetailsItem* item = [[XPYPaymentMethodDetailsItem alloc] initWithData:d];
                        [items addObject:item];
                    }
                    break;
                }
                case XPYPMDetailsKeyTime:
                    if (integer) _date = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case XPYPMDetailsKeyExpires:
                    if (integer) _expirationDate = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case XPYPMDetailsKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPMDetailsKeyMerchantData:
                    if (d) _merchantData = d;
                    break;
                default: break;
            }
        }

        // PMR must have at least one item
        if (items.count == 0) return nil;

        // PMR requires a creation time.
        if (!_date) return nil;

        _items = items;
        _data = data;
    }
    return self;
}

- (XPYNetwork*) network {
    return _network ?: [XPYNetwork mainnet];
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_network) {
            [XPYProtocolBuffers writeString:_network.paymentProtocolName withKey:XPYPMDetailsKeyNetwork toData:dst];
        }
        if (_paymentMethodURL) {
            [XPYProtocolBuffers writeString:_paymentMethodURL.absoluteString withKey:XPYPMDetailsKeyPaymentMethodURL toData:dst];
        }
        for (XPYPaymentMethodDetailsItem* item in _items) {
            [XPYProtocolBuffers writeData:item.data withKey:XPYPMDetailsKeyItems toData:dst];
        }
        if (_date) {
            [XPYProtocolBuffers writeInt:(uint64_t)[_date timeIntervalSince1970] withKey:XPYPMDetailsKeyTime toData:dst];
        }
        if (_expirationDate) {
            [XPYProtocolBuffers writeInt:(uint64_t)[_expirationDate timeIntervalSince1970] withKey:XPYPMDetailsKeyExpires toData:dst];
        }
        if (_memo) {
            [XPYProtocolBuffers writeString:_memo withKey:XPYPMDetailsKeyMemo toData:dst];
        }
        if (_merchantData) {
            [XPYProtocolBuffers writeData:_merchantData withKey:XPYPMDetailsKeyMerchantData toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end





//message PaymentItem {
//    optional string type                   = 1 [default = "default"];
//    optional bool   optional               = 2 [default = false];
//    optional bytes  item_identifier        = 3;
//    optional uint64 amount                 = 4 [default = 0];
//    repeated AcceptedAsset accepted_assets = 5;
//    optional string memo                   = 6;
//}
typedef NS_ENUM(NSInteger, XPYPMItemKey) {
    XPYPMRItemKeyItemType           = 1,
    XPYPMRItemKeyItemOptional       = 2,
    XPYPMRItemKeyItemIdentifier     = 3,
    XPYPMRItemKeyAmount             = 4,
    XPYPMRItemKeyAcceptedAssets     = 5,
    XPYPMRItemKeyMemo               = 6,
};

@interface XPYPaymentMethodDetailsItem ()
@property(nonatomic, readwrite, nullable) NSString* itemType;
@property(nonatomic, readwrite) BOOL optional;
@property(nonatomic, readwrite, nullable) NSData* itemIdentifier;
@property(nonatomic, readwrite) XPYAmount amount;
@property(nonatomic, readwrite, nonnull) NSArray* /* [XPYPaymentMethodAcceptedAsset] */ acceptedAssets;
@property(nonatomic, readwrite, nullable) NSString* memo;
@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethodDetailsItem

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* assets = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPMRItemKeyItemType:
                    if (d) _itemType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPMRItemKeyItemOptional:
                    _optional = (integer != 0);
                    break;
                case XPYPMRItemKeyItemIdentifier:
                    if (d) _itemIdentifier = d;
                    break;

                case XPYPMRItemKeyAmount: {
                    _amount = integer;
                    break;
                }
                case XPYPMRItemKeyAcceptedAssets: {
                    if (d) {
                        XPYPaymentMethodAcceptedAsset* asset = [[XPYPaymentMethodAcceptedAsset alloc] initWithData:d];
                        [assets addObject:asset];
                    }
                    break;
                }
                case XPYPMRItemKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                default: break;
            }
        }
        _acceptedAssets = assets;
        _data = data;
    }
    return self;
}


- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_itemType) {
            [XPYProtocolBuffers writeString:_itemType withKey:XPYPMRItemKeyItemType toData:dst];
        }
        [XPYProtocolBuffers writeInt:_optional ? 1 : 0 withKey:XPYPMRItemKeyItemOptional toData:dst];
        if (_itemIdentifier) {
            [XPYProtocolBuffers writeData:_itemIdentifier withKey:XPYPMRItemKeyItemIdentifier toData:dst];
        }
        if (_amount > 0) {
             [XPYProtocolBuffers writeInt:(uint64_t)_amount withKey:XPYPMRItemKeyAmount toData:dst];
        }
        for (XPYPaymentMethodAcceptedAsset* asset in _acceptedAssets) {
            [XPYProtocolBuffers writeData:asset.data withKey:XPYPMRItemKeyAcceptedAssets toData:dst];
        }
        if (_memo) {
            [XPYProtocolBuffers writeString:_memo withKey:XPYPMRItemKeyMemo toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end





//message AcceptedAsset {
//    optional string asset_id = 1 [default = "default"];
//    optional string asset_group = 2;
//    optional double multiplier = 3 [default = 1.0];
//    optional uint64 min_amount = 4 [default = 0];
//    optional uint64 max_amount = 5;
//}
typedef NS_ENUM(NSInteger, XPYPMAcceptedAssetKey) {
    XPYPMRAcceptedAssetKeyAssetID    = 1,
    XPYPMRAcceptedAssetKeyAssetGroup = 2,
    XPYPMRAcceptedAssetKeyMultiplier = 3,
    XPYPMRAcceptedAssetKeyMinAmount  = 4,
    XPYPMRAcceptedAssetKeyMaxAmount  = 5,
};


@interface XPYPaymentMethodAcceptedAsset ()
@property(nonatomic, readwrite, nullable) NSString* assetType; // XPYAssetTypePaycoin or XPYAssetTypeOpenAssets
@property(nonatomic, readwrite, nullable) XPYAssetID* assetID;
@property(nonatomic, readwrite, nullable) NSString* assetGroup;
@property(nonatomic, readwrite) double multiplier; // to use as a multiplier need to multiply by that amount and divide by 1e8.
@property(nonatomic, readwrite) XPYAmount minAmount;
@property(nonatomic, readwrite) XPYAmount maxAmount;
@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethodAcceptedAsset


- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSString* assetIDString = nil;

        _multiplier = 1.0;

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            uint64_t fixed64 = 0;
            NSData* d = nil;
            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer fixed32:NULL fixed64:&fixed64 data:&d fromData:data]) {
                case XPYPMRAcceptedAssetKeyAssetID:
                    if (d) assetIDString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;

                case XPYPMRAcceptedAssetKeyAssetGroup: {
                    if (d) _assetGroup = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                }
                case XPYPMRAcceptedAssetKeyMultiplier: {
                    _multiplier = (double)fixed64;
                    break;
                }
                case XPYPMRAcceptedAssetKeyMinAmount: {
                    _minAmount = integer;
                    break;
                }
                case XPYPMRAcceptedAssetKeyMaxAmount: {
                    _maxAmount = integer;
                    break;
                }
                default: break;
            }
        }

        if (!assetIDString || [assetIDString isEqual:@"default"]) {
            _assetType = XPYAssetTypePaycoin;
            _assetID = nil;
        } else {
            _assetID = [XPYAssetID assetIDWithString:assetIDString];
            if (_assetID) {
                _assetType = XPYAssetTypeOpenAssets;
            }
        }
        _data = data;
    }
    return self;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if ([_assetType isEqual:XPYAssetTypePaycoin]) {
            [XPYProtocolBuffers writeString:@"default" withKey:XPYPMRAcceptedAssetKeyAssetID toData:dst];
        } else if ([_assetType isEqual:XPYAssetTypeOpenAssets] && _assetID) {
            [XPYProtocolBuffers writeString:_assetID.string withKey:XPYPMRAcceptedAssetKeyAssetID toData:dst];
        }
        if (_assetGroup) {
            [XPYProtocolBuffers writeString:_assetGroup withKey:XPYPMRAcceptedAssetKeyAssetGroup toData:dst];
        }

        [XPYProtocolBuffers writeFixed64:(uint64_t)_multiplier withKey:XPYPMRAcceptedAssetKeyMultiplier toData:dst];
        [XPYProtocolBuffers writeInt:(uint64_t)_minAmount withKey:XPYPMRAcceptedAssetKeyMinAmount toData:dst];
        [XPYProtocolBuffers writeInt:(uint64_t)_maxAmount withKey:XPYPMRAcceptedAssetKeyMaxAmount toData:dst];
        _data = dst;
    }
    return _data;
}

@end

