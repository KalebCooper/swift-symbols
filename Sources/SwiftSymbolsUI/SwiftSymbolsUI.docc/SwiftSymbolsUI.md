# ``SwiftSymbolsUI``

SwiftUI views and modifiers for typed SF Symbols.

## Overview

Build an `Image` or a `Label` from an ``/SwiftSymbols/SFSymbol``, let the catalog resolve the
variants, and style a symbol's layers in one call.

```swift
Image(.plus, variants: .circle, .fill)
Label("Add", symbol: .plus)
Image(.wifi).symbolStyle(.hierarchical, weight: .semibold, scale: .large)
```

SwiftUI's own symbol modifiers keep working alongside these: `symbolEffect`,
`symbolRenderingMode`, `symbolVariant`, `fontWeight`, and `imageScale` apply to these views as they
do to any other image.

This module depends on ``/SwiftSymbols``, which holds the catalog and imports no UI framework.

## Topics

### Essentials

- <doc:DisplayingSymbols>

### Styling

- ``SymbolStyle``
