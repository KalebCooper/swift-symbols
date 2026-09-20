/// An SF Symbol, identified by its system name.
///
/// Every symbol in the catalog is a static member, so `SFSymbol.plus` is the typed form of
/// `"plus"`. ``variants`` and ``availability`` come from the catalog compiled into this module,
/// and the `SwiftSymbolsUI` module turns a symbol into an `Image` or a `Label`.
///
/// ```swift
/// let symbol: SFSymbol = .plus
/// symbol.name                              // "plus"
/// symbol.circle.fill                       // .plusCircleFill
/// SFSymbol(name: "plus.circle.fill")       // .plusCircleFill
/// SFSymbol(name: "not.a.symbol")           // nil
/// ```
///
/// A symbol carries nothing but its ``name``, so it encodes as that name, compares by it, and can
/// be stored in a model or driven through a `ForEach` without a wrapper.
public struct SFSymbol: Codable, CustomStringConvertible, Hashable, Identifiable, Sendable {
  /// The system name, as passed to `Image(systemName:)`.
  public let name: String

  /// Creates a symbol from a catalogued name, or nil when the catalog does not list it.
  ///
  /// Use it for a name that arrives at run time, from a server or a stored preference. A name
  /// Apple has since renamed is accepted and resolves to the current one, so ``name`` is not
  /// always the string passed in. For a name the catalog cannot vouch for, use
  /// ``init(unchecked:)``.
  ///
  /// ```swift
  /// SFSymbol(name: "plus.circle.fill")    // .plusCircleFill
  /// SFSymbol(name: "123.rectangle")       // .numbersRectangle, the current name
  /// SFSymbol(name: "not.a.symbol")        // nil
  /// ```
  ///
  /// - Parameter name: The system name of a symbol, current or deprecated.
  public init?(name: String) {
    guard let row = SymbolTable.resolve(name) else { return nil }
    self.name = SymbolTable.names[row]
  }

  /// Creates a symbol from a name without consulting the catalog.
  ///
  /// Use it for a symbol newer than the catalog or for one of your own. The symbol reports no
  /// ``availability`` and no ``variants``, ``base`` answers with itself, and it draws only if the
  /// name is right, so prefer ``init(name:)`` wherever the catalog can check the name.
  ///
  /// ```swift
  /// let logo = SFSymbol(unchecked: "cooperlabs.logo")
  /// logo.name            // "cooperlabs.logo"
  /// logo.variants        // []
  /// logo.availability    // nil
  /// ```
  ///
  /// - Parameter name: The system name of a symbol, checked by nothing.
  public init(unchecked name: String) {
    self.name = name
  }

  /// Decodes a symbol from its name, without consulting the catalog.
  public init(from decoder: any Decoder) throws {
    self.name = try decoder.singleValueContainer().decode(String.self)
  }

  /// The system name.
  public var description: String { name }

  /// The system name.
  public var id: String { name }

  /// Encodes the symbol as its name.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(name)
  }
}
