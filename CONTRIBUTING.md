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
- **Catalog:** generated symbol data is produced by the generator from the system SF Symbols
  metadata and never edited by hand. Regenerate and commit the diff on its own.
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
