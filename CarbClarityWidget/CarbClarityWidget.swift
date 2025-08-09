//
//  CarbClarityWidget.swift
//  CarbClarityWidget
//
//  Created by René Fouquet on 08.06.24.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CarbEntry.self,
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, groupContainer: .identifier(AppSettings.appGroupIdentifier))

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    func placeholder(in context: Context) -> CarbClarityEntry {
        CarbClarityEntry(total: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CarbClarityEntry) -> ()) {
        var total: Double = 0.0
        if let items = fetchItems() {
            items.forEach { entry in
                if Calendar.current.isDateInToday(entry.timestamp) {
                    total += entry.value
                }
            }
        }
        
        let entry = CarbClarityEntry(total: total)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let total = fetchItems()?
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.value } ?? 0.0

        let entry = CarbClarityEntry(total: total)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func fetchItems() -> [CarbEntry]? {
        let modelContext = ModelContext(sharedModelContainer)
        
        do {
            let items = try modelContext.fetch(FetchDescriptor<CarbEntry>())
            print("Widget fetched \(items.count) items")
            return items
        } catch {
            print("Error fetching products: \(error)")
            return nil
        }
    }
}

struct CarbClarityEntry: TimelineEntry {
    var date: Date = .now
    let total: Double
}

struct CarbClarityWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var size
    @AppStorage(AppSettings.SettingsKey.carbLimit.rawValue, store: AppSettings.sharedUserDefaults) var carbLimit = AppSettings.carbLimit
    @AppStorage(AppSettings.SettingsKey.cautionLimit.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimit = AppSettings.cautionLimit
    @AppStorage(AppSettings.SettingsKey.warnLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var warnLimitEnabled = AppSettings.warnLimitEnabled
    @AppStorage(AppSettings.SettingsKey.cautionLimitEnabled.rawValue, store: AppSettings.sharedUserDefaults) var cautionLimitEnabled = AppSettings.cautionLimitEnabled
    
    private let viewModel = CarbClarityWidgetViewModel()
    
    private var carbDisplayColor: CarbClarityWidgetViewModel.CarbDisplayColor {
        viewModel.getCarbDisplayColor(
            total: entry.total,
            carbLimit: carbLimit,
            cautionLimit: cautionLimit,
            warnLimitEnabled: warnLimitEnabled,
            cautionLimitEnabled: cautionLimitEnabled
        )
    }
    
    var body: some View {
        let carbString = entry.total.carbString()
        
        switch size {
            #if os(iOS)
            case .systemSmall:
                smallWidget(carbString: carbString, displayColor: carbDisplayColor)
            case .systemMedium:
                mediumWidget(carbString: carbString, displayColor: carbDisplayColor)
            case .systemLarge:
                largeWidget(carbString: carbString, displayColor: carbDisplayColor)
            #endif
            case .accessoryCircular:
                accessoryCircularWidget(carbString: carbString, value: entry.total, max: carbLimit)
            case .accessoryRectangular:
                accessoryRectangularWidget(carbString: carbString, displayColor: carbDisplayColor)
            case .accessoryInline:
                accessoryInlineWidget(carbString: carbString)
            #if os(watchOS)
            case .accessoryCorner:
                accessoryCornerWidget(carbString: carbString, displayColor: carbDisplayColor)
            #endif
            default:
                #if os(iOS)
                smallWidget(carbString: carbString, displayColor: carbDisplayColor)
                #else
                accessoryCircularWidget(carbString: carbString, value: entry.total, max: carbLimit)
                #endif
        }
    }
    
    @ViewBuilder
    func accessoryCircularWidget(carbString: String, value: Double, max: Double) -> some View {
        Gauge(value: value, in: 0...max) {
            Text("CHO")
        } currentValueLabel: {
            Text(viewModel.formatGaugeValue(value))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(AngularGradient(colors: [.green, .yellow, .red],
                              center: .bottom))
        .widgetAccentable()
    }
    
    #if os(iOS)
    @ViewBuilder
    func smallWidget(carbString: String, displayColor: CarbClarityWidgetViewModel.CarbDisplayColor) -> some View {
        VStack {
            Text("Today's carbs")
                .multilineTextAlignment(.center)
            .padding(.top)
            Text(carbString)
                .padding(.horizontal, 10)
                .font(.system(size: 150))
                .minimumScaleFactor(0.1)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .foregroundColor(displayColor.color)
        }
    }
    
    @ViewBuilder
    func mediumWidget(carbString: String, displayColor: CarbClarityWidgetViewModel.CarbDisplayColor) -> some View {
        HStack {
            if viewModel.shouldShowWarningIcon(displayColor) {
                Text("⚠️")
                    .font(.system(size: 150))
                    .minimumScaleFactor(0.01)
                    .foregroundStyle(Color.red)
                    .padding()
            }
            VStack {
                Text("Today's carbs")
                    .multilineTextAlignment(.center)
                    .padding(.top)
                Text(carbString)
                    .padding(.horizontal, 10)
                    .font(.system(size: 150))
                    .minimumScaleFactor(0.1)
                    .fontWeight(.heavy)
                    .multilineTextAlignment(.center)
                    .foregroundColor(displayColor.color)
            }
        }
    }
    
    @ViewBuilder
    func largeWidget(carbString: String, displayColor: CarbClarityWidgetViewModel.CarbDisplayColor) -> some View {
        VStack {
            if viewModel.shouldShowWarningIcon(displayColor) {
                Text(viewModel.getWarningMessage())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.red)
                    .padding()
            }
            Text("Today's carbs")
                .multilineTextAlignment(.center)
                .padding(.top)
            Text(carbString)
                .padding(.horizontal, 10)
                .font(.system(size: 150))
                .minimumScaleFactor(0.1)
                .fontWeight(.heavy)
                .multilineTextAlignment(.center)
                .foregroundColor(displayColor.color)
        }
    }
    #endif
    
    @ViewBuilder
    func accessoryRectangularWidget(carbString: String, displayColor: CarbClarityWidgetViewModel.CarbDisplayColor) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Carbs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.shouldShowWarningIcon(displayColor) {
                    Text("⚠️")
                        .font(.caption2)
                }
            }
            HStack {
                Text(carbString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(displayColor.color)
            }
        }
    }
    
    @ViewBuilder
    func accessoryInlineWidget(carbString: String) -> some View {
        HStack {
            Text("Carbs:")
                .font(.caption)
            Text(carbString)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    #if os(watchOS)
    @ViewBuilder
    func accessoryCornerWidget(carbString: String, displayColor: CarbClarityWidgetViewModel.CarbDisplayColor) -> some View {
        VStack(spacing: 1) {
            Text(carbString)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(displayColor.color)
            Text("Carbs:")
                .font(.caption)
        }
    }
    #endif
}

struct CarbClarityWidget: Widget {
    let kind: String = "CarbClarityWidget"
    
    private var platformSpecificFamilies: [WidgetFamily] {
        #if os(iOS)
        return [.systemSmall, .systemMedium, .systemLarge]
        #elseif os(watchOS)
        return [.accessoryCorner]
        #else
        return []
        #endif
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CarbClarityWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Carb Clarity")
        .description("A widget showing today's total carbs.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ] + platformSpecificFamilies)
    }
}
