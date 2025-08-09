//
//  SettingsView.swift
//  CarbClarity
//
//  Created by René Fouquet on 07.06.24.
//

import SwiftUI

struct SettingsView: View {
    @Binding var presented: Bool
    @StateObject private var viewModel = SettingsViewModel()
    
    @AppStorage(AppSettings.SettingsKey.carbLimit.rawValue, store: AppSettings.sharedUserDefaults) var carbLimit = AppSettings.carbLimit
    @AppStorage(AppSettings.SettingsKey.cautionLimit.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimit = AppSettings.cautionLimit
    @AppStorage(AppSettings.SettingsKey.warnLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var warnLimitEnabled = AppSettings.warnLimitEnabled
    @AppStorage(AppSettings.SettingsKey.cautionLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimitEnabled = AppSettings.cautionLimitEnabled
    @AppStorage(AppSettings.SettingsKey.lookupEnabled.rawValue, store: AppSettings.sharedUserDefaults) var lookupEnabled = AppSettings.lookupEnabled
    @AppStorage(AppSettings.SettingsKey.lookupAPIKey.rawValue, store: AppSettings.sharedUserDefaults) var lookupAPIKey = AppSettings.lookupAPIKey
    @AppStorage(AppSettings.SettingsKey.quickAddButtonsEnabled.rawValue, store: AppSettings.sharedUserDefaults) var quickAddButtonsEnabled = AppSettings.quickAddButtonsEnabled
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                warningLimitSection
                cautionLimitSection
                quickAddButtonsSection
                foodLookupSection
                aboutSection
                linksSection
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
            .navigationTitle("Settings")
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            .alert("API Key Required", isPresented: $viewModel.showingAPIKeyAlert) {
                Button("OK", role: .cancel) {
                    viewModel.dismissAPIKeyAlert()
                }
                Button("Get API Key") {
                    viewModel.openAPIKeyURL()
                }
            } message: {
                Text("This functionality requires an API key. Please enter an API key.")
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            UIApplication.shared.open(url)
            return .handled
        })
        .onAppear {
            syncToViewModel()
        }
        .onChange(of: viewModel.carbLimit) { _, newValue in
            carbLimit = newValue
        }
        .onChange(of: viewModel.cautionLimit) { _, newValue in
            cautionLimit = newValue
        }
        .onChange(of: viewModel.warnLimitEnabled) { _, newValue in
            warnLimitEnabled = newValue
        }
        .onChange(of: viewModel.cautionLimitEnabled) { _, newValue in
            cautionLimitEnabled = newValue
        }
        .onChange(of: viewModel.lookupEnabled) { _, newValue in
            lookupEnabled = newValue
        }
        .onChange(of: viewModel.lookupAPIKey) { _, newValue in
            lookupAPIKey = newValue
        }
        .onChange(of: carbLimit) { _, _ in
            syncToViewModel()
        }
        .onChange(of: cautionLimit) { _, _ in
            syncToViewModel()
        }
        .onChange(of: warnLimitEnabled) { _, _ in
            syncToViewModel()
        }
        .onChange(of: cautionLimitEnabled) { _, _ in
            syncToViewModel()
        }
        .onChange(of: lookupEnabled) { _, _ in
            syncToViewModel()
        }
        .onChange(of: lookupAPIKey) { _, _ in
            syncToViewModel()
        }
    }
    
    
    private var warningLimitSection: some View {
        Section {
            HStack {
                Text("Warning limit enabled")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle(isOn: $viewModel.warnLimitEnabled) {}
                    .accessibilityIdentifier("Warning limit enabled")
            }
            
            HStack {
                Text("Warning limit in grams")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Warning Limit", value: $viewModel.carbLimit, format: .number)
                    .padding(.all, 5.0)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 30.0, maxWidth: 100.0, alignment: .trailing)
                    .focused($isFocused)
                    .accessibilityIdentifier("Warning Limit")
                    .disabled(!viewModel.warnLimitEnabled)
            }
        } header: {
            Text("Warning Limit")
        } footer: {
            Text("The warning limit shows red coloring and an alert message when exceeded.")
        }
    }
    
    private var cautionLimitSection: some View {
        Section {
            HStack {
                Text("Caution limit enabled")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle(isOn: $viewModel.cautionLimitEnabled) {}
                    .accessibilityIdentifier("Caution limit enabled")
            }
            
            HStack {
                Text("Caution limit in grams")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Caution Limit", value: $viewModel.cautionLimit, format: .number)
                    .padding(.all, 5.0)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 30.0, maxWidth: 100.0, alignment: .trailing)
                    .focused($isFocused)
                    .accessibilityIdentifier("Caution Limit")
                    .disabled(!viewModel.cautionLimitEnabled)
            }
        } header: {
            Text("Caution Limit")
        } footer: {
            Text("The Caution limit shows yellow coloring when exceeded.")
        }
    }
    
    private var quickAddButtonsSection: some View {
        Section {
            HStack {
                Text("Show Quick Add Buttons")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Toggle(isOn: $quickAddButtonsEnabled) {}
                    .accessibilityIdentifier("Quick Add Buttons Enabled")
            }
        } header: {
            Text("Quick Add")
        } footer: {
            Text("Show preset buttons for quickly adding common carb amounts (0.1, 0.5, 1, 4, 6, 10 grams).")
        }
    }
    
    private var foodLookupSection: some View {
        Section {
            VStack {
                Text(.init(viewModel.foodLookupDescription))
                    .multilineTextAlignment(.leading)
                    .padding(.vertical)
                
                HStack {
                    Text("Enable USDA FoodData Lookup")
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 5.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Toggle(isOn: lookupToggleBinding) {}
                        .padding(.trailing, 5.0)
                        .accessibilityIdentifier("Enable USDA FoodData Lookup")
                }
                
                HStack(spacing: 12) {
                    Text("API Key")
                        .multilineTextAlignment(.leading)
                    TextField("API Key", text: $viewModel.lookupAPIKey)
                        .padding(.all, 5.0)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.asciiCapable)
                        .focused($isFocused)
                        .accessibilityIdentifier("API Key")
                }
                .padding(.horizontal, 5.0)
            }
        } header: {
            Text("Food Lookup")
        }
    }
    
    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text(viewModel.aboutText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 5.0)
                Text(viewModel.versionText)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 5.0)
                Text(viewModel.copyrightText)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 5.0)
                Text(.init(viewModel.supportText))
                    .padding(.bottom, 5.0)
                Text(.init(viewModel.ossText))
            }
        } header: {
            Text("About")
        }
    }
    
    private var linksSection: some View {
        Section {
            NavigationLink {
                PrivacyView()
            } label: {
                Text("Privacy Policy")
            }
            .accessibilityIdentifier("Privacy Policy")
            
            NavigationLink {
                FAQView()
            } label: {
                Text("FAQ")
            }
            .accessibilityIdentifier("FAQ")
        }
    }
    
    
    private var doneButton: some View {
        Button(action: {
            presented.toggle()
        }, label: {
            Text("Done")
        })
        .accessibilityIdentifier("Done")
    }
    
    private var lookupToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.lookupEnabled },
            set: { newValue in
                viewModel.toggleLookupEnabled(newValue)
            }
        )
    }
    
    
    private func syncToViewModel() {
        viewModel.updateSettings(
            carbLimit: carbLimit,
            cautionLimit: cautionLimit,
            warnLimitEnabled: warnLimitEnabled,
            cautionLimitEnabled: cautionLimitEnabled,
            lookupEnabled: lookupEnabled,
            lookupAPIKey: lookupAPIKey
        )
    }
}

#Preview {
    SettingsView(presented: .constant(true))
}
