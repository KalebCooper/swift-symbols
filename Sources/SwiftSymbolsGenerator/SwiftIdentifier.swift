/// Turns an SF Symbol name into the identifier the generated catalog declares for it.
///
/// The rule is deterministic so regenerating the catalog never renames a symbol: split the name
/// on dots, lowercase the first token, capitalize the first letter of every later token, and
/// join. A Swift identifier cannot start with a digit, so `0.circle` becomes `_0Circle`. A result
/// that is a keyword is wrapped in backticks for its declaration; a call site may still write it
/// after a dot without them.
package enum SwiftIdentifier {
  /// Words that cannot be declared as a member name without backticks.
  package static let keywords: Set<String> = [
    "Any", "Self", "as", "associatedtype", "await", "break", "case", "catch", "class", "continue",
    "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "false",
    "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is",
    "let", "nil", "open", "operator", "precedencegroup", "private", "protocol", "public", "repeat",
    "rethrows", "return", "self", "static", "struct", "subscript", "super", "switch", "throw",
    "throws", "true", "try", "typealias", "var", "where", "while",
  ]

  /// The identifier without backticks, for `renamed:` strings and documentation links.
  package static func bare(for symbolName: String) -> String {
    let tokens = symbolName.split(separator: ".")
    var result = ""
    for (index, token) in tokens.enumerated() {
      if index == 0 {
        result = token.lowercased()
      } else {
        result += token.prefix(1).uppercased() + token.dropFirst()
      }
    }
    if let first = result.first, first.isNumber {
      result = "_" + result
    }
    return result
  }

  /// The identifier as it must appear in a declaration, backticks included when needed.
  package static func declaration(for symbolName: String) -> String {
    let identifier = bare(for: symbolName)
    return keywords.contains(identifier) ? "`\(identifier)`" : identifier
  }
}
