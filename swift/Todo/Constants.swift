//
//  Constants.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 8/7/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

// Property Expression:

let ID = Meta.id
let CREATED_AT = Expression.property("createdAt")
let COMPLETE = Expression.property("complete")
let NAME = Expression.property("name")
let TASK = Expression.property("task")
let TASK_LIST_ID = Expression.property("taskList.id")
let TYPE = Expression.property("type")
let USERNAME = Expression.property("username")

// SelectResult:

let S_ID = SelectResult.expression(ID)
let S_COMPLETE = SelectResult.expression(COMPLETE)
let S_COUNT = SelectResult.expression(Function.count(Expression.int(1)))
let S_IMAGE = SelectResult.property("image")
let S_NAME = SelectResult.expression(NAME)
let S_TASK = SelectResult.expression(TASK)
let S_TASK_LIST_ID = SelectResult.expression(TASK_LIST_ID)
let S_USERNAME = SelectResult.expression(USERNAME)

// Config Keys

let HAS_SETTINGS_KEY = "settings.hasSettings"
let IS_LOGGING_KEY = "settings.isLoggingEnabled"
let IS_LOGIN_FLOW_KEY = "settings.isLoginFlowEnabled"
let IS_SYNC_KEY = "settings.isSyncEnabled"
let IS_PUSH_NOTIFICATION_ENABLED_KEY = "settings.isPushNotificationEnabled"
let IS_CCR_ENABLED_KEY = "settings.isCCREnabled"
let CCR_TYPE_KEY = "settings.ccrType"
let MAX_RETRY_KEY = "setting.maxRetry"
let MAX_RETRY_WAIT_TIME_KEY = "setting.maxRetryWaitTime"
