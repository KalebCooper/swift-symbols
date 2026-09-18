extension SFSymbol {
  /// The SF Symbols release and macOS build a catalog was generated from.
  public struct CatalogVersion: Hashable, Sendable {
    /// The macOS build whose CoreGlyphs bundle supplied the data, such as `26A428`.
    public let macOSBuild: String
    /// The SF Symbols release year, such as `2026`.
    public let sfSymbolsYear: Int

    /// Creates a version from its build and release year.
    public init(macOSBuild: String, sfSymbolsYear: Int) {
      self.macOSBuild = macOSBuild
      self.sfSymbolsYear = sfSymbolsYear
    }
  }
}
