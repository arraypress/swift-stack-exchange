//
//  HTMLText.swift
//  StackExchange
//
//  Created by David Sherlock on 2026.
//
//  Answer bodies arrive as HTML; agents want text they can read and code
//  they can paste. Pure string work, no attributed strings, no main
//  thread: code blocks become fences BEFORE tags are stripped, and
//  entities decode LAST so `&lt;div&gt;` in prose survives as literal
//  angle brackets rather than becoming a tag to strip.
//

import Foundation

/// HTML to readable plain text, code kept.
public enum HTMLText {

    /// The body as plain text with fenced code blocks.
    public static func plain(_ html: String) -> String {
        var s = html
        // Code first, while the tags still mark it.
        s = s.replacingOccurrences(of: "<pre[^>]*><code[^>]*>", with: "\n```\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "</code>\\s*</pre>", with: "\n```\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "<code[^>]*>", with: "`", options: .regularExpression)
        s = s.replacingOccurrences(of: "</code>", with: "`")
        // Structure into whitespace.
        s = s.replacingOccurrences(of: "<br ?/?>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "</p>", with: "\n\n")
        s = s.replacingOccurrences(of: "<li[^>]*>", with: "• ", options: .regularExpression)
        s = s.replacingOccurrences(of: "</li>", with: "\n")
        // Everything else that is a tag, away.
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Entities last, so decoded angle brackets are text, not markup.
        s = decodeEntities(s)
        // Tidy the whitespace the removals left behind.
        s = s.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Named and numeric entity decoding, the handful HTML actually emits.
    static func decodeEntities(_ text: String) -> String {
        var s = text
        for (entity, character) in [("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
                                    ("&#39;", "'"), ("&nbsp;", " "), ("&amp;", "&")] {
            s = s.replacingOccurrences(of: entity, with: character)
        }
        while let range = s.range(of: "&#[0-9]+;", options: .regularExpression) {
            let digits = s[range].dropFirst(2).dropLast()
            if let value = UInt32(digits), let scalar = Unicode.Scalar(value) {
                s.replaceSubrange(range, with: String(Character(scalar)))
            } else {
                s.replaceSubrange(range, with: "")
            }
        }
        return s
    }
}
