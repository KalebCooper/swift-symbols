#!/usr/bin/env bash
#
# The repository gate: every invariant the compiler cannot see, plus the format lint. Run it before
# every commit; it must exit 0.
#
# `--self-test` proves the gate itself. It writes a clean tree into a scratch directory, confirms
# every self-testable check passes there, then for each check plants one or more violations and
# confirms the check trips, and removes the check's subject and confirms the check fails rather than
# passing vacuously. Run it after any edit to this file.
#
# Usage: bash Scripts/verify.sh [--self-test]

set -u

ROOT="${VERIFY_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
FAILURES=0

# Every check here is exercised by `--self-test`. `check_format` and `check_nothing_local_tracked`
# are not: the first needs a toolchain and the second a git checkout, and neither has a planted
# violation that a scratch tree can hold.
SELF_TESTABLE=(
  check_banned_imports
  check_coordinates
  check_core_import_boundary
  check_em_dash
  check_force_ops
  check_job_timeouts
  check_suite_time_limit
  check_swift_testing_only
  check_test_jargon
  check_unsafe
  check_wall_clock_and_locks
)

# Matches an import of any listed module in any spelling: `import X`, `public import X`,
# `@_exported import X`, `@preconcurrency import X`, `import struct X.Y`. `$1` is the alternation.
import_pattern() {
  printf ':[0-9]+:[[:space:]]*(@[A-Za-z_]+(\\([^)]*\\))?[[:space:]]+)*((public|package|internal|fileprivate|private)[[:space:]]+)?import[[:space:]]+((typealias|struct|class|enum|protocol|let|var|func)[[:space:]]+)?(%s)\\b' "$1"
}

