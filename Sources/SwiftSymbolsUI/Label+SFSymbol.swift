import SwiftSymbols
import SwiftUI

extension Label where Title == Text, Icon == Image {
  /// Creates a label with a localized title and a system symbol icon.
  ///
  /// ```swift
  /// Label("Add", symbol: .plus)
  /// ```
  public init(_ titleKey: LocalizedStringKey, symbol: SFSymbol) {
    self.init(titleKey, systemImage: symbol.name)
  }

  /// Creates a label with an already localized title and a system symbol icon.
  ///
  /// ```swift
  /// Label(item.title, symbol: .plus)
  /// ```
  public init(_ title: some StringProtocol, symbol: SFSymbol) {
    self.init(title, systemImage: symbol.name)
  }
}
