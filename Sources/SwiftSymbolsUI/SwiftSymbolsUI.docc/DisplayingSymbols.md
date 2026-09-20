# Displaying symbols

Create images and labels from typed symbols, and style them.

## Overview

`Image` and `Label` take an ``/SwiftSymbols/SFSymbol`` wherever they would take a system name, so a
symbol is checked by the compiler on its way to the screen.

```swift
Image(.plus)
Image(.plus, variants: .circle, .fill)    // plus.circle.fill
Label("Add", symbol: .plus)
Label(item.title, symbol: .folder)
```

Variants passed to `Image` are resolved by the catalog, which knows which combinations Apple draws.
A combination that does not exist falls back to the nearest name that does, so
`Image(.plus, variants: .fill)` draws a plus rather than nothing.

### Styling a symbol

``SymbolStyle`` names one of the four ways SF Symbols renders layers: ``SymbolStyle/monochrome``,
``SymbolStyle/hierarchical``, ``SymbolStyle/multicolor``, and a palette of one, two, or three shape
styles. Apply it with `symbolStyle(_:weight:scale:)`, which also takes an optional font weight and
image scale.

```swift
Image(.cloudSun).symbolStyle(.multicolor)
Image(.personCropCircle).symbolStyle(.palette(.white, .blue))
Image(.wifi).symbolStyle(.hierarchical, weight: .semibold, scale: .large)
```

A palette style sets the foreground styles of the symbol's first three layers, and the layer after
the last style named draws in that style too. Leaving `weight` or `scale` out keeps the value set
further up the view hierarchy, so a style can be applied without disturbing the surrounding font.

### Letting SwiftUI resolve the variants instead

SwiftUI carries its own variant model in `SymbolVariants`, applied with `symbolVariant(_:)` and
inherited by every symbol in a subtree. ``/SwiftSymbols/SFSymbol/Variant`` bridges to it, and the
bridge is worth understanding before mixing the two:

- `fill` and `slash` are independent flags. A symbol can be filled, slashed, both, or neither.
- There is a single slot for an enclosing shape, so `circle`, `rectangle`, and `square` compete for
  it rather than combining.
- When a set names more than one shape, the last one applied wins: `square` over `rectangle`, and
  `rectangle` over `circle`.

```swift
VStack {
  Image(.bell)
  Image(.wifi)
}
.symbolVariant(SFSymbol.Variant([.slash, .fill]).symbolVariants)
```

SwiftUI falls back on its own when a variant does not exist for a symbol, which is what makes the
modifier safe to apply to a whole subtree. Use it for that. Use `Image(_:variants:)` when a single
symbol should be resolved against the catalog at the point of use.

### Working with the rest of SwiftUI

Nothing here replaces SwiftUI's symbol API. A typed symbol is still an `Image`, so the stock
modifiers compose with it.

```swift
Image(.heart, variants: .fill)
  .symbolEffect(.bounce, value: isFavorite)
  .foregroundStyle(.pink)
  .imageScale(.large)
```
