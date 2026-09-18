#!/usr/bin/env bash
# Regenerates the checked-in SF Symbols catalog from this machine's CoreGlyphs bundle.
#
# The generator is compiled straight from its sources with the toolchain's swiftc, so this works
# without a package build and without a scheme. Any argument is forwarded to the generator; with no
# argument the package root is the output.
#
# Usage: bash Scripts/generate-catalog.sh [--output DIR] [--bundle DIR] [--build STRING]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/.build/generator"
mkdir -p "$build"

# The same language mode and package name as Package.swift, so `package` declarations resolve and
# the generator compiles as the same dialect the package tests it in.
xcrun swiftc -O -swift-version 6 -parse-as-library -package-name swift_symbols \
  -module-name SwiftSymbolsGenerator \
  -emit-module -emit-module-path "$build/SwiftSymbolsGenerator.swiftmodule" \
  -emit-library -static -o "$build/libSwiftSymbolsGenerator.a" \
  "$root"/Sources/SwiftSymbolsGenerator/*.swift

xcrun swiftc -O -swift-version 6 -package-name swift_symbols -module-name swift_symbols_generate \
  -I "$build" "$build/libSwiftSymbolsGenerator.a" "$root/Sources/swift-symbols-generate/main.swift" \
  -o "$build/swift-symbols-generate"

if [ "$#" -eq 0 ]; then
  "$build/swift-symbols-generate" --output "$root"
else
  "$build/swift-symbols-generate" "$@"
fi
