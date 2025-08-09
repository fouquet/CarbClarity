//
//  SettingsViewModel.swift
//  CarbClarity
//
//  Created by René Fouquet on 13.07.25.
//

import Foundation
import UIKit

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var carbLimit: Double = 20.0
    @Published var cautionLimit: Double = 15.0
    @Published var warnLimitEnabled: Bool = true
    @Published var cautionLimitEnabled: Bool = true
    @Published var lookupEnabled: Bool = false
    @Published var lookupAPIKey: String = ""
    @Published var showingAPIKeyAlert: Bool = false
    
    // App information
    let appVersion: String
    let buildNumber: String
    let aboutText: String
    let copyrightText: String
    let supportText: String
    let ossText: String
    
    init() {
        // Initialize app information
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.aboutText = "Carb Clarity"
        self.copyrightText = "©️ 2024–2025 René Fouquet"
        self.supportText = "For questions and feedback, send me an [email](mailto:support@fouquet.me) or find me on [Mastodon](https://mastodon.social/@renef)."
        self.ossText = "Carb Clarity is Open Source Software! You can find the source code on [GitHub](https://github.com/fouquet/CarbClarity). If you want to contribute, please fork the repository and submit a pull request. You can also open an issue on GitHub if you have any problems or suggestions."
    }
    
    
    var versionText: String {
        return "Version \(appVersion) (\(buildNumber))"
    }
    
    var isAPIKeyEmpty: Bool {
        return lookupAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var foodLookupDescription: String {
        return "You can enable food lookup, which lets you search for carbohydrate values of food. The feature uses the USDA (US Department of Agriculture) FoodData API, which requires a valid API key. You can get one for free on the [FoodData website](https://fdc.nal.usda.gov/api-key-signup.html)."
    }
    
    
    func toggleLookupEnabled(_ newValue: Bool) {
        if newValue && isAPIKeyEmpty {
            showingAPIKeyAlert = true
        } else {
            lookupEnabled = newValue
        }
    }
    
    func dismissAPIKeyAlert() {
        showingAPIKeyAlert = false
    }
    
    func openAPIKeyURL() {
        guard let url = URL(string: "https://fdc.nal.usda.gov/api-key-signup.html") else { return }
        UIApplication.shared.open(url)
    }
    
    
    
    
    func updateSettings(carbLimit: Double, cautionLimit: Double, warnLimitEnabled: Bool, cautionLimitEnabled: Bool, lookupEnabled: Bool, lookupAPIKey: String) {
        self.carbLimit = carbLimit
        self.cautionLimit = cautionLimit
        self.warnLimitEnabled = warnLimitEnabled
        self.cautionLimitEnabled = cautionLimitEnabled
        self.lookupEnabled = lookupEnabled
        self.lookupAPIKey = lookupAPIKey
    }
    
}
