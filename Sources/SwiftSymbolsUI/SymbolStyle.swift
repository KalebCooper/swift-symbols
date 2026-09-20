import SwiftUI

/// A rendering treatment for the layers of a symbol.
///
/// A style names one of the four ways SF Symbols draws a symbol's layers: hierarchical,
/// monochrome, multicolor, or a palette of one, two, or three shape styles. Apply it with
/// `symbolStyle(_:weight:scale:)`.
///
/// ```swift
/// Image(.plus).symbolStyle(.palette(.white, .blue))
/// ```
public struct SymbolStyle: Sendable {
  /// The treatments a style names.
  ///
  /// The palette case carries its shape styles as `AnyShapeStyle` so a style stays `Sendable`.
  enum Kind: Sendable {
    case hierarchical
    case monochrome
    case multicolor
    case palette(primary: AnyShapeStyle, secondary: AnyShapeStyle?, tertiary: AnyShapeStyle?)
  }

  /// The treatment this style names.
  let kind: Kind

  /// Draws every layer in the foreground style, at the opacity its depth calls for.
  ///
  /// ```swift
  /// Image(.plus, variants: .circle, .fill).symbolStyle(.hierarchical)
  /// ```
  public static let hierarchical = SymbolStyle(kind: .hierarchical)

  /// Draws every layer in the foreground style, at full opacity.
  ///
  /// ```swift
  /// Image(.plus, variants: .circle, .fill).symbolStyle(.monochrome)
  /// ```
  public static let monochrome = SymbolStyle(kind: .monochrome)

  /// Draws the symbol in the colors Apple gave it, falling back to monochrome for a symbol
  /// drawn in one color.
  ///
  /// ```swift
  /// Image(.folder).symbolStyle(.multicolor)
  /// ```
  public static let multicolor = SymbolStyle(kind: .multicolor)

  /// Draws every layer in one shape style.
  ///
  /// ```swift
  /// Image(.plus, variants: .circle, .fill).symbolStyle(.palette(.blue))
  /// ```
  ///
  /// - Parameter primary: The style of the first layer, and of any layer after it.
  /// - Returns: A palette style.
  public static func palette(_ primary: some ShapeStyle) -> SymbolStyle {
    SymbolStyle(kind: .palette(primary: AnyShapeStyle(primary), secondary: nil, tertiary: nil))
  }

  /// Draws the first layer in one shape style and every layer after it in a second.
  ///
  /// ```swift
  /// Image(.plus, variants: .circle, .fill).symbolStyle(.palette(.white, .blue))
  /// ```
  ///
  /// - Parameters:
  ///   - primary: The style of the first layer.
  ///   - secondary: The style of the second layer, and of any layer after it.
  /// - Returns: A palette style.
  public static func palette(
    _ primary: some ShapeStyle,
    _ secondary: some ShapeStyle
  ) -> SymbolStyle {
    SymbolStyle(
      kind: .palette(
        primary: AnyShapeStyle(primary),
        secondary: AnyShapeStyle(secondary),
        tertiary: nil
      )
    )
  }

  /// Draws each of the first three layers in its own shape style.
  ///
  /// ```swift
  /// Image(.person, variants: .circle, .fill).symbolStyle(.palette(.white, .blue, .teal))
  /// ```
  ///
  /// - Parameters:
  ///   - primary: The style of the first layer.
  ///   - secondary: The style of the second layer.
  ///   - tertiary: The style of the third layer, and of any layer after it.
  /// - Returns: A palette style.
  public static func palette(
    _ primary: some ShapeStyle,
    _ secondary: some ShapeStyle,
    _ tertiary: some ShapeStyle
  ) -> SymbolStyle {
    SymbolStyle(
      kind: .palette(
        primary: AnyShapeStyle(primary),
        secondary: AnyShapeStyle(secondary),
        tertiary: AnyShapeStyle(tertiary)
      )
    )
  }

  /// The SwiftUI rendering mode this style asks for.
  var renderingMode: SymbolRenderingMode {
    switch kind {
    case .hierarchical: .hierarchical
    case .monochrome: .monochrome
    case .multicolor: .multicolor
    case .palette: .palette
    }
  }
}

extension View {
  /// Styles the symbols in this view.
  ///
  /// The style sets the rendering mode, and a palette style also sets the foreground styles its
  /// layers draw in. A weight and a scale are applied only when given, so the two default calls
  /// leave the view's font weight and image scale as they were.
  ///
  /// ```swift
  /// Image(.plus, variants: .circle, .fill)
  ///   .symbolStyle(.palette(.white, .blue), weight: .semibold, scale: .large)
  /// ```
  ///
  /// - Parameters:
  ///   - style: The rendering treatment for the symbol's layers.
  ///   - weight: The font weight the symbol draws at, or `nil` to keep the inherited weight.
  ///   - scale: The image scale the symbol draws at, or `nil` to keep the inherited scale.
  /// - Returns: A view whose symbols draw in the given style.
  public func symbolStyle(
    _ style: SymbolStyle,
    weight: Font.Weight? = nil,
    scale: Image.Scale? = nil
  ) -> some View {
    modifier(SymbolStyleModifier(scale: scale, style: style, weight: weight))
  }
}

/// The work behind `symbolStyle(_:weight:scale:)`.
///
/// A nil weight and a nil scale both leave an ancestor's value in place. The scale reaches the
/// environment through a transform that a nil leaves alone, but the weight has to branch:
/// `fontWeight(nil)` clears a weight set higher in the hierarchy rather than passing it through.
/// Only that branch and the number of palette styles change the shape of the tree, and neither
/// the presence of a weight nor a palette's layer count tends to change once a view is on screen.
private struct SymbolStyleModifier: ViewModifier {
  let scale: Image.Scale?
  let style: SymbolStyle
  let weight: Font.Weight?

  func body(content: Content) -> some View {
    weighted(colored(content.symbolRenderingMode(style.renderingMode)))
      .transformEnvironment(\.imageScale) { imageScale in
        if let scale { imageScale = scale }
      }
  }

  /// Applies the palette's foreground styles, one call per layer the palette names.
  @ViewBuilder
  private func colored(_ content: some View) -> some View {
    switch style.kind {
    case .palette(let primary, let secondary?, let tertiary?):
      content.foregroundStyle(primary, secondary, tertiary)
    case .palette(let primary, let secondary?, nil):
      content.foregroundStyle(primary, secondary)
    case .palette(let primary, nil, _):
      content.foregroundStyle(primary)
    case .hierarchical, .monochrome, .multicolor:
      content
    }
  }

  /// Applies the font weight, and applies nothing at all when there is none to apply.
  @ViewBuilder
  private func weighted(_ content: some View) -> some View {
    if let weight {
      content.fontWeight(weight)
    } else {
      content
    }
  }
}
