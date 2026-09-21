import SwiftSymbols
import SwiftSymbolsUI
import SwiftUI

/// Both `Label(_:symbol:)` overloads and both `Image` initializers, in a `List` and in a `Form`.
///
/// The two label rows read the same on screen, so the call site is what tells them apart: a
/// string literal selects the `LocalizedStringKey` overload, and a `String` value selects the
/// `StringProtocol` one.
struct LabelDemo: View {
  private enum Container: String, CaseIterable {
    case form = "Form"
    case list = "List"
  }

  /// A `String` value, not a literal, so the label built from it takes the `StringProtocol`
  /// overload.
  fileprivate static let stringTitle: String = "String title"

  @State private var container = Container.list

  var body: some View {
    VStack(spacing: 0) {
      Picker("Container", selection: $container) {
        ForEach(Container.allCases, id: \.self) { container in
          Text(container.rawValue).tag(container)
        }
      }
      .pickerStyle(.segmented)
      .padding()

      switch container {
      case .form:
        Form { samples }
      case .list:
        List { samples }
      }
    }
    .navigationTitle("Labels and images")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder private var samples: some View {
    Section("Label, automatic style") {
      LabelRows(style: .automatic)
    }
    Section("Label, icon only") {
      LabelRows(style: .iconOnly)
    }
    Section("Label, title only") {
      LabelRows(style: .titleOnly)
    }
    Section("Image") {
      HStack {
        Image(.plus)
        Text("Image(_:)")
      }
      HStack {
        Image(.plus, variants: .circle, .fill)
        Text("Image(_:variants:) circle and fill")
      }
      HStack {
        Image(.plus, variants: .fill)
        Text("Image(_:variants:) fill falls back to plus")
      }
    }
  }
}

/// The two label overloads under one label style.
private struct LabelRows<Style: LabelStyle>: View {
  let style: Style

  var body: some View {
    Label("Literal title", symbol: .plus)
      .labelStyle(style)
    Label(LabelDemo.stringTitle, symbol: .plus)
      .labelStyle(style)
  }
}
