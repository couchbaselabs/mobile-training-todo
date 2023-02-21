//
//  ObservableQuery.swift
//  Todo
//
//  Created by Callum Birks on 15/02/2023.
//  Copyright © 2023 Couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

// A class made to hold a CBL Query and subscribe to its change listener
// The class is Observable, and will emit whenever the change listener emits
class ObservableQuery : ObservableObject {
    @Published var queryResults: [IResult]
    private let query: Query
    
    init(_ query: Query) {
        self.query = query
        self.queryResults = []
        self.query.addChangeListener({ (change) in
            if let error = change.error {
                AppController.logger.log("Error during query \(query.description): \(error.localizedDescription)")
            }
            if let results = change.results {
                self.queryResults = Array<IResult>(results.map({ IResult($0) }))
            } else {
                self.queryResults = []
            }
        })
    }
    
    // Wrapper around Result that conforms to identifiable so we can use it in a SwiftUI List
    struct IResult : Identifiable {
        public let id: UUID
        public let wrappedResult: CouchbaseLiteSwift.Result
        public var docID: String { // computed docID
            self.id.uuidString
        }
        
        init(_ cblResult: CouchbaseLiteSwift.Result) {
            self.wrappedResult = cblResult
            guard let docID = cblResult.string(at: 0)
            else {
                fatalError("Could not get docID from Query result")
            }
            guard let uuidFromStr = UUID(uuidString: docID)
            else {
                fatalError("UUID could not be constructed from string: \(docID)")
            }
            self.id = uuidFromStr
        }
    }
}
