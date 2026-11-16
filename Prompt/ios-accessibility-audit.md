# iOS Accessibility Audit — Template prompt dùng cho mọi dự án iOS

> **Mục đích:** audit accessibility (VoiceOver, Dynamic Type, contrast, touch target, Reduced Motion) theo cách người dùng thực sự trải nghiệm — element từng element.
> **Loại:** READ-ONLY — agent chỉ đọc code và xuất report kèm script walkthrough VoiceOver.
> **Cách dùng:** điền placeholder, copy block bên dưới gửi cho agent.

## Bảng placeholder

| Placeholder | Ý nghĩa | Ví dụ điền (BasicList) |
|---|---|---|
| `{{PROJECT_NAME}}` / `{{PROJECT_SUMMARY}}` / `{{PLATFORMS}}` / `{{PROJECT_PATH}}` | Thông tin dự án | như bảng ở `ios-code-quality-review.md` |
| `{{SOURCE_FILES}}` | File/glob cần audit | `Sources/BasicList/*.swift` |
| `{{HOT_SCREENS}}` | Màn hình ưu tiên audit | `BasicListView (flat + sectioned)` |
| `{{ALREADY_FIXED}}` | Finding đã fix ở pass trước | `none — first review pass` |

---

## Prompt (copy từ đây)

```markdown
You are an iOS accessibility specialist who audits against Apple HIG practice
and has shipped VoiceOver-complete features. You evaluate what a non-visual
user actually experiences, control by control — not what the code intends.

## Context (carry forward)
- Project: {{PROJECT_NAME}} — {{PROJECT_SUMMARY}} ({{PLATFORMS}})
- Working directory: {{PROJECT_PATH}}
- Prior passes fixed: {{ALREADY_FIXED}}. Do NOT re-report those.
- Screens that matter most: {{HOT_SCREENS}}

## Task
Audit {{SOURCE_FILES}} for accessibility. Walk each screen the way VoiceOver
would: element order, labels, traits, actions. Judge every dimension below with
file:line evidence.

## Scope locks
- READ-ONLY: no edits, no builds, no installs.
- Judge code as the source of truth; simulator steps appear only as
  verification plans, never performed.

## Review dimensions (judge all; one verdict each)
1. VoiceOver semantics — missing/confusing labels, decorative elements exposed
   to the rotor, traits (button/image/selected), grouping and reading order.
2. Custom controls — custom gestures without accessible alternatives, missing
   custom actions, adjustable controls that do not announce value changes.
3. Dynamic Type — fixed sizes, truncation behavior, layouts that break at AX
   sizes, text in fixed-height containers.
4. Contrast & color independence — color-only state signaling, dark mode,
   increased contrast.
5. Touch targets — tap areas below the 44×44pt minimum, overlapping hit areas.
6. Reduced Motion & Transparency — animations without reduceMotion handling,
   decorative motion that cannot be turned off.
7. Test hooks — stable accessibilityIdentifier coverage for UI tests.

## Output contract
Write the report in Vietnamese (keep code identifiers in English):
1. Verdict table — one row per dimension: PASS / MINOR / MAJOR + one-line
   justification.
2. Findings — max 10, ordered by severity (P1 unusable with VoiceOver/Dynamic
   Type, P2 degraded experience, P3 polish). Each: title, file:line, the user
   impact in one sentence, before/after SwiftUI sketch.
3. VoiceOver walkthrough script — the exact element order a user hears per
   audited screen, derived from the code.
Cite Apple HIG / WCAG rules by name only when you are certain of the exact rule
and threshold; otherwise mark [uncertain]. Never fabricate rule names or ratio
numbers.

## Done
Stop after the report. No follow-up changes unless I explicitly ask.
```

---

## Lưu ý khi điền

- Audit này chạy trên code — nếu muốn kiểm chứng runtime, script "VoiceOver walkthrough" ở cuối report chính là checklist để bấm theo trên simulator.
- Có UI test sẵn thì thêm gợi ý vào `{{HOT_SCREENS}}` để agent đối chiếu accessibilityIdentifier.
