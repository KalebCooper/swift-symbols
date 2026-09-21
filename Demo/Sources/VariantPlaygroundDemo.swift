import SwiftSymbols
import SwiftSymbolsUI
import SwiftUI

/// One variant request read three ways, so an exact resolution, a fallback, and SwiftUI's own
/// substitution stand beside each other for the same base symbol and the same variants.
///
/// The three columns answer three different questions. `resolving(_:)` answers whether the
/// catalog draws exactly what was asked for, and draws nothing when it does not. `applying(_:)`
/// answers what the nearest drawn name is, and names it, because a fallback shown without its
/// name looks exactly like an exact resolution. `symbolVariant(_:)` answers what the system does
/// on its own, given the same variants through `Variant.symbolVariants`.
struct VariantPlaygroundDemo: View {
  private static let enclosingShapeNote = """
    SwiftUI holds one enclosing shape, so a request naming more than one of circle, rectangle and \
    square keeps the last in that order.
    """
  private static let variantNames: [(variant: SFSymbol.Variant, name: String)] = [
    (.circle, "circle"),
    (.fill, "fill"),
    (.rectangle, "rectangle"),
    (.slash, "slash"),
    (.square, "square"),
  ]

  @State private var name = "plus"
  @State private var selection: SFSymbol.Variant = []

  /// The symbol the typed name resolves to, or nil when the catalog lists no such name.
  private var baseSymbol: SFSymbol? {
    SFSymbol(name: name)
  }

  /// The selected variants in the order the toggles list them.
  ///
  /// The order is not cosmetic: it is the order the request is made in, and the fallback drops
  /// from the end of it.
  private var requestedVariants: [SFSymbol.Variant] {
    Self.variantNames.filter { selection.contains($0.variant) }.map(\.variant)
  }

  var body: some View {
    List {
      Section("Base symbol") {
        TextField("Symbol name", text: $name)
          .font(.system(.body, design: .monospaced))
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
        if baseSymbol == nil {
          Text("The catalog lists no symbol named \"\(name)\".")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      Section("Variants") {
        ForEach(Self.variantNames, id: \.name) { entry in
          Toggle(entry.name, isOn: binding(for: entry.variant))
        }
      }

      if let baseSymbol {
        Section {
          HStack(alignment: .top, spacing: 12) {
            resolvingColumn(for: baseSymbol)
            applyingColumn(for: baseSymbol)
            symbolVariantColumn(for: baseSymbol)
          }
          .padding(.vertical, 8)
        } header: {
          Text("Results")
        } footer: {
          Text(Self.enclosingShapeNote)
        }
      }
    }
    .navigationTitle("Variant playground")
    .navigationBarTitleDisplayMode(.inline)
  }

  /// The exact combination, or the word "unavailable" and no drawing at all.
  private func resolvingColumn(for symbol: SFSymbol) -> some View {
    let resolved = symbol.resolving(selection)
    return ResultColumn(
      caption: resolved?.name ?? "No such combination in the catalog.",
      title: "resolving(_:)"
    ) {
      if let resolved {
        Image(resolved)
          .font(.system(size: 40))
          .accessibilityLabel(resolved.name)
      } else {
        Text("unavailable")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
  }

  /// What the fallback produced, under the name it landed on.
  private func applyingColumn(for symbol: SFSymbol) -> some View {
    let applied = applying(to: symbol)
    return ResultColumn(caption: applied.name, title: "applying(_:)") {
      Image(applied)
        .font(.system(size: 40))
        .accessibilityLabel(applied.name)
    }
  }

  /// What SwiftUI draws when the same variants reach it as a `SymbolVariants` value.
  private func symbolVariantColumn(for symbol: SFSymbol) -> some View {
    ResultColumn(
      caption: "The system substitutes the drawing and reports no name.",
      title: "symbolVariant(_:)"
    ) {
      Image(symbol)
        .symbolVariant(selection.symbolVariants)
        .font(.system(size: 40))
        .accessibilityLabel(symbol.name)
    }
  }

  /// The fallback result for the selected variants, requested in the toggles' order.
  ///
  /// `applying(_:)` is variadic and its array form is not part of the public surface, so a
  /// request assembled while the app runs is spelled out once per count. Chaining one call per
  /// variant would be a different operation, and passing the variants as a single combined value
  /// would ask for one thing rather than for a sequence the fallback can narrow.
  private func applying(to symbol: SFSymbol) -> SFSymbol {
    let requested = requestedVariants
    switch requested.count {
    case 0:
      return symbol
    case 1:
      return symbol.applying(requested[0])
    case 2:
      return symbol.applying(requested[0], requested[1])
    case 3:
      return symbol.applying(requested[0], requested[1], requested[2])
    case 4:
      return symbol.applying(requested[0], requested[1], requested[2], requested[3])
    default:
      return symbol.applying(
        requested[0], requested[1], requested[2], requested[3], requested[4])
    }
  }

  /// One toggle's view of the option set, so the five toggles drive a single value.
  private func binding(for variant: SFSymbol.Variant) -> Binding<Bool> {
    Binding(
      get: { selection.contains(variant) },
      set: { isOn in
        if isOn {
          selection.insert(variant)
        } else {
          selection.remove(variant)
        }
      }
    )
  }
}

/// One result of the shared request, under the name of the call that produced it.
private struct ResultColumn<Content: View>: View {
  let caption: String
  let content: Content
  let title: String

  // The builder comes last so a caller can write the drawing as a trailing closure.
  init(caption: String, title: String, @ViewBuilder content: () -> Content) {
    self.caption = caption
    self.content = content()
    self.title = title
  }

  var body: some View {
    VStack(spacing: 8) {
      Text(title)
        .font(.caption.monospaced())
      content
        .frame(height: 52)
      Text(caption)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
  }
}