check_banned_imports() {
  local name="no Combine or Dispatch import in Sources"
  local hits
  hits=$(code_lines $(swift_files Sources) | grep -E "$(import_pattern 'Combine|Dispatch')" || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_coordinates() {
  local name="no plan, phase, task, or turn coordinates in Sources or Tests"
  local hits section
  section=$(printf '\302\247')
  hits=$(grep -nHE "\\bP[0-9]+-T[0-9]+\\b|\\bPh[a]se [0-9]|\\bT[a]sk [0-9]|\\bturn[- ][0-9]+\\b|$section" $(swift_files Sources) $(swift_files Tests) 2>/dev/null || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

# The catalog module is usable from UIKit and AppKit code without SwiftUI, so it imports no UI
# framework and never the module that depends on it.
check_core_import_boundary() {
  local name="no SwiftUI, UIKit, AppKit, Observation, or SwiftSymbolsUI import in Sources/SwiftSymbols"
  local files hits
  files=$(swift_files Sources/SwiftSymbols)
  if [ -z "$files" ]; then fail "$name (Sources/SwiftSymbols holds no Swift file; the check has lost its subject)"; return; fi
  hits=$(code_lines $files | grep -E "$(import_pattern 'AppKit|Observation|SwiftSymbolsUI|SwiftUI|UIKit')" || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_em_dash() {
  local name="no em dash in Sources, Tests, Scripts, .github, Package.swift, .spi.yml, README, CHANGELOG, CONTRIBUTING"
  local hits dash
  dash=$(printf '\342\200\224')
  hits=$(grep -rnH -- "$dash" "$ROOT/Sources" "$ROOT/Tests" "$ROOT/Scripts" "$ROOT/.github" "$ROOT/Package.swift" "$ROOT/.spi.yml" "$ROOT/README.md" "$ROOT/CHANGELOG.md" "$ROOT/CONTRIBUTING.md" 2>/dev/null || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_force_ops() {
  local name="no try! or as! in Sources"
  local hits
  hits=$(code_lines $(swift_files Sources) | grep -E '\btry!|\bas!' || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_format() {
  local name="swift format lint --strict reports zero findings"
  if ! command -v swift >/dev/null 2>&1; then fail "$name (swift toolchain not found)"; return; fi
  if (cd "$ROOT" && swift format lint --strict --recursive Sources Tests >/dev/null 2>&1); then
    pass "$name"
  else
    fail "$name"
    (cd "$ROOT" && swift format lint --strict --recursive Sources Tests 2>&1 | head -40)
  fi
}

# Every job is bounded so a hang fails the job instead of sitting for GitHub's six-hour default.
check_job_timeouts() {
  local name="every job in .github/workflows carries a timeout-minutes"
  local files report
  files=$(find "$ROOT/.github/workflows" \( -name '*.yml' -o -name '*.yaml' \) -type f 2>/dev/null | sort)
  if [ -z "$files" ]; then fail "$name (no workflow file found; the check has lost its subject)"; return; fi
  report=$(awk '
    function close_job() {
      if (job != "") { total++; if (!has) print jobfile ": job " job " has no timeout-minutes" }
      job = ""; has = 0
    }
    FNR == 1 { close_job(); in_jobs = 0 }
    /^[^[:space:]#]/ { close_job(); in_jobs = ($0 ~ /^jobs:[[:space:]]*$/); next }
    in_jobs && /^  [^[:space:]#].*:[[:space:]]*$/ {
      close_job(); job = $0; sub(/^  /, "", job); sub(/:[[:space:]]*$/, "", job); jobfile = FILENAME; next
    }
    in_jobs && job != "" && /^    timeout-minutes:[[:space:]]*[0-9]+[[:space:]]*(#.*)?$/ { has = 1; next }
    END { close_job(); if (total == 0) print "NO-JOBS" }
  ' $files 2>/dev/null || true)
  if [ "$report" = "NO-JOBS" ]; then
    fail "$name (no job found in any workflow; the check has lost its subject)"
  elif [ -z "$report" ]; then
    pass "$name"
  else
    fail "$name"; printf '%s\n' "$report"
  fi
}

check_nothing_local_tracked() {
  local name="no local-only file is tracked"
  local hits
  hits=$(cd "$ROOT" && git ls-files -- CLAUDE.md AGENTS.md GEMINI.md .agents .claude .codex .gemini .grok plans 2>/dev/null || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

# Every `@Suite` carries the shared time limit, and no `@Test` sits at file scope where no suite
# bounds it. The awk strips string literals and line comments before looking for the constant, and
# joins a multi-line `@Suite(...)` attribute by tracking parenthesis depth.
check_suite_time_limit() {
  local name="every suite in Tests carries the shared time limit"
  local files report
  files=$(swift_files Tests)
  if [ -z "$files" ]; then fail "$name (no test file found; the check has lost its subject)"; return; fi
  report=$(awk '
    function code(s,   i, c, out, instr, esc) {
      out = ""; instr = 0; esc = 0
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (instr) {
          if (esc) esc = 0
          else if (c == "\\") esc = 1
          else if (c == "\"") instr = 0
          continue
        }
        if (c == "\"") { instr = 1; continue }
        if (c == "/" && substr(s, i + 1, 1) == "/") break
        out = out c
      }
      return out
    }
    function balance(s,   i, c, d) {
      d = 0
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "(") d++
        else if (c == ")") d--
      }
      return d
    }
    /^[[:space:]]*\/\// { next }
    /^(@[A-Za-z_][A-Za-z0-9_]*(\([^)]*\))?[[:space:]]+)*@Test([[:space:](]|$)/ {
      print FILENAME ":" FNR ": a test at file scope has no suite to bound it"
      next
    }
    /^[[:space:]]*(@[A-Za-z_][A-Za-z0-9_]*(\([^)]*\))?[[:space:]]+)*@Suite([[:space:](]|$)/ {
      total++
      buf = code($0); loc = FILENAME ":" FNR; depth = balance(buf)
      while (depth > 0 && (getline) > 0) {
        chunk = code($0); buf = buf " " chunk; depth += balance(chunk)
      }
      if (index(buf, "suiteTimeLimitMinutes") == 0) print loc ": " buf
      next
    }
    END { if (total == 0) print "NO-SUITES" }
  ' $files 2>/dev/null || true)
  if [ "$report" = "NO-SUITES" ]; then
    fail "$name (no suite found in Tests; the check has lost its subject)"
  elif [ -z "$report" ]; then
    pass "$name"
  else
    fail "$name"; printf '%s\n' "$report"
  fi
}

check_swift_testing_only() {
  local name="Swift Testing only in Tests"
  local files hits testing
  files=$(swift_files Tests)
  testing=$(grep -l '^import Testing$' $files 2>/dev/null | wc -l | tr -d ' ')
  if [ "$testing" -eq 0 ]; then fail "$name (no file imports Testing; the check has lost its subject)"; return; fi
  hits=$(grep -nHE 'import XCTest|XCTestCase|XCTAssert' $files 2>/dev/null || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_test_jargon() {
  local name="no test double, driver, or seam jargon in Sources, Tests, .github, README, CHANGELOG, CONTRIBUTING"
  local hits
  hits=$(grep -rnHwiE "test doubles?|doubles|(the|a|second|no) double|the driver|the seam|a seam|seams" "$ROOT/Sources" "$ROOT/Tests" "$ROOT/.github" "$ROOT/README.md" "$ROOT/CHANGELOG.md" "$ROOT/CONTRIBUTING.md" 2>/dev/null || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_unsafe() {
  local name="no unsafe in Sources"
  local hits
  hits=$(code_lines $(swift_files Sources) | grep -wE 'unsafe' || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

check_wall_clock_and_locks() {
  local name="no wall clock, nanosecond sleep, DispatchQueue, NSLock, or OSAllocatedUnfairLock in Sources"
  local hits
  hits=$(code_lines $(swift_files Sources) | grep -E 'Date\(\)|Date\.now|Task\.sleep\(nanoseconds|DispatchQueue|NSLock|OSAllocatedUnfairLock' || true)
  if [ -z "$hits" ]; then pass "$name"; else fail "$name"; printf '%s\n' "$hits"; fi
}

# Non-comment lines of the given files, prefixed `file:line:`. A line that is only a comment is
# dropped, so a doc comment may name a banned symbol.
code_lines() {
  grep -nHvE '^\s*//' "$@" 2>/dev/null
}

fail() { printf '[FAIL] %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

# Runs one check against one tree and prints PASS or FAIL, leaving the global count untouched.
outcome_of() {
  local saved="$FAILURES" result
  FAILURES=0
  ROOT="$1" "$2" >/dev/null 2>&1
  if [ "$FAILURES" -eq 0 ]; then result=PASS; else result=FAIL; fi
  FAILURES="$saved"
  printf '%s' "$result"
}

pass() { printf '[PASS] %s\n' "$1"; }

# The second and later plants cover the import spellings and file shapes that a naive pattern
# would miss. A check with no further plant returns 1 and the self-test moves on.
plant_second_violation() {
  local d="$1"
  case "$2" in
    check_banned_imports)
      printf '@preconcurrency import Dispatch\n' > "$d/Sources/SwiftSymbolsUI/Leak.swift" ;;
    check_core_import_boundary)
      printf '@_exported public import SwiftSymbolsUI\n' > "$d/Sources/SwiftSymbols/Leak.swift" ;;
    check_job_timeouts)
      printf 'name: Nested\n\non:\n  push:\n\njobs:\n  nested:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v7\n        timeout-minutes: 5\n' > "$d/.github/workflows/nested.yml" ;;
    check_suite_time_limit)
      printf 'import SwiftSymbolsTestSupport\nimport Testing\n\n@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes))) struct OuterTests {\n  @Suite struct NestedTests {\n    @Test func aTestRuns() {\n      #expect(true)\n    }\n  }\n}\n' > "$d/Tests/SwiftSymbolsTests/NestedTests.swift" ;;
    *) return 1 ;;
  esac
}

plant_third_violation() {
  local d="$1"
  case "$2" in
    check_core_import_boundary)
      printf 'import struct SwiftUI.Image\n' > "$d/Sources/SwiftSymbols/Leak.swift" ;;
    check_job_timeouts)
      printf 'name: Quoted\n\non:\n  push:\n\njobs:\n  "quoted":\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v7\n' > "$d/.github/workflows/quoted.yml" ;;
    check_suite_time_limit)
      printf 'import Testing\n\n@MainActor @Suite struct PrefixedTests {\n  @Test func aTestRuns() {\n    #expect(true)\n  }\n}\n' > "$d/Tests/SwiftSymbolsTests/PrefixedTests.swift" ;;
    *) return 1 ;;
  esac
}

plant_fourth_violation() {
  local d="$1"
  case "$2" in
    check_core_import_boundary)
      printf 'import UIKit\n' >> "$d/Sources/SwiftSymbols/Module.swift" ;;
    check_suite_time_limit)
      printf 'import Testing\n\n@Suite struct CommentedTests {  // suiteTimeLimitMinutes\n  @Test func aTestRuns() {\n    #expect(true)\n  }\n}\n' > "$d/Tests/SwiftSymbolsTests/CommentedTests.swift" ;;
    *) return 1 ;;
  esac
}

plant_fifth_violation() {
  local d="$1"
  case "$2" in
    check_suite_time_limit)
      printf 'import Testing\n\n@Test func aTestAtFileScopeRuns() {\n  #expect(true)\n}\n' > "$d/Tests/SwiftSymbolsTests/FileScopeTests.swift" ;;
    *) return 1 ;;
  esac
}

plant_violation() {
  local d="$1"
  case "$2" in
    check_banned_imports)
      printf 'import Combine\n' >> "$d/Sources/SwiftSymbols/Module.swift" ;;
    check_coordinates)
      printf '// Added in P3\055T2 for Ph\141se 4\n' >> "$d/Sources/SwiftSymbols/Module.swift" ;;
    check_core_import_boundary)
      printf 'import SwiftUI\n' > "$d/Sources/SwiftSymbols/Leak.swift" ;;
    check_em_dash)
      printf 'A line \342\200\224 with an em dash\n' >> "$d/README.md" ;;
    check_force_ops)
      printf 'let x = y as! Int\n' >> "$d/Sources/SwiftSymbols/Module.swift" ;;
    check_job_timeouts)
      printf 'name: Extra\n\non:\n  push:\n\njobs:\n  stray:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v7\n' > "$d/.github/workflows/extra.yml" ;;
    check_suite_time_limit)
      printf 'import Testing\n\n@Suite struct UnboundedTests {\n  @Test func aTestRuns() {\n    #expect(true)\n  }\n}\n' > "$d/Tests/SwiftSymbolsTests/UnboundedTests.swift" ;;
    check_swift_testing_only)
      printf 'import XCTest\n' >> "$d/Tests/SwiftSymbolsTests/ModuleTests.swift" ;;
    check_test_jargon)
      printf 'Swap in a test double here.\n' >> "$d/README.md" ;;
    check_unsafe)
      printf 'let n = unsafe ptr.load()\n' >> "$d/Sources/SwiftSymbols/Module.swift" ;;
    check_wall_clock_and_locks)
      printf 'let now = Date()\n' >> "$d/Sources/SwiftSymbols/Module.swift" ;;
  esac
}

