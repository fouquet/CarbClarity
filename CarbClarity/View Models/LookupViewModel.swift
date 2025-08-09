//
//  LookupViewModel.swift
//  CarbClarity
//
//  Created by René Fouquet on 12.07.25.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
class LookupViewModel: ObservableObject {
    @Published var foods = [CarbFood]()
    @Published var selectedFood: CarbFood?
    @Published var amountEaten: Double?
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var currentError: LookupError?
    @Published var showingError = false
    
    private var lookupAPI: LookupAPIProtocol
    private var modelContext: ModelContext?
    private var lastSearchTerm: String = ""
    
    var calculatedCarbs: Double {
        guard let selectedFood = selectedFood,
              let amountEaten = amountEaten,
              selectedFood.carbs > 0 else { return 0 }
        return (selectedFood.carbs / 100.0) * amountEaten
    }
    
    var canAddEntry: Bool {
        guard let amountEaten = amountEaten else { return false }
        return selectedFood != nil && amountEaten > 0
    }
    
    init(apiKey: String, modelContext: ModelContext? = nil, lookupAPI: LookupAPIProtocol? = nil) {
        self.modelContext = modelContext
        self.lookupAPI = lookupAPI ?? LookupAPI(apiKey: apiKey)
    }
    
    func search(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            hasSearched = false
            foods = []
            selectedFood = nil
            clearError()
            return
        }
        
        if lookupAPI.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            handleError(NSError(
                domain: "LookupAPI",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No API key"]
            ))
            return
        }
        
        lastSearchTerm = searchText
        isLoading = true
        selectedFood = nil
        clearError()
        
        do {
            let results = try await lookupAPI.search(for: searchText)
            foods = results
            hasSearched = true
        } catch {
            foods = []
            hasSearched = true
            handleError(error)
        }
        
        isLoading = false
    }
    
    func loadCarbsForFood(_ food: CarbFood) async {
        guard food.isLoadingCarbs else { return }
        
        do {
            if let carbValue = try await lookupAPI.fetchFoodDetail(fdcId: food.fdcId) {
                if let index = foods.firstIndex(where: { $0.fdcId == food.fdcId }) {
                    foods[index] = CarbFood(
                        name: food.name,
                        carbs: carbValue,
                        fdcId: food.fdcId,
                        isLoadingCarbs: false
                    )
                }
            }
        } catch {
            // For detail fetch errors, silently fail and show 0 carbs
            if let index = foods.firstIndex(where: { $0.fdcId == food.fdcId }) {
                foods[index] = CarbFood(
                    name: food.name,
                    carbs: 0,
                    fdcId: food.fdcId,
                    isLoadingCarbs: false
                )
            }
        }
    }
    
    func selectFood(_ food: CarbFood) {
        selectedFood = food
    }
    
    func addCarbEntry() -> Bool {
        guard canAddEntry,
              let modelContext = modelContext else { return false }
        
        let newEntry = CarbEntry(timestamp: Date(), value: calculatedCarbs)
        modelContext.insert(newEntry)
        
        WidgetUpdateManager.requestWidgetUpdate()
        
        amountEaten = nil
        selectedFood = nil
        
        return true
    }
    
    func reset() {
        foods = []
        selectedFood = nil
        amountEaten = nil
        isLoading = false
        hasSearched = false
        clearError()
    }
    
    func updateDependencies(apiKey: String, modelContext: ModelContext?, lookupAPI: LookupAPIProtocol? = nil) {
        // If a specific API is provided, use it (for testing)
        if let providedAPI = lookupAPI {
            self.lookupAPI = providedAPI
        } else {
            // Always create a new API instance with the provided key
            if let currentAPI = self.lookupAPI as? LookupAPI {
                self.lookupAPI = LookupAPI(apiKey: apiKey, session: currentAPI.session)
            } else {
                self.lookupAPI = LookupAPI(apiKey: apiKey)
            }
        }
        self.modelContext = modelContext
        
        clearError()
    }
    
    func retryLastSearch() async {
        guard !lastSearchTerm.isEmpty else { return }
        await search(for: lastSearchTerm)
    }
    
    private func handleError(_ error: Error) {
        let lookupError = LookupError.from(error)
        currentError = lookupError
        showingError = true
    }
    
    private func clearError() {
        currentError = nil
        showingError = false
    }
    
    func dismissError() {
        clearError()
    }
}
