//
//  DogLogger.swift
//  Todo
//
//  Created by Pasin Suriyentrakorn on 6/16/20.
//  Copyright © 2020 Couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

func logTaskList(doc: Document, database: Database) throws {
    let tasksQuery = QueryBuilder
        .select(S_ID)
        .from(DataSource.database(database))
        .where(TYPE.equalTo(Expression.string("task")).and(TASK_LIST_ID.equalTo(Expression.string(doc.id))))
        .orderBy(Ordering.expression(CREATED_AT), Ordering.expression(TASK))
    let tasks = try tasksQuery.execute().allResults()
    
    let usersQuery = QueryBuilder
        .select(S_ID)
        .from(DataSource.database(database))
        .where(TYPE.equalTo(Expression.string("task-list.user")).and(TASK_LIST_ID.equalTo(Expression.string(doc.id))))
    let users = try usersQuery.execute().allResults()
    
    print(">>>>>>>> TASK LIST LOG START <<<<<<<<")
    print("")
    print("Task List Doc: \(taskListBody(doc: doc))")
    print("")
    print("Number of Tasks: \(tasks.count)")
    print("")
    var i = 0;
    for task in tasks {
        i = i + 1;
        if let taskDoc = database.document(withID: task.string(at: 0)!) {
            print("> Task Doc #\(i) : \(taskBody(doc: taskDoc))");
        } else {
            print("> Task Doc #\(i) : << N/A >>")
        }
        print("")
    }
    
    print("Number of Users: \(users.count)");
    print("")
    i = 0;
    for user in users {
        i = i + 1;
        if let userDoc = database.document(withID: user.string(at: 0)!) {
            print("> User Doc #\(i) : \(userBody(doc: userDoc))");
        } else {
            print("> User Doc #\(i) : << N/A >>")
        }
        print("")
    }
}

func logTask(doc: Document) {
    print(">>>>>>>> TASK LOG START <<<<<<<<");
    print("")
    print("> Task Doc: \(taskBody(doc: doc))");
    print("")
    print(">>>>>>>> TASK LOG END <<<<<<<<");
}

func taskListBody(doc: Document) -> Dictionary<String, Any> {
    var body = doc.toDictionary()
    body["_id"] = doc.id
    return body
}

func taskBody(doc: Document) -> Dictionary<String, Any> {
    var body = doc.toDictionary()
    body["_id"] = doc.id
    if let blob = body["image"] as? Blob {
        body["iamge"] = blob.properties
    }
    return body
}

func userBody(doc: Document) -> Dictionary<String, Any> {
    var body = doc.toDictionary()
    body["_id"] = doc.id
    return body
}
