import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite("Catalog module", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ModuleTests {
  @Test("The shared suite time limit is the smallest bound Swift Testing can express")
  func theSharedSuiteTimeLimitIsTheSmallestBoundSwiftTestingCanExpress() {
    #expect(suiteTimeLimitMinutes == 1)
  }
}
