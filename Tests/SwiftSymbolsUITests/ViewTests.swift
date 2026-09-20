import SwiftSymbols
import SwiftSymbolsTestSupport
import SwiftSymbolsUI
import SwiftUI
import Testing

@Suite("SwiftUI views", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ViewTests {
  /// The five suffixes and the SwiftUI values they answer with.
  static let counterparts: [(SFSymbol.Variant, SymbolVariants)] = [
    (.circle, .circle), (.fill, .fill), (.rectangle, .rectangle), (.slash, .slash),
    (.square, .square),
  ]

  @Test("A typed symbol makes the image its system name makes")
  func aTypedSymbolMakesTheImageItsSystemNameMakes() {
    #expect(Image(.plus) == Image(systemName: "plus"))
  }

  @Test("Requested variants reach the image through the catalog")
  func requestedVariantsReachTheImageThroughTheCatalog() {
    #expect(Image(.plus, variants: .circle, .fill) == Image(systemName: "plus.circle.fill"))
  }

  @Test("A combination the catalog does not draw falls back to a name it does")
  func aCombinationTheCatalogDoesNotDrawFallsBackToANameItDoes() {
    #expect(Image(.plus, variants: .fill) == Image(systemName: "plus"))
  }

  @Test("A localized title and a symbol make a label of text and an image")
  func aLocalizedTitleAndASymbolMakeALabelOfTextAndAnImage() {
    let label = Label("Add", symbol: .plus)
    #expect(type(of: label) == Label<Text, Image>.self)
  }

  @Test("An already localized title and a symbol make a label of text and an image")
  func anAlreadyLocalizedTitleAndASymbolMakeALabelOfTextAndAnImage() {
    let title = "Add"
    let label = Label(title, symbol: .plus)
    #expect(type(of: label) == Label<Text, Image>.self)
  }

  @Test("Each suffix answers its SwiftUI counterpart", arguments: ViewTests.counterparts)
  func eachSuffixAnswersItsSwiftUICounterpart(
    variant: SFSymbol.Variant,
    counterpart: SymbolVariants
  ) {
    #expect(variant.symbolVariants == counterpart)
  }

  @Test("An empty set answers no variant")
  func anEmptySetAnswersNoVariant() {
    #expect(SFSymbol.Variant().symbolVariants == SymbolVariants.none)
  }

  @Test("A shape and a flag combine into one value")
  func aShapeAndAFlagCombineIntoOneValue() {
    #expect(SFSymbol.Variant([.circle, .fill]).symbolVariants == SymbolVariants.circle.fill)
  }

  @Test("A set naming more than one enclosing shape keeps the last one")
  func aSetNamingMoreThanOneEnclosingShapeKeepsTheLastOne() {
    #expect(SFSymbol.Variant([.circle, .square]).symbolVariants == SymbolVariants.square)
  }

  @Test("Every combination carries its flags and its last enclosing shape")
  func everyCombinationCarriesItsFlagsAndItsLastEnclosingShape() {
    let shapes: [(SFSymbol.Variant, SymbolVariants)] = [
      (.circle, .circle), (.rectangle, .rectangle), (.square, .square),
    ]
    for rawValue in UInt8(0)...0b1_1111 {
      let variant = SFSymbol.Variant(rawValue: rawValue)
      let combined = variant.symbolVariants
      #expect(combined.contains(.fill) == variant.contains(.fill))
      #expect(combined.contains(.slash) == variant.contains(.slash))
      let kept = shapes.last { variant.contains($0.0) }?.0
      for (shape, counterpart) in shapes {
        #expect(combined.contains(counterpart) == (shape == kept))
      }
    }
  }
}
