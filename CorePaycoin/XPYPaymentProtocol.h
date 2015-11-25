// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYPaymentRequest.h"
#import "XPYPaymentMethodRequest.h"

// Interface to BIP70 payment protocol.
// Spec: https://github.com/paycoin/bips/blob/master/bip-0070.mediawiki
//
// * XPYPaymentProtocol implements high-level request and response API.
// * XPYPaymentRequest object that represents "PaymentRequest" as described in BIP70.
// * XPYPaymentDetails object that represents "PaymentDetails" as described in BIP70.
// * XPYPayment object that represents "Payment" as described in BIP70.
// * XPYPaymentACK object that represents "PaymentACK" as described in BIP70.

@interface XPYPaymentProtocol : NSObject

// List of accepted asset types.
@property(nonnull, nonatomic, readonly) NSArray* assetTypes;

// Instantiates default BIP70 protocol that supports only Paycoin.
- (nonnull id) init;

// Instantiates protocol instance with accepted asset types. See XPYAssetType* constants.
- (nonnull id) initWithAssetTypes:(nonnull NSArray*)assetTypes;


// Convenience API

// Loads a XPYPaymentRequest object or XPYPaymentMethodRequest from a given URL.
// May return either PaymentMethodRequest or PaymentRequest, depending on the response from the server.
// This method ignores `assetTypes` and allows both paycoin and openassets types.
- (void) loadPaymentMethodRequestFromURL:(nonnull NSURL*)paymentMethodRequestURL completionHandler:(nonnull void(^)(XPYPaymentMethodRequest* __nullable pmr, XPYPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler;

// Loads a XPYPaymentRequest object from a given URL.
- (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(XPYPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler;

// Posts completed payment object to a given payment URL (provided in XPYPaymentDetails) and
// returns a PaymentACK object.
- (void) postPayment:(nonnull XPYPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(XPYPaymentACK* __nullable ack, NSError* __nullable error))completionHandler;


// Low-level API
// (use these if you have your own connection queue).

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout;
- (nullable id) polymorphicPaymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;

- (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)url; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout;
- (nullable XPYPaymentRequest*) paymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;

- (nullable NSURLRequest*) requestForPayment:(nonnull XPYPayment*)payment url:(nonnull NSURL*)paymentURL; // default timeout is 10 sec
- (nullable NSURLRequest*) requestForPayment:(nonnull XPYPayment*)payment url:(nonnull NSURL*)paymentURL timeout:(NSTimeInterval)timeout;
- (nullable XPYPaymentACK*) paymentACKFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut;


// Deprecated Methods

+ (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(XPYPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler DEPRECATED_ATTRIBUTE;
+ (void) postPayment:(nonnull XPYPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(XPYPaymentACK* __nullable ack, NSError* __nullable error))completionHandler DEPRECATED_ATTRIBUTE;

+ (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)paymentRequestURL DEPRECATED_ATTRIBUTE; // default timeout is 10 sec
+ (nullable NSURLRequest*) requestForPaymentRequestWithURL:(nonnull NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout DEPRECATED_ATTRIBUTE;
+ (nullable XPYPaymentRequest*) paymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut DEPRECATED_ATTRIBUTE;

+ (nullable NSURLRequest*) requestForPayment:(nonnull XPYPayment*)payment url:(nonnull NSURL*)paymentURL DEPRECATED_ATTRIBUTE; // default timeout is 10 sec
+ (nullable NSURLRequest*) requestForPayment:(nonnull XPYPayment*)payment url:(nonnull NSURL*)paymentURL timeout:(NSTimeInterval)timeout DEPRECATED_ATTRIBUTE;
+ (nullable XPYPaymentACK*) paymentACKFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut DEPRECATED_ATTRIBUTE;

@end
