// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>

extern NSString* const XPYErrorDomain;

typedef NS_ENUM(NSUInteger, XPYErrorCode) {
    
    // Canonical pubkey/signature check errors
    XPYErrorNonCanonicalPublicKey            = 4001,
    XPYErrorNonCanonicalScriptSignature      = 4002,
    
    // Script verification errors
    XPYErrorScriptError                      = 5001,
    
    // XPYPriceSource errors
    XPYErrorUnsupportedCurrencyCode          = 6001,

    // BIP70 Payment Protocol errors
    XPYErrorPaymentRequestInvalidResponse    = 7001,
    XPYErrorPaymentRequestTooBig             = 7002,
};