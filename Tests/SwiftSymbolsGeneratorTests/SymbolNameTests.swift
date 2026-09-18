import SwiftSymbolsGenerator
import SwiftSymbolsTestSupport
import Testing

@Suite("Symbol name parsing", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SymbolNameTests {
  @Test(
    "Variant suffixes are stripped from the right, never the first token",
    arguments: [
      ("plus", "plus", [String]()),
      ("plus.circle.fill", "plus", ["circle", "fill"]),
      ("bell.slash.circle.fill", "bell", ["slash", "circle", "fill"]),
      ("circle", "circle", []),
      ("circle.fill", "circle", ["fill"]),
      ("circle.circle.fill", "circle", ["circle", "fill"]),
      ("square.and.arrow.up", "square.and.arrow.up", []),
      ("person.crop.circle.badge.plus", "person.crop.circle.badge.plus", []),
      ("rectangle.fill", "rectangle", ["fill"]),
    ])
  func variantSuffixesAreStrippedFromTheRight(name: String, base: String, variants: [String]) {
    let parsed = SymbolName(name)
    #expect(parsed.name == name)
    #expect(parsed.base == base)
    #expect(parsed.variants == variants)
  }

  @Test("The variant key ignores order")
  func theVariantKeyIgnoresOrder() {
    #expect(SymbolName("bell.slash.circle.fill").variantKey == "circle,fill,slash")
    #expect(SymbolName("plus").variantKey == "")
  }

  @Test(
    "A locale suffix on a canonical stem marks a localized drawing",
    arguments: [
      ("0.circle.ar", true),
      ("character.book.closed.hi", true),
      ("textformat.rtl", true),
      ("app.badge", false),
      ("x.tv", false),
      ("ar", false),
      ("figure.strengthtraining.traditional", false),
    ])
  func aLocaleSuffixMarksALocalizedDrawing(name: String, expected: Bool) {
    let canonical: Set<String> = [
      "0.circle", "character.book.closed", "textformat", "app", "x", "figure.strengthtraining",
    ]
    #expect(SymbolName.isLocalized(name, canonical: canonical) == expected)
  }

  @Test("A locale suffix whose stem is unknown is not localized")
  func aLocaleSuffixWhoseStemIsUnknownIsNotLocalized() {
    #expect(SymbolName.isLocalized("unknown.stem.ar", canonical: []) == false)
  }
}
