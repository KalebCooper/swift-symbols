# Changelog

All notable changes are documented here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- `SymbolStyle` and the `symbolStyle(_:weight:scale:)` view modifier, which set a symbol's
  rendering mode and, for `palette(_:)`, the foreground styles of its first three layers. The
  modifier applies a font weight and an image scale only when given, and a nil for either keeps
  the value an ancestor set.
- SwiftUI initializers taking a typed symbol: `Image(_:)`, `Image(_:variants:)`, and
  `Label(_:symbol:)` for a localized or an already localized title. `SFSymbol.Variant` also
  answers `symbolVariants`, the SwiftUI value for `symbolVariant(_:)`.
- `SFSymbol.all`, listing every catalogued symbol once, in the order Apple's SF Symbols app
  shows them. The list is built on first use.
- Availability on `SFSymbol`: `availability`, reporting the first release of each Apple platform
  that draws the symbol, the `Availability` and `Version` types it answers with, and
  `isAvailable`, which compares the running OS against the entry for the platform it is built
  for. A name the catalog does not list has no availability and is reported available.
- Variant resolution on `SFSymbol`: `base`, `variants`, `applying(_:)`, `resolving(_:)`,
  `hasVariant(_:)`, and the `circle`, `fill`, `rectangle`, `slash`, and `square` properties.
  Applying a combination the catalog does not draw falls back to the nearest name it does.
- `SFSymbol(name:)`, which initializes a symbol from a catalogued name, accepts a deprecated name
  and returns the current one, and fails on a name the catalog does not list. `SFSymbol` also
  conforms to `Codable`, encoding as its name, and to `CustomStringConvertible` and `Identifiable`.
- `SFSymbol.Variant`, the option set naming the `circle`, `fill`, `rectangle`, `slash`, and
  `square` suffixes.
- The `SFSymbol` type, the catalog generator, and `Scripts/generate-catalog.sh`, which regenerates
  the checked-in catalog from the system SF Symbols metadata.
- SwiftSymbols and SwiftSymbolsUI module foundations, with no public API.
- Shared test support with the suite time limit, and wiring checks for both products.
- Documentation catalogs, the verification gate, and CI and docs workflows.
