#import "XPYTransactionBuilder.h"
#import "XPYTransaction.h"
#import "XPYTransactionOutput.h"
#import "XPYTransactionInput.h"
#import "XPYAddress.h"
#import "XPYScript.h"
#import "XPYKey.h"
#import "XPYData.h"

NSString* const XPYTransactionBuilderErrorDomain = @"com.oleganza.CorePaycoin.TransactionBuilder";

@interface XPYTransactionBuilderResult ()
@property(nonatomic, readwrite) XPYTransaction* transaction;
@property(nonatomic, readwrite) NSIndexSet* unsignedInputsIndexes;
@property(nonatomic, readwrite) XPYAmount fee;
@property(nonatomic, readwrite) XPYAmount inputsAmount;
@property(nonatomic, readwrite) XPYAmount outputsAmount;
@end

@implementation XPYTransactionBuilder

- (id) init
{
    if (self = [super init])
    {
        _feeRate = XPYTransactionDefaultFeeRate;
        _minimumChange = -1; // so it picks feeRate at runtime.
        _dustChange = -1; // so it picks minimumChange at runtime.
        _shouldSign = YES;
        _shouldShuffle = YES;
    }
    return self;
}

- (XPYTransactionBuilderResult*) buildTransaction:(NSError**)errorOut
{
    if (!self.changeScript)
    {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYTransactionBuilderErrorDomain code:XPYTransactionBuilderInsufficientFunds userInfo:nil];
        return nil;
    }

    NSEnumerator* unspentsEnumerator = self.unspentOutputsEnumerator;

    if (!unspentsEnumerator)
    {
        if (errorOut) *errorOut = [NSError errorWithDomain:XPYTransactionBuilderErrorDomain code:XPYTransactionBuilderUnspentOutputsMissing userInfo:nil];
        return nil;
    }

    XPYTransactionBuilderResult* result = [[XPYTransactionBuilderResult alloc] init];
    result.transaction = [[XPYTransaction alloc] init];

    // If no outputs given, try to spend all available unspents.
    if (self.outputs.count == 0)
    {
        result.inputsAmount = 0;

        for (XPYTransactionOutput* utxo in unspentsEnumerator)
        {
            result.inputsAmount += utxo.value;

            XPYTransactionInput* txin = [self makeTransactionInputWithUnspentOutput:utxo];
            [result.transaction addInput:txin];
        }

        if (result.transaction.inputs.count == 0)
        {
            if (errorOut) *errorOut = [NSError errorWithDomain:XPYTransactionBuilderErrorDomain code:XPYTransactionBuilderUnspentOutputsMissing userInfo:nil];
            return nil;
        }

        // Prepare a destination output.
        // Value will be determined after computing the fee.
        XPYTransactionOutput* changeOutput = [[XPYTransactionOutput alloc] initWithValue:XPY_MAX_MONEY script:self.changeScript];
        [result.transaction addOutput:changeOutput];

        result.fee = [self computeFeeForTransaction:result.transaction];
        result.outputsAmount = result.inputsAmount - result.fee;

        // Check if inputs cover the fees
        if (result.outputsAmount < 0)
        {
            if (errorOut) *errorOut = [NSError errorWithDomain:XPYTransactionBuilderErrorDomain code:XPYTransactionBuilderInsufficientFunds userInfo:nil];
            return nil;
        }

        // Set the output value as needed
        changeOutput.value = result.outputsAmount;

        result.unsignedInputsIndexes = [self attemptToSignTransaction:result.transaction error:errorOut];
        if (!result.unsignedInputsIndexes)
        {
            return nil;
        }

        return result;

    } // if no outputs

    // We are having one or more outputs (e.g. normal payment)
    // Need to find appropriate unspents and compose a transaction.

    // Prepare all outputs

    result.outputsAmount = 0; // will contain change value after all inputs are finalized

    for (XPYTransactionOutput* txout in self.outputs)
    {
        result.outputsAmount += txout.value;
        [result.transaction addOutput:txout];
    }

    // We'll determine final change value depending on inputs.
    // Setting default to MAX_MONEY will protect against a bug when we fail to update the amount and
    // spend unexpected amount on mining fees.
    XPYTransactionOutput* changeOutput = [[XPYTransactionOutput alloc] initWithValue:XPY_MAX_MONEY script:self.changeScript];
    [result.transaction addOutput:changeOutput];

    // We have specific outputs with specific amounts, so we need to select the best amount of coins.

    result.inputsAmount = 0;

    for (XPYTransactionOutput* utxo in unspentsEnumerator)
    {
        result.inputsAmount += utxo.value;

        XPYTransactionInput* txin = [self makeTransactionInputWithUnspentOutput:utxo];
        [result.transaction addInput:txin];

        // Before computing the fee, quick check if we have enough inputs to cover the outputs.
        // If not, go and add one more utxo before wasting time computing fees.
        if (result.inputsAmount < result.outputsAmount)
        {
            // Try adding more unspent outputs on the next cycle.
            continue;
        }

        XPYAmount fee = [self computeFeeForTransaction:result.transaction];

        XPYAmount change = result.inputsAmount - result.outputsAmount - fee;

        if (change >= self.minimumChange)
        {
            // We have a big enough change, set missing values and return.
            changeOutput.value = change;
            result.outputsAmount += change;
            result.fee = fee;

            result.unsignedInputsIndexes = [self attemptToSignTransaction:result.transaction error:errorOut];
            if (!result.unsignedInputsIndexes)
            {
                return nil;
            }
            return result;
        }
        else if (change > self.dustChange && change < self.minimumChange)
        {
            // We have a shitty change: not small enough to forgo, not big enough to be useful.
            // Try adding more utxos on the next cycle (or fail if no more utxos are available).
        }
        else if (change >= 0 && change <= self.dustChange)
        {
            // This also includes the case when change is exactly zero satoshis.
            // Remove the change output, keep existing outputsAmount, set fee and try to sign.

            NSMutableArray* txoutputs = [result.transaction.outputs mutableCopy];
            [txoutputs removeObjectIdenticalTo:changeOutput];
            result.transaction.outputs = txoutputs;
            result.fee = fee;
            result.unsignedInputsIndexes = [self attemptToSignTransaction:result.transaction error:errorOut];
            if (!result.unsignedInputsIndexes)
            {
                return nil;
            }
            return result;
        }
        else
        {
            // Change is negative, we need more funds for this transaction.
            // Try adding more utxos on the next cycle.
        }
    }

    // If we haven't finished within the loop, then we don't have enough unspent outputs and should fail.

    XPYTransactionBuilderError errorCode = XPYTransactionBuilderInsufficientFunds;
    if (result.transaction.inputs.count == 0)
    {
        errorCode = XPYTransactionBuilderUnspentOutputsMissing;
    }
    if (errorOut) *errorOut = [NSError errorWithDomain:XPYTransactionBuilderErrorDomain code:errorCode userInfo:nil];
    return nil;
}




