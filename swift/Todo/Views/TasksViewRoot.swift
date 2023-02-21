//
//  TasksViewRoot.swift
//  Todo
//
//  Created by Callum Birks on 20/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI
import CouchbaseLiteSwift

private enum Filters {
    case tasks
    case users
}
// Essentially a wrapper around TasksView and UsersView to allow the bottom navigation bar
struct TasksViewRoot: View {
    @State fileprivate var selectedFilter: Filters = .tasks
    private let taskListID: String
    private var taskListDoc: Document {
        TodoController.getTaskListDoc(fromID: self.taskListID)
    }
    
    init(taskListID: String) {
        self.taskListID = taskListID
    }
    
    var body: some View {
        NavigationStack {
            if selectedFilter == .tasks {
                TasksView(taskListID: self.taskListID)
            } else {
                UsersView(taskListID: self.taskListID)
            }
        }
        .toolbar {
            // Tasks or User display filter
            ToolbarItemGroup(placement: .bottomBar) {
                FilterToolbar(selectedFilter: $selectedFilter,
                              thisUserOwns: Session.shared.username == taskListDoc.string(forKey: "owner")!)
            }
        }
    }
}

struct FilterToolbar : View {
    @Binding fileprivate var selectedFilter: Filters
    fileprivate let thisUserOwns: Bool
    var body: some View {
        Spacer()
        Button {
            selectedFilter = .tasks
        } label: {
            VStack {
                Image(systemName: "checklist")
                Text("Tasks")
            }
            .foregroundColor(selectedFilter == .tasks ? .blue : .gray)
        }
        .disabled(selectedFilter == .tasks)
        Spacer()
        if thisUserOwns {
            Button {
                selectedFilter = .users
            } label: {
                VStack {
                    Image(systemName: "person.crop.circle")
                    Text("Users")
                }
                .foregroundColor(selectedFilter == .users ? .blue : .gray)
            }
            .disabled(selectedFilter == .users)
            Spacer()
        }
    }
}
