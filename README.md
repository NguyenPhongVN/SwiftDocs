# SwiftDocs

> A knowledge base for **Swift** development and app development across the **Apple** ecosystem — written for both human developers and AI coding agents.

- Repository: [NguyenPhongVN/SwiftDocs](https://github.com/NguyenPhongVN/SwiftDocs)
- Documentation language: English (technical terms are kept in their original form — see [Documentation Language Conventions](#-documentation-language-conventions))
- Technical data last verified: **September 22, 2026** — methodology and sources listed in [Verified Sources](#-verified-sources)

**Notation:** ✅ recommended / verified · ⚠️ use with caution · ⛔ do not do this

---

## 📁 Repository structure

| Path | Contents |
| --- | --- |
| [`TCA-SwiftUI-Agent-Guide.md`](./TCA-SwiftUI-Agent-Guide.md) | In-depth guide to The Composable Architecture (TCA) + SwiftUI: API surface, composition rules, navigation, testing, the API status matrix, and review checklists |
| `projects/` | Folder for Swift projects (currently empty) |

---

## 🧱 Tech stack overview

### 1. Language & foundations

| Component | Details |
| --- | --- |
| **Swift 6.x** | The primary language. Latest stable release: **6.4.0** (per [swift.org](https://www.swift.org/)). The TCA guide in this repo requires at least Swift 6.1, and TCA 1.26.2's manifest declares `swift-tools-version: 6.4`, so a Swift 6.4+ toolchain is the verified configuration ✅ |
| **Swift Concurrency** | `async/await`, `AsyncSequence`, actors, structured concurrency, and task cancellation |
| **SwiftUI** | The primary UI framework: `@Observable`/Observation, `NavigationStack`, `@Bindable`, `sheet(item:)` |
| **UIKit / AppKit** | Complementary frameworks for backward compatibility; TCA supports SwiftUI, UIKit, and AppKit alike |
| **Swift 6 strict concurrency** | The default target for new code: data-race safety enforced at compile time |

### 2. Architecture & state management — TCA (The Composable Architecture)

The centerpiece of this tech stack is [**swift-composable-architecture**](https://github.com/pointfreeco/swift-composable-architecture) by Point-Free:

- **Pinned version:** `1.26.2` — released August 28, 2026, the latest release as of September 22, 2026 ✅. TCA 2.0 is in preparation; releases 1.24–1.26 form an intentional deprecation runway.
- **The model:** `State` (a value type) + `Action` (an enum) + `Reducer` (a pure `(inout State, Action) -> Effect<Action>` function) + `Store` (the runtime that dispatches actions and drives SwiftUI observation).
- **License:** MIT ✅ (verified from the LICENSE file at tag 1.26.2).
- **Installation via Swift Package Manager:**

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        from: "1.26.0"
    )
]
```

**Core rules for writing TCA code** (full details in the guide, §3–§12):

- ✅ Use the `@Reducer` macro; mark `State` with `@ObservableState` + `Equatable`; read state directly from the store in views, and use bindings via `@Bindable`.
- ✅ Effects may only capture immutable `Sendable` values — ⛔ never capture `state`.
- ✅ Route all access to the outside world (network, storage, clocks) through `@Dependency` clients with `liveValue` / `testValue` / `previewValue`.
- ✅ Navigation: tree-based (`@Presents` + `PresentationAction`) or stack-based (`StackState` + `StackActionOf`); dismiss via the `\.dismiss` dependency.
- ✅ Use `@Shared` / `@SharedReader` for shared state; wrap compound mutations in `withLock`.

### 3. Companion packages (Point-Free)

`import ComposableArchitecture` re-exports the following packages — no separate dependency declarations needed:

| Package | Role | Repository |
| --- | --- | --- |
| `swift-dependencies` | Dependency injection: `@Dependency`, `withDependencies` | [GitHub](https://github.com/pointfreeco/swift-dependencies) |
| `swift-case-paths` | Case paths for enums — first-class pattern matching | [GitHub](https://github.com/pointfreeco/swift-case-paths) |
| `swift-clocks` | Controllable clocks — replace `Task.sleep` to keep tests deterministic | [GitHub](https://github.com/pointfreeco/swift-clocks) |
| `swift-sharing` | `@Shared` / `@SharedReader` — shared state and persistence | [GitHub](https://github.com/pointfreeco/swift-sharing) |
| `swift-identified-collections` | `IdentifiedArray` — safe id-keyed collections | [GitHub](https://github.com/pointfreeco/swift-identified-collections) |
| `swift-perception` | `@Perceptible`/Perception tooling — backports observation to iOS 16 | [GitHub](https://github.com/pointfreeco/swift-perception) |

> ⚠️ Note: Perception is the observation-backport package. There is **no** repository named `swift-observation` in the Point-Free organization.

### 4. Testing

| Tool | Role |
| --- | --- |
| **Swift Testing** (`import Testing`) | The primary test framework: `@Test`, `@Suite`, `#expect` — upstream repository at [swiftlang/swift-testing](https://github.com/swiftlang/swift-testing); suites should be marked `@MainActor` |
| **`TestStore`** | Exhaustive TCA testing: assert each mutation, `await store.receive(...)`, and override dependencies via `withDependencies` |
| **XCTest** | Retained for legacy unit/UI tests. ⚠️ Do not link `ComposableArchitecture` into the test target when the app target already links it — this causes duplicate-symbol errors and "live dependency" failures |

### 5. Tooling & the Apple toolchain

| Tool | Role |
| --- | --- |
| **Xcode** | The primary IDE — latest release: **Xcode 27** (GA September 14, 2026). Download at [developer.apple.com/xcode](https://developer.apple.com/xcode/) |
| **Swift Package Manager** | The repository's dependency manager |
| **Instruments** | Performance profiling: retain cycles, main-thread hitches, energy |
| **Simulator / `xcodebuild`** | Command-line builds and tests — well suited to CI and to AI agents verifying their own work |
| **TestFlight / App Store Connect** | Beta distribution and release |

### 6. Apple platforms

The minimum deployment targets are **as declared in TCA 1.26.2's manifest** (verified from `Package.swift`):

| Platform | Minimum version |
| --- | --- |
| iOS / iPadOS | 16 |
| macOS | 13 |
| tvOS | 16 |
| watchOS | 9 |

> ⚠️ TCA 1.26.2's manifest does not declare visionOS. If your project needs visionOS, verify compatibility yourself before committing to it.

---

## 🗂 Documentation language conventions

Documentation in this repository follows these rules:

1. **Explain in English**, keeping technical terms in their original form (Reducer, Effect, Store, Dependency, State…) — never translate them halfway.
2. Spell proper names with their exact canonical casing: `SwiftUI`, `UIKit`, `Xcode`, `The Composable Architecture`.
3. Code blocks keep the original English API; comments inside code are written in English.
4. Status notation is used consistently: ✅ recommended/verified · ⚠️ use with caution · ⛔ do not do this.
5. Every version number must be traceable to a source in [Verified Sources](#-verified-sources).

---

## ✅ Definition of Done

The quality bar for Swift code produced in this project (full version in the guide, §17):

- [ ] Compiles against the pinned TCA version; ⛔ no deprecated APIs in new code (status matrix in the guide, §15).
- [ ] `State` has `@ObservableState` + `Equatable`; `Action` is a nested enum; `body` is `some ReducerOf<Self>`.
- [ ] Effects are cancellable where they can restart (`CancelID`); ⛔ no `Task.sleep`; ⛔ no re-entrant action sends.
- [ ] All side effects go through `@Dependency` clients with `liveValue` + `testValue`.
- [ ] Navigation uses `@Presents`/`PresentationAction` or `StackState`; dismissal goes through `\.dismiss`.
- [ ] Tests use `TestStore` (`@MainActor`, overridden dependencies, exhaustive `receive` assertions).
- [ ] Verification evidence captured: the exact build/test command, exit status, and relevant output.

---

## 🤖 For AI coding agents

1. Read [`TCA-SwiftUI-Agent-Guide.md`](./TCA-SwiftUI-Agent-Guide.md) before touching TCA code — start with the §0 table (situation → sections to read) and §17 (definition of done).
2. Prefer the "current" column of the API matrix in §15; ⛔ never emit "legacy" APIs.
3. Always verify with real builds/tests and record the evidence before handing work back.

---

## 🔎 Verified sources

Every technical claim in this README was checked directly on **September 22, 2026**:

| Claim | Verified value | Source |
| --- | --- | --- |
| Latest TCA release | 1.26.2 (August 28, 2026) | GitHub Releases API for `pointfreeco/swift-composable-architecture` |
| TCA minimum platforms | iOS 16 / macOS 13 / tvOS 16 / watchOS 9 | `Package.swift` at tag `1.26.2` |
| TCA `swift-tools-version` | 6.4 | `Package.swift` at tag `1.26.2` |
| TCA license | MIT | `LICENSE` at tag `1.26.2` |
| Latest stable Swift | 6.4.0 | swift.org releases API |
| Latest Xcode | Xcode 27 (GA September 14, 2026) | Web search synthesis, September 22, 2026 |
| Companion package repositories | 6/6 links live (HTTP 200) | GitHub API |
| TCA docs link on Swift Package Index | Taken verbatim from TCA's official README; direct checks from this machine were blocked by SPI's bot protection (HTTP 403) — open it in a browser to confirm | `swift-composable-architecture` README |
| External links in this README | 15/16 URLs returned HTTP 200 in a sequential `curl` check on September 22, 2026 (the remaining URL is the SPI docs link above) | Sequential `curl` check |

> Software versions change over time. Before major upgrades, re-check the [TCA releases](https://github.com/pointfreeco/swift-composable-architecture/releases) and [swift.org](https://www.swift.org/).

---

## 🔗 References

- [The Composable Architecture — official repository](https://github.com/pointfreeco/swift-composable-architecture)
- [TCA — official documentation (Swift Package Index)](https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture)
- [Point-Free — TCA video collection](https://www.pointfree.co/collections/composable-architecture)
- [Swift.org — language & toolchain](https://www.swift.org/)
- [Swift Testing — upstream repository](https://github.com/swiftlang/swift-testing)
- [Xcode — official page](https://developer.apple.com/xcode/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 📄 License

- The text content of this repository is owned by the repository owner — if you distribute it publicly, consider adding a `LICENSE` file at the repository root.
- Referenced libraries keep their own licenses — for example, TCA is released under the **MIT License**.
