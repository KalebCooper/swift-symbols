#!/usr/bin/env bash
# Builds the DocC site for both products from already-built iOS Simulator modules, the same way
# `.github/workflows/docs.yml` does, so a documentation change is verified at zero warnings before a
# push instead of by reading a CI log afterward. `--warnings-as-errors` makes any DocC warning fail.
#
# MODULES_DIRECTORY holds the `.swiftmodule` files of a build of this package, for instance the
# `Build/Products/Debug-iphonesimulator` directory under the derived data of an Xcode build.
#
# Usage: bash Scripts/build-docs.sh MODULES_DIRECTORY OUTPUT_DIRECTORY [TARGET]
set -euo pipefail

modules="${1:?Usage: bash Scripts/build-docs.sh MODULES_DIRECTORY OUTPUT_DIRECTORY [TARGET]}"
output="${2:?Supply a new output directory}"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
target="${3:-$(uname -m)-apple-ios26.0-simulator}"

if [[ -e "$output" ]]; then
  echo "Output already exists: $output. Supply a new directory." >&2
  exit 1
fi
mkdir -p "$output/catalog-symbols" "$output/ui-symbols" "$output/module-cache"

# The catalog module first, publishing link metadata the UI catalog resolves against.
xcrun swift-symbolgraph-extract -module-name SwiftSymbols \
  -target "$target" -sdk "$sdk" -I "$modules" \
  -module-cache-path "$output/module-cache" \
  -output-dir "$output/catalog-symbols" -minimum-access-level public
xcrun docc convert Sources/SwiftSymbols/SwiftSymbols.docc \
  --additional-symbol-graph-dir "$output/catalog-symbols" \
  --output-dir "$output/SwiftSymbols.doccarchive" \
  --enable-experimental-external-link-support --warnings-as-errors

xcrun swift-symbolgraph-extract -module-name SwiftSymbolsUI \
  -target "$target" -sdk "$sdk" -I "$modules" \
  -module-cache-path "$output/module-cache" \
  -output-dir "$output/ui-symbols" -minimum-access-level public
xcrun docc convert Sources/SwiftSymbolsUI/SwiftSymbolsUI.docc \
  --additional-symbol-graph-dir "$output/ui-symbols" \
  --output-dir "$output/SwiftSymbolsUI.doccarchive" \
  --enable-experimental-external-link-support \
  --dependency "$output/SwiftSymbols.doccarchive" --warnings-as-errors

xcrun docc merge "$output/SwiftSymbols.doccarchive" "$output/SwiftSymbolsUI.doccarchive" \
  --synthesized-landing-page-name swift-symbols --synthesized-landing-page-kind Package \
  --output-path "$output/merged.doccarchive"
xcrun docc process-archive transform-for-static-hosting "$output/merged.doccarchive" \
  --output-path "$output/site" --hosting-base-path swift-symbols

# The archive's app shell has no root route under the Pages subpath.
cat > "$output/site/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=documentation/">
    <link rel="canonical" href="https://kalebcooper.github.io/swift-symbols/documentation/">
    <title>swift-symbols</title>
  </head>
  <body>
    <p>Redirecting to the <a href="documentation/">swift-symbols documentation</a>.</p>
  </body>
</html>
HTML
