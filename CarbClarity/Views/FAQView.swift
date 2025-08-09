//
//  PrivacyView.swift
//  CarbClarity
//
//  Created by René Fouquet on 10.06.24.
//

import SwiftUI

struct FAQView: View {
    private struct FAQQuestion: Identifiable {
        let question: String
        let answer: String
        var id: String { question }
    }
    
    private let questions: [FAQQuestion] = [
        FAQQuestion(
            question: "What does CHO stand for?",
            answer: "CHO is an abbreviation for carbohydrate, referencing its three elements: Carbon (C), Hydrogen (H), and Oxygen (O)."
        ),
        FAQQuestion(
            question: "What are the carb limits for?",
            answer: "There are two carb limits in the app:\n• Caution limit: A threshold close to your maximum daily intake. When this is reached, your total is highlighted in yellow.\n• Maximum limit: The highest amount of carbs you want to consume per day. For strict keto, this is typically below 20 grams, which is also the app’s default.\n\nYou can adjust both values freely. If you exceed the maximum, the app will highlight your total in red and show a warning."
        ),
        FAQQuestion(
            question: "The widgets are not updating",
            answer: "It can take a few minutes for iOS to refresh widget data, even if changes (like adding or deleting values) are made. This behavior is controlled by iOS.\n\nEven though the local widgets on each platform usually update immediatly, it can take a while until the widgets on the other platform (iOS or watchOS) are updated. Sometimes, opening the app will trigger a refresh. Unfortunately, this behaviour is non-deterministic and there is nothing developers can do about it.\n\nAvoid force-quitting Carb Clarity, as it may negatively affect widget updates."
        ),
        FAQQuestion(
            question: "How can I switch to imperial units?",
            answer: "Carb Clarity only supports metric units (grams). This is the global standard for measuring macronutrients, including in the US."
        ),
        FAQQuestion(
            question: "Can I track other macronutrients as well?",
            answer: "No. Carb Clarity is purpose-built for tracking carbohydrates only."
        ),
        FAQQuestion(
            question: "What is Food Lookup?",
            answer: "Food Lookup lets you search the USDA (U.S. Department of Agriculture) food database and quickly add carbohydrate values to your log.\nIt requires a free API key, which you can obtain from the USDA website."
        ),
        FAQQuestion(
            question: "I can't find a specific food in Food Lookup, or the carbohydrate values seem incorrect.",
            answer: "Carb Clarity relies solely on USDA data. If something seems wrong or missing, please report it directly to the USDA."
        )
    ]

    var body: some View {
        NavigationView {
            List {
                ForEach(questions) { faq in
                    faqView(title: faq.question, text: faq.answer)
                }
            }
        }
        .navigationTitle("FAQ")
    }
    
    @ViewBuilder
    func faqView(title: String, text: String) -> some View {
        Section {
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8.0)
                Text(text)
            }.padding()
        }
    }
}

#Preview {
    FAQView()
}
