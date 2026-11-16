# The Composable Architecture (TCA) + SwiftUI — Guide for AI coding agents

> **Audience:** an automated coding agent that must read, write, review, or migrate Swift code that
> uses the [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA).
> **Goal:** give you the current API surface, the composition rules, and the failure modes, so you can
> produce code that compiles and matches the library's conventions on the first attempt.
>
> **Baseline:** TCA **1.26.2** (latest release, published 2026-08-28), verified on **2026-09-22** against
> the upstream `main` Documentation.docc and GitHub release notes. TCA 2.0 is in preparation; the
> `1.24`/`1.25` releases are an intentional deprecation runway toward it. When you generate code,
> **prefer the "current" column of §15 and never emit the "legacy" APIs** unless the repository already
> uses them.

---

## 0. How to use this document

| Situation | Read |
| --- | --- |
| Writing a new feature | §4, §5, §6, §7, §10, §11 |
| Composing/embedding features | §8 |
| Sheets, alerts, drill-downs, nav stacks | §9 |
| Async work, cancellation, clocks | §10 |
| Networking / system APIs | §11 |
| Cross-screen or persisted state | §12 |
| Writing tests | §13 |
| Reviewing or fixing code that does not compile / misbehaves | §14, §16 |
| Migrating legacy code | §15 |
| Before you hand work back | §17 |

Conventions used below: ✅ current/documented; ⚠️ deprecated but still present; ⛔ removed or a bug.

---

## 1. What TCA is, and when to reach for it

TCA is a state-management library for Swift apps (SwiftUI, UIKit, AppKit) built around four ideas:

1. **State** is a value type describing everything the feature needs.
2. **Action** is a value type describing everything that can happen.
3. **Reducer** is a pure function `(inout State, Action) -> Effect<Action>` that mutates state and
   describes side effects.
4. **Store** is the runtime object that holds state, feeds actions through the reducer, runs effects,
   and drives SwiftUI observation.

Practical guidance from the maintainers (FAQ article):
- Do **not** use TCA as a first step in learning Swift/SwiftUI, and it is overkill for simple
  "fetch JSON and display it" apps.
- TCA complements SwiftUI rather than replacing it: you still use `sheet(item:)`, `NavigationStack`,
  `@Bindable`, `@Environment`, etc.
- The library's biggest payoff is **exhaustive testing of logic + effects** and **feature composition**.

---

## 2. Install

```swift
// Package.swift
let package = Package(
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.26.0"
    ),
  ],
  targets: [
    .target(
      name: "<target>",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    )
  ]
)
```

Rules and constraints:

- ✅ Single import: `import ComposableArchitecture`. It re-exports the companion packages
  (`Dependencies`, `CasePaths`, `Clocks`, `Perception`, `Sharing`, `SwiftNavigation`-adjacent tools).
- ✅ Minimum platform: **iOS 16 / macOS 13 / tvOS 16 / watchOS 9** (1.24 deprecated the pre-16 range).
- ✅ Swift **6.1+** (1.24 deprecated older toolchains). The library is Swift 6 strict-concurrency clean
  since 1.15.
- ⚠️ Do **not** statically link `ComposableArchitecture` into your *test target* if it is already
  linked into the app target — that produces "live dependency" test failures from duplicate symbols.
  Remove it from the test target's link phase.
- 💡 Optional "prepare for 2.0" package traits (1.25+):

```swift
.package(
  url: "https://github.com/pointfreeco/swift-composable-architecture",
  from: "1.26.0",
  traits: ["ComposableArchitecture2Deprecations", "ComposableArchitecture2DeprecationOverloads"]
)
```

  - `ComposableArchitecture2Deprecations` — leave on; warns on APIs that will be removed.
  - `ComposableArchitecture2DeprecationOverloads` — enable temporarily only; can regress compile times.

---

## 3. Canonical feature skeleton (memorize this shape)

```swift
import ComposableArchitecture

@Reducer
struct CounterFeature {
  @ObservableState
  struct State: Equatable {
    var count = 0
    var isLoading = false
    var fact: String?
  }

  enum Action {
    case incrementButtonTapped
    case decrementButtonTapped
    case factButtonTapped
    case factResponse(String)
  }

  @Dependency(\.numberFact) var numberFact

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementButtonTapped:
        state.count += 1
        return .none

      case .decrementButtonTapped:
        state.count -= 1
        return .none

      case .factButtonTapped:
        state.isLoading = true
        return .run { [count = state.count] send in
          // Effects may only capture immutable, Sendable values — never `state` itself.
          await send(.factResponse(try await self.numberFact.fetch(count)))
        }

      case let .factResponse(fact):
        state.isLoading = false
        state.fact = fact
        return .none
      }
    }
  }
}
```

