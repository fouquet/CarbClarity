//
//  MainViewModel.swift
//  CarbClarity
//
//  Created by René Fouquet on 13.07.25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

@MainActor
class MainViewModel: ObservableObject {
    @Published var inputValue: Double?
    @Published var showingSettings = false
    @Published var showingLookup = false
    
    private var modelContext: ModelContext?
    private var allEntries = [CarbEntry]()
    
    var carbLimit: Double = 20.0
    var cautionLimit: Double = 15.0
    var warnLimitEnabled: Bool = true
    var cautionLimitEnabled: Bool = true
    var lookupEnabled: Bool = false
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func updateDependencies(modelContext: ModelContext, allEntries: [CarbEntry], carbLimit: Double, cautionLimit: Double, warnLimitEnabled: Bool, cautionLimitEnabled: Bool, lookupEnabled: Bool) {
        self.modelContext = modelContext
        self.allEntries = allEntries
        self.carbLimit = carbLimit
        self.cautionLimit = cautionLimit
        self.warnLimitEnabled = warnLimitEnabled
        self.cautionLimitEnabled = cautionLimitEnabled
        self.lookupEnabled = lookupEnabled
        
        objectWillChange.send()
    }
    
    
    var carbEntriesByDay: [CarbEntryByDay] {
        var returnArray = [CarbEntryByDay]()
        var itemsToSort = Array(allEntries)
        
        itemsToSort.forEach { entry in
            if let dayToUse = returnArray.first(where: { Calendar.current.isDate($0.day, inSameDayAs: entry.timestamp) }) {
                dayToUse.entries.append(entry)
            } else {
                returnArray.append(CarbEntryByDay(day: entry.timestamp, entries: [entry]))
            }
            itemsToSort.removeAll(where: { $0 == entry })
        }
        
        let sortedArray = returnArray.sorted(by: { $0.day.compare($1.day) == .orderedDescending })
        
        for dayGroup in sortedArray {
            dayGroup.entries.sort(by: { $0.timestamp > $1.timestamp })
        }
        
        return sortedArray
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
    
    
    func showSettings() {
        showingSettings = true
    }
    
    
    func showLookup() {
        showingLookup = true
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
        
        // Force save to ensure data is persisted before widget refresh
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
        
        WidgetUpdateManager.requestWidgetUpdate()
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
        
        // Force save to ensure data is persisted before widget refresh
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
        
        WidgetUpdateManager.requestWidgetUpdate()
        return true
    }
    
    func deleteItems(items: [CarbEntry], offsets: IndexSet) -> Bool {
        guard let modelContext = modelContext else { return false }
        
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
        
        // Force save to ensure data is persisted before widget refresh
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
        
        WidgetUpdateManager.requestWidgetUpdate()
        return true
    }
    
    func dayTotal(for day: CarbEntryByDay) -> String {
        let total = day.total()
        var warning = ""
        
        if warnLimitEnabled && total > carbLimit {
            warning = " ⚠️"
        }
        
        return "Total: " + total.carbString() + warning
    }
    
    // MARK: - Testing Support
    
    func addDummyData() {
        guard let modelContext = modelContext else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy HH:mm"

        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "14.07.2025 8:13")!, value: 1.0.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "14.07.2025 12:30")!, value: 9.1.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "14.07.2025 18:08")!, value: 6.0.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "15.07.2025 7:53")!, value: 0.7.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "15.07.2025 13:22")!, value: 7.5.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "15.07.2025 20:21")!, value: 12.0.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "15.07.2025 10:27")!, value: 4.3.roundedForCarbs()))
        modelContext.insert(CarbEntry(timestamp: dateFormatter.date(from: "16.07.2025 18:19")!, value: 6.5.roundedForCarbs()))
    }
}
