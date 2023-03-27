//
// SGAdmin.swift
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

public class SGAdmin {
    public static let shared = SGAdmin()
    
    private init() { }
    
    public func createRole(_ role: String) async throws {
        let body: [String : Any] = [
            "name": role,
            "collection_access": [
                "_default": [
                    "lists": ["admin_channels": []],
                    "tasks": ["admin_channels": []],
                    "users": ["admin_channels": []]
                ]
            ]
        ]
        let (_, response) = try await sendJSONRequest(method: "POST", path: "_role", body: body)
        try checkError(for: "Create Role '\(role)'", response: response)
    }
    
    // MARK: Utils
    
    private func adminURL(path: String) -> URL {
        var comps = URLComponents(string: Config.shared.syncURL)!
        comps.scheme = comps.scheme! == "wss" ? "https" : "http"
        comps.port = Config.shared.syncAdminPort
        comps.path = (comps.path as NSString).appendingPathComponent(path)
        if path.hasSuffix("/") && !comps.path.hasSuffix("/") {
            comps.path = comps.path + "/" // Important to SG for some requests
        }
        return comps.url!
    }
    
    private func adminAuthHeader() -> String {
        let auth = String(format: "%@:%@", Config.shared.syncAdminUsername, Config.shared.syncAdminPassword)
        let authBase64 = auth.data(using: String.Encoding.utf8)!.base64EncodedString()
        return "Basic \(authBase64)"
    }
    
    private func sendJSONRequest(method: String, path: String, body: [String : Any]?) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: adminURL(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(adminAuthHeader(), forHTTPHeaderField: "Authorization")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await URLSession.shared.data(for: request, delegate: RedirectDelegate(for: request))
    }
    
    private func statusCode(_ response: URLResponse) -> (Int, Bool) {
        let code = (response as! HTTPURLResponse).statusCode
        return (code, code < 300)
    }
    
    private func checkError(for name: String, response: URLResponse) throws {
        let (code, ok) = statusCode(response)
        AppController.logger.log("[Todo] \(name) \(ok ? "Success" : "Error") : \(code)")
        if (!ok) {
            throw AppLogicError.sgError(code)
        }
    }
}

/// By default URLSession will redirect with a new /GET request. RedirectDelegate will preserve the original request and alter only the url.
fileprivate class RedirectDelegate : NSObject, URLSessionTaskDelegate {
    let originalRequest: URLRequest
    
    init(for request: URLRequest) {
        self.originalRequest = request
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest) async -> URLRequest? {
        var redirect = originalRequest
        redirect.url = request.url
        return redirect
    }
}
