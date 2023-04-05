//
// AppController.swift
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

import os
import SwiftUI

// Logout Method
enum LogoutMethod {
    case closeDatabase, deleteDatabase;
}

class AppController {
    public static let logger = Logger()
    
    /// This function doesn't do the real authentication with SG. If the authentication fails, the
    /// app can still be using but there will be no replication.
    public static func login(_ username: String, _ password: String) throws {
        Session.shared.start(username, password)
        try AppLogic.shared.open()
        if Config.shared.syncEnabled {
            try AppLogic.shared.startReplicator()
        }
    }
    
    public static func logout(method: LogoutMethod) {
        let startTime = Date().timeIntervalSinceReferenceDate
        if method == .closeDatabase {
            do {
                try AppLogic.shared.close()
            } catch let error as NSError {
                logger.log("Cannot close database: \(error.localizedDescription)")
                return
            }
        } else if method == .deleteDatabase {
            do {
                try AppLogic.shared.delete()
            } catch let error as NSError {
                logger.log("Cannot delete database: \(error.localizedDescription)")
                return
            }
        }
        
        let endTime = Date().timeIntervalSinceReferenceDate
        logger.log("Logout took in \(endTime - startTime) seconds")
        
        Session.shared.end()
    }
}
