import SwiftSymbols
import SwiftSymbolsUI
import SwiftUI

/// The catalog's release, one symbol's release on this platform, and every symbol that needs a
/// later iOS than the package's floor.
///
/// The list is built once in `.task`, by filtering `SFSymbol.all` and comparing `Version` values,
/// so `body` only reads the result.
struct AvailabilityDemo: View {
  /// The iOS release the package supports without an `@available` check.
  private static let floor = SFSymbol.Version(major: 26, minor: 0)

  @State private var name = "star"
  @State private var newerSymbols: [SFSymbol] = []

  private var chosen: SFSymbol? {
    SFSymbol(name: name)
  }

  var body: some View {
    List {
      Section("Catalog") {
        LabeledContent("SF Symbols year", value: "\(SFSymbol.catalogVersion.sfSymbolsYear)")
        LabeledContent("macOS build", value: SFSymbol.catalogVersion.macOSBuild)
      }

      Section {
        TextField("Symbol name", text: $name)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        if let chosen {
          if let availability = chosen.availability {
            LabeledContent("Release on this platform", value: describe(availability.current))
          } else {
            Text("The catalog carries no release for this name.")
          }
          LabeledContent("isAvailable", value: "\(chosen.isAvailable)")
        } else {
          Text("The catalog has no symbol named \"\(name)\".")
        }
      } header: {
        Text("Chosen symbol")
      } footer: {
        Text("Running \(ProcessInfo.processInfo.operatingSystemVersionString).")
      }

      Section {
        ForEach(newerSymbols) { symbol in
          HStack {
            Image(symbol)
              .frame(width: 32)
            VStack(alignment: .leading) {
              Text(symbol.name)
              if let release = symbol.availability?.iOS {
                Text("iOS \(describe(release))")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
            Spacer()
            Text(String(symbol.isAvailable))
              .foregroundStyle(.secondary)
          }
        }
      } header: {
        Text("Needing a later iOS than 26.0: \(newerSymbols.count)")
      } footer: {
        Text(
          """
          Each row reads isAvailable against the system running this app. A symbol reports true \
          only once that system has reached its release.
          """)
      }
    }
    .navigationTitle("Availability")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      newerSymbols = SFSymbol.all.filter { symbol in
        guard let release = symbol.availability?.iOS else { return false }
        return release > Self.floor
      }
    }
  }

  private func describe(_ version: SFSymbol.Version) -> String {
    "\(version.major).\(version.minor)"
  }
}
