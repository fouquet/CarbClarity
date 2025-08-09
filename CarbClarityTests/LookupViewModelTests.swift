//
//  LookupViewModelTests.swift
//  CarbClarity
//
//  Created by René Fouquet on 12.07.25.
//

import XCTest
import SwiftData
@testable import CarbClarity

@MainActor
final class LookupViewModelTests: XCTestCase, @unchecked Sendable {
    
    var sut: LookupViewModel!
    var mockAPI: MockLookupAPI!
    var modelContext: ModelContext!
    let testAPIKey = "test-api-key"
    
    override func setUpWithError() throws {
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        MainActor.assumeIsolated {
            modelContext = ModelContext(container)
            mockAPI = MockLookupAPI()
            sut = LookupViewModel(apiKey: testAPIKey, modelContext: modelContext, lookupAPI: mockAPI)
        }
    }

    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            sut = nil
            mockAPI = nil
            modelContext = nil
        }
    }

    // MARK: - Initialization Tests
    
    func testInit_WithValidParameters_InitializesCorrectly() {
        // Given & When
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertNil(sut.selectedFood)
        XCTAssertNil(sut.amountEaten)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertEqual(sut.calculatedCarbs, 0)
        XCTAssertFalse(sut.canAddEntry)
    }
    
    // MARK: - Calculated Carbs Tests
    
    func testCalculatedCarbs_WithValidFoodAndAmount_ReturnsCorrectValue() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = 200.0
        
        let result = sut.calculatedCarbs
        
        XCTAssertEqual(result, 28.0, accuracy: 0.01)
    }
    
    func testCalculatedCarbs_WithZeroCarbFood_ReturnsZero() {
        let testFood = CarbFood(name: "Water", carbs: 0.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = 100.0
        
        let result = sut.calculatedCarbs
        
        XCTAssertEqual(result, 0.0)
    }
    
    func testCalculatedCarbs_WithNoFood_ReturnsZero() {
        sut.selectedFood = nil
        sut.amountEaten = 100.0
        
        let result = sut.calculatedCarbs
        
        XCTAssertEqual(result, 0.0)
    }
    
    func testCalculatedCarbs_WithNoAmount_ReturnsZero() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = nil
        
        let result = sut.calculatedCarbs
        
        XCTAssertEqual(result, 0.0)
    }
    
    // MARK: - Can Add Entry Tests
    
    func testCanAddEntry_WithValidFoodAndAmount_ReturnsTrue() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = 100.0
        
        let result = sut.canAddEntry
        
        XCTAssertTrue(result)
    }
    
    func testCanAddEntry_WithoutFood_ReturnsFalse() {
        sut.selectedFood = nil
        sut.amountEaten = 100.0
        
        let result = sut.canAddEntry
        
        XCTAssertFalse(result)
    }
    
    func testCanAddEntry_WithoutAmount_ReturnsFalse() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = nil
        
        let result = sut.canAddEntry
        
        XCTAssertFalse(result)
    }
    
    func testCanAddEntry_WithZeroAmount_ReturnsFalse() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = 0.0
        
        let result = sut.canAddEntry
        
        XCTAssertFalse(result)
    }
    
    // MARK: - Search Tests
    
    func testSearch_WithValidQuery_ReturnsResults() async {
        let mockFoods = [
            CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345),
            CarbFood(name: "Banana", carbs: 20.0, fdcId: 67890)
        ]
        mockAPI.mockSearchResults = mockFoods
        
        await sut.search(for: "fruit")
        
        XCTAssertEqual(sut.foods.count, 2)
        XCTAssertEqual(sut.foods[0].name, "Apple")
        XCTAssertEqual(sut.foods[1].name, "Banana")
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.selectedFood)
    }
    
    func testSearch_WithEmptyQuery_DoesNotSearch() async {
        let emptyQuery = ""
        
        await sut.search(for: emptyQuery)
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.selectedFood)
    }
    
    func testSearch_WithWhitespaceQuery_DoesNotSearch() async {
        let whitespaceQuery = "   "
        
        await sut.search(for: whitespaceQuery)
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.selectedFood)
    }
    
    func testSearch_WithNoResults_UpdatesStateCorrectly() async {
        mockAPI.mockSearchResults = [CarbFood]()
        
        await sut.search(for: "nonexistent")
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSearch_WithError_UpdatesStateCorrectly() async {
        mockAPI.shouldThrowError = true
        
        await sut.search(for: "test")
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSearch_WithExistingSelection_ClearsSelection() async {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        mockAPI.mockSearchResults = [CarbFood]()
        
        await sut.search(for: "test")
        
        XCTAssertNil(sut.selectedFood)
    }
    
    // MARK: - Load Carbs for Food Tests
    
    func testLoadCarbsForFood_WithSuccessfulResponse_UpdatesFoodCarbs() async {
        let testFood = CarbFood(name: "Apple", carbs: 0.0, fdcId: 12345, isLoadingCarbs: true)
        sut.foods = [testFood]
        mockAPI.mockCarbValue = 14.0
        
        await sut.loadCarbsForFood(testFood)
        
        XCTAssertEqual(sut.foods.count, 1)
        XCTAssertEqual(sut.foods[0].carbs, 14.0)
        XCTAssertFalse(sut.foods[0].isLoadingCarbs)
    }
    
    func testLoadCarbsForFood_WithError_ClearsLoadingState() async {
        let testFood = CarbFood(name: "Apple", carbs: 0.0, fdcId: 12345, isLoadingCarbs: true)
        sut.foods = [testFood]
        mockAPI.shouldThrowError = true
        
        await sut.loadCarbsForFood(testFood)
        
        XCTAssertEqual(sut.foods.count, 1)
        XCTAssertEqual(sut.foods[0].carbs, 0.0)
        XCTAssertFalse(sut.foods[0].isLoadingCarbs)
    }
    
    func testLoadCarbsForFood_WhenNotLoading_DoesNotCallAPI() async {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345, isLoadingCarbs: false)
        sut.foods = [testFood]
        
        await sut.loadCarbsForFood(testFood)
        
        XCTAssertEqual(sut.foods[0].carbs, 14.0)
        XCTAssertFalse(mockAPI.fetchFoodDetailCalled)
    }
    
    // MARK: - Select Food Tests
    
    func testSelectFood_WithValidFood_UpdatesSelection() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        
        sut.selectFood(testFood)
        
        XCTAssertEqual(sut.selectedFood?.fdcId, testFood.fdcId)
        XCTAssertEqual(sut.selectedFood?.name, testFood.name)
    }
    
    // MARK: - Add Carb Entry Tests
    
    func testAddCarbEntry_WithValidData_AddsEntryAndClearsSelection() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = 200.0
        
        let result = sut.addCarbEntry()
        
        XCTAssertTrue(result)
        XCTAssertNil(sut.selectedFood)
        XCTAssertNil(sut.amountEaten)
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].value, 28.0, accuracy: 0.01)
    }
    
    func testAddCarbEntry_WithoutFood_ReturnsFalse() {
        sut.selectedFood = nil
        sut.amountEaten = 100.0
        
        let result = sut.addCarbEntry()
        
        XCTAssertFalse(result)
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0)
    }
    
    func testAddCarbEntry_WithoutAmount_ReturnsFalse() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.selectedFood = testFood
        sut.amountEaten = nil
        
        let result = sut.addCarbEntry()
        
        XCTAssertFalse(result)
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0)
    }
    
    func testAddCarbEntry_WithoutModelContext_ReturnsFalse() {
        let sutWithoutContext = LookupViewModel(apiKey: testAPIKey, modelContext: nil, lookupAPI: mockAPI)
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sutWithoutContext.selectedFood = testFood
        sutWithoutContext.amountEaten = 100.0
        
        let result = sutWithoutContext.addCarbEntry()
        
        XCTAssertFalse(result)
    }
    
    // MARK: - Reset Tests
    
    func testReset_WithExistingData_ClearsAllState() {
        let testFood = CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)
        sut.foods = [testFood]
        sut.selectedFood = testFood
        sut.amountEaten = 100.0
        sut.isLoading = true
        sut.hasSearched = true
        sut.currentError = .networkUnavailable
        sut.showingError = true
        
        sut.reset()
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertNil(sut.selectedFood)
        XCTAssertNil(sut.amountEaten)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
    }
    
    // MARK: - Error Handling Tests
    
    func testSearch_WithEmptyAPIKey_SetsNoAPIKeyError() async {
        sut.updateDependencies(apiKey: "", modelContext: modelContext)
        
        await sut.search(for: "apple")
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
        XCTAssertEqual(sut.currentError, .noAPIKey)
    }
    
    func testSearch_WithWhitespaceAPIKey_SetsNoAPIKeyError() async {
        sut.updateDependencies(apiKey: "   ", modelContext: modelContext)
        
        await sut.search(for: "apple")
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertFalse(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
        XCTAssertEqual(sut.currentError, .noAPIKey)
    }
    
    func testSearch_WithAPIError_SetsErrorState() async {
        mockAPI.shouldThrowError = true
        
        await sut.search(for: "test")
        
        XCTAssertTrue(sut.foods.isEmpty)
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }
    
    func testSearch_AfterError_ClearsErrorOnSuccess() async {
        sut.currentError = .networkUnavailable
        sut.showingError = true
        mockAPI.mockSearchResults = [CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)]
        
        await sut.search(for: "apple")
        
        XCTAssertEqual(sut.foods.count, 1)
        XCTAssertTrue(sut.hasSearched)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
    }
    
    func testRetryLastSearch_WithPreviousSearch_RepeatsSearch() async {
        mockAPI.mockSearchResults = [CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345)]
        await sut.search(for: "apple")
        XCTAssertEqual(sut.foods.count, 1)
        
        sut.foods = [CarbFood]()
        mockAPI.mockSearchResults = [
            CarbFood(name: "Apple", carbs: 14.0, fdcId: 12345),
            CarbFood(name: "Apple Juice", carbs: 20.0, fdcId: 67890)
        ]
        
        await sut.retryLastSearch()
        
        XCTAssertEqual(sut.foods.count, 2)
        XCTAssertTrue(mockAPI.searchCalled)
    }
    
    func testRetryLastSearch_WithoutPreviousSearch_DoesNotCallAPI() async {
        await sut.retryLastSearch()
        
        XCTAssertFalse(mockAPI.searchCalled)
        XCTAssertTrue(sut.foods.isEmpty)
    }
    
    func testDismissError_WithActiveError_ClearsErrorState() {
        sut.currentError = .networkUnavailable
        sut.showingError = true
        
        sut.dismissError()
        
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
    }
    
    func testUpdateDependencies_WithActiveError_ClearsErrorState() {
        sut.currentError = .networkUnavailable
        sut.showingError = true
        
        sut.updateDependencies(apiKey: "new-key", modelContext: modelContext)
        
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
    }
    
    func testSearch_WithEmptyQueryAndActiveError_ClearsError() async {
        sut.currentError = .networkUnavailable
        sut.showingError = true
        
        await sut.search(for: "")
        
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
    }
    
    func testSearch_WithWhitespaceQueryAndActiveError_ClearsError() async {
        sut.currentError = .networkUnavailable
        sut.showingError = true
        
        await sut.search(for: "   ")
        
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.showingError)
    }
}

// MARK: - Mock LookupAPI

final class MockLookupAPI: LookupAPIProtocol, @unchecked Sendable {
    let apiKey: String = "mock-key"
    var mockSearchResults = [CarbFood]()
    var mockCarbValue: Double?
    var shouldThrowError = false
    var searchCalled = false
    var fetchFoodDetailCalled = false
    
    init() {}
    
    func search(for string: String) async throws -> [CarbFood] {
        searchCalled = true
        
        if shouldThrowError {
            throw URLError(.networkConnectionLost)
        }
        
        return mockSearchResults
    }
    
    func fetchFoodDetail(fdcId: Int) async throws -> Double? {
        fetchFoodDetailCalled = true
        
        if shouldThrowError {
            throw URLError(.networkConnectionLost)
        }
        
        return mockCarbValue
    }
}
