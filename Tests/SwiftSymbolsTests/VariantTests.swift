import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite("Variants", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct VariantTests {
  @Test("A missing combination drops the last requested variant")
  func aMissingCombinationDropsTheLastRequestedVariant() {
    #expect(SFSymbol.plus.fill == .plus)
    #expect(SFSymbol.plus.applying(.circle, .slash) == .plusCircle)
    #expect(SFSymbol.plus.applying(.slash, .circle) == .plus)
    #expect(SFSymbol.plus.applying() == .plus)
    #expect(SFSymbol.plusCircle.applying(.fill) == .plusCircleFill)
  }

  @Test("A name outside the catalog answers from itself")
  func aNameOutsideTheCatalogAnswersFromItself() {
    let custom = SFSymbol(unchecked: "cooperlabs.logo")
    #expect(custom.base == custom)
    #expect(custom.variants == [])
    #expect(custom.applying(.fill) == custom)
    #expect(custom.fill == custom)
    #expect(custom.resolving(.fill) == nil)
    #expect(custom.hasVariant(.fill) == false)
  }

  @Test("Base and variants describe the name")
  func baseAndVariantsDescribeTheName() {
    #expect(SFSymbol.bellSlashCircleFill.base == .bell)
    #expect(SFSymbol.bellSlashCircleFill.variants == [.circle, .fill, .slash])
    #expect(SFSymbol.plusCircleFill.base == .plus)
    #expect(SFSymbol.plusCircleFill.variants == [.circle, .fill])
    #expect(SFSymbol.plus.variants == [])
    #expect(SFSymbol.circleFill.base == .circle)
  }

  @Test("Chained properties resolve through the catalog")
  func chainedPropertiesResolveThroughTheCatalog() {
    #expect(SFSymbol.plus.circle == .plusCircle)
    #expect(SFSymbol.plus.circle.fill == .plusCircleFill)
    #expect(SFSymbol.plus.square.fill == .plusSquareFill)
    #expect(SFSymbol.wifi.slash == .wifiSlash)
    #expect(SFSymbol.bell.slash.circle.fill == .bellSlashCircleFill)
    #expect(SFSymbol.numbers.rectangle == .numbersRectangle)
  }

  @Test("Every base the catalog does not draw still resolves its symbols")
  func everyBaseTheCatalogDoesNotDrawStillResolvesItsSymbols() {
    #expect(SymbolTable.orphanBases.isEmpty == false)
    let misplaced = SymbolTable.orphanBases.filter { name in
      let orphan = SFSymbol(unchecked: name)
      return orphan.base.name != name || orphan.variants != []
    }
    #expect(misplaced.isEmpty, "\(misplaced.prefix(3))")
    let unresolved = SymbolTable.names.indices.filter { row in
      let base = Int(SymbolTable.baseIndex[row])
      guard base >= SymbolTable.names.count else { return false }
      let orphan = SFSymbol(unchecked: SymbolTable.baseName(base))
      let variants = SFSymbol.Variant(rawValue: SymbolTable.variantBits[row])
      return orphan.resolving(variants)?.name != SymbolTable.names[row]
    }
    #expect(unresolved.isEmpty, "\(unresolved.prefix(3).map { SymbolTable.names[$0] })")
  }

  @Test("Every catalogued name is its base with its variants applied")
  func everyCataloguedNameIsItsBaseWithItsVariantsApplied() {
    #expect(SymbolTable.names.isEmpty == false)
    let mismatched = SymbolTable.names.filter { name in
      let symbol = SFSymbol(unchecked: name)
      return symbol.base.applying(symbol.variants) != symbol
        || symbol.base.resolving(symbol.variants) != symbol
    }
    #expect(mismatched.isEmpty, "\(mismatched.prefix(3))")
  }

  @Test("Resolving is exact")
  func resolvingIsExact() {
    #expect(SFSymbol.plus.resolving([.circle, .fill]) == .plusCircleFill)
    #expect(SFSymbol.plus.resolving(.fill) == nil)
    #expect(SFSymbol.plus.resolving([.circle, .slash]) == nil)
    #expect(SFSymbol.plusCircleFill.resolving([]) == .plusCircleFill)
  }

  @Test("hasVariant reports catalog membership")
  func hasVariantReportsCatalogMembership() {
    #expect(SFSymbol.plus.hasVariant(.circle))
    #expect(SFSymbol.plus.hasVariant(.fill) == false)
    #expect(SFSymbol.plusCircle.hasVariant(.fill))
  }
}
