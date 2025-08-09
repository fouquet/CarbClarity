//
//  WatchMainView.swift
//  CarbClarityWatch
//
//  Created by René Fouquet on 18.07.25.
//

import SwiftUI
import SwiftData
import Foundation

struct WatchMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [CarbEntry]
    @StateObject private var viewModel = WatchViewModel()    
    @AppStorage(AppSettings.SettingsKey.carbLimit.rawValue, store: AppSettings.sharedUserDefaults) var carbLimit = AppSettings.carbLimit
    @AppStorage(AppSettings.SettingsKey.cautionLimit.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimit = AppSettings.cautionLimit
    @AppStorage(AppSettings.SettingsKey.warnLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var warnLimitEnabled = AppSettings.warnLimitEnabled
    @AppStorage(AppSettings.SettingsKey.cautionLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimitEnabled = AppSettings.cautionLimitEnabled
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.totalCarbsForTodayString)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.todaysCarbDisplayColor.color)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.vertical, 8)
                    
                    if viewModel.isExceedingCarbLimit {
                        Text("⚠️ Over limit")
                            .font(.caption2)
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        Text("Quick Add")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                            QuickAddButton(value: 0.1, viewModel: viewModel)
                            QuickAddButton(value: 0.5, viewModel: viewModel)
                            QuickAddButton(value: 1, viewModel: viewModel)
                            QuickAddButton(value: 4, viewModel: viewModel)
                            QuickAddButton(value: 6, viewModel: viewModel)
                            QuickAddButton(value: 10, viewModel: viewModel)
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        viewModel.showAddView()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Custom Amount")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Carb Clarity")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showingAddView) {
            CustomAddView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled
            )
        }
        .onChange(of: items) { _, newItems in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: newItems,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled
            )
        }
        .onChange(of: carbLimit) { _, newLimit in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: newLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled
            )
        }
        .onChange(of: cautionLimit) { _, newCautionLimit in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: newCautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled
            )
        }
        .onChange(of: warnLimitEnabled) { _, newWarnLimitEnabled in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: newWarnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled
            )
        }
        .onChange(of: cautionLimitEnabled) { _, newCautionLimitEnabled in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: newCautionLimitEnabled
            )
        }
    }
}

struct QuickAddButton: View {
    let value: Double
    let viewModel: WatchViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                _ = viewModel.quickAdd(value)
            }
        }) {
            Text("\(value.carbString())")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 44, height: 32)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomAddView: View {
    @ObservedObject var viewModel: WatchViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Add Carbs")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    TextField("Amount", value: $viewModel.inputValue, format: .number)
                        .focused($isFocused)
                    
                    Text("grams")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.inputValue = nil
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    
                    Button("Add") {
                        if viewModel.addItem() {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canAddEntry)
                    .foregroundColor(viewModel.canAddEntry ? .accentColor : .secondary)
                }
                .font(.system(size: 16, weight: .medium))
            }
            .padding()
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    WatchMainView()
        .modelContainer(for: CarbEntry.self, inMemory: true)
}
