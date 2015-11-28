#import "XPYPriceSource+Tests.h"

@implementation XPYPriceSource (Tests)

+ (void) runAllTests {

    XPYPriceSourceCoindesk* coindesk = [[XPYPriceSourceCoindesk alloc] init];
    NSAssert([coindesk.name.lowercaseString containsString:@"coindesk"], @"should be named coindesk");
    NSAssert([coindesk.currencyCodes containsObject:@"USD"], @"should contain USD");
    NSAssert([coindesk.currencyCodes containsObject:@"EUR"], @"should contain EUR");
    [self validatePrice:[coindesk loadPriceForCurrency:@"USD" error:NULL] min:100 max:10000];
    [self validatePrice:[coindesk loadPriceForCurrency:@"EUR" error:NULL] min:100 max:10000];

    XPYPriceSourceWinkdex* winkdex = [[XPYPriceSourceWinkdex alloc] init];
    NSAssert([winkdex.name.lowercaseString containsString:@"wink"], @"should be named properly");
    NSAssert([winkdex.currencyCodes containsObject:@"USD"], @"should contain USD");
    [self validatePrice:[winkdex loadPriceForCurrency:@"USD" error:NULL] min:100 max:10000];

    XPYPriceSourceCoinbase* coinbase = [[XPYPriceSourceCoinbase alloc] init];
    NSAssert([coinbase.name.lowercaseString containsString:@"coinbase"], @"should be named properly");
    NSAssert([coinbase.currencyCodes containsObject:@"USD"], @"should contain USD");
    [self validatePrice:[coinbase loadPriceForCurrency:@"USD" error:NULL] min:100 max:10000];

    XPYPriceSourcePaymium* paymium = [[XPYPriceSourcePaymium alloc] init];
    NSAssert([paymium.name.lowercaseString containsString:@"paymium"], @"should be named properly");
    NSAssert([paymium.currencyCodes containsObject:@"EUR"], @"should contain EUR");
    [self validatePrice:[paymium loadPriceForCurrency:@"EUR" error:NULL] min:100 max:10000];
}

+ (void) validatePrice:(XPYPriceSourceResult*)result min:(double)minValue max:(double)maxValue {
    NSNumber* number = result.averageRate;
//    NSLog(@"price = %@ %@", number, result.currencyCode);
    NSAssert(result, @"result should not be nil");
    NSAssert(result.date, @"date should not be nil");
    NSAssert(number, @"averageRate should not be nil");
    NSAssert(number.floatValue >= minValue, @"Must be over minimum value");
    NSAssert(number.floatValue <= maxValue, @"Must be over minimum value");
}

@end
