//
//  Answer.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One answer, body already readable.
public struct Answer: Codable, Sendable, Equatable {
    /// The answer's id.
    public let id: Int
    /// The question it answers.
    public let questionID: Int
    /// Vote score.
    public let score: Int
    /// Whether the asker accepted it.
    public let isAccepted: Bool
    /// The body as plain text — tags stripped, entities decoded, code kept
    /// in fenced blocks so the fix stays copy-pasteable.
    public let body: String
    /// Who wrote it.
    public let author: String

    public init(id: Int, questionID: Int, score: Int, isAccepted: Bool, body: String, author: String) {
        self.id = id
        self.questionID = questionID
        self.score = score
        self.isAccepted = isAccepted
        self.body = body
        self.author = author
    }
}
