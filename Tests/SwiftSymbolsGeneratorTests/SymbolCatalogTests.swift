import SwiftSymbolsGenerator
import SwiftSymbolsTestSupport
import Testing

@Suite("Catalog model", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SymbolCatalogTests {
  private let release2019 = [
    "iOS": "13.0", "macOS": "11.0", "tvOS": "13.0", "watchOS": "6.0", "visionOS": "1.0",
  ]
  private let release2025 = [
    "iOS": "26.0", "macOS": "26.0", "tvOS": "26.0", "watchOS": "26.0", "visionOS": "26.0",
  ]
  private let release2025_1 = [
    "iOS": "26.1", "macOS": "26.1", "tvOS": "26.1", "watchOS": "26.1", "visionOS": "26.1",
  ]
  private let release2026 = [
    "iOS": "27.0", "macOS": "27.0", "tvOS": "27.0", "watchOS": "27.0", "visionOS": "27.0",
  ]

  private func makeData() -> CoreGlyphsData {
    CoreGlyphsData(
      aliases: ["old.plus": "plus", "old.plus.ar": "plus.ar"],
      availability: [
        "plus": "2019", "plus.circle": "2019", "plus.circle.fill": "2025", "plus.ar": "2019",
        "sparkle.new": "2026", "gauge.new": "2025.1", "old.plus": "2019", "old.plus.ar": "2019",
      ],
      categories: [
        CategoryInfo(icon: "square.grid.2x2", key: "all"),
        CategoryInfo(icon: "x.squareroot", key: "math"),
      ],
      fillCounterparts: ["plus.circle": "plus.circle.fill"],
      order: ["plus", "plus.ar", "plus.circle", "plus.circle.fill", "sparkle.new", "gauge.new"],
      restrictions: ["sparkle.new": "Only for Apple things."],
      searchTerms: ["plus": ["add", "new"]],
      symbolCategories: ["plus": ["math", "all"]],
      yearToRelease: [
        "2019": release2019, "2025": release2025, "2025.1": release2025_1, "2026": release2026,
      ])
  }

  @Test("Localized names are dropped and order is kept")
  func localizedNamesAreDroppedAndOrderIsKept() throws {
    let catalog = try SymbolCatalog.build(from: makeData())
    #expect(
      catalog.entries.map(\.name) == [
        "plus", "plus.circle", "plus.circle.fill", "sparkle.new", "gauge.new",
      ])
  }

  @Test("An entry carries every field the resource needs")
  func anEntryCarriesEveryFieldTheResourceNeeds() throws {
    let catalog = try SymbolCatalog.build(from: makeData())
    let plus = try #require(catalog.entries.first)
    #expect(plus.identifier == "plus")
    #expect(plus.base == "plus")
    #expect(plus.variants.isEmpty)
    #expect(plus.year == "2019")
    #expect(plus.release == release2019)
    #expect(plus.categories == ["math"])
    #expect(plus.searchTerms == ["add", "new"])
    #expect(plus.restriction == nil)
    #expect(plus.filledName == nil)
    let circle = catalog.entries[1]
    #expect(circle.filledName == "plus.circle.fill")
    #expect(circle.variants == ["circle"])
    #expect(catalog.entries[3].restriction == "Only for Apple things.")
  }

  @Test("Only releases above the floor get an availability attribute")
  func onlyReleasesAboveTheFloorGetAnAvailabilityAttribute() throws {
    let catalog = try SymbolCatalog.build(from: makeData())
    #expect(catalog.entries[0].availabilityAttribute == nil)
    #expect(catalog.entries[2].availabilityAttribute == nil)
    #expect(
      catalog.entries[3].availabilityAttribute
        == "@available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)")
    #expect(
      catalog.entries[4].availabilityAttribute
        == "@available(iOS 26.1, macOS 26.1, tvOS 26.1, watchOS 26.1, visionOS 26.1, *)")
  }

  @Test("Aliases keep only non-localized pairs whose target is canonical")
  func aliasesKeepOnlyNonLocalizedPairsWhoseTargetIsCanonical() throws {
    let catalog = try SymbolCatalog.build(from: makeData())
    #expect(catalog.aliases.map(\.name) == ["old.plus"])
    #expect(catalog.aliases.first?.identifier == "oldPlus")
    #expect(catalog.aliases.first?.target == "plus")
    #expect(catalog.aliases.first?.targetIdentifier == "plus")
  }

  @Test("An alias whose old name is localized over a canonical stem is dropped")
  func anAliasWhoseOldNameIsLocalizedOverACanonicalStemIsDropped() throws {
    var data = makeData()
    data.aliases["plus.he"] = "plus.circle"
    let catalog = try SymbolCatalog.build(from: data)
    #expect(!catalog.aliases.map(\.name).contains("plus.he"))
  }

  @Test("An alias whose old name is not localized over a canonical stem is kept")
  func anAliasWhoseOldNameIsNotLocalizedOverACanonicalStemIsKept() throws {
    var data = makeData()
    data.aliases["gizmo.ar"] = "plus.circle"
    let catalog = try SymbolCatalog.build(from: data)
    let entry = try #require(catalog.aliases.first { $0.name == "gizmo.ar" })
    #expect(entry.target == "plus.circle")
  }

  @Test("An alias with a non-localized old name is still dropped when the target is localized")
  func anAliasWithANonLocalizedOldNameIsStillDroppedWhenTheTargetIsLocalized() throws {
    var data = makeData()
    data.aliases["gizmo.ar"] = "plus.ar"
    let catalog = try SymbolCatalog.build(from: data)
    #expect(!catalog.aliases.map(\.name).contains("gizmo.ar"))
  }

  @Test("The all category is dropped")
  func theAllCategoryIsDropped() throws {
    let catalog = try SymbolCatalog.build(from: makeData())
    #expect(catalog.categories.map(\.key) == ["math"])
  }

  @Test("The SF Symbols year is the newest year among the entries")
  func theSFSymbolsYearIsTheNewestYearAmongTheEntries() throws {
    var data = makeData()
    data.yearToRelease["2027"] = release2026
    #expect(try SymbolCatalog.build(from: data).sfSymbolsYear == 2026)
    data.order.removeAll { $0 == "sparkle.new" }
    #expect(try SymbolCatalog.build(from: data).sfSymbolsYear == 2025)
  }

  @Test("A catalog without symbols fails loudly")
  func aCatalogWithoutSymbolsFailsLoudly() {
    var data = makeData()
    data.order = []
    data.aliases = [:]
    #expect(throws: GeneratorError.unresolved("symbol_order.plist lists no canonical symbol")) {
      try SymbolCatalog.build(from: data)
    }
  }

  @Test("A name without a year fails loudly")
  func aNameWithoutAYearFailsLoudly() {
    var data = makeData()
    data.availability["plus.circle"] = nil
    #expect(throws: GeneratorError.unresolved("plus.circle has no year in name_availability.plist"))
    {
      try SymbolCatalog.build(from: data)
    }
  }

  @Test("A release row missing a platform fails loudly")
  func aReleaseRowMissingAPlatformFailsLoudly() {
    var data = makeData()
    data.yearToRelease["2026"]?["tvOS"] = nil
    #expect(
      throws: GeneratorError.unresolved(
        "sparkle.new has year 2026, whose year_to_release row has no tvOS version")
    ) {
      try SymbolCatalog.build(from: data)
    }
  }

  @Test("Two names with the same base and variants fail loudly")
  func twoNamesWithTheSameBaseAndVariantsFailLoudly() {
    var data = makeData()
    data.order.append("plus.fill.circle")
    data.availability["plus.fill.circle"] = "2019"
    #expect(
      throws: GeneratorError.collision(
        "plus.fill.circle and plus.circle.fill share base plus and variants circle,fill")
    ) {
      try SymbolCatalog.build(from: data)
    }
  }

  @Test("Two names with the same identifier fail loudly")
  func twoNamesWithTheSameIdentifierFailLoudly() {
    var data = makeData()
    data.order += ["plus.2", "plus2"]
    data.availability["plus.2"] = "2019"
    data.availability["plus2"] = "2019"
    #expect(throws: GeneratorError.collision("plus2 and plus.2 share identifier plus2")) {
      try SymbolCatalog.build(from: data)
    }
  }

  @Test("An alias sharing a canonical identifier fails loudly")
  func anAliasSharingACanonicalIdentifierFailsLoudly() {
    var data = makeData()
    data.order.append("plus.2")
    data.availability["plus.2"] = "2019"
    data.aliases["plus2"] = "plus"
    #expect(throws: GeneratorError.collision("alias plus2 and plus.2 share identifier plus2")) {
      try SymbolCatalog.build(from: data)
    }
  }

  @Test("An alias targeting a name outside the catalog fails loudly")
  func anAliasTargetingANameOutsideTheCatalogFailsLoudly() {
    var data = makeData()
    data.aliases["old.gone"] = "gone"
    #expect(
      throws: GeneratorError.unresolved("alias old.gone targets gone, which is not canonical")
    ) {
      try SymbolCatalog.build(from: data)
    }
  }
}
