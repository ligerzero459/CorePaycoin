//
//  XPY256Tests.swift
//  CorePaycoin
//
//  Created by Robert S Mozayeni on 6/23/15.
//  Copyright (c) 2015 Oleg Andreev. All rights reserved.
//

import Cocoa
import XCTest

class XPY256Tests: XCTestCase {
    
    func testXPY256ChunkSize() {
        XCTAssertEqual(sizeof(XPY160), 20, "160-bit struct should by 160 bit long")
        XCTAssertEqual(sizeof(XPY256), 32, "256-bit struct should by 256 bit long")
        XCTAssertEqual(sizeof(XPY512), 64, "512-bit struct should by 512 bit long")
    }
    
    func testXPY256Null() {
        XCTAssertEqual(NSStringFromXPY160(XPY160Null), "82963d5edd842f1e6bd2b6bc2e9a97a40a7d8652", "null hash should be correct")
        XCTAssertEqual(NSStringFromXPY256(XPY256Null), "d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e", "null hash should be correct")
        XCTAssertEqual(NSStringFromXPY512(XPY512Null), "62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f0363e01b5d7a53c4a2e5a76d283f3e4a04d28ab54849c6e3e874ca31128bcb759e1", "null hash should be correct")
    }
    
    func testXPY256One() {
        var one = XPY256Zero
        one.words64 = (1, one.words64.1, one.words64.2, one.words64.3)
        XCTAssertEqual(NSStringFromXPY256(one), "0100000000000000000000000000000000000000000000000000000000000000", "")
    }
    
    func testXPY256Equal() {
        XCTAssert(XPY256Equal(XPY256Null, XPY256Null), "equal")
        XCTAssert(XPY256Equal(XPY256Zero, XPY256Zero), "equal")
        XCTAssert(XPY256Equal(XPY256Max,  XPY256Max),  "equal")
        
        XCTAssert(!XPY256Equal(XPY256Zero, XPY256Null), "not equal")
        XCTAssert(!XPY256Equal(XPY256Zero, XPY256Max),  "not equal")
        XCTAssert(!XPY256Equal(XPY256Max,  XPY256Null), "not equal")
    }
    
