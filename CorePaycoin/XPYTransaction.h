// CorePaycoin by Oleg Andreev <oleganza@gmail.com>, WTFPL.

#import <Foundation/Foundation.h>
#import "XPYUnitsAndLimits.h"
#import "XPYSignatureHashType.h"

static const uint32_t XPYTransactionCurrentVersion = 1;
static const XPYAmount XPYTransactionDefaultFeeRate = 10000; // 10K satoshis per 1000 bytes


@class XPYScript;
@class XPYTransactionInput;
@class XPYTransactionOutput;

/*!
 * Converts string transaction ID (reversed tx hash in hex format) to transaction hash.
 */
NSData* XPYTransactionHashFromID(NSString* txid) DEPRECATED_ATTRIBUTE;

/*!
 * Converts hash of the transaction to its string ID (reversed tx hash in hex format).
 */
NSString* XPYTransactionIDFromHash(NSData* txhash) DEPRECATED_ATTRIBUTE;


/*!
 * XPYTransaction represents a Paycoin transaction structure which contains
 * inputs, outputs and additional metadata.
 */
@interface XPYTransaction : NSObject<NSCopying>

// Raw transaction hash SHA256(SHA256(payload))
@property(nonatomic, readonly) NSData* transactionHash;

/*!
 * Hex representation of reversed `-transactionHash`.
 * This property is deprecated. Use `-transactionID` instead.
 */
@property(nonatomic, readonly) NSString* displayTransactionHash DEPRECATED_ATTRIBUTE;

/*!
 * Hex representation of reversed `-transactionHash`. Also known as "txid".
 */
@property(nonatomic, readonly) NSString* transactionID;

// Array of XPYTransactionInput objects
@property(nonatomic) NSArray* inputs;

// Array of XPYTransactionOutput objects
@property(nonatomic) NSArray* outputs;

// Version. Default is 1.
@property(nonatomic) uint32_t version;

// Lock time. Either a block height or a unix timestamp.
// Default is 0.
@property(nonatomic) uint32_t lockTime; // aka "lock_time"

// Binary representation on tx ready to be sent over the wire (aka "payload")
@property(nonatomic, readonly) NSData* data;

// Binary representiation in hex.
@property(nonatomic, readonly) NSString* hex;


// Informational properties
// ------------------------
// These are set by external APIs such as Chain.com.


// Hash of the block in which transaction is included.
// Default is nil.
@property(nonatomic) NSData* blockHash;

// ID of the block in which transaction is included.
// Default is nil.
@property(nonatomic) NSString* blockID;

// Height of the block in which this transaction is included.
// Unconfirmed transactions may be marked with -1 block height.
// Default is 0.
@property(nonatomic) NSInteger blockHeight;

// Date and time of the block if specified by the API that returns this transaction.
// Default is nil.
@property(nonatomic) NSDate* blockDate;

// Number of confirmations. Default is NSNotFound.
@property(nonatomic) NSUInteger confirmations;

// Mining fee paid by this transaction.
// If set, `inputs_amount` is updated as (`outputs_amount` + `fee`).
// Default is -1.
@property(nonatomic) XPYAmount fee;

// If available, returns total amount of all inputs.
// If set, `fee` is updated as (`inputsAmount` - `outputsAmount`).
// Default is -1.
@property(nonatomic) XPYAmount inputsAmount;

// Total amount on all outputs (not including fees).
// Always available since outputs contain their amounts.
@property(nonatomic, readonly) XPYAmount outputsAmount;

// Arbitrary information attached to this instance.
// The reference is copied when this instance is copied.
// Default is nil.
@property(nonatomic) NSDictionary* userInfo;

// Returns a dictionary representation suitable for encoding in JSON or Plist.
@property(nonatomic, readonly) NSDictionary* dictionary;

- (NSDictionary*) dictionaryRepresentation DEPRECATED_ATTRIBUTE;

// Parses tx from data buffer.
- (id) initWithData:(NSData*)data;

// Parses tx from hex string.
- (id) initWithHex:(NSString*)hex;

// Parses input stream (useful when parsing many transactions from a single source, e.g. a block).
- (id) initWithStream:(NSInputStream*)stream;

// Constructs transaction from its dictionary representation
- (id) initWithDictionary:(NSDictionary*)dictionary;

// Hash for signing a transaction.
// You should supply the output script of the previous transaction, desired hash type and input index in this transaction.
- (NSData*) signatureHashForScript:(XPYScript*)subscript inputIndex:(uint32_t)inputIndex hashType:(XPYSignatureHashType)hashType error:(NSError**)errorOut;

// Adds input script
- (void) addInput:(XPYTransactionInput*)input;

// Adds output script
- (void) addOutput:(XPYTransactionOutput*)output;

// Replaces inputs with an empty array.
- (void) removeAllInputs;

// Replaces outputs with an empty array.
- (void) removeAllOutputs;

// Returns YES if this txin generates new coins.
@property(nonatomic, readonly) BOOL isCoinbase;

// Computes estimated fee for this tx size using default fee rate.
// @see XPYTransactionDefaultFeeRate.
@property(nonatomic, readonly) XPYAmount estimatedFee;

// Computes estimated fee for this tx size using specified fee rate (satoshis per 1000 bytes).
- (XPYAmount) estimatedFeeWithRate:(XPYAmount)feePerK;

// Computes estimated fee for the given tx size using specified fee rate (satoshis per 1000 bytes).
+ (XPYAmount) estimateFeeForSize:(NSInteger)txsize feeRate:(XPYAmount)feePerK;


// These fee methods need to be reviewed. They are for validating incoming transactions, not for
// calculating a fee for a new transaction.

// Minimum fee to relay the transaction
- (XPYAmount) minimumRelayFee;

// Minimum fee to send the transaction
- (XPYAmount) minimumSendFee;

// Minimum base fee to send a transaction.
+ (XPYAmount) minimumFee;
+ (void) setMinimumFee:(XPYAmount)fee;

// Minimum base fee to relay a transaction.
+ (XPYAmount) minimumRelayFee;
+ (void) setMinimumRelayFee:(XPYAmount)fee;


@end
