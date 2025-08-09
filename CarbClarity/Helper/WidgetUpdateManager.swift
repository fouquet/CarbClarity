//
//  WidgetUpdateManager.swift
//  CarbClarity
//
//  Created by René Fouquet on 19.07.25.
//

import Foundation
import WidgetKit

final class WidgetUpdateManager: @unchecked Sendable {
    static func requestWidgetUpdate() {
        refreshLocalWidgets()
        
        // Small delay to ensure local data is committed before cross-platform sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WatchConnectivityManager.shared.requestCrossPlatformWidgetRefresh()
        }
    }
    
    static func refreshLocalWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        // Also reload specific widget kinds for extra reliability
        WidgetCenter.shared.reloadTimelines(ofKind: "CarbClarityWidget")
    }
}