// Helpers



- (XPYTransactionInput*) makeTransactionInputWithUnspentOutput:(XPYTransactionOutput*)utxo
{
    XPYTransactionInput* txin = [[XPYTransactionInput alloc] init];

    if (!utxo.transactionHash || utxo.index == XPYTransactionOutputIndexUnknown)
    {
        [[NSException exceptionWithName:@"Incorrect unspent transaction output" reason:@"Unspent output must have valid -transactionHash and -index properties" userInfo:nil] raise];
    }

    txin.previousHash = utxo.transactionHash;
    txin.previousIndex = utxo.index;
    txin.signatureScript = utxo.script; // put the output script here so the signer knows which key to use.
    txin.transactionOutput = utxo;

    return txin;
}


- (XPYAmount) computeFeeForTransaction:(XPYTransaction*)tx
{
    // Compute fees for this tx by composing a tx with properly sized dummy signatures.
    XPYTransaction* simtx = [tx copy];
    uint32_t i = 0;
    for (XPYTransactionInput* txin in simtx.inputs)
    {
        NSAssert(!!txin.transactionOutput, @"must have transactionOutput");
        XPYScript* txoutScript = txin.transactionOutput.script;

        if (![self attemptToSignTransactionInput:txin tx:simtx inputIndex:i error:NULL])
        {
            // TODO: if cannot match the simulated signature, use data source to provide one. (If signing API available, then use it.)
            txin.signatureScript = [txoutScript simulatedSignatureScriptWithOptions:XPYScriptSimulationMultisigP2SH];
        }

        if (!txin.signatureScript) txin.signatureScript = txoutScript;

        i++;
    }
    return [simtx estimatedFeeWithRate:self.feeRate];
}


// Tries to sign a transaction and returns index set of unsigned inputs.
- (NSIndexSet*) attemptToSignTransaction:(XPYTransaction*)tx error:(NSError**)errorOut
{
    // By default, all inputs are marked to be signed.
    NSMutableIndexSet* unsignedIndexes = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < tx.inputs.count; i++)
    {
        [unsignedIndexes addIndex:i];
    }

    // Check if we can possibly sign anything. Otherwise return early.
    if (!_shouldSign || tx.inputs.count == 0 || !self.dataSource)
    {
        return unsignedIndexes;
    }

    if (_shouldShuffle && _shouldSign)
    {
        // Shuffle both the inputs and outputs.
        NSData* seed = nil;

        if ([self.dataSource respondsToSelector:@selector(shuffleSeedForTransactionBuilder:)])
        {
            seed = [self.dataSource shuffleSeedForTransactionBuilder:self];
        }

        if (!seed && [self.dataSource respondsToSelector:@selector(transactionBuilder:keyForUnspentOutput:)])
        {
            // find the first key
            for (XPYTransactionInput* txin in tx.inputs)
            {
                XPYKey* k = [self.dataSource transactionBuilder:self keyForUnspentOutput:txin.transactionOutput];
                seed = k.privateKey;
                if (seed) break;
            }
        }

        // If finally have something as a seed, shuffle
        if (seed)
        {
            tx.inputs = [self shuffleInputs:tx.inputs withSeed:seed];
            tx.outputs = [self shuffleOutputs:tx.outputs withSeed:seed];
        }
    }

    // Try to sign each input.
    for (uint32_t i = 0; i < tx.inputs.count; i++)
    {
        // We support two kinds of scripts: p2pkh (modern style) and p2pk (old style)
        // For each of these we support compressed and uncompressed pubkeys.
        XPYTransactionInput* txin = tx.inputs[i];

        if ([self attemptToSignTransactionInput:txin tx:tx inputIndex:i error:errorOut])
        {
            [unsignedIndexes removeIndex:i];
        }
    } // each input

    return unsignedIndexes;
}

