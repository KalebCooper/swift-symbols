import Foundation
import SwiftSymbolsGenerator
import SwiftSymbolsTestSupport
import Testing

@Suite("CoreGlyphs data loading", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct CoreGlyphsDataTests {
  /// Writes a complete fixture bundle and returns its directory.
  private func makeFixture() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: "coreglyphs-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let encoder = PropertyListEncoder()
    func write(_ value: some Encodable, to file: String) throws {
      try encoder.encode(value).write(to: directory.appending(path: file))
    }
    struct Availability: Encodable {
      let symbols: [String: String]
      let year_to_release: [String: [String: String]]
    }
    try write(
      Availability(
        symbols: [
          "plus": "2019", "plus.circle": "2019", "plus.circle.ar": "2019", "old.plus": "2019",
        ],
        year_to_release: [
          "2019": [
            "iOS": "13.0", "macOS": "11.0", "tvOS": "13.0", "watchOS": "6.0", "visionOS": "1.0",
          ]
        ]),
      to: "name_availability.plist")
    try write(["plus", "plus.circle", "plus.circle.ar"], to: "symbol_order.plist")
    try write(["old.plus": "plus"], to: "name_aliases.strings")
    try write(["plus.circle": "plus.circle.fill"], to: "nofill_to_fill.strings")
    try write(
      [["key": "all", "icon": "square.grid.2x2"], ["key": "math", "icon": "x.squareroot"]],
      to: "categories.plist")
    try write(["plus": ["math"]], to: "symbol_categories.plist")
    try write(["plus": ["add", "new"]], to: "symbol_search.plist")
    try write(["plus": "Only for adding."], to: "symbol_restrictions.strings")
    return directory
  }

  @Test("Every file is decoded into the data model")
  func everyFileIsDecodedIntoTheDataModel() throws {
    let data = try CoreGlyphsData.load(from: try makeFixture())
    #expect(data.order == ["plus", "plus.circle", "plus.circle.ar"])
    #expect(data.availability["plus"] == "2019")
    #expect(data.yearToRelease["2019"]?["iOS"] == "13.0")
    #expect(data.aliases["old.plus"] == "plus")
    #expect(data.fillCounterparts["plus.circle"] == "plus.circle.fill")
    #expect(data.categories.map(\.key) == ["all", "math"])
    #expect(data.categories.map(\.icon) == ["square.grid.2x2", "x.squareroot"])
    #expect(data.symbolCategories["plus"] == ["math"])
    #expect(data.searchTerms["plus"] == ["add", "new"])
    #expect(data.restrictions["plus"] == "Only for adding.")
  }

  @Test("A missing file is reported by name")
  func aMissingFileIsReportedByName() throws {
    let directory = try makeFixture()
    try FileManager.default.removeItem(at: directory.appending(path: "symbol_search.plist"))
    #expect(throws: GeneratorError.missingFile("symbol_search.plist")) {
      try CoreGlyphsData.load(from: directory)
    }
  }

  @Test("The system directory is where macOS keeps the bundle")
  func theSystemDirectoryIsWhereMacOSKeepsTheBundle() {
    #expect(
      CoreGlyphsData.systemDirectory.path()
        .hasPrefix("/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources"))
  }
}
