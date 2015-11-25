// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYPaymentMethod.h"
#import "XPYProtocolBuffers.h"
#import "XPYAssetID.h"
#import "XPYAssetType.h"

//message PaymentMethod {
//    optional bytes             merchant_data = 1;
//    repeated PaymentMethodItem items         = 2;
//}
typedef NS_ENUM(NSInteger, XPYPaymentMethodKey) {
    XPYPaymentMethodKeyMerchantData = 1,
    XPYPaymentMethodKeyItem         = 2,
};


@interface XPYPaymentMethod ()
@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethod

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* items = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentMethodKeyMerchantData:
                    if (d) _merchantData = d;
                    break;

                case XPYPaymentMethodKeyItem: {
                    if (d) {
                        XPYPaymentMethodItem* item = [[XPYPaymentMethodItem alloc] initWithData:d];
                        [items addObject:item];
                    }
                    break;
                }
                default: break;
            }
        }

        _items = items;
        _data = data;
    }
    return self;
}

- (void) setMerchantData:(NSData * __nullable)merchantData {
    _merchantData = merchantData;
    _data = nil;
}

- (void) setItems:(NSArray * __nullable)items {
    _items = items;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_merchantData) {
            [XPYProtocolBuffers writeData:_merchantData withKey:XPYPaymentMethodKeyMerchantData toData:dst];
        }
        for (XPYPaymentMethodItem* item in _items) {
            [XPYProtocolBuffers writeData:item.data withKey:XPYPaymentMethodKeyItem toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end




//message PaymentMethodItem {
//    optional string             type                = 1 [default = "default"];
//    optional bytes              item_identifier     = 2;
//    repeated PaymentMethodAsset payment_item_assets = 3;
//}
typedef NS_ENUM(NSInteger, XPYPaymentMethodItemKey) {
    XPYPaymentMethodItemKeyItemType          = 1, // default = "default"
    XPYPaymentMethodItemKeyItemIdentifier    = 2,
    XPYPaymentMethodItemKeyAssets            = 3,
};


@interface XPYPaymentMethodItem ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethodItem

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSMutableArray* assets = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentMethodItemKeyItemType:
                    if (d) _itemType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPaymentMethodItemKeyItemIdentifier:
                    if (d) _itemIdentifier = d;
                    break;
                case XPYPaymentMethodItemKeyAssets: {
                    if (d) {
                        XPYPaymentMethodAsset* asset = [[XPYPaymentMethodAsset alloc] initWithData:d];
                        [assets addObject:asset];
                    }
                    break;
                }
                default: break;
            }
        }

        _assets = assets;
        _data = data;
    }
    return self;
}

- (void) setItemType:(NSString * __nonnull)itemType {
    _itemType = itemType;
    _data = nil;
}

- (void) setItemIdentifier:(NSData * __nullable)itemIdentifier {
    _itemIdentifier = itemIdentifier;
    _data = nil;
}

- (void) setAssets:(NSArray * __nullable)assets {
    _assets = assets;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_itemType) {
            [XPYProtocolBuffers writeString:_itemType withKey:XPYPaymentMethodItemKeyItemType toData:dst];
        }
        if (_itemIdentifier) {
            [XPYProtocolBuffers writeData:_itemIdentifier withKey:XPYPaymentMethodItemKeyItemIdentifier toData:dst];
        }
        for (XPYPaymentMethodItem* item in _assets) {
            [XPYProtocolBuffers writeData:item.data withKey:XPYPaymentMethodItemKeyAssets toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end






//message PaymentMethodAsset {
//    optional string            asset_id = 1 [default = "default"];
//    optional uint64            amount = 2;
//}
typedef NS_ENUM(NSInteger, XPYPaymentMethodAssetKey) {
    XPYPaymentMethodAssetKeyAssetID = 1,
    XPYPaymentMethodAssetKeyAmount  = 2,
};


@interface XPYPaymentMethodAsset ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethodAsset

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSString* assetIDString = nil;

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentMethodAssetKeyAssetID:
                    if (d) assetIDString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPaymentMethodAssetKeyAmount: {
                    _amount = integer;
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

- (void) setAssetType:(NSString * __nullable)assetType {
    _assetType = assetType;
    _data = nil;
}

- (void) setAssetID:(XPYAssetID * __nullable)assetID {
    _assetID = assetID;
    _data = nil;
}

- (void) setAmount:(XPYAmount)amount {
    _amount = amount;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if ([_assetType isEqual:XPYAssetTypePaycoin]) {
            [XPYProtocolBuffers writeString:@"default" withKey:XPYPaymentMethodAssetKeyAssetID toData:dst];
        } else if ([_assetType isEqual:XPYAssetTypeOpenAssets] && _assetID) {
            [XPYProtocolBuffers writeString:_assetID.string withKey:XPYPaymentMethodAssetKeyAssetID toData:dst];
        }

        [XPYProtocolBuffers writeInt:(uint64_t)_amount withKey:XPYPaymentMethodAssetKeyAmount toData:dst];
        _data = dst;
    }
    return _data;
}

@end




//message PaymentMethodRejection {
//    optional string memo = 1;
//    repeated PaymentMethodRejectedAsset rejected_assets = 2;
//}
typedef NS_ENUM(NSInteger, XPYPaymentMethodRejectionKey) {
    XPYPaymentMethodRejectionKeyMemo   = 1,
    XPYPaymentMethodRejectionKeyCode   = 2,
    XPYPaymentMethodRejectionKeyAssets = 3,
};


@interface XPYPaymentMethodRejection ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethodRejection

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSMutableArray* rejectedAssets = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentMethodRejectionKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPaymentMethodRejectionKeyCode:
                    _code = integer;
                    break;
                case XPYPaymentMethodRejectionKeyAssets: {
                    if (d) {
                        XPYPaymentMethodRejectedAsset* rejasset = [[XPYPaymentMethodRejectedAsset alloc] initWithData:d];
                        [rejectedAssets addObject:rejasset];
                    }
                    break;
                }
                default: break;
            }
        }

        _rejectedAssets = rejectedAssets;
        _data = data;
    }
    return self;
}

