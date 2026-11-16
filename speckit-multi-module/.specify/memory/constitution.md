<!--
SYNC IMPACT REPORT
==================
Version: (none) → 1.0.0 — initial ratification
Principles: 8 established (I–VIII), no amendments
Templates status:
  ✅ .specify/templates/plan-template.md   — Constitution Check gates map to I–VIII
  ✅ .specify/templates/spec-template.md   — tech-agnostic, aligned
  ✅ .specify/templates/tasks-template.md  — Setup phase includes module scaffolding tasks
Follow-up TODOs:
  - Replace [PROJECT_NAME] with the real project name on adoption (README step 3).
Amendments:
  1.0.0 → 1.0.1 (2026-11-17): PATCH — clarified access-level vocabulary in Principle VII;
  fixed governance field name (LAST_AMENDED → "Last Amended").
-->
# [PROJECT_NAME] Constitution — Multi-Module Swift Architecture

**Version**: 1.0.1 | **Ratified**: 2026-11-02 | **Last Amended**: 2026-11-17

## Preamble

This project is built in a hyper-modularized style, adapted from isowords: every feature,
engine, dependency client, and model lives in its own Swift Package Manager module, all
declared in a single root `Package.swift`. A module is the unit of build, test, preview,
and reuse. Every specification (`/speckit-specify`), plan (`/speckit-plan`), and task list
(`/speckit-tasks`) MUST comply with the principles below. A plan MAY devolve from a
principle only with an explicit, written justification in its Complexity Tracking
section. The full technical reference is `ARCHITECTURE.md` (repo root).

### Core Principles

### Principle I — One Manifest, Many Modules

All modules are declared in the single root `Package.swift`; `Sources/` is flat with one
directory per module; the directory name equals the target name equals the product name;
every product is a plain `.library` with automatic linking. Grouping is expressed by
`// MARK:` sections in the manifest and by naming conventions, never by directory trees.

**Rationale**: module-level isolation is what makes incremental builds fast, SwiftUI
previews stable, and slim binaries (e.g. App Clips) possible.

### Principle II — Strict, Acyclic Dependency Direction

Dependencies flow one way only: App shell → root feature → `*Feature`/`*Core` modules →
Kit (`Styleguide`, `*Helpers`) + client interfaces (`*Client`) + models (`SharedModels`) →
third-party packages. The app shell is thin (`@main` + live wiring only) and links the
root feature and `*Live` modules exclusively. Features may import sibling features they
present (parent imports child, never the reverse). A module MUST NOT import a module that
transitively imports it back, and every dependency MUST be declared explicitly in that
target's `dependencies:`.

**Rationale**: cycles defeat incremental compilation and make reuse impossible.

### Principle III — Interface/Live Split for All Side Effects

Every side-effecting system (networking, storage, audio, notifications, StoreKit,
GameCenter, clocks, random…) is wrapped in a dependency client: the interface, its mock,
and its `DependencyKey`/`testValue` live in a `*Client` module; the real implementation
lives in a separate `*Live` module linked **only** by the app target, which injects it.
Features MUST NOT import `*Live` modules and MUST NOT call side-effecting frameworks
directly.

**Rationale**: features must be exercisable in previews and tests with in-memory mocks;
this is what enables exhaustive reducer tests and isolated preview apps.

### Principle IV — One Feature, One Module

Each user-facing feature is its own vertical-slice module named `<Name>Feature`, whose
reducer/view type drops the suffix (`Home` in `HomeFeature`). The module contains one
primary `<Module>.swift` with reducer + view, child features as a nested `Destination`
enum composed with `.ifLet`, and dependencies declared as stored `@Dependency` properties.
Domain engines shared by several features are `<Name>Core` modules. Shared UI primitives
go to `Styleguide`; shared models to `SharedModels` — never duplicated between features.

**Rationale**: a screen or flow is the natural unit of ownership, review, and reuse;
keeping it whole in one module keeps the blast radius of change small.

### Principle V — Mirrored, Exhaustive Testing

Every module has a mirrored `Tests/<Module>Tests` target registered in `Package.swift`
(`exclude: ["__Snapshots__"]`). Reducer tests are exhaustive — state transitions, effect
execution, and action feedback asserted with `customDump`-style diffs. View tests are
snapshot tests seeded with explicit `State` and mocked dependencies. Client mocks live in
dedicated `TestHelpers`/`FirstPartyMocks` modules. Cross-boundary flows get
`<Module>IntegrationTests`.

**Rationale**: in TCA-style architectures tests are the fastest, most precise feedback
loop; exhaustive tests are cheap only when mocks are trivial to install.

### Principle VI — Run in Isolation

Every feature MUST build, test, and run without the full app: its test target passes via
`swift test --filter <Module>Tests`, its previews render with mocked dependencies, and a
tiny preview app target (`App/Previews/<Name>Preview`) is used when previews are not
enough. No feature may reach through singletons or depend on app-global state.

**Rationale**: isolated execution is the payoff of Principles I–IV; it is also how bugs
get isolated and iterations stay fast.

### Principle VII — Explicit, Minimal Public Surface

The module boundary is the API boundary. Everything a consumer needs is `public`
(reducer, `State`, `Action`, view, client interface); everything else is
`internal`/`fileprivate`/`private`. Cross-module reach into another module's internals is
forbidden; adding public surface requires justification.

**Rationale**: SwiftPM enforces nothing beyond `public`; discipline here is what keeps
module contracts stable and refactorable.

### Principle VIII — Manifest Groups and Platform Gating

Targets are registered under the correct `// MARK:` group in `Package.swift`
(`shared`, `client`, `server`, or project equivalents). Code usable by several platform
slices (client + server, app + App Clip) lives in `shared` group modules. Platform- or
flavor-specific target sets MAY be gated by environment variables in the manifest
(isowords' `TEST_SERVER` pattern). System C libraries are isolated in their own
`.systemLibrary` targets.

**Rationale**: the manifest is the single source of architectural truth; groups make the
layer map greppable and keep the server/tooling build decoupled from iOS-only code.

## Governance

- This constitution supersedes ad-hoc practices in specs, plans, and tasks.
- `/speckit-plan` MUST run the Constitution Check gates (mapped to Principles I–VIII)
  before design and re-check after design; unjustified violations are build errors for
  the plan.
- Amendments follow semantic versioning: MAJOR for removing/redefining a principle,
  MINOR for adding a principle or materially expanding guidance, PATCH for
  clarifications. Record the change in a Sync Impact Report comment at the top of this
  file and update the **Last Amended** date.
- Compliance is reviewed during `/speckit-analyze` and code review; recurring violations
  are constitution bugs — fix the principle or the practice, not just the instance.

**Version**: 1.0.1
