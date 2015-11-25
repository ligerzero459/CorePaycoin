// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

//
//  SwiftBridgingHeader.h
//
//

#import "CorePaycoin.h"
#import "NSData+XPYData.h"
#import "NS+XPYBase58.h"

#include <CommonCrypto/CommonCrypto.h>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/evp.h>
#include <openssl/obj_mac.h>
#include <openssl/bn.h>
#include <openssl/rand.h>