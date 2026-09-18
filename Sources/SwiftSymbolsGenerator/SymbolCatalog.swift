/// A deprecated name that forwards to the current one.
package struct AliasEntry: Hashable, Sendable {
  /// The identifier declared for the old name.
  package let identifier: String
  /// The old system name.
  package let name: String
  /// The current system name.
  package let target: String
  /// The identifier of the current name, without backticks.
  package let targetIdentifier: String
}

/// One canonical, non-localized symbol with everything the generated files say about it.
package struct SymbolEntry: Hashable, Sendable {
  /// The name with variant suffixes removed.
  package let base: String
  /// Category keys, without `all`.
  package let categories: [String]
  /// The filled counterpart, when Apple lists one.
  package let filledName: String?
  /// The declared identifier, backticks included when needed.
  package let identifier: String
  /// The system name.
  package let name: String
  /// Platform to OS version, from `year_to_release`.
  package let release: [String: String]
  /// Apple's usage restriction, when one applies.
  package let restriction: String?
  /// Apple's search terms.
  package let searchTerms: [String]
  /// Variant tokens in name order.
  package let variants: [String]
  /// The SF Symbols year, such as `2024.3`.
  package let year: String

  /// The `@available` attribute the declaration needs, or nil when every platform is at or
  /// below the package floor.
  package var availabilityAttribute: String? {
    let aboveFloor = SymbolCatalog.platforms.contains { platform in
      SymbolCatalog.isGreater(
        SymbolCatalog.version(release[platform]),
        than: SymbolCatalog.version(SymbolCatalog.floor[platform]))
    }
    guard aboveFloor else { return nil }
    let clauses = SymbolCatalog.platforms.map { "\($0) \(release[$0] ?? "")" }
    return "@available(\(clauses.joined(separator: ", ")), *)"
  }
}

/// The catalog the generator emits: canonical entries in Apple's order, aliases, and categories.
package struct SymbolCatalog: Sendable {
  /// The package's platform floor. A symbol released at or below it needs no annotation.
  package static let floor = [
    "iOS": "26.0", "macOS": "26.0", "tvOS": "26.0", "watchOS": "26.0", "visionOS": "26.0",
  ]

  /// The platforms every `year_to_release` row must name, in the order `@available` lists them.
  package static let platforms = ["iOS", "macOS", "tvOS", "watchOS", "visionOS"]

  /// Non-localized aliases whose target is canonical, sorted by old name.
  package let aliases: [AliasEntry]
  /// Apple's categories in Apple's order, without `all`.
  package let categories: [CategoryInfo]
  /// Canonical, non-localized symbols in `symbol_order` order.
  package let entries: [SymbolEntry]
  /// The newest SF Symbols release year among the entries, without its point release, so
  /// `2025.1` counts as 2025.
  package let sfSymbolsYear: Int

  /// Builds the catalog, failing on any inconsistency rather than guessing.
  package static func build(from data: CoreGlyphsData) throws -> SymbolCatalog {
    let canonical = Set(data.order)
    var entries: [SymbolEntry] = []
    var identifiers: [String: String] = [:]
    var variantKeys: [String: String] = [:]
    for name in data.order where !SymbolName.isLocalized(name, canonical: canonical) {
      guard let year = data.availability[name] else {
        throw GeneratorError.unresolved("\(name) has no year in name_availability.plist")
      }
      guard let release = data.yearToRelease[year] else {
        throw GeneratorError.unresolved(
          "\(name) has year \(year), which year_to_release does not define")
      }
      // An annotation with an empty version would not compile, so a partial row stops generation.
      if let missing = platforms.first(where: { release[$0] == nil }) {
        throw GeneratorError.unresolved(
          "\(name) has year \(year), whose year_to_release row has no \(missing) version")
      }
      let parsed = SymbolName(name)
      let identifier = SwiftIdentifier.declaration(for: name)
      if let other = identifiers[identifier] {
        throw GeneratorError.collision("\(name) and \(other) share identifier \(identifier)")
      }
      identifiers[identifier] = name
      let key = "\(parsed.base)|\(parsed.variantKey)"
      if let other = variantKeys[key] {
        throw GeneratorError.collision(
          "\(name) and \(other) share base \(parsed.base) and variants \(parsed.variantKey)")
      }
      variantKeys[key] = name
      entries.append(
        SymbolEntry(
          base: parsed.base,
          categories: (data.symbolCategories[name] ?? []).filter { $0 != "all" },
          filledName: data.fillCounterparts[name],
          identifier: identifier,
          name: name,
          release: release,
          restriction: data.restrictions[name],
          searchTerms: data.searchTerms[name] ?? [],
          variants: parsed.variants,
          year: year))
    }
    var aliases: [AliasEntry] = []
    for (old, current) in data.aliases.sorted(by: { $0.key < $1.key }) {
      guard canonical.contains(current) else {
        throw GeneratorError.unresolved("alias \(old) targets \(current), which is not canonical")
      }
      // A localized pair follows the same localized rule on both sides: the system picks the
      // drawing itself, whether the localization sits on the old name or the current one.
      if SymbolName.isLocalized(current, canonical: canonical) { continue }
      if SymbolName.isLocalized(old, canonical: canonical) { continue }
      // Alias keys are never canonical names, so this cannot trip on Apple's data; a collision
      // would declare the same member twice, so it is checked rather than assumed.
      let identifier = SwiftIdentifier.declaration(for: old)
      if let other = identifiers[identifier] {
        throw GeneratorError.collision("alias \(old) and \(other) share identifier \(identifier)")
      }
      identifiers[identifier] = old
      aliases.append(
        AliasEntry(
          identifier: identifier, name: old, target: current,
          targetIdentifier: SwiftIdentifier.bare(for: current)))
    }
    // The year describes what was emitted, so a release row no symbol uses does not raise it.
    guard let sfSymbolsYear = entries.compactMap({ version($0.year).first }).max() else {
      throw GeneratorError.unresolved("symbol_order.plist lists no canonical symbol")
    }
    return SymbolCatalog(
      aliases: aliases,
      categories: data.categories.filter { $0.key != "all" },
      entries: entries,
      sfSymbolsYear: sfSymbolsYear)
  }

  /// Whether `lhs` is a later version than `rhs`, component by component, so `[26, 1]` is later
  /// than `[26, 0]` and `[27, 0]` is later than both.
  ///
  /// A shorter array orders before a longer one it prefixes, so the floor keeps two components
  /// and `26.0` compares equal to it.
  package static func isGreater(_ lhs: [Int], than rhs: [Int]) -> Bool {
    rhs.lexicographicallyPrecedes(lhs)
  }

  /// Numeric components of a dotted version or year string, for ordering.
  package static func version(_ string: String?) -> [Int] {
    (string ?? "").split(separator: ".").map { Int($0) ?? 0 }
  }
}
