//
//  Question.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One question, as search returns it.
public struct Question: Codable, Sendable, Equatable {
    /// The site's question id — what ``StackExchange/answers(for:site:)`` takes.
    public let id: Int
    /// The title, HTML entities decoded.
    public let title: String
    /// Vote score.
    public let score: Int
    /// Whether the site considers it answered.
    public let isAnswered: Bool
    /// The accepted answer's id, when one was accepted.
    public let acceptedAnswerID: Int?
    /// How many answers it has.
    public let answerCount: Int
    /// How many times it was viewed.
    public let viewCount: Int
    /// The question page.
    public let link: String
    /// The question body as readable plain text, truncated for listings.
    public let excerpt: String
    /// The question's tags.
    public let tags: [String]

    public init(id: Int, title: String, score: Int, isAnswered: Bool, acceptedAnswerID: Int?,
                answerCount: Int, viewCount: Int, link: String, excerpt: String, tags: [String]) {
        self.id = id
        self.title = title
        self.score = score
        self.isAnswered = isAnswered
        self.acceptedAnswerID = acceptedAnswerID
        self.answerCount = answerCount
        self.viewCount = viewCount
        self.link = link
        self.excerpt = excerpt
        self.tags = tags
    }
}
