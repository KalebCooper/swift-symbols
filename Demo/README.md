# SymbolBrowser demo app

A standalone iOS app that browses the SF Symbols catalog through swift-symbols. It references the
package as a local dependency, so it is never part of any product and library consumers never
build or link it.

## Why there is no `.xcodeproj` here

SwiftPM cannot produce an iOS `.app`, so the demo needs a real Xcode app target. The project is
generated from [`project.yml`](project.yml) with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
instead of being checked in (`SymbolBrowser.xcodeproj` is gitignored). After cloning, generate it
yourself.

## Setup

```sh
# One time: install XcodeGen (2.46.0 or later)
brew install xcodegen

# Generate the project and open it
cd Demo && xcodegen generate
open SymbolBrowser.xcodeproj
```

Pick an iPhone or iPad simulator running iOS 26 and run the `SymbolBrowser` scheme.

Re-run `xcodegen generate` whenever `project.yml` or the file layout under `Sources/` or
`Resources/` changes. The generated project lists sources by scanning those directories at
generation time, so a file added without regenerating is silently left out of the build.
