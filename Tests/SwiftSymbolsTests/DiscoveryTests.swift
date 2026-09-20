import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite("Discovery", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DiscoveryTests {
  @Test("All lists the catalogued names in the catalog's order")
  func allListsTheCataloguedNamesInTheCatalogsOrder() {
    let expected = SymbolTable.order.map { SymbolTable.names[Int($0)] }
    #expect(SFSymbol.all.map(\.name) == expected)
  }

  @Test("All holds every catalogued name exactly once")
  func allHoldsEveryCataloguedNameExactlyOnce() {
    let listed = Set(SFSymbol.all.map(\.name))
    #expect(listed.count == SFSymbol.all.count)
    #expect(listed == Set(SymbolTable.names))
  }

  @Test("Every listed symbol has an availability")
  func everyListedSymbolHasAnAvailability() {
    let missing = SFSymbol.all.filter { $0.availability == nil }.map(\.name)
    #expect(missing.isEmpty, "\(missing.prefix(3))")
  }
}
