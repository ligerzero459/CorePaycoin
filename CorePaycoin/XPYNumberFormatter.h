// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYUnitsAndLimits.h"

typedef NS_ENUM(NSInteger, XPYNumberFormatterUnit) {
    XPYNumberFormatterUnitSatoshi  = 0, // satoshis = 0.00000001 XPY
    XPYNumberFormatterUnitBit      = 2, // bits     = 0.000001 XPY
    XPYNumberFormatterUnitMilliXPY = 5, // mXPY     = 0.001 XPY
    XPYNumberFormatterUnitXPY      = 8, // XPY      = 100 million satoshis
};

typedef NS_ENUM(NSInteger, XPYNumberFormatterSymbolStyle) {
    XPYNumberFormatterSymbolStyleNone      = 0, // no suffix
    XPYNumberFormatterSymbolStyleCode      = 1, // suffix is XPY, mXPY, Bits or SAT
    XPYNumberFormatterSymbolStyleLowercase = 2, // suffix is XPY, mXPY, bits or sat
    XPYNumberFormatterSymbolStyleSymbol    = 3, // suffix is Ƀ, mɃ, ƀ or ṡ
};

extern NSString* const XPYNumberFormatterPaycoinCode;    // XBT
extern NSString* const XPYNumberFormatterSymbolXPY;      // Ƀ
extern NSString* const XPYNumberFormatterSymbolMilliXPY; // mɃ
extern NSString* const XPYNumberFormatterSymbolBit;      // ƀ
extern NSString* const XPYNumberFormatterSymbolSatoshi;  // ṡ

/*!
 * Rounds the decimal number and returns its longLongValue.
 * Do not use NSDecimalNumber.longLongValue as it will return 0 on iOS 8.0.2 if the number is not rounded first.
 */
XPYAmount XPYAmountFromDecimalNumber(NSNumber* num);

@interface XPYNumberFormatter : NSNumberFormatter

/*!
 * Instantiates and configures number formatter with given unit and suffix style.
 */
- (id) initWithPaycoinUnit:(XPYNumberFormatterUnit)unit;
- (id) initWithPaycoinUnit:(XPYNumberFormatterUnit)unit symbolStyle:(XPYNumberFormatterSymbolStyle)symbolStyle;

/*!
 * Unit size to be displayed (regardless of how it is presented)
 */
@property(nonatomic) XPYNumberFormatterUnit paycoinUnit;

/*!
 * Style of formatting the units regardless of the unit size.
 */
@property(nonatomic) XPYNumberFormatterSymbolStyle symbolStyle;

/*!
 * Placeholder text for the input field.
 * E.g. "0 000 000.00" for 'bits' and "0.00000000" for 'XPY'.
 */
@property(nonatomic, readonly) NSString* placeholderText;

/*!
 * Returns a matching paycoin symbol.
 * If `symbolStyle` is XPYNumberFormatterSymbolStyleNone, returns the code (XPY, mXPY, Bits or SAT).
 */
@property(nonatomic, readonly) NSString* standaloneSymbol;

/*!
 * Returns a matching paycoin unit code (XPY, mXPY etc) regardless of the symbol style.
 */
@property(nonatomic, readonly) NSString* unitCode;

/*!
 * Formats the amount according to units and current formatting style.
 */
- (NSString *) stringFromAmount:(XPYAmount)amount;

/*!
 * Returns 0 in case of failure to parse the string.
 * To handle that case, use `-[NSNumberFormatter numberFromString:]`, but keep in mind
 * that NSNumber* will be in specified units, not in satoshis.
 */
- (XPYAmount) amountFromString:(NSString *)string;

@end
