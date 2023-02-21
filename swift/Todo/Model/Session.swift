//
// Session.swift
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

import Foundation

class Session : ObservableObject {
    private(set) var username: String = ""
    private(set) var password: String = ""
    var isLoggedIn: Bool {
        return !(username.isEmpty || password.isEmpty)
    }
    func start(_ username: String, _ password: String) {
        self.username = username
        self.password = password
        objectWillChange.send()
    }
    func end() {
        self.username = ""
        self.password = ""
        objectWillChange.send()
    }
    private(set) static var shared: Session = Session()
}
