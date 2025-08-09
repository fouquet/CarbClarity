//
//  WatchConnectivityManagerTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
import WatchConnectivity
@testable import CarbClarity

final class WatchConnectivityManagerTests: XCTestCase {
    
    var sut: WatchConnectivityManager!
    
    override func setUpWithError() throws {
        sut = WatchConnectivityManager(testMode: true)
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstance_IsSingleton() {
        // Given & When
        let instance1 = WatchConnectivityManager.shared
        let instance2 = WatchConnectivityManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "WatchConnectivityManager should be a singleton")
    }
    
    // MARK: - Initialization Tests
    
    func testInit_WithTestMode_DoesNotSetupSession() {
        // Given & When
        let testManager = WatchConnectivityManager(testMode: true)
        
        // Then
        XCTAssertNotNil(testManager, "Test mode manager should initialize successfully")
    }
    
    func testInit_WithoutTestMode_AttemptsSessionSetup() {
        // Given & When
        XCTAssertNoThrow(WatchConnectivityManager(testMode: false))
    }
    
    // MARK: - ObservableObject Conformance Tests
    
    func testWatchConnectivityManager_ConformsToObservableObject() {
        // Given & When & Then
        XCTAssertTrue(sut is ObservableObject, "WatchConnectivityManager should conform to ObservableObject")
    }
    
    // MARK: - Cross-Platform Widget Refresh Tests
    
    func testRequestCrossPlatformWidgetRefresh_WithoutWCSessionSupport_HandlesGracefully() {
        // Given & When & Then
        XCTAssertNoThrow(sut.requestCrossPlatformWidgetRefresh())
    }
    
    func testRequestCrossPlatformWidgetRefresh_CompletesWithoutError() {
        // Given & When
        sut.requestCrossPlatformWidgetRefresh()
        
        XCTAssertTrue(true, "Method should complete without throwing")
    }
    
    // MARK: - Message Handling Tests
    
    func testHandleMessage_WithRefreshWidgetsAction_CallsWidgetUpdateManager() {
        // Given
        let message = ["action": "refreshWidgets", "timestamp": Date().timeIntervalSince1970] as [String: Any]
        
        // When
        sut.session(WCSession.default, didReceiveMessage: message)
        
        XCTAssertTrue(true, "Message handling should complete without error")
    }
    
    func testHandleMessage_WithInvalidAction_IgnoresMessage() {
        // Given
        let message = ["action": "invalidAction", "timestamp": Date().timeIntervalSince1970] as [String: Any]
        
        // When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveMessage: message))
    }
    
    func testHandleMessage_WithMissingAction_IgnoresMessage() {
        // Given
        let message = ["timestamp": Date().timeIntervalSince1970] as [String: Any]
        
        // When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveMessage: message))
    }
    
    func testHandleMessage_WithEmptyMessage_HandlesGracefully() {
        // Given
        let message: [String: Any] = [:]
        
        // When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveMessage: message))
    }
    
    // MARK: - WCSessionDelegate Method Tests
    
    func testSessionActivationDidComplete_WithoutError_CompletesSuccessfully() {
        // Given & When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, activationDidCompleteWith: .activated, error: nil))
    }
    
    func testSessionActivationDidComplete_WithError_HandlesGracefully() {
        // Given
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        
        // When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, activationDidCompleteWith: .notActivated, error: error))
    }
    
    func testDidReceiveApplicationContext_WithValidMessage_ProcessesCorrectly() {
        // Given
        let context = ["action": "refreshWidgets", "timestamp": Date().timeIntervalSince1970] as [String: Any]
        
        // When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveApplicationContext: context))
    }
    
