//
// TasksViewRoot.swift
//
// Copyright (c) 2023 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

private enum Filters {
    case tasks
    case users
}

// Essentially a wrapper around TasksView and UsersView to allow the bottom navigation bar
struct TasksViewRoot: View {
    @State fileprivate var selectedFilter: Filters = .tasks
    
    private let taskList: TaskList
    
    init(taskList: TaskList) {
        self.taskList = taskList
    }
    
    var body: some View {
        NavigationStack {
            if selectedFilter == .tasks {
                TasksView(taskList: taskList)
            } else {
                UsersView(taskList: taskList)
            }
        }
        .toolbar {
            // Tasks or User display filter
            ToolbarItemGroup(placement: .bottomBar) {
                FilterToolbar(selectedFilter: $selectedFilter, thisUserOwns: Session.shared.username == taskList.owner)
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
