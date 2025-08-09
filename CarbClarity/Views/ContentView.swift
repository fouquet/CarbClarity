//
//  ContentView.swift
//  CarbClarity
//
//  Created by René Fouquet on 17.07.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TrackView()
                .tabItem {
                    Image(systemName: "plus.circle")
                        .accessibilityLabel("Track Tab")
                    Text("Track")
                }
                .accessibilityIdentifier("TrackTab")
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                        .accessibilityLabel("Insights Tab")
                    Text("Insights")
                }
                .accessibilityIdentifier("InsightsTab")
        }
        .accessibilityIdentifier("MainTabView")
    }
}

#Preview {
    ContentView()
}
