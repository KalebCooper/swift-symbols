extension SFSymbol {
  /// The suffixes SwiftUI models as symbol variants: `circle`, `fill`, `rectangle`, `slash`,
  /// and `square`, in any combination the catalog contains.
  public struct Variant: Hashable, OptionSet, Sendable {
    /// The bit pattern of the set.
    public let rawValue: UInt8

    /// Creates a set from its bit pattern.
    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }

    /// The `.circle` suffix.
    public static let circle = Variant(rawValue: 1 << 0)
    /// The `.fill` suffix.
    public static let fill = Variant(rawValue: 1 << 1)
    /// The `.rectangle` suffix.
    public static let rectangle = Variant(rawValue: 1 << 2)
    /// The `.slash` suffix.
    public static let slash = Variant(rawValue: 1 << 3)
    /// The `.square` suffix.
    public static let square = Variant(rawValue: 1 << 4)
  }
}

extension SFSymbol {
  /// The symbol with every variant suffix removed.
  ///
  /// A few bases are not drawn themselves, and a name the catalog does not list is its own base.
  /// Both still answer ``variants``, ``applying(_:)``, and ``resolving(_:)``.
  ///
  /// ```swift
  /// SFSymbol.bellSlashCircleFill.base    // .bell
  /// SFSymbol.plus.base                   // .plus
  /// ```
  public var base: SFSymbol {
    guard let placement else { return self }
    return SFSymbol(unchecked: SymbolTable.baseName(placement.base))
  }

  /// The symbol drawn inside a circle, or the symbol itself when the catalog has no such name.
  ///
  /// ```swift
  /// SFSymbol.plus.circle    // .plusCircle
  /// ```
  public var circle: SFSymbol { applying(.circle) }

  /// The filled symbol, or the symbol itself when the catalog has no such name.
  ///
  /// ```swift
  /// SFSymbol.plusCircle.fill    // .plusCircleFill
  /// ```
  public var fill: SFSymbol { applying(.fill) }

  /// The symbol drawn inside a rectangle, or the symbol itself when the catalog has no such name.
  ///
  /// ```swift
  /// SFSymbol.numbers.rectangle    // .numbersRectangle
  /// ```
  public var rectangle: SFSymbol { applying(.rectangle) }

  /// The symbol struck through, or the symbol itself when the catalog has no such name.
  ///
  /// ```swift
  /// SFSymbol.wifi.slash    // .wifiSlash
  /// ```
  public var slash: SFSymbol { applying(.slash) }

  /// The symbol drawn inside a square, or the symbol itself when the catalog has no such name.
  ///
  /// ```swift
  /// SFSymbol.plus.square    // .plusSquare
  /// ```
  public var square: SFSymbol { applying(.square) }

  /// The variant suffixes the name carries.
  ///
  /// A name the catalog does not list carries none.
  ///
  /// ```swift
  /// SFSymbol.bellSlashCircleFill.variants    // [.circle, .fill, .slash]
  /// SFSymbol.plus.variants                   // []
  /// ```
  public var variants: Variant {
    placement?.variants ?? Variant()
  }

  /// The symbol with the given variants added, or the nearest name the catalog does list.
  ///
  /// The whole request is tried first. When the catalog draws no such symbol the last requested
  /// variant is dropped and the lookup repeats, ending at the receiver, which always resolves.
  /// Variants the receiver already carries are kept throughout, so a chain narrows the symbol
  /// one step at a time.
  ///
  /// ```swift
  /// SFSymbol.plus.applying(.circle, .fill)     // .plusCircleFill
  /// SFSymbol.plus.applying(.circle, .slash)    // .plusCircle, no plus in a slashed circle
  /// SFSymbol.plus.applying(.fill)              // .plus, no filled plus
  /// ```
  public func applying(_ variants: Variant...) -> SFSymbol {
    applying(variants)
  }

  /// Whether the catalog draws the symbol with `variant` added.
  ///
  /// ```swift
  /// SFSymbol.plus.hasVariant(.circle)    // true
  /// SFSymbol.plus.hasVariant(.fill)      // false
  /// ```
  public func hasVariant(_ variant: Variant) -> Bool {
    resolving(variant) != nil
  }

  /// The symbol carrying exactly its own variants plus `variants`, or nil when the catalog draws
  /// no such symbol.
  ///
  /// Unlike ``applying(_:)`` this never falls back, so it reports whether one exact combination
  /// exists.
  ///
  /// ```swift
  /// SFSymbol.plus.resolving([.circle, .fill])    // .plusCircleFill
  /// SFSymbol.plus.resolving(.fill)               // nil
  /// ```
  public func resolving(_ variants: Variant) -> SFSymbol? {
    guard let placement,
      let row = SymbolTable.index(
        base: placement.base,
        variants: placement.variants.union(variants).rawValue
      )
    else { return nil }
    return SFSymbol(unchecked: SymbolTable.names[row])
  }

  /// The variants added in request order, falling back as ``applying(_:)`` describes.
  ///
  /// The array form serves a caller that already holds the variants, such as an image
  /// initializer forwarding its own variadic parameter.
  package func applying(_ variants: [Variant]) -> SFSymbol {
    var requested = variants
    while requested.isEmpty == false {
      let combined = requested.reduce(into: Variant()) { $0.formUnion($1) }
      if let resolved = resolving(combined) {
        return resolved
      }
      requested.removeLast()
    }
    return self
  }

  /// Where the catalog places the name: the row of its base, and the variants that tell it apart
  /// from that base.
  ///
  /// A catalogued name reads both from its own row. A name that is only the base of other
  /// symbols has that base and no variants. Any other name is absent, and every variant query
  /// then answers from the receiver alone.
  private var placement: (base: Int, variants: Variant)? {
    if let row = SymbolTable.index(of: name) {
      return (Int(SymbolTable.baseIndex[row]), Variant(rawValue: SymbolTable.variantBits[row]))
    }
    guard let base = SymbolTable.baseIndex(of: name) else { return nil }
    return (base, Variant())
  }
}
