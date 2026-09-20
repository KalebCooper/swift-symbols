import SwiftSymbols
import SwiftUI

extension SFSymbol.Variant {
  /// The SwiftUI equivalent, for `symbolVariant(_:)`.
  ///
  /// An empty set answers `SymbolVariants.none`. SwiftUI carries `fill` and `slash` alongside each
  /// other but holds a single enclosing shape, so a set naming more than one of `circle`,
  /// `rectangle`, and `square` keeps the last of them in that order.
  ///
  /// ```swift
  /// Image(.plus).symbolVariant(SFSymbol.Variant.circle.symbolVariants)
  /// ```
  public var symbolVariants: SymbolVariants {
    var variants = SymbolVariants.none
    if contains(.circle) { variants = variants.circle }
    if contains(.fill) { variants = variants.fill }
    if contains(.rectangle) { variants = variants.rectangle }
    if contains(.slash) { variants = variants.slash }
    if contains(.square) { variants = variants.square }
    return variants
  }
}
