//
//  CarbEntry.swift
//  CarbClarity
//
//  Created by René Fouquet on 07.06.24.
//

import Foundation
import SwiftData

@Model
final class CarbEntry {
    var timestamp: Date = Date()
    var value: Double = 0.0
    
    init(timestamp: Date = Date(), value: Double = 0.0) {
        self.timestamp = timestamp
        self.value = value
    }
}
