# swift-symbols

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Type-safe SF Symbols for Swift: every symbol as a Swift value, with variants, availability, custom
symbols, and a SwiftUI surface for styling and animating them.

## Status

Unreleased scaffolding only. The two product modules, test support, documentation catalogs,
verification script, and workflows are present. There is no public API yet. The symbol catalog,
the variant model, custom-symbol support, and the SwiftUI surface are not yet built. The tests
check package wiring, not symbol behavior.

## Usage

The modules can be imported; there is nothing to call yet.

```swift
import SwiftSymbols
import SwiftSymbolsUI
```

## Example

A runnable demo is not yet included. The import example above is the available usage.

## Products

| Product | Status | Dependencies |
| --- | --- | --- |
| `SwiftSymbols` | Catalog module foundation; no public API. Imports no UI framework, so UIKit and AppKit code can use it without SwiftUI. | None. |
| `SwiftSymbolsUI` | SwiftUI module foundation; no public API. | `SwiftSymbols`. |

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
