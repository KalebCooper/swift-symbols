# Changelog

All notable changes are documented here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- SymbolBrowser, a demo iOS app under `Demo/` that browses the catalog and exercises variants,
  styling, labels, and availability. It is generated with XcodeGen, is not part of any product, and
  consumers never build or link it.

## 0.1.0 - 2026-09-20

### Added

- Documentation catalogs for both products, with articles on referencing symbols, working with
  variants, availability, and displaying symbols in SwiftUI.
- `SymbolStyle` and the `symbolStyle(_:weight:scale:)` view modifier, which set a symbol's
  rendering mode and, for a palette, the foreground styles of its first three layers. A weight and
  a scale are applied only when given, so leaving either out keeps the value an ancestor set.
- `Image` and `Label` initializers taking an `SFSymbol`, including `Image(_:variants:)`, which
  resolves the variants through the catalog, and `SFSymbol.Variant.symbolVariants`, the bridge to
  SwiftUI's `SymbolVariants`.
- `SFSymbol.all`, listing every catalogued symbol once, in the order Apple's SF Symbols app shows
  them.
- Availability on `SFSymbol`: `availability`, reporting the first release of each Apple platform
  that draws the symbol, the `Availability` and `Version` types it answers with, and `isAvailable`,
  which compares the running system against the entry for the platform it was built for.
- Variant resolution through the catalog: `base`, `variants`, `applying(_:)`, `resolving(_:)`,
  `hasVariant(_:)`, and the `circle`, `fill`, `rectangle`, `slash`, and `square` properties.
  Applying a combination the catalog does not draw falls back to the nearest name it does.
- `SFSymbol.Variant`, the option set naming the `circle`, `fill`, `rectangle`, `slash`, and
  `square` suffixes.
- `SFSymbol`, a typed value for every SF Symbol, with a static member per symbol, a deprecated
  member for every renamed one, `@available` on symbols newer than the platform floor,
  `init(name:)` for a name that arrives at run time, `init(unchecked:)` for a name the catalog does
  not list, and `catalogVersion`. `SFSymbol` is `Codable` as its name, `CustomStringConvertible`,
  `Hashable`, `Identifiable`, and `Sendable`.
- The catalog generator and `Scripts/generate-catalog.sh`, which regenerates the checked-in catalog
  from the SF Symbols metadata that ships with macOS. The catalog is generated Swift: the package
  declares no bundle resource and parses nothing at run time.
