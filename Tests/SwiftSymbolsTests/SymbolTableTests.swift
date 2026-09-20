import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite("SymbolTable", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SymbolTableTests {
  /// The suffix token each variant bit stands for, for rebuilding a name from its base.
  static let variantTokens: [String: SFSymbol.Variant] = [
    "circle": .circle,
    "fill": .fill,
    "rectangle": .rectangle,
    "slash": .slash,
    "square": .square,
  ]

  @Test("A base name is the name with its variant suffixes removed")
  func aBaseNameIsTheNameWithItsVariantSuffixesRemoved() {
    let mismatched = SymbolTable.names.indices.filter { row in
      let name = SymbolTable.names[row]
      let base = SymbolTable.baseName(Int(SymbolTable.baseIndex[row]))
      let bits = SFSymbol.Variant(rawValue: SymbolTable.variantBits[row])
      if name == base { return bits != [] }
      guard name.hasPrefix(base + ".") else { return true }
      let suffixes = name.dropFirst(base.count + 1).split(separator: ".").map(String.init)
      let named = suffixes.compactMap { Self.variantTokens[$0] }
      return named.count != suffixes.count
        || named.reduce(into: SFSymbol.Variant()) { $0.formUnion($1) } != bits
    }
    #expect(mismatched.isEmpty, "\(mismatched.prefix(3).map { SymbolTable.names[$0] })")
  }

  @Test("A base name maps back to the row that stands for it")
  func aBaseNameMapsBackToTheRowThatStandsForIt() {
    #expect(SymbolTable.orphanBases.isEmpty == false)
    let unmapped = SymbolTable.orphanBases.indices.filter { orphan in
      SymbolTable.baseIndex(of: SymbolTable.orphanBases[orphan])
        != SymbolTable.names.count + orphan
    }
    #expect(unmapped.isEmpty, "\(unmapped.prefix(3).map { SymbolTable.orphanBases[$0] })")
    let unnamed = SymbolTable.names.indices.filter { row in
      let base = Int(SymbolTable.baseIndex[row])
      return SymbolTable.baseIndex(of: SymbolTable.baseName(base)) != base
    }
    #expect(unnamed.isEmpty, "\(unnamed.prefix(3).map { SymbolTable.names[$0] })")
  }

  @Test("An absent base and variant pair is not found")
  func anAbsentBaseAndVariantPairIsNotFound() throws {
    let base = Int(SymbolTable.baseIndex[0])
    let present = SymbolTable.names.indices
      .filter { Int(SymbolTable.baseIndex[$0]) == base }
      .map { SymbolTable.variantBits[$0] }
    let absent = try #require((UInt8(0)...31).first { present.contains($0) == false })
    #expect(SymbolTable.index(base: base, variants: absent) == nil)
    let pastTheEnd = SymbolTable.names.count + SymbolTable.orphanBases.count
    #expect(SymbolTable.index(base: pastTheEnd, variants: 0) == nil)
  }

  @Test("Every name is found by its own row and an absent name is not")
  func everyNameIsFoundByItsOwnRowAndAnAbsentNameIsNot() {
    let misplaced = SymbolTable.names.indices.filter {
      SymbolTable.index(of: SymbolTable.names[$0]) != $0
    }
    #expect(misplaced.isEmpty, "\(misplaced.prefix(3).map { SymbolTable.names[$0] })")
    #expect(SymbolTable.index(of: "not.a.symbol") == nil)
    #expect(SymbolTable.index(of: "") == nil)
  }

  @Test("Every row is found by its base and variants")
  func everyRowIsFoundByItsBaseAndVariants() {
    let misplaced = SymbolTable.names.indices.filter { row in
      let found = SymbolTable.index(
        base: Int(SymbolTable.baseIndex[row]),
        variants: SymbolTable.variantBits[row]
      )
      return found != row
    }
    #expect(misplaced.isEmpty, "\(misplaced.prefix(3).map { SymbolTable.names[$0] })")
  }

  @Test("The binary-searched columns are strictly increasing")
  func theBinarySearchedColumnsAreStrictlyIncreasing() {
    #expect(SymbolTable.aliasNames.isEmpty == false)
    let columns = [
      "aliasNames": SymbolTable.aliasNames,
      "names": SymbolTable.names,
      "orphanBases": SymbolTable.orphanBases,
    ]
    let unsorted = columns.filter { _, column in
      zip(column, column.dropFirst()).contains { $0 >= $1 }
    }
    #expect(unsorted.isEmpty, "\(unsorted.keys.sorted())")
  }

  @Test("variantOrder permutes the rows into base and variant order")
  func variantOrderPermutesTheRowsIntoBaseAndVariantOrder() {
    #expect(SymbolTable.variantOrder.count == SymbolTable.names.count)
    #expect(Set(SymbolTable.variantOrder).count == SymbolTable.names.count)
    #expect(SymbolTable.variantOrder.allSatisfy { Int($0) < SymbolTable.names.count })
    let keys = SymbolTable.variantOrder.map { row in
      (base: SymbolTable.baseIndex[Int(row)], variants: SymbolTable.variantBits[Int(row)])
    }
    let outOfOrder = zip(keys, keys.dropFirst()).filter { earlier, later in
      (earlier.base, earlier.variants) >= (later.base, later.variants)
    }
    #expect(outOfOrder.isEmpty, "\(outOfOrder.prefix(3).map { $0.0.base })")
  }
}
