/// The Swift spelling of a symbol name, as the generated catalog declares it.
///
/// The catalog declares one member per symbol, but a symbol value reports only the string name it
/// was built from, so a screen that shows the reader what to type has to derive the member's
/// spelling itself. This file is that derivation, and it duplicates the rule the catalog's own
/// code applies: split the name on dots, lowercase the first token, uppercase the first letter of
/// every later token and leave the rest of that token as written, prefix an underscore when the
/// result starts with a digit, and wrap a keyword in backticks. The rule is deterministic, so two
/// screens naming the same symbol always agree.
enum SwiftSpelling {
  /// Words that cannot be declared as a member name without backticks.
  private static let keywords: Set<String> = [
    "Any", "Self", "as", "associatedtype", "await", "break", "case", "catch", "class", "continue",
    "default", "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "false",
    "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is",
    "let", "nil", "open", "operator", "precedencegroup", "private", "protocol", "public", "repeat",
    "rethrows", "return", "self", "static", "struct", "subscript", "super", "switch", "throw",
    "throws", "true", "try", "typealias", "var", "where", "while",
  ]

  /// The spelling without backticks, for prose that names the member.
  static func bare(for symbolName: String) -> String {
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

  /// The spelling as it appears in a declaration, backticks included when the name is a keyword.
  static func declaration(for symbolName: String) -> String {
    let identifier = bare(for: symbolName)
    return keywords.contains(identifier) ? "`\(identifier)`" : identifier
  }
}