- (NSArray*) shuffleInputs:(NSArray*)txins withSeed:(NSData*)seed
{
    return [txins sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(XPYTransactionInput* a, XPYTransactionInput* b) {
        NSData* d1 = XPYHash256Concat(a.data, seed);
        NSData* d2 = XPYHash256Concat(b.data, seed);
        return [d1.description compare:d2.description];
    }];
}

- (NSArray*) shuffleOutputs:(NSArray*)txouts withSeed:(NSData*)seed
{
    return [txouts sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(XPYTransactionOutput* a, XPYTransactionOutput* b) {
        NSData* d1 = XPYHash256Concat(a.data, seed);
        NSData* d2 = XPYHash256Concat(b.data, seed);
        return [d1.description compare:d2.description];
    }];
}

- (BOOL) attemptToSignTransactionInput:(XPYTransactionInput*)txin tx:(XPYTransaction*)tx inputIndex:(uint32_t)i error:(NSError**)errorOut
{
    if (!_shouldSign) return NO;

    // We stored output script here earlier.
    XPYScript* outputScript = txin.signatureScript;
    XPYKey* key = nil;

    if ([self.dataSource respondsToSelector:@selector(transactionBuilder:keyForUnspentOutput:)])
    {
        key = [self.dataSource transactionBuilder:self keyForUnspentOutput:txin.transactionOutput];
    }

    if (key)
    {
        NSData* cpk = key.compressedPublicKey;
        NSData* ucpk = key.uncompressedPublicKey;

        XPYSignatureHashType hashtype = SIGHASH_ALL;

        NSData* sighash = [tx signatureHashForScript:[outputScript copy] inputIndex:i hashType:hashtype error:errorOut];
        if (!sighash)
        {
            return NO;
        }

        // Most common case: P2PKH with compressed pubkey (because of BIP32)
        XPYScript* p2cpkhScript = [[XPYScript alloc] initWithAddress:[XPYPublicKeyAddress addressWithData:XPYHash160(cpk)]];
        if ([outputScript.data isEqual:p2cpkhScript.data])
        {
            txin.signatureScript = [[[XPYScript new] appendData:[key signatureForHash:sighash hashType:hashtype]] appendData:cpk];
            return YES;
        }

        // Less common case: P2PKH with uncompressed pubkey (when not using BIP32)
        XPYScript* p2ucpkhScript = [[XPYScript alloc] initWithAddress:[XPYPublicKeyAddress addressWithData:XPYHash160(ucpk)]];
        if ([outputScript.data isEqual:p2ucpkhScript.data])
        {
            txin.signatureScript = [[[XPYScript new] appendData:[key signatureForHash:sighash hashType:hashtype]] appendData:ucpk];
            return YES;
        }

        XPYScript* p2cpkScript = [[[XPYScript new] appendData:cpk] appendOpcode:OP_CHECKSIG];
        XPYScript* p2ucpkScript = [[[XPYScript new] appendData:ucpk] appendOpcode:OP_CHECKSIG];

        if ([outputScript.data isEqual:p2cpkScript] ||
            [outputScript.data isEqual:p2ucpkScript])
        {
            txin.signatureScript = [[XPYScript new] appendData:[key signatureForHash:sighash hashType:hashtype]];
            return YES;
        }
        else
        {
            // Not supported script type.
            // Try custom signature.
        }
    } // if key

    // Ask to sign the transaction input to sign this if that's some kind of special input or script.
    if ([self.dataSource respondsToSelector:@selector(transactionBuilder:signatureScriptForTransaction:script:inputIndex:)])
    {
        XPYScript* sigScript = [self.dataSource transactionBuilder:self signatureScriptForTransaction:tx script:outputScript inputIndex:i];
        if (sigScript)
        {
            txin.signatureScript = sigScript;
            return YES;
        }
    }

    return NO;
}




// Properties



- (XPYScript*) changeScript
{
    if (_changeScript) return _changeScript;

    if (!self.changeAddress) return nil;

    return [[XPYScript alloc] initWithAddress:self.changeAddress.publicAddress];
}

- (NSEnumerator*) unspentOutputsEnumerator
{
    if (_unspentOutputsEnumerator) return _unspentOutputsEnumerator;

    if (self.dataSource)
    {
        return [self.dataSource unspentOutputsForTransactionBuilder:self];
    }

    return nil;
}

- (XPYAmount) minimumChange
{
    if (_minimumChange < 0) return self.feeRate;
    return _minimumChange;
}

- (XPYAmount) dustChange
{
    if (_dustChange < 0) return self.minimumChange;
    return _dustChange;
}

@end


@implementation XPYTransactionBuilderResult
@end

