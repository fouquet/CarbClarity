//
//  USDAAPIMock.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 06.08.25.
//

import Foundation

/// Mock USDA API implementation for UI tests
final class USDAAPIMock: LookupAPIProtocol, @unchecked Sendable {
    let apiKey: String = "mock-ui-test-key"
    
    // MARK: - Mock Data
    
    private let mockFoods = [
        // Apple variants
        CarbFood(name: "Apples, raw, with skin", carbs: 14.0, fdcId: 171688),
        CarbFood(name: "Apple juice, canned or bottled, unsweetened", carbs: 11.3, fdcId: 174292),
        CarbFood(name: "Apple pie, commercially prepared", carbs: 32.4, fdcId: 174987),
        
        // Banana variants
        CarbFood(name: "Bananas, raw", carbs: 22.8, fdcId: 173944),
        CarbFood(name: "Banana bread, prepared from recipe", carbs: 47.6, fdcId: 172679),
        
        // Bread variants
        CarbFood(name: "Bread, white, commercially prepared", carbs: 49.4, fdcId: 172687),
        CarbFood(name: "Bread, whole-wheat, commercially prepared", carbs: 43.3, fdcId: 172691),
        CarbFood(name: "Breadcrumbs, dry, grated, seasoned", carbs: 72.0, fdcId: 172692),
        
        // Rice variants
        CarbFood(name: "Rice, white, long-grain, regular, cooked", carbs: 28.2, fdcId: 169704),
        CarbFood(name: "Rice, brown, long-grain, cooked", carbs: 23.0, fdcId: 168878),
        
        // Pasta variants
        CarbFood(name: "Pasta, cooked, enriched, without added salt", carbs: 31.0, fdcId: 168874),
        CarbFood(name: "Spaghetti, whole-wheat, cooked", carbs: 26.0, fdcId: 168876),
        
        // Potato variants
        CarbFood(name: "Potatoes, baked, flesh and skin", carbs: 21.2, fdcId: 170093),
        CarbFood(name: "Potatoes, french fried, frozen, prepared", carbs: 28.7, fdcId: 170426),
        
        // Cereal variants
        CarbFood(name: "Cereals ready-to-eat, corn flakes", carbs: 84.0, fdcId: 173904),
        CarbFood(name: "Oatmeal, cooked with water", carbs: 12.0, fdcId: 172873),
        
        // High carb foods for testing limits
        CarbFood(name: "Sugar, granulated", carbs: 99.8, fdcId: 169655),
        CarbFood(name: "Honey", carbs: 82.4, fdcId: 169640),
        
        // Zero/low carb foods
        CarbFood(name: "Chicken, broilers or fryers, breast, meat only, cooked", carbs: 0.0, fdcId: 171477),
        CarbFood(name: "Cheese, cheddar", carbs: 1.3, fdcId: 171265),
        CarbFood(name: "Spinach, raw", carbs: 3.6, fdcId: 168462),
        
        // Foods that need detail loading (simulate isLoadingCarbs = true)
        CarbFood(name: "Pizza, cheese topping, regular crust", carbs: 0.0, fdcId: 999001, isLoadingCarbs: true),
        CarbFood(name: "Cookies, chocolate chip, commercially prepared", carbs: 0.0, fdcId: 999002, isLoadingCarbs: true)
    ]
    
    private let mockFoodDetails: [Int: Double] = [
        999001: 32.4, // Pizza - detailed carb value
        999002: 68.2  // Cookies - detailed carb value
    ]
    
    // MARK: - Search Error Scenarios
    
    enum MockScenario {
        case normal
        case networkError
        case invalidAPIKey
        case serverError
        case emptyResults
        case slowResponse
    }
    
    var currentScenario: MockScenario = .normal
    
    // MARK: - LookupAPIProtocol Implementation
    
    func search(for string: String) async throws -> [CarbFood] {
        print("🧪 USDAAPIMock.search called for: '\(string)'")
        
        // Simulate network delay
        if currentScenario == .slowResponse {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        } else {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds for faster UI tests
        }
        
        // Handle error scenarios
        switch currentScenario {
        case .networkError:
            throw URLError(.networkConnectionLost)
        case .invalidAPIKey:
            throw NSError(domain: "LookupAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"])
        case .serverError:
            throw NSError(domain: "LookupAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        case .emptyResults:
            return []
        case .normal, .slowResponse:
            break
        }
        
        // Handle empty search
        let trimmedQuery = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmedQuery.isEmpty {
            return []
        }
        
        // Filter foods based on search query
        let results = mockFoods.filter { food in
            food.name.lowercased().contains(trimmedQuery)
        }
        
        print("🧪 USDAAPIMock found \(results.count) results for '\(string)'")
        
        // Return up to 25 results (like real USDA API)
        return Array(results.prefix(25))
    }
    
    func fetchFoodDetail(fdcId: Int) async throws -> Double? {
        print("🧪 USDAAPIMock.fetchFoodDetail called for fdcId: \(fdcId)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Handle error scenarios
        switch currentScenario {
        case .networkError:
            throw URLError(.networkConnectionLost)
        case .invalidAPIKey:
            throw NSError(domain: "LookupAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"])
        case .serverError:
            throw NSError(domain: "LookupAPI", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        case .normal, .emptyResults, .slowResponse:
            break
        }
        
        // Return mock detail data
        return mockFoodDetails[fdcId]
    }
    
    // MARK: - Test Helper Methods
    
    /// Configure the mock for specific test scenarios
    func setScenario(_ scenario: MockScenario) {
        currentScenario = scenario
    }
    
    /// Reset to normal operation
    func reset() {
        currentScenario = .normal
    }
}

// MARK: - Mock Data Helpers

extension USDAAPIMock {
    
    /// Get common search terms for testing
    static var commonSearchTerms: [String] {
        return [
            "apple",
            "banana", 
            "bread",
            "rice",
            "pasta",
            "potato",
            "chicken",
            "cheese",
            "sugar",
            "pizza",
            "cookies"
        ]
    }
    
    /// Get foods with zero carbs for testing
    static var zeroCarbFoods: [CarbFood] {
        return [
            CarbFood(name: "Chicken, broilers or fryers, breast, meat only, cooked", carbs: 0.0, fdcId: 171477),
            CarbFood(name: "Water, tap", carbs: 0.0, fdcId: 171881)
        ]
    }
    
    /// Get high carb foods for testing limits
    static var highCarbFoods: [CarbFood] {
        return [
            CarbFood(name: "Sugar, granulated", carbs: 99.8, fdcId: 169655),
            CarbFood(name: "Cereals ready-to-eat, corn flakes", carbs: 84.0, fdcId: 173904),
            CarbFood(name: "Honey", carbs: 82.4, fdcId: 169640)
        ]
    }
}
