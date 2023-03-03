//
//  TodoApp.swift
//  Todo
//
//  Created by Callum Birks on 13/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI
import CouchbaseLiteSwift

@main
struct TodoApp: SwiftUI.App {
    init() {
        if Config.shared.loggingEnabled {
            Database.log.console.level = .info
        }
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .previewInterfaceOrientation(.portrait)
        }
    }
    
    
    enum Views {
        case login
        case tasklists
        case tasks
        case taskimage
        case users
        case settings
    }
}
