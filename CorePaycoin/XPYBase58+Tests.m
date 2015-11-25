// Oleg Andreev <oleganza@gmail.com>

#import "XPYBase58+Tests.h"
#import "XPYData.h"

void XPYAssertHexEncodesToBase58(NSString* hex, NSString* base58)
{
    NSData* data = XPYDataFromHex(hex);
    
    // Encode
    NSCAssert([XPYBase58StringWithData(data) isEqualToString:base58], @"should encode in base58 correctly");
    
    // Decode
    NSData* data2 = XPYDataFromBase58(base58);
    NSCAssert([data2 isEqual:data], @"should decode base58 correctly");
}

void XPYAssertDetectsInvalidBase58(NSString* text)
{
	NSData *data = XPYDataFromBase58Check(text);
    
    NSCAssert(data == nil, @"should return nil if base58 is invalid");
}

void XPYBase58RunAllTests()
{
    XPYAssertDetectsInvalidBase58(nil);
    XPYAssertDetectsInvalidBase58(@" ");
    XPYAssertDetectsInvalidBase58(@"lLoO");
    XPYAssertDetectsInvalidBase58(@"l");
    XPYAssertDetectsInvalidBase58(@"L");
    XPYAssertDetectsInvalidBase58(@"o");
    XPYAssertDetectsInvalidBase58(@"O");
    XPYAssertDetectsInvalidBase58(@"öまи");
    
    XPYAssertHexEncodesToBase58(@"", @""); // Empty string is valid encoding of an empty binary string
    XPYAssertHexEncodesToBase58(@"61", @"2g");
    XPYAssertHexEncodesToBase58(@"626262", @"a3gV");
    XPYAssertHexEncodesToBase58(@"636363", @"aPEr");
    XPYAssertHexEncodesToBase58(@"73696d706c792061206c6f6e6720737472696e67", @"2cFupjhnEsSn59qHXstmK2ffpLv2");
    XPYAssertHexEncodesToBase58(@"00eb15231dfceb60925886b67d065299925915aeb172c06647", @"1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L");
    XPYAssertHexEncodesToBase58(@"516b6fcd0f", @"ABnLTmg");
    XPYAssertHexEncodesToBase58(@"bf4f89001e670274dd", @"3SEo3LWLoPntC");
    XPYAssertHexEncodesToBase58(@"572e4794", @"3EFU7m");
    XPYAssertHexEncodesToBase58(@"ecac89cad93923c02321", @"EJDM8drfXA6uyA");
    XPYAssertHexEncodesToBase58(@"10c8511e", @"Rt5zm");
    XPYAssertHexEncodesToBase58(@"00000000000000000000", @"1111111111");

    if ((0))
    {
        // Search for vanity prefix
        NSString* prefix = @"s";
        
        NSData* payload = XPYRandomDataWithLength(32);
        for (uint32_t i = 0x10000000; i <= UINT32_MAX; i++)
        {
            int j = 10;
            NSString* serialization = nil;
            do
            {
                NSMutableData* data = [NSMutableData data];

                uint32_t idx = 0;
                [data appendBytes:&i length:sizeof(i)];
                [data appendBytes:&idx length:sizeof(idx)];
                [data appendData:payload];

                serialization = XPYBase58CheckStringWithData(data);

                payload = XPYRandomDataWithLength(32);

            } while ([serialization hasPrefix:prefix] && j-- > 0);

            if ([serialization hasPrefix:prefix])
            {
                NSLog(@"integer for prefix %@ is %d", prefix, i);
                break;
            }
        }
    }
}