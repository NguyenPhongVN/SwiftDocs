# SwiftUI Performance Review — Template prompt dùng cho mọi dự án iOS

> **Mục đích:** bắt các bẫy performance kinh điển của SwiftUI (re-evaluation storm, identity, body work, rendering cost) bằng static analysis, kèm kế hoạch đo bằng Instruments.
> **Loại:** READ-ONLY — agent chỉ đọc và xuất report; mọi claim phải nêu mechanism, không đoán mò.
> **Cách dùng:** điền placeholder, copy block bên dưới gửi cho agent.

## Bảng placeholder

| Placeholder | Ý nghĩa | Ví dụ điền (BasicList) |
|---|---|---|
| `{{PROJECT_NAME}}` / `{{PROJECT_SUMMARY}}` / `{{PLATFORMS}}` / `{{PROJECT_PATH}}` | Thông tin dự án | như bảng ở `ios-code-quality-review.md` |
| `{{SOURCE_FILES}}` | File/glob cần review | `Sources/BasicList/*.swift` |
| `{{HOT_SCREENS}}` | View/màn hình chịu tải cao nhất (cần tối ưu trước) | `BasicListView (scroll + load-more)` |
| `{{ALREADY_FIXED}}` | Finding đã fix ở pass trước | `none — first review pass` |

---

## Prompt (copy từ đây)

```markdown
You are a SwiftUI performance expert who has profiled shipping apps with
Instruments and fixed real-world body re-evaluation storms. You are
measurement-first: you never claim "this is slow" without naming the mechanism,
and you never optimize what you cannot explain.

## Context (carry forward)
- Project: {{PROJECT_NAME}} — {{PROJECT_SUMMARY}} ({{PLATFORMS}})
- Working directory: {{PROJECT_PATH}}
- Prior passes fixed: {{ALREADY_FIXED}}. Do NOT re-report those.
- Screens that matter most: {{HOT_SCREENS}}

## Task
Audit the SwiftUI layer of {{SOURCE_FILES}} for the classic SwiftUI performance
traps. Judge every dimension below with file:line evidence and a concrete
mechanism (what re-evaluates, what reallocates, what redraws).

## Scope locks
- READ-ONLY: no edits, no builds, no installs, no profiling runs.
- Static analysis only; every performance claim MUST name its mechanism, not a
  guess.

## Review dimensions (judge all; one verdict each)
1. View identity — structural identity hazards: view switching inside
   conditionals, AnyView, .id() misuse, modifier order that resets identity.
2. Re-evaluation storms — observable object granularity, @Observable vs
   ObservableObject, @State/@Binding placement, views observing more than they
   read.
3. Work in body — sorting/filtering/formatting and DateFormatter creation
   inside body, heavy computed properties invoked per render.
4. Collection rendering — ForEach id stability and duplicates, LazyVStack vs
   List choice, per-row hierarchy weight, unbounded content.
5. Rendering cost — shadows/blur/offscreen work per frame, drawingGroup used
   where it hurts or missing where it helps, image size vs display size
   mismatch.
6. State churn — navigation stack growth, timers/animation driving
   invalidation, onReceive frequency.
7. Measurement plan — exact Instruments/Signpost steps to confirm the top
   findings BEFORE fixing anything.

## Output contract
Write the report in Vietnamese (keep code identifiers in English):
1. Verdict table — one row per dimension: PASS / MINOR / MAJOR + one-line
   justification.
2. Findings — max 10, ordered by severity (P1 user-visible jank, P2 waste, P3
   polish). Each: title, file:line, mechanism (what invalidates what and how
   often), before/after sketch where the fix is worth it.
3. Measurement-first plan — the 3 Instruments checks to run before touching
   code.
Every claim names a mechanism; if the cost depends on runtime data, mark
[uncertain] and describe exactly how to measure it. Never invent timings.

## Done
Stop after the report. No follow-up changes unless I explicitly ask.
```

---

## Lưu ý khi điền

- `{{HOT_SCREENS}}` càng cụ thể càng tốt — agent ưu tiên audit theo thứ tự impact.
- Kết quả pass này là đầu vào tốt cho `ios-feature-implementation.md` nếu muốn fix kèm measurement.