View:

```swift
struct CounterView: View {
  let store: StoreOf<CounterFeature>          // read-only view

  var body: some View {
    Form {
      Text("\(store.count)")                  // state is read directly off the store
      Button("−") { store.send(.decrementButtonTapped) }
      Button("+") { store.send(.incrementButtonTapped) }
      Button("Fact") { store.send(.factButtonTapped) }
      if let fact = store.fact { Text(fact) }
    }
  }
}
```

App entry point:

```swift
@main
struct MyApp: App {
  static let store = Store(initialState: CounterFeature.State()) {
    CounterFeature()
  }
  var body: some Scene {
    WindowGroup { CounterView(store: Self.store) }
  }
}
```

> 💡 Hold the root store in `static let` (or a `@StateObject`) so it is not re-created every time the
> parent view body is evaluated. `@State`'s initializer is eager; `@StateObject`'s is lazy (1.19).
> Xcode previews also run the app entry point, which is why `static let` is recommended.

---

## 4. Naming and type-alias vocabulary

| Alias | Expands to | Use |
| --- | --- | --- |
| `StoreOf<R>` | `Store<R.State, R.Action>` | type of a feature's store |
| `ReducerOf<R>` | `Reducer<R.State, R.Action>` | return type of `body` |
| `EffectOf<R>` | `Effect<R.Action>` | an effect of a reducer's domain |
| `StackActionOf<R>` | `StackAction<R.State, R.Action>` | actions for a `NavigationStack` `Path` |
| `PresentationAction<A>` | — | wraps a presented child's action |
| `IdentifiedArrayOf<T>` | — | stable-identity collections (re-exported) |

Naming conventions used throughout Point-Free's code and docs — follow them:

- Reducer: `Feature` / `XxxFeature`; state: `State`; actions: `Action`.
- View actions: `...ButtonTapped`, `...Changed`, `onAppear`, `task`.
- Effect results: `<thing>Response`, `<thing>Result`.
- Delegation to parent: nested `enum Delegate { case ... }` + `case delegate(Delegate)`.
- IDs: `enum CancelID { case load, timer }` for cancellation.

---

## 5. The `@Reducer` macro — the contract

`@Reducer` synthesizes conformance to `Reducer` (and `CaseReducer`). What it does for you:

1. Applies `@CasePathable` to your `Action` enum → enables key-path syntax for cases
   (`\.factResponse`, `\.counter.incrementButtonTapped`).
2. Applies `@ObservableState` to `State` if you did not (⚠️ but **explicitly annotate `State` with
   `@ObservableState`** — modern code does it explicitly, and it is required for observation).
3. Conforms `Action` to `Equatable`/`Sendable` when possible and provides `CaseScope`/`scope`
   helpers.
4. On an `enum` reducer (`@Reducer enum Destination`), generates `State`/`Action` enums, one case per
   listed feature, and composes their reducers.

Rules:

- ✅ `State` should be `Equatable` (required by `TestStore`) and `Sendable`.
- ✅ `body` returns `some ReducerOf<Self>`; the simplest body is `Reduce { state, action in ... }`.
- ✅ `@Reducer` works on `struct` (feature) and `enum` (destination/path).
- ⛔ Do **not** call `reducer.reduce(into:action:)` directly (hard-deprecated in 1.25); only the store
  drives actions.
- ⚠️ `@Reducer(state: .equatable, action: .sendable, ...)` is **deprecated** (1.23). Declare
  conformances in an extension instead:

```swift
extension Feature.State: Equatable, Sendable {}
extension Feature.Action: Hashable {}
```

- 💡 For enum reducers, cases holding **non-feature** data need an explicit marker:

```swift
@Reducer
enum Destination {
  @ReducerCaseIgnored                 // plain data, no child reducer
  case meeting(id: Meeting.ID)

  @ReducerCaseEphemeral               // AlertState / ConfirmationDialogState
  case alert(AlertState<Alert>)

  case settings(SettingsFeature)

  enum Alert { case deleteTapped }
}
```

- 💡 Restrict what a view may send with `ViewAction` + `@ViewAction(for:)`:

```swift
@Reducer
struct LoginFeature {
  enum Action: ViewAction {
    case loginResponse(Bool)
    case view(View)
    enum View { case loginButtonTapped }
  }
}

@ViewAction(for: LoginFeature.self)
struct LoginView: View {
  let store: StoreOf<LoginFeature>
  var body: some View {
    Button("Login") { send(.loginButtonTapped) }   // ✅ not store.send
  }
}
```

---

## 6. State and observation rules

- ✅ Annotate `State` with `@ObservableState`. Views then observe **only the fields they read**, like
  vanilla `@Observable`.
- ✅ Read state directly: `store.count`, `store.user.name`. There is no view-store indirection.
- ⚠️ `ViewStore`, `WithViewStore`, `IfLetStore`, `ForEachStore`, `SwitchStore`, `NavigationLinkStore`,
  `NavigationStackStore`, `BindingViewState`, `BindingViewStore`, `Store.withState` are all
  **hard-deprecated** (1.24/1.25). Never generate them for new code.
- ⚠️ TCA also supports `@ObservationStateIgnored`/`@ObservationStateTracked` to control tracking on
  individual fields (rarely needed).
- iOS 16 support uses the **Perception** backport:
  - ⚠️ Some views need `WithPerceptionTracking { ... }` around body content, otherwise you get a purple
    runtime warning *"Perceptible state was accessed but is not being tracked."*
  - ⚠️ Lazy closures (`ForEach`, `sheet` content, …) need their **own** nested `WithPerceptionTracking`.
  - ⚠️ Bindings on iOS 16 use `@Perception.Bindable` instead of `@Bindable`.
  - 💡 On iOS 17+ none of this is needed. If the project's minimum target is ≥ iOS 17, do not add it.
- `@Shared` readers inside a view on pre-iOS 17 also require `WithPerceptionTracking`.

---

## 7. Views: reading state, sending actions, bindings

```swift
struct SearchView: View {
  @Bindable var store: StoreOf<SearchFeature>   // only when you need `$store.…` bindings

  var body: some View {
    Form {
      TextField("Query", text: $store.query)     // requires BindableAction + BindingReducer
      Text("\(store.results.count) results")

      Button("Search") { store.send(.searchButtonTapped) }

      // Scoped child store handed to a child view:
      ChildView(store: store.scope(\.child, action: \.child))
    }
  }
}
```

Rules:

- ✅ `store.send(action)` returns a `StoreTask`; ignore it (`@discardableResult`) unless you need to
  await the effect: `.task { await store.send(.task).finish() }`.
- ⚠️ `store.send(action, animation:)` / `send(_:transaction:)` are on the deprecation path. Use:
  `withAnimation { store.send(action) }`.
- ✅ Scoping: `store.scope(\.child, action: \.child)` — the **unlabeled** `scope(_:action:)` form is
  current (1.26); the old `store.scope(state:action:)` is renamed/deprecated (`StoreDeprecations`).
- ✅ Only scope along **stored** properties. Scoping through a *computed* property recomputes the
  child state on every access and is a known performance trap (`Performance` article).
- ✅ Two-way bindings, two options:
  - Ad-hoc: `$store.query.sending(\.queryChanged)` with an explicit action.
  - Boilerplate-free: conform `Action` to `BindableAction` and add `BindingReducer()`.

```swift
@Reducer
struct Settings {
  @ObservableState
  struct State: Equatable { var displayName = ""; var notifications = false }
  enum Action: BindableAction { case binding(BindingAction<State>) }

  var body: some ReducerOf<Self> {
    BindingReducer()                       // performs field mutations for you
    Reduce { state, action in
      switch action {
      case .binding(\.displayName):        // react to individual fields
        return .none
      default: return .none
      }
    }
  }
}
```

- ⚠️ `@BindingState` and `BindingReducer(Action.view)`-style helpers are hard-deprecated (1.24). With
  `@ObservableState` you just declare plain properties; no `@BindingState` needed.

---

## 8. Composing features

`body` is a result builder (`ReducerBuilder`). Stack reducers; later ones run *after* earlier ones.

| Operator | Use when | Example |
| --- | --- | --- |
| `Reduce { }` | leaf logic | `Reduce { state, action in ... }` |
| `.ifLet(\.$child, action: \.child) { Child() }` | optional `@Presents` child | sheet/drill-down |
| `.ifLet(\.$destination, action: \.destination)` | enum destination reducer (child inferred) | tree navigation |
| `.ifCaseLet(\.enum, action: \.enum)` | enum state without extra branching | "advanced" |
| `.forEach(\.rows, action: \.rows) { Row() }` | collection of child features | lists, stacks |
| `.onChange(of: \.value) { oldValue, state in … }` | react to a state change | new streamlined form (1.25) |
| `.signpost(_:log:)` | performance instrumentation | debug builds |
| `._printChanges()` | print every action + state diff | debug builds only |
| `.dependency(\.client, .mock)` | run a child feature with overridden dependencies | onboarding/previews |

```swift
var body: some ReducerOf<Self> {
  Reduce { state, action in
    switch action {
    case .addButtonTapped:
      state.addItem = ItemFormFeature.State()   // setting non-nil presents the sheet
      return .none
    default: return .none
    }
  }
  .ifLet(\.$addItem, action: \.addItem) { ItemFormFeature() }
}
```

Intercept child actions by destructuring **the parent's** action:

```swift
case .destination(.presented(.editItem(.saveButtonTapped))):
  guard case let .editItem(editItemState) = state.destination else { return .none }
  state.destination = nil
  return .run { _ in await self.database.save(editItemState.item) }
```

⚠️ `.onChange` old form `{ oldValue, newValue in Reduce { … } }` is deprecated (1.25). Current form
returns an `Effect` directly and receives `(oldValue, newState)`:

```swift
BindingReducer()
  .onChange(of: \.userSettings.isHapticFeedbackEnabled) { oldValue, state in
    .run { [isOn = state.userSettings.isHapticFeedbackEnabled] send in
      await self.userDefaults.set(isOn)
    }
  }
```

---

## 9. Navigation

TCA unifies navigation with two toolkits. Both are "domain first": you model the destination in state,
and SwiftUI's own modifiers present it.

### 9.1 Tree-based (optional / enum state)

```swift
@Reducer
struct InventoryFeature {
  @ObservableState
  struct State: Equatable {
    @Presents var addItem: ItemFormFeature.State?          // single destination
    // or: @Presents var destination: Destination.State?    // enum of destinations
    var items: IdentifiedArrayOf<Item> = []
  }
  enum Action {
    case addItem(PresentationAction<ItemFormFeature.Action>)
    // or: case destination(PresentationAction<Destination.Action>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.addItem = ItemFormFeature.State()             // navigate by populating state
        return .none
      default: return .none
      }
    }
    .ifLet(\.$addItem, action: \.addItem) { ItemFormFeature() }
  }
}
```

View:

```swift
struct InventoryView: View {
  @Bindable var store: StoreOf<InventoryFeature>

  var body: some View {
    List { /* … */ }
      .sheet(item: $store.scope(\.addItem, action: \.addItem)) { store in
        ItemFormView(store: store)
      }
  }
}
```

Enum destinations give compile-time proof only one destination is active. Present a case by
dot-chaining off the scoped destination:

```swift
.sheet(item: $store.scope(\.destination, action: \.destination).addItem) { store in
  AddItemView(store: store)
}
.popover(item: $store.scope(\.destination, action: \.destination).editItem) { store in
  EditItemView(store: store)
}
.navigationDestination(item: $store.scope(\.destination, action: \.destination).detailItem) { store in
  DetailItemView(store: store)
}
```

> **Version note (matters when editing old code):** older releases wrote
> `$store.scope(state: \.destination?.addItem, action: \.destination.addItem)` — case-level scoping
> with an explicit `state:` label. That form is deprecated. The 1.25 migration guide shows
> `state: \.$destination`; the current articles on `main` show the unlabeled `\.destination`. Both
> key-path spellings are accepted by the compiler in the current release family; if one fails to
> compile against a pinned version, try the other. Always drop the `state:` label in new code.
>
> Also new in 1.25: enum scoping no longer wraps non-reducer cases in a `Store`. Those payloads must
> be `Identifiable`, or (for empty cases producing `Optional<Void>`) you switch to the
> `isPresented:` modifier:
>
> ```swift
> .sheet(isPresented: Binding($store.scope(\.$destination, action: \.destination).help)) { … }
> ```

### 9.2 Stack-based (`StackState`)

```swift
@Reducer
struct RootFeature {
  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
  }
  enum Action {
    case path(StackActionOf<Path>)
  }

  @Reducer
  enum Path {
    case addItem(AddItemFeature)
    case detailItem(DetailItemFeature)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .path(.element(id: _, action: .list(.detailButtonTapped))):
        state.path.append(.detailItem(DetailItemFeature.State()))
        return .none
      default: return .none
      }
    }
    .forEach(\.path, action: \.path)     // Path() inferred from `@Reducer enum Path`
  }
}
```

View:

```swift
struct RootView: View {
  @Bindable var store: StoreOf<RootFeature>

  var body: some View {
    NavigationStack(path: $store.scope(\.path, action: \.path)) {
      // root view; push with NavigationLink(state:) or by sending actions
      NavigationLink(state: RootFeature.Path.State.addItem(AddItemFeature.State())) {
        Text("Add item")
      }
    } destination: { store in
      switch store.case {                       // exhaustively pattern-match the path enum
      case .addItem(let store):    AddItemView(store: store)
      case .detailItem(let store): DetailItemView(store: store)
      }
    }
  }
}
```

