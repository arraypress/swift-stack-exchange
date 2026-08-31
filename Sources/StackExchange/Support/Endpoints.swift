//
//  Endpoints.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//
//  The API's URL grammar in one testable place. `filter=withbody` is the
//  whole point: it is what puts answer bodies in the response so an
//  agent can read the fix instead of a link to it.
//

import Foundation

/// Stack Exchange API 2.3 URLs.
enum Endpoints {

    /// Relevance-ordered search with bodies included.
    static func search(_ query: String, site: String, limit: Int) -> URL? {
        var components = URLComponents(string: "https://api.stackexchange.com/2.3/search/advanced")!
        components.queryItems = [
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "sort", value: "relevance"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "site", value: site),
            URLQueryItem(name: "pagesize", value: String(min(max(limit, 1), 30))),
            URLQueryItem(name: "filter", value: "withbody"),
        ]
        return components.url
    }

    /// A question's answers, highest votes first, bodies included.
    static func answers(question: Int, site: String) -> URL? {
        var components = URLComponents(string: "https://api.stackexchange.com/2.3/questions/\(question)/answers")!
        components.queryItems = [
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "sort", value: "votes"),
            URLQueryItem(name: "site", value: site),
            URLQueryItem(name: "filter", value: "withbody"),
        ]
        return components.url
    }
}
