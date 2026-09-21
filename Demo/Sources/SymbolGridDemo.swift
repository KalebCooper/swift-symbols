import SwiftSymbols
import SwiftSymbolsUI
import SwiftUI

/// Every catalogued symbol in Apple's order, one fixed-size cell each, narrowed by name.
///
/// The catalog is read once, into local state, so the cost of materializing `SFSymbol.all` is
/// paid where it can be timed and printed rather than inside the first body evaluation. The
/// lowercased names are built in that same pass: lowercasing 7,209 names again on every keystroke
/// is what would make a substring search over the whole catalog expensive.
struct SymbolGridDemo: View {
  fileprivate static let cellSize: CGFloat = 56
  private static let columns = [
    GridItem(.adaptive(minimum: cellSize), spacing: 8)
  ]
  private static let nameOnlyNote = """
    Matching is on the symbol name alone, because Apple's search terms are documentation in \
    this release.
    """

  @State private var lowercasedNames: [String] = []
  @State private var query = ""
  @State private var symbols: [SFSymbol] = []

  /// The symbols whose name contains the query, case insensitively, in Apple's order.
  ///
  /// The query is lowercased once here rather than once per symbol, and the names it is compared
  /// against were lowercased when the catalog was read. An empty query returns the catalog itself,
  /// so clearing the field costs nothing and restores Apple's order exactly.
  private var matchingSymbols: [SFSymbol] {
    let needle = query.lowercased()
    guard !needle.isEmpty else { return symbols }
    var matches: [SFSymbol] = []
    let names = zip(symbols, lowercasedNames)
    for (symbol, lowercasedName) in names where lowercasedName.contains(needle) {
      matches.append(symbol)
    }
    return matches
  }

  var body: some View {
    let matches = matchingSymbols
    ScrollView {
      if matches.isEmpty, !query.isEmpty {
        ContentUnavailableView {
          Label {
            Text("No matching name")
          } icon: {
            Image(SFSymbol.magnifyingglass)
          }
        } description: {
          Text("Nothing in the catalog has \"\(query)\" in its name.")
        }
        .padding(.top, 64)
      } else {
        LazyVGrid(columns: Self.columns, spacing: 8) {
          ForEach(matches) { symbol in
            NavigationLink {
              SymbolDetailDemo(symbol: symbol)
            } label: {
              SymbolCell(symbol: symbol)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
      }
    }
    .searchable(text: $query, prompt: "Symbol name")
    .safeAreaInset(edge: .bottom) {
      Text(Self.nameOnlyNote)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
    .navigationTitle("Symbol catalog")
    .navigationSubtitle("\(matches.count) symbols")
    .task {
      let clock = ContinuousClock()
      var catalog: [SFSymbol] = []
      var lowercased: [String] = []
      let catalogElapsed = clock.measure { catalog = SFSymbol.all }
      let namesElapsed = clock.measure {
        lowercased = catalog.map { $0.name.lowercased() }
      }
      print("SFSymbol.all: \(catalog.count) symbols materialized in \(catalogElapsed)")
      print("Lowercased names: \(lowercased.count) built in \(namesElapsed)")
      lowercasedNames = lowercased
      symbols = catalog
    }
  }
}

/// One symbol at a fixed size, so the grid lays out without measuring each cell.
private struct SymbolCell: View {
  let symbol: SFSymbol

  var body: some View {
    Image(symbol)
      .font(.title2)
      .frame(width: SymbolGridDemo.cellSize, height: SymbolGridDemo.cellSize)
      .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
      .accessibilityLabel(symbol.name)
  }
}
