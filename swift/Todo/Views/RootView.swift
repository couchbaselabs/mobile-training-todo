//
//  RootView.swift
//  Todo
//
//  Created by Callum Birks on 15/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @ObservedObject var session: Session = Session.shared
    
    var body: some View {
        if session.isLoggedIn {
            TaskListsView()
        } else {
            LoginView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
