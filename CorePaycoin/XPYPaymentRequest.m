// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYPaymentRequest.h"
#import "XPYProtocolBuffers.h"
#import "XPYErrors.h"
#import "XPYAssetType.h"
#import "XPYAssetID.h"
#import "XPYData.h"
#import "XPYNetwork.h"
#import "XPYScript.h"
#import "XPYTransaction.h"
#import "XPYTransactionOutput.h"
#import "XPYTransactionInput.h"
#import <Security/Security.h>

NSInteger const XPYPaymentRequestVersion1 = 1;
NSInteger const XPYPaymentRequestVersionOpenAssets1 = 0x4f41;

NSString* const XPYPaymentRequestPKITypeNone = @"none";
NSString* const XPYPaymentRequestPKITypeX509SHA1 = @"x509+sha1";
NSString* const XPYPaymentRequestPKITypeX509SHA256 = @"x509+sha256";

XPYAmount const XPYUnspecifiedPaymentAmount = -1;

typedef NS_ENUM(NSInteger, XPYOutputKey) {
    XPYOutputKeyAmount = 1,
    XPYOutputKeyScript = 2,
    XPYOutputKeyAssetID = 4001, // only for Open Assets PRs.
    XPYOutputKeyAssetAmount = 4002 // only for Open Assets PRs.
};

typedef NS_ENUM(NSInteger, XPYInputKey) {
    XPYInputKeyTxhash = 1,
    XPYInputKeyIndex = 2
};

typedef NS_ENUM(NSInteger, XPYRequestKey) {
    XPYRequestKeyVersion        = 1,
    XPYRequestKeyPkiType        = 2,
    XPYRequestKeyPkiData        = 3,
    XPYRequestKeyPaymentDetails = 4,
    XPYRequestKeySignature      = 5
};

typedef NS_ENUM(NSInteger, XPYDetailsKey) {
    XPYDetailsKeyNetwork      = 1,
    XPYDetailsKeyOutputs      = 2,
    XPYDetailsKeyTime         = 3,
    XPYDetailsKeyExpires      = 4,
    XPYDetailsKeyMemo         = 5,
    XPYDetailsKeyPaymentURL   = 6,
    XPYDetailsKeyMerchantData = 7,
    XPYDetailsKeyInputs       = 8
};

typedef NS_ENUM(NSInteger, XPYCertificatesKey) {
    XPYCertificatesKeyCertificate = 1
};

typedef NS_ENUM(NSInteger, XPYPaymentKey) {
    XPYPaymentKeyMerchantData = 1,
    XPYPaymentKeyTransactions = 2,
    XPYPaymentKeyRefundTo     = 3,
    XPYPaymentKeyMemo         = 4
};

typedef NS_ENUM(NSInteger, XPYPaymentAckKey) {
    XPYPaymentAckKeyPayment = 1,
    XPYPaymentAckKeyMemo    = 2
};


@interface XPYPaymentRequest ()
// If you make these publicly writable, make sure to set _data to nil and _isValidated to NO.
@property(nonatomic, readwrite) NSInteger version;
@property(nonatomic, readwrite) NSString* pkiType;
@property(nonatomic, readwrite) NSData* pkiData;
@property(nonatomic, readwrite) XPYPaymentDetails* details;
@property(nonatomic, readwrite) NSData* signature;
@property(nonatomic, readwrite) NSArray* certificates;
@property(nonatomic, readwrite) NSData* data;

@property(nonatomic) BOOL isValidated;
@property(nonatomic, readwrite) BOOL isValid;
@property(nonatomic, readwrite) NSString* signerName;
@property(nonatomic, readwrite) XPYPaymentRequestStatus status;
@end


@interface XPYPaymentDetails ()
@property(nonatomic, readwrite) XPYNetwork* network;
@property(nonatomic, readwrite) NSArray* /*[XPYTransactionOutput]*/ outputs;
@property(nonatomic, readwrite) NSArray* /*[XPYTransactionInput]*/ inputs;
@property(nonatomic, readwrite) NSDate* date;
@property(nonatomic, readwrite) NSDate* expirationDate;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSURL* paymentURL;
@property(nonatomic, readwrite) NSData* merchantData;
@property(nonatomic, readwrite) NSData* data;
@end


