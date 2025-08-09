//
//  FoodLookup.swift
//  CarbClarity
//
//  Created by René Fouquet on 16.06.24.
//

import Foundation

struct FoodLookup: Codable {
    let foods: [Food]
}

struct CarbFood: Hashable {
    let name: String
    let carbs: Double
    let fdcId: Int
    let isLoadingCarbs: Bool
    
    init(name: String, carbs: Double, fdcId: Int, isLoadingCarbs: Bool = false) {
        self.name = name
        self.carbs = carbs
        self.fdcId = fdcId
        self.isLoadingCarbs = isLoadingCarbs
    }
}

struct Food: Codable {
    let fdcID: Int
    let description: String
    let foodNutrients: [FoodNutrient]

    enum CodingKeys: String, CodingKey {
        case fdcID = "fdcId"
        case description, foodNutrients
    }
    
    func carbs() -> Double {
        foodNutrients.first(where: { $0.nutrientID == 1005 })?.value ?? 0.0
    }
}

struct FoodNutrient: Codable {
    let nutrientID: Int
    let value: Double

    enum CodingKeys: String, CodingKey {
        case nutrientID = "nutrientId"
        case value
    }
}