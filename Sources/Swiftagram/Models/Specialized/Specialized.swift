//
//  Specialized.swift
//  Swiftagram
//
//  Created by Stefano Bertagno on 26/08/20.
//

import Foundation

/// A `protocol` describing a generic response returning an element of `Response`.
public protocol Specialized: Wrapped {
    /// An optional `ResponseError` message returned by a response.
    /// Default emplementation returns failing description, if it exists,
    /// otherwise `.unknown` if `status` is not `ok`, and `nil` if it is.
    var error: ResponseError? { get }
}

public extension Specialized {
    /// The response status.
    @available(*, deprecated, message: "check for `error` instead")
    var status: String! { self["status"].string() }

    /// An optional `ResponseError` message returned by a response.
    /// It returns the failing description, if it exists, otherwise `.unknown` if `status` is not `ok`, and `nil` if it is.
    var error: ResponseError? {
        switch self["status"].string() {
        case "ok": return nil
        case "fail": return self["message"].string().flatMap(ResponseError.generic) ?? .unknown
        case let status: return .unforseen(status)
        }
    }
}