//
//  XPYCurrencyConverterTests.swift
//  CorePaycoin
//
//  Created by Robert S Mozayeni on 5/19/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class XPYCurrencyConverterTests: XCTestCase {
    
    func testRateUpdates() {
        let converter = XPYCurrencyConverter()
        converter.buyRate = NSDecimalNumber(string: "210.0")
        converter.sellRate = NSDecimalNumber(string: "200.0")
        
        XCTAssertEqual(converter.averageRate.doubleValue, 205.0, "Average should be from buy and sell rates")
        
        converter.averageRate = NSDecimalNumber(string: "300.0")
        
        XCTAssertEqual(converter.sellRate.doubleValue, 300, "Setting average should reassign sell rate")
        XCTAssertEqual(converter.buyRate.doubleValue, 300, "Setting average should reassign buy rate")
        
    }
    
    func testAsksAndBids() {
        let converter = XPYCurrencyConverter()
        converter.buyRate = NSDecimalNumber(string: "210.0")
        converter.sellRate = NSDecimalNumber(string: "200.0")
        
        let asks = [[NSNumber(double: 209.0), NSNumber(double: 1.0)]]
        
        converter.asks = asks
        XCTAssertNotNil(converter.asks, "Should be valid ask array")
        
        let bids = [[NSNumber(double: 201.0), NSNumber(double: 1.0)]]
        
        converter.bids = bids
        XCTAssertNotNil(converter.bids, "Should be valid bids array")
        
        
    }
    
    func testFiatConversions() {
        let converter = XPYCurrencyConverter()
        converter.buyRate = NSDecimalNumber(string: "205.0")
        converter.sellRate = NSDecimalNumber(string: "195.0")
        
        
        
        converter.mode = XPYCurrencyConverterMode.Average
        let averageXPYAmount = converter.paycoinFromFiat(NSDecimalNumber(string: "10.0"))
        
        XCTAssertEqual(averageXPYAmount, 5000000, "10.0 fiat with average XPY price of 200 should buy 5 million satoshis")
        
        
        
        converter.mode = XPYCurrencyConverterMode.Buy
        let buyXPYAmount = converter.paycoinFromFiat(NSDecimalNumber(string: "10.0"))
        
        XCTAssertEqual(buyXPYAmount, 4878049, "10.0 fiat with buy rate of 205 should buy 4878049 satoshis")
        
        
        
        converter.mode = XPYCurrencyConverterMode.Sell
        let sellXPYAmount = converter.paycoinFromFiat(NSDecimalNumber(string: "10.0"))
        XCTAssertEqual(sellXPYAmount, 5128205, "10.0 fiat with sell rate of 195 should convert to 5128205 satoshis")
        
    }
}
