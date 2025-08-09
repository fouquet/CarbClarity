//
//  CarbEntryByDay.swift
//  CarbClarity
//
//  Created by René Fouquet on 11.07.25.
//

import Foundation

final class CarbEntryByDay {
    var day: Date
    var entries: [CarbEntry]
    
    init(day: Date, entries: [CarbEntry]) {
        self.day = day
        self.entries = entries
    }
    
    func total() -> Double {
        var value: Double = 0.0
        entries.forEach { entry in
            value += entry.value
        }
        
        return value
    }
}
