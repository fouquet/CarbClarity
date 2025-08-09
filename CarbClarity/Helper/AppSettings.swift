//
//  AppSettings.swift
//  CarbClarity
//
//  Created by René Fouquet on 19.07.25.
//

import Foundation

class AppSettings {
    static let appGroupIdentifier: String = {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String else {
            fatalError("AppGroupIdentifier not found in Info.plist")
        }
        return identifier
    }()
    nonisolated(unsafe) static let sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier)
    
    enum SettingsKey: String {
        case carbLimit = "carbLimit"
        case cautionLimit = "cautionLimit"
        case warnLimitEnabled = "warnLimitEnabled"
        case cautionLimitEnabled = "cautionLimitEnabled"
        case lookupEnabled = "lookupEnabled"
        case lookupAPIKey = "lookupAPIKey"
        case quickAddButtonsEnabled = "quickAddButtonsEnabled"
        case widgetLastUpdate = "widget_last_update"
    }
    
    static var carbLimit: Double {
        get {
            guard let userDefaults = sharedUserDefaults else { return 20.0 }
            if userDefaults.object(forKey: SettingsKey.carbLimit.rawValue) == nil {
                return 20.0
            }
            return userDefaults.double(forKey: SettingsKey.carbLimit.rawValue)
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.carbLimit.rawValue)
        }
    }

    static var cautionLimit: Double {
        get {
            guard let userDefaults = sharedUserDefaults else { return 15.0 }
            if userDefaults.object(forKey: SettingsKey.cautionLimit.rawValue) == nil {
                return 15.0
            }
            return userDefaults.double(forKey: SettingsKey.cautionLimit.rawValue)
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.cautionLimit.rawValue)
        }
    }

    static var warnLimitEnabled: Bool {
        get {
            guard let userDefaults = sharedUserDefaults else { return true }
            if userDefaults.object(forKey: SettingsKey.warnLimitEnabled.rawValue) == nil {
                return true
            }
            return userDefaults.bool(forKey: SettingsKey.warnLimitEnabled.rawValue)
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.warnLimitEnabled.rawValue)
        }
    }

    static var cautionLimitEnabled: Bool {
        get {
            guard let userDefaults = sharedUserDefaults else { return true }
            if userDefaults.object(forKey: SettingsKey.cautionLimitEnabled.rawValue) == nil {
                return true
            }
            return userDefaults.bool(forKey: SettingsKey.cautionLimitEnabled.rawValue)
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.cautionLimitEnabled.rawValue)
        }
    }
    
    static var lookupAPIKey: String {
        get {
            if let lookupAPIKey = sharedUserDefaults?.string(forKey: SettingsKey.lookupAPIKey.rawValue) {
                return lookupAPIKey
            }
            return ""
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.lookupAPIKey.rawValue)
        }
    }

    static var lookupEnabled: Bool {
        get {
            guard let userDefaults = sharedUserDefaults else { return false }
            let isEnabled = userDefaults.object(forKey: SettingsKey.lookupEnabled.rawValue) == nil ? false : userDefaults.bool(forKey: SettingsKey.lookupEnabled.rawValue)
            return isEnabled && !lookupAPIKey.isEmpty
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.lookupEnabled.rawValue)
        }
    }

    static var quickAddButtonsEnabled: Bool {
        get {
            guard let userDefaults = sharedUserDefaults else { return false }
            if userDefaults.object(forKey: SettingsKey.quickAddButtonsEnabled.rawValue) == nil {
                return false  // Default to disabled
            }
            return userDefaults.bool(forKey: SettingsKey.quickAddButtonsEnabled.rawValue)
        }
        set(value) {
            sharedUserDefaults?.setValue(value, forKey: SettingsKey.quickAddButtonsEnabled.rawValue)
        }
    }
}