- ✅ `StackState` is `Collection`/`RangeReplaceableCollection`: `append`, `popLast()`, `pop(from: id)`,
  `[id:]` subscript, iteration. Prefer it over `NavigationPath` (which is type-erased and
  append/removeLast-only).
- ✅ Push by `NavigationLink(state:)` (needs the full `Path.State` value, hurts modularity) or by
  sending an action and appending in the parent reducer (better modularity).
- ✅ Intercept child actions with `.path(.element(id:action:))`; the `id` lets you locate and pop.
- ✅ UIKit: `NavigationStackController(path:root:destination:)` drives `UINavigationController` from
  `StackState`.
- ✅ Alerts/dialogs in a stack screen work like any other feature; `AlertState`/`ConfirmationDialogState`
  conform to `_EphemeralState`.

### 9.3 Alerts and confirmation dialogs

```swift
@ObservableState
struct State: Equatable {
  @Presents var alert: AlertState<Action.Alert>?
}

enum Action {
  case deleteButtonTapped
  case alert(PresentationAction<Alert>)
  enum Alert { case confirmDeletion }
}

// in the reducer
case .deleteButtonTapped:
  state.alert = AlertState {
    TextState("Delete?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeletion) { TextState("Delete") }
    ButtonState(role: .cancel) { TextState("Cancel") }
  }
  return .none

// in the view
.alert($store.scope(\.alert, action: \.alert))
```

### 9.4 Dismissal

- Parent dismisses by `state.destination = nil` / `state.path.popLast()`.
- A child can dismiss itself without knowing the parent, using the `dismiss` **dependency**:

```swift
@Dependency(\.dismiss) var dismiss
...
return .run { _ in await self.dismiss() }     // must run inside .run — it is async
```

- ⛔ Never send another action after `dismiss()`; the state is gone and you will get a runtime warning
  plus a test failure.
- Note `@Dependency(\.dismiss)` (reducer-side) is a **different type** from SwiftUI's
  `@Environment(\.dismiss)` (view-side). Both exist; do not mix them up.

---

## 10. Effects

```swift
return .none                                        // no work
return .run { send in                               // async work, can send many actions
  await send(.response(try await client.fetch()))
}
return .run(name: "load") { send in … }             // named task (1.23+)
return .run { send in
  await send(.tick, animation: .default)            // animate a state change
}
return .cancel(id: CancelID.load)                   // cancel a previous effect
```

Rules:

- 🔒 **Closures in `.run` are `@Sendable`.** You cannot capture `state` (it is `inout`). Capture
  immutable copies:

```swift
return .run { [count = state.count] send in … }        // ✅
return .run { [state] send in await send(.x(state.count)) }  // ✅
return .run { send in await send(.x(state.count)) }    // ⛔ mutable capture of inout parameter
```

- 🔒 Dependencies used from effects must be `Sendable`; annotate client closures `@Sendable`.
- ⏱ Time-based work must use an injectable clock, never `Task.sleep`:

```swift
@Dependency(\.continuousClock) var clock
return .run { send in
  for _ in 1...5 {
    try await self.clock.sleep(for: .seconds(1))       // InstantClock in tests
    await send(.tick)
  }
}
```

- 🚫 **Re-entrancy** (1.25+): sending an action *while another action is being processed* now emits a
  runtime warning and will become a precondition failure. Never call `store.send` from inside reducer
  logic or from a synchronous effect; restructure instead.
- ♻️ **Effect lifetime** (1.18+): a store cancels its in-flight effects when it deallocates. If an
  effect must outlive the store (analytics, persistence), wrap it in an unstructured `Task { }`.
- ⚠️ `.concatenate`, `.map` on effects, `Effect.animation(_:)`, `Effect.transaction(_:)`,
  `Effect.debounce`, `Effect.throttle` and all Combine-scheduler-based operators are deprecated
  (1.24/1.25). Sequence work inside a single `.run` with `async`/`await`; cancel with
  `.cancellable(id:)` / `clock.sleep` instead of debounce/throttle.
- ⚠️ `store.publisher` / `StorePublisher` is deprecated; use observation (`observe { … }` in UIKit).
- ⚠️ `TaskResult` is hard-deprecated (1.24).
- 💡 Share logic between actions with **methods**, not with extra actions. Sending a "shared" action
  costs a full pass through the reducer tree and bloats tests:

