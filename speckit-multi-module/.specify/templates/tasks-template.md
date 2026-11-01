# Tasks: [FEATURE]

**Input**: [design documents link]
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md,
contracts/, quickstart.md (optional — generate tasks from what exists)

**Tests: [check with user — requested / not requested]**
*In this architecture tests are strongly recommended (Principle V): reducer tests per
module, snapshot tests for views.*

## Format

Every task strictly: `- [ ] [TaskID] [P?] [Story?] Description with file path`

- `[P]` = parallelizable (different files, no dependency on an incomplete task)
- `[US1]` etc. = user story label, required for user-story phases only
- Task IDs sequential in execution order (T001, T002…)

## Path Conventions

```text
Sources/<Module>/         ← flat feature/client/kit modules; one directory per module
Tests/<Module>Tests/      ← mirrored test targets
Package.swift             ← every module and dependency is registered here
App/                      ← thin app shell + optional preview app targets
```

Module registration tasks must name the `// MARK:` group the target belongs to
(Principle VIII).

## Phase 1: Setup

- [ ] T001 Scaffold new modules from plan.md Module Decomposition: run
      `bash .specify/scripts/bash/create-new-module.sh <Name>` for each, which creates
      `Sources/<Name>/` and `Tests/<Name>Tests/` and prints the registration snippet
- [ ] T002 Register targets/products/testTargets in Package.swift under the correct
      `// MARK:` group per plan.md "Package.swift changes"
- [ ] T003 Add third-party `.package(url:…)` dependencies to Package.swift (if any)

## Phase 2: Foundational (Blocking Prerequisites)

**⚠ CRITICAL: no user-story work may start before this phase is complete**

- [ ] T004 Implement shared model additions in Sources/SharedModels/ per data-model.md [P]
- [ ] T005 Implement client interfaces (State-less contracts): method set + mock +
      `testValue` in Sources/<Name>Client/ per contracts/<name-client>.md [P]
- [ ] T006 Create public reducer/State/Action skeletons in each new
      Sources/<Name>Feature/<Name>.swift per contracts/<name>.md [P]

## Phase 3: User Story 1 (P1) — [Title]

**Goal**: [one sentence from spec US1]
**Independent Test**: [from spec — e.g. `swift test --filter <Module>Tests` passes and
the isolated preview runs the full flow with mocks]

- [ ] T007 [P] [US1] Implement State/Action in Sources/<Module>/<Module>.swift per
      contracts/<module>.md
- [ ] T008 [US1] Implement reducer core logic in Sources/<Module>/<Module>.swift with
      dependencies injected via `@Dependency`
- [ ] T009 [P] [US1] Implement <Module>View in Sources/<Module>/<Module>.swift (subviews
      in sibling files where needed)
- [ ] T010 [US1] Write exhaustive reducer tests in
      Tests/<Module>Tests/<Module>Tests.swift: state transitions, effects, action feedback
- [ ] T011 [P] [US1] Write snapshot tests for the view in
      Tests/<Module>Tests/<Module>ViewTests.swift seeded with explicit State
- [ ] T012 [US1] Wire the module into its parent feature: add to the parent's
      `Destination` enum and compose with `.ifLet` in Sources/<ParentFeature>/
- [ ] T013 [US1] Implement live implementation in Sources/<Name>Live/ and link it only in
      the app shell's dependency wiring in App/ (if a new client was introduced)
- [ ] T014 [US1] Run quickstart.md validation scenarios and record results

## Phase 4: User Story 2 (P2) — [Title]

[same structure: Goal, Independent Test, tests → models → reducer → view → wiring →
integration — tasks T015+]

## Final Phase: Polish & Cross-Cutting

- [ ] T0NN [P] Run the full test suite (`swift test` / `xcodebuild test`) and fix
      regressions
- [ ] T0NN [P] Re-run plan.md Constitution Check gates post-design and record results
- [ ] T0NN Update App/Previews/<Name>Preview app target (or create one) so the feature
      runs in isolation per Principle VI
- [ ] T0NN Update CHANGELOG.md / release notes (if the project keeps one)

## Dependencies & Execution Order

- Phase 1 → Phase 2 → user-story phases (P1 → P2 → P3) → Final Phase.
- Within Phase 2, client interfaces and models are blockers for everything downstream.
- Within a story: contracts/State → reducer → view → wiring → tests may interleave, but
  the module contract (T006) must exist before reducer implementation.
- Feature-on-feature wiring (T012-style) must follow the dependency direction in
  plan.md's diagram — parent imports child, never the reverse.

### Parallel groups

- Different modules are independent: reducer work on `<FeatureA>` runs parallel to
  `<FeatureB>` ([P] markers).
- Tests for a module can start once its contract skeleton exists.

## Implementation Strategy

- **MVP first**: ship US1 alone — thanks to module isolation, one finished feature module
  is already runnable via its test target and preview app without the remaining stories.
- **Incremental**: each user story adds a module (or grows one) without touching other
  stories' modules beyond wiring into the parent feature.
- Keep tasks module-scoped: a task touching three modules is a smell — split it.
