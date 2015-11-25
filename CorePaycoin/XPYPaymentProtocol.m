// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYPaymentProtocol.h"
#import "XPYPaymentRequest.h"
#import "XPYErrors.h"
#import "XPYAssetType.h"
#import <Security/Security.h>

static NSString* const XPYPaycoinPaymentRequestMimeType = @"application/paycoin-paymentrequest";
static NSString* const XPYOpenAssetsPaymentRequestMimeType = @"application/oa-paymentrequest";
static NSString* const XPYOpenAssetsPaymentMethodRequestMimeType = @"application/oa-paymentmethodrequest";

@interface XPYPaymentProtocol ()
@property(nonnull, nonatomic, readwrite) NSArray* assetTypes;
@property(nonnull, nonatomic) NSArray* paymentRequestMediaTypes;
@end

@implementation XPYPaymentProtocol

// Instantiates default BIP70 protocol that supports only Paycoin.
- (nonnull id) init {
    return [self initWithAssetTypes:@[ XPYAssetTypePaycoin ]];
}

// Instantiates protocol instance with accepted asset types.
- (nonnull id) initWithAssetTypes:(nonnull NSArray*)assetTypes {
    NSParameterAssert(assetTypes);
    NSParameterAssert(assetTypes.count > 0);
    if (self = [super init]) {
        self.assetTypes = assetTypes;
    }
    return self;
}

- (NSArray*) paymentRequestMediaTypes {
    if (!_paymentRequestMediaTypes && self.assetTypes) {
        NSMutableArray* arr = [NSMutableArray array];
        for (NSString* assetType in self.assetTypes) {
            if ([assetType isEqual:XPYAssetTypePaycoin]) {
                [arr addObject:XPYPaycoinPaymentRequestMimeType];
            } else if ([assetType isEqual:XPYAssetTypeOpenAssets]) {
                [arr addObject:XPYOpenAssetsPaymentRequestMimeType];
            }
        }
        _paymentRequestMediaTypes = arr;
    }
    return _paymentRequestMediaTypes;
}

- (NSInteger) maxDataLength {
    return 50000;
}


// Convenience API


- (void) loadPaymentMethodRequestFromURL:(nonnull NSURL*)paymentMethodRequestURL
                       completionHandler:(nonnull void(^)(XPYPaymentMethodRequest* __nullable pmr, XPYPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler {

    NSParameterAssert(paymentMethodRequestURL);
    NSParameterAssert(completionHandler);

    NSURLRequest* request = [self requestForPaymentMethodRequestWithURL:paymentMethodRequestURL];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, nil, error);
            });
            return;
        }
        id prOrPmr = [self polymorphicPaymentRequestFromData:data response:response error:&error];
        XPYPaymentRequest* pr = ([prOrPmr isKindOfClass:[XPYPaymentRequest class]] ? prOrPmr : nil);
        XPYPaymentMethodRequest* pmr = ([prOrPmr isKindOfClass:[XPYPaymentMethodRequest class]] ? prOrPmr : nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(pmr, pr, prOrPmr ? nil : error);
        });
    });
}


- (void) loadPaymentRequestFromURL:(nonnull NSURL*)paymentRequestURL completionHandler:(nonnull void(^)(XPYPaymentRequest* __nullable pr, NSError* __nullable error))completionHandler {
    NSParameterAssert(paymentRequestURL);
    NSParameterAssert(completionHandler);

    NSURLRequest* request = [self requestForPaymentRequestWithURL:paymentRequestURL];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }
        XPYPaymentRequest* pr = [self paymentRequestFromData:data response:response error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(pr, pr ? nil : error);
        });
    });
}

- (void) postPayment:(nonnull XPYPayment*)payment URL:(nonnull NSURL*)paymentURL completionHandler:(nonnull void(^)(XPYPaymentACK* __nullable ack, NSError* __nullable error))completionHandler {
    NSParameterAssert(payment);
    NSParameterAssert(paymentURL);
    NSParameterAssert(completionHandler);

    NSURLRequest* request = [self requestForPayment:payment url:paymentURL];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, error);
            });
            return;
        }
        XPYPaymentACK* ack = [self paymentACKFromData:data response:response error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(ack, ack ? nil : error);
        });
    });
}


// Low-level API
// (use this if you have your own connection queue).

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url {
    return [self requestForPaymentMethodRequestWithURL:url timeout:10];
}

- (nullable NSURLRequest*) requestForPaymentMethodRequestWithURL:(nonnull NSURL*)url timeout:(NSTimeInterval)timeout {
    if (!url) return nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    [request addValue:XPYPaycoinPaymentRequestMimeType forHTTPHeaderField:@"Accept"];
    [request addValue:XPYOpenAssetsPaymentRequestMimeType forHTTPHeaderField:@"Accept"];
    [request addValue:XPYOpenAssetsPaymentMethodRequestMimeType forHTTPHeaderField:@"Accept"];
    return request;
}