@interface XPYPayment ()
@property(nonatomic, readwrite) NSData* merchantData;
@property(nonatomic, readwrite) NSArray* /*[XPYTransaction]*/ transactions;
@property(nonatomic, readwrite) NSArray* /*[XPYTransactionOutput]*/ refundOutputs;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSData* data;
@end


@interface XPYPaymentACK ()
@property(nonatomic, readwrite) XPYPayment* payment;
@property(nonatomic, readwrite) NSString* memo;
@property(nonatomic, readwrite) NSData* data;
@end







@implementation XPYPaymentRequest

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        // Note: we are not assigning default values here because we need to
        // reconstruct exact data (without the signature) for signature verification.

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t i = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&i data:&d fromData:data]) {
                case XPYRequestKeyVersion:
                    if (i) _version = (uint32_t)i;
                    break;
                case XPYRequestKeyPkiType:
                    if (d) _pkiType = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYRequestKeyPkiData:
                    if (d) _pkiData = d;
                    break;
                case XPYRequestKeyPaymentDetails:
                    if (d) _details = [[XPYPaymentDetails alloc] initWithData:d];
                    break;
                case XPYRequestKeySignature:
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
        [XPYProtocolBuffers writeInt:_version withKey:XPYRequestKeyVersion toData:data];
    }
    if (_pkiType) {
        [XPYProtocolBuffers writeString:_pkiType withKey:XPYRequestKeyPkiType toData:data];
    }
    if (_pkiData) {
        [XPYProtocolBuffers writeData:_pkiData withKey:XPYRequestKeyPkiData toData:data];
    }

    [XPYProtocolBuffers writeData:self.details.data withKey:XPYRequestKeyPaymentDetails toData:data];

    if (signature) {
        [XPYProtocolBuffers writeData:signature withKey:XPYRequestKeySignature toData:data];
    }
    return data;
}

