import Foundation

/// A file the generator writes, with its path relative to the package root.
package struct GeneratedFile: Hashable, Sendable {
  /// The full text of the file.
  package let contents: String
  /// The path relative to the package root.
  package let path: String

  package init(contents: String, path: String) {
    self.contents = contents
    self.path = path
  }
}

/// The columns of the generated metadata table, derived from a catalog.
///
/// A row index is the position of a name in `names`, which is sorted, so every per-symbol column
/// shares one index and a binary search over `names` reaches the rest. Nothing here is a record:
/// columns of scalars and strings are what the optimizer compiles quickly.
private struct SymbolTables: Sendable {
  /// The bit each variant token contributes, matching the variant option set's raw values.
  static let variantBit: [String: UInt8] = [
    "circle": 1, "fill": 2, "rectangle": 4, "slash": 8, "square": 16,
  ]

  /// Old names, sorted, so an alias resolves by binary search.
  let aliasNames: [String]
  /// The row in `names` the alias at the same position forwards to.
  let aliasTargets: [UInt16]
  /// Each symbol's base, as a row in `names`, or `names.count + k` for `orphanBases[k]`.
  let baseIndex: [UInt16]
  /// Every catalogued name, sorted.
  let names: [String]
  /// Apple's canonical position to the row in `names`, so the catalog can be listed in order.
  let order: [UInt16]
  /// Bases that are not themselves catalogued names, sorted.
  let orphanBases: [String]
  /// Ten numbers per release: a major and a minor version for each platform, years ascending.
  let releases: [UInt8]
  /// Each symbol's variant suffixes as bits.
  let variantBits: [UInt8]
  /// Rows ordered by base then variant bits, so a pair resolves by binary search.
  let variantOrder: [UInt16]
  /// The release each symbol first appeared in, as a row of `releases`.
  let yearIndex: [UInt8]

  /// Builds every column, failing loudly rather than truncating an index or guessing a bit.
  ///
  /// - Parameters:
  ///   - catalog: The catalog to describe.
  ///   - platforms: The platforms a release lists, in the order the columns store them.
  static func build(from catalog: SymbolCatalog, platforms: [String]) throws -> SymbolTables {
    let sorted = catalog.entries.enumerated().sorted { $0.element.name < $1.element.name }
    let names = sorted.map(\.element.name)
    var order = [UInt16](repeating: 0, count: sorted.count)
    var row: [String: Int] = [:]
    for (index, item) in sorted.enumerated() {
      order[item.offset] = try self.index(index, of: item.element.name)
      row[item.element.name] = index
    }

    var orphanBases: [String] = []
    var seen: Set<String> = []
    for item in sorted
    where row[item.element.base] == nil && seen.insert(item.element.base).inserted {
      orphanBases.append(item.element.base)
    }
    orphanBases.sort()
    for (offset, base) in orphanBases.enumerated() { row[base] = names.count + offset }

    var baseIndex: [UInt16] = []
    var variantBits: [UInt8] = []
    baseIndex.reserveCapacity(sorted.count)
    variantBits.reserveCapacity(sorted.count)
    for item in sorted {
      guard let slot = row[item.element.base] else {
        throw GeneratorError.unresolved(
          "\(item.element.name) has base \(item.element.base), which has no row")
      }
      baseIndex.append(try self.index(slot, of: item.element.base))
      var bits: UInt8 = 0
      for token in item.element.variants {
        guard let bit = variantBit[token] else {
          throw GeneratorError.unresolved(
            "\(item.element.name) has variant \(token), which no bit describes")
        }
        bits |= bit
      }
      variantBits.append(bits)
    }
    let variantOrder = try (0..<sorted.count)
      .sorted { (baseIndex[$0], variantBits[$0], $0) < (baseIndex[$1], variantBits[$1], $1) }
      .map { try self.index($0, of: names[$0]) }

    var releaseByYear: [String: [String: String]] = [:]
    for entry in catalog.entries { releaseByYear[entry.year] = entry.release }
    let releaseRows = releaseByYear.sorted {
      SymbolCatalog.version($0.key).lexicographicallyPrecedes(SymbolCatalog.version($1.key))
    }
    var releases: [UInt8] = []
    var yearRow: [String: Int] = [:]
    for (offset, release) in releaseRows.enumerated() {
      yearRow[release.key] = offset
      for platform in platforms {
        let components = SymbolCatalog.version(release.value[platform])
        let major = components.first ?? 0
        let minor = components.count > 1 ? components[1] : 0
        guard let majorByte = UInt8(exactly: major), let minorByte = UInt8(exactly: minor) else {
          throw GeneratorError.unresolved(
            "release \(release.key) has \(platform) version \(major).\(minor), which a byte "
              + "column cannot hold")
        }
        releases.append(majorByte)
        releases.append(minorByte)
      }
    }
    var yearIndex: [UInt8] = []
    yearIndex.reserveCapacity(sorted.count)
    for item in sorted {
      guard let offset = yearRow[item.element.year], let byte = UInt8(exactly: offset) else {
        throw GeneratorError.unresolved(
          "\(item.element.name) has year \(item.element.year), which has no release row")
      }
      yearIndex.append(byte)
    }

    let aliases = catalog.aliases.sorted { $0.name < $1.name }
    var aliasTargets: [UInt16] = []
    aliasTargets.reserveCapacity(aliases.count)
    for alias in aliases {
      guard let slot = row[alias.target], slot < names.count else {
        throw GeneratorError.unresolved(
          "alias \(alias.name) targets \(alias.target), which has no row")
      }
      aliasTargets.append(try self.index(slot, of: alias.target))
    }

    return SymbolTables(
      aliasNames: aliases.map(\.name),
      aliasTargets: aliasTargets,
      baseIndex: baseIndex,
      names: names,
      order: order,
      orphanBases: orphanBases,
      releases: releases,
      variantBits: variantBits,
      variantOrder: variantOrder,
      yearIndex: yearIndex)
  }