- (nullable id) polymorphicPaymentRequestFromData:(nonnull NSData*)data response:(nonnull NSURLResponse*)response error:(NSError* __nullable * __nullable)errorOut {
    NSString* mime = response.MIMEType.lowercaseString;
    BOOL isPaymentRequest = [mime isEqual:XPYPaycoinPaymentRequestMimeType] ||
                            [mime isEqual:XPYOpenAssetsPaymentRequestMimeType];
    BOOL isPaymentMethodRequest = [mime isEqual:XPYOpenAssetsPaymentMethodRequestMimeType];

    if (!isPaymentRequest && !isPaymentMethodRequest) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (data.length > [self maxDataLength]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestTooBig userInfo:@{}];
        return nil;
    }
    if (isPaymentRequest) {
        XPYPaymentRequest* pr = [[XPYPaymentRequest alloc] initWithData:data];
        if (!pr) {
            if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
            return nil;
        }
        return pr;
    } else if (isPaymentMethodRequest) {
        XPYPaymentMethodRequest* pmr = [[XPYPaymentMethodRequest alloc] initWithData:data];
        if (!pmr) {
            if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
            return nil;
        }
        return pmr;
    }
    return nil;

}

- (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL {
    return [self requestForPaymentRequestWithURL:paymentRequestURL timeout:10];
}

- (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout {
    if (!paymentRequestURL) return nil;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:paymentRequestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    for (NSString* mimeType in self.paymentRequestMediaTypes) {
        [request addValue:mimeType forHTTPHeaderField:@"Accept"];
    }
    return request;
}

- (XPYPaymentRequest*) paymentRequestFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {

    NSArray* mimes = self.paymentRequestMediaTypes;
    NSString* mime = response.MIMEType.lowercaseString;
    if (![mimes containsObject:mime]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (data.length > [self maxDataLength]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestTooBig userInfo:@{}];
        return nil;
    }
    XPYPaymentRequest* pr = [[XPYPaymentRequest alloc] initWithData:data];
    if (!pr) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (pr.version == XPYPaymentRequestVersion1 && ![self.assetTypes containsObject:XPYAssetTypePaycoin]) {
        // Client did not want paycoin, but received paycoin.
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (pr.version == XPYPaymentRequestVersionOpenAssets1 && ![self.assetTypes containsObject:XPYAssetTypeOpenAssets]) {
        // Client did not want open assets, but received open assets.
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    return pr;
}

- (NSURLRequest*) requestForPayment:(XPYPayment*)payment url:(NSURL*)paymentURL {
    return [self requestForPayment:payment url:paymentURL timeout:10];
}

- (NSURLRequest*) requestForPayment:(XPYPayment*)payment url:(NSURL*)paymentURL timeout:(NSTimeInterval)timeout {
    if (!payment) return nil;
    if (!paymentURL) return nil;

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:paymentURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];

    [request addValue:@"application/paycoin-payment" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/paycoin-paymentack" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payment.data];
    return request;
}

- (XPYPaymentACK*) paymentACKFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {

    if (![response.MIMEType.lowercaseString isEqual:@"application/paycoin-paymentack"]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    if (data.length > [self maxDataLength]) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestTooBig userInfo:@{}];
        return nil;
    }

    XPYPaymentACK* ack = [[XPYPaymentACK alloc] initWithData:data];

    if (!ack) {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYErrorDomain code:XPYErrorPaymentRequestInvalidResponse userInfo:@{}];
        return nil;
    }
    
    return ack;
}




// DEPRECATED METHODS

+ (void) loadPaymentRequestFromURL:(NSURL*)paymentRequestURL completionHandler:(void(^)(XPYPaymentRequest* pr, NSError* error))completionHandler {
    [[[self alloc] init] loadPaymentRequestFromURL:paymentRequestURL completionHandler:completionHandler];
}
+ (void) postPayment:(XPYPayment*)payment URL:(NSURL*)paymentURL completionHandler:(void(^)(XPYPaymentACK* ack, NSError* error))completionHandler {
    [[[self alloc] init] postPayment:payment URL:paymentURL completionHandler:completionHandler];
}

+ (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL {
    return [self requestForPaymentRequestWithURL:paymentRequestURL timeout:10];
}

+ (NSURLRequest*) requestForPaymentRequestWithURL:(NSURL*)paymentRequestURL timeout:(NSTimeInterval)timeout {
    return [[[self alloc] init] requestForPaymentRequestWithURL:paymentRequestURL timeout:timeout];
}

+ (XPYPaymentRequest*) paymentRequestFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {
    return [[[self alloc] init] paymentRequestFromData:data response:response error:errorOut];
}

+ (NSURLRequest*) requestForPayment:(XPYPayment*)payment url:(NSURL*)paymentURL {
    return [self requestForPayment:payment url:paymentURL timeout:10];
}

+ (NSURLRequest*) requestForPayment:(XPYPayment*)payment url:(NSURL*)paymentURL timeout:(NSTimeInterval)timeout {
    return [[[self alloc] init] requestForPayment:payment url:paymentURL timeout:timeout];
}

+ (XPYPaymentACK*) paymentACKFromData:(NSData*)data response:(NSURLResponse*)response error:(NSError**)errorOut {
    return [[[self alloc] init] paymentACKFromData:data response:response error:errorOut];
}

@end


