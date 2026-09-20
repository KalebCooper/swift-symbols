extension SFSymbol {
  /// Every symbol the catalog lists, in the order Apple's SF Symbols app shows them.
  ///
  /// The list holds each catalogued name once and leaves out deprecated aliases. It is built
  /// the first time it is read and reused after that.
  ///
  /// ```swift
  /// SFSymbol.all.count                       // the number of catalogued symbols
  /// SFSymbol.all.filter(\.isAvailable)       // the symbols the running OS draws
  /// ```
  public static var all: [SFSymbol] { catalogOrder }

  private static let catalogOrder: [SFSymbol] = SymbolTable.order.map {
    SFSymbol(unchecked: SymbolTable.names[Int($0)])
  }
}
