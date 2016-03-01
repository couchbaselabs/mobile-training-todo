//
//  AppDelegate.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 2/8/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

import UIKit

let kLoginFlowEnabled = true
let kEncryptionEnabled = true
let kSyncEnabled = true
let kSyncGatewayUrl = NSURL(string: "http://10.17.2.133:4984/todo/")!
let kLoggingEnabled = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginViewControllerDelegate {
    var window: UIWindow?

    var database: CBLDatabase!
    var pusher: CBLReplication!
    var puller: CBLReplication!
    var syncError: NSError?
    var conflictsLiveQuery: CBLLiveQuery?

    // MARK: - Application Life Cycle
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if kLoggingEnabled {
            enableLogging()
        }
        
        if kLoginFlowEnabled {
            login()
        } else {
            do {
                try startSession(username: "todo")
            } catch let error as NSError {
                NSLog("Cannot start a session: %@", error)
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Logging
    func enableLogging() {
        CBLManager.enableLogging("CBLDatabase")
        CBLManager.enableLogging("View")
        CBLManager.enableLogging("ViewVerbose")
        CBLManager.enableLogging("Query")
        CBLManager.enableLogging("Sync")
        CBLManager.enableLogging("SyncVerbose")
    }
    
    // MARK: - Session
    
    func startSession(username username:String, withPassword password:String? = nil,
        withNewPassword newPassword:String? = nil) throws {
            try openDatabase(username: username, withKey: password, withNewKey: newPassword)
            Session.username = username
            startReplication(withUsername: username, andPassword: newPassword ?? password)
            showApp()
    }
    
    func openDatabase(username username:String, withKey key:String?,
        withNewKey newKey:String?) throws {
            let dbname = username
            let options = CBLDatabaseOptions()
            options.create = true

            if kEncryptionEnabled {
                if let encryptionKey = key {
                    options.encryptionKey = encryptionKey
                }
            }

            try database = CBLManager.sharedInstance().openDatabaseNamed(dbname, withOptions: options)
            if newKey != nil {
                try database.changeEncryptionKey(newKey)
            }
            startConflictLiveQuery()
    }
    
    func closeDatabase() throws {
        stopConflictLiveQuery()
        try database.close()
    }

    // MARK: - Login

    func login(username: String? = nil) {
        let storyboard =  window!.rootViewController!.storyboard
        let navigation = storyboard!.instantiateViewControllerWithIdentifier(
            "LoginNavigationController") as! UINavigationController
        let loginController = navigation.topViewController as! LoginViewController
        loginController.delegate = self
        loginController.username = username
        window!.rootViewController = navigation
    }

    func logout() {
        stopReplication()
        do {
            try closeDatabase()
        } catch let error as NSError {
            NSLog("Cannot close database: %@", error)
        }
        let oldUsername = Session.username
        Session.username = nil
        login(oldUsername)
    }

    func showApp() {
        guard let root = window?.rootViewController, storyboard = root.storyboard else {
            return
        }

        let controller = storyboard.instantiateInitialViewController()
        window!.rootViewController = controller
    }

    // MARK: - LoginViewControllerDelegate

    func login(controller: UIViewController, withUsername username: String,
        andPassword password: String) {
            processLogin(controller, withUsername: username, withPassword: password)
    }

    func processLogin(controller: UIViewController, withUsername username: String,
        withPassword password: String, withNewPassword newPassword: String? = nil) {
            do {
                try startSession(username: username, withPassword: password,
                    withNewPassword: newPassword)
            } catch let error as NSError {
                if error.code == 401 {
                    handleEncryptionError(controller, withUsername: username,
                        withPassword: password)
                } else {
                    Ui.showMessageDialog(
                        onController: controller,
                        withTitle: "Error",
                        withMessage: "Login has an error occurred, code = \(error.code).")
                    NSLog("Cannot start a session: %@", error)
                }
            }
    }

    func handleEncryptionError(controller: UIViewController, withUsername username: String,
        withPassword password: String) {
            Ui.showEncryptionErrorDialog(
                onController: controller,
                onMigrateAction: { oldPassword in
                    self.processLogin(controller, withUsername: username,
                        withPassword: oldPassword, withNewPassword: password)
                },
                onDeleteAction: {
                    // Delete database:
                    self.deleteDatabase(username)
                    // login:
                    self.processLogin(controller, withUsername: username,
                        withPassword: password)
                }
            )
    }

    func deleteDatabase(dbName: String) {
        // Delete the database by using file manager. Currently CBL doesn't have
        // an API to delete an encrypted database so we remove the database
        // file manually as a workaround.
        let dir = NSURL(fileURLWithPath: CBLManager.sharedInstance().directory)
        let dbFile = dir.URLByAppendingPathComponent("\(dbName).cblite2")
        do {
            try NSFileManager.defaultManager().removeItemAtURL(dbFile)
        } catch let err as NSError {
            NSLog("Error when deleting the database file: %@", err)
        }

    }

    // MARK: - Replication

    func startReplication(withUsername username:String, andPassword password:String? = "") {
        guard kSyncEnabled else {
            return
        }

        var authenticator: CBLAuthenticatorProtocol?
        var headers: [String: String]?
        if kLoginFlowEnabled {
            authenticator = CBLAuthenticator.basicAuthenticatorWithName(username, password: password!)

            // Workaround #1124:
            // https://github.com/couchbase/couchbase-lite-ios/issues/1124
            let cred = NSString(format: "%@:%@", username, password!)
            let credData = cred.dataUsingEncoding(NSUTF8StringEncoding)!
            let credBase64 = credData.base64EncodedStringWithOptions([])
            headers = ["Authorization": "Basic \(credBase64)"]
        }
        
        syncError = nil
        
        pusher = database.createPushReplication(kSyncGatewayUrl)
        pusher.continuous = true
        pusher.authenticator = authenticator
        pusher.headers = headers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:",
            name: kCBLReplicationChangeNotification, object: pusher)

        puller = database.createPullReplication(kSyncGatewayUrl)
        puller.continuous = true
        puller.customProperties = ["websocket": false]
        puller.authenticator = authenticator
        puller.headers = headers

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationProgress:",
            name: kCBLReplicationChangeNotification, object: puller)

        pusher.start()
        puller.start()
    }
    
    func stopReplication() {
        guard kSyncEnabled else {
            return
        }

        pusher.stop()
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kCBLReplicationChangeNotification, object: pusher)
        
        puller.stop()
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kCBLReplicationChangeNotification, object: puller)
    }
    
    func replicationProgress(notification: NSNotification) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible =
            (pusher.status == .Active || puller.status == .Active)

        let error = pusher.lastError ?? puller.lastError
        if (error != syncError) {
            syncError = error
            if let errorCode = error?.code {
                NSLog("Replication Error: %@", error!)
                if errorCode == 401 {
                    Ui.showMessageDialog(
                        onController: self.window!.rootViewController!,
                        withTitle: "Authentication Error",
                        withMessage:"Your username or password is not correct.",
                        withError: nil,
                        onClose: {
                            self.logout()
                    })
                }
            }
        }
    }

    // MARK: - Conflicts Resolution

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
        change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
            if object as? NSObject == conflictsLiveQuery {
                resolveConflicts()
            }
    }

    func startConflictLiveQuery() {
        conflictsLiveQuery = database.createAllDocumentsQuery().asLiveQuery()
        conflictsLiveQuery!.allDocsMode = .OnlyConflicts
        conflictsLiveQuery!.addObserver(self, forKeyPath: "rows", options: .New, context: nil)
        conflictsLiveQuery!.start()
    }

    func stopConflictLiveQuery() {
        conflictsLiveQuery?.removeObserver(self, forKeyPath: "rows")
        conflictsLiveQuery?.stop()
        conflictsLiveQuery = nil
    }

    func resolveConflicts() {
        let rows = conflictsLiveQuery?.rows
        while let row = rows?.nextRow() {
            if let revs = row.conflictingRevisions where revs.count > 1 {
                resolveConflicts(revisions: revs)
            }
        }
    }

    func resolveConflicts(revisions revs: [CBLRevision]) {
        let defaultWinning = revs[0]
        let type = (defaultWinning["type"] as? String) ?? ""
        switch type {
        case "task-list", "task-list.user":
            let props = defaultWinning.userProperties
            let image = defaultWinning.attachmentNamed("image")
            resolveConflicts(revisions: revs, withProps: props, andImage: image)
        case "task":
            let merged = nWayMergeConflicts(revs)
            resolveConflicts(revisions: revs, withProps: merged.props, andImage: merged.image)
        default:
            break
        }
    }

    func resolveConflicts(revisions revs: [CBLRevision], withProps props: [String: AnyObject]?,
        andImage image: CBLAttachment?) {
            database.inTransaction {
                var i = 0
                for rev in revs as! [CBLSavedRevision] {
                    let newRev = rev.createRevision()
                    if (i == 0) { // Default winning revision
                        newRev.userProperties = props
                        if rev.attachmentNamed("image") != image {
                            newRev.setAttachmentNamed("image", withContentType: "image/jpg",
                                content: image?.content)
                        }
                    } else {
                        newRev.isDeletion = true
                    }

                    do {
                        try newRev.saveAllowingConflict()
                    } catch let error as NSError {
                        NSLog("Cannot resolve conflicts with error: %@", error)
                        return false
                    }
                    i += 1
                }
                return true
            }
    }

    func nWayMergeConflicts(revs: [CBLRevision]) ->
        (props: [String: AnyObject]!, image: CBLAttachment?) {
            guard let parent = findCommonParent(revs) else {
                let defaultWinning = revs[0]
                let props = defaultWinning.userProperties
                let image = defaultWinning.attachmentNamed("image")
                return (props, image)
            }

            var mergedProps = parent.userProperties ?? [:]
            var mergedImage = parent.attachmentNamed("image")
            var gotTask = false, gotComplete = false, gotImage = false
            for rev in revs {
                if let props = rev.userProperties {
                    if !gotTask {
                        let task = props["task"] as? String
                        if task != mergedProps["task"] as? String {
                            mergedProps["task"] = task
                            gotTask = true
                        }
                    }

                    if !gotComplete {
                        let complete = props["complete"] as? Bool
                        if complete != mergedProps["complete"] as? Bool {
                            mergedProps["complete"] = complete
                            gotComplete = true
                        }
                    }
                }

                if !gotImage {
                    let attachment = rev.attachmentNamed("image")
                    let attachmentDiggest = attachment?.metadata["digest"] as? String
                    if (attachmentDiggest != mergedImage?.metadata["digest"] as? String) {
                        mergedImage = attachment
                        gotImage = true
                    }
                }

                if gotTask && gotComplete && gotImage {
                    break
                }
            }
            return (mergedProps, mergedImage)
    }

    func findCommonParent(revisions: [CBLRevision]) -> CBLRevision? {
        var minHistoryCount = 0
        var histories : [[CBLRevision]] = []
        for rev in revisions {
            let history = (try? rev.getRevisionHistory()) ?? []
            histories.append(history)
            minHistoryCount =
                minHistoryCount > 0 ? min(minHistoryCount, history.count) : history.count
        }

        if minHistoryCount == 0 {
            return nil
        }

        var commonParent : CBLRevision? = nil
        for i in 0...minHistoryCount {
            var rev: CBLRevision? = nil
            for history in histories {
                if rev == nil {
                    rev = history[i]
                } else if rev!.revisionID != history[i].revisionID {
                    rev = nil
                    break
                }
            }
            if rev == nil {
                break
            }
            commonParent = rev
        }

        if let deleted = commonParent?.isDeletion where deleted {
            commonParent = nil
        }
        return commonParent
    }
}
