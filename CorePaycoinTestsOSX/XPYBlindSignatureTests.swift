//
//  XPYBlindSignatureTests.swift
//  CorePaycoin
//
//  Created by Robert S Mozayeni on 5/21/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class XPYBlindSignatureTests: XCTestCase {
    
    func testCoreAlgorithm() {
        
        let api = XPYBlindSignature()
        
        let a = XPYBigNumber(unsignedBigEndian: XPYHash256("a".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        let b = XPYBigNumber(unsignedBigEndian: XPYHash256("b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        let c = XPYBigNumber(unsignedBigEndian: XPYHash256("c".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        let d = XPYBigNumber(unsignedBigEndian: XPYHash256("d".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        let p = XPYBigNumber(unsignedBigEndian: XPYHash256("p".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        let q = XPYBigNumber(unsignedBigEndian: XPYHash256("q".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)))
        
        let PQ = api.bob_P_and_Q_for_p(p, q: q) as! [XPYCurvePoint]
        let P = PQ.first!
        let Q = PQ.last!
        
        XCTAssertNotNil(P, "sanity check")
        XCTAssertNotNil(Q, "sanity check")
        
        let KT = api.alice_K_and_T_for_a(a, b: b, c: c, d: d, p: P, q: Q) as! [XPYCurvePoint]
        let K = KT.first!
        let T = KT.last!
        
        XCTAssertNotNil(K, "sanity check")
        XCTAssertNotNil(T, "sanity check")
        
        // In real life we'd use T in a destination script and keep K.x around for redeeming it later.
        // ...
        // It's time to redeem funds! Lets do it by asking Bob to sign stuff for Alice.
        
        let hash = XPYHash256("some transaction".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        
        // Alice computes and sends to Bob.
        let blindedHash = api.aliceBlindedHashForHash(XPYBigNumber(unsignedBigEndian: hash), a: a, b: b)
        
        XCTAssertNotNil(blindedHash, "sanity check")
        
        // Bob computes and sends to Alice.
        let blindedSig = api.bobBlindedSignatureForHash(blindedHash, p: p, q: q)
        
        XCTAssertNotNil(blindedSig, "sanity check")
        
        // Alice unblinds and uses in the final signature.
        let unblindedSignature = api.aliceUnblindedSignatureForSignature(blindedSig, c: c, d: d)
        
        XCTAssertNotNil(unblindedSignature, "sanity check")
        
        let finalSignature = api.aliceCompleteSignatureForKx(K.x, unblindedSignature: unblindedSignature)
        
        XCTAssertNotNil(finalSignature, "sanity check")
        
        let pubkey = XPYKey(curvePoint: T)
        XCTAssertTrue(pubkey.isValidSignature(finalSignature, hash: hash), "should have created a valid signature after all that trouble")
        
    }
    
    
    func testConvenienceAPI() {
        let aliceKeychain = XPYKeychain(seed: "Alice".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        let bobKeychain = XPYKeychain(seed: "Bob".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        let bobPublicKeychain = XPYKeychain(extendedKey: bobKeychain.extendedPublicKey)
        
        XCTAssertNotNil(aliceKeychain, "sanity check")
        XCTAssertNotNil(bobKeychain, "sanity check")
        XCTAssertNotNil(bobPublicKeychain, "sanity check")
        
        let alice = XPYBlindSignature(clientKeychain: aliceKeychain, custodianKeychain: bobPublicKeychain)
        let bob = XPYBlindSignature(custodianKeychain: bobKeychain)
        
        XCTAssertNotNil(alice, "sanity check")
        XCTAssertNotNil(bob, "sanity check")
        
        for var i: uint32 = 0; i < 32; i++ {
            // This will be Alice's pubkey that she can use in a destination script.
            let pubkey = alice.publicKeyAtIndex(i)
            XCTAssertNotNil(pubkey, "sanity check")
            
//            println("pubkey = \(pubkey)")
            
            // This will be a hash of Alice's transaction.
            let hash = XPYHash256("transaction \(i)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
            
//            println("hash = \(hash)")
            
            // Alice will send this to Bob.
            let blindedHash = alice.blindedHashForHash(hash, index: i)
            XCTAssertNotNil(blindedHash, "sanity check")
            
            // Bob computes the signature for Alice and sends it back to her.
            let blindSig = bob.blindSignatureForBlindedHash(blindedHash)
            XCTAssertNotNil(blindSig, "sanity check")
            
            // Alice receives the blind signature and computes the complete ECDSA signature ready to use in a redeeming transaction.
            let finalSig = alice.unblindedSignatureForBlindSignature(blindSig, verifyHash: hash)
            XCTAssertNotNil(finalSig, "sanity check")
            
            XCTAssertTrue(pubkey.isValidSignature(finalSig, hash: hash), "Check that the resulting signature is valid for our original hash and pubkey.")
        }
    }
}