```swift
// ✅ recommended
case .buttonTapped:
  state.count += 1
  return self.sharedComputation(state: &state)

func sharedComputation(state: inout State) -> Effect<Action> { … }
```

- 💡 CPU-heavy work belongs in an effect (cooperative thread pool), not in the reducer (main thread);
  `await Task.yield()` periodically.
- 💡 High-frequency actions are expensive. For sliders/scroll, buffer in view-local `@State` and send
  one action on commit; for progress reporting, throttle inside the effect.

---

## 11. Dependencies

```swift
struct NumberFactClient {
  var fetch: @Sendable (Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
  static let liveValue = NumberFactClient(
    fetch: { number in
      let (data, _) = try await URLSession.shared.data(from: URL(string: "…")!)
      return String(decoding: data, as: UTF8.self)
    }
  )
  static let testValue = NumberFactClient(fetch: { _ in "0 is a good number" })
  static let previewValue = NumberFactClient(fetch: { "\($0) is a good number" })
}

extension DependencyValues {
  var numberFact: NumberFactClient {
    get { self[NumberFactClient.self] }
    set { self[NumberFactClient.self] = newValue }
  }
}

// in a reducer
@Dependency(\.numberFact) var numberFact
```

- Override per reducer: `Feature().dependency(\.userDefaults, .mock)`.
- Override per store / per test: `withDependencies { $0.numberFact.fetch = { … } }`.
- Built-in dependencies worth knowing: `\.uuid`, `\.date`, `\.calendar`, `\.timeZone`, `\.continuousClock`,
  `\.dismiss`, `\.defaultAppStorage`, `\.defaultFileStorage`, `\.mainQueue`, `\.mainRunLoop`.
- `@Dependency` inside a reducer is lazy — construct the client in the call, not in a stored property.

---

## 12. Shared state (`@Shared` / `@SharedReader`)

Value-type state is copied, so sharing is a first-class concern. Tools live in the **Sharing** package
(re-exported by TCA; extracted in 1.17).

```swift
@Reducer
struct ChildFeature {
  @ObservableState
  struct State: Equatable {
    @Shared var count: Int                      // explicit, in-memory, passed by reference
    @Shared(.inMemory("count")) var cached = 0  // app-wide, non-persisted
    @Shared(.appStorage("count")) var saved = 0 // UserDefaults
    @Shared(.fileStorage(.users)) var users: [User] = []   // JSON on disk (Codable)
  }
}

// parent passes a reference, not a copy:
state.child = ChildFeature.State(count: state.$count)
```

Rules:

- ✅ Mutating shared state is a reference operation — guard compound updates with `withLock`:
  `state.$count.withLock { $0 += 1 }`.
- ✅ Derive sub-parts by dot-chaining the projection: `state.$currentUser.name`.
- ✅ `@SharedReader` = read-only variant; `SharedReaderKey` = read-only persistence strategy.
- ✅ Type-safe keys are strongly recommended:

```swift
extension SharedReaderKey where Self == FileStorageKey<IdentifiedArrayOf<User>> {
  static var users: Self { fileStorage(.users) }
}
// then: @Shared(.users) var users: IdentifiedArrayOf<User> = []
```

- ⛔ `@Shared` values are **not** `Hashable`, and **not** `Codable`; write custom `encode`/`decode`
  when an enclosing type must be codable.
- ⚠️ Do not combine `$x.publisher` subscriptions with mutations of the same shared value — infinite loop.
- ✅ Initializers: assign the underscored property (`self._count = count`) — rules differ for
  parent-owned vs feature-owned vs persisted shared state (see the SharingState article).
- ✅ In tests `appStorage`/`fileStorage` are automatically non-persisting, and `TestStore` snapshots
  shared values so you can still assert exhaustively.
- ✅ Keys containing `.` or `@` fall back to `NotificationCenter` (slower, cross-thread hop, and
  `withAnimation` will not animate them). Prefer `:`/`/`/`-` in keys.
- ✅ UI tests: override `defaultAppStorage`/`defaultFileStorage` to in-memory via an environment flag.

---

## 13. Testing

```swift
import Testing

@MainActor
struct CounterFeatureTests {
  @Test
  func increment() async {
    let store = TestStore(initialState: CounterFeature.State()) {
      CounterFeature()
    }

    await store.send(.incrementButtonTapped) { $0.count = 1 }   // no effect → nothing to receive
  }

  @Test
  func fact() async {
    let store = TestStore(initialState: CounterFeature.State()) {
      CounterFeature()
    } withDependencies: {
      $0.numberFact.fetch = { "\($0) is a good number" }
    }

    await store.send(.factButtonTapped) { $0.isLoading = true }
    await store.receive(\.factResponse) {
      $0.isLoading = false
      $0.fact = "0 is a good number"                            // fetch(count) with the initial count 0
    }
  }
}
```