    func testXPY256Compare() {
        XCTAssert(XPY256Compare(XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
        XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSComparisonResult.OrderedSame, "ordered same")
        
        XCTAssert(XPY256Compare(XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f035"),
        XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSComparisonResult.OrderedAscending, "ordered asc")
        
        XCTAssert(XPY256Compare(XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f037"),
        XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSComparisonResult.OrderedDescending, "ordered asc")
        
        XCTAssert(XPY256Compare(XPY256FromNSString("61ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
        XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSComparisonResult.OrderedAscending, "ordered same")
        
        XCTAssert(XPY256Compare(XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036"),
        XPY256FromNSString("61ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")) == NSComparisonResult.OrderedDescending, "ordered same")
    
    }
    
    func testXPY256Invers() {
        let chunk = XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")
        let chunk2 = XPY256Inverse(chunk)
        
        XCTAssert(!XPY256Equal(chunk, chunk2), "not equal")
        XCTAssert(XPY256Equal(chunk, XPY256Inverse(chunk2)), "equal")
        
        XCTAssertEqual(chunk2.words64.0, ~chunk.words64.0, "bytes are inversed")
        XCTAssertEqual(chunk2.words64.1, ~chunk.words64.1, "bytes are inversed")
        XCTAssertEqual(chunk2.words64.2, ~chunk.words64.2, "bytes are inversed")
        XCTAssertEqual(chunk2.words64.3, ~chunk.words64.3, "bytes are inversed")
        
        XCTAssert(XPY256Equal(XPY256Zero, XPY256AND(chunk, chunk2)), "(a & ~a) == 000000...")
        XCTAssert(XPY256Equal(XPY256Max, XPY256OR(chunk, chunk2)), "(a | ~a) == 111111...")
        XCTAssert(XPY256Equal(XPY256Max, XPY256XOR(chunk, chunk2)), "(a ^ ~a) == 111111...")
    }
    
    func testXPY256Swap() {
        let chunk = XPY256FromNSString("62ce64dd92836e6e99d83eee3f623652f6049cf8c22272f295b262861738f036")
        let chunk2 = XPY256Swap(chunk)
        XCTAssertEqual(XPYReversedData(NSDataFromXPY256(chunk)), NSDataFromXPY256(chunk2), "swap should reverse all bytes")

        XCTAssertEqual(chunk2.words64.0, _OSSwapInt64(chunk.words64.3), "swap should reverse all bytes")
        XCTAssertEqual(chunk2.words64.1, _OSSwapInt64(chunk.words64.2), "swap should reverse all bytes")
        XCTAssertEqual(chunk2.words64.2, _OSSwapInt64(chunk.words64.1), "swap should reverse all bytes")
        XCTAssertEqual(chunk2.words64.3, _OSSwapInt64(chunk.words64.0), "swap should reverse all bytes")

    }
    
    func testXPY256AND() {
        XCTAssert(XPY256Equal(XPY256AND(XPY256Max,  XPY256Max),  XPY256Max),  "1 & 1 == 1")
        XCTAssert(XPY256Equal(XPY256AND(XPY256Max,  XPY256Zero), XPY256Zero), "1 & 0 == 0")
        XCTAssert(XPY256Equal(XPY256AND(XPY256Zero, XPY256Max),  XPY256Zero), "0 & 1 == 0")
        XCTAssert(XPY256Equal(XPY256AND(XPY256Zero, XPY256Null), XPY256Zero), "0 & x == 0")
        XCTAssert(XPY256Equal(XPY256AND(XPY256Null, XPY256Zero), XPY256Zero), "x & 0 == 0")
        XCTAssert(XPY256Equal(XPY256AND(XPY256Max,  XPY256Null), XPY256Null), "1 & x == x")
        XCTAssert(XPY256Equal(XPY256AND(XPY256Null, XPY256Max),  XPY256Null), "x & 1 == x")
    }
    
    func testXPY256OR() {
        XCTAssert(XPY256Equal(XPY256OR(XPY256Max,  XPY256Max),  XPY256Max),  "1 | 1 == 1")
        XCTAssert(XPY256Equal(XPY256OR(XPY256Max,  XPY256Zero), XPY256Max),  "1 | 0 == 1")
        XCTAssert(XPY256Equal(XPY256OR(XPY256Zero, XPY256Max),  XPY256Max),  "0 | 1 == 1")
        XCTAssert(XPY256Equal(XPY256OR(XPY256Zero, XPY256Null), XPY256Null), "0 | x == x")
        XCTAssert(XPY256Equal(XPY256OR(XPY256Null, XPY256Zero), XPY256Null), "x | 0 == x")
        XCTAssert(XPY256Equal(XPY256OR(XPY256Max,  XPY256Null), XPY256Max),  "1 | x == 1")
        XCTAssert(XPY256Equal(XPY256OR(XPY256Null, XPY256Max),  XPY256Max),  "x | 1 == 1")
    }
    
    func testXPY256XOR() {
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Max,  XPY256Max),  XPY256Zero),  "1 ^ 1 == 0")
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Max,  XPY256Zero), XPY256Max),  "1 ^ 0 == 1")
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Zero, XPY256Max),  XPY256Max),  "0 ^ 1 == 1")
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Zero, XPY256Null), XPY256Null), "0 ^ x == x")
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Null, XPY256Zero), XPY256Null), "x ^ 0 == x")
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Max,  XPY256Null), XPY256Inverse(XPY256Null)),  "1 ^ x == ~x")
        XCTAssert(XPY256Equal(XPY256XOR(XPY256Null, XPY256Max),  XPY256Inverse(XPY256Null)),  "x ^ 1 == ~x")
    }
    
    func testXPY256Concat() {
        let concat = XPY512Concat(XPY256Null, XPY256Max)
        XCTAssertEqual(NSStringFromXPY512(concat), "d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e"+"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", "should concatenate properly")
        
        let concat2 = XPY512Concat(XPY256Max, XPY256Null)
        XCTAssertEqual(NSStringFromXPY512(concat2), "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"+"d1007a1fe826e95409e21595845f44c3b9411d5285b6b5982285aabfa5999a5e", "should concatenate properly")
    }
    
    func testXPY256ConvertToData() {
        //TODO...
    }
    
    func testXPY256ConvertToString() {
        let chunk = XPY256FromNSString("000095409e215952" +
                                       "85b6b5982285aabf" +
                                       "a5999a5e845f44c3" +
                                       "b9411d5d1007a1")
        XCTAssert(XPY256Equal(chunk, XPY256Null), "too short string => null")
        
        let chunk2 = XPY256FromNSString("000095409e215952" +
                                        "85b6b5982285aabf" +
                                        "a5999a5e845f44c3" +
                                        "b9411d5d1007a1b166")
        XCTAssertEqual(chunk2.words64.0, _OSSwapInt64(0x000095409e215952), "parse correctly")
        XCTAssertEqual(chunk2.words64.1, _OSSwapInt64(0x85b6b5982285aabf), "parse correctly")
        XCTAssertEqual(chunk2.words64.2, _OSSwapInt64(0xa5999a5e845f44c3), "parse correctly")
        XCTAssertEqual(chunk2.words64.3, _OSSwapInt64(0xb9411d5d1007a1b1), "parse correctly")
        
        XCTAssertEqual(NSStringFromXPY256(chunk2), "000095409e215952" +
                                                   "85b6b5982285aabf" +
                                                   "a5999a5e845f44c3" +
                                                   "b9411d5d1007a1b1", "should serialize to the same string")
        
    }
}
