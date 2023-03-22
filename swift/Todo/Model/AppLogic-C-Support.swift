//
// AppLogic-C-Support.swift
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
import CouchbaseLite

public enum CouchbaseLiteError : Error {
    case cbl(Int, String)
    case posix (Int, String)
    case sqlite (Int, String)
    case fleece (Int, String)
    case network(Int, String)
    case websocket (Int, String)
}

public extension CBLError {
    func throwable() -> CouchbaseLiteError {
        var e = self;
        let code = Int(e.code)
        let message = CBLError_Message(&e).stringVal();

        switch e.domain {
            case .cblDomain: return .cbl(code, message)
            case .cblposixDomain: return .posix(code, message)
            case .cblsqLiteDomain: return .posix(code, message)
            case .cblFleeceDomain: return .fleece(code, message)
            case .cblNetworkDomain: return .network(code, message)
            case .cblWebSocketDomain: return .websocket(code, message)
            default: return .cbl(Int(CBLErrorCode.unexpectedError.rawValue), message)
        }
    }
}

public struct FLS {
    private let data: NSData
    
    public init(_ string: String) {
        data = string.data(using: .utf8)! as NSData
    }
    
    public init(_ data: Data) {
        self.data = data as NSData
    }
    
    public func sl() -> FLSlice {
        return FLSlice(buf: data.bytes, size: data.length)
    }
}

public extension FLSliceResult {
    func string(_ release: Bool = true) -> String? {
        defer { if release { FLSliceResult_Release(self) } }
        guard let buf = self.buf else { return nil }
        return NSString(bytes: buf, length: self.size, encoding: NSUTF8StringEncoding) as String?
    }
    
    func stringVal(_ release: Bool = true) -> String {
        return string(release) ?? ""
    }
    
    func data(_ release: Bool = true) -> Data? {
        defer { if release { FLSliceResult_Release(self) } }
        guard let buf = self.buf else { return nil }
        return Data.init(bytes: buf, count: self.size)
    }
}

extension FLSlice {
    func string() -> String {
        guard let buf = self.buf else { fatalError("Invalid string") }
        return NSString(bytes: buf, length: self.size, encoding: NSUTF8StringEncoding)! as String
    }
    
    func asData() -> Data? {
        guard let buf = self.buf else { return nil }
        return Data.init(bytes: buf, count: self.size)
    }
}

extension String {
    func withSlice<R>(_ block: (FLSlice) throws -> R) rethrows -> R {
        return try self.utf8.withContiguousStorageIfAvailable { bytes in
            return try block(FLSlice(buf: bytes.baseAddress, size: bytes.count))
        }!
    }
    
    func withSliceNoThrow<R>(_ block: (FLSlice) -> R) -> R {
        return self.utf8.withContiguousStorageIfAvailable { bytes in
            return block(FLSlice(buf: bytes.baseAddress, size: bytes.count))
        }!
    }
}
