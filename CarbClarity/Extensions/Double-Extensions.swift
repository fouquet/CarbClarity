//
//  Double-Extensions.swift
//  CarbClarity
//
//  Created by René Fouquet on 11.07.25.
//

import Foundation

extension Double {
    func carbString(locale: Locale = Locale.current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        
        guard var stringValue = formatter.string(from: NSNumber(value: self.roundedForCarbs())) else { return "" }
        
        if stringValue.hasSuffix(".0") {
            stringValue.removeLast(2)
        }
        
        return stringValue + "g"
    }
    
    func roundedForCarbs() -> Double {
        return (self * 100).rounded() / 100
    }
}
