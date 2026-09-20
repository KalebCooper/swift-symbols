# Referencing symbols

Name a symbol with a typed member instead of a string.

## Overview

Every symbol in the catalog is a static member of ``SFSymbol``. The member name is the system name
in camel case, so `plus.circle.fill` is ``SFSymbol/plusCircleFill``. A name that begins with a digit
takes a leading underscore, and a name that collides with a Swift keyword is declared in backticks
and written after a dot without them.

```swift
let symbols: [SFSymbol] = [.plus, .plusCircleFill, ._0Circle, .repeat]
```

A member spelled with a leading underscore, such as `_0Circle` for `0.circle`, has no page on this
site and does not turn up in its search, because the documentation compiler leaves out every
declaration whose name begins with one. Autocompletion still offers these members, and Xcode quick
help still shows each one's documentation, search terms and all. Look for `0.circle` by its
spelling, `._0Circle`, in Xcode rather than here.

A symbol Apple has renamed keeps its old member, marked deprecated and forwarding to the current
one, so existing code still compiles and the warning names the replacement.

### Names that arrive at run time

``SFSymbol/init(name:)`` checks a name against the catalog and resolves a renamed symbol to its
current name. It returns nil for a name the catalog does not list.

```swift
SFSymbol(name: "plus.circle.fill")    // .plusCircleFill
SFSymbol(name: "not.a.symbol")        // nil
```

``SFSymbol/init(unchecked:)`` skips the catalog, for a symbol newer than the catalog or one of your
own. The result carries its name and nothing else: it has no ``SFSymbol/availability`` and reports
no ``SFSymbol/variants``, and it draws only if the name is right.

```swift
let logo = SFSymbol(unchecked: "cooperlabs.logo")
logo.name        // "cooperlabs.logo"
logo.variants    // []
```

``SFSymbol`` is `Hashable` and `Sendable`, encodes and decodes as its name alone, and is
`Identifiable` by that name, so a symbol travels in a model or a `ForEach` without a wrapper.

```swift
struct Shortcut: Codable, Identifiable {
  let id: UUID
  let symbol: SFSymbol
  let title: String
}
```

### The whole catalog

``SFSymbol/all`` lists each catalogued symbol once, in the order Apple's SF Symbols app shows them,
leaving out the deprecated names. The list is built the first time it is read and reused after that.

```swift
SFSymbol.all.count                    // how many symbols the catalog holds
SFSymbol.all.filter(\.isAvailable)    // the ones the running system draws
```