- (void) setMemo:(NSString * __nullable)memo {
    _memo = [memo copy];
    _data = nil;
}

- (void) setCode:(uint64_t)code {
    _code = code;
    _data = nil;
}

- (void) setRejectedAssets:(NSArray * __nullable)rejectedAssets {
    _rejectedAssets = rejectedAssets;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_memo) {
            [XPYProtocolBuffers writeString:_memo withKey:XPYPaymentMethodRejectionKeyMemo toData:dst];
        }

        [XPYProtocolBuffers writeInt:_code withKey:XPYPaymentMethodRejectionKeyCode toData:dst];

        for (XPYPaymentMethodRejectedAsset* rejectedAsset in _rejectedAssets) {
            [XPYProtocolBuffers writeData:rejectedAsset.data withKey:XPYPaymentMethodRejectionKeyAssets toData:dst];
        }

        _data = dst;
    }
    return _data;
}

@end


//message PaymentMethodRejectedAsset {
//    required string asset_id = 1;
//    optional uint64 code     = 2;
//    optional string reason   = 3;
//}
typedef NS_ENUM(NSInteger, XPYPaymentMethodRejectedAssetKey) {
    XPYPaymentMethodRejectedAssetKeyAssetID = 1,
    XPYPaymentMethodRejectedAssetKeyCode    = 2,
    XPYPaymentMethodRejectedAssetKeyReason  = 3,
};


@interface XPYPaymentMethodRejectedAsset ()

@property(nonatomic, readwrite, nonnull) NSData* data;
@end

@implementation XPYPaymentMethodRejectedAsset

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSString* assetIDString = nil;

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentMethodRejectedAssetKeyAssetID:
                    if (d) assetIDString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPaymentMethodRejectionKeyCode:
                    _code = integer;
                    break;
                case XPYPaymentMethodRejectedAssetKeyReason: {
                    if (d) _reason = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
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

- (void) setAssetType:(NSString * __nonnull)assetType {
    _assetType = assetType;
    _data = nil;
}

- (void) setAssetID:(XPYAssetID * __nullable)assetID {
    _assetID = assetID;
    _data = nil;
}

- (void) setCode:(uint64_t)code {
    _code = code;
    _data = nil;
}

- (void) setReason:(NSString * __nullable)reason {
    _reason = reason;
    _data = nil;
}

- (NSData*) data {
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if ([_assetType isEqual:XPYAssetTypePaycoin]) {
            [XPYProtocolBuffers writeString:@"default" withKey:XPYPaymentMethodRejectedAssetKeyAssetID toData:dst];
        } else if ([_assetType isEqual:XPYAssetTypeOpenAssets] && _assetID) {
            [XPYProtocolBuffers writeString:_assetID.string withKey:XPYPaymentMethodRejectedAssetKeyAssetID toData:dst];
        }

        [XPYProtocolBuffers writeInt:_code withKey:XPYPaymentMethodRejectedAssetKeyCode toData:dst];

        if (_reason) {
            [XPYProtocolBuffers writeString:_reason withKey:XPYPaymentMethodRejectedAssetKeyReason toData:dst];
        }

        _data = dst;
    }
    return _data;
}

@end
