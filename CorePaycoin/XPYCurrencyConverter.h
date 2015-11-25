// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYUnitsAndLimits.h"

typedef NS_ENUM(NSInteger, XPYCurrencyConverterMode) {
    /*!
     * Uses the average exchange rate to convert XPY to fiat and back.
     */
    XPYCurrencyConverterModeAverage  = 0,

    /*!
     * Uses the buy rate to convert XPY to fiat and back.
     * Assumes "buying paycoins" mode:
     * fiat -> XPY: "How much XPY will I buy for that much of fiat"
     * XPY -> fiat: "How much fiat should I spend to buy that much XPY"
     */
    XPYCurrencyConverterModeBuy      = 10,

    /*!
     * Uses the sell rate to convert XPY to fiat and back.
     * Assumes "sell paycoins" mode:
     * fiat -> XPY: "How much XPY should I sell to get this much fiat"
     * XPY -> fiat: "How much fiat will I buy for that much of XPY"
     */
    XPYCurrencyConverterModeSell     = 20,

    /*!
     * Instead of using simple buy rate, "eats" through order book asks.
     */
    XPYCurrencyConverterModeBuyOrderBook = 11,

    /*!
     * Instead of using simple sell rate, "eats" through order book bids.
     */
    XPYCurrencyConverterModeSellOrderBook = 21,
};

/*!
 Currency converter allows converting according currency using various modes and sources.
 */
@interface XPYCurrencyConverter : NSObject<NSCopying>

/*!
 * Conversion mode. Depending on your needs (selling or buying paycoin) you may set various modes.
 * Default is XPYCurrencyConverterModeAverage.
 */
@property(nonatomic) XPYCurrencyConverterMode mode;

/*!
 * Average rate. When set, overwrites buy and sell rates.
 */
@property(nonatomic) NSDecimalNumber* averageRate;

/*!
 * Buy exchange rate (price for 1 XPY when you buy XPY).
 * When set, recomputes average exchange rate using sell rate.
 * If sell rate is nil, it is set to buy rate.
 */
@property(nonatomic) NSDecimalNumber* buyRate;

/*!
 * Sell exchange rate (price for 1 XPY when you sell XPY).
 * When set, recomputes average exchange rate using buy rate.
 * If buy rate is nil, it is set to sell rate.
 */
@property(nonatomic) NSDecimalNumber* sellRate;

/*!
 * List of @[ NSNumber price-per-XPY, NSNumber XPYs ] pairs for order book asks.
 * When set, updates buyRate to the lowest price.
 */
@property(nonatomic) NSArray* asks;

/*!
 * List of @[ NSNumber price-per-XPY, NSNumber XPYs ] pairs for order book bids.
 * When set, updates sellRate to the highest price.
 */
@property(nonatomic) NSArray* bids;

/*!
 * Date of last update. It is set automatically when exchange rates are updated,
 * but you can set it manually afterwards.
 */
@property(nonatomic) NSDate* date;

/*!
 * Code of the fiat currency in which prices are expressed.
 */
@property(nonatomic) NSString* currencyCode;

/*!
 * Code of the fiat currency used by exchange natively.
 * Typically, it is the same as `currencyCode`, but may differ if,
 * for instance, prices are expressed in USD, but exchange operates in EUR.
 */
@property(nonatomic) NSString* nativeCurrencyCode;

/*!
 * Name of the exchange/market that provides this exchange rate.
 * Deprecated. Use sourceName instead.
 */
@property(nonatomic) NSString* marketName DEPRECATED_ATTRIBUTE;

/*!
 * Name of the exchange market or price index that provides this exchange rate.
 */
@property(nonatomic) NSString* sourceName;

/*!
 * Serializes state into a plist/json dictionary.
 */
@property(nonatomic, readonly) NSDictionary* dictionary;

/*!
 * Serializes state into a plist/json dictionary.
 */
- (id) initWithDictionary:(NSDictionary*)dict;

/*!
 * Converts fiat amount to paycoin amount in satoshis using specified mode.
 */
- (XPYAmount) paycoinFromFiat:(NSDecimalNumber*)fiatAmount;

/*!
 * Converts paycoin amount to fiat amount using specified mode.
 */
- (NSDecimalNumber*) fiatFromPaycoin:(XPYAmount)satoshis;


@end