  /// `value` as the index type the columns store, rather than a silent truncation.
  private static func index(_ value: Int, of name: String) throws -> UInt16 {
    guard let index = UInt16(exactly: value) else {
      throw GeneratorError.unresolved(
        "\(name) is at row \(value), which a two-byte index column cannot hold")
    }
    return index
  }
}

/// Renders a catalog as the Swift files checked into `Sources/SwiftSymbols/Generated`.
///
/// Output depends only on the catalog and the build string, so regenerating from the same data
/// produces byte-identical files and a clean diff. The output is already in swift-format's style,
/// because the repository gate compares it byte for byte with the checked-in files.
package struct Emitter: Sendable {
  /// The first words of every generated Swift file, which the repository gate looks for.
  package static let headerPrefix = "// Generated by swift-symbols-generate"

  /// The widest doc-comment text, so `  /// ` plus the text stays within swift-format's
  /// 100-column limit.
  private static let docWidth = 94
  private static let generatedDirectory = "Sources/SwiftSymbols/Generated/"
  private static let lineLimit = 100
  /// The platforms a release row lists, alphabetically, as the availability type stores them.
  /// `SymbolCatalog.platforms` is the different order `@available` clauses need.
  private static let releasePlatforms = ["iOS", "macOS", "tvOS", "visionOS", "watchOS"]
  /// Elements per literal. A whole column in one literal costs the optimizer time that grows
  /// with the catalog; a literal this size keeps that cost linear and stays readable.
  private static let tableChunk = 128

  /// The macOS build the data came from.
  package let build: String
  /// The catalog to render.
  package let catalog: SymbolCatalog

  package init(build: String, catalog: SymbolCatalog) {
    self.build = build
    self.catalog = catalog
  }

  /// The header every file starts with, ending in a blank line.
  package var header: String {
    """
    \(Self.headerPrefix) from SF Symbols \(catalog.sfSymbolsYear), macOS build \(build). Do not edit.
    // Regenerate with `bash Scripts/generate-catalog.sh` after an Xcode or macOS update.

    """
  }

  /// Every file, symbols first, in a stable order.
  package func files() throws -> [GeneratedFile] {
    var files: [GeneratedFile] = []
    var groups: [String: [SymbolEntry]] = [:]
    for entry in catalog.entries {
      groups[Self.groupKey(for: entry.identifier), default: []].append(entry)
    }
    for key in groups.keys.sorted() {
      files.append(
        GeneratedFile(
          contents: symbolsFile(groups[key] ?? []),
          path: "\(Self.generatedDirectory)SFSymbol+Symbols-\(key).swift"))
    }
    files.append(
      GeneratedFile(
        contents: aliasesFile(), path: "\(Self.generatedDirectory)SFSymbol+Aliases.swift"))
    files.append(
      GeneratedFile(contents: versionFile(), path: "\(Self.generatedDirectory)CatalogVersion.swift")
    )
    files += try tableFiles()
    return files
  }

  /// Splits `text` on spaces into lines no longer than `width`, never breaking inside a word.
  package static func wrap(_ text: String, width: Int = docWidth) -> [String] {
    var lines: [String] = []
    var current = ""
    for word in text.split(separator: " ") {
      if current.isEmpty {
        current = String(word)
      } else if current.count + 1 + word.count > width {
        lines.append(current)
        current = String(word)
      } else {
        current += " " + word
      }
    }
    if !current.isEmpty { lines.append(current) }
    return lines
  }

  /// A column as `summary`, then at most `tableChunk` elements per literal, composed once on
  /// first access.
  ///
  /// The composition appends each piece in its own statement, so no operator chain reaches the
  /// type checker and no literal grows with the catalog.
  private static func column(
    _ name: String, _ type: String, _ elements: [String], _ summary: String
  ) -> String {
    guard elements.count > tableChunk else {
      return docLines(summary) + literal(name, type, elements, visibility: "package ")
    }
    var out = ""
    var pieces: [String] = []
    var start = elements.startIndex
    while start < elements.endIndex {
      let end = min(start + tableChunk, elements.endIndex)
      let piece = "\(name)\(pieces.count)"
      pieces.append(piece)
      out += literal(piece, type, Array(elements[start..<end]), visibility: "private ")
      start = end
    }
    out += docLines(summary)
    out += "  package static let \(name): [\(type)] = {\n"
    out += "    var all: [\(type)] = []\n"
    out += "    all.reserveCapacity(\(elements.count))\n"
    for piece in pieces { out += "    all += \(piece)\n" }
    return out + "    return all\n  }()\n"
  }

  /// `@available(*, deprecated, renamed: "identifier")`, broken as swift-format breaks it.
  private static func deprecation(renamed identifier: String) -> String {
    let renamed = "renamed: \"\(identifier)\""
    return firstFitting([
      ["  @available(*, deprecated, \(renamed))"],
      ["  @available(", "    *, deprecated, \(renamed)", "  )"],
      ["  @available(", "    *, deprecated,", "    \(renamed)", "  )"],
    ])
  }

  /// Doc-comment lines for `text`, wrapped so the whole line stays under swift-format's limit.
  private static func docLines(_ text: String) -> String {
    wrap(field(text)).map { "  /// \($0)\n" }.joined()
  }

  /// A field with tabs and newlines replaced, so a doc comment stays one line per line.
  private static func field(_ value: String) -> String {
    value.replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: " ")
  }

  /// The first layout whose lines all fit swift-format's limit, or the last, most broken one.
  ///
  /// The candidates are swift-format's own line breaks, tried in the order its pretty printer
  /// tries them, so a long name produces exactly the text the formatter would.
  private static func firstFitting(_ layouts: [[String]]) -> String {
    let fitting = layouts.first { $0.allSatisfy { $0.count <= lineLimit } }
    return (fitting ?? layouts.last ?? []).map { $0 + "\n" }.joined()
  }

  /// The file a declaration lands in: its first letter, or `digits` for a leading digit.
  private static func groupKey(for identifier: String) -> String {
    let bare = identifier.replacingOccurrences(of: "`", with: "")
    guard let first = bare.first, first.isLetter else { return "digits" }
    return String(first).lowercased()
  }

  /// One array literal, its elements packed under the line limit.
  ///
  /// Formatting is suppressed so a later formatting pass leaves the packing alone; one element
  /// per line would be tens of thousands of lines for no gain in what the compiler sees.
  private static func literal(
    _ name: String, _ type: String, _ elements: [String], visibility: String
  ) -> String {
    let indent = "    "
    var out = "  // swift-format-ignore\n  \(visibility)static let \(name): [\(type)] = [\n"
    var line = indent
    for element in elements {
      let piece = element + ","
      if line.count + piece.count + 1 > lineLimit && line.count > indent.count {
        out += line + "\n"
        line = indent
      }
      line += (line.count > indent.count ? " " : "") + piece
    }
    if line.count > indent.count { out += line + "\n" }
    return out + "  ]\n"
  }

  /// A Swift string literal for `value`, escaping what a symbol name can contain.
  private static func quoted(_ value: String) -> String {
    var out = "\""
    for scalar in value.unicodeScalars {
      switch scalar {
      case "\\": out += "\\\\"
      case "\"": out += "\\\""
      default: out.unicodeScalars.append(scalar)
      }
    }
    return out + "\""
  }

  /// How a doc comment names another member: a symbol link, or a code span for a member that has
  /// no documentation page.
  ///
  /// The documentation compiler leaves out every declaration whose name begins with an
  /// underscore, which is how a symbol whose name starts with a digit is spelled, so a link to one
  /// resolves at nothing and fails the documentation build. Such a member keeps its own comment in
  /// Xcode quick help, so a code span still leads the reader to it.
  private static func reference(_ identifier: String) -> String {
    identifier.hasPrefix("_") ? "`\(identifier)`" : "``\(identifier)``"
  }

  /// The opening of `public static var identifier: type {`, broken as swift-format breaks it.
  private static func staticVar(_ identifier: String, type: String) -> String {
    firstFitting([
      ["  public static var \(identifier): \(type) {"],
      ["  public static var \(identifier): \(type)", "  {"],
      ["  public static var \(identifier):", "    \(type)", "  {"],
      ["  public static", "    var \(identifier): \(type)", "  {"],
      ["  public static", "    var \(identifier):", "    \(type)", "  {"],
    ])
  }

  /// A getter body of `SFSymbol(unchecked: "name")`, broken as swift-format breaks it.
  private static func uncheckedInitializer(_ name: String) -> String {
    let literal = "\"\(name)\""
    return firstFitting([
      ["    SFSymbol(unchecked: \(literal))"],
      ["    SFSymbol(", "      unchecked: \(literal))"],
      ["    SFSymbol(", "      unchecked: \(literal)", "    )"],
      ["    SFSymbol(", "      unchecked:", "        \(literal))"],
      ["    SFSymbol(", "      unchecked:", "        \(literal)", "    )"],
    ])
  }

  private func aliasesFile() -> String {
    var out = header + "\nextension SFSymbol {\n"
    let attributes = Dictionary(
      uniqueKeysWithValues: catalog.entries.map { ($0.name, $0.availabilityAttribute) })
    for alias in catalog.aliases {
      out += Self.docLines("`\(alias.name)`, renamed to \(Self.reference(alias.targetIdentifier)).")
      if let attribute = attributes[alias.target] ?? nil { out += "  \(attribute)\n" }
      out += Self.deprecation(renamed: alias.targetIdentifier)
      out += Self.staticVar(alias.identifier, type: "SFSymbol")
      out += "    .\(alias.targetIdentifier)\n  }\n"
    }
    return out + "}\n"
  }

  private func symbolsFile(_ entries: [SymbolEntry]) -> String {
    var out = header + "\nextension SFSymbol {\n"
    for entry in entries {
      out += "  /// `\(entry.name)`\n  ///\n"
      var facts: [String] = []
      if !entry.categories.isEmpty {
        facts.append("Categories: \(entry.categories.joined(separator: ", ")).")
      }
      if !entry.searchTerms.isEmpty {
        facts.append("Search terms: \(entry.searchTerms.joined(separator: ", ")).")
      }
      if !facts.isEmpty {
        out += Self.docLines(facts.joined(separator: " ")) + "  ///\n"
      }
      let since = SymbolCatalog.platforms.map { "\($0) \(entry.release[$0] ?? "")" }
      out += Self.docLines("Available since \(since.joined(separator: ", ")).")
      if let restriction = entry.restriction {
        out += "  ///\n" + Self.docLines("Restriction: \(restriction)")
      }
      if let attribute = entry.availabilityAttribute { out += "  \(attribute)\n" }
      out += Self.staticVar(entry.identifier, type: "SFSymbol")
      out += Self.uncheckedInitializer(entry.name) + "  }\n"
    }
    return out + "}\n"
  }

  /// One table file: the header, then `body` inside an extension of the table.
  private func tableExtension(_ body: String) -> String {
    header + "\nextension SymbolTable {\n" + body + "}\n"
  }

  /// The table declaration and its columns, grouped so each file stays a readable size.
  private func tableFiles() throws -> [GeneratedFile] {
    let tables = try SymbolTables.build(from: catalog, platforms: Self.releasePlatforms)
    let platforms = Self.releasePlatforms.joined(separator: ", ")
    let names = Self.column(
      "names", "String", tables.names.map(Self.quoted),
      "Every catalogued name, sorted, so a binary search finds one.")
    let order = Self.column(
      "order", "UInt16", tables.order.map { "\($0)" },
      "Apple's canonical position to the row in `names` at that position.")
    let baseIndex = Self.column(
      "baseIndex", "UInt16", tables.baseIndex.map { "\($0)" },
      "Each symbol's base, as a row in `names`, or `names.count + k` for `orphanBases[k]`.")
    let variantBits = Self.column(
      "variantBits", "UInt8", tables.variantBits.map { "\($0)" },
      "Each symbol's variant suffixes: circle 1, fill 2, rectangle 4, slash 8, square 16.")
    let variantOrder = Self.column(
      "variantOrder", "UInt16", tables.variantOrder.map { "\($0)" },
      "Rows ordered by base then variant bits, so a pair resolves by binary search.")
    let orphanBases = Self.column(
      "orphanBases", "String", tables.orphanBases.map(Self.quoted),
      "Bases that are not themselves catalogued names, sorted.")
    let yearIndex = Self.column(
      "yearIndex", "UInt8", tables.yearIndex.map { "\($0)" },
      "The release each symbol first appeared in, as a row of `releases`.")
    let releases = Self.column(
      "releases", "UInt8", tables.releases.map { "\($0)" },
      "Ten numbers per release, a major and a minor version for \(platforms), years ascending.")
    let aliasNames = Self.column(
      "aliasNames", "String", tables.aliasNames.map(Self.quoted),
      "Old names, sorted, so an alias resolves by binary search.")
    let aliasTargets = Self.column(
      "aliasTargets", "UInt16", tables.aliasTargets.map { "\($0)" },
      "The row in `names` the alias at the same position forwards to.")
    return [
      GeneratedFile(
        contents: tableTypeFile(), path: "\(Self.generatedDirectory)SymbolTable.swift"),
      GeneratedFile(
        contents: tableExtension(aliasNames + aliasTargets),
        path: "\(Self.generatedDirectory)SymbolTable+Aliases.swift"),
      GeneratedFile(
        contents: tableExtension(names + order),
        path: "\(Self.generatedDirectory)SymbolTable+Names.swift"),
      GeneratedFile(
        contents: tableExtension(releases + yearIndex),
        path: "\(Self.generatedDirectory)SymbolTable+Releases.swift"),
      GeneratedFile(
        contents: tableExtension(baseIndex + orphanBases + variantBits + variantOrder),
        path: "\(Self.generatedDirectory)SymbolTable+Variants.swift"),
    ]
  }

  private func tableTypeFile() -> String {
    header + """

      /// The SF Symbols metadata, as columns of numbers and names rather than records.
      ///
      /// A row index is the position of a name in ``names``, which is sorted, so a binary search
      /// over it reaches every other column. ``baseIndex`` and ``aliasTargets`` hold row indexes,
      /// ``variantBits`` holds the bits of a variant set, and ``yearIndex`` selects one row of
      /// ``releases``. Nothing is read from a bundle, parsed, or built into a dictionary: the
      /// columns are compiled Swift, and Swift initializes each one on first use.
      package enum SymbolTable {}

      """
  }

  private func versionFile() -> String {
    header + """

      extension SFSymbol {
        /// The SF Symbols release and macOS build the catalog was generated from.
        public static var catalogVersion: CatalogVersion {
          CatalogVersion(macOSBuild: "\(build)", sfSymbolsYear: \(catalog.sfSymbolsYear))
        }
      }

      """
  }
}
