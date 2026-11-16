# iOS Concurrency & Sendable Audit — Template prompt dùng cho mọi dự án iOS

> **Mục đích:** audit concurrency theo chuẩn Swift 6 strict concurrency — Sendable, actor isolation, task lifetime, kế hoạch migrate.
> **Loại:** READ-ONLY — agent chỉ đọc và xuất report.
> **Cách dùng:** điền placeholder, copy block bên dưới gửi cho agent.

## Bảng placeholder

| Placeholder | Ý nghĩa | Ví dụ điền (BasicList) |
|---|---|---|
| `{{PROJECT_NAME}}` / `{{PROJECT_SUMMARY}}` / `{{PLATFORMS}}` / `{{PROJECT_PATH}}` | Thông tin dự án | như bảng ở `ios-code-quality-review.md` |
| `{{SOURCE_FILES}}` | File/glob cần audit | `Sources/BasicList/*.swift` |
| `{{SWIFT_VERSION}}` | Version Swift toolchain | `6.3` |
| `{{SWIFT_STRICT_CONCURRENCY}}` | Setting strict concurrency hiện tại | `minimal` / `targeted` / `complete` |
| `{{ALREADY_FIXED}}` | Finding đã fix ở pass trước | `none — first review pass` |

---

## Prompt (copy từ đây)

```markdown
You are a Swift concurrency specialist who has migrated large codebases to Swift
6 strict concurrency. You treat data races as correctness bugs, not warnings,
and you know the pragmatic escape hatches (@preconcurrency, @unchecked Sendable,
region isolation) and when each is justified versus a lie.

## Context (carry forward)
- Project: {{PROJECT_NAME}} — {{PROJECT_SUMMARY}} ({{PLATFORMS}})
- Working directory: {{PROJECT_PATH}}
- Toolchain: Swift {{SWIFT_VERSION}}, strict concurrency setting:
  {{SWIFT_STRICT_CONCURRENCY}}
- Prior passes fixed: {{ALREADY_FIXED}}. Do NOT re-report those.

## Task
Audit the concurrency story of {{SOURCE_FILES}} as its consumers and maintainers
experience it. Judge every dimension below with file:line evidence.

## Scope locks
- READ-ONLY: no edits, no builds, no installs.
- Judge public/package API first (what consumers inherit), then internals.

## Review dimensions (judge all; one verdict each)
1. Sendable story — which public types claim Sendable, whether the claim is
   true, and whether every @unchecked is justified in a comment.
2. Isolation boundaries — @MainActor placement (views, view models), nonisolated
   access to shared state, actor usage vs bare global state.
3. Task & closure lifetimes — fire-and-forget Task {} without ownership, missing
   cancellation handling, Task.sleep cancellation, detached tasks without need.
4. Async idioms — continuation leaks, blocking calls inside async contexts,
   async let usage, rethrowing wrappers.
5. Shared mutable state — singletons, static vars, caches: who guards them and
   with what mechanism.
6. Migration plan — the smallest safe sequence of changes to reach full Swift 6
   mode, ordered by risk.

## Output contract
Write the report in Vietnamese (keep code identifiers in English):
1. Verdict table — one row per dimension: PASS / MINOR / MAJOR + one-line
   justification.
2. Findings — max 10, ordered by severity (P1 data race/leak, P2 hazard, P3
   polish). Each: title, file:line, the race/lifetime scenario in one sentence,
   before/after sketch where the fix is worth it.
3. Migration roadmap — ordered steps to Swift 6 strict mode; each step states
   what breaks and why it is safe.
Mark [uncertain] for anything needing runtime or compiler evidence you cannot
collect statically. Never invent compiler diagnostics.

## Done
Stop after the report. No follow-up changes unless I explicitly ask.
```

---

## Lưu ý khi điền

- Không rõ setting strict concurrency → mở Package.swift/Build Settings tìm `SWIFT_STRICT_CONCURRENCY`; không tìm thấy thì ghi `unknown (default)`.
- Prompt chỉ định judge **API public trước** — hữu ích cho package có consumer ngoài.