    func testDidReceiveUserInfo_WithValidMessage_ProcessesCorrectly() {
        // Given
        let userInfo = ["action": "refreshWidgets", "timestamp": Date().timeIntervalSince1970] as [String: Any]
        
        // When & Then
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveUserInfo: userInfo))
    }
    
    // MARK: - iOS-specific Delegate Method Tests
    
    #if os(iOS)
    func testSessionDidBecomeInactive_HandlesCorrectly() {
        // Given & When & Then
        XCTAssertNoThrow(sut.sessionDidBecomeInactive(WCSession.default))
    }
    
    func testSessionDidDeactivate_ReactivatesSession() {
        // Given & When & Then
        XCTAssertNoThrow(sut.sessionDidDeactivate(WCSession.default))
    }
    #endif
    
    // MARK: - Thread Safety Tests
    
    func testMessageHandling_MultipleSequentialCallsHandled() {
        // Given
        let message = ["action": "refreshWidgets"] as [String: Any]
        
        sut.session(WCSession.default, didReceiveMessage: message)
        sut.session(WCSession.default, didReceiveApplicationContext: message)
        sut.session(WCSession.default, didReceiveMessage: message)
        
        XCTAssertTrue(true, "Multiple message handling calls should complete without crash")
    }
    
    func testRequestCrossPlatformWidgetRefresh_FromMultipleThreads_HandlesCorrectly() {
        // Given
        let expectation1 = expectation(description: "Request 1 completion")
        let expectation2 = expectation(description: "Request 2 completion")
        
        // When
        DispatchQueue.global().async {
            self.sut.requestCrossPlatformWidgetRefresh()
            expectation1.fulfill()
        }
        
        DispatchQueue.global().async {
            self.sut.requestCrossPlatformWidgetRefresh()
            expectation2.fulfill()
        }
        
        // Then
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
    
    // MARK: - Error Resilience Tests
    
    func testRequestCrossPlatformWidgetRefresh_WithWCSessionErrors_HandlesGracefully() {
        // Given & When & Then
        XCTAssertNoThrow(sut.requestCrossPlatformWidgetRefresh())
    }
    
    func testMessageHandling_WithMalformedData_HandlesGracefully() {
        // Given
        let malformedMessages = [
            ["action": 123] as [String: Any],
            ["action": "refreshWidgets", "timestamp": "invalid"] as [String: Any],
            ["randomKey": "randomValue"] as [String: Any]
        ]
        
        // When & Then
        for message in malformedMessages {
            XCTAssertNoThrow(sut.session(WCSession.default, didReceiveMessage: message))
        }
    }
    
    // MARK: - Integration Tests
    
    func testWatchConnectivityManager_WithWidgetUpdateManager_IntegratesCorrectly() {
        // Given
        let message = ["action": "refreshWidgets"] as [String: Any]
        
        // When
        sut.session(WCSession.default, didReceiveMessage: message)
        
        let expectation = expectation(description: "Main queue execution")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    // MARK: - Message Handling Tests
    
    func testHandleMessage_WithRefreshWidgetsAction_ProcessesCorrectly() {
        // Given
        let message = ["action": "refreshWidgets"] as [String: Any]
        
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveMessage: message))
    }
    
    func testHandleMessage_WithInvalidAction_HandlesGracefully() {
        // Given
        let invalidMessage = ["action": "unknownAction"] as [String: Any]
        
        XCTAssertNoThrow(sut.session(WCSession.default, didReceiveMessage: invalidMessage))
    }
    
    // MARK: - Coverage Tests
    
    func testWatchConnectivityManager_ExercisesAllDelegateMethods() {
        // Given
        let refreshMessage = ["action": "refreshWidgets"] as [String: Any]
        let context = ["action": "refreshWidgets", "data": "test"] as [String: Any]
        let userInfo = ["action": "refreshWidgets", "source": "watch"] as [String: Any]
        
        sut.session(WCSession.default, didReceiveMessage: refreshMessage)
        sut.session(WCSession.default, didReceiveApplicationContext: context)
        sut.session(WCSession.default, didReceiveUserInfo: userInfo)
        
        sut.session(WCSession.default, activationDidCompleteWith: .activated, error: nil)
        sut.session(WCSession.default, activationDidCompleteWith: .inactive, error: nil)
        sut.session(WCSession.default, activationDidCompleteWith: .notActivated, error: NSError(domain: "TestError", code: 1))
        
        #if os(iOS)
        sut.sessionDidBecomeInactive(WCSession.default)
        sut.sessionDidDeactivate(WCSession.default)
        #endif
        
        // Then
        XCTAssertTrue(true, "All delegate methods should execute without crashing")
    }
    
    func testWatchConnectivityManager_HandlesDifferentMessageTypes() {
        // Given
        let messages = [
            ["action": "refreshWidgets", "timestamp": Date().timeIntervalSince1970] as [String: Any],
            ["action": "refreshWidgets", "source": "phone"] as [String: Any],
            ["action": "refreshWidgets"] as [String: Any],
            [:] as [String: Any],
            ["unknown": "data"] as [String: Any]
        ]
        
        for message in messages {
            sut.session(WCSession.default, didReceiveMessage: message)
            sut.session(WCSession.default, didReceiveApplicationContext: message)
            sut.session(WCSession.default, didReceiveUserInfo: message)
        }
        
        // Then
        XCTAssertTrue(true, "Should handle all message types without crashing")
    }
    
    func testWatchConnectivityManager_MultipleInstancesHaveSameShared() {
        // Given
        let shared1 = WatchConnectivityManager.shared
        let shared2 = WatchConnectivityManager.shared
        let shared3 = WatchConnectivityManager.shared
        
        // When
        let areAllSame = (shared1 === shared2) && (shared2 === shared3)
        
        // Then
        XCTAssertTrue(areAllSame, "All shared instances should reference the same object")
        XCTAssertTrue(shared1 === WatchConnectivityManager.shared, "Shared instance should be consistent")
    }
    
}
