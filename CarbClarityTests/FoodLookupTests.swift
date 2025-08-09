//
//  FoodLookupTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
@testable import CarbClarity

final class FoodLookupTests: XCTestCase {
    
    // MARK: - CarbFood Tests
    
    func testCarbFood_WithValidData_InitializesCorrectly() {
        // Given
        let carbFood = CarbFood(name: "Apple", carbs: 25.3, fdcId: 12345, isLoadingCarbs: true)
        
        // When
        
        // Then
        XCTAssertEqual(carbFood.name, "Apple", "Name should match initialization value")
        XCTAssertEqual(carbFood.carbs, 25.3, accuracy: 0.001, "Carbs should match initialization value")
        XCTAssertEqual(carbFood.fdcId, 12345, "FDC ID should match initialization value")
        XCTAssertTrue(carbFood.isLoadingCarbs, "Loading state should match initialization value")
    }
    
    func testCarbFood_WithDefaultLoadingState_SetsLoadingToFalse() {
        // Given & When
        let carbFood = CarbFood(name: "Banana", carbs: 20.1, fdcId: 67890)
        
        // Then
        XCTAssertFalse(carbFood.isLoadingCarbs, "Default loading state should be false")
        XCTAssertEqual(carbFood.name, "Banana", "Name should be preserved with default loading state")
    }
    
    func testCarbFood_CanBeUsedInCollections() {
        // Given
        let food1 = CarbFood(name: "Apple", carbs: 25.0, fdcId: 123)
        let food2 = CarbFood(name: "Banana", carbs: 30.0, fdcId: 456)
        let food3 = CarbFood(name: "Apple", carbs: 25.0, fdcId: 123) // Duplicate
        
        // When
        let foods = Set([food1, food2, food3])
        
        // Then
        XCTAssertEqual(foods.count, 2, "Set should deduplicate identical CarbFood instances")
        XCTAssertTrue(foods.contains(food1), "Set should contain the apple")
        XCTAssertTrue(foods.contains(food2), "Set should contain the banana")
    }
    
    // MARK: - Food.carbs() Tests
    
    func testFoodCarbs_WithCarbNutrient_ReturnsCorrectValue() {
        // Given
        let carbNutrient = FoodNutrient(nutrientID: 1005, value: 25.3)
        let otherNutrient = FoodNutrient(nutrientID: 1003, value: 10.5)
        let food = Food(fdcID: 123, description: "Apple", foodNutrients: [carbNutrient, otherNutrient])
        
        // When
        let carbValue = food.carbs()
        
        // Then
        XCTAssertEqual(carbValue, 25.3, accuracy: 0.001, "Should return carb value from nutrient with ID 1005")
    }
    
    func testFoodCarbs_WithoutCarbNutrient_ReturnsZero() {
        // Given
        let proteinNutrient = FoodNutrient(nutrientID: 1003, value: 10.5)
        let fatNutrient = FoodNutrient(nutrientID: 1004, value: 5.2)
        let food = Food(fdcID: 456, description: "Some Food", foodNutrients: [proteinNutrient, fatNutrient])
        
        // When
        let carbValue = food.carbs()
        
        // Then
        XCTAssertEqual(carbValue, 0.0, "Should return 0 when no carb nutrient found")
    }
    
    func testFoodCarbs_WithEmptyNutrients_ReturnsZero() {
        // Given
        let food = Food(fdcID: 789, description: "Empty Food", foodNutrients: [])
        
        // When
        let carbValue = food.carbs()
        
        // Then
        XCTAssertEqual(carbValue, 0.0, "Should return 0 for empty nutrients array")
    }
    
    func testFoodCarbs_WithMultipleCarbNutrients_ReturnsFirst() {
        // Given
        let carbNutrient1 = FoodNutrient(nutrientID: 1005, value: 15.0)
        let carbNutrient2 = FoodNutrient(nutrientID: 1005, value: 20.0)
        let food = Food(fdcID: 999, description: "Duplicate Carbs", foodNutrients: [carbNutrient1, carbNutrient2])
        
        // When
        let carbValue = food.carbs()
        
        // Then
        XCTAssertEqual(carbValue, 15.0, "Should return the first matching carb nutrient value")
    }
}
