import CoreGraphics
import Foundation
import SwiftSymbols
import SwiftSymbolsTestSupport
import SwiftSymbolsUI
import SwiftUI
import Testing

@Suite("Symbol styles", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SymbolStyleTests {
  /// Every style the type offers, including a palette of each size.
  static let styles: [SymbolStyle] = [
    .hierarchical, .monochrome, .multicolor, .palette(.blue), .palette(.white, .blue),
    .palette(.white, .blue, .teal),
  ]

  /// A rendered view as its pixel bytes and its size, so two renderings compare exactly.
  struct Raster: Equatable {
    let bytes: Data
    let height: Int
    let width: Int
  }

  /// Rasterizes a view at one pixel per point, and answers its pixels and size.
  @MainActor
  func raster(_ view: some View) -> Raster? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    guard let image = renderer.cgImage, let bytes = image.dataProvider?.data else { return nil }
    return Raster(bytes: Data(referencing: bytes), height: image.height, width: image.width)
  }

  /// Renders a view the way a host app would, and answers whether an image came back.
  @MainActor
  func renders(_ view: some View) -> Bool {
    ImageRenderer(content: view).cgImage != nil
  }

  /// A styled symbol beneath an ancestor that sets a heavy weight and a large scale, so a style
  /// that passes its own nil through would visibly clear one of them.
  @MainActor
  func symbolUnderAnAncestor(weight: Font.Weight?, scale: Image.Scale?) -> some View {
    Image(.plus, variants: .circle, .fill)
      .symbolStyle(.monochrome, weight: weight, scale: scale)
      .fontWeight(.black)
      .imageScale(.large)
  }

  @Test("Every style renders a symbol", arguments: SymbolStyleTests.styles)
  @MainActor
  func everyStyleRendersASymbol(style: SymbolStyle) {
    #expect(renders(Image(.plus, variants: .circle, .fill).symbolStyle(style)))
  }

  @Test("A weight and a scale render alongside a style")
  @MainActor
  func aWeightAndAScaleRenderAlongsideAStyle() {
    let image = Image(.plus, variants: .circle, .fill)
    #expect(renders(image.symbolStyle(.hierarchical, weight: .semibold, scale: .large)))
  }

  @Test("A style renders on a view that is not an image")
  @MainActor
  func aStyleRendersOnAViewThatIsNotAnImage() {
    #expect(renders(Label("Add", symbol: .plus).symbolStyle(.palette(.white, .blue))))
  }

  @Test("A style crosses an isolation boundary")
  func aStyleCrossesAnIsolationBoundary() async {
    let style = SymbolStyle.palette(.white, .blue, .teal)
    await Task.detached { _ = style }.value
  }

  @Test("A nil weight and a nil scale keep an ancestor's values")
  @MainActor
  func aNilWeightAndANilScaleKeepAnAncestorsValues() throws {
    let inherited = try #require(raster(symbolUnderAnAncestor(weight: nil, scale: nil)))
    let restated = try #require(raster(symbolUnderAnAncestor(weight: .black, scale: .large)))
    let lighter = try #require(raster(symbolUnderAnAncestor(weight: .ultraLight, scale: nil)))
    let smaller = try #require(raster(symbolUnderAnAncestor(weight: nil, scale: .small)))
    #expect(inherited == restated)
    #expect(inherited != lighter)
    #expect(inherited != smaller)
  }
}
