// swift-tools-version:6.2

import PackageDescription

// Two products, one dependency direction. SwiftSymbols is the catalog: symbol names, variants,
// availability, categories, and custom-symbol declarations. It imports no UI framework, so UIKit and
// AppKit code can use the catalog without linking SwiftUI. SwiftSymbolsUI is the SwiftUI binding.
// SF Symbols exist only on Apple platforms, so the package targets nothing else.
let package = Package(
  name: "swift-symbols",
  platforms: [
    .iOS(.v26), .macOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26),
  ],
  products: [
    .library(name: "SwiftSymbols", targets: ["SwiftSymbols"]),
    .library(name: "SwiftSymbolsUI", targets: ["SwiftSymbolsUI"]),
  ],
  targets: [
    .target(
      name: "SwiftSymbols",
      resources: [
        .copy("Resources/aliases.tsv"),
        .copy("Resources/categories.tsv"),
        .copy("Resources/symbols.tsv"),
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "SwiftSymbolsUI",
      dependencies: ["SwiftSymbols"],
      swiftSettings: swiftSettings
    ),
    // The generator reads the system SF Symbols metadata and writes the checked-in catalog. No
    // product declares these targets, so a consumer never builds them.
    .target(name: "SwiftSymbolsGenerator", swiftSettings: swiftSettings),
    .executableTarget(
      name: "swift-symbols-generate",
      dependencies: ["SwiftSymbolsGenerator"],
      swiftSettings: swiftSettings
    ),
    // The shared suite time limit stays out of every consumer product.
    .target(name: "SwiftSymbolsTestSupport", swiftSettings: swiftSettings),
    .testTarget(
      name: "SwiftSymbolsGeneratorTests",
      dependencies: ["SwiftSymbolsGenerator", "SwiftSymbolsTestSupport"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SwiftSymbolsTests",
      dependencies: ["SwiftSymbols", "SwiftSymbolsTestSupport"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SwiftSymbolsUITests",
      dependencies: ["SwiftSymbols", "SwiftSymbolsTestSupport", "SwiftSymbolsUI"],
      swiftSettings: swiftSettings
    ),
  ],
  swiftLanguageModes: [.v6]
)

// Library code is nonisolated by default (the inverse of an app target's MainActor default), so every
// `@MainActor` in the package is written where it applies; async entry points run on the caller's
// actor until they truly suspend; and every `unsafe` would have to be spelled out. There are none.
var swiftSettings: [SwiftSetting] {
  [
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .strictMemorySafety(),
  ]
}
