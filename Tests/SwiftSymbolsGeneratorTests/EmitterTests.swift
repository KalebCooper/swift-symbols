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

  private func makeFiles(_ data: CoreGlyphsData? = nil) throws -> [GeneratedFile] {
    Emitter(build: "26A428", catalog: try SymbolCatalog.build(from: data ?? makeData())).files()
  }

  private func file(_ path: String, in files: [GeneratedFile]) throws -> String {
    try #require(files.first { $0.path == path }).contents
  }

  @Test("Every file starts with the header")
  func everyFileStartsWithTheHeader() throws {
    let files = try makeFiles()
    #expect(files.count == 10)
    for file in files {
      let isSwift = file.path.hasSuffix(".swift")
      let prefix = isSwift ? Emitter.headerPrefix : Emitter.resourceHeaderPrefix
      #expect(file.contents.hasPrefix(prefix), "\(file.path)")
      #expect(file.contents.contains("SF Symbols 2026"), "\(file.path)")
      #expect(file.contents.contains("macOS build 26A428"), "\(file.path)")
      #expect(file.contents.contains("Do not edit."), "\(file.path)")
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

  @Test("Categories and the catalog version are emitted")
  func categoriesAndTheCatalogVersionAreEmitted() throws {
    let files = try makeFiles()
    let categories = try file(
      "Sources/SwiftSymbols/Generated/SFSymbol.Category+All.swift", in: files)
    #expect(
      categories.contains(
        """
          /// The `math` category. Apple's icon for it is `x.squareroot`.
          public static var math: SFSymbol.Category {
            SFSymbol.Category(key: "math")
          }

        """))
    #expect(categories.contains("key: \"all\"") == false)
    let version = try file("Sources/SwiftSymbols/Generated/CatalogVersion.swift", in: files)
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

  @Test("Resource rows are tab separated with escaped fields")
  func resourceRowsAreTabSeparatedWithEscapedFields() throws {
    let files = try makeFiles()
    let symbols = try file("Sources/SwiftSymbols/Resources/symbols.tsv", in: files)
    let lines = symbols.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(
      lines[0]
        == "# Generated by swift-symbols-generate from SF Symbols 2026, macOS build 26A428. Do not edit."
    )
    #expect(lines[1] == "0.circle\t2019\t13.0\t11.0\t13.0\t6.0\t1.0\t\t\t\t\t0\tcircle")
    #expect(
      lines[2] == "plus\t2019\t13.0\t11.0\t13.0\t6.0\t1.0\tmath\tadd,new improved\t\t\tplus\t")
    #expect(
      lines[3]
        == "plus.circle\t2019\t13.0\t11.0\t13.0\t6.0\t1.0\t\t\t\tplus.circle.fill\tplus\tcircle")
    #expect(
      lines[5]
        == "sparkle.new\t2026\t27.0\t27.0\t27.0\t27.0\t27.0\t\t\tApple's \"new\" things only.\t\tsparkle.new\t"
    )
    #expect(lines.last == "")
    #expect(
      lines.dropFirst().dropLast().allSatisfy {
        $0.split(separator: "\t", omittingEmptySubsequences: false).count == 13
      })
    let aliases = try file("Sources/SwiftSymbols/Resources/aliases.tsv", in: files)
    #expect(aliases.split(separator: "\n")[1] == "old.plus\tplus")
    let categories = try file("Sources/SwiftSymbols/Resources/categories.tsv", in: files)
    #expect(categories.split(separator: "\n").dropFirst() == ["math\tx.squareroot"])
  }

  @Test("Tabs and newlines inside a field become spaces")
  func tabsAndNewlinesInsideAFieldBecomeSpaces() throws {
    var data = makeData()
    data.restrictions["plus"] = "Line one.\nLine\ttwo."
    data.searchTerms["plus"] = ["a\tb", "c\nd"]
    let files = try makeFiles(data)
    let symbols = try file("Sources/SwiftSymbols/Resources/symbols.tsv", in: files)
    let plus = try #require(symbols.split(separator: "\n").first { $0.hasPrefix("plus\t") })
    let fields = plus.split(separator: "\t", omittingEmptySubsequences: false)
    #expect(fields[8] == "a b,c d")
    #expect(fields[9] == "Line one. Line two.")
    let p = try file("Sources/SwiftSymbols/Generated/SFSymbol+Symbols-p.swift", in: files)
    #expect(p.contains("  /// Restriction: Line one. Line two.\n"))
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
    for file in try makeFiles(data) where file.path.hasSuffix(".swift") {
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
    let first = Emitter(build: "26A428", catalog: catalog).files()
    let second = Emitter(build: "26A428", catalog: catalog).files()
    let rebuilt = Emitter(build: "26A428", catalog: try SymbolCatalog.build(from: makeData()))
    #expect(first == second)
    #expect(first == rebuilt.files())
  }
}