Rules:

- ✅ Mark suites/tests `@MainActor`; `TestStore` is main-actor isolated. Test methods should be `async`.
- ✅ The trailing closure of `send` describes the expected state **after** the action, written as
  literal values. `$0` is the state *before* the action (exhaustive mode).
- ✅ Every effect must be accounted for with `receive(_:)`; every effect must finish before the test
  store deallocates, else "an effect returned for this action is still running".
- ✅ Use `\.casePath` syntax for received actions; chain through children/navigation
  (`\.login.submitButtonTapped`, `\.counter.dismiss`, `\.path[id: 0].counter.response`).
- ✅ Subscript helper for stack/enum mutation:

```swift
await store.send(\.path[id: 0].counter.incrementButtonTapped) {
  XCTModify(&$0.path[id: 0], case: \.counter) { $0.count = 4 }
}
```

- ✅ Non-exhaustive integration tests:

```swift
store.exhaustivity = .off                      // or .off(showSkippedAssertions: true)
```

  In non-exhaustive mode `$0` is the state **after** the action, and **relative** mutations
  (`removeLast()`, `+=`) are illegal — use absolute assignments.
- ✅ Dependency overrides go in `withDependencies`; `ImmediateClock()` makes timers instant.
- ✅ Shared state: assert with `store.assert { $0.$count.withLock { $0 = 1 } }`, or capture the
  `@Shared` in the test and mutate it inside the assertion closure for robustness.
- ⚠️ Shared-state mutations must be asserted on the **first** action that leads to them (a TestStore
  implementation detail that predates `@Shared`).
- ⛔ Do not store `TestStore` as a property of the test type — it must deallocate at the end of the
  test. If it cannot, call `await store.finish()`.
- ⚠️ App-host tests run the real app entry point; guard it with `if TestContext.current == nil { … }`.
- ⛔ Do not carelessly perform side effects in assertion closures when using
  `.off(showSkippedAssertions: true)` — the closure runs twice.

---

## 14. Debugging and runtime warnings

| Symptom | Cause / fix |
| --- | --- |
| "Perceptible state was accessed but is not being tracked" | wrap in `WithPerceptionTracking` (pre-iOS 17) / add `@ObservableState` |
| "A reentrant action was sent while processing another action" | action sent synchronously from reducer/effect; restructure |
| Sending an action for a feature whose state is `nil` | sent an action after `dismiss()`; stop immediately after dismissing |
| Test: "An effect returned for this action is still running" | assert with `receive(_:)` or make the effect complete |
| Test: "Expected state to change, but no change occurred" | wrong expectation or the effect completed before assertion |
| Test: live dependency used unexpectedly | app entry point ran during tests, or `CA` statically linked into the test target |
| Views re-rendering too much | scoping through computed properties; mixing legacy `ViewStore` features with modern ones |
| Can't see what changed | `._printChanges()` on a reducer (debug only) |

---

## 15. API status matrix (baseline 1.26.2)

| Concern | ✅ Current | ⚠️ Deprecated | Note |
| --- | --- | --- | --- |
| Observation | `@ObservableState` | `ViewStore`, `WithViewStore`, `IfLetStore`, `ForEachStore`, `SwitchStore`, `BindingViewState`, `BindingViewStore`, `Store.withState`, `store.publisher` | hard-deprecated 1.24/1.25 |
| Bindings | plain properties + `BindableAction`/`BindingReducer` | `@BindingState`, `BindingReducer(Action.view)` | hard-deprecated 1.24 |
| Store scoping | `store.scope(\.child, action: \.child)` | `store.scope(state:action:)` | renamed 1.26 |
| Enum destinations | `$store.scope(\.$destination, action: \.destination).case`, `@Reducer enum` | `Scope(state:action:)` on enum state, case-level `\.destination?.case` | 1.25 |
| Effects | `.run { send in … }`, `.cancellable(id:)`, `.cancel(id:)`, clock sleeps | `Effect.concatenate/map`, `.animation()`, `.transaction()`, `.debounce`, `.throttle`, Combine schedulers, `TaskResult` | 1.24/1.25 |
| Animation | `withAnimation { store.send(a) }`, `send(a, animation:)` inside `.run` | `store.send(_:animation:)`, `store.send(_:transaction:)` | |
| `onChange` | `.onChange(of:) { oldValue, state in effect }` | `.onChange(of:) { oldValue, newValue in Reduce { … } }` | 1.25 |
| State mutation | `store.send(_:)`, `Effect.send` | `reducer.reduce(into:action:)` | hard-deprecated 1.25 |
| Type names | `Effect<Action>` (or `EffectOf<Feature>`) | `Effect` → `EffectOf` trait-deprecation (1.25) | namespace-only; both spellings exist |
| Conformance synthesis | extensions | `@Reducer(state: .equatable, action: …)` | hard-deprecated 1.23 |
| Enum case markers | `@ReducerCaseIgnored`, `@ReducerCaseEphemeral` | — | 1.25 |
| View-side action routes | `ViewAction` + `@ViewAction(for:)` | — | optional but recommended |
| Platform | iOS 16+ / Swift 6.1+ | iOS <16, Swift <6.1 | deprecated in 1.24 |

