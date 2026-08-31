# swift-stack-exchange

Stack Exchange search and answers for Swift — keyless, bodies as readable text.

```swift
import StackExchange

let found = try await StackExchange().search("swift actor isolation")
let answers = try await StackExchange().answers(for: 69259397)
// answers.items.first is the ACCEPTED answer, body already plain text
```

## What it does with the HTML

Answer bodies arrive as HTML; callers want text they can read and code they can paste.
`HTMLText.plain` is pure string work — no attributed strings, no main thread:

- `<pre><code>` becomes a fenced ``` block, so the fix pastes straight out
- `<code>` becomes backticks, `<li>` becomes a bullet, `<p>` becomes a blank line
- entities decode **after** tags strip, so `&lt;div&gt;` in prose survives as literal text

## The budget is part of the API

The free tier is 300 requests per IP per day. Every result carries what the API said:

```swift
found.quotaRemaining   // requests left today
found.backoff          // seconds the API asked callers to wait, when it did
```

A `throttle_violation` surfaces as `StackError.rateLimited`, never as a mystery 400.

## API

```swift
let client = StackExchange()
try await client.search("query", site: "askubuntu", limit: 10)  // Answered<[Question]>
try await client.answers(for: 69259397)                          // Answered<[Answer]>, accepted first
```

Responses are gzip on the wire; URLSession inflates them transparently. The transport is
injectable, and the whole suite runs on responses recorded live — no network in tests.

## Requirements

- macOS 14+ / iOS 16+, Swift 6

## License

MIT — see [LICENSE](LICENSE).
