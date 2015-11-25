#import "XPYNumberFormatter.h"

#define NarrowNbsp @"\xE2\x80\xAF"
//#define PunctSpace @" "
//#define ThinSpace  @" "

NSString* const XPYNumberFormatterPaycoinCode    = @"XBT";

NSString* const XPYNumberFormatterSymbolXPY      = @"Ƀ" @"";
NSString* const XPYNumberFormatterSymbolMilliXPY = @"mɃ";
NSString* const XPYNumberFormatterSymbolBit      = @"ƀ";
NSString* const XPYNumberFormatterSymbolSatoshi  = @"ṡ";

XPYAmount XPYAmountFromDecimalNumber(NSNumber* num)
{
    if ([num isKindOfClass:[NSDecimalNumber class]])
    {
        NSDecimalNumber* dnum = (id)num;
        // Starting iOS 8.0.2, the longLongValue method returns 0 for some non rounded values.
        // Rounding the number looks like a work around.
        NSDecimalNumberHandler *roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain
                                                                                                          scale:0
                                                                                               raiseOnExactness:NO
                                                                                                raiseOnOverflow:YES
                                                                                               raiseOnUnderflow:NO
                                                                                            raiseOnDivideByZero:YES];
        num = [dnum decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    }
    XPYAmount sat = [num longLongValue];
    return sat;
}

@implementation XPYNumberFormatter {
    NSDecimalNumber* _myMultiplier; // because standard multiplier when below 1e-6 leads to a rounding no matter what the settings.
}

- (id) initWithPaycoinUnit:(XPYNumberFormatterUnit)unit
{
    return [self initWithPaycoinUnit:unit symbolStyle:XPYNumberFormatterSymbolStyleNone];
}

- (id) initWithPaycoinUnit:(XPYNumberFormatterUnit)unit symbolStyle:(XPYNumberFormatterSymbolStyle)symbolStyle
{
    if (self = [super init])
    {
        _paycoinUnit = unit;
        _symbolStyle = symbolStyle;

        [self updateFormatterProperties];
    }
    return self;
}

- (void) setPaycoinUnit:(XPYNumberFormatterUnit)paycoinUnit
{
    if (_paycoinUnit == paycoinUnit) return;
    _paycoinUnit = paycoinUnit;
    [self updateFormatterProperties];
}

- (void) setSymbolStyle:(XPYNumberFormatterSymbolStyle)suffixStyle
{
    if (_symbolStyle == suffixStyle) return;
    _symbolStyle = suffixStyle;
    [self updateFormatterProperties];
}

- (void) updateFormatterProperties
{
    // Reset formats so they are recomputed after we change properties.
    self.positiveFormat = nil;
    self.negativeFormat = nil;

    self.lenient = YES;
    self.generatesDecimalNumbers = YES;
    self.numberStyle = NSNumberFormatterCurrencyStyle;
    self.currencyCode = @"XBT";
    self.groupingSize = 3;

    self.currencySymbol = [self paycoinUnitSymbol] ?: @"";

    self.internationalCurrencySymbol = self.currencySymbol;

    // On iOS 8 we have to set these *after* setting the currency symbol.
    switch (_paycoinUnit)
    {
        case XPYNumberFormatterUnitSatoshi:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:0 isNegative:NO];
            self.minimumFractionDigits = 0;
            self.maximumFractionDigits = 0;
            break;
        case XPYNumberFormatterUnitBit:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-2 isNegative:NO];
            self.minimumFractionDigits = 0;
            self.maximumFractionDigits = 2;
            break;
        case XPYNumberFormatterUnitMilliXPY:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-5 isNegative:NO];
            self.minimumFractionDigits = 2;
            self.maximumFractionDigits = 5;
            break;
        case XPYNumberFormatterUnitXPY:
            _myMultiplier = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-8 isNegative:NO];
            self.minimumFractionDigits = 2;
            self.maximumFractionDigits = 8;
            break;
        default:
            [[NSException exceptionWithName:@"XPYNumberFormatter: not supported paycoin unit" reason:@"" userInfo:nil] raise];
    }

    switch (_symbolStyle)
    {
        case XPYNumberFormatterSymbolStyleNone:
            self.minimumFractionDigits = 0;
            self.positivePrefix = @"";
            self.positiveSuffix = @"";
            self.negativePrefix = @"–";
            self.negativeSuffix = @"";
            break;
        case XPYNumberFormatterSymbolStyleCode:
        case XPYNumberFormatterSymbolStyleLowercase:
            self.positivePrefix = @"";
            self.positiveSuffix = [NSString stringWithFormat:@" %@", self.currencySymbol]; // nobreaking space here.
            self.negativePrefix = @"-";
            self.negativeSuffix = self.positiveSuffix;
            break;

        case XPYNumberFormatterSymbolStyleSymbol:
            // Leave positioning of the currency symbol to locale (in English it'll be prefix, in French it'll be suffix).
            break;
    }
    self.maximum = @(XPY_MAX_MONEY);

    // Fixup prefix symbol with a no-breaking space. When it's postfix, Foundation puts nobr space already.
    self.positiveFormat = [self.positiveFormat stringByReplacingOccurrencesOfString:@"¤" withString:@"¤" NarrowNbsp "#"];

    // Fixup negative format to have the same format as positive format and a minus sign in front of the first digit.
    self.negativeFormat = [self.positiveFormat stringByReplacingCharactersInRange:[self.positiveFormat rangeOfString:@"#"] withString:@"–#"];
}

