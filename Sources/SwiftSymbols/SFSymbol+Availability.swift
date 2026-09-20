import Foundation

extension SFSymbol {
  /// The first release of each Apple platform that draws a symbol.
  ///
  /// Read it from ``SFSymbol/availability``, which answers from the catalog. A symbol the
  /// catalog does not list has none.
  ///
  /// ```swift
  /// SFSymbol.plus.availability?.macOS    // Version(major: 10, minor: 15)
  /// ```
  public struct Availability: Hashable, Sendable {
    /// The first iOS and iPadOS release that draws the symbol.
    ///
    /// ```swift
    /// SFSymbol.plus.availability?.iOS    // Version(major: 13, minor: 0)
    /// ```
    public let iOS: Version

    /// The first macOS release that draws the symbol.
    ///
    /// ```swift
    /// SFSymbol.plus.availability?.macOS    // Version(major: 10, minor: 15)
    /// ```
    public let macOS: Version

    /// The first tvOS release that draws the symbol.
    ///
    /// ```swift
    /// SFSymbol.plus.availability?.tvOS    // Version(major: 13, minor: 0)
    /// ```
    public let tvOS: Version

    /// The first visionOS release that draws the symbol.
    ///
    /// A symbol older than visionOS itself reports the first visionOS release.
    ///
    /// ```swift
    /// SFSymbol.plus.availability?.visionOS    // Version(major: 1, minor: 0)
    /// ```
    public let visionOS: Version

    /// The first watchOS release that draws the symbol.
    ///
    /// ```swift
    /// SFSymbol.plus.availability?.watchOS    // Version(major: 6, minor: 0)
    /// ```
    public let watchOS: Version

    /// The entry for the platform the code is built for.
    ///
    /// ```swift
    /// SFSymbol.plus.availability?.current    // the iOS entry in an iOS build
    /// ```
    public var current: Version {
      #if os(iOS)
      return iOS
      #elseif os(macOS)
      return macOS
      #elseif os(tvOS)
      return tvOS
      #elseif os(visionOS)
      return visionOS
      #elseif os(watchOS)
      return watchOS
      #else
      #error("This platform has no entry in Availability; add one and widen the release table.")
      #endif
    }
  }

  /// An OS release, as a major and a minor version.
  ///
  /// ```swift
  /// SFSymbol.Version(major: 26, minor: 1) < SFSymbol.Version(major: 27, minor: 0)    // true
  /// ```
  public struct Version: Comparable, Hashable, Sendable {
    /// The major version, such as `26`.
    public let major: Int
    /// The minor version, such as `1` in `26.1`.
    public let minor: Int

    /// Creates a version from its major and minor numbers.
    ///
    /// ```swift
    /// let release = SFSymbol.Version(major: 26, minor: 0)
    /// ```
    public init(major: Int, minor: Int) {
      self.major = major
      self.minor = minor
    }

    /// Whether one release came before another, comparing the major version and then the minor.
    ///
    /// ```swift
    /// SFSymbol.Version(major: 26, minor: 9) < SFSymbol.Version(major: 27, minor: 0)    // true
    /// ```
    public static func < (lhs: Version, rhs: Version) -> Bool {
      (lhs.major, lhs.minor) < (rhs.major, rhs.minor)
    }
  }
}

extension SFSymbol {
  /// The first release of each platform that draws the symbol, or nil for a name the catalog
  /// does not list.
  ///
  /// A name reached through ``init(unchecked:)`` that the catalog does not list has none, and so
  /// does a base the catalog records without drawing it.
  ///
  /// ```swift
  /// SFSymbol.plus.availability?.iOS                       // Version(major: 13, minor: 0)
  /// SFSymbol(unchecked: "cooperlabs.logo").availability     // nil
  /// ```
  public var availability: Availability? {
    guard let row = SymbolTable.index(of: name) else { return nil }
    return SymbolTable.release(row)
  }

  /// Whether the running OS is at or above the symbol's ``availability``.
  ///
  /// A symbol with no availability is treated as available, so a name newer than the catalog or
  /// a custom symbol is never reported missing.
  ///
  /// ```swift
  /// SFSymbol.plus.isAvailable                              // true, iOS 13 and later
  /// SFSymbol(unchecked: "cooperlabs.logo").isAvailable     // true, nothing is known
  /// ```
  public var isAvailable: Bool {
    guard let availability else { return true }
    let release = availability.current
    return ProcessInfo.processInfo.isOperatingSystemAtLeast(
      OperatingSystemVersion(
        majorVersion: release.major,
        minorVersion: release.minor,
        patchVersion: 0
      )
    )
  }
}

extension SymbolTable {
  /// The first release of each platform that draws the symbol in the given row.
  ///
  /// ``yearIndex`` selects the row of ``releases``, whose numbers are the major and minor
  /// version of each platform in the order ``SFSymbol/Availability`` stores them.
  static func release(_ index: Int) -> SFSymbol.Availability {
    let row = Int(yearIndex[index]) * numbersPerRelease
    return SFSymbol.Availability(
      iOS: version(at: row),
      macOS: version(at: row + 2),
      tvOS: version(at: row + 4),
      visionOS: version(at: row + 6),
      watchOS: version(at: row + 8)
    )
  }

  /// How many numbers one release occupies in ``releases``: a major and a minor version for each
  /// of the five platforms.
  private static let numbersPerRelease = 10

  /// The release the numbers at and after the given position in ``releases`` spell.
  private static func version(at position: Int) -> SFSymbol.Version {
    SFSymbol.Version(major: Int(releases[position]), minor: Int(releases[position + 1]))
  }
}
