import Foundation

/// A failure the generator reports instead of writing a partial catalog.
package enum GeneratorError: Error, Equatable, Sendable {
  /// Two names map to the same identifier or the same base and variant set.
  case collision(String)
  /// A plist could not be decoded into its expected shape.
  case malformed(String)
  /// A required plist is absent from the bundle directory.
  case missingFile(String)
  /// A symbol references a year, alias target, or category that the data does not define.
  case unresolved(String)
}

/// One row of `categories.plist`.
package struct CategoryInfo: Decodable, Hashable, Sendable {
  /// The symbol Apple uses as the category's icon.
  package let icon: String
  /// The category key, such as `weather`.
  package let key: String

  package init(icon: String, key: String) {
    self.icon = icon
    self.key = key
  }
}

/// The SF Symbols metadata the system ships, decoded from the CoreGlyphs bundle.
///
/// Every file is a property list, including the ones with a `.strings` extension, so the loader
/// uses `PropertyListDecoder` throughout and never reads the files as text.
package struct CoreGlyphsData: Sendable {
  /// Old name to current name.
  package var aliases: [String: String]
  /// Name to the SF Symbols year it first appeared in, such as `2024.3`.
  package var availability: [String: String]
  /// Apple's category list, in Apple's order.
  package var categories: [CategoryInfo]
  /// Name to its filled counterpart.
  package var fillCounterparts: [String: String]
  /// Every current name in Apple's canonical order.
  package var order: [String]
  /// Name to Apple's usage restriction text.
  package var restrictions: [String: String]
  /// Name to its search terms.
  package var searchTerms: [String: [String]]
  /// Name to its category keys.
  package var symbolCategories: [String: [String]]
  /// SF Symbols year to the OS version per platform that carries it.
  package var yearToRelease: [String: [String: String]]

  package init(
    aliases: [String: String],
    availability: [String: String],
    categories: [CategoryInfo],
    fillCounterparts: [String: String],
    order: [String],
    restrictions: [String: String],
    searchTerms: [String: [String]],
    symbolCategories: [String: [String]],
    yearToRelease: [String: [String: String]]
  ) {
    self.aliases = aliases
    self.availability = availability
    self.categories = categories
    self.fillCounterparts = fillCounterparts
    self.order = order
    self.restrictions = restrictions
    self.searchTerms = searchTerms
    self.symbolCategories = symbolCategories
    self.yearToRelease = yearToRelease
  }

  /// Where macOS keeps the bundle.
  package static let systemDirectory = URL(
    filePath: "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/",
    directoryHint: .isDirectory)

  /// Decodes every file in `directory`.
  package static func load(from directory: URL) throws -> CoreGlyphsData {
    struct Availability: Decodable {
      let symbols: [String: String]
      let yearToRelease: [String: [String: String]]

      enum CodingKeys: String, CodingKey {
        case symbols
        case yearToRelease = "year_to_release"
      }
    }
    let availability = try decode(Availability.self, from: "name_availability.plist", in: directory)
    return CoreGlyphsData(
      aliases: try decode([String: String].self, from: "name_aliases.strings", in: directory),
      availability: availability.symbols,
      categories: try decode([CategoryInfo].self, from: "categories.plist", in: directory),
      fillCounterparts: try decode(
        [String: String].self, from: "nofill_to_fill.strings", in: directory),
      order: try decode([String].self, from: "symbol_order.plist", in: directory),
      restrictions: try decode(
        [String: String].self, from: "symbol_restrictions.strings", in: directory),
      searchTerms: try decode([String: [String]].self, from: "symbol_search.plist", in: directory),
      symbolCategories: try decode(
        [String: [String]].self, from: "symbol_categories.plist", in: directory),
      yearToRelease: availability.yearToRelease)
  }

  private static func decode<Value: Decodable>(
    _ type: Value.Type, from file: String, in directory: URL
  ) throws -> Value {
    let url = directory.appending(path: file)
    guard let data = try? Data(contentsOf: url) else { throw GeneratorError.missingFile(file) }
    do {
      return try PropertyListDecoder().decode(Value.self, from: data)
    } catch {
      throw GeneratorError.malformed("\(file): \(error)")
    }
  }
}
