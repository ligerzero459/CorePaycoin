//
//  XPYCurvePointTests.swift
//  CorePaycoin
//
//  Created by Robert S Mozayeni on 5/21/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class XPYCurvePointTests: XCTestCase {
    
    func testPublicKey() {
        
        // Should be able to create public key N = n*G via XPYKey API as well as raw EC arithmetic using XPYCurvePoint.
        let privateKeyData = XPYHash256("Private Key Seed".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        
        // 1. Make the pubkey using XPYKey API.
        
        let key = XPYKey(privateKey: privateKeyData)
        
        
        // 2. Make the pubkey using XPYCurvePoint API.
        
        let bn = XPYBigNumber(unsignedBigEndian: privateKeyData)
        
        let generator = XPYCurvePoint.generator()
        let pubKeyPoint = generator.copy().multiply(bn)
        let keyFromPoint = XPYKey(curvePoint: pubKeyPoint)
        
        // 2.1. Test serialization
        
        XCTAssertEqual(pubKeyPoint, XPYCurvePoint(data: pubKeyPoint.data), "test serialization")
        
        // 3. Compare the two pubkeys.
        
        XCTAssertEqual(keyFromPoint, key, "pubkeys should be equal")
        XCTAssertEqual(key.curvePoint, pubKeyPoint, "points should be equal")
        
    }
    
    func testDiffieHellman() {
        // Alice: a, A=a*G. Bob: b, B=b*G.
        // Test shared secret: a*B = b*A = (a*b)*G.
        
        let alicePrivateKeyData = XPYHash256("alice private key".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        let bobPrivateKeyData = XPYHash256("bob private key".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        
//        println("Alice privkey: \(XPYHexFromData(alicePrivateKeyData))")
//        println("Bob privkey: \(XPYHexFromData(bobPrivateKeyData))")
        
        let aliceNumber = XPYBigNumber(unsignedBigEndian: alicePrivateKeyData)
        let bobNumber = XPYBigNumber(unsignedBigEndian: bobPrivateKeyData)
        
//        println("Alice number: \(aliceNumber.hexString)")
//        println("Bob number: \(bobNumber.hexString)")
        
        let aliceKey = XPYKey(privateKey: alicePrivateKeyData)
        let bobKey = XPYKey(privateKey: bobPrivateKeyData)
        
        XCTAssertEqual(aliceKey.privateKey, aliceNumber.unsignedBigEndian, "")
        XCTAssertEqual(bobKey.privateKey, bobNumber.unsignedBigEndian, "")
        
        let aliceSharedSecret = bobKey.curvePoint.multiply(aliceNumber)
        let bobSharedSecret = aliceKey.curvePoint.multiply(bobNumber)
        
//        println("(a*B).x = \(aliceSharedSecret.x.decimalString)")
//        println("(b*A).x = \(bobSharedSecret.x.decimalString)")
        
        let sharedSecretNumber = aliceNumber.mutableCopy().multiply(bobNumber, mod: XPYCurvePoint.curveOrder())
        let sharedSecret = XPYCurvePoint.generator().multiply(sharedSecretNumber)
        
        XCTAssertEqual(aliceSharedSecret, bobSharedSecret, "Should have the same shared secret")
        XCTAssertEqual(aliceSharedSecret, sharedSecret, "Multiplication of private keys should yield a private key for the shared point")
        
    }
}
