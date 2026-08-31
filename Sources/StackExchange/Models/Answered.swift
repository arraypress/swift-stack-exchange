//
//  Answered.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A response plus the API's own budget bookkeeping — the free tier is
/// 300 requests per IP per day, and pretending otherwise helps nobody.
public struct Answered<Rows: Sendable & Equatable>: Sendable, Equatable {
    /// The rows themselves.
    public let items: Rows
    /// Requests left in today's quota, as the API reported it.
    public let quotaRemaining: Int?
    /// Seconds the API asked callers to back off before the next request,
    /// when it did.
    public let backoff: Int?

    public init(items: Rows, quotaRemaining: Int?, backoff: Int?) {
        self.items = items
        self.quotaRemaining = quotaRemaining
        self.backoff = backoff
    }
}
