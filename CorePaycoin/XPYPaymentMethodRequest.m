// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYPaymentRequest.h"
#import "XPYPaymentMethodRequest.h"
#import "XPYPaymentMethodDetails.h"
#import "XPYProtocolBuffers.h"

NSInteger const XPYPaymentMethodRequestVersion1 = 1;

//message PaymentMethodRequest {
//    optional uint32 payment_details_version = 1 [default = 1];
//    optional string pki_type = 2 [default = "none"];
//    optional bytes  pki_data = 3;
//    required bytes  serialized_payment_method_details = 4;
//    optional bytes  signature = 5;
//}
typedef NS_ENUM(NSInteger, XPYPMRKey) {
    XPYPMRKeyVersion        = 1,
    XPYPMRKeyPkiType        = 2,
    XPYPMRKeyPkiData        = 3,
    XPYPMRKeyPaymentDetails = 4,
    XPYPMRKeySignature      = 5
};

@interface XPYPaymentMethodRequest ()
// If you make these publicly writable, make sure to set _data to nil and _isValidated to NO.
@property(nonatomic, readwrite) NSInteger version;
@property(nonatomic, readwrite) NSString* pkiType;
@property(nonatomic, readwrite) NSData* pkiData;
@property(nonatomic, readwrite) XPYPaymentMethodDetails* details;
@property(nonatomic, readwrite) NSData* signature;
@property(nonatomic, readwrite) NSArray* certificates;
@property(nonatomic, readwrite) NSData* data;

@property(nonatomic) BOOL isValidated;
@property(nonatomic, readwrite) BOOL isValid;
@property(nonatomic, readwrite) NSString* signerName;
@property(nonatomic, readwrite) XPYPaymentRequestStatus status;
@end





@implementation XPYPaymentMethodRequest

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    // Note: we are not assigning default values here because we need to
    // reconstruct exact data (without the signature) for signature verification.

    if (self = [super init]) {
        
        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t i = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&i data:&d fromData:data]) {
                case XPYPMRKeyVersion:
                    if (i) _version = (uint32_t)i;
                    break;
                case XPYPMRKeyPkiType:
                    if (d) _pkiType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYPMRKeyPkiData:
                    if (d) _pkiData = d;
                    break;
                case XPYPMRKeyPaymentDetails:
                    if (d) _details = [[XPYPaymentMethodDetails alloc] initWithData:d];
                    break;
                case XPYPMRKeySignature:
                    if (d) _signature = d;
                    break;
                default: break;
            }
        }

        // Payment details are required.
        if (!_details) return nil;
    }
    return self;
}

- (NSData*) data {
    if (!_data) {
        _data = [self dataWithSignature:_signature];
    }
    return _data;
}

- (NSData*) dataForSigning {
    return [self dataWithSignature:[NSData data]];
}

- (NSData*) dataWithSignature:(NSData*)signature {
    NSMutableData* data = [NSMutableData data];

    // Note: we should reconstruct the data exactly as it was on the input.
    if (_version > 0) {
        [XPYProtocolBuffers writeInt:_version withKey:XPYPMRKeyVersion toData:data];
    }
    if (_pkiType) {
        [XPYProtocolBuffers writeString:_pkiType withKey:XPYPMRKeyPkiType toData:data];
    }
    if (_pkiData) {
        [XPYProtocolBuffers writeData:_pkiData withKey:XPYPMRKeyPkiData toData:data];
    }

    [XPYProtocolBuffers writeData:self.details.data withKey:XPYPMRKeyPaymentDetails toData:data];

    if (signature) {
        [XPYProtocolBuffers writeData:signature withKey:XPYPMRKeySignature toData:data];
    }
    return data;
}

- (NSInteger) version
{
    return (_version > 0) ? _version : XPYPaymentMethodRequestVersion1;
}

- (NSString*) pkiType
{
    return _pkiType ?: XPYPaymentRequestPKITypeNone;
}

- (NSArray*) certificates {
    if (!_certificates) {
        _certificates = XPYParseCertificatesFromPaymentRequestPKIData(self.pkiData);
    }
    return _certificates;
}

- (BOOL) isValid {
    if (!_isValidated) [self validatePaymentRequest];
    return _isValid;
}

- (NSString*) signerName {
    if (!_isValidated) [self validatePaymentRequest];
    return _signerName;
}

- (XPYPaymentRequestStatus) status {
    if (!_isValidated) [self validatePaymentRequest];
    return _status;
}

- (void) validatePaymentRequest {
    _isValidated = YES;
    _isValid = NO;

    // Make sure we do not accidentally send funds to a payment request that we do not support.
    if (self.version != XPYPaymentMethodRequestVersion1) {
        _status = XPYPaymentRequestStatusNotCompatible;
        return;
    }

    if (self.details.expirationDate && [self.currentDate ?: [NSDate date] timeIntervalSinceDate:self.details.expirationDate] > 0.0) {
        _status = XPYPaymentRequestStatusExpired;
        _isValid = NO;
        return;
    }

    __typeof(_status) status = _status;
    __typeof(_signerName) signer = _signerName;
    _isValid = XPYPaymentRequestVerifySignature(self.pkiType,
                                                [self dataForSigning],
                                                self.certificates,
                                                _signature,
                                                &status,
                                                &signer);
    _status = status;
    _signerName = signer;
    if (!_isValid) {
        return;
    }
}

@end







