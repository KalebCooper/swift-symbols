import SwiftSymbols
import SwiftSymbolsTestSupport
import SwiftSymbolsUI
import SwiftUI
import Testing

@Suite("SwiftUI module", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ModuleTests {
  @Test("SwiftUI resolves a system symbol by name without this package")
  func swiftUIResolvesASystemSymbolByNameWithoutThisPackage() {
    // The baseline the typed surface will replace: a string name, unchecked until runtime.
    let image = Image(systemName: "plus")
    #expect(image == Image(systemName: "plus"))
  }
}
