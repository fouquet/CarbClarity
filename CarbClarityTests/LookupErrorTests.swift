//
//  LookupErrorTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 12.07.25.
//

import XCTest
@testable import CarbClarity

final class LookupErrorTests: XCTestCase {
    
    
    // MARK: - Error Conversion Tests
    
    func testFromURLError_WithNotConnectedToInternet_ReturnsNetworkUnavailable() {
        let urlError = URLError(.notConnectedToInternet)
        
        let sut = LookupError.from(urlError)
        
        XCTAssertEqual(sut, .networkUnavailable)
    }
    
    func testFromURLError_WithNetworkConnectionLost_ReturnsNetworkUnavailable() {
        let urlError = URLError(.networkConnectionLost)
        
        let sut = LookupError.from(urlError)
        
        XCTAssertEqual(sut, .networkUnavailable)
    }
    
    func testFromURLError_WithTimedOut_ReturnsTimeout() {
        let urlError = URLError(.timedOut)
        
        let sut = LookupError.from(urlError)
        
        XCTAssertEqual(sut, .timeout)
    }
    
    func testFromURLError_WithBadURL_ReturnsUnknownError() {
        let urlError = URLError(.badURL)
        
        let sut = LookupError.from(urlError)
        
        if case .unknown(let message) = sut {
            XCTAssertTrue(message.contains("URL") || message.contains("url"))
        } else {
            XCTFail("Expected unknown error")
        }
    }
    
    func testFromNSError_WithHTTP401_ReturnsInvalidAPIKey() {
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let nsError = NSError(
            domain: "TestDomain",
            code: 401,
            userInfo: ["response": httpResponse]
        )
        
        let sut = LookupError.from(nsError)
        
        XCTAssertEqual(sut, .invalidAPIKey)
    }
    
    func testFromNSError_WithHTTP403_ReturnsInvalidAPIKey() {
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 403,
            httpVersion: nil,
            headerFields: nil
        )!
        let nsError = NSError(
            domain: "TestDomain",
            code: 403,
            userInfo: ["response": httpResponse]
        )
        
        let sut = LookupError.from(nsError)
        
        XCTAssertEqual(sut, .invalidAPIKey)
    }
    
    func testFromNSError_WithHTTP400_ReturnsServerError() {
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )!
        let nsError = NSError(
            domain: "TestDomain",
            code: 400,
            userInfo: ["response": httpResponse]
        )
        
        let sut = LookupError.from(nsError)
        
        XCTAssertEqual(sut, .serverError(400))
    }
    
    func testFromNSError_WithHTTP500_ReturnsServerError() {
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        let nsError = NSError(
            domain: "TestDomain",
            code: 500,
            userInfo: ["response": httpResponse]
        )
        
        let sut = LookupError.from(nsError)
        
        XCTAssertEqual(sut, .serverError(500))
    }
    
    func testFromNSError_WithLookupAPINoAPIKeyMessage_ReturnsNoAPIKey() {
        let nsError = NSError(
            domain: "LookupAPI",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "No API key configured"]
        )
        
        let sut = LookupError.from(nsError)
        
        XCTAssertEqual(sut, .noAPIKey)
    }
    
    func testFromNSError_WithLookupAPIParseFailureMessage_ReturnsParseError() {
        let nsError = NSError(
            domain: "LookupAPI",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]
        )
        
        let sut = LookupError.from(nsError)
        
        XCTAssertEqual(sut, .parseError)
    }
    
    func testFromNSError_WithGenericError_ReturnsUnknownError() {
        let genericError = NSError(
            domain: "SomeOtherDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "Some random error"]
        )
        
        let sut = LookupError.from(genericError)
        
        if case .unknown(let message) = sut {
            XCTAssertEqual(message, "Some random error")
        } else {
            XCTFail("Expected unknown error")
        }
    }
    
    // MARK: - Equatable Tests
    
    func testLookupErrorEquality_WithSameErrors_ReturnsTrue() {
        // Given & When & Then
        XCTAssertEqual(LookupError.networkUnavailable, LookupError.networkUnavailable)
        XCTAssertEqual(LookupError.timeout, LookupError.timeout)
        XCTAssertEqual(LookupError.noAPIKey, LookupError.noAPIKey)
        XCTAssertEqual(LookupError.invalidAPIKey, LookupError.invalidAPIKey)
        XCTAssertEqual(LookupError.serverError(500), LookupError.serverError(500))
        XCTAssertEqual(LookupError.parseError, LookupError.parseError)
        XCTAssertEqual(LookupError.unknown("test"), LookupError.unknown("test"))
    }
    
    func testLookupErrorEquality_WithDifferentErrors_ReturnsFalse() {
        // Given & When & Then
        XCTAssertNotEqual(LookupError.networkUnavailable, LookupError.timeout)
        XCTAssertNotEqual(LookupError.serverError(400), LookupError.serverError(500))
        XCTAssertNotEqual(LookupError.unknown("test1"), LookupError.unknown("test2"))
    }
}
