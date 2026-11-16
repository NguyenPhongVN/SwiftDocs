# Multi-Module Architecture Reference (isowords style)

This document is the architecture reference for projects adopting the
`speckit-multi-module` kit. `/speckit-plan` reads it together with
`.specify/memory/constitution.md` when designing a feature. It is distilled from
[isowords](https://github.com/pointfreeco/isowords), a production iOS game + Swift server
built from 86+ Swift Package Manager modules declared in a single root `Package.swift`.

## 1. Repository layout

```text
Package.swift            ← ONE manifest; every module = one target + one product
Sources/                 ← FLAT: one directory per module (no folder trees)
Tests/                   ← MIRRORED: one directory per module, Tests/<Module>Tests
App/                     ← checked-in Xcode project: app shell + optional preview apps
```

Grouping is expressed by `// MARK: - shared | client | server` sections **inside
`Package.swift`** and by naming conventions — never by nested directory trees. The module
directory name equals the target name equals the product name.

## 2. Layers and dependency direction

```text
┌────────────────────────────────────────────────────────────┐
│  App shell (App/) — @main, live dependency wiring only     │  links: root feature + *Live
├────────────────────────────────────────────────────────────┤
│  Root feature (AppFeature) — composes top-level features   │
├─────────────────┬──────────────────────────────────────────┤
│  *Feature       │  *Core (engines: GameCore, CubeCore…)    │  may depend on features below
├─────────────────┴──────────────────────────────────────────┤
│  Kit: Styleguide · SwiftUIHelpers · TcaHelpers (*Helpers)  │
│  Clients: *Client (interface + mock, no live code)         │
│  Models: SharedModels · Build                              │
├────────────────────────────────────────────────────────────┤
│  Third-party SPM: TCA, swift-dependencies, swift-parsing…  │
└────────────────────────────────────────────────────────────┘
```

| Layer | Naming | Examples | May depend on |
|---|---|---|---|
| App shell | `App/` | `isowords`, `AppClip` | root feature + `*Live` only |
| Root feature | `*Feature` | `AppFeature` | all top-level features, engines, kit |
| Feature slice | `*Feature` | `HomeFeature`, `SettingsFeature` | sibling features it presents, `*Core`, kit, clients, models |
| Engine | `*Core` | `GameCore`, `CubeCore` | features it aggregates, clients, models |
| Design system | `Styleguide` | `Styleguide` | SwiftUIHelpers, third-party (leaf) |
| Helper | `*Helpers` | `TcaHelpers`, `DateHelpers` | third-party only (leaf) |
| Client interface | `*Client` | `ApiClient`, `FileClient` | models, TCA/dependencies lib |
| Live implementation | `*Live` | `ApiClientLive`, `DatabaseLive` | the `*Client` it implements + transport libs |
| Shared models | `SharedModels` | `SharedModels`, `Build` | Tagged-like leaf libs |
| System library | — | `Csqlite3`, `system-zlib` | nothing (`.systemLibrary` targets) |

Hard rules:

1. **Acyclic.** A module never imports a module that (transitively) imports it back.
2. **Feature-on-feature is normal and preferred** (a parent presents a child) over shared
   mutable state; parent imports child, never the reverse.
3. **The app shell is thin**: `@main` + live dependency wiring + nothing else. It links
   exactly one root feature plus the `*Live` modules.
4. **No feature imports a `*Live` module.** Live implementations are linked only by the
   app target, which injects them (`.dependency(\.client, .live)` / `liveValue`).
5. **No feature touches a side-effecting system framework directly** (StoreKit,
   UserNotifications, GameCenter, AVAudioPlayer, UserDefaults, networking…). It goes
   through a `*Client` interface module.
6. Every dependency must be declared explicitly in that target's `dependencies:` in
   `Package.swift`.

## 3. Naming conventions

| Kind | Convention | Example | Notes |
|---|---|---|---|
| Feature module | `<Name>Feature` | `HomeFeature` | reducer/view type **drops the suffix**: `Home` |
| Engine module | `<Name>Core` | `GameCore` | domain engine shared by features |
| Client interface | `<Name>Client` | `ApiClient` | interface + mock + `DependencyKey` |
| Live implementation | `<Name>Live` | `ApiClientLive` | or technology suffix: `DictionarySqliteClient` |
| Framework wrapper | `Composable<Framework>` | `ComposableStoreKit` | wraps an Apple framework |
| Design system | `Styleguide` | `Styleguide` | fonts, colors, buttons |
| Helper | `<Name>Helpers` | `TcaHelpers` | |
| Models | `SharedModels` | `SharedModels` | safe for client + server |
| Test target | `<Module>Tests` | `HomeFeatureTests` | mirrors the module |
| Integration tests | `<Module>IntegrationTests` | `GameOverFeatureIntegrationTests` | cross-boundary flows |
| Server executables | lowercase | `server`, `runner` | `.executableTarget` |

## 4. Module anatomy

### 4.1 Feature module (TCA 1.x)

One primary file `<Module>.swift` holding the reducer **and** the view; tiny private
subviews may live as sibling files.

```swift
// Sources/HomeFeature/Home.swift
import ComposableArchitecture
import Styleguide
import SwiftUI

@Reducer public struct Home {
  public init() {}

  // Presented child features, enumerated as a Destination.
  // NOTE: @Reducer(state: .equatable, …) macro options are hard-deprecated since 1.23 —
  // declare conformances in an extension instead (see TCA guide §5).
  @Reducer
  public enum Destination {
    case changelog(Changelog)
    case leaderboard(Leaderboard)
  }

  @ObservableState
  public struct State: Equatable {
    @Presents public var destination: Destination.State?
    // …feature state
    public init() {}
  }

  public enum Action {
    case destination(PresentationAction<Destination.Action>)
    // …feature actions
  }

  // Dependencies as stored @Dependency properties — never singletons.
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.mainRunLoop.now.date) var now

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      self.core(state: &state, action: action)
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination.body
    }
  }

  private func core(state: inout State, action: Action) -> Effect<Action> { … }
}

// Same file as the declaration so the compiler can synthesize `==`.
extension Home.Destination.State: Equatable {}

public struct HomeView: View {
  @Bindable var store: StoreOf<Home>
  public init(store: StoreOf<Home>) { self.store = store }
  public var body: some View { … }
}
```

Rules: everything consumer-facing is `public` (the module boundary **is** the API
boundary); internals `private`/`fileprivate`; module resources ship inside the module
via `resources: [.process("Resources/")]`.

### 4.2 Dependency client module (interface)

```swift
// Sources/FileClient/FileClient.swift
import Dependencies

@DependencyClient
public struct FileClient {
  public var save: @Sendable (Data, String) async throws -> URL
}

extension FileClient: TestDependencyKey {
  public static let testValue = FileClient()   // test/preview fails loudly unless overridden
}

extension FileClient: DependencyKey {
  public static var liveValue: FileClient { .live }
}

extension FileClient {
  public static let mock = FileClient(save: { _, _ in URL(fileURLWithPath: "/tmp/mock") })
}
```

### 4.3 Live implementation module

```swift
// Sources/FileClientLive/FileClient+Live.swift
import FileClient

extension FileClient {
  public static var live: Self {
    .init(save: { data, name in … })   // real disk/Foundation code lives ONLY here
  }
}
```

`*Live` modules are linked **only** by the app target. This is what keeps features
buildable in previews and testable without the real backend.

## 5. Package.swift conventions

```swift
// swift-tools-version: 6.4
let package = Package(
  name: "MyApp",
  platforms: [.iOS(.v17)],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.26.0"),
  ],
  targets: [
    // MARK: - shared
    .target(name: "SharedModels"),
    .product(name: "SharedModels", targets: ["SharedModels"]),

    // MARK: - client
    .target(
      name: "HomeFeature",
      dependencies: [
        "ApiClient",
        "Styleguide",
        "TcaHelpers",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .product(name: "HomeFeature", targets: ["HomeFeature"]),

    .testTarget(
      name: "HomeFeatureTests",
      dependencies: ["HomeFeature", "TestHelpers"],
      exclude: ["__Snapshots__"]
    ),
    // MARK: - server   (optionally appended under an env flag, cf. isowords TEST_SERVER)
  ]
)
```

Conventions: product name == target name; all products are plain `.library` (automatic
linking); system C libraries get their own `.systemLibrary` target (`Csqlite3`,
`system-zlib` pattern); snapshot baselines live in `__Snapshots__/` and are always
`exclude:`d from targets.

## 6. Test mirroring

- Every module gets `Tests/<Module>Tests/` registered as a `testTarget` depending on the
  module, `TestHelpers`/`FirstPartyMocks`, and `SnapshotTesting` when needed.
- Reducer tests are **exhaustive**: assert state transitions, effect execution, and
  action feedback with `customDump`/`expectNoDifference`.
- View tests are snapshot tests seeded with explicit `State` and mocked dependencies.
- Client mocks live in dedicated modules (`FirstPartyMocks`, `TestHelpers`) so test
  targets stay thin.
- Cross-boundary flows get `<Feature>IntegrationTests` that wire real router/middleware
  against client code (client + server in one process).

## 7. Running a feature in isolation

A feature must never require the full app to build, test, or run:

1. **SwiftUI previews** with mocked dependencies — first choice.
2. **Preview app targets** (`App/Previews/<Name>Preview/`) — a tiny `@main` app linking
   one feature + mocks; used when previews cannot (custom fonts, GameCenter, complex
   flows). isowords builds 9 of these from the same manifest.
3. **`swift test --filter <Module>Tests`** must pass using only that module's test target.

## 8. Adding a module — checklist

1. Classify it (feature / engine / client / live / kit / model) and name it per §3.
2. Run `bash .specify/scripts/bash/create-new-module.sh <Name>` — creates
   `Sources/<Name>/` + `Tests/<Name>Tests/` with skeletons and prints the snippet.
3. Register the target/product/testTarget under the correct `// MARK:` group in
   `Package.swift`, declaring every dependency explicitly.
4. Write the module contract: public `State`/`Action`/reducer, or the client interface.
5. Write exhaustive tests with mocks (`Tests/<Name>Tests/`).
6. Wire it into the parent feature (`Destination` enum + `.ifLet`) or the app.
7. Verify it runs in isolation (test target / preview).

## 9. Sizing guidance

- A module should compile in seconds. If a file grows past ~1000 lines, split private
  subviews into sibling files or extract children into their own modules.
- Prefer many small modules over few large ones (isowords: 86+). One screen or flow =
  one module.
- Shared UI primitives go into `Styleguide` — never copy-paste them between features.
- Shared domain types go into `SharedModels` — never redefine a model in two modules.