- (NSInteger) version
{
    return (_version > 0) ? _version : XPYPaymentRequestVersion1;
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
    if (self.version != XPYPaymentRequestVersion1 &&
        self.version != XPYPaymentRequestVersionOpenAssets1) {
        _status = XPYPaymentRequestStatusNotCompatible;
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

    // Signatures are valid, but PR has expired.
    if (self.details.expirationDate && [self.currentDate ?: [NSDate date] timeIntervalSinceDate:self.details.expirationDate] > 0.0) {
        _status = XPYPaymentRequestStatusExpired;
        _isValid = NO;
        return;
    }
}

- (XPYPayment*) paymentWithTransaction:(XPYTransaction*)tx {
    NSParameterAssert(tx);
    return [self paymentWithTransactions:@[ tx ] memo:nil];
}

- (XPYPayment*) paymentWithTransactions:(NSArray*)txs memo:(NSString*)memo {
    if (!txs || txs.count == 0) return nil;
    XPYPayment* payment = [[XPYPayment alloc] init];
    payment.merchantData = self.details.merchantData;
    payment.transactions = txs;
    payment.memo = memo;
    return payment;
}

@end


NSArray* __nullable XPYParseCertificatesFromPaymentRequestPKIData(NSData* __nullable pkiData) {
    if (!pkiData) return nil;
    NSMutableArray* certs = [NSMutableArray array];
    NSInteger offset = 0;
    while (offset < pkiData.length) {
        NSData* d = nil;
        NSInteger key = [XPYProtocolBuffers fieldAtOffset:&offset int:NULL data:&d fromData:pkiData];
        if (key == XPYCertificatesKeyCertificate && d) {
            [certs addObject:d];
        }
    }
    return certs;
}


BOOL XPYPaymentRequestVerifySignature(NSString* __nullable pkiType,
                                      NSData* __nullable dataToVerify,
                                      NSArray* __nullable certificates,
                                      NSData* __nullable signature,
                                      XPYPaymentRequestStatus* __nullable statusOut,
                                      NSString* __autoreleasing __nullable *  __nullable signerOut) {

    if ([pkiType isEqual:XPYPaymentRequestPKITypeX509SHA1] ||
        [pkiType isEqual:XPYPaymentRequestPKITypeX509SHA256]) {

        if (!signature || !certificates || certificates.count == 0 || !dataToVerify) {
            if (statusOut) *statusOut = XPYPaymentRequestStatusInvalidSignature;
            return NO;
        }

        // 1. Verify chain of trust

        NSMutableArray *certs = [NSMutableArray array];
        NSArray *policies = @[CFBridgingRelease(SecPolicyCreateBasicX509())];
        SecTrustRef trust = NULL;
        SecTrustResultType trustResult = kSecTrustResultInvalid;

        for (NSData *certData in certificates) {
            SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
            if (cert) [certs addObject:CFBridgingRelease(cert)];
        }

        if (certs.count > 0) {
            if (signerOut) *signerOut = CFBridgingRelease(SecCertificateCopySubjectSummary((__bridge SecCertificateRef)certs[0]));
        }

        SecTrustCreateWithCertificates((__bridge CFArrayRef)certs, (__bridge CFArrayRef)policies, &trust);
        SecTrustEvaluate(trust, &trustResult); // verify certificate chain

        // kSecTrustResultUnspecified indicates the evaluation succeeded
        // and the certificate is implicitly trusted, but user intent was not
        // explicitly specified.
        if (trustResult != kSecTrustResultUnspecified && trustResult != kSecTrustResultProceed) {
            if (certs.count > 0) {
                if (statusOut) *statusOut = XPYPaymentRequestStatusUntrustedCertificate;
            } else {
                if (statusOut) *statusOut = XPYPaymentRequestStatusMissingCertificate;
            }
            return NO;
        }

        // 2. Verify signature

    #if TARGET_OS_IPHONE
        SecKeyRef pubKey = SecTrustCopyPublicKey(trust);
        SecPadding padding = kSecPaddingPKCS1;
        NSData* hash = nil;

        if ([pkiType isEqual:XPYPaymentRequestPKITypeX509SHA256]) {
            hash = XPYSHA256(dataToVerify);
            padding = kSecPaddingPKCS1SHA256;
        }
        else if ([pkiType isEqual:XPYPaymentRequestPKITypeX509SHA1]) {
            hash = XPYSHA1(dataToVerify);
            padding = kSecPaddingPKCS1SHA1;
        }

        OSStatus status = SecKeyRawVerify(pubKey, padding, hash.bytes, hash.length, signature.bytes, signature.length);

        CFRelease(pubKey);

        if (status != errSecSuccess) {
            if (statusOut) *statusOut = XPYPaymentRequestStatusInvalidSignature;
            return NO;
        }

        if (statusOut) *statusOut = XPYPaymentRequestStatusValid;
        return YES;

    #else
        // On OS X 10.10 we don't have kSecPaddingPKCS1SHA256 and SecKeyRawVerify.
        // So we have to verify the signature using Security Transforms API.

        //  Here's a draft of what needs to be done here.
        /*
         CFErrorRef* error = NULL;
         verifier = SecVerifyTransformCreate(publickey, signature, &error);
         if (!verifier) { CFShow(error); exit(-1); }
         if (!SecTransformSetAttribute(verifier, kSecTransformInputAttributeName, dataForSigning, &error) {
         CFShow(error);
         exit(-1);
         }
         // if it's sha256, then set SHA2 digest type and 32 bytes length.
         if (!SecTransformSetAttribute(verifier, kSecDigestTypeAttribute, kSecDigestSHA2, &error) {
         CFShow(error);
         exit(-1);
         }
         // Not sure if the length is in bytes or bits. Quinn The Eskimo says it's in bits:
         // https://devforums.apple.com/message/1119092#1119092
         if (!SecTransformSetAttribute(verifier, kSecDigestLengthAttribute, @(256), &error) {
         CFShow(error);
         exit(-1);
         }

         result = SecTransformExecute(verifier, &error);
         if (error) {
         CFShow(error);
         exit(-1);
         }
         if (result == kCFBooleanTrue) {
         // signature is valid
         if (statusOut) *statusOut = XPYPaymentRequestStatusValid;
         _isValid = YES;
         } else {
         // signature is invalid.
         if (statusOut) *statusOut = XPYPaymentRequestStatusInvalidSignature;
         _isValid = NO;
         return NO;
         }

         // -----------------------------------------------------------------------

         // From CryptoCompatibility sample code (QCCRSASHA1VerifyT.m):

         BOOL                success;
         SecTransformRef     transform;
         CFBooleanRef        result;
         CFErrorRef          errorCF;

         result = NULL;
         errorCF = NULL;

         // Set up the transform.

         transform = SecVerifyTransformCreate(self.publicKey, (__bridge CFDataRef) self.signatureData, &errorCF);
         success = (transform != NULL);

         // Note: kSecInputIsAttributeName defaults to kSecInputIsPlainText, which is what we want.

         if (success) {
         success = SecTransformSetAttribute(transform, kSecDigestTypeAttribute, kSecDigestSHA1, &errorCF) != false;
         }

         if (success) {
         success = SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFDataRef) self.inputData, &errorCF) != false;
         }

         // Run it.

         if (success) {
         result = SecTransformExecute(transform, &errorCF);
         success = (result != NULL);
         }

         // Process the results.

         if (success) {
         assert(CFGetTypeID(result) == CFBooleanGetTypeID());
         self.verified = (CFBooleanGetValue(result) != false);
         } else {
         assert(errorCF != NULL);
         self.error = (__bridge NSError *) errorCF;
         }

         // Clean up.

         if (result != NULL) {
         CFRelease(result);
         }
         if (errorCF != NULL) {
         CFRelease(errorCF);
         }
         if (transform != NULL) {
         CFRelease(transform);
         }
         */

        if (statusOut) *statusOut = XPYPaymentRequestStatusUnknown;
        return NO;
    #endif

    } else {
        // Either "none" PKI type or some new and unsupported PKI.

        if (certificates.count > 0) {
            // Non-standard extension to include a signer's name without actually signing request.
            if (signerOut) *signerOut = [[NSString alloc] initWithData:certificates[0] encoding:NSUTF8StringEncoding];
        }

        if ([pkiType isEqual:XPYPaymentRequestPKITypeNone]) {
            if (statusOut) *statusOut = XPYPaymentRequestStatusUnsigned;
            return YES;
        } else {
            if (statusOut) *statusOut = XPYPaymentRequestStatusUnknown;
            return NO;
        }
    }
    return NO;
}



















@implementation XPYPaymentDetails

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSMutableArray* outputs = [NSMutableArray array];
        NSMutableArray* inputs = [NSMutableArray array];

        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYDetailsKeyNetwork:
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
                case XPYDetailsKeyOutputs: {
                    NSInteger offset2 = 0;
                    XPYAmount amount = XPYUnspecifiedPaymentAmount;
                    NSData* scriptData = nil;
                    XPYAssetID* assetID = nil;
                    XPYAmount assetAmount = XPYUnspecifiedPaymentAmount;

                    uint64_t integer2 = 0;
                    NSData* d2 = nil;
                    while (offset2 < d.length) {
                        switch ([XPYProtocolBuffers fieldAtOffset:&offset2 int:&integer2 data:&d2 fromData:d]) {
                            case XPYOutputKeyAmount:
                                amount = integer2;
                                break;
                            case XPYOutputKeyScript:
                                scriptData = d2;
                                break;
                            case XPYOutputKeyAssetID:
                                if (d2.length != 20) {
                                    NSLog(@"CorePaycoin ERROR: Received invalid asset id in Payment Request Details (must be 20 bytes long): %@", d2);
                                    return nil;
                                }
                                assetID = [XPYAssetID assetIDWithHash:d2];
                                break;
                            case XPYOutputKeyAssetAmount:
                                assetAmount = integer2;
                                break;
                            default:
                                break;
                        }
                    }
                    if (scriptData) {
                        XPYScript* script = [[XPYScript alloc] initWithData:scriptData];
                        if (!script) {
                            NSLog(@"CorePaycoin ERROR: Received invalid script data in Payment Request Details: %@", scriptData);
                            return nil;
                        }
                        if (assetID) {
                            if (amount != XPYUnspecifiedPaymentAmount) {
                                NSLog(@"CorePaycoin ERROR: Received invalid amount specification in Payment Request Details: amount must not be specified.");
                                return nil;
                            }
                        } else {
                            if (assetAmount != XPYUnspecifiedPaymentAmount) {
                                NSLog(@"CorePaycoin ERROR: Received invalid amount specification in Payment Request Details: asset_amount must not specified without asset_id.");
                                return nil;
                            }
                        }
                        XPYTransactionOutput* txout = [[XPYTransactionOutput alloc] initWithValue:amount script:script];
                        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];

                        if (assetID) {
                            userInfo[@"assetID"] = assetID;
                        }
                        if (assetAmount != XPYUnspecifiedPaymentAmount) {
                            userInfo[@"assetAmount"] = @(assetAmount);
                        }
                        txout.userInfo = userInfo;
                        txout.index = (uint32_t)outputs.count;
                        [outputs addObject:txout];
                    }
                    break;
                }
                case XPYDetailsKeyInputs: {
                    NSInteger offset2 = 0;
                    uint64_t index = XPYUnspecifiedPaymentAmount;
                    NSData* txhash = nil;
                    // both amount and scriptData are optional, so we try to read any of them
                    while (offset2 < d.length) {
                        [XPYProtocolBuffers fieldAtOffset:&offset2 int:(uint64_t*)&index data:&txhash fromData:d];
                    }
                    if (txhash) {
                        if (txhash.length != 32) {
                            NSLog(@"CorePaycoin ERROR: Received invalid txhash in Payment Request Input: %@", txhash);
                            return nil;
                        }
                        if (index > 0xffffffffLL) {
                            NSLog(@"CorePaycoin ERROR: Received invalid prev index in Payment Request Input: %@", @(index));
                            return nil;
                        }
                        XPYTransactionInput* txin = [[XPYTransactionInput alloc] init];
                        txin.previousHash = txhash;
                        txin.previousIndex = (uint32_t)index;
                        [inputs addObject:txin];
                    }
                    break;
                }
                case XPYDetailsKeyTime:
                    if (integer) _date = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case XPYDetailsKeyExpires:
                    if (integer) _expirationDate = [NSDate dateWithTimeIntervalSince1970:integer];
                    break;
                case XPYDetailsKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                case XPYDetailsKeyPaymentURL:
                    if (d) _paymentURL = [NSURL URLWithString:[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]];
                    break;
                case XPYDetailsKeyMerchantData:
                    if (d) _merchantData = d;
                    break;
                default: break;
            }
        }

        // PR must have at least one output
        if (outputs.count == 0) return nil;

        // PR requires a creation time.
        if (!_date) return nil;

        _outputs = outputs;
        _inputs = inputs;
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

        // Note: we should reconstruct the data exactly as it was on the input.

        if (_network) {
            [XPYProtocolBuffers writeString:_network.paymentProtocolName withKey:XPYDetailsKeyNetwork toData:dst];
        }

        for (XPYTransactionOutput* txout in _outputs) {
            NSMutableData* outputData = [NSMutableData data];

            if (txout.value != XPYUnspecifiedPaymentAmount) {
                [XPYProtocolBuffers writeInt:txout.value withKey:XPYOutputKeyAmount toData:outputData];
            }
            [XPYProtocolBuffers writeData:txout.script.data withKey:XPYOutputKeyScript toData:outputData];

            if (txout.userInfo[@"assetID"]) {
                XPYAssetID* aid = txout.userInfo[@"assetID"];
                [XPYProtocolBuffers writeData:aid.data withKey:XPYOutputKeyAssetID toData:outputData];
            }
            if (txout.userInfo[@"assetAmount"]) {
                XPYAmount assetAmount = [txout.userInfo[@"assetAmount"] longLongValue];
                [XPYProtocolBuffers writeInt:assetAmount withKey:XPYOutputKeyAssetAmount toData:outputData];
            }
            [XPYProtocolBuffers writeData:outputData withKey:XPYDetailsKeyOutputs toData:dst];
        }

        for (XPYTransactionInput* txin in _inputs) {
            NSMutableData* inputsData = [NSMutableData data];

            [XPYProtocolBuffers writeData:txin.previousHash withKey:XPYInputKeyTxhash toData:inputsData];
            [XPYProtocolBuffers writeInt:txin.previousIndex withKey:XPYInputKeyIndex toData:inputsData];
            [XPYProtocolBuffers writeData:inputsData withKey:XPYDetailsKeyInputs toData:dst];
        }

        if (_date) {
            [XPYProtocolBuffers writeInt:(uint64_t)[_date timeIntervalSince1970] withKey:XPYDetailsKeyTime toData:dst];
        }
        if (_expirationDate) {
            [XPYProtocolBuffers writeInt:(uint64_t)[_expirationDate timeIntervalSince1970] withKey:XPYDetailsKeyExpires toData:dst];
        }
        if (_memo) {
            [XPYProtocolBuffers writeString:_memo withKey:XPYDetailsKeyMemo toData:dst];
        }
        if (_paymentURL) {
            [XPYProtocolBuffers writeString:_paymentURL.absoluteString withKey:XPYDetailsKeyPaymentURL toData:dst];
        }
        if (_merchantData) {
            [XPYProtocolBuffers writeData:_merchantData withKey:XPYDetailsKeyMerchantData toData:dst];
        }
        _data = dst;
    }
    return _data;
}

