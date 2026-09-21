import SwiftUI

@main
struct SymbolBrowserApp: App {
  var body: some Scene {
    WindowGroup {
      DemoRootView()
    }
  }
}

struct DemoRootView: View {
  var body: some View {
    NavigationStack {
      List {
        NavigationLink("Symbol catalog") { SymbolGridDemo() }
        NavigationLink("Variant playground") { VariantPlaygroundDemo() }
        NavigationLink("Symbol style") { SymbolStyleDemo() }
        NavigationLink("Labels and images") { LabelDemo() }
        NavigationLink("Availability") { AvailabilityDemo() }
      }
      .navigationTitle("SymbolBrowser")
    }
  }
}