# Removes what a check inspects, so the self-test can confirm the check fails loudly instead of
# passing over nothing. A check whose subject cannot be removed returns 1.
remove_subject() {
  local d="$1"
  case "$2" in
    check_core_import_boundary)
      rm -rf "$d/Sources/SwiftSymbols" ;;
    check_job_timeouts)
      rm -rf "$d/.github" ;;
    check_suite_time_limit)
      printf 'import SwiftSymbols\nimport Testing\n\nstruct NotASuite {}\n' > "$d/Tests/SwiftSymbolsTests/ModuleTests.swift"
      printf 'import SwiftSymbolsUI\nimport Testing\n\nstruct NotASuite {}\n' > "$d/Tests/SwiftSymbolsUITests/ModuleTests.swift" ;;
    check_swift_testing_only)
      printf 'import SwiftSymbols\n' > "$d/Tests/SwiftSymbolsTests/ModuleTests.swift"
      printf 'import SwiftSymbolsUI\n' > "$d/Tests/SwiftSymbolsUITests/ModuleTests.swift" ;;
    *) return 1 ;;
  esac
}

run_all() {
  for check in "${SELF_TESTABLE[@]}"; do "$check"; done
  check_nothing_local_tracked
  check_format
}

self_test() {
  local scratch clean planted got arms=0
  scratch=$(mktemp -d "${TMPDIR:-/tmp}/verify-self-test.XXXXXX")
  trap "rm -rf '$scratch'" EXIT
  clean="$scratch/clean"
  write_clean_tree "$clean"
  for check in "${SELF_TESTABLE[@]}"; do
    got=$(outcome_of "$clean" "$check")
    arms=$((arms + 1))
    if [ "$got" = PASS ]; then pass "self-test: $check passes a clean tree"; else fail "self-test: $check FAILED a clean tree"; fi
  done
  for check in "${SELF_TESTABLE[@]}"; do
    planted="$scratch/planted-$check"
    write_clean_tree "$planted"
    plant_violation "$planted" "$check"
    got=$(outcome_of "$planted" "$check")
    arms=$((arms + 1))
    if [ "$got" = FAIL ]; then pass "self-test: $check trips on its planted violation"; else fail "self-test: $check MISSED its planted violation"; fi
    planted="$scratch/second-$check"
    write_clean_tree "$planted"
    if plant_second_violation "$planted" "$check"; then
      got=$(outcome_of "$planted" "$check")
      arms=$((arms + 1))
      if [ "$got" = FAIL ]; then pass "self-test: $check trips on its second planted violation"; else fail "self-test: $check MISSED its second planted violation"; fi
    fi
    planted="$scratch/third-$check"
    write_clean_tree "$planted"
    if plant_third_violation "$planted" "$check"; then
      got=$(outcome_of "$planted" "$check")
      arms=$((arms + 1))
      if [ "$got" = FAIL ]; then pass "self-test: $check trips on its third planted violation"; else fail "self-test: $check MISSED its third planted violation"; fi
    fi
    planted="$scratch/fourth-$check"
    write_clean_tree "$planted"
    if plant_fourth_violation "$planted" "$check"; then
      got=$(outcome_of "$planted" "$check")
      arms=$((arms + 1))
      if [ "$got" = FAIL ]; then pass "self-test: $check trips on its fourth planted violation"; else fail "self-test: $check MISSED its fourth planted violation"; fi
    fi
    planted="$scratch/fifth-$check"
    write_clean_tree "$planted"
    if plant_fifth_violation "$planted" "$check"; then
      got=$(outcome_of "$planted" "$check")
      arms=$((arms + 1))
      if [ "$got" = FAIL ]; then pass "self-test: $check trips on its fifth planted violation"; else fail "self-test: $check MISSED its fifth planted violation"; fi
    fi
    planted="$scratch/subjectless-$check"
    write_clean_tree "$planted"
    if remove_subject "$planted" "$check"; then
      got=$(outcome_of "$planted" "$check")
      arms=$((arms + 1))
      if [ "$got" = FAIL ]; then pass "self-test: $check fails when its subject is gone"; else fail "self-test: $check PASSED with its subject gone"; fi
    fi
  done
  printf '%d self-test arms\n' "$arms"
}

