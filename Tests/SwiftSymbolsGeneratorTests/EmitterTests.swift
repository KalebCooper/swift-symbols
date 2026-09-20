import Foundation
import SwiftSymbolsGenerator
import SwiftSymbolsTestSupport
import Testing

@Suite("Emitter", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct EmitterTests {
  private let release2019 = [
    "iOS": "13.0", "macOS": "11.0", "tvOS": "13.0", "watchOS": "6.0", "visionOS": "1.0",
  ]
  private let release2026 = [
    "iOS": "27.0", "macOS": "27.0", "tvOS": "27.0", "watchOS": "27.0", "visionOS": "27.0",
  ]

  private func makeData() -> CoreGlyphsData {
    CoreGlyphsData(
      aliases: ["old.plus": "plus"],
      availability: [
        "plus": "2019", "plus.circle": "2019", "0.circle": "2019", "repeat": "2019",
        "sparkle.new": "2026", "old.plus": "2019",
      ],
      categories: [
        CategoryInfo(icon: "square.grid.2x2", key: "all"),
        CategoryInfo(icon: "x.squareroot", key: "math"),
      ],
      fillCounterparts: ["plus.circle": "plus.circle.fill"],
      order: ["0.circle", "plus", "plus.circle", "repeat", "sparkle.new"],
      restrictions: ["sparkle.new": "Apple's \"new\" things only."],
      searchTerms: ["plus": ["add", "new, improved"]],
      symbolCategories: ["plus": ["math"]],
      yearToRelease: ["2019": release2019, "2026": release2026])
  }

  /// The fixture plus Apple names long enough to need every line break the emitter makes.
  private func longNameData() -> CoreGlyphsData {
    let car =
      "car.rear.road.lane.distance.1.and.gauge.open.with.lines.needle.67percent.and.arrowtriangle"
    let figure =
      "figure.seated.side.left.windshield.front.and.heat.waves.air.distribution.upper.and.middle.and.lower"
    let old =
      "figure.seated.side.windshield.front.and.heat.waves.air.distribution.upper.and.middle.and.lower"
    var data = makeData()
    data.order += [car, figure]
    data.availability[car] = "2019"
    data.availability[figure] = "2019"
    data.availability[old] = "2019"
    data.aliases[old] = figure
    return data
  }

  /// A fixture with more names than one literal holds, so a column has to be split.
  private func wideData() -> CoreGlyphsData {
    var data = CoreGlyphsData(
      aliases: [:],
      availability: [:],
      categories: [],
      fillCounterparts: [:],
      order: [],
      restrictions: [:],
      searchTerms: [:],
      symbolCategories: [:],
      yearToRelease: ["2019": release2019])
    for index in 0..<130 {
      let name = "sym\(String(format: "%03d", index))"
      data.order.append(name)
      data.availability[name] = "2019"
    }
    return data
  }

  private func makeFiles(_ data: CoreGlyphsData? = nil) throws -> [GeneratedFile] {
    try Emitter(build: "26A428", catalog: try SymbolCatalog.build(from: data ?? makeData())).files()
  }

  private func file(_ path: String, in files: [GeneratedFile]) throws -> String {
    try #require(files.first { $0.path == path }).contents
  }

  /// Every table file's text, so a column is found wherever the emitter grouped it.
  private func tables(_ files: [GeneratedFile]) -> String {
    files.filter { $0.path.contains("SymbolTable") }.map(\.contents).joined()
  }

  /// The elements of one literal, or nil when `source` declares no such literal.
  private func literal(_ name: String, _ type: String, in source: String) -> [String]? {
    guard let opening = source.range(of: "static let \(name): [\(type)] = [\n") else { return nil }
    guard let closing = source.range(of: "\n  ]\n", range: opening.upperBound..<source.endIndex)
    else { return nil }
    return source[opening.upperBound..<closing.lowerBound]
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  /// The elements of a column, whether it is one literal or a chunked one, in composed order.
  private func column(_ name: String, _ type: String, in source: String) -> [String] {
    if let single = literal(name, type, in: source) { return single }
    var elements: [String] = []
    var chunk = 0
    while let piece = literal("\(name)\(chunk)", type, in: source) {
      elements += piece
      chunk += 1
    }
    return elements
  }

  @Test("Every file starts with the header")
  func everyFileStartsWithTheHeader() throws {
    let files = try makeFiles()
    #expect(files.count == 11)
    for file in files {
      #expect(file.contents.hasPrefix(Emitter.headerPrefix), "\(file.path)")
      #expect(file.contents.contains("SF Symbols 2026"), "\(file.path)")
      #expect(file.contents.contains("macOS build 26A428"), "\(file.path)")
      #expect(file.contents.contains("Do not edit."), "\(file.path)")
    }
  }

  @Test("Every file is generated Swift under one directory")
  func everyFileIsGeneratedSwiftUnderOneDirectory() throws {
    for file in try makeFiles() {
      #expect(file.path.hasPrefix("Sources/SwiftSymbols/Generated/"), "\(file.path)")
      #expect(file.path.hasSuffix(".swift"), "\(file.path)")
      #expect(file.path.contains("Category") == false, "\(file.path)")
    }
  }

  @Test("Symbols are split by first character with a digits file")
  func symbolsAreSplitByFirstCharacterWithADigitsFile() throws {
    let paths = try makeFiles().map(\.path)
    #expect(
      paths.filter { $0.contains("SFSymbol+Symbols-") } == [
        "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-digits.swift",
        "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-p.swift",
        "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-r.swift",
        "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-s.swift",
      ])
  }

  @Test("A symbol declaration carries its documentation and availability")
  func aSymbolDeclarationCarriesItsDocumentationAndAvailability() throws {
    let files = try makeFiles()
    let p = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-p.swift", in: files)
    #expect(
      p.contains(
        """
          /// `plus`
          ///
          /// Categories: math. Search terms: add, new, improved.
          ///
          /// Available since iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, visionOS 1.0.
          public static var plus: SFSymbol {
            SFSymbol(unchecked: "plus")
          }

        """))
    let s = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-s.swift", in: files)
    #expect(
      s.contains(
        """
          /// Restriction: Apple's "new" things only.
          @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
          public static var sparkleNew: SFSymbol {
            SFSymbol(unchecked: "sparkle.new")
          }

        """))
    let digits = try file(
      "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-digits.swift", in: files)
    #expect(
      digits.contains(
        "public static var _0Circle: SFSymbol {\n    SFSymbol(unchecked: \"0.circle\")\n  }"))
    let r = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-r.swift", in: files)
    #expect(
      r.contains("public static var `repeat`: SFSymbol {\n    SFSymbol(unchecked: \"repeat\")\n  }")
    )
  }

  @Test("A symbol with no categories or search terms documents only its name and availability")
  func aSymbolWithNoCategoriesOrSearchTermsDocumentsOnlyItsNameAndAvailability() throws {
    let r = try file(
      "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-r.swift", in: try makeFiles())
    #expect(
      r.contains(
        """
          /// `repeat`
          ///
          /// Available since iOS 13.0, macOS 11.0, tvOS 13.0, watchOS 6.0, visionOS 1.0.
          public static var `repeat`: SFSymbol {

        """))
    #expect(r.contains("Categories:") == false)
    #expect(r.contains("Search terms:") == false)
  }

  @Test("Availability comes from the release table, not from literals")
  func availabilityComesFromTheReleaseTableNotFromLiterals() throws {
    var data = makeData()
    data.yearToRelease["2026"] = [
      "iOS": "28.1", "macOS": "29.2", "tvOS": "30.3", "watchOS": "31.4", "visionOS": "32.5",
    ]
    let s = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-s.swift", in: makeFiles(data))
    #expect(
      s.contains("  @available(iOS 28.1, macOS 29.2, tvOS 30.3, watchOS 31.4, visionOS 32.5, *)\n"))
    #expect(s.contains("27.0") == false)
  }

  @Test("Long documentation is wrapped under the line limit")
  func longDocumentationIsWrappedUnderTheLineLimit() throws {
    var data = makeData()
    data.searchTerms["plus"] = Array(repeating: "addition", count: 30)
    let p = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-p.swift", in: makeFiles(data))
    let docLines = p.split(separator: "\n").filter { $0.hasPrefix("  /// ") }
    #expect(docLines.count > 4)
    #expect(docLines.allSatisfy { $0.count <= 100 })
    let wrapped = Emitter.wrap(
      String(repeating: "word ", count: 40).trimmingCharacters(in: .whitespaces))
    #expect(wrapped.count == 3)
    #expect(wrapped.allSatisfy { $0.count <= 94 })
  }

  @Test("An alias is a deprecated forwarding declaration")
  func anAliasIsADeprecatedForwardingDeclaration() throws {
    let aliases = try file("Sources/SwiftSymbols/Generated/SFSymbol+Aliases.swift", in: makeFiles())
    #expect(
      aliases.contains(
        """
          /// `old.plus`, renamed to ``plus``.
          @available(*, deprecated, renamed: "plus")
          public static var oldPlus: SFSymbol {
            .plus
          }

        """))
  }

  @Test("An alias of a newer symbol carries the symbol's availability")
  func anAliasOfANewerSymbolCarriesTheSymbolsAvailability() throws {
    var data = makeData()
    data.aliases["sparkle.old"] = "sparkle.new"
    data.availability["sparkle.old"] = "2019"
    let aliases = try file(
      "Sources/SwiftSymbols/Generated/SFSymbol+Aliases.swift", in: makeFiles(data))
    #expect(
      aliases.contains(
        """
          /// `sparkle.old`, renamed to ``sparkleNew``.
          @available(iOS 27.0, macOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, *)
          @available(*, deprecated, renamed: "sparkleNew")
          public static var sparkleOld: SFSymbol {
            .sparkleNew
          }

        """))
  }

  @Test("The catalog version is emitted")
  func theCatalogVersionIsEmitted() throws {
    let version = try file(
      "Sources/SwiftSymbols/Generated/CatalogVersion.swift", in: makeFiles())
    #expect(version.contains("CatalogVersion(macOSBuild: \"26A428\", sfSymbolsYear: 2026)"))
  }

  @Test("The catalog version year ignores the point release")
  func theCatalogVersionYearIgnoresThePointRelease() throws {
    var data = makeData()
    data.availability["sparkle.new"] = "2025.1"
    data.yearToRelease["2025.1"] = release2026
    let files = try makeFiles(data)
    let version = try file("Sources/SwiftSymbols/Generated/CatalogVersion.swift", in: files)
    #expect(version.contains("sfSymbolsYear: 2025)"))
    #expect(files.allSatisfy { $0.contents.contains("SF Symbols 2025,") })
  }

  @Test("The table is declared once, as package rather than public")
  func theTableIsDeclaredOnceAsPackageRatherThanPublic() throws {
    let files = try makeFiles()
    let declaration = try file(
      "Sources/SwiftSymbols/Generated/SymbolTable.swift", in: files)
    #expect(declaration.contains("package enum SymbolTable {}"))
    #expect(tables(files).contains("public ") == false)
    for file in files where file.path.contains("SymbolTable+") {
      #expect(file.contents.contains("\nextension SymbolTable {\n"), "\(file.path)")
    }
  }

  @Test("Every per-symbol column has one element per name")
  func everyPerSymbolColumnHasOneElementPerName() throws {
    let source = tables(try makeFiles())
    let names = column("names", "String", in: source)
    #expect(
      names == ["\"0.circle\"", "\"plus\"", "\"plus.circle\"", "\"repeat\"", "\"sparkle.new\""])
    for (name, type) in [
      ("baseIndex", "UInt16"), ("order", "UInt16"), ("variantBits", "UInt8"),
      ("variantOrder", "UInt16"), ("yearIndex", "UInt8"),
    ] {
      #expect(column(name, type, in: source).count == names.count, "\(name)")
    }
  }

  @Test("The order and variant columns are permutations of the rows")
  func theOrderAndVariantColumnsArePermutationsOfTheRows() throws {
    let source = tables(try makeFiles())
    let rows = column("names", "String", in: source).count
    for (name, type) in [("order", "UInt16"), ("variantOrder", "UInt16")] {
      let values = column(name, type, in: source).compactMap(Int.init)
      #expect(values.sorted() == Array(0..<rows), "\(name)")
    }
    // The canonical order is the fixture's, and the sorted order puts `0.circle` first.
    #expect(column("order", "UInt16", in: source) == ["0", "1", "2", "3", "4"])
  }

  @Test("Every index column points at a row that exists")
  func everyIndexColumnPointsAtARowThatExists() throws {
    let source = tables(try makeFiles())
    let rows = column("names", "String", in: source).count
    let orphans = column("orphanBases", "String", in: source).count
    for value in column("baseIndex", "UInt16", in: source).compactMap(Int.init) {
      #expect(value < rows + orphans)
    }
    for value in column("aliasTargets", "UInt16", in: source).compactMap(Int.init) {
      #expect(value < rows)
    }
    #expect(column("aliasNames", "String", in: source) == ["\"old.plus\""])
    #expect(column("aliasTargets", "UInt16", in: source) == ["1"])
  }

  @Test("A release is ten numbers and the variant bits describe the suffixes")
  func aReleaseIsTenNumbersAndTheVariantBitsDescribeTheSuffixes() throws {
    let source = tables(try makeFiles())
    let releases = column("releases", "UInt8", in: source)
    let years = Set(column("yearIndex", "UInt8", in: source))
    #expect(years == ["0", "1"])
    #expect(releases.count == 20)
    // Years ascend, and a row lists iOS, macOS, tvOS, visionOS, then watchOS.
    #expect(Array(releases.prefix(10)) == ["13", "0", "11", "0", "13", "0", "1", "0", "6", "0"])
    // `0.circle` and `plus.circle` are the names with a suffix, and `circle` is bit one.
    #expect(column("variantBits", "UInt8", in: source) == ["1", "0", "1", "0", "0"])
  }

  @Test("A base that is not a catalogued name becomes an orphan row")
  func aBaseThatIsNotACataloguedNameBecomesAnOrphanRow() throws {
    var data = makeData()
    data.order.append("bell.slash")
    data.availability["bell.slash"] = "2019"
    let source = tables(try makeFiles(data))
    let rows = column("names", "String", in: source).count
    // `0` is the base of `0.circle` and `bell` of `bell.slash`; neither is a name of its own.
    #expect(column("orphanBases", "String", in: source) == ["\"0\"", "\"bell\""])
    // The two orphans sit past the last name, in the order `orphanBases` lists them.
    #expect(
      Array(column("baseIndex", "UInt16", in: source).prefix(2)) == ["\(rows)", "\(rows + 1)"])
  }

  @Test("A name with a quote or a backslash keeps its escapes")
  func aNameWithAQuoteOrABackslashKeepsItsEscapes() throws {
    var data = makeData()
    for name in [#"quote"name"#, #"back\slash"#] {
      data.order.append(name)
      data.availability[name] = "2019"
    }
    let source = tables(try makeFiles(data))
    let names = column("names", "String", in: source)
    #expect(names.contains(#""back\\slash""#))
    #expect(names.contains(#""quote\"name""#))
  }

  @Test("A column longer than one literal is split and composed in order")
  func aColumnLongerThanOneLiteralIsSplitAndComposedInOrder() throws {
    let names = try file(
      "Sources/SwiftSymbols/Generated/SymbolTable+Names.swift", in: makeFiles(wideData()))
    #expect(literal("names", "String", in: names) == nil)
    #expect(literal("names0", "String", in: names)?.count == 128)
    #expect(literal("names1", "String", in: names)?.count == 2)
    #expect(literal("names1", "String", in: names) == ["\"sym128\"", "\"sym129\""])
    #expect(column("names", "String", in: names).count == 130)
    #expect(column("names", "String", in: names).first == "\"sym000\"")
    #expect(
      names.contains(
        """
          package static let names: [String] = {
            var all: [String] = []
            all.reserveCapacity(130)
            all += names0
            all += names1
            return all
          }()

        """))
  }

  @Test("Tabs and newlines inside a field become spaces")
  func tabsAndNewlinesInsideAFieldBecomeSpaces() throws {
    var data = makeData()
    data.restrictions["plus"] = "Line one.\nLine\ttwo."
    data.searchTerms["plus"] = ["a\tb", "c\nd"]
    let p = try file(
      "Sources/SwiftSymbols/Generated/SFSymbol+Symbols-p.swift", in: makeFiles(data))
    #expect(p.contains("  /// Restriction: Line one. Line two.\n"))
    #expect(p.contains("  /// Categories: math. Search terms: a b, c d.\n"))
  }

  @Test("Long names break where swift-format breaks them")
  func longNamesBreakWhereSwiftFormatBreaksThem() throws {
    let files = try makeFiles(longNameData())
    let c = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-c.swift", in: files)
    #expect(
      c.contains(
        """
          public static var carRearRoadLaneDistance1AndGaugeOpenWithLinesNeedle67percentAndArrowtriangle:
            SFSymbol
          {
            SFSymbol(
              unchecked:
                "car.rear.road.lane.distance.1.and.gauge.open.with.lines.needle.67percent.and.arrowtriangle"
            )
          }

        """))
    let f = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-f.swift", in: files)
    #expect(
      f.contains(
        """
          public static
            var figureSeatedSideLeftWindshieldFrontAndHeatWavesAirDistributionUpperAndMiddleAndLower:
            SFSymbol
          {
            SFSymbol(
              unchecked:
                "figure.seated.side.left.windshield.front.and.heat.waves.air.distribution.upper.and.middle.and.lower"
            )
          }

        """))
    let aliases = try file(
      "Sources/SwiftSymbols/Generated/SFSymbol+Aliases.swift", in: files)
    #expect(
      aliases.contains(
        """
          @available(
            *, deprecated,
            renamed: "figureSeatedSideLeftWindshieldFrontAndHeatWavesAirDistributionUpperAndMiddleAndLower"
          )
          public static
            var figureSeatedSideWindshieldFrontAndHeatWavesAirDistributionUpperAndMiddleAndLower: SFSymbol
          {
            .figureSeatedSideLeftWindshieldFrontAndHeatWavesAirDistributionUpperAndMiddleAndLower
          }

        """))
  }

  // The gate compares raw generator output with the checked-in files, and the lint runs over the
  // checked-in files, so the emitter itself has to produce swift-format's layout: two-space
  // indentation, no trailing whitespace, one final newline, and no line over 100 columns unless
  // it is a single token, such as a name, that no break can shorten.
  @Test("Swift output keeps swift-format's layout")
  func swiftOutputKeepsSwiftFormatsLayout() throws {
    var data = longNameData()
    data.searchTerms["plus"] = Array(repeating: "addition", count: 30)
    for file in try makeFiles(data) + makeFiles(wideData()) {
      #expect(file.contents.hasSuffix("}\n"), "\(file.path)")
      #expect(file.contents.contains("\n\n\n") == false, "\(file.path)")
      #expect(file.contents.contains("\t") == false, "\(file.path)")
      for line in file.contents.split(separator: "\n") {
        let text = line.drop { $0 == " " }
        let content = text.hasPrefix("/// ") ? text.dropFirst(4) : text
        #expect(line.count <= 100 || content.contains(" ") == false, "\(file.path): \(line)")
        #expect(line.last?.isWhitespace != true, "\(file.path): \(line)")
        #expect((line.count - text.count) % 2 == 0, "\(file.path): \(line)")
      }
    }
  }

  @Test("Output is deterministic")
  func outputIsDeterministic() throws {
    let catalog = try SymbolCatalog.build(from: makeData())
    let first = try Emitter(build: "26A428", catalog: catalog).files()
    let second = try Emitter(build: "26A428", catalog: catalog).files()
    let rebuilt = Emitter(build: "26A428", catalog: try SymbolCatalog.build(from: makeData()))
    #expect(first == second)
    #expect(first == (try rebuilt.files()))
  }
}
