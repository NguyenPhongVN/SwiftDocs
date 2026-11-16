# iOS Refactor Plan (plan-only) — Template prompt dùng cho mọi dự án iOS

> **Mục đích:** lập kế hoạch refactor bảo toàn hành vi — mỗi step compile độc lập, test xanh, rollback được; chỉ kế hoạch, không thực thi.
> **Loại:** READ-ONLY — agent chỉ đọc và xuất plan; execution làm ở session sau, từng step một.
> **Cách dùng:** điền placeholder, copy block bên dưới gửi cho agent.

## Bảng placeholder

| Placeholder | Ý nghĩa | Ví dụ điền (BasicList) |
|---|---|---|
| `{{PROJECT_NAME}}` / `{{PROJECT_SUMMARY}}` / `{{PLATFORMS}}` / `{{PROJECT_PATH}}` | Thông tin dự án | như bảng ở `ios-code-quality-review.md` |
| `{{SOURCE_FILES}}` | Code liên quan cần đọc | `Sources/BasicList/*.swift` |
| `{{REFACTOR_GOAL}}` | Mục tiêu refactor | `tách config struct khỏi view, gom 3 init thành builder pattern` |
| `{{PUBLIC_SURFACE}}` | API public phải giữ source-compatible | `BasicListView, BasicListConfig, BasicListSection` |

---

## Prompt (copy từ đây)

```markdown
You are a refactoring specialist who plans behavior-preserving changes so each
step compiles, tests stay green, and rollback is trivial. You plan in steps a
reviewer can approve one at a time.

## Context (carry forward)
- Project: {{PROJECT_NAME}} — {{PROJECT_SUMMARY}} ({{PLATFORMS}})
- Working directory: {{PROJECT_PATH}}
- Refactor goal: {{REFACTOR_GOAL}}
- Constraint: the public API of {{PUBLIC_SURFACE}} MUST stay source-compatible,
  or each breaking step must state its semver move explicitly.

## Task
Produce a REFACTORING PLAN ONLY — no edits. Read the affected code, then output
a step plan where every step is independently compilable and testable.

## Scope locks
- READ-ONLY: do not edit, create, or delete any file; no builds; no installs.
- Plan only. Implementation happens later, one approved step at a time.

## Plan requirements
1. Inventory — the exact current state: files, types, call sites (file:line
   anchors) the refactor touches.
2. Steps — ordered from low to high risk. Each step: what changes, why behavior
   is preserved, how to verify (specific test/command), how to roll back.
3. Public API impact — per step: source-compatible? If not, the semver move
   (add overload in 1.x → deprecate old → remove in major).
4. Risk register — the 3 most likely ways this refactor breaks something, with
   the guard for each.
5. Test gaps — tests to add BEFORE the risky steps so the plan is verifiable.

## Output contract
Write the plan in Vietnamese (keep code identifiers in English). End the plan
with the line: `Step 1 is ready to execute on request` — do not start executing.
Ground every step in actual file:line anchors. If verification requires
information you cannot gather statically, mark [uncertain].

## Done
Stop after the plan. No follow-up changes unless I explicitly approve a step.
```

---

## Lưu ý khi điền

- Workflow chuẩn: pass này (plan) → duyệt từng step → dùng `ios-feature-implementation.md` để execute step đã duyệt.
- Nếu API public bị đổi bắt buộc, agent phải ghi rõ semver step — giữ đúng triết lý "API là promise" như pass `ios-api-design-review.md`.
