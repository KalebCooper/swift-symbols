/// An SF Symbol name split into its base and the variant suffixes SwiftUI models as
/// `SymbolVariants`.
///
/// Variant tokens are stripped from the right until a token that is not a variant is reached.
/// The first token is never stripped, so `circle.fill` has base `circle` and one variant.
package struct SymbolName: Hashable, Sendable {
  /// Last-token suffixes that mark a localized drawing of another symbol. The system chooses the
  /// localized drawing itself, so these names never get a declaration of their own.
  package static let localeTokens: Set<String> = [
    "ar", "bn", "el", "gu", "he", "hi", "ja", "km", "kn", "ko", "ml", "mni", "mr", "my", "or",
    "pa", "rtl", "ru", "sat", "si", "ta", "te", "th", "zh",
  ]

  /// Suffix tokens SwiftUI models as symbol variants.
  package static let variantTokens: Set<String> = [
    "circle", "fill", "rectangle", "slash", "square",
  ]

  /// The name with its variant suffixes removed.
  package let base: String
  /// The full system name.
  package let name: String
  /// The stripped suffixes, in the order they appear in the name.
  package let variants: [String]

  package init(_ name: String) {
    let tokens = name.split(separator: ".").map(String.init)
    var end = tokens.count
    while end > 1, Self.variantTokens.contains(tokens[end - 1]) {
      end -= 1
    }
    self.base = tokens[..<end].joined(separator: ".")
    self.name = name
    self.variants = Array(tokens[end...])
  }

  /// The lookup key shared by every ordering of the same variants.
  package var variantKey: String {
    variants.sorted().joined(separator: ",")
  }

  /// Whether `name` is a localized drawing of a canonical symbol.
  package static func isLocalized(_ name: String, canonical: Set<String>) -> Bool {
    guard let dot = name.lastIndex(of: ".") else { return false }
    let suffix = String(name[name.index(after: dot)...])
    let stem = String(name[..<dot])
    return localeTokens.contains(suffix) && canonical.contains(stem)
  }
}
