/// An SF Symbol, identified by its system name.
///
/// Every symbol in the catalog is a static member, so `SFSymbol.plus` is the typed form of
/// `"plus"`. Variants and availability come from the catalog compiled into this module; the
/// SwiftUI module turns a symbol into an `Image` or `Label`.
///
/// ```swift
/// let symbol: SFSymbol = .plus
/// symbol.name                              // "plus"
/// SFSymbol(name: "plus.circle.fill")       // .plusCircleFill
/// SFSymbol(name: "not.a.symbol")           // nil
/// ```
public struct SFSymbol: Codable, CustomStringConvertible, Hashable, Identifiable, Sendable {
  /// The system name, as passed to `Image(systemName:)`.
  public let name: String

  /// Creates a symbol from a catalogued name, or nil when the catalog does not list it.
  ///
  /// A deprecated name is accepted and resolves to its current name.
  public init?(name: String) {
    guard let row = SymbolTable.resolve(name) else { return nil }
    self.name = SymbolTable.names[row]
  }

  /// Creates a symbol from a name without consulting the catalog.
  ///
  /// Use it for a symbol newer than the catalog or one the catalog does not list. The symbol
  /// has no metadata and no variants, and rendering it is only as safe as the name.
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
