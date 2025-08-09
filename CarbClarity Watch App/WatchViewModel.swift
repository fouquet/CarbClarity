//
//  WatchViewModel.swift
//  CarbClarityWatch
//
//  Created by René Fouquet on 18.07.25.
//

import Foundation
import SwiftUI
import SwiftData
import ClockKit
import WidgetKit

@MainActor
class WatchViewModel: ObservableObject {
    @Published var inputValue: Double?
    @Published var showingAddView = false
    
    private var modelContext: ModelContext?
    private var allEntries = [CarbEntry]()
    
    var carbLimit: Double = 20.0
    var cautionLimit: Double = 15.0
    var warnLimitEnabled: Bool = true
    var cautionLimitEnabled: Bool = true
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func updateDependencies(modelContext: ModelContext, allEntries: [CarbEntry], carbLimit: Double, cautionLimit: Double, warnLimitEnabled: Bool, cautionLimitEnabled: Bool) {
        self.modelContext = modelContext
        self.allEntries = allEntries
        self.carbLimit = carbLimit
        self.cautionLimit = cautionLimit
        self.warnLimitEnabled = warnLimitEnabled
        self.cautionLimitEnabled = cautionLimitEnabled
        
        objectWillChange.send()
    }
    
    
    var totalCarbsForToday: Double {
        var value: Double = 0.0
        allEntries.forEach { entry in
            if Calendar.current.isDateInToday(entry.timestamp) {
                value += entry.value
            }
        }
        return value
    }
    
    var totalCarbsForTodayString: String {
        return totalCarbsForToday.carbString()
    }
    
    var isExceedingCarbLimit: Bool {
        return warnLimitEnabled && totalCarbsForToday > carbLimit
    }
    
    var isExceedingCautionLimit: Bool {
        return cautionLimitEnabled && totalCarbsForToday > cautionLimit
    }
    
    var canAddEntry: Bool {
        guard let input = inputValue else { return false }
        return input > 0.0
    }
    
    enum CarbDisplayColor {
        case normal
        case caution
        case warning
        
        var color: Color {
            switch self {
            case .normal:
                return .primary
            case .caution:
                return .yellow
            case .warning:
                return .red
            }
        }
    }
    
    var todaysCarbDisplayColor: CarbDisplayColor {
        if isExceedingCarbLimit {
            return .warning
        } else if isExceedingCautionLimit {
            return .caution
        } else {
            return .normal
        }
    }
    
    
    func showAddView() {
        showingAddView = true
    }
    
    func hideAddView() {
        showingAddView = false
    }
    
    func addItem() -> Bool {
        guard let modelContext = modelContext,
              let input = inputValue,
              input > 0.0 else {
            return false
        }
        
        let roundedValue = input.roundedForCarbs()
        
        guard roundedValue > 0.0 else {
            return false
        }
        
        let newItem = CarbEntry(timestamp: Date(), value: roundedValue)
        modelContext.insert(newItem)
        
        inputValue = nil
        
        do {
            try modelContext.save()
            
            refreshComplications()
        } catch {
            print("Error saving context: \(error)")
        }
        
        return true
    }
    
    
    func quickAdd(_ value: Double) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        let roundedValue = value.roundedForCarbs()
        
        guard roundedValue > 0.0 else {
            return false
        }
        
        let newItem = CarbEntry(timestamp: Date(), value: roundedValue)
        modelContext.insert(newItem)
        
        do {
            try modelContext.save()
            
            refreshComplications()
        } catch {
            print("Error saving context: \(error)")
        }
        
        return true
    }
    
    
    private func refreshComplications() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        for complication in complicationServer.activeComplications ?? [] {
            complicationServer.reloadTimeline(for: complication)
        }
        
        WidgetUpdateManager.requestWidgetUpdate()
    }
}
