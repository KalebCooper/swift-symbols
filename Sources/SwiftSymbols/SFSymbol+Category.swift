extension SFSymbol {
  /// One of Apple's SF Symbols categories, such as `weather`.
  public struct Category: Hashable, Sendable {
    /// Apple's key for the category.
    public let key: String

    init(key: String) {
      self.key = key
    }
  }
}
