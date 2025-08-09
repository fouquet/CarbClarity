//
//  WatchConnectivityManager.swift
//  CarbClarity
//
//  Created by René Fouquet on 20.07.25.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        setupSession()
    }
    
    // For testing - internal init that doesn't setup session
    internal init(testMode: Bool) {
        super.init()
        if !testMode {
            setupSession()
        }
    }
    
    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    
    func requestCrossPlatformWidgetRefresh() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { 
            return 
        }
        
        let message = ["action": "refreshWidgets", "timestamp": Date().timeIntervalSince1970] as [String: Any]
        
        // Use multiple delivery methods for maximum reliability
        #if os(iOS)
        // Primary method: Use complication transfer for reliable widget updates to watch
        if WCSession.default.isComplicationEnabled {
            WCSession.default.transferCurrentComplicationUserInfo(message)
        }
        
        // Also try user info transfer as backup
        WCSession.default.transferUserInfo(message)
        #endif
        
        // Always update application context as fallback
        try? WCSession.default.updateApplicationContext(message)
        
        // Try immediate message if reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { 
        WCSession.default.activate() 
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleMessage(applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleMessage(userInfo)
    }
    
    #if os(watchOS)
    func session(_ session: WCSession, didReceiveCurrentComplicationUserInfo userInfo: [String: Any]) {
        handleMessage(userInfo)
    }
    #endif
    
    private func handleMessage(_ message: [String: Any]) {
        guard message["action"] as? String == "refreshWidgets" else { return }
        DispatchQueue.main.async {
            WidgetUpdateManager.refreshLocalWidgets()
        }
    }
}
