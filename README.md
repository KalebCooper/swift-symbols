# swift-symbols

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Type-safe SF Symbols for Swift: every symbol as a Swift value, with variants, availability, custom
symbols, and a SwiftUI surface for styling and animating them.

The catalog ships as generated Swift and nothing else: no bundle resources, and nothing parsed
while your app runs.

## Status

0.1.0 in preparation, unreleased. The symbol catalog, the variant model, availability, and the
SwiftUI image, label, and style surface are in place. Custom symbols and typed symbol-effect
modifiers are planned for a later release.

## Usage

```swift
import SwiftSymbols

let add: SFSymbol = .plus
add.name                          // "plus"
add.circle.fill                   // .plusCircleFill
add.variants                      // []
add.hasVariant(.fill)             // false
add.availability?.iOS             // SFSymbol.Version(major: 13, minor: 0)
SFSymbol(name: "plus.circle")     // .plusCircle
SFSymbol(name: "not.a.symbol")    // nil
SFSymbol.all.count                // every catalogued symbol, in Apple's order
```

```swift
import SwiftSymbolsUI

Image(.plus, variants: .circle, .fill)
Label("Add", symbol: .plus)
Image(.wifi).symbolStyle(.hierarchical, weight: .semibold, scale: .large)
Image(.personCropCircle).symbolStyle(.palette(.white, .blue))
```

A renamed symbol keeps a deprecated member pointing at the current name. A symbol newer than the
platform floor carries `@available`. A localized drawing, such as the right-to-left form of an
arrow, is chosen by the system and has no member of its own. Apple's search terms, categories, and
usage restrictions are part of each member's documentation, visible in Xcode quick help.

Full documentation: <https://kalebcooper.github.io/swift-symbols/documentation/>.

## Products

| Product | What it holds | Dependencies |
| --- | --- | --- |
| `SwiftSymbols` | `SFSymbol`, the generated catalog, variants, and availability. Imports no UI framework, so UIKit and AppKit code can use it without SwiftUI. | None. |
| `SwiftSymbolsUI` | `Image` and `Label` initializers, `SymbolStyle` and the `symbolStyle` modifier, and the bridge to SwiftUI's `SymbolVariants`. | `SwiftSymbols`. |

## Catalog

The catalog is generated from the SF Symbols metadata that ships with macOS and checked in, so
building the package needs nothing but the package. `SFSymbol.catalogVersion` names the SF Symbols
release and the macOS build it came from. Regenerate it after an Xcode or macOS update with
`bash Scripts/generate-catalog.sh`, and commit the result on its own.

## Requirements

- Swift 6.2 tools and Swift 6 language mode.
- iOS, macOS, tvOS, visionOS, or watchOS 26 and later.

SF Symbols exist only on Apple platforms, so the package targets nothing else.

## Installation

No release has been published. For local development, add this checkout as a local Swift package
and select either product. The repository location is
[KalebCooper/swift-symbols](https://github.com/KalebCooper/swift-symbols).

## License

MIT. See [LICENSE](LICENSE). This project is independent of Apple. SF Symbols are provided by Apple
and their use is subject to Apple's terms; this package contains no symbol artwork.
