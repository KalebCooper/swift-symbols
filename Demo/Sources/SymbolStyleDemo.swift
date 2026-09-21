import SwiftSymbols
import SwiftSymbolsUI
import SwiftUI

/// One symbol drawn through `symbolStyle(_:weight:scale:)`, with a picker for each of its three
/// arguments.
///
/// The preview sits inside a container that sets the black weight and the small image scale
/// itself. That contrast is what makes the "inherited" choices visible: passing `nil` for the
/// weight or the scale keeps the container's value, so the symbol stays black and small, while an
/// explicit choice replaces it.
struct SymbolStyleDemo: View {
  private static let multicolorNote = "A symbol drawn in one colour falls back to monochrome."
  private static let scales: [(name: String, scale: Image.Scale)] = [
    ("small", .small),
    ("medium", .medium),
    ("large", .large),
  ]
  private static let styles: [(name: String, style: SymbolStyle)] = [
    ("Monochrome", .monochrome),
    ("Hierarchical", .hierarchical),
    ("Multicolor", .multicolor),
    ("Palette of one", .palette(.red)),
    ("Palette of two", .palette(.red, .blue)),
    ("Palette of three", .palette(.red, .blue, .green)),
  ]
  private static let weights: [(name: String, weight: Font.Weight)] = [
    ("ultraLight", .ultraLight),
    ("thin", .thin),
    ("light", .light),
    ("regular", .regular),
    ("medium", .medium),
    ("semibold", .semibold),
    ("bold", .bold),
    ("heavy", .heavy),
    ("black", .black),
  ]

  @State private var scale: Image.Scale?
  @State private var styleName = "Multicolor"
  @State private var weight: Font.Weight?

  /// The style the picker names; the picker only offers names from the same list.
  private var style: SymbolStyle {
    Self.styles.first { $0.name == styleName }?.style ?? .monochrome
  }

  var body: some View {
    List {
      Section {
        // The container, not the symbol, carries these three, so they are what nil inherits.
        VStack {
          Image(.cloudSunRainFill)
            .symbolStyle(style, weight: weight, scale: scale)
            .accessibilityLabel(SFSymbol.cloudSunRainFill.name)
        }
        .font(.system(size: 64))
        .fontWeight(.black)
        .imageScale(.small)
        .frame(maxWidth: .infinity, minHeight: 120)
        // Multicolor draws this cloud white, which vanishes on a white row.
        .listRowBackground(Color.gray.opacity(0.25))
      } header: {
        Text("Preview")
      } footer: {
        Text("The container sets the black weight and the small scale; inherited keeps both.")
      }

      Section("Style") {
        Picker("Style", selection: $styleName) {
          ForEach(Self.styles, id: \.name) { entry in
            VStack(alignment: .leading, spacing: 2) {
              Text(entry.name)
              if entry.name == "Multicolor" {
                Text(Self.multicolorNote)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
            .tag(entry.name)
          }
        }
        .pickerStyle(.inline)
        .labelsHidden()
      }

      Section("Weight") {
        Picker("Weight", selection: $weight) {
          Text("inherited").tag(Font.Weight?.none)
          ForEach(Self.weights, id: \.name) { entry in
            Text(entry.name).tag(Optional(entry.weight))
          }
        }
      }

      Section("Scale") {
        Picker("Scale", selection: $scale) {
          Text("inherited").tag(Image.Scale?.none)
          ForEach(Self.scales, id: \.name) { entry in
            Text(entry.name).tag(Optional(entry.scale))
          }
        }
        .pickerStyle(.segmented)
      }
    }
    .navigationTitle("Symbol style")
    .navigationBarTitleDisplayMode(.inline)
  }
}
