# Changelog

All notable changes are documented here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

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
