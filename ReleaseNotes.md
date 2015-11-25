CorePaycoin Release Notes
=========================

CorePaycoin 0.6.7
-----------------

March 30, 2015.

* Implemented RFC6979 deterministic signatures (`XPYKey`). Previously signatures were also deterministic, but non-standard.
* Implemented [Automatic Encrypted Wallet Backup scheme](https://github.com/oleganza/bitcoin-papers/blob/master/AutomaticEncryptedWalletBackups.md) (`XPYEncryptedBackup`).
* Fixed crash in XPYBitcoinURL parser on invalid amounts.

CorePaycoin 0.6.6
-----------------

March 29, 2015.

* Added support for BIP70 Payment Requests (`XPYPaymentProtocol`). Note: X.509 signatures are [not verified on OS X](https://github.com/oleganza/CorePaycoin/issues/42) yet.
* Implemented ECIES compatible with [Bitcore-ECIES](https://github.com/bitpay/bitcore-ecies) implementation (`XPYEncryptedMessage`).
* Merged improved Xcode SDK detection to `update_openssl.sh` by Mark Pfluger (@mpfluger).
* Added SHA512 function (`XPYSHA512`).
* Added tail mutation checks to `XPYMerkleTree`.

CorePaycoin 0.6.5
-----------------

March 6, 2015.

* Added merkle tree implementation (`XPYMerkleTree`).

CorePaycoin 0.6.4
-----------------

March 6, 2015.

* Optimized hash functions to efficiently work with memory-mapped `NSData` instances (`XPYSHA1`, `XPYSHA256`, `XPYSHA256Concat` etc).


CorePaycoin 0.6.3
-----------------

March 3, 2015.

* Added Payment Request support to `XPYBitcoinURL` according to [BIP72](https://github.com/bitcoin/bips/blob/master/bip-0072.mediawiki).
* Added Payment Request support to `XPYNetwork` according to [BIP70](https://github.com/bitcoin/bips/blob/master/bip-0070.mediawiki).
* Added support for `tpub...` and `tprv...` extended key encoding on testnet (`XPYKeychain`).
* Improved format conversion API of `XPYBigNumber`.


CorePaycoin 0.6.2
-----------------

January 30, 2015.

* Added price source API (`XPYPriceSource`) with support for Coinbase, Coindesk, Winkdex, Paymium and custom implementations.
* Added label to `XPYBitcoinURL`.
* Improved linking of inputs and outputs to their transaction instance (`XPYTransaction`).
* Added safety check to QR code scanner (`XPYQRCode`).
* Fixed rounding bug in `XPYNumberFormatter`.


CorePaycoin 0.6.0
-----------------

December 3, 2014.

* Improved property declarations to work better with Swift.
* Streamlined hex-related methods (`XPYHexFromData`, `XPYDataFromHex` etc)


CorePaycoin 0.5.3
-----------------

December 2, 2014.

* Block and block headers API (`XPYBlock`, `XPYBlockHeader`).
* Unified hash-to-ID conversion for transactions and blocks (`XPYHashFromID`, `XPYIDFromHash`).
* Added various optional properties to transaction, inputs and outputs (`XPYTransaction`, `XPYTransactionInput`, `XPYTransactionOutput`).
* Renamed type `XPYSatoshi` to `XPYAmount`.


CorePaycoin 0.5.2
-----------------

November 21, 2014.

* Added WIF API and testnet support to `XPYKey`.
* Swift interoperability improvements.

CorePaycoin 0.5.1
-----------------

November 18, 2014.

* Fixed dependencies on UIKit and AppKit.


CorePaycoin 0.5.0
-----------------

November 18, 2014.

* First CocoaPod published.


CorePaycoin 0.1.0
-----------------

August 11, 2013.

* First commit.








