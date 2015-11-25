// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import "XPYHashID.h"
#import "XPYData.h"

NSData* XPYHashFromID(NSString* identifier)
{
    return XPYReversedData(XPYDataFromHex(identifier));
}

NSString* XPYIDFromHash(NSData* hash)
{
    return XPYHexFromData(XPYReversedData(hash));
}
