import SwiftSymbolsGenerator
import SwiftSymbolsTestSupport
import Testing

@Suite("Swift identifier rule", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SwiftIdentifierTests {
  @Test(
    "Dotted names become camelCase",
    arguments: [
      ("plus", "plus"),
      ("plus.circle.fill", "plusCircleFill"),
      ("square.and.arrow.up", "squareAndArrowUp"),
      (
        "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left",
        "arrowUpLeftAndDownRightAndArrowUpRightAndDownLeft"
      ),
      ("switch.2", "switch2"),
      ("4k.tv", "_4kTv"),
      ("0.circle", "_0Circle"),
      ("123.rectangle.fill", "_123RectangleFill"),
    ])
  func dottedNamesBecomeCamelCase(name: String, expected: String) {
    #expect(SwiftIdentifier.bare(for: name) == expected)
    #expect(SwiftIdentifier.declaration(for: name) == expected)
  }

  @Test("The first token is lowercased")
  func theFirstTokenIsLowercased() {
    #expect(SwiftIdentifier.bare(for: "Plus.circle") == "plusCircle")
    #expect(SwiftIdentifier.declaration(for: "Repeat") == "`repeat`")
  }

  @Test(
    "Keywords are declared with backticks and referenced without",
    arguments: ["case", "repeat", "return"])
  func keywordsAreDeclaredWithBackticks(name: String) {
    #expect(SwiftIdentifier.bare(for: name) == name)
    #expect(SwiftIdentifier.declaration(for: name) == "`\(name)`")
  }

  @Test("A keyword followed by a suffix needs no backticks")
  func aKeywordFollowedByASuffixNeedsNoBackticks() {
    #expect(SwiftIdentifier.declaration(for: "repeat.circle") == "repeatCircle")
  }
}