@end




















@implementation XPYPayment

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {

        NSInteger offset = 0;
        NSMutableArray* txs = [NSMutableArray array];
        NSMutableArray* outputs = [NSMutableArray array];

        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;
            XPYTransaction* tx = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentKeyMerchantData:
                    if (d) _merchantData = d;
                    break;
                case XPYPaymentKeyTransactions:
                    if (d) tx = [[XPYTransaction alloc] initWithData:d];
                    if (tx) [txs addObject:tx];
                    break;
                case XPYPaymentKeyRefundTo: {
                    NSInteger offset2 = 0;
                    XPYAmount amount = XPYUnspecifiedPaymentAmount;
                    NSData* scriptData = nil;
                    // both amount and scriptData are optional, so we try to read any of them
                    while (offset2 < d.length) {
                        [XPYProtocolBuffers fieldAtOffset:&offset2 int:(uint64_t*)&amount data:&scriptData fromData:d];
                    }
                    if (scriptData) {
                        XPYScript* script = [[XPYScript alloc] initWithData:scriptData];
                        if (!script) {
                            NSLog(@"CorePaycoin ERROR: Received invalid script data in Payment Request Details: %@", scriptData);
                            return nil;
                        }
                        XPYTransactionOutput* txout = [[XPYTransactionOutput alloc] initWithValue:amount script:script];
                        [outputs addObject:txout];
                    }
                    break;
                }
                case XPYPaymentKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                default: break;
            }

        }

        _transactions = txs;
        _refundOutputs = outputs;
    }
    return self;
}

