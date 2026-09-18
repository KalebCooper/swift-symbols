// The generator entry point. Argument handling and file writing live here; every rule about the
// catalog lives in SwiftSymbolsGenerator so tests can reach it.
//
// Usage: swift-symbols-generate --output PACKAGE_ROOT [--bundle DIRECTORY] [--build STRING]
import Foundation
import SwiftSymbolsGenerator

struct SystemVersion: Decodable {
  let productBuildVersion: String

  enum CodingKeys: String, CodingKey {
    case productBuildVersion = "ProductBuildVersion"
  }
}

func option(_ name: String) -> String? {
  let arguments = CommandLine.arguments
  guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
  return arguments[index + 1]
}

func systemBuild() throws -> String {
  let url = URL(filePath: "/System/Library/CoreServices/SystemVersion.plist")
  let data = try Data(contentsOf: url)
  return try PropertyListDecoder().decode(SystemVersion.self, from: data).productBuildVersion
}

do {
  guard let output = option("--output") else {
    FileHandle.standardError.write(
      Data(
        "usage: swift-symbols-generate --output PACKAGE_ROOT [--bundle DIRECTORY] [--build STRING]\n"
          .utf8))
    exit(2)
  }
  let bundle =
    option("--bundle").map { URL(filePath: $0, directoryHint: .isDirectory) }
    ?? CoreGlyphsData.systemDirectory
  let build = try option("--build") ?? systemBuild()
  let data = try CoreGlyphsData.load(from: bundle)
  let catalog = try SymbolCatalog.build(from: data)
  let files = Emitter(build: build, catalog: catalog).files()
  let root = URL(filePath: output, directoryHint: .isDirectory)
  // A stale file from an earlier release would otherwise survive next to the fresh ones.
  for directory in ["Sources/SwiftSymbols/Generated", "Sources/SwiftSymbols/Resources"] {
    let url = root.appending(path: directory, directoryHint: .isDirectory)
    if FileManager.default.fileExists(atPath: url.path()) {
      try FileManager.default.removeItem(at: url)
    }
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }
  for file in files {
    try Data(file.contents.utf8).write(to: root.appending(path: file.path))
  }
  print(
    "Generated \(catalog.entries.count) symbols, \(catalog.aliases.count) aliases, "
      + "\(catalog.categories.count) categories from SF Symbols \(catalog.sfSymbolsYear), "
      + "macOS build \(build).")
} catch {
  FileHandle.standardError.write(Data("swift-symbols-generate: \(error)\n".utf8))
  exit(1)
}
