//
//  StatisticsView.swift
//  CarbClarity
//
//  Created by René Fouquet on 17.07.25.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [CarbEntry]
    @StateObject private var viewModel = StatisticsViewModel()
    @AppStorage(AppSettings.SettingsKey.carbLimit.rawValue, store: AppSettings.sharedUserDefaults) var carbLimit = AppSettings.carbLimit
    @AppStorage(AppSettings.SettingsKey.cautionLimit.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimit = AppSettings.cautionLimit
    @AppStorage(AppSettings.SettingsKey.warnLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var warnLimitEnabled = AppSettings.warnLimitEnabled
    @AppStorage(AppSettings.SettingsKey.cautionLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimitEnabled = AppSettings.cautionLimitEnabled
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "7-Day Average", value: viewModel.weeklyAverage, unit: "g")
                        StatCard(title: "This Month", value: viewModel.monthlyTotal, unit: "g")
                        StatCard(title: "Lowest Day", value: viewModel.lowestDay?.value ?? 0, unit: "g", subtitle: viewModel.lowestDay?.date)
                        StatCard(title: "Highest Day", value: viewModel.highestDay?.value ?? 0, unit: "g", subtitle: viewModel.highestDay?.date)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Carb Intake (Last 30 Days)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            if warnLimitEnabled {
                                RuleMark(
                                    y: .value("Warning Limit", carbLimit)
                                )
                                .foregroundStyle(.red)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            }
                            
                            if cautionLimitEnabled {
                                RuleMark(
                                    y: .value("Caution Limit", cautionLimit)
                                )
                                .foregroundStyle(.yellow)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            }
                            
                            ForEach(viewModel.dailyData.suffix(30), id: \.date) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Carbs", data.totalCarbs)
                                )
                                .foregroundStyle(.blue.gradient)
                                .cornerRadius(2)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Average Trend")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(viewModel.weeklyData) { data in
                            LineMark(
                                x: .value("Week", data.weekStart, unit: .weekOfYear),
                                y: .value("Average", data.weeklyAverage)
                            )
                            .symbol(.circle)
                            .symbolSize(60)
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            AreaMark(
                                x: .value("Week", data.weekStart, unit: .weekOfYear),
                                y: .value("Average", data.weeklyAverage)
                            )
                            .foregroundStyle(.green.opacity(0.1))
                        }
                        .frame(height: 150)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Insights")
        }
        .onAppear {
            viewModel.updateData(entries: entries)
        }
        .onChange(of: entries) { _, newEntries in
            viewModel.updateData(entries: newEntries)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let unit: String
    let subtitle: String?
    
    init(title: String, value: Double, unit: String, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value.formatted(.number.precision(.fractionLength(1))))
                    .font(.title2)
                    .fontWeight(.semibold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    StatisticsView()
}
