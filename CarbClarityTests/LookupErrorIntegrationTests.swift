//
//  LookupErrorIntegrationTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 12.07.25.
//

import XCTest
import SwiftData
@testable import CarbClarity

@MainActor
final class LookupErrorIntegrationTests: XCTestCase, @unchecked Sendable {
    
    var sut: LookupViewModel!
    var mockSession: MockURLSession!
    var modelContext: ModelContext!
    let testAPIKey = "test-api-key"
    
    private func createViewModelWithMockSession(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) -> LookupViewModel {
        let mockSession = MockURLSession(data: data, response: response, error: error)
        let mockAPI = LookupAPI(apiKey: testAPIKey, session: mockSession)
        return LookupViewModel(apiKey: testAPIKey, modelContext: modelContext, lookupAPI: mockAPI)
    }
    
    override func setUpWithError() throws {
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        MainActor.assumeIsolated {
            modelContext = ModelContext(container)
            mockSession = MockURLSession()
            let mockAPI = LookupAPI(apiKey: testAPIKey, session: mockSession)
            sut = LookupViewModel(apiKey: testAPIKey, modelContext: modelContext, lookupAPI: mockAPI)
        }
    }

    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            sut = nil
            mockSession = nil
            modelContext = nil
        }
    }
    
    // MARK: - Network Error Integration Tests
    
    func testSearch_WithNetworkUnavailableError_ShowsCorrectErrorStateAndAllowsRetry() async {
        let errorViewModel = createViewModelWithMockSession(error: URLError(.notConnectedToInternet))
        
        await errorViewModel.search(for: "apple")
        
        XCTAssertTrue(errorViewModel.foods.isEmpty)
        XCTAssertTrue(errorViewModel.hasSearched)
        XCTAssertFalse(errorViewModel.isLoading)
        XCTAssertEqual(errorViewModel.currentError, .networkUnavailable)
        XCTAssertTrue(errorViewModel.showingError)
        XCTAssertTrue(errorViewModel.currentError?.canRetry == true)
        
        // Given
        let successViewModel = createViewModelWithMockSession(data: createMockSearchResponse())
        
        await successViewModel.search(for: "apple")
        
        XCTAssertEqual(successViewModel.foods.count, 1)
        XCTAssertFalse(successViewModel.showingError)
        XCTAssertNil(successViewModel.currentError)
    }
    
    func testSearch_WithTimeoutError_ShowsCorrectErrorState() async {
        let timeoutViewModel = createViewModelWithMockSession(error: URLError(.timedOut))
        
        await timeoutViewModel.search(for: "banana")
        
        XCTAssertTrue(timeoutViewModel.foods.isEmpty)
        XCTAssertTrue(timeoutViewModel.hasSearched)
        XCTAssertEqual(timeoutViewModel.currentError, .timeout)
        XCTAssertTrue(timeoutViewModel.showingError)
        XCTAssertTrue(timeoutViewModel.currentError?.canRetry == true)
    }
    
    // MARK: - API Key Error Integration Tests
    
    func testSearch_WithEmptyAPIKey_ShowsNoAPIKeyError() async {
        sut.updateDependencies(apiKey: "", modelContext: modelContext)
        
        await sut.search(for: "orange")
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertFalse(sut.hasSearched) // Should not mark as searched for API key errors
        XCTAssertEqual(sut.currentError, .noAPIKey)
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.currentError?.canRetry == true)
    }
    
    func testSearch_With401Response_ShowsInvalidAPIKeyError() async {
        let unauthorizedViewModel = createViewModelWithMockSession(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await unauthorizedViewModel.search(for: "grape")
        
        XCTAssertTrue(unauthorizedViewModel.foods.isEmpty)
        XCTAssertTrue(unauthorizedViewModel.hasSearched)
        XCTAssertEqual(unauthorizedViewModel.currentError, .invalidAPIKey)
        XCTAssertTrue(unauthorizedViewModel.showingError)
        XCTAssertFalse(unauthorizedViewModel.currentError?.canRetry == true)
    }
    
    // MARK: - Server Error Integration Tests
    
    func testSearch_With500Response_ShowsServerError() async {
        let serverErrorViewModel = createViewModelWithMockSession(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await serverErrorViewModel.search(for: "peach")
        
        XCTAssertTrue(serverErrorViewModel.foods.isEmpty)
        XCTAssertTrue(serverErrorViewModel.hasSearched)
        XCTAssertEqual(serverErrorViewModel.currentError, .serverError(500))
        XCTAssertTrue(serverErrorViewModel.showingError)
        XCTAssertTrue(serverErrorViewModel.currentError?.canRetry == true)
    }
    
    func testSearch_WithInvalidJSON_ShowsParseError() async {
        let parseErrorViewModel = createViewModelWithMockSession(
            data: "invalid json".data(using: .utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await parseErrorViewModel.search(for: "pear")
        
        XCTAssertTrue(parseErrorViewModel.foods.isEmpty)
        XCTAssertTrue(parseErrorViewModel.hasSearched)
        XCTAssertEqual(parseErrorViewModel.currentError, .parseError)
        XCTAssertTrue(parseErrorViewModel.showingError)
        XCTAssertTrue(parseErrorViewModel.currentError?.canRetry == true)
    }
    
    // MARK: - Error Recovery Integration Tests
    
    func testSearch_AfterError_ClearsErrorStateOnSuccessfulSearch() async {
        // Given
        let errorViewModel = createViewModelWithMockSession(error: URLError(.networkConnectionLost))
        
        await errorViewModel.search(for: "apple")
        
        XCTAssertNotNil(errorViewModel.currentError)
        XCTAssertTrue(errorViewModel.showingError)
        
        // Given
        let successViewModel = createViewModelWithMockSession(data: createMockSearchResponse())
        
        await successViewModel.search(for: "apple")
        
        XCTAssertNil(successViewModel.currentError)
        XCTAssertFalse(successViewModel.showingError)
        XCTAssertEqual(successViewModel.foods.count, 1)
    }
    
    func testSearch_WithMultipleErrorTypes_HandlesEachErrorCorrectly() async {
        // Given
        let networkErrorViewModel = createViewModelWithMockSession(error: URLError(.notConnectedToInternet))
        
        await networkErrorViewModel.search(for: "test1")
        
        XCTAssertEqual(networkErrorViewModel.currentError, .networkUnavailable)
        
        // Given
        let serverErrorViewModel = createViewModelWithMockSession(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await serverErrorViewModel.search(for: "test2")
        
        XCTAssertEqual(serverErrorViewModel.currentError, .serverError(503))
        
        // Given
        let parseErrorViewModel = createViewModelWithMockSession(
            data: "bad json".data(using: .utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await parseErrorViewModel.search(for: "test3")
        
        XCTAssertEqual(parseErrorViewModel.currentError, .parseError)
    }
    
    func testDismissError_WithActiveError_ClearsErrorState() async {
        let errorViewModel = createViewModelWithMockSession(error: URLError(.timedOut))
        await errorViewModel.search(for: "test")
        
        XCTAssertTrue(errorViewModel.showingError)
        XCTAssertNotNil(errorViewModel.currentError)
        
        errorViewModel.dismissError()
        
        XCTAssertFalse(errorViewModel.showingError)
        XCTAssertNil(errorViewModel.currentError)
    }
    
    // MARK: - Edge Case Integration Tests
    
    func testSearch_RetryWithDifferentError_ShowsNewErrorType() async {
        // Given
        let networkErrorViewModel = createViewModelWithMockSession(error: URLError(.networkConnectionLost))
        
        await networkErrorViewModel.search(for: "test")
        
        XCTAssertEqual(networkErrorViewModel.currentError, .networkUnavailable)
        
        // Given
        let serverErrorViewModel = createViewModelWithMockSession(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await serverErrorViewModel.search(for: "test")
        
        XCTAssertEqual(serverErrorViewModel.currentError, .serverError(500))
        XCTAssertTrue(serverErrorViewModel.showingError)
    }
    
    func testUpdateDependencies_AfterInvalidAPIKeyError_ClearsErrorState() async {
        // Given
        let unauthorizedViewModel = createViewModelWithMockSession(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await unauthorizedViewModel.search(for: "test")
        
        XCTAssertEqual(unauthorizedViewModel.currentError, .invalidAPIKey)
        
        // Given
        
        sut.updateDependencies(apiKey: "new-valid-key", modelContext: modelContext)
        
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
        
        // Given
        let successViewModel = createViewModelWithMockSession(
            data: createMockSearchResponse(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        await successViewModel.search(for: "apple")
        
        XCTAssertNil(successViewModel.currentError)
        XCTAssertEqual(successViewModel.foods.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createMockSearchResponse() -> Data {
        let mockResponse = """
        {
            "foods": [
                {
                    "fdcId": 12345,
                    "description": "Apple, raw",
                    "foodNutrients": [
                        {
                            "nutrientId": 1005,
                            "value": 14.0
                        }
                    ]
                }
            ]
        }
        """
        return mockResponse.data(using: .utf8)!
    }
}
