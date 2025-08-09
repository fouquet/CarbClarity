//
//  PrivacyView.swift
//  CarbClarity
//
//  Created by René Fouquet on 10.06.24.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                Text("""
                     **Introduction**

                     I am committed to protecting the privacy of my users. This Privacy Policy explains how I handle and safeguard your personal information.

                     **Information Collected**

                     Carb Clarity stores the carbohydrate values you enter into the app, along with timestamps. This data is stored locally on your device and may be synced across your devices using iCloud, a service provided by Apple.

                     **How Your Information Is Used**

                     The carbohydrate values you enter are used solely to provide the core functionality of the Carb Clarity app—tracking and displaying your carbohydrate intake. This data is not used for any other purpose.

                     **iCloud Syncing**

                     Carb Clarity uses iCloud syncing, a service provided by Apple, to enable data synchronization across multiple devices. While Carb Clarity does not directly collect your data, I recommend reviewing Apple’s Privacy Policy to understand how Apple handles your information during iCloud syncing.

                     **Third-Party Services**

                     Carb Clarity does not use any third-party services that collect or process your personal data.

                     **Food Lookup**

                     Carb Clarity includes a feature called Food Lookup, which allows you to search for carbohydrate values in the USDA Food Database. When you use this feature, your search queries are sent to the USDA’s servers. No personally identifiable information is included in these requests. The results returned by the USDA are used only to help you log carbohydrate values and are not stored or shared beyond your device unless you enable iCloud syncing.

                     **Your Rights**

                     Since Carb Clarity stores your data locally on your device, you have full control over it. You can access, modify, or delete your data within the app or by uninstalling it. If you use iCloud syncing, you can also manage your data through your iCloud settings.

                     **Contact**

                     If you have any questions or concerns about this Privacy Policy, feel free to contact me at support@fouquet.me.

                     Date: July 20, 2025.
                     """)
                .padding()
            }
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    PrivacyView()
}
