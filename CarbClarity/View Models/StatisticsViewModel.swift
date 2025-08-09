//
//  StatisticsViewModel.swift
//  CarbClarity
//
//  Created by René Fouquet on 17.07.25.
//

import Foundation
import SwiftUI

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var dailyData = [DailyData]()
    @Published var weeklyData = [WeeklyData]()
    @Published var weeklyAverage: Double = 0.0
    @Published var monthlyTotal: Double = 0.0
    @Published var lowestDay: (date: String, value: Double)? = nil
    @Published var highestDay: (date: String, value: Double)? = nil
    
    func updateData(entries: [CarbEntry]) {
        calculateDailyData(entries: entries)
        calculateWeeklyData()
        calculateStatistics(entries: entries)
    }
    
    private func calculateDailyData(entries: [CarbEntry]) {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let groupedEntries = Dictionary(grouping: entries.filter { $0.timestamp >= thirtyDaysAgo }) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        var daily = [DailyData]()
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let totalCarbs = groupedEntries[dayStart]?.reduce(0.0, { $0 + $1.value }) ?? 0.0
            
            daily.append(DailyData(date: dayStart, totalCarbs: totalCarbs))
        }
        
        dailyData = daily.reversed()
    }
    
    private func calculateWeeklyData() {
        let calendar = Calendar.current
        var weekly = [WeeklyData]()
        
        let weekGroups = Dictionary(grouping: dailyData) { data in
            calendar.dateInterval(of: .weekOfYear, for: data.date)?.start ?? data.date
        }
        
        for (weekStart, weekDays) in weekGroups.sorted(by: { $0.key < $1.key }) {
            let weeklyAverage = weekDays.map { $0.totalCarbs }.reduce(0.0, +) / Double(weekDays.count)
            weekly.append(WeeklyData(weekStart: weekStart, weeklyAverage: weeklyAverage))
        }
        
        weeklyData = weekly
    }
    
    private func calculateStatistics(entries: [CarbEntry]) {
        let calendar = Calendar.current
        let now = Date()
        
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let weekEntries = entries.filter { $0.timestamp >= weekAgo }
        let weekTotal = weekEntries.reduce(0.0, { $0 + $1.value })
        weeklyAverage = weekTotal / 7.0
        
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthEntries = entries.filter { $0.timestamp >= monthStart }
        monthlyTotal = monthEntries.reduce(0.0, { $0 + $1.value })
        
        let daysWithCarbs = dailyData.filter { $0.totalCarbs > 0 }
        if let lowestDayData = daysWithCarbs.min(by: { $0.totalCarbs < $1.totalCarbs }) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            lowestDay = (formatter.string(from: lowestDayData.date), lowestDayData.totalCarbs)
        } else {
            lowestDay = nil
        }
        
        if let highestDayData = dailyData.max(by: { $0.totalCarbs < $1.totalCarbs }),
           highestDayData.totalCarbs > 0 {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            highestDay = (formatter.string(from: highestDayData.date), highestDayData.totalCarbs)
        } else {
            highestDay = nil
        }
    }
}

struct DailyData: Identifiable {
    let id = UUID()
    let date: Date
    let totalCarbs: Double
}

struct WeeklyData: Identifiable {
    let id = UUID()
    let weekStart: Date
    let weeklyAverage: Double
}