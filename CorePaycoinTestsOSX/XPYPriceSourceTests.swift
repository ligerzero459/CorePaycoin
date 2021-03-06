//
//  XPYPriceSourceTests.swift
//  CorePaycoin
//
//  Created by Robert S Mozayeni on 4/20/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class XPYPriceSourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCoindesk() {
        let coindesk = XPYPriceSourceCoindesk()
        XCTAssert(coindesk.name.lowercaseString.rangeOfString("coindesk") != nil, "should be named coindesk")
        let codes = coindesk.currencyCodes as! [String]
        XCTAssert(contains(codes, "USD"), "should contain USD")
        XCTAssert(contains(codes, "EUR"), "should contain EUR")
        
        validatePrice(coindesk.loadPriceForCurrency("USD", error: nil), min: 100, max: 10000)
        validatePrice(coindesk.loadPriceForCurrency("EUR", error: nil), min: 100, max: 10000)
    }
    
    func testWinkdex() {
        let winkdex = XPYPriceSourceWinkdex()
        XCTAssert(winkdex.name.lowercaseString.rangeOfString("wink") != nil, "should be named properly")
        
        let codes = winkdex.currencyCodes as! [String]
        
        XCTAssert(contains(codes, "USD"), "should contain USD")
        
        validatePrice(winkdex.loadPriceForCurrency("USD", error: nil), min: 100, max: 10000)
    }
    
    func testCoinbase() {
        let coinbase = XPYPriceSourceCoinbase()
        XCTAssert(coinbase.name.lowercaseString.rangeOfString("coinbase") != nil, "should be named properly")
        let codes = coinbase.currencyCodes as! [String]
        XCTAssert(contains(codes, "USD"), "should contain USD")
    }
    
    func testPaymium() {
        let paymium = XPYPriceSourcePaymium()
        XCTAssert(paymium.name.lowercaseString.rangeOfString("paymium") != nil, "should be named properly")
        
        let codes = paymium.currencyCodes as! [String]
        
        XCTAssert(contains(codes, "EUR"), "should contain EUR")
        validatePrice(paymium.loadPriceForCurrency("EUR", error: nil), min: 100, max: 10000)
        
    }
    
    
    func validatePrice(result: XPYPriceSourceResult?, min: Double, max: Double) {
        
        XCTAssert(result != nil, "result should not be nil")
        
        let number = result!.averageRate
        //        println("price = \(number) \(result.currencyCode)")
        
        XCTAssert(result!.date != nil , "date should not be nil")
        XCTAssert(number != nil, "averageRate should not be nil")
        XCTAssert(number.doubleValue >= min, "Must be over minimum value")
        XCTAssert(number.doubleValue <= max, "Must be under max value")
    }
    
    
}