- (NSData*) data {

    if (!_data) {
        NSMutableData* dst = [NSMutableData data];

        if (_merchantData) {
            [XPYProtocolBuffers writeData:_merchantData withKey:XPYPaymentKeyMerchantData toData:dst];
        }

        for (XPYTransaction* tx in _transactions) {
            [XPYProtocolBuffers writeData:tx.data withKey:XPYPaymentKeyTransactions toData:dst];
        }

        for (XPYTransactionOutput* txout in _refundOutputs) {
            NSMutableData* outputData = [NSMutableData data];

            if (txout.value != XPYUnspecifiedPaymentAmount) {
                [XPYProtocolBuffers writeInt:txout.value withKey:XPYOutputKeyAmount toData:outputData];
            }
            [XPYProtocolBuffers writeData:txout.script.data withKey:XPYOutputKeyScript toData:outputData];
            [XPYProtocolBuffers writeData:outputData withKey:XPYPaymentKeyRefundTo toData:dst];
        }

        if (_memo) {
            [XPYProtocolBuffers writeString:_memo withKey:XPYPaymentKeyMemo toData:dst];
        }

        _data = dst;
    }
    return _data;
}

@end






















@implementation XPYPaymentACK

- (id) initWithData:(NSData*)data {
    if (!data) return nil;

    if (self = [super init]) {
        NSInteger offset = 0;
        while (offset < data.length) {
            uint64_t integer = 0;
            NSData* d = nil;

            switch ([XPYProtocolBuffers fieldAtOffset:&offset int:&integer data:&d fromData:data]) {
                case XPYPaymentAckKeyPayment:
                    if (d) _payment = [[XPYPayment alloc] initWithData:d];
                    break;
                case XPYPaymentAckKeyMemo:
                    if (d) _memo = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
                    break;
                default: break;
            }
        }
        
        // payment object is required.
        if (! _payment) return nil;
    }
    return self;
}


- (NSData*) data {
    
    if (!_data) {
        NSMutableData* dst = [NSMutableData data];
        
        [XPYProtocolBuffers writeData:_payment.data withKey:XPYPaymentAckKeyPayment toData:dst];
        
        if (_memo) {
            [XPYProtocolBuffers writeString:_memo withKey:XPYPaymentAckKeyMemo toData:dst];
        }
        
        _data = dst;
    }
    return _data;
}


@end
