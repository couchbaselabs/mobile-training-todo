//
//  LoginView.swift
//  Todo
//
//  Created by Callum Birks on 13/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import SwiftUI
import CouchbaseLiteSwift

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
            .padding(50)
            .navigationTitle("Login")
            .alert("Authentication Error", isPresented: $presentUnauthorized) {
                Button("OK", role: .cancel) {
                    try! DB.shared.close()
                }
            }
        }
    }
    
    private func login() {
        username = username.trimmingCharacters(in: .whitespaces)
        password = password.trimmingCharacters(in: .whitespaces)
        do {
            guard try AppController.startSession(username, password)
            else { self.loginFailed(); return }
        } catch {
            AppController.logger.log("\(error.localizedDescription)")
        }
    }
    
    private func loginFailed() {
        AppController.logout(method: .closeDatabase)
        presentUnauthorized = true
        self.password = ""
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
