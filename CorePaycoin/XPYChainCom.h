// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
@class XPYAddress;

// Collection of APIs for Chain.con
@interface XPYChainCom : NSObject

- (id)initWithToken:(NSString *)token; // Free API Token from http://chain.com

// Getting unspent outputs.

// Builds a request from a list of XPYAddress objects.
- (NSMutableURLRequest*) requestForUnspentOutputsWithAddress:(XPYAddress*)address;
// List of XPYTransactionOutput instances parsed from the response.
- (NSArray*) unspentOutputsForResponseData:(NSData*)responseData error:(NSError**)errorOut;
// Makes sync request for unspent outputs and parses the outputs.
- (NSArray*) unspentOutputsWithAddress:(XPYAddress*)addresses error:(NSError**)errorOut;


// Broadcasting transaction

// Request to broadcast a raw transaction data.
- (NSMutableURLRequest*) requestForTransactionBroadcastWithData:(NSData*)data;

@end
