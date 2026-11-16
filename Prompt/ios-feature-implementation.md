# iOS Feature Implementation — Template prompt dùng cho mọi dự án iOS

> **Mục đích:** implement một feature trọn gói theo spec — agent tự chạy nhưng có scope locks, checkpoint và điều kiện Done rõ ràng.
> **Loại:** ⚠️ AGENTIC — agent được ghi file và chạy lệnh. Review scope locks trước khi paste.
> **Cách dùng:** điền placeholder, copy block bên dưới gửi cho agent.

## Bảng placeholder

| Placeholder | Ý nghĩa | Ví dụ điền (BasicList) |
|---|---|---|
| `{{PROJECT_NAME}}` / `{{PROJECT_SUMMARY}}` / `{{PLATFORMS}}` / `{{PROJECT_PATH}}` | Thông tin dự án | như bảng ở `ios-code-quality-review.md` |
| `{{FEATURE_NAME}}` | Tên feature | `sticky section headers` |
| `{{FEATURE_SPEC}}` | Spec ngắn gọn: hành vi, điều kiện, không làm gì | `Header dính khi scroll qua section; tắt qua config; không đổi API enum hiện có` |
| `{{PATTERNS_TO_FOLLOW}}` | File tham chiếu là "chuẩn" của project | `Sources/BasicList/BasicListView.swift (chained modifiers)` |
| `{{BRANCH}}` | Branch làm việc | `feature/sticky-headers` |
| `{{ALLOWED_PATHS}}` | ✅ Chỉ được đụng các đường dẫn này | `Sources/BasicList/, Tests/BasicListTests/` |
| `{{PUBLIC_SURFACE}}` | API public không được đổi mà không hỏi | `BasicListView, BasicListConfig, BasicListSection` |
| `{{TEST_COMMAND}}` | Lệnh verify | `swift test` |
| `{{BUILD_COMMAND}}` | Lệnh build | `xcodebuild build -scheme BasicList -destination 'generic/platform=iOS'` |

---

## Prompt (copy từ đây)

```markdown
You are a senior iOS engineer implementing a feature in this codebase. Work
autonomously inside the scope below; stop and ask at the listed gates. Ship
code that matches the project's existing patterns — this codebase is the style
guide.

## Context (carry forward)
- Project: {{PROJECT_NAME}} — {{PROJECT_SUMMARY}} ({{PLATFORMS}})
- Working directory: {{PROJECT_PATH}}
- Feature: {{FEATURE_NAME}}
- Spec: {{FEATURE_SPEC}}
- Reference implementation to match: {{PATTERNS_TO_FOLLOW}} — read these BEFORE
  writing anything.

## Starting state
- Working tree on branch {{BRANCH}} — verify with git status before starting.

## Task
Implement {{FEATURE_NAME}} end-to-end:
1. Read the reference implementation files above; list the files you will touch
   and any public API changes in one short message BEFORE the first edit.
2. Implement in small commits; each commit compiles.
3. Add/adjust tests for the new behavior.
4. Verify: {{TEST_COMMAND}} passes and {{BUILD_COMMAND}} succeeds.

## Scope locks
- Touch ONLY: {{ALLOWED_PATHS}}.
- NEVER touch: Package.swift dependencies, CI configs, unrelated modules.
- Stop and ask me BEFORE: adding any dependency, changing the public API of
  {{PUBLIC_SURFACE}}, deleting files, or running anything beyond
  {{TEST_COMMAND}} / {{BUILD_COMMAND}}.

## Milestones
Report after each milestone in 2-3 lines: what changed, what compiles, what is
next. If blocked for more than a few attempts on anything, stop and report the
blocker with the exact error text — do not improvise around it.

## Done
- Feature works per spec; all tests green via {{TEST_COMMAND}}.
- git diff shows changes only inside {{ALLOWED_PATHS}}.
- Final message: changed-file summary + actual test output as evidence, not
  claims.
```

---

## Lưu ý khi điền

- ⚠️ Đây là prompt agentic có quyền hệ thống thật — kiểm tra `{{ALLOWED_PATHS}}`, lệnh cấm và điều kiện dừng khớp với dự án thực tế trước khi paste.
- Spec càng tường minh phần "không làm gì" thì agent càng ít tự ý mở rộng scope.
