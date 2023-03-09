//
// LoginView.swift
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

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""
    @State var presentUnauthorized: Bool = false
    
    var loginDisabled: Bool {
        username.isEmpty || password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                TextField("Username", text: $username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                
                SecureField("Password", text: $password)
                    .onSubmit {
                        if(!loginDisabled) {
                            login()
                        }
                    }
                
                Button(action: login, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(loginDisabled ? .gray : .blue)
                            .foregroundStyle(.opacity(loginDisabled ? 0.8 : 1.0))
                        Text("Login")
                            .foregroundColor(.white)
                    }
                    .frame(maxHeight: 50)
                    .padding([.horizontal], 50)
                })
                .disabled(loginDisabled)
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Login")
        }
    }
    
    private func login() {
        username = username.trimmingCharacters(in: .whitespaces)
        password = password.trimmingCharacters(in: .whitespaces)
        do {
            try AppController.login(username, password)
        } catch {
            AppController.logger.log("\(error.localizedDescription)")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
