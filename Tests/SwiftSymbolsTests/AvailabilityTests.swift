import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite("Availability", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AvailabilityTests {
  @Test("A name the catalog does not list has no availability and is treated as available")
  func aNameTheCatalogDoesNotListHasNoAvailabilityAndIsTreatedAsAvailable() throws {
    let custom = SFSymbol(unchecked: "cooperlabs.logo")
    #expect(custom.availability == nil)
    #expect(custom.isAvailable)
    let orphan = SFSymbol(unchecked: try #require(SymbolTable.orphanBases.first))
    #expect(orphan.availability == nil)
    #expect(orphan.isAvailable)
  }

  @Test("A symbol from the first release is available on any supported OS")
  func aSymbolFromTheFirstReleaseIsAvailableOnAnySupportedOS() throws {
    let availability = try #require(SFSymbol.plus.availability)
    #expect(availability.iOS == SFSymbol.Version(major: 13, minor: 0))
    #expect(availability.macOS == SFSymbol.Version(major: 10, minor: 15))
    #expect(availability.watchOS == SFSymbol.Version(major: 6, minor: 0))
    #expect(SFSymbol.plus.isAvailable)
  }

  @Test("A version compares by major version and then minor")
  func aVersionComparesByMajorVersionAndThenMinor() {
    #expect(SFSymbol.Version(major: 26, minor: 0) < SFSymbol.Version(major: 27, minor: 0))
    #expect(SFSymbol.Version(major: 26, minor: 9) < SFSymbol.Version(major: 27, minor: 0))
    #expect(SFSymbol.Version(major: 26, minor: 0) < SFSymbol.Version(major: 26, minor: 1))
    #expect(SFSymbol.Version(major: 26, minor: 1) > SFSymbol.Version(major: 26, minor: 0))
    #expect(SFSymbol.Version(major: 26, minor: 0) == SFSymbol.Version(major: 26, minor: 0))
  }

  @Test("Every catalogued name reads the release its year selects")
  func everyCataloguedNameReadsTheReleaseItsYearSelects() {
    let misread = SymbolTable.names.indices.filter { row in
      guard let availability = SFSymbol(unchecked: SymbolTable.names[row]).availability else {
        return true
      }
      return versions(of: availability) != releaseRow(Int(SymbolTable.yearIndex[row]))
    }
    #expect(misread.isEmpty, "\(misread.prefix(3).map { SymbolTable.names[$0] })")
  }

  @Test("The current version is the entry of the platform under test")
  func theCurrentVersionIsTheEntryOfThePlatformUnderTest() throws {
    let availability = try #require(SFSymbol.plus.availability)
    #if os(iOS)
    #expect(availability.current == availability.iOS)
    #elseif os(macOS)
    #expect(availability.current == availability.macOS)
    #elseif os(tvOS)
    #expect(availability.current == availability.tvOS)
    #elseif os(visionOS)
    #expect(availability.current == availability.visionOS)
    #elseif os(watchOS)
    #expect(availability.current == availability.watchOS)
    #endif
  }

  @Test("The newest symbols read the last row of the release table")
  func theNewestSymbolsReadTheLastRowOfTheReleaseTable() throws {
    let newest = try #require(SymbolTable.yearIndex.max())
    let expected = releaseRow(Int(newest))
    let rows = SymbolTable.names.indices.filter { SymbolTable.yearIndex[$0] == newest }
    #expect(rows.isEmpty == false)
    let misread = rows.filter { row in
      guard let availability = SFSymbol(unchecked: SymbolTable.names[row]).availability else {
        return true
      }
      return versions(of: availability) != expected
    }
    #expect(misread.isEmpty, "\(misread.prefix(3).map { SymbolTable.names[$0] })")
  }

  /// The versions of one row of the release table, in the order the table stores platforms.
  private func releaseRow(_ row: Int) -> [SFSymbol.Version] {
    let start = row * 10
    return stride(from: start, to: start + 10, by: 2).map { position in
      SFSymbol.Version(
        major: Int(SymbolTable.releases[position]),
        minor: Int(SymbolTable.releases[position + 1])
      )
    }
  }

  /// The platform entries of an availability, in the same order as ``releaseRow(_:)``.
  private func versions(of availability: SFSymbol.Availability) -> [SFSymbol.Version] {
    [
      availability.iOS, availability.macOS, availability.tvOS, availability.visionOS,
      availability.watchOS,
    ]
  }
}