Direction of travel: **1.24 = deprecation-only cleanup, 1.25 = deprecations + enum scoping + new
`onChange` + reentrancy warnings, 1.26 = `scope(_:action:)` unification.** TCA 2.0 will remove the
deprecated surface, so new code should never depend on it.

---

## 16. Pitfalls checklist (fast review heuristics)

1. `State` missing `@ObservableState` → views won't update.
2. Capturing `state` inside `.run` → compile error (`inout` capture).
3. Using `Task.sleep` instead of an injected clock → slow, flaky tests.
4. Sending an action from inside reducer logic → reentrancy warning (future crash).
5. `store.send` inside `body` instead of inside a button/`.task` action → update loop.
6. Scoping along computed properties → repeated expensive recomputation.
7. Modelling multiple destinations as several optionals → invalid states; use one enum.
8. Asserting relative mutations in non-exhaustive tests → crash/false failure.
9. `TestStore` held as a test-class property → skipped exhaustive assertions.
10. Root store in `@State` → recreated on every parent body evaluation; use `static let`/`@StateObject`.
11. Fire-and-forget effect expected to outlive the store → wrap in `Task { }`.
12. Reaching for `ViewStore`/`WithViewStore` from old tutorials → deprecated; read state directly.
13. `@Shared` marked `Hashable`/`Codable`, or mutated without `withLock`.
14. Linking `ComposableArchitecture` into both app and test targets → phantom live-dependency failures.

---

## 17. Definition-of-done for an agent

- [ ] Code compiles against the pinned TCA version; no deprecated API in new code (§15).
- [ ] `State` is `@ObservableState` + `Equatable`; `Action` is a nested enum; `body` is
      `some ReducerOf<Self>`.
- [ ] Every effect is cancellable where it can be restarted (`CancelID`); no `Task.sleep`; no
      re-entrant sends.
- [ ] All outside-world access goes through `@Dependency` clients with `liveValue` + `testValue`.
- [ ] Views read state directly from the store; bindings via `@Bindable` + `BindableAction`.
- [ ] Navigation modelled with `@Presents`/`PresentationAction` (tree) or `StackState`/`StackActionOf`
      (stack); dismissal via `\.dismiss` dependency, never sending after dismiss.
- [ ] Tests: `TestStore` per test, `@MainActor`, effects asserted with `receive`, dependencies
      overridden, `await store.finish()` if the store cannot deallocate.
- [ ] Verification evidence captured: exact build/test command, exit status, relevant output.

---

## 18. Sources (upstream, verified 2026-09-22)

- Repository: https://github.com/pointfreeco/swift-composable-architecture
- DocC articles used: `GettingStarted`, `TestingTCA`, `Navigation`, `TreeBasedNavigation`,
  `StackBasedNavigation`, `SharingState`, `Bindings`, `DependencyManagement`, `SwiftConcurrency`,
  `Performance`, `FAQ`, `ObservationBackport`, `MigrationGuides` (`1.7` … `1.19`, `1.25`).
- Release notes read: `1.18.0`, `1.19.0`, `1.21.0`–`1.26.2`.
- Rendered docs: https://pointfreeco.github.io/swift-composable-architecture/
- Point-Free video collection: https://www.pointfree.co/collections/composable-architecture
- Companion packages: `swift-dependencies`, `swift-case-paths`, `swift-clocks`, `swift-sharing`,
  `swift-identified-collections`, `swift-perception` (provides the `Perception` module — note there
  is no repository named `swift-observation`, see the README warning).

*Provenance note: content assembled from the upstream repository at `main` plus GitHub release
metadata on 2026-09-22. Version numbers, deprecation stages and API spellings change; re-verify §15
against the pinned version before large migrations.*
