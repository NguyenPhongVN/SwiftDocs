# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [./spec.md](./spec.md) | **Input**: [feature description]

**Note**: This template is filled in by the `/speckit-plan` command. Multi-module specifics
(Constitution Check gates, Module Decomposition, Package.swift changes) are the heart of
this plan — do not delete those sections.

## Summary

[One paragraph from the spec: what is being built and the primary user value.]

## Technical Context

**Language/Version**: Swift 6.4+ (swift-tools-version 6.4)
**Primary dependencies**: [Composable Architecture (TCA) 1.x, swift-dependencies, swift-custom-dump, swift-snapshot-testing — adjust to the project]
**Storage**: [if applicable — else N/A]
**Testing**: [XCTest + swift-snapshot-testing, run via `swift test` / `xcodebuild test`]
**Target platform**: [iOS 17+ / macOS 14+ / etc.]
**Package manager**: Swift Package Manager — single root `Package.swift`
**Project type**: [single iOS app / app + App Clip / client+server monorepo]
**Architecture reference**: ARCHITECTURE.md (repo root) — read before filling the sections below

| Need | Answer | Notes |
|---|---|---|
| Which existing modules are touched? | [list or none] | |
| Which new modules are required? | [list or none] | see Module Decomposition |
| New third-party packages? | [list or none] | each must be added to `Package.swift` |
| Any unresolvable question? | [NEEDS CLARIFICATION: …] | → goes to research.md |

## Constitution Check

*Gates re-evaluated after Phase 1 design. Source: `.specify/memory/constitution.md`.*

| Gate | Principle | Status | Justification (only if violated) |
|---|---|---|---|
| New code lives in an appropriate module (existing or new) | I | ☐ | |
| Dependency direction acyclic; all deps declared in `Package.swift` | II | ☐ | |
| Side effects behind `*Client` interface; live impl separate, app-linked only | III | ☐ | |
| One feature = one module, naming + anatomy per ARCHITECTURE.md §3–4 | IV | ☐ | |
| `Tests/<Module>Tests` mirrored and registered for every touched/new module | V | ☐ | |
| Feature builds/tests/runs in isolation (test target, preview) | VI | ☐ | |
| Public surface explicit and minimal (module boundary = API boundary) | VII | ☐ | |
| Targets registered under the correct `// MARK:` group in the manifest | VIII | ☐ | |

**Post-design check**: [re-run after Phase 1 and record ✓/✗ per gate]

## Module Decomposition *(mandatory — the core of a multi-module plan)*

New and changed modules for this feature:

| Module | Layer (per ARCHITECTURE.md §2) | New/Changed | Depends on | Responsibilities |
|---|---|---|---|---|
| [e.g. HomeFeature] | Feature slice | Changed | [clients, kit…] | [one line] |
| [e.g. SyncClient] | Client interface | New | [SharedModels] | [one line] |
| [e.g. SyncClientLive] | Live implementation | New | [SyncClient] | [one line] |

**Package.swift changes**:

- [ ] targets: [list `.target(name:dependencies:)` additions, with the `// MARK:` group each belongs to]
- [ ] products: [list `.product(name:targets:)` additions]
- [ ] testTargets: [list `.testTarget(name:dependencies:)` additions, each with `exclude: ["__Snapshots__"]` if snapshots used]
- [ ] third-party packages: [list `.package(url:…)` additions or "none"]

**Dependency direction diagram** (update after design):

```text
[App shell] → [RootFeature] → [NewFeature] → [NewClient] ← [App links NewClientLive]
```

## Project Structure

### Documentation (this feature)

```text
specs/NNN-<feature-name>/
├── spec.md          ← WHAT/WHY (from /speckit-specify)
├── plan.md          ← this file
├── research.md      ← Phase 0: decisions resolving NEEDS CLARIFICATION
├── data-model.md    ← Phase 1: entities → State/Action/Dependencies per module
├── contracts/       ← Phase 1: module contracts (public surface per module)
├── quickstart.md    ← Phase 1: isolated run/validation guide
└── tasks.md         ← from /speckit-tasks
```

### Source code (repository layout)

```text
Sources/<Module>/         ← flat; one directory per module, name == target == product
Sources/<Module>/Resources/   ← module-local assets, bundled via .process("Resources/")
Tests/<Module>Tests/      ← mirrored test targets
App/                      ← thin app shell(s) + optional preview app targets
```

## Phase 0: Outline & Research

For every unknown above (and every integration or best-practice question), produce a
research task; consolidate findings in `research.md` as **Decision / Rationale /
Alternatives considered**. Output: all NEEDS CLARIFICATION resolved.

## Phase 1: Design & Contracts

- **data-model.md**: extract entities from the spec; for each module define its public
  `State` / `Action` / child `Destination` / injected dependencies (or the client
  interface's method set), with validation rules and state transitions.
- **contracts/**: one contract file per new/changed module
  (`contracts/<module>.md`) — its public surface only: reducer + State + Action
  signature, or client interface + mock contract. Consumers (parent feature, app shell)
  reference these files; nothing outside a module may assume non-public internals.
- **quickstart.md**: runnable validation proving the feature works end-to-end in
  isolation — which test target(s) to run (`swift test --filter <Module>Tests`), which
  preview app to launch, expected observable outcomes. No implementation code.

**Re-run Constitution Check** after this phase and record the result above.

## Complexity Tracking

*Any Constitution Check gate marked ✗ MUST be justified here.*

| Violation | Why needed | Simpler alternative rejected because |
|---|---|---|
| | | |
