//
//  QuickAddButtonView.swift
//  CarbClarity
//
//  Created by René Fouquet on 08.08.25.
//

import SwiftUI

struct QuickAddButton: View {
    let value: Double
    let viewModel: MainViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                _ = viewModel.quickAdd(value)
            }
        }) {
            Text(value.carbString())
                .font(.system(size: 16, weight: .semibold))
                .frame(minWidth: 60, minHeight: 44)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickAddButtonsView: View {
    let viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(maximum: 68)), count: 3), spacing: 16) {
                QuickAddButton(value: 0.1, viewModel: viewModel)
                QuickAddButton(value: 0.5, viewModel: viewModel)
                QuickAddButton(value: 1, viewModel: viewModel)
                QuickAddButton(value: 4, viewModel: viewModel)
                QuickAddButton(value: 6, viewModel: viewModel)
                QuickAddButton(value: 10, viewModel: viewModel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    QuickAddButtonsView(viewModel: MainViewModel())
        .padding()
}
