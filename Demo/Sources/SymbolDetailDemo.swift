import SwiftSymbols
import SwiftSymbolsUI
import SwiftUI
import UIKit

/// One symbol read in full: how it is drawn, how it is written, what it is made of, and which
/// release of each platform first drew it.
///
/// Both names on the screen are worth copying, so each carries its own button: the string name
/// belongs in a resource or a piece of data, and the Swift spelling belongs in code.
struct SymbolDetailDemo: View {
  let symbol: SFSymbol

  private static let underscoreNote = """
    A Swift identifier cannot start with a digit, so the leading underscore is part of the \
    spelling.
    """
  private static let variantNames: [(variant: SFSymbol.Variant, name: String)] = [
    (.circle, "circle"),
    (.fill, "fill"),
    (.rectangle, "rectangle"),
    (.slash, "slash"),
    (.square, "square"),
  ]

  /// The member's spelling, backticks included, which is what a reader would type.
  private var spelling: String {
    SwiftSpelling.declaration(for: symbol.name)
  }

  /// The variant suffixes the name carries, in the order the variant type declares them.
  private var variantSummary: String {
    let carried = Self.variantNames.filter { symbol.variants.contains($0.variant) }
    guard !carried.isEmpty else { return "none" }
    return carried.map(\.name).joined(separator: ", ")
  }

  var body: some View {
    List {
      Section {
        Image(symbol)
          .font(.system(size: 96))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
          .accessibilityLabel(symbol.name)
      }

      Section("Names") {
        CopyableValue(title: "Name", value: symbol.name)
        CopyableValue(title: "Swift spelling", value: spelling)
        if spelling.hasPrefix("_") {
          Text(Self.underscoreNote)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }

      Section("Composition") {
        LabeledContent("Variants", value: variantSummary)
        if symbol.base != symbol {
          LabeledContent("Base", value: symbol.base.name)
        }
      }

      Section("Availability") {
        if let availability = symbol.availability {
          LabeledContent("iOS", value: Self.text(for: availability.iOS))
          LabeledContent("macOS", value: Self.text(for: availability.macOS))
          LabeledContent("tvOS", value: Self.text(for: availability.tvOS))
          LabeledContent("visionOS", value: Self.text(for: availability.visionOS))
          LabeledContent("watchOS", value: Self.text(for: availability.watchOS))
        } else {
          Text("The catalog lists no release for this name.")
            .foregroundStyle(.secondary)
        }
        LabeledContent("Drawn on this system", value: symbol.isAvailable ? "Yes" : "No")
      }
    }
    .navigationTitle(symbol.name)
    .navigationBarTitleDisplayMode(.inline)
  }

  /// A platform release written the way a deployment target is written.
  private static func text(for version: SFSymbol.Version) -> String {
    "\(version.major).\(version.minor)"
  }
}

/// A named value the reader can put on the pasteboard.
private struct CopyableValue: View {
  let title: String
  let value: String

  var body: some View {
    LabeledContent(title) {
      HStack(spacing: 12) {
        Text(value)
          .font(.system(.body, design: .monospaced))
          .textSelection(.enabled)
        Button {
          UIPasteboard.general.string = value
        } label: {
          Image(SFSymbol.documentOnDocument)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Copy \(title)")
      }
    }
  }
}
