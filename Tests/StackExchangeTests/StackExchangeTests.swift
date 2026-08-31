//
//  StackExchangeTests.swift
//  StackExchangeTests
//
//  Created by David Sherlock on 2026.
//
//  Real responses recorded 2026-08-31; no network in the suite.
//

import Foundation
import XCTest
@testable import StackExchange

final class StackExchangeTests: XCTestCase {

    private func fixture(_ name: String) throws -> Data {
        try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")))
    }

    private func client(_ data: Data, status: Int = 200) -> StackExchange {
        StackExchange(transport: { request in
            (data, HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!)
        })
    }

    func testEndpointsAskForBodiesAndClampThePage() throws {
        let url = try XCTUnwrap(Endpoints.search("swift actor", site: "stackoverflow", limit: 500))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(items.first { $0.name == "filter" }?.value, "withbody",
                       "withbody is the whole point — the fix must be IN the response")
        XCTAssertEqual(items.first { $0.name == "pagesize" }?.value, "30")
        XCTAssertEqual(items.first { $0.name == "sort" }?.value, "relevance")
        let answers = try XCTUnwrap(Endpoints.answers(question: 42, site: "superuser"))
        XCTAssertTrue(answers.absoluteString.contains("/questions/42/answers"))
        XCTAssertTrue(answers.query!.contains("site=superuser"))
    }

    func testSearchDecodesTheRecordingAndSurfacesQuota() async throws {
        let result = try await client(try fixture("se-search")).search("swift actor isolation")
        XCTAssertFalse(result.items.isEmpty)
        let first = try XCTUnwrap(result.items.first)
        XCTAssertTrue(first.isAnswered)
        XCTAssertGreaterThan(first.viewCount, 1000)
        XCTAssertFalse(first.excerpt.contains("<"), "excerpts are plain text: \(first.excerpt.prefix(60))")
        XCTAssertNotNil(result.quotaRemaining, "the daily budget must be surfaced")
    }

    func testAnswersPutTheAcceptedOneFirstWithFencedCode() async throws {
        let result = try await client(try fixture("se-answers")).answers(for: 69259397)
        XCTAssertEqual(result.items.count, 3)
        let first = try XCTUnwrap(result.items.first)
        XCTAssertTrue(first.isAccepted, "accepted before higher-voted")
        XCTAssertFalse(first.body.contains("<p>"))
        let anyCode = result.items.contains { $0.body.contains("```") }
        XCTAssertTrue(anyCode, "code blocks survive as fences")
    }

    func testHTMLTextKeepsCodeAndDecodesEntitiesLast() {
        let html = "<p>Use <code>actor</code> like so:</p><pre><code>actor Cache { }\n</code></pre><p>Then &lt;div&gt; is just text &amp; so on.</p><ul><li>one</li><li>two</li></ul>"
        let plain = HTMLText.plain(html)
        XCTAssertTrue(plain.contains("Use `actor` like so:"))
        XCTAssertTrue(plain.contains("```\nactor Cache { }"))
        XCTAssertTrue(plain.contains("<div> is just text & so on"), "entities decode AFTER tag stripping: \(plain)")
        XCTAssertTrue(plain.contains("• one"))
        XCTAssertNil(plain.range(of: "<p>"))
        XCTAssertEqual(HTMLText.decodeEntities("caf&#233;"), "café")
    }

    func testThrottleViolationSurfacesAsRateLimited() async throws {
        let body = Data("{\"error_id\":502,\"error_name\":\"throttle_violation\",\"backoff\":12,\"items\":[]}".utf8)
        do {
            _ = try await client(body, status: 400).search("anything")
            XCTFail("a throttle must surface as rateLimited")
        } catch let error as StackError {
            XCTAssertEqual(error, .rateLimited(retryAfter: 12))
        }
    }
}
