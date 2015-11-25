// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

// Implementation of [Automatic Encrypted Wallet Backups](https://github.com/oleganza/paycoin-papers/blob/master/AutomaticEncryptedWalletBackups.md) scheme.
// For test vectors, see unit tests (XPYEncryptedBackup+Tests.m).

#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned char, XPYEncryptedBackupVersion) {
    XPYEncryptedBackupVersion1 = 0x01,
};

@class XPYNetwork;
@class XPYKey;
@interface XPYEncryptedBackup : NSObject

// Default version is XPYEncryptedBackupVersion1.
@property(nonatomic, readonly) XPYEncryptedBackupVersion version;

// Timestamp of the backup. If not specified, during encryption set to current time.
@property(nonatomic, readonly) NSTimeInterval timestamp;
@property(nonatomic, readonly) NSDate* date;

@property(nonatomic, readonly) NSData* decryptedData;
@property(nonatomic, readonly) NSData* encryptedData;

@property(nonatomic, readonly) NSString* walletID;
@property(nonatomic, readonly) XPYKey* authenticationKey;

+ (instancetype) encrypt:(NSData*)data backupKey:(NSData*)backupKey;
+ (instancetype) encrypt:(NSData*)data backupKey:(NSData*)backupKey timestamp:(NSTimeInterval)timestamp;
+ (instancetype) decrypt:(NSData*)data backupKey:(NSData*)backupKey;

+ (NSData*) backupKeyForNetwork:(XPYNetwork*)network masterKey:(NSData*)masterKey;
+ (XPYKey*) authenticationKeyWithBackupKey:(NSData*)backupKey;
+ (NSString*) walletIDWithAuthenticationKey:(NSData*)authPubkey;

// For testing/audit purposes only:

@property(nonatomic, readonly) NSData* encryptionKey;
@property(nonatomic, readonly) NSData* iv;
@property(nonatomic, readonly) NSData* merkleRoot;
@property(nonatomic, readonly) NSData* ciphertext;
@property(nonatomic, readonly) NSData* dataForSigning;
@property(nonatomic, readonly) NSData* signature;

@end
