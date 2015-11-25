//
//  XPYAddressTests.swift
//  CorePaycoin
//
//  Created by Robert S Mozayeni on 4/20/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class XPYAddressTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPublicKeyAddress() {
        let addr = XPYPublicKeyAddress(string: "1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T")!
        XCTAssert(addr.dynamicType === XPYPublicKeyAddress.self, "Address should be an instance of XPYPublicKeyAddress")
        XCTAssertEqual("c4c5d791fcb4654a1ef5e03fe0ad3d9c598f9827", addr.data.hex(), "Must decode hash160 correctly.")
        XCTAssertEqual(addr, addr.publicAddress, "Address should be equal to its publicAddress")
        
        let addr2 = XPYPublicKeyAddress(data: XPYDataFromHex("c4c5d791fcb4654a1ef5e03fe0ad3d9c598f9827"))!
        
        XCTAssertNotNil(addr2, "Address should be created")
        XCTAssertEqual("1JwSSubhmg6iPtRjtyqhUYYH7bZg3Lfy1T", addr2.string, "Must encode hash160 correctly.")
    }
    
    func testPrivateKeyAddress() {
        let addr = XPYPrivateKeyAddress(string: "5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS")!
        XCTAssert(addr.dynamicType === XPYPrivateKeyAddress.self, "Address should be an instance of XPYPrivateKeyAddress")
        XCTAssert(!addr.publicKeyCompressed, "Address should be not compressed")
        XCTAssertEqual("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a", addr.data.hex(), "must provide proper public address")
        
        let addr2 = XPYPrivateKeyAddress(data: XPYDataFromHex("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"))!
        XCTAssertNotNil(addr2, "Address should be created")
        XCTAssertEqual("5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS", addr2.string, "Must encode secret key correctly.")
    }
    
    func testPrivateKeyAddressWithCompressedPoint() {
        let addr = XPYPrivateKeyAddress(string: "L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu")!
        XCTAssert(addr.dynamicType === XPYPrivateKeyAddress.self, "Address should be an instance of XPYPrivateKeyAddress")
        XCTAssert(addr.publicKeyCompressed, "address should be compressed")
        XCTAssertEqual("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a", addr.data.hex(), "Must decode secret key correctly.")
        XCTAssertEqual(addr.publicAddress.string, "1C7zdTfnkzmr13HfA2vNm5SJYRK6nEKyq8", "must provide proper public address")
        
        let addr2 = XPYPrivateKeyAddress(data: XPYDataFromHex("c4bbcb1fbec99d65bf59d85c8cb62ee2db963f0fe106f483d9afa73bd4e39a8a"))!
        addr2.publicKeyCompressed = true
        XCTAssertEqual("L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu", addr2.string, "Must encode secret key correctly.")
        addr2.publicKeyCompressed = false
        XCTAssertEqual("5KJvsngHeMpm884wtkJNzQGaCErckhHJBGFsvd3VyK5qMZXj3hS", addr2.string, "Must encode secret key correctly.")
    }
    
    func testScriptHashKeyAddress() {
        let addr = XPYScriptHashAddress(string: "3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8")!
        XCTAssert(addr.dynamicType === XPYScriptHashAddress.self, "Address should be an instance of XPYScriptHashAddress")
        XCTAssertEqual("e8c300c87986efa84c37c0519929019ef86eb5b4", addr.data.hex(), "Must decode hash160 correctly.")
        XCTAssertEqual(addr, addr.publicAddress, "Address should be equal to its publicAddress")
        
        let addr2 = XPYScriptHashAddress(data: XPYDataFromHex("e8c300c87986efa84c37c0519929019ef86eb5b4"))!
        XCTAssertNotNil(addr2, "Address should be created")
        XCTAssertEqual("3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8", addr2.string, "Must encode hash160 correctly.")
    }

    func testAssetAddress() {
        let XPYAddr = XPYPublicKeyAddress(string: "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM")!
        let assetAddr = XPYAssetAddress(paycoinAddress:XPYAddr)
        XCTAssertEqual("akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy", assetAddr.string, "Must encode to Open Assets format correctly.")

        let assetAddr2 = XPYAssetAddress(string:"akB4NBW9UuCmHuepksob6yfZs6naHtRCPNy")!
        XCTAssertEqual("16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM", assetAddr2.paycoinAddress.string, "Must decode underlying Paycoin address from Open Assets address.")
    }

    func testParseErrors() {
        XCTAssertNil(XPYAddress(string: "X6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"), "Must fail to parse incorrect address")
        XCTAssertNil(XPYPublicKeyAddress(string: "3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8"), "Must fail to parse valid address of non-matching type")
        XCTAssertNil(XPYPrivateKeyAddress(string: "3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8"), "Must fail to parse valid address of non-matching type")
        XCTAssertNil(XPYScriptHashAddress(string: "L3p8oAcQTtuokSCRHQ7i4MhjWc9zornvpJLfmg62sYpLRJF9woSu"), "Must fail to parse valid address of non-matching type")
        XCTAssertNil(XPYAssetAddress(string: "3NukJ6fYZJ5Kk8bPjycAnruZkE5Q7UW7i8"), "Must fail to parse valid address of non-matching type")
    }

}