- (NSString *) standaloneSymbol
{
    NSString* sym = [self paycoinUnitSymbol];
    if (!sym)
    {
        sym = [self paycoinUnitSymbolForUnit:_paycoinUnit];
    }
    return sym;
}

- (NSString*) paycoinUnitSymbol
{
    return [self paycoinUnitSymbolForStyle:_symbolStyle unit:_paycoinUnit];
}

- (NSString*) unitCode
{
    return [self paycoinUnitCodeForUnit:_paycoinUnit];
}

- (NSString*) paycoinUnitCodeForUnit:(XPYNumberFormatterUnit)unit
{
    switch (unit)
    {
        case XPYNumberFormatterUnitSatoshi:
            return NSLocalizedStringFromTable(@"SAT", @"CorePaycoin", @"");
        case XPYNumberFormatterUnitBit:
            return NSLocalizedStringFromTable(@"Bits", @"CorePaycoin", @"");
        case XPYNumberFormatterUnitMilliXPY:
            return NSLocalizedStringFromTable(@"mXPY", @"CorePaycoin", @"");
        case XPYNumberFormatterUnitXPY:
            return NSLocalizedStringFromTable(@"XPY", @"CorePaycoin", @"");
        default:
            [[NSException exceptionWithName:@"XPYNumberFormatter: not supported paycoin unit" reason:@"" userInfo:nil] raise];
    }
}

- (NSString*) paycoinUnitSymbolForUnit:(XPYNumberFormatterUnit)unit
{
    switch (unit)
    {
        case XPYNumberFormatterUnitSatoshi:
            return XPYNumberFormatterSymbolSatoshi;
        case XPYNumberFormatterUnitBit:
            return XPYNumberFormatterSymbolBit;
        case XPYNumberFormatterUnitMilliXPY:
            return XPYNumberFormatterSymbolMilliXPY;
        case XPYNumberFormatterUnitXPY:
            return XPYNumberFormatterSymbolXPY;
        default:
            [[NSException exceptionWithName:@"XPYNumberFormatter: not supported paycoin unit" reason:@"" userInfo:nil] raise];
    }
}

- (NSString*) paycoinUnitSymbolForStyle:(XPYNumberFormatterSymbolStyle)symbolStyle unit:(XPYNumberFormatterUnit)paycoinUnit
{
    switch (symbolStyle)
    {
        case XPYNumberFormatterSymbolStyleNone:
            return nil;
        case XPYNumberFormatterSymbolStyleCode:
            return [self paycoinUnitCodeForUnit:paycoinUnit];
        case XPYNumberFormatterSymbolStyleLowercase:
            return [[self paycoinUnitCodeForUnit:paycoinUnit] lowercaseString];
        case XPYNumberFormatterSymbolStyleSymbol:
            return [self paycoinUnitSymbolForUnit:paycoinUnit];
        default:
            [[NSException exceptionWithName:@"XPYNumberFormatter: not supported symbol style" reason:@"" userInfo:nil] raise];
    }
    return nil;
}

- (NSString *) placeholderText
{
    //NSString* groupSeparator = self.currencyGroupingSeparator ?: @"";
    NSString* decimalPoint = self.currencyDecimalSeparator ?: @".";
    switch (_paycoinUnit)
    {
        case XPYNumberFormatterUnitSatoshi:
            return @"0";
        case XPYNumberFormatterUnitBit:
            return [NSString stringWithFormat:@"0%@00", decimalPoint];
        case XPYNumberFormatterUnitMilliXPY:
            return [NSString stringWithFormat:@"0%@00000", decimalPoint];
        case XPYNumberFormatterUnitXPY:
            return [NSString stringWithFormat:@"0%@00000000", decimalPoint];
        default:
            [[NSException exceptionWithName:@"XPYNumberFormatter: not supported paycoin unit" reason:@"" userInfo:nil] raise];
            return nil;
    }
}

- (NSString*) stringFromNumber:(NSNumber *)number {
    if (![number isKindOfClass:[NSDecimalNumber class]]) {
        number = [NSDecimalNumber decimalNumberWithDecimal:number.decimalValue];
    }
    return [super stringFromNumber:[(NSDecimalNumber*)number decimalNumberByMultiplyingBy:_myMultiplier]];
}

- (NSNumber*) numberFromString:(NSString *)string {
    // self.generatesDecimalNumbers guarantees NSDecimalNumber here.
    NSDecimalNumber* number = (NSDecimalNumber*)[super numberFromString:string];
    return [number decimalNumberByDividingBy:_myMultiplier];
}

- (NSString *) stringFromAmount:(XPYAmount)amount
{
    return [self stringFromNumber:@(amount)];
}

- (XPYAmount) amountFromString:(NSString *)string
{
    return XPYAmountFromDecimalNumber([self numberFromString:string]);
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[XPYNumberFormatter alloc] initWithPaycoinUnit:self.paycoinUnit symbolStyle:self.symbolStyle];
}


@end
