# Working with variants

Move between a symbol and its circled, filled, slashed, and enclosed forms.

## Overview

An SF Symbol name is a base name plus a chain of suffixes. ``SFSymbol/Variant`` models the five
suffixes SwiftUI also models, `circle`, `fill`, `rectangle`, `slash`, and `square`, and the catalog
knows which of their combinations Apple actually draws.

```swift
SFSymbol.plus.circle.fill           // .plusCircleFill
SFSymbol.plusCircleFill.base        // .plus
SFSymbol.plusCircleFill.variants    // [.circle, .fill]
```

Any other suffix belongs to the base name and stays there. ``SFSymbol/bellBadge`` is a base of its
own, not ``SFSymbol/bell`` with a badge variant.

### Asking for a form that may not exist

``SFSymbol/applying(_:)`` and the five properties resolve through the catalog. When no symbol
carries the whole request, the last variant asked for is dropped and the lookup runs again, down to
the receiver, which always resolves. Variants the receiver already carries are kept throughout, so
chaining narrows a symbol one step at a time and never lands on a name that draws nothing.

```swift
SFSymbol.plus.applying(.circle, .fill)     // .plusCircleFill
SFSymbol.plus.applying(.circle, .slash)    // .plusCircle, no plus is slashed inside a circle
SFSymbol.plus.fill                         // .plus, there is no filled plus
```

### Asking whether it exists

``SFSymbol/resolving(_:)`` answers with exactly the requested combination or with nil, and
``SFSymbol/hasVariant(_:)`` asks the same question and answers with a Bool. Use them where a
fallback would be misleading, such as choosing between two designs.

```swift
SFSymbol.plus.resolving([.circle, .fill])    // .plusCircleFill
SFSymbol.plus.resolving(.fill)               // nil
SFSymbol.plus.hasVariant(.circle)            // true
SFSymbol.plus.hasVariant(.fill)              // false
```

A symbol from ``SFSymbol/init(unchecked:)`` is its own base, reports no variants, and resolves
nothing, because the catalog has nothing to say about it.
