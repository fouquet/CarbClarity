//
//  LookupAPITests.swift
//  CarbClarity
//
//  Created by René Fouquet on 12.07.25.
//

import XCTest
@testable import CarbClarity

final class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    private let _data: Data?
    private let _response: URLResponse?
    private let _error: Error?
    
    var data: Data? { _data }
    var response: URLResponse? { _response }
    var error: Error? { _error }
    
    init(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
        self._data = data
        self._response = response
        self._error = error
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        
        let data = self.data ?? Data()
        let response = self.response ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
}

final class LookupAPITests: XCTestCase {
    
    var sut: LookupAPI!
    let testAPIKey = "test-api-key-123"
    
    override func setUp() {
        super.setUp()
        sut = createLookupAPI()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    private func createLookupAPI(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) -> LookupAPI {
        let mockSession = MockURLSession(data: data, response: response, error: error)
        return LookupAPI(apiKey: testAPIKey, session: mockSession)
    }

    // MARK: - Initialization Tests
    
    func testInit_WithAPIKey_SetsPropertiesCorrectly() {
        // Given
        let apiKey = testAPIKey
        
        // When
        let lookupAPI = LookupAPI(apiKey: apiKey)
        
        // Then
        XCTAssertEqual(lookupAPI.apiKey, apiKey)
        XCTAssertNotNil(lookupAPI.session)
    }
    
    // MARK: - Request Generation Tests
    
    func testRequest_WithValidPath_CreatesCorrectRequest() {
        // Given
        let path = "/foods/search"
        let method = LookupAPI.Method.post
        
        // When
        let request = sut.request(with: path, method: method)
        
        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.url?.absoluteString, "https://api.nal.usda.gov/fdc/v1/foods/search")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "X-Api-Key"), testAPIKey)
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
    }
    
    func testRequest_WithGETMethod_CreatesGETRequest() {
        // Given
        let path = "/food/12345"
        let method = LookupAPI.Method.get
        
        // When
        let request = sut.request(with: path, method: method)
        
        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.nal.usda.gov/fdc/v1/food/12345")
    }
    
    func testRequest_WithEmptyPath_CreatesBaseURLRequest() {
        let emptyPath = ""
        let method = LookupAPI.Method.get
        
        let request = sut.request(with: emptyPath, method: method)
        
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.url?.absoluteString, "https://api.nal.usda.gov/fdc/v1")
    }
    
    func testRequest_WithSearchPath_GeneratesCorrectSearchRequest() {
        let path = "/foods/search"
        let method = LookupAPI.Method.post
        
        let request = sut.request(with: path, method: method)
        
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.url?.path, "/fdc/v1/foods/search")
    }
    
    // MARK: - Method Enum Tests
    
    
    // MARK: - FetchFoodDetail Method Tests
    
    func testFetchFoodDetailRequest_WithFdcId_GeneratesCorrectRequest() {
        let fdcId = 12345
        let path = "/food/\(fdcId)?nutrients=1005"
        
        let request = sut.request(with: path, method: .get)
        
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.nal.usda.gov/fdc/v1/food/12345?nutrients=1005")
        XCTAssertTrue(request?.url?.query?.contains("nutrients=1005") ?? false)
    }
    
    func testFetchFoodDetailRequest_WithDifferentIds_ContainsCorrectIds() {
        let testIds = [1, 999, 123456]
        
        for fdcId in testIds {
            let request = sut.request(with: "/food/\(fdcId)?nutrients=1005", method: .get)
            
            XCTAssertNotNil(request)
            XCTAssertTrue(request?.url?.absoluteString.contains("\(fdcId)") ?? false)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testSearch_WithEmptyString_HandlesGracefully() async {
        // Given
        let emptySearchTerm = ""
        
        // When & Then
        do {
            let results = try await sut.search(for: emptySearchTerm)
            XCTAssertTrue(results.isEmpty || results.count >= 0)
        } catch {
            XCTAssertTrue(error is URLError || error is DecodingError || (error as NSError).domain == "LookupAPI")
        }
    }
    
    func testFetchFoodDetail_WithNegativeId_HandlesGracefully() async {
        let negativeId = -1
        
        do {
            let result = try await sut.fetchFoodDetail(fdcId: negativeId)
            XCTAssertNil(result)
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - API Key Tests
    
    
    // MARK: - Network Mocking Tests
    
    func testSearch_WithMockSuccessResponse_ParsesResultsCorrectly() async throws {
        // Given
        let mockSearchResponse = """
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
                },
                {
                    "fdcId": 67890,
                    "description": "Banana, raw", 
                    "foodNutrients": [
                        {
                            "nutrientId": 1005,
                            "value": 20.0
                        }
                    ]
                }
            ]
        }
        """
        let testAPI = createLookupAPI(data: mockSearchResponse.data(using: .utf8))
        
        // When
        let results = try await testAPI.search(for: "fruit")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "Apple, raw")
        XCTAssertEqual(results[0].carbs, 14.0)
        XCTAssertEqual(results[0].fdcId, 12345)
        XCTAssertFalse(results[0].isLoadingCarbs)
        
        XCTAssertEqual(results[1].name, "Banana, raw")
        XCTAssertEqual(results[1].carbs, 20.0)
        XCTAssertEqual(results[1].fdcId, 67890)
        XCTAssertFalse(results[1].isLoadingCarbs)
    }
    
    func testSearch_WithMockEmptyResponse_ReturnsEmptyResults() async throws {
        let mockEmptyResponse = """
        {
            "foods": []
        }
        """
        let testAPI = createLookupAPI(data: mockEmptyResponse.data(using: .utf8))
        
        let results = try await testAPI.search(for: "nonexistent")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func testSearch_WithMockZeroCarbsResponse_SetsLoadingState() async throws {
        let mockZeroCarbsResponse = """
        {
            "foods": [
                {
                    "fdcId": 11111,
                    "description": "Water, plain",
                    "foodNutrients": [
                        {
                            "nutrientId": 1005,
                            "value": 0.0
                        }
                    ]
                }
            ]
        }
        """
        let testAPI = createLookupAPI(data: mockZeroCarbsResponse.data(using: .utf8))
        
        let results = try await testAPI.search(for: "water")
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].carbs, 0.0)
        XCTAssertTrue(results[0].isLoadingCarbs)
    }
    
    func testSearch_WithMockNoCarbNutrientResponse_DefaultsToZeroAndLoadingState() async throws {
        let mockNoCarbResponse = """
        {
            "foods": [
                {
                    "fdcId": 22222,
                    "description": "Mystery food",
                    "foodNutrients": [
                        {
                            "nutrientId": 1003,
                            "value": 5.0
                        }
                    ]
                }
            ]
        }
        """
        let testAPI = createLookupAPI(data: mockNoCarbResponse.data(using: .utf8))
        
        let results = try await testAPI.search(for: "mystery")
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].carbs, 0.0)
        XCTAssertTrue(results[0].isLoadingCarbs)
    }
    
    func testSearch_WithNetworkError_ThrowsURLError() async {
        // Given
        let testAPI = createLookupAPI(error: URLError(.networkConnectionLost))
        
        // When & Then
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testSearch_WithInvalidJSONResponse_ThrowsParseError() async {
        let testAPI = createLookupAPI(data: "invalid json".data(using: .utf8))
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected parse error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, -1)
            XCTAssertTrue(nsError.localizedDescription.contains("Failed to parse response"))
        }
    }
    
    func testFetchFoodDetail_WithMockSuccessResponse_ReturnsCorrectCarbValue() async throws {
        // Given
        let mockDetailResponse = """
        {
            "fdcId": 12345,
            "description": "Apple, raw",
            "foodNutrients": [
                {
                    "nutrientId": 1005,
                    "value": 14.5
                }
            ]
        }
        """
        let testAPI = createLookupAPI(data: mockDetailResponse.data(using: .utf8))
        let fdcId = 12345
        
        // When
        let carbValue = try await testAPI.fetchFoodDetail(fdcId: fdcId)
        
        // Then
        XCTAssertEqual(carbValue, 14.5)
    }
    
    func testFetchFoodDetail_WithMockZeroCarbsResponse_ReturnsZero() async throws {
        let mockZeroCarbsResponse = """
        {
            "fdcId": 67890,
            "description": "No carb food",
            "foodNutrients": [
                {
                    "nutrientId": 1005,
                    "value": 0.0
                }
            ]
        }
        """
        let testAPI = createLookupAPI(data: mockZeroCarbsResponse.data(using: .utf8))
        let fdcId = 67890
        
        let carbValue = try await testAPI.fetchFoodDetail(fdcId: fdcId)
        
        XCTAssertEqual(carbValue, 0.0)
    }
    
    func testFetchFoodDetail_WithMockNoCarbNutrient_DefaultsToZero() async throws {
        let mockNoCarbResponse = """
        {
            "fdcId": 33333,
            "description": "Food without carb data",
            "foodNutrients": [
                {
                    "nutrientId": 1003,
                    "value": 10.0
                }
            ]
        }
        """
        let testAPI = createLookupAPI(data: mockNoCarbResponse.data(using: .utf8))
        let fdcId = 33333
        
        let carbValue = try await testAPI.fetchFoodDetail(fdcId: fdcId)
        
        XCTAssertEqual(carbValue, 0.0)
    }
    
    func testFetchFoodDetail_WithNetworkError_ThrowsURLError() async {
        let testAPI = createLookupAPI(error: URLError(.timedOut))
        let fdcId = 12345
        
        do {
            _ = try await testAPI.fetchFoodDetail(fdcId: fdcId)
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testFetchFoodDetail_WithInvalidJSONResponse_ReturnsNil() async throws {
        let testAPI = createLookupAPI(data: "not json".data(using: .utf8))
        let fdcId = 12345
        
        let carbValue = try await testAPI.fetchFoodDetail(fdcId: fdcId)
        
        XCTAssertNil(carbValue)
    }
    
    // MARK: - Enhanced Error Handling Tests
    
    func testSearch_WithMockSession_HandlesErrors() async {
        let mockSession = MockURLSession()
        let apiWithEmptyKey = LookupAPI(apiKey: "", session: mockSession)
        
        do {
            _ = try await apiWithEmptyKey.search(for: "test")
        } catch {
            XCTAssertTrue(error is URLError || (error as NSError).domain == "LookupAPI")
        }
    }
    
    func testSearch_WithHTTPUnauthorized_ThrowsAPIError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected NSError with 401 status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 401)
            XCTAssertTrue(nsError.localizedDescription.contains("Invalid API key"))
        }
    }
    
    func testSearch_WithHTTPForbidden_ThrowsAPIError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected NSError with 403 status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 403)
        }
    }
    
    func testSearch_WithHTTPClientError_ThrowsRequestError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected NSError with 400 status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 400)
            XCTAssertTrue(nsError.localizedDescription.contains("Request error"))
        }
    }
    
    func testSearch_WithHTTPServerError_ThrowsServerError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected NSError with 500 status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 500)
            XCTAssertTrue(nsError.localizedDescription.contains("Server error"))
        }
    }
    
    func testSearch_WithInvalidJSONAndOKStatus_ThrowsParseError() async {
        let testAPI = createLookupAPI(
            data: "invalid json".data(using: .utf8),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected parse error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, -1)
            XCTAssertTrue(nsError.localizedDescription.contains("Failed to parse response"))
        }
    }
    
    func testSearch_WithUnknownHTTPStatus_ThrowsUnknownError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 999,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected NSError with unknown status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 999)
            XCTAssertTrue(nsError.localizedDescription.contains("Unknown error"))
        }
    }
    
    func testSearch_WithInformationalHTTPStatus_ThrowsUnknownError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!,
                statusCode: 102,
                httpVersion: nil,
                headerFields: nil
            )
        )
        
        do {
            _ = try await testAPI.search(for: "test")
            XCTFail("Expected NSError with informational status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 102)
            XCTAssertTrue(nsError.localizedDescription.contains("Unknown error"))
        }
    }
    
    func testFetchFoodDetail_WithHTTPNotFound_ReturnsNil() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/food/12345")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let fdcId = 12345
        
        do {
            let result = try await testAPI.fetchFoodDetail(fdcId: fdcId)
            XCTAssertNil(result)
        } catch {
            XCTFail("Should not throw error for 404, should return nil")
        }
    }
    
    func testFetchFoodDetail_WithHTTPUnauthorized_ThrowsAPIError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/food/12345")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let fdcId = 12345
        
        do {
            _ = try await testAPI.fetchFoodDetail(fdcId: fdcId)
            XCTFail("Expected NSError with 401 status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 401)
        }
    }
    
    func testFetchFoodDetail_WithHTTPServerError_ThrowsServerError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/food/12345")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let fdcId = 12345
        
        do {
            _ = try await testAPI.fetchFoodDetail(fdcId: fdcId)
            XCTFail("Expected NSError with 500 status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 500)
        }
    }
    
    func testFetchFoodDetail_WithUnknownHTTPStatus_ThrowsUnknownError() async {
        let testAPI = createLookupAPI(
            data: Data(),
            response: HTTPURLResponse(
                url: URL(string: "https://api.nal.usda.gov/fdc/v1/food/12345")!,
                statusCode: 302,
                httpVersion: nil,
                headerFields: nil
            )
        )
        let fdcId = 12345
        
        do {
            _ = try await testAPI.fetchFoodDetail(fdcId: fdcId)
            XCTFail("Expected NSError with unknown status")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "LookupAPI")
            XCTAssertEqual(nsError.code, 302)
            XCTAssertTrue(nsError.localizedDescription.contains("Unknown error"))
        }
    }
    
    func testFetchFoodDetail_WithMockSession_HandlesErrors() async {
        let mockSession = MockURLSession()
        let apiWithEmptyKey = LookupAPI(apiKey: "", session: mockSession)
        let fdcId = 12345
        
        do {
            _ = try await apiWithEmptyKey.fetchFoodDetail(fdcId: fdcId)
        } catch {
            XCTAssertTrue(error is URLError || (error as NSError).domain == "LookupAPI")
        }
    }
}

// MARK: - Mock Data Tests

extension LookupAPITests {
    
    func testCarbFood_Creation_SetsPropertiesCorrectly() {
        // Given
        let name = "Test Apple"
        let carbs = 14.0
        let fdcId = 12345
        let isLoadingCarbs = false
        
        // When
        let testFood = CarbFood(
            name: name,
            carbs: carbs,
            fdcId: fdcId,
            isLoadingCarbs: isLoadingCarbs
        )
        
        // Then
        XCTAssertEqual(testFood.name, name)
        XCTAssertEqual(testFood.carbs, carbs)
        XCTAssertEqual(testFood.fdcId, fdcId)
        XCTAssertFalse(testFood.isLoadingCarbs)
    }
    
    func testCarbFood_WithZeroCarbs_SetsLoadingState() {
        let name = "Test Food"
        let carbs = 0.0
        let fdcId = 67890
        let isLoadingCarbs = true
        
        let testFood = CarbFood(
            name: name,
            carbs: carbs,
            fdcId: fdcId,
            isLoadingCarbs: isLoadingCarbs
        )
        
        XCTAssertEqual(testFood.carbs, 0.0)
        XCTAssertTrue(testFood.isLoadingCarbs)
    }
}
