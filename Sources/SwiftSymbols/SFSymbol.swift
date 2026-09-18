/// An SF Symbol, identified by its system name.
///
/// Every symbol in the catalog is a static member, so `SFSymbol.plus` is the typed form of
/// `"plus"`. Variants, availability, categories, and search terms come from the bundled catalog;
/// the SwiftUI module turns a symbol into an `Image` or `Label`.
public struct SFSymbol: Hashable, Sendable {
  /// The system name, as passed to `Image(systemName:)`.
  public let name: String

  /// Creates a symbol from a name without consulting the catalog.
  ///
  /// Use it for a symbol newer than the catalog or one the catalog does not list. The symbol
  /// has no metadata and no variants, and rendering it is only as safe as the name.
  public init(unchecked name: String) {
    self.name = name
  }
}
