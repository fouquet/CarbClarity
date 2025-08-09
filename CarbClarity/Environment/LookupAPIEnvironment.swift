//
//  LookupAPIEnvironment.swift
//  CarbClarity
//
//  Created by René Fouquet on 06.08.25.
//

import SwiftUI

/// Environment key for injecting lookup API factory
struct LookupAPIFactoryKey: EnvironmentKey {
    static let defaultValue: (@Sendable () -> LookupAPIProtocol)? = nil
}

extension EnvironmentValues {
    /// Optional factory for creating lookup API instances
    /// When nil (default), uses production LookupAPI
    /// When provided, uses the factory (for testing)
    var lookupAPIFactory: (@Sendable () -> LookupAPIProtocol)? {
        get { self[LookupAPIFactoryKey.self] }
        set { self[LookupAPIFactoryKey.self] = newValue }
    }
}
