//
//  AppDependencyManager.swift
//  CarbClarity
//
//  Created by René Fouquet on 18.07.25.
//

import Foundation
import SwiftData

@MainActor
class AppDependencyManager: ObservableObject {
    static let shared = AppDependencyManager()
    
    private(set) var modelContainer: ModelContainer?
    
    private init() {}
    
    func setModelContainer(_ container: ModelContainer?) {
        self.modelContainer = container
    }
}
