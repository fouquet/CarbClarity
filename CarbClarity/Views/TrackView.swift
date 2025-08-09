//
//  TrackView.swift
//  CarbClarity
//
//  Created by René Fouquet on 07.06.24.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TrackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [CarbEntry]
    @StateObject private var viewModel = MainViewModel()
    
    @AppStorage(AppSettings.SettingsKey.carbLimit.rawValue, store: AppSettings.sharedUserDefaults) var carbLimit = AppSettings.carbLimit
    @AppStorage(AppSettings.SettingsKey.cautionLimit.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimit = AppSettings.cautionLimit
    @AppStorage(AppSettings.SettingsKey.warnLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var warnLimitEnabled = AppSettings.warnLimitEnabled
    @AppStorage(AppSettings.SettingsKey.cautionLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimitEnabled = AppSettings.cautionLimitEnabled
    @AppStorage(AppSettings.SettingsKey.lookupEnabled.rawValue, store: AppSettings.sharedUserDefaults) var lookupEnabled = AppSettings.lookupEnabled
    @AppStorage(AppSettings.SettingsKey.quickAddButtonsEnabled.rawValue, store: AppSettings.sharedUserDefaults) var quickAddButtonsEnabled = AppSettings.quickAddButtonsEnabled
    @FocusState private var isFocused: Bool
    @State private var isListExpanded = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                    VStack(spacing: 0) {
                    if !isListExpanded {
                        HStack {
                            Text("Carb Clarity")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                    
                    if !isListExpanded {
                        VStack {
                            VStack {
                                if viewModel.isExceedingCarbLimit {
                                    Text("⚠️ You are exceeding your carb limit ⚠️")
                                        .foregroundStyle(Color.red)
                                        .padding()
                                }
                                
                                VStack(spacing: 8) {
                                    Text("Today's total carb intake")
                                        .multilineTextAlignment(.center)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text(viewModel.totalCarbsForTodayString)
                                        .padding(.horizontal, 20)
                                        .font(.system(size: 150))
                                        .minimumScaleFactor(0.5)
                                        .fontWeight(.heavy)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(viewModel.todaysCarbDisplayColor.color)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal, 25)
                                .padding(.top, 8)
                            }
                            
                            if quickAddButtonsEnabled {
                                QuickAddButtonsView(viewModel: viewModel)
                                    .padding(.horizontal, 5)
                                    .transition(.opacity.combined(with: .scale))
                            }
                            
                            Spacer().frame(height: 20.0)
                            HStack(spacing: 12) {
                                TextField("New carbs in grams", value: $viewModel.inputValue, format: .number)
                                    .padding(.all, 5.0)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .focused($isFocused)
                                    .accessibilityIdentifier("New carbs in grams")
                                    .frame(width: 180)
                                Button(action: addItem) {
                                    Label("Add", systemImage: "plus")
                                        .disabled(!viewModel.canAddEntry)
                                }
                                .accessibilityIdentifier("Add")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .contentShape(Rectangle())
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .background(Color(.systemBackground))
                        
                        historyHeader
                    }
                    
                    scrollableListView()
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                
                if isListExpanded {
                    expandedListView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: showSettings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("Settings")
                }
                if lookupEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: showLookup) {
                            Label("Food Lookup", systemImage: "plus.magnifyingglass")
                        }
                        .accessibilityIdentifier("Food Lookup")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .accessibilityIdentifier("Edit")
                }
                #if DEBUG
                // The mock data generator makes it easy to create realistical
                // mock data for screenshots and testing. To use it, add the file
                // MockDataGenerator.swift to the CarbClarity target and uncomment the following code.
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Menu("Debug") {
//                        Button("Generate Mock Data") {
//                            MockDataGenerator.generateMockData(modelContext: modelContext)
//                        }
//                        Button("Clear All Data") {
//                            MockDataGenerator.clearAllData(modelContext: modelContext)
//                        }
//                        Menu("Test Scenarios") {
//                            Button("Increasing Trend") {
//                                MockDataGenerator.generateTestScenario(modelContext: modelContext, scenario: .increasingTrend)
//                            }
//                            Button("Decreasing Trend") {
//                                MockDataGenerator.generateTestScenario(modelContext: modelContext, scenario: .decreasingTrend)
//                            }
//                            Button("High Variability") {
//                                MockDataGenerator.generateTestScenario(modelContext: modelContext, scenario: .highVariability)
//                            }
//                        }
//                    }
//                    .foregroundColor(.secondary)
//                }
                #endif
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
                    SettingsView(presented: $viewModel.showingSettings)
                }
        .sheet(isPresented: $viewModel.showingLookup) {
                    LookupView(presented: $viewModel.showingLookup)
                }
        .onAppear {
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled,
                lookupEnabled: lookupEnabled
            )
        }
        .onChange(of: items) { _, newItems in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: newItems,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled,
                lookupEnabled: lookupEnabled
            )
        }
        .onChange(of: carbLimit) { _, newLimit in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: newLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled,
                lookupEnabled: lookupEnabled
            )
        }
        .onChange(of: lookupEnabled) { _, newLookupEnabled in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled,
                lookupEnabled: newLookupEnabled
            )
        }
        .onChange(of: cautionLimit) { _, newCautionLimit in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: newCautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled,
                lookupEnabled: lookupEnabled
            )
        }
        .onChange(of: warnLimitEnabled) { _, newWarnLimitEnabled in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: newWarnLimitEnabled,
                cautionLimitEnabled: cautionLimitEnabled,
                lookupEnabled: lookupEnabled
            )
        }
        .onChange(of: cautionLimitEnabled) { _, newCautionLimitEnabled in
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: items,
                carbLimit: carbLimit,
                cautionLimit: cautionLimit,
                warnLimitEnabled: warnLimitEnabled,
                cautionLimitEnabled: newCautionLimitEnabled,
                lookupEnabled: lookupEnabled
            )
        }
    }
    
    
    @ViewBuilder
    var historyHeader: some View {
        HStack {
            Text("History")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button(action: toggleExpandedState) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Expand list to full screen")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .gesture(historyHeaderGesture)
    }
    
    var historyHeaderGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 30
                if value.translation.height < -threshold {
                    if !isListExpanded {
                        toggleExpandedState()
                    }
                } else if value.translation.height > threshold {
                    if isListExpanded {
                        toggleExpandedState()
                    }
                }
            }
    }
    
    @ViewBuilder
    func scrollableListView() -> some View {
        VStack(spacing: 0) {
            if viewModel.carbEntriesByDay.isEmpty {
                List {
                    VStack(spacing: 12) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                        
                        Text("No entries yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .listRowSeparator(.hidden)
                }
            } else {
                List {
                    ForEach(viewModel.carbEntriesByDay, id: \.day) { entry in
                        Section {
                            ForEach(entry.entries, id: \.timestamp) { item in
                                HStack(spacing: 20.0) {
                                    Text(item.value.carbString())
                                    Text(item.timestamp, format: Date.FormatStyle(date: .omitted, time: .shortened))
                                        .foregroundStyle(Color.gray)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }.onDelete { 
                                self.deleteItems(items: entry.entries, offsets: $0)
                            }
                        } header: {
                            HStack {
                                Text(entry.day, format: Date.FormatStyle(date: .complete, time: .omitted))
                                Text(viewModel.dayTotal(for: entry))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }.padding(.zero)
                        }.textCase(.none)
                    }
                }
                .overlay(Divider(), alignment: .top)
            }
        }
    }
    
    @ViewBuilder
    var expandedHistoryHeader: some View {
        HStack {
            Text("History")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: toggleExpandedState) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Contract list back to normal view")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .gesture(expandedHeaderGesture)
    }
    
    var expandedHeaderGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 30
                if value.translation.height > threshold {
                    if isListExpanded {
                        toggleExpandedState()
                    }
                }
            }
    }
    
    @ViewBuilder
    func expandedListView() -> some View {
        VStack(spacing: 0) {
            expandedHistoryHeader
            
            if viewModel.carbEntriesByDay.isEmpty {
                List {
                    VStack(spacing: 12) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                        
                        Text("No entries yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .listRowSeparator(.hidden)
                }
            } else {
                List {
                    ForEach(viewModel.carbEntriesByDay, id: \.day) { entry in
                        Section {
                            ForEach(entry.entries, id: \.timestamp) { item in
                                HStack(spacing: 20.0) {
                                    Text(item.value.carbString())
                                    Text(item.timestamp, format: Date.FormatStyle(date: .omitted, time: .shortened))
                                        .foregroundStyle(Color.gray)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }.onDelete { 
                                self.deleteItems(items: entry.entries, offsets: $0)
                            }
                        } header: {
                            HStack {
                                Text(entry.day, format: Date.FormatStyle(date: .complete, time: .omitted))
                                Text(viewModel.dayTotal(for: entry))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }.padding(.zero)
                        }.textCase(.none)
                    }
                }
                .overlay(Divider(), alignment: .top)
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    
    private func showSettings() {
        viewModel.showSettings()
    }
    
    private func showLookup() {
        viewModel.showLookup()
    }

    private func addItem() {
        withAnimation {
            if viewModel.addItem() {
                isFocused = false
            }
        }
    }

    private func deleteItems(items: [CarbEntry], offsets: IndexSet) {
        withAnimation {
            _ = viewModel.deleteItems(items: items, offsets: offsets)
        }
    }
    
    private func toggleExpandedState() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            isListExpanded.toggle()
        }
    }
 }

#Preview {
    TrackView()
        .modelContainer(for: CarbEntry.self, inMemory: true)
}
