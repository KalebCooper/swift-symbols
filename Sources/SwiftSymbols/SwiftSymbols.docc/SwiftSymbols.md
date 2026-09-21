# ``SwiftSymbols``

Every SF Symbol as a typed Swift value, with variants and availability.

## Overview

``SFSymbol`` takes the place of the string in `Image(systemName:)`. Each symbol Apple ships is a
static member, so autocompletion finds it and a misspelled name is a compile error rather than a
blank image.

```swift
let add: SFSymbol = .plus
add.name                 // "plus"
add.circle.fill          // .plusCircleFill
add.availability?.iOS    // SFSymbol.Version(major: 13, minor: 0)
```

The catalog is generated from the SF Symbols metadata that ships with macOS and compiled into this
module as Swift. Nothing is read from a bundle and nothing is parsed while your app runs.
``SFSymbol/catalogVersion`` names the SF Symbols release and the macOS build the catalog came from.

Apple's search terms for a symbol, the categories it belongs to, and any restriction on its use are
part of each member's documentation, so they show up in Xcode quick help and on this site. A
localized drawing, such as the right-to-left form of an arrow, is chosen by the system and has no
member of its own.

This module imports no UI framework, so UIKit and AppKit code can use it without SwiftUI. The
`SwiftSymbolsUI` module adds the SwiftUI surface.

## Topics

### Essentials

- <doc:ReferencingSymbols>
- ``SFSymbol``

### Variants

- <doc:WorkingWithVariants>
- ``SFSymbol/Variant``

### Releases and metadata

- <doc:SwiftSymbols/Availability>
- ``SFSymbol/Availability``
- ``SFSymbol/Version``
- ``SFSymbol/CatalogVersion``
