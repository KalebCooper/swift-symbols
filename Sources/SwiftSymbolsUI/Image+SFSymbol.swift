import SwiftSymbols
import SwiftUI

extension Image {
  /// Creates an image of a system symbol.
  ///
  /// ```swift
  /// Image(.plus)
  /// ```
  public init(_ symbol: SFSymbol) {
    self.init(systemName: symbol.name)
  }

  /// Creates an image of a system symbol with the given variants added.
  ///
  /// The catalog resolves the variants, so a combination it does not draw falls back to the
  /// nearest name it does, exactly as ``/SwiftSymbols/SFSymbol/applying(_:)`` describes.
  ///
  /// ```swift
  /// Image(.plus, variants: .circle, .fill)    // plus.circle.fill
  /// Image(.plus, variants: .fill)             // plus, no filled plus exists
  /// ```
  public init(_ symbol: SFSymbol, variants: SFSymbol.Variant...) {
    self.init(systemName: symbol.applying(variants).name)
  }
}
