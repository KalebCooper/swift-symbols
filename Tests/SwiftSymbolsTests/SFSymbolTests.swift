import Foundation
import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite("SFSymbol", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SFSymbolTests {
  @Test("A generated static wraps its system name")
  func aGeneratedStaticWrapsItsSystemName() {
    #expect(SFSymbol.plus.name == "plus")
    #expect(SFSymbol.plusCircleFill.name == "plus.circle.fill")
    #expect(SFSymbol._0Circle.name == "0.circle")
    #expect(SFSymbol.repeat.name == "repeat")
  }

  @Test("A catalogued name initializes and an unknown one does not")
  func aCataloguedNameInitializesAndAnUnknownOneDoesNot() {
    #expect(SFSymbol(name: "plus") == .plus)
    #expect(SFSymbol(name: "not.a.symbol") == nil)
    #expect(SFSymbol(name: "") == nil)
  }

  @Test("An unchecked name is kept as given")
  func anUncheckedNameIsKeptAsGiven() {
    let custom = SFSymbol(unchecked: "cooperlabs.logo")
    #expect(custom.name == "cooperlabs.logo")
    #expect(custom.id == "cooperlabs.logo")
    #expect(custom.description == "cooperlabs.logo")
  }

  @Test("A symbol encodes as its name")
  func aSymbolEncodesAsItsName() throws {
    let data = try JSONEncoder().encode([SFSymbol.plus])
    #expect(String(decoding: data, as: UTF8.self) == "[\"plus\"]")
    #expect(try JSONDecoder().decode([SFSymbol].self, from: data) == [.plus])
  }

  @Test("Every alias initializes to its current, catalogued name")
  func everyAliasInitializesToItsCurrentCataloguedName() {
    #expect(SymbolTable.aliasNames.isEmpty == false)
    let misresolved = SymbolTable.aliasNames.indices.filter { row in
      SFSymbol(name: SymbolTable.aliasNames[row])?.name
        != SymbolTable.names[Int(SymbolTable.aliasTargets[row])]
    }
    #expect(misresolved.isEmpty, "\(misresolved.prefix(3).map { SymbolTable.aliasNames[$0] })")
  }

  @Test("Every catalogued name initializes to itself")
  func everyCataloguedNameInitializesToItself() {
    #expect(SymbolTable.names.isEmpty == false)
    let unresolved = SymbolTable.names.filter { SFSymbol(name: $0)?.name != $0 }
    #expect(unresolved.isEmpty, "\(unresolved.prefix(3))")
  }

  @Test("The catalog version names an SF Symbols release the package knows")
  func theCatalogVersionNamesAnSFSymbolsReleaseThePackageKnows() {
    #expect(SFSymbol.catalogVersion.sfSymbolsYear >= 2026)
    #expect(SFSymbol.catalogVersion.macOSBuild.isEmpty == false)
  }
}
