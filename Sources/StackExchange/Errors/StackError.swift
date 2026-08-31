//
//  StackError.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What can go wrong asking Stack Exchange.
public enum StackError: Error, LocalizedError, Sendable, Equatable {
    /// The query could not be turned into a request.
    case badQuery(String)
    /// The API answered with an HTTP failure.
    case http(Int)
    /// The API is throttling; wait this many seconds if it said.
    case rateLimited(retryAfter: Int?)
    /// A response did not have the documented shape.
    case malformed(String)

    public var errorDescription: String? {
        switch self {
        case .badQuery(let q): return "\(q) is not a query a request can be made from"
        case .http(let code): return "the API answered HTTP \(code)"
        case .rateLimited(let after):
            return "the API is throttling" + (after.map { " (wait \($0)s)" } ?? "")
        case .malformed(let what): return "unexpected response shape: \(what)"
        }
    }
}
