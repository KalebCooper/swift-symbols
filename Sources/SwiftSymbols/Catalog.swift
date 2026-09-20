extension SymbolTable {
  /// The row of the symbol a base name stands for, whether or not the base is itself a
  /// catalogued name.
  ///
  /// A base that has no symbol of its own answers with a row past the end of ``names``, which
  /// ``baseName(_:)`` reads back from ``orphanBases``. Returns nil when the name is neither.
  package static func baseIndex(of name: String) -> Int? {
    if let row = index(of: name) {
      return row
    }
    guard let orphan = index(of: name, in: orphanBases) else { return nil }
    return names.count + orphan
  }

  /// The name a base row stands for, from ``names`` or, past its end, from ``orphanBases``.
  package static func baseName(_ baseIndex: Int) -> String {
    baseIndex < names.count ? names[baseIndex] : orphanBases[baseIndex - names.count]
  }

  /// The row of the symbol with the given base and variant bits, or nil when the catalog has no
  /// such combination.
  ///
  /// ``variantOrder`` lists the rows ordered by base and then by variant bits, so the pair is a
  /// binary-search key even though neither column is sorted on its own.
  package static func index(base: Int, variants: UInt8) -> Int? {
    var low = 0
    var high = variantOrder.count - 1
    while low <= high {
      let middle = low + (high - low) / 2
      let row = Int(variantOrder[middle])
      let candidate = (base: Int(baseIndex[row]), variants: variantBits[row])
      if candidate.base == base, candidate.variants == variants {
        return row
      }
      if candidate.base < base || (candidate.base == base && candidate.variants < variants) {
        low = middle + 1
      } else {
        high = middle - 1
      }
    }
    return nil
  }

  /// The row of a catalogued name, or nil when the catalog does not list it.
  package static func index(of name: String) -> Int? {
    index(of: name, in: names)
  }

  /// The row of the symbol a name refers to, following an alias to the name that replaced it.
  static func resolve(_ name: String) -> Int? {
    if let row = index(of: name) {
      return row
    }
    guard let alias = index(of: name, in: aliasNames) else { return nil }
    return Int(aliasTargets[alias])
  }

  /// The position of a name in a sorted column, found by binary search.
  private static func index(of name: String, in sortedNames: [String]) -> Int? {
    var low = 0
    var high = sortedNames.count - 1
    while low <= high {
      let middle = low + (high - low) / 2
      let candidate = sortedNames[middle]
      if candidate == name {
        return middle
      }
      if candidate < name {
        low = middle + 1
      } else {
        high = middle - 1
      }
    }
    return nil
  }
}
