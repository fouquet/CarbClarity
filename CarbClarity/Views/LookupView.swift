//
//  LookupView.swift
//  CarbClarity
//
//  Created by René Fouquet on 15.06.24.
//

import SwiftUI
import SwiftData
import WidgetKit

struct LookupView: View {
    @Binding var presented: Bool
    @State private var searchText = ""
    @StateObject private var viewModel: LookupViewModel
    @AppStorage(AppSettings.SettingsKey.lookupAPIKey.rawValue, store: AppSettings.sharedUserDefaults) var lookupAPIKey = AppSettings.lookupAPIKey
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.lookupAPIFactory) private var lookupAPIFactory
    @State private var showBottomSection = false
    
    init(presented: Binding<Bool>) {
        self._presented = presented
        self._viewModel = StateObject(wrappedValue: LookupViewModel(apiKey: ""))
    }
    
    init(presented: Binding<Bool>, viewModel: LookupViewModel) {
        self._presented = presented
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Searching for foods...")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else if viewModel.hasSearched && viewModel.foods.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No foods found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Try a different search term")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else if !viewModel.hasSearched {
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Search for foods")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Enter a food name to get started")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.foods, id: \.self) { food in
                            HStack {
                                if viewModel.selectedFood?.fdcId == food.fdcId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.headline)
                                } else {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.clear)
                                        .font(.headline)
                                }
                                
                                Text(food.name)
                                    .lineLimit(2)
                                Spacer()
                                HStack {
                                    if food.isLoadingCarbs {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading...")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    } else {
                                        Text(carbString(for: food.carbs))
                                            .foregroundColor(food.carbs > 0 ? .primary : .gray)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.selectFood(food)
                                    showBottomSection = true
                                }
                            }
                            .onAppear {
                                if food.isLoadingCarbs {
                                    Task {
                                        await viewModel.loadCarbsForFood(food)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if showBottomSection && viewModel.selectedFood != nil {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 0.5)
                        
                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Amount Eaten")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    TextField("Amount", value: $viewModel.amountEaten, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 100)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("grams")
                                        .foregroundColor(.secondary)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Total Carbs")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(carbString(for: viewModel.calculatedCarbs))
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            
                            Button(action: addCarbEntry) {
                                Label("Add to Daily Total", systemImage: "plus.circle.fill")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canAddEntry)
                            .controlSize(.large)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(
                            Color(.systemBackground)
                                .ignoresSafeArea(.container, edges: .bottom)
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Food Lookup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presented = false
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .automatic)
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .onAppear {
            // Use environment factory if provided (for testing), otherwise production API
            if let factory = lookupAPIFactory {
                let mockAPI = factory()
                viewModel.updateDependencies(apiKey: mockAPI.apiKey, modelContext: modelContext, lookupAPI: mockAPI)
            } else {
                viewModel.updateDependencies(apiKey: lookupAPIKey, modelContext: modelContext)
            }
        }
        .onSubmit(of: .search) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showBottomSection = false
            }
            Task {
                await viewModel.search(for: searchText)
            }
        }
        .onChange(of: searchText) { _, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showBottomSection = false
            }
            Task {
                await viewModel.search(for: newValue)
            }
        }
        .alert(
            viewModel.currentError?.errorDescription ?? "Error",
            isPresented: $viewModel.showingError,
            presenting: viewModel.currentError
        ) { error in
            if error.canRetry {
                Button("Retry") {
                    Task {
                        await viewModel.retryLastSearch()
                    }
                }
            }
            Button("OK", role: .cancel) {
                viewModel.dismissError()
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
    
    private func addCarbEntry() {
        if viewModel.addCarbEntry() {
            presented = false
        }
    }
    
    private func carbString(for value: Double) -> String {
        guard var stringValue = numberFormatter.string(from: NSNumber(value: value)) else { return "" }
        
        if stringValue.hasSuffix(".0") {
            stringValue.removeLast(2)
        }
        
        return stringValue + "g"
    }
}

#Preview {
    LookupView(presented: .constant(true))
}
