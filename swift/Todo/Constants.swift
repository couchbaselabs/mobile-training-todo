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
