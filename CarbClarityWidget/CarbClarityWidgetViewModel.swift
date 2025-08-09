//
//  CarbClarityWidgetViewModel.swift
//  CarbClarityWidget
//
//  Created by René Fouquet on 17.07.25.
//

import Foundation
import SwiftUI

@Observable
class CarbClarityWidgetViewModel {
    
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
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    func formatGaugeValue(_ value: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    func getCarbDisplayColor(
        total: Double,
        carbLimit: Double,
        cautionLimit: Double,
        warnLimitEnabled: Bool,
        cautionLimitEnabled: Bool
    ) -> CarbDisplayColor {
        if warnLimitEnabled && total > carbLimit {
            return .warning
        } else if cautionLimitEnabled && total > cautionLimit {
            return .caution
        } else {
            return .normal
        }
    }
    
    func shouldShowWarningIcon(_ displayColor: CarbDisplayColor) -> Bool {
        return displayColor == .warning
    }
    
    func getWarningMessage() -> String {
        return "⚠️\nYou are exceeding\nyour carb limit"
    }
}
