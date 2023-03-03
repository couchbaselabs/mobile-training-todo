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
    @State var loggingEnabled: Bool = UserDefaults.standard.bool(forKey: IS_LOGGING_KEY)
    @State var syncEnabled: Bool = UserDefaults.standard.bool(forKey: IS_SYNC_KEY)
    @State var syncEndpoint: String = Config.shared.syncURL
    @State var pushNotificationEnabled: Bool = UserDefaults.standard.bool(forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
    @State var ccrEnabled: Bool = UserDefaults.standard.bool(forKey: IS_CCR_ENABLED_KEY)
    @State var ccrType: CCRType = CCRType(rawValue: UserDefaults.standard.integer(forKey: CCR_TYPE_KEY))!
    @State var maxAttempts: Int = UserDefaults.standard.integer(forKey: MAX_ATTEMPTS_KEY)
    @State var maxWaitTime: Int = UserDefaults.standard.integer(forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
    
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
                    TextField("Sync Endpoint", text: $syncEndpoint)
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
                    TextField("Max attempt wait time", value: $maxWaitTime, formatter: NumberFormatter())
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
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: HAS_SETTINGS_KEY)
        defaults.set(loggingEnabled, forKey: IS_LOGGING_KEY)
        defaults.set(syncEnabled, forKey: IS_SYNC_KEY)
        defaults.set(pushNotificationEnabled, forKey: IS_PUSH_NOTIFICATION_ENABLED_KEY)
        defaults.set(ccrEnabled, forKey: IS_CCR_ENABLED_KEY)
        defaults.set(ccrType.rawValue, forKey: CCR_TYPE_KEY)
        defaults.set(maxAttempts, forKey: MAX_ATTEMPTS_KEY)
        defaults.set(maxWaitTime, forKey: MAX_ATTEMPTS_WAIT_TIME_KEY)
        
        Config.shared.syncURL = syncEndpoint
        
        AppController.logout(method: .closeDatabase)
        dismiss()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
