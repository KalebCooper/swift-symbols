# Availability

Know which releases draw a symbol, and where the rest of Apple's metadata lives.

## Overview

``SFSymbol/availability`` reports the first release of each Apple platform that draws the symbol.
A name the catalog does not list, including every name from ``SFSymbol/init(unchecked:)``, has none.

```swift
SFSymbol.plus.availability?.iOS        // SFSymbol.Version(major: 13, minor: 0)
SFSymbol.plus.availability?.current    // the entry for the platform being built for
```

``SFSymbol/Version`` is `Comparable`, so a symbol can be measured against a release you care about
without taking the numbers apart.

```swift
let floor = SFSymbol.Version(major: 26, minor: 0)
let isNew = SFSymbol.plus.availability.map { $0.current >= floor } ?? false
```

### Checked by the compiler, checked at run time

The package's platform floor is 26, and a symbol that arrived after it carries `@available`. The
compiler asks for the check, so a symbol too new for a deployment target cannot be used unguarded.

```swift
if #available(iOS 26.1, *) {
  let symbol = SFSymbol.buttonHorizontalTop
}
```

A symbol chosen from data rather than written in source gets no such check, so
``SFSymbol/isAvailable`` compares the running system against the symbol's entry for the platform it
was built for. A symbol with no availability is reported available, so a name newer than the catalog
and a name of your own are never called missing.

```swift
let symbols = SFSymbol.all.filter(\.isAvailable)
```

### Search terms, categories, and restrictions

Apple's search terms for a symbol, the categories it belongs to, and any restriction Apple places on
its use are part of the documentation of each member rather than API. They appear in Xcode quick
help and on this site, above the declaration. ``SFSymbol/accessibility`` carries Apple's restriction
text, which limits that symbol to referring to Apple's accessibility features.

### The release the catalog came from

``SFSymbol/catalogVersion`` names the SF Symbols release and the macOS build the checked-in catalog
was generated from. A newer SF Symbols release reaches the package only when the catalog is
regenerated, so a symbol added after that build is unknown until then and can still be named with
``SFSymbol/init(unchecked:)``.

```swift
SFSymbol.catalogVersion.sfSymbolsYear    // 2026
SFSymbol.catalogVersion.macOSBuild       // "26A428"
```
