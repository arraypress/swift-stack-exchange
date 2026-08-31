//
//  StackExchange.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//
//  Stack Exchange's API, keyless: 300 requests per IP per day, gzip on
//  the wire (URLSession inflates it), and a `backoff` field the API uses
//  to ask for patience. The quota and the backoff are surfaced, never
//  swallowed — an agent budgeting its day needs the numbers.
//

import Foundation

/// A keyless Stack Exchange client.
public struct StackExchange: Sendable {

    /// How requests are performed — injectable so tests run on recordings.
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    /// Identify yourself; polite callers keep keyless endpoints keyless.
    public static let defaultUserAgent = "swift-stack-exchange/0.1 (+https://github.com/arraypress/swift-stack-exchange)"

    private let userAgent: String
    private let transport: Transport

    /// A client. Leave `transport` nil for the shared URLSession.
    public init(userAgent: String = StackExchange.defaultUserAgent, transport: Transport? = nil) {
        self.userAgent = userAgent
        self.transport = transport ?? { request in
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw StackError.malformed("not an HTTP response")
            }
            return (data, http)
        }
    }

    // MARK: - Search

    /// Questions matching `query`, most relevant first, with readable excerpts.
    public func search(_ query: String, site: String = "stackoverflow",
                       limit: Int = 5) async throws -> Answered<[Question]> {
        struct Item: Decodable {
            let question_id: Int, title: String, score: Int, is_answered: Bool
            let accepted_answer_id: Int?, answer_count: Int, view_count: Int
            let link: String, body: String?, tags: [String]
        }
        guard let url = Endpoints.search(query, site: site, limit: limit) else {
            throw StackError.badQuery(query)
        }
        let (wrapper, data) = try await performWrapped(url)
        guard let items = try? JSONDecoder().decode(Envelope<Item>.self, from: data).items else {
            throw StackError.malformed("search/advanced items")
        }
        let questions = items.map { item in
            let plain = item.body.map(HTMLText.plain) ?? ""
            return Question(id: item.question_id, title: HTMLText.decodeEntities(item.title),
                            score: item.score, isAnswered: item.is_answered,
                            acceptedAnswerID: item.accepted_answer_id,
                            answerCount: item.answer_count, viewCount: item.view_count,
                            link: item.link, excerpt: String(plain.prefix(280)), tags: item.tags)
        }
        return Answered(items: questions, quotaRemaining: wrapper.quota_remaining, backoff: wrapper.backoff)
    }

    // MARK: - Answers

    /// A question's answers — the ACCEPTED one first, then by votes, bodies
    /// as readable text with code fenced.
    public func answers(for question: Int, site: String = "stackoverflow") async throws -> Answered<[Answer]> {
        struct Item: Decodable {
            let answer_id: Int, question_id: Int, score: Int, is_accepted: Bool
            let body: String?
            let owner: Owner?
            struct Owner: Decodable { let display_name: String? }
        }
        guard let url = Endpoints.answers(question: question, site: site) else {
            throw StackError.badQuery(String(question))
        }
        let (wrapper, data) = try await performWrapped(url)
        guard let items = try? JSONDecoder().decode(Envelope<Item>.self, from: data).items else {
            throw StackError.malformed("answers items")
        }
        let answers = items
            .map { item in
                Answer(id: item.answer_id, questionID: item.question_id, score: item.score,
                       isAccepted: item.is_accepted,
                       body: item.body.map(HTMLText.plain) ?? "",
                       author: HTMLText.decodeEntities(item.owner?.display_name ?? "unknown"))
            }
            .sorted { a, b in
                if a.isAccepted != b.isAccepted { return a.isAccepted }
                return a.score > b.score
            }
        return Answered(items: answers, quotaRemaining: wrapper.quota_remaining, backoff: wrapper.backoff)
    }

    // MARK: - Plumbing

    /// The API's common wrapper fields, decoded alongside the items.
    struct Wrapper: Decodable {
        let quota_remaining: Int?
        let backoff: Int?
        let error_id: Int?
        let error_name: String?
    }

    struct Envelope<Item: Decodable>: Decodable { let items: [Item] }

    func performWrapped(_ url: URL) async throws -> (Wrapper, Data) {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await transport(request)
        let wrapper = (try? JSONDecoder().decode(Wrapper.self, from: data))
            ?? Wrapper(quota_remaining: nil, backoff: nil, error_id: nil, error_name: nil)
        switch response.statusCode {
        case 200...299:
            return (wrapper, data)
        case 400 where wrapper.error_name == "throttle_violation":
            throw StackError.rateLimited(retryAfter: wrapper.backoff)
        case 429:
            throw StackError.rateLimited(retryAfter: wrapper.backoff)
        default:
            throw StackError.http(response.statusCode)
        }
    }
}
