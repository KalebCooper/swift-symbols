# Contributing to swift-symbols

Thanks for your interest. Contributions are welcome; every change to the public surface lands in
`CHANGELOG.md`.

## Getting started

1. Fork and clone the repository.
2. Open the package directory in Xcode 26 or later.
3. Build and run tests on Xcode's generated `swift-symbols-Package` scheme (⌘U), or `swift test`
   from the command line.

## Guidelines

- **Layers:** `SwiftSymbols` depends on nothing and imports no UI framework: no SwiftUI, UIKit, or
  AppKit, in any import spelling. If a type needs one to exist, it belongs in `SwiftSymbolsUI`.
  `SwiftSymbolsUI` adds views and modifiers, never catalog data.
- **Catalog:** everything under `Sources/SwiftSymbols/Generated` is written by
  `bash Scripts/generate-catalog.sh` from the SF Symbols metadata that ships with macOS, and is
  never edited by hand. Regenerate after an Xcode or macOS update and commit the result on its own,
  as a `chore:` commit. The catalog ships as Swift: the package declares no bundle resource and
  parses nothing at run time.
- **Catalog freshness:** `Scripts/verify.sh` compares the checked-in catalog against a fresh
  generation, which is possible only on the macOS build the catalog was generated from. Anywhere
  else, including CI and any machine that has taken a macOS update, `check_catalog_fresh` prints
  `[WARN]` instead of `[PASS]` and the comparison does not happen. The local run before a commit is
  therefore the enforcement point: run the gate on a machine whose build matches, and read the
  catalog line rather than only the exit code.
- **Public API:** every public symbol needs a DocC comment.
- **Concurrency:** no actors, `DispatchQueue`, `NSLock`, or Combine. Shared state, if any, is
  `Mutex` or `Atomic`. Never sleep or read the wall clock.
- **Tests:** Swift Testing only. Every `@Suite` carries
  `.timeLimit(.minutes(suiteTimeLimitMinutes))`, so a test that stops making progress fails its
  suite instead of holding the run open.
- **Style:** `swift format lint --strict --recursive Sources Tests` must report zero findings.
  Declarations are ordered alphabetically within their groupings unless an inline comment says why
  not.
- **Gate:** `Scripts/verify.sh` runs the format lint and every repository invariant the compiler
  cannot see. Run it before every commit; it must exit 0. `Scripts/verify.sh --self-test` proves
  each check still trips on a planted violation.
- **Documentation:** a change to a doc comment or a documentation catalog is verified locally with
  `bash Scripts/build-docs.sh <modules directory> <new output directory>`, which builds both
  products at zero warnings. The modules directory holds the `.swiftmodule` files of an iOS
  Simulator build.
- **Scope:** no macros, no UIKit or AppKit bridge. Open an issue to discuss additions before
  investing in a large PR.

## Pull requests

- Target `main`. One concern per PR.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
  `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`, `refactor:`, `perf:`, `build:`, with `!`
  for a breaking change.
- Update `CHANGELOG.md` under **Unreleased**.

## Reporting issues

Include a minimal reproduction where possible.
