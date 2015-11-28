#import "XPYChainCom.h"
#import "XPYAddress.h"
#import "XPYTransactionOutput.h"
#import "XPYScript.h"
#import "XPYData.h"

@interface XPYChainCom()
@property NSString* token;
@end

@implementation XPYChainCom

// Initalizes a XPYChainCom object with a free API Token from http://chain.com
- (id)initWithToken:(NSString *)token
{
    if (self = [super init])
    {
        self.token = token;
    }
    return self;
}

// Builds a request from a list of XPYAddress objects.
- (NSMutableURLRequest*) requestForUnspentOutputsWithAddress:(XPYAddress*)address
{
    NSString* pathString = [NSString stringWithFormat:@"addresses/%@/unspents", [address valueForKey:@"base58String"]];
    NSURL* url = [self  chainURLWithV1PaycoinPath:pathString];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    return request;
}

// List of XPYTransactionOutput instances parsed from the response.
- (NSArray*) unspentOutputsForResponseData:(NSData*)responseData error:(NSError**)errorOut
{
    if (!responseData) return nil;
    NSArray* array = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:errorOut];
    if (!array || ![array isKindOfClass:[NSArray class]]) return nil;
    
    NSMutableArray* outputs = [NSMutableArray array];

    for (NSDictionary* item in array)
    {
        XPYTransactionOutput* txout = [[XPYTransactionOutput alloc] init];

        txout.value = [item[@"value"] longLongValue];
        txout.script = [[XPYScript alloc] initWithString:item[@"script"]];
        txout.index = [item[@"output_index"] intValue];
        txout.transactionHash = (XPYReversedData(XPYDataFromHex(item[@"transaction_hash"])));
        [outputs addObject:txout];
    }
    
    return outputs;
}

// Makes sync request for unspent outputs and parses the outputs.
- (NSArray*) unspentOutputsWithAddress:(XPYAddress*)address error:(NSError**)errorOut {
    NSURLRequest* req = [self requestForUnspentOutputsWithAddress:address];
    NSURLResponse* response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:errorOut];
    if (!data)
    {
        return nil;
    }
    return [self unspentOutputsForResponseData:data error:errorOut];
}


- (NSMutableURLRequest*) requestForTransactionBroadcastWithData:(NSData*)data
{
    if (data.length == 0) return nil;
    
    NSString* pathString = @"transactions";
    NSURL* url = [self  chainURLWithV1PaycoinPath:pathString];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSDictionary *requestDictionary = @{@"hex":XPYHexFromData(data)};
    
    NSError *serializationError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary options:0 error:&serializationError];
    if (serializationError != nil) {
        return nil;
    }
    
    request.HTTPMethod = @"PUT";
    request.HTTPBody = jsonData;
    return request;
}

- (BOOL) broadcastTransactionData:(NSData*)data error:(NSError**)errorOut
{
    NSURLRequest* req = [self requestForTransactionBroadcastWithData:data];
    NSURLResponse* response = nil;
    
    [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:errorOut];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (NSURL*) chainURLWithV1PaycoinPath:(NSString *)path
{
    NSString *baseURLString = @"https://api.chain.com/v1/paycoin";
    NSString *URLString = [NSString stringWithFormat:@"%@/%@?key=%@", baseURLString, path, self.token];
    return [NSURL URLWithString:URLString];
}

@end
