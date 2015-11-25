// Oleg Andreev <oleganza@gmail.com>

#import "NS+XPYBase58.h"

// TODO.

@implementation NSString (XPYBase58)

- (NSMutableData*) dataFromBase58 { return XPYDataFromBase58(self); }
- (NSMutableData*) dataFromBase58Check { return XPYDataFromBase58Check(self); }
@end


@implementation NSMutableData (XPYBase58)

+ (NSMutableData*) dataFromBase58CString:(const char*)cstring
{
    return XPYDataFromBase58CString(cstring);
}

+ (NSMutableData*) dataFromBase58CheckCString:(const char*)cstring
{
    return XPYDataFromBase58CheckCString(cstring);
}

@end


@implementation NSData (XPYBase58)

- (char*) base58CString
{
    return XPYBase58CStringWithData(self);
}

- (char*) base58CheckCString
{
    return XPYBase58CheckCStringWithData(self);
}

- (NSString*) base58String
{
    return XPYBase58StringWithData(self);
}

- (NSString*) base58CheckString
{
    return XPYBase58CheckStringWithData(self);
}


@end