swift_files() {
  find "$ROOT/$1" -name '*.swift' -type f 2>/dev/null | sort
}

# The smallest tree every check passes on. The core module's doc comment names banned symbols on
# purpose: it proves comment lines are excluded from the code checks.
write_clean_tree() {
  local d="$1"
  mkdir -p "$d/Sources/SwiftSymbols" "$d/Sources/SwiftSymbolsUI" "$d/Sources/SwiftSymbolsTestSupport" "$d/Tests/SwiftSymbolsTests" "$d/Tests/SwiftSymbolsUITests" "$d/Scripts"
  cat > "$d/Sources/SwiftSymbols/Module.swift" <<'EOF'
import Foundation

/// A symbol name. The doc comment may say Date(), unsafe, import SwiftUI, and DispatchQueue.
public struct SymbolName: Sendable {
  public let rawValue: String
}
EOF
  cat > "$d/Sources/SwiftSymbolsUI/Module.swift" <<'EOF'
import SwiftSymbols
import SwiftUI

public struct SymbolImage: Sendable {}
EOF
  cat > "$d/Sources/SwiftSymbolsTestSupport/SuiteTimeLimit.swift" <<'EOF'
package let suiteTimeLimitMinutes = 1
EOF
  cat > "$d/Tests/SwiftSymbolsTests/ModuleTests.swift" <<'EOF'
import SwiftSymbols
import SwiftSymbolsTestSupport
import Testing

@Suite(
  "Catalog module", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ModuleTests {
  @Test func aSymbolNameKeepsItsString() {
  }
}
EOF
  cat > "$d/Tests/SwiftSymbolsUITests/ModuleTests.swift" <<'EOF'
import SwiftSymbolsTestSupport
import SwiftSymbolsUI
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes))) struct ModuleTests {
  @Test func aSymbolImageIsMade() {
  }
}
EOF
  mkdir -p "$d/.github/workflows"
  cat > "$d/.github/workflows/ci.yml" <<'EOF'
name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  apple:
    runs-on: macos-26
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v7
EOF
  cat > "$d/.github/workflows/docs.yml" <<'EOF'
name: Docs
on:
  push:
    branches: [main]
permissions:
  contents: read
jobs:
  build:
    runs-on: macos-26
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
EOF
  printf '# Readme\n' > "$d/README.md"
  printf '# Changelog\n' > "$d/CHANGELOG.md"
  printf '# Contributing\n' > "$d/CONTRIBUTING.md"
  printf 'version: 1\n' > "$d/.spi.yml"
  printf '// swift-tools-version: 6.2\n' > "$d/Package.swift"
}

case "${1:-}" in
  "") run_all ;;
  --self-test) self_test ;;
  *) printf 'usage: %s [--self-test]\n' "$0" >&2; exit 2 ;;
esac

if [ "$FAILURES" -eq 0 ]; then exit 0; fi
printf '%d check(s) failed\n' "$FAILURES"
exit 1
