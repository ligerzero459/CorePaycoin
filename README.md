CorePaycoin
===========

CorePaycoin implements Bitcoin protocol in Objective-C and provides many additional APIs to make great apps.

CorePaycoin deliberately implements as much as possible directly in Objective-C with limited dependency on OpenSSL. This gives everyone an opportunity to learn Bitcoin on a clean codebase and enables all Mac and iOS developers to extend and improve Bitcoin protocol.

Note that "Bitcoin Core" (previously known as BitcoinQT or "Satoshi client") is a completely different project.


Projects using CorePaycoin
--------------------------

- [Chain-iOS SDK](https://github.com/chain-engineering/chain-ios) (written by Oleg Andreev)
- [Mycelium iOS Wallet](https://itunes.apple.com/us/app/mycelium-bitcoin-wallet/id943912290) (written by Oleg Andreev)
- [bitWallet](https://itunes.apple.com/us/app/bitwallet-bitcoin-wallet/id777634714)
- [Yallet](https://www.yallet.com)
- [BitStore](http://bitstoreapp.com)
- [ArcBit](http://arcbit.io)

Features
--------

See also [Release Notes](ReleaseNotes.md).

- Encoding/decoding addresses: P2PK, P2PKH, P2SH, WIF format ([XPYAddress](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYAddress.h)).
- Transaction building blocks: inputs, outputs, scripts ([XPYTransaction](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYTransaction.h), [XPYScript](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYScript.h)).
- EC keys and signatures ([XPYKey](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYKey.h)).
- High-level convenient and safe transaction builder ([XPYTransactionBuilder](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYTransactionBuilder.h)).
- Parsing and composing bitcoin URLs and payment requests ([XPYBitcoinURL](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYBitcoinURL.h)).
- QR Code generator and scanner in a unified API (iOS only for now; [XPYQRCode](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYQRCode.h)).
- BIP32, BIP44 hierarchical deterministic wallets ([XPYKeychain](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYKeychain.h)).
- BIP39 implementation ([XPYMnemonic](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYMnemonic.h)).
- BIP70 implementation ([XPYPaymentProtocol](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYPaymentProtocol.h)).
- [Automatic Encrypted Wallet Backup](https://github.com/ligerzero459/bitcoin-papers/blob/master/AutomaticEncryptedWalletBackups.md) scheme ([XPYEncryptedBackup](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYEncryptedBackup.h)).

Currency Tools
--------------

- Bitcoin currency formatter with support for XPY, mXPY, bits ([XPYNumberFormatter](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYNumberFormatter.h)).
- Currency converter (not linked to any exchange) with support for various methods to calculate exchange rate ([XPYCurrencyConverter](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYCurrencyConverter.h)).
- Various price sources and abstract interface for adding new ones ([XPYPriceSource](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYPriceSource.h) with support for Winkdex, Coindesk, Coinbase, Paymium).

Advanced Features
-----------------

- Deterministic [RFC6979](https://tools.ietf.org/html/rfc6979#section-3.2)-compliant ECDSA signatures.
- Script evaluation machine to actually validate individual transactions ([XPYScriptMachine](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYScriptMachine.h)).
- Blind signatures implementation ([XPYBlindSignature](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYBlindSignature.h)).
- Math on elliptic curves: big numbers, curve points, conversion between keys, numbers and points ([XPYBigNumber](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYBigNumber.h), [XPYCurvePoint](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYCurvePoint.h)).
- Various cryptographic primitives like hash functions and AES encryption (see [XPYData.h](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYData.h)).


On the roadmap
--------------

See [all todo items](https://github.com/ligerzero459/CorePaycoin/issues).

- Complete support for blocks and block headers.
- SPV mode and P2P communication with other nodes.
- Full blockchain verification procedure and storage.
- Importing BitcoinQT, Electrum and Blockchain.info wallets.
- Support for [libsecp256k1](https://github.com/bitcoin/secp256k1) in addition to OpenSSL.
- Eventual support for libconsensus as it gets more mature and feature-complete.

The goal is to implement everything useful related to Bitcoin and organize it nicely in a single powerful library. Pull requests are welcome.


Starting points
---------------

To encode/decode addresses see [XPYAddress](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYAddress.h).

To perform cryptographic operations, use [XPYKey](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYKey.h), [XPYBigNumber](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYBigNumber.h) and [XPYCurvePoint](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYCurvePoint). [XPYKeychain](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYKeychain.h) implements BIP32 (hierarchical deterministic wallet).

To fetch unspent coins and broadcast transactions use one of the 3rd party APIs: [XPYBlockchainInfo](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYBlockchainInfo.h) (blockchain.info) or [Chain-iOS](https://github.com/chain-engineering/chain-ios) (recommended).

For full wallet workflow see [XPYTransaction+Tests.m](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYTransaction+Tests.m) (fetch unspent outputs, compose a transaction, sign inputs, verify and broadcast).

For multisignature scripts usage see [XPYScript+Tests.m](https://github.com/ligerzero459/CorePaycoin/blob/master/CorePaycoin/XPYScript+Tests.m): compose and unlock multisig output.

All other files with `+Tests` in their name are worth checking out as they contain useful sample code.


Using CorePaycoin CocoaPod (recommended)
----------------------------------------

Add this to your Podfile:

    pod 'CorePaycoin', :podspec => 'https://raw.github.com/ligerzero459/CorePaycoin/master/CorePaycoin.podspec'

Run in Terminal:

    $ pod install

Include headers:

	#import <CorePaycoin/CorePaycoin.h>

If you'd like to use categories, include different header:

	#import <CorePaycoin/CorePaycoin+Categories.h>


Using CorePaycoin.framework
---------------------------

Clone this repository and build all libraries:

	$ ./update_openssl.sh
	$ ./build_libraries.sh

Copy iOS or OS X framework located in binaries/iOS or binaries/OSX to your project.

Include headers:

	#import <CorePaycoin/CorePaycoin.h>
	
There are also raw universal libraries (.a) with headers located in binaries/include, if you happen to need them for some reason. Frameworks and binary libraries have OpenSSL built-in. If you have different version of OpenSSL in your project, consider using CocoaPods or raw sources of CorePaycoin.


Swift
-----

We love Swift and design the code to be compatible with Swift. That means using modern enums, favoring initializers over factory methods, avoiding obscure C features etc. You are welcome to try using CorePaycoin from Swift, please file bugs if you have problems.

Swift is awesome to write crypto in it (due to explicit optionals, generics and first-class structs) and we would love to rewrite the entire CorePaycoin and even relevant portions of OpenSSL in it. Unfortunately, for a year or two it's just out of the question due to instability. And then, using Swift-only features on the API level would mean that Objective-C code wouldn't be able to use CorePaycoin. Given that, in the medium term we will focus solely on Objective-C implementation compatible with Swift. When everyone jumps exclusively on Swift, we'll make a complete rewrite.


Contribute
----------

Feel free to open issues, drop us pull requests or contact us to discuss how to do things.

Follow existing code style and use 4 spaces instead of tabs. Methods have opening braces on a new line. There's no line width limit.

Email: [ligerzero459@gmail.com](mailto:ligerzero459@gmail.com)

Twitter: [@ligerzero459](http://twitter.com/ligerzero459)

To publish on CocoaPods:

    $ pod trunk push --verbose --use-libraries


Donate
------

Please send your donations here: 1CXPYGivXmHQ8ZqdPgeMfcpQNJrqTrSAcG.

All funds will be used only for bounties.

You can also donate to a specific bounty. The amount will be reserved for that bounty and listed above. Contact [Oleg](mailto:ligerzero459@gmail.com) to arrange that.


License
-------

Released under [WTFPL](http://www.wtfpl.net) (except for OpenSSL). Have a nice day.

