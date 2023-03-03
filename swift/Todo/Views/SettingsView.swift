//
//  SettingsView.swift
//  Todo
//
//  Created by Callum Birks on 16/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State var loggingEnabled = Config.shared.loggingEnabled
    @State var syncEnabled = Config.shared.syncEnabled
    @State var syncURL = Config.shared.syncURL
    @State var pushNotificationEnabled = Config.shared.pushNotificationEnabled
    @State var ccrEnabled = Config.shared.ccrEnabled
    @State var ccrType = Config.shared.ccrType
    @State var maxAttempts = Config.shared.maxAttempts
    @State var maxAttemptWaitTime = Config.shared.maxAttemptWaitTime
    
    init() {
        guard UserDefaults.standard.bool(forKey: HAS_SETTINGS_KEY)
        else {
            fatalError("Failed to load settings from UserDefaults")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Logging:", isOn: $loggingEnabled)
                Section {
                    Toggle("Sync:", isOn: $syncEnabled)
                    TextField("Sync Endpoint", text: $syncURL)
                        .textFieldStyle(.roundedBorder)
                }
                Toggle("Push notification:", isOn: $pushNotificationEnabled)
                Section {
                    Toggle("CCR:", isOn: $ccrEnabled)
                    Picker("CCR Type", selection: $ccrType) {
                        ForEach(CCRType.allCases, id: \.self) {
                            Text($0.description())
                        }
                    }
                    .pickerStyle(.segmented)
                }
                LabeledContent("Max Attempts:") {
                    TextField("Max attempts", value: $maxAttempts, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Max Wait Time:") {
                    TextField("Max attempt wait time", value: $maxAttemptWaitTime, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                }
            }
            .scrollDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        let config = Config.shared
        config.loggingEnabled = loggingEnabled
        config.syncEnabled = syncEnabled
        config.syncURL = syncURL
        config.pushNotificationEnabled = pushNotificationEnabled
        config.ccrEnabled = ccrEnabled
        config.ccrType = ccrType
        config.maxAttempts = maxAttempts
        config.maxAttemptWaitTime = maxAttemptWaitTime
        config.save()
        AppController.logout(method: .closeDatabase)
        dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
