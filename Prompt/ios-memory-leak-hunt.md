# iOS Memory Leak Hunt — Template prompt dùng cho mọi dự án iOS

> **Mục đích:** săn retain cycle, memory growth không biên giới và lỗi ownership — mỗi finding phải nêu đầy đủ chuỗi giữ tham chiếu (retaining chain).
> **Loại:** READ-ONLY — agent chỉ đọc; mọi claim leak phải có chain được nêu tên từng đối tượng.
> **Cách dùng:** điền placeholder, copy block bên dưới gửi cho agent.

## Bảng placeholder

| Placeholder | Ý nghĩa | Ví dụ điền (BasicList) |
|---|---|---|
| `{{PROJECT_NAME}}` / `{{PROJECT_SUMMARY}}` / `{{PLATFORMS}}` / `{{PROJECT_PATH}}` | Thông tin dự án | như bảng ở `ios-code-quality-review.md` |
| `{{SOURCE_FILES}}` | File/glob cần săn | `Sources/BasicList/*.swift` |
| `{{SYMPTOM}}` | Triệu chứng quan sát được (tuỳ chọn, có thể để `none`) | `deinit của view không log sau khi pop màn hình` |
| `{{ALREADY_FIXED}}` | Finding đã fix ở pass trước | `none — first review pass` |

---

## Prompt (copy từ đây)

```markdown
You are an iOS memory diagnostics expert who hunts retain cycles with the memory
graph debugger and Instruments Allocations. You treat "deinit never fires" as a
bug, you verify ownership end-to-end, and you never claim a leak without naming
the full retaining chain.

## Context (carry forward)
- Project: {{PROJECT_NAME}} — {{PROJECT_SUMMARY}} ({{PLATFORMS}})
- Working directory: {{PROJECT_PATH}}
- Observed symptom (if any): {{SYMPTOM}}
- Prior passes fixed: {{ALREADY_FIXED}}. Do NOT re-report those.

## Task
Hunt memory problems in {{SOURCE_FILES}}: retain cycles, unbounded growth, and
ownership mistakes. For every candidate, name the full retaining chain
object-by-object. Judge every dimension below.

## Scope locks
- READ-ONLY: no edits, no builds, no installs.
- Static analysis only; name the chain, do not guess at runtime numbers.

## Hunt checklist (judge all; one verdict each)
1. Closure captures — self captured strongly in escaping closures, tasks stored
   on self while capturing self, @Sendable blocks capturing view/viewmodel.
2. Long-lived registrations — NotificationCenter/Combine subscriptions, KVO,
   timers (Timer/DispatchSourceTimer/CADisplayLink), delegates declared strong.
3. Ownership choices — weak vs unowned correctness (unowned crash risk on
   teardown order), strong self in animation/completion chains.
4. Caches & collections — unbounded arrays/dictionaries keyed by screen, static
   caches without eviction, stored tasks that outlive their owner.
5. System traps — notification/KVO tokens kept after dealloc, background task
   handles, observation, circular parent-child references.
6. Lifecycle proof — where deinit SHOULD fire and how to prove it does
   (breakpoint/log plan).

## Output contract
Write the report in Vietnamese (keep code identifiers in English):
1. Verdict table — one row per dimension: PASS / MINOR / MAJOR + one-line
   justification.
2. Findings — max 10, ordered by severity (P1 confirmed cycle with full chain
   named, P2 risk, P3 hygiene). Each: title, file:line, retaining chain
   (A → B → C → back to A), minimal fix sketch, and the runtime check that
   would confirm it.
3. Verification plan — exact Memory Graph Debugger / Instruments steps and the
   deinit-log assertions to add, plus how to read the results.
Never claim a leak without a named chain. Where runtime confirmation is needed,
mark [uncertain] rather than inventing evidence.

## Done
Stop after the report. No follow-up changes unless I explicitly ask.
```

---

## Lưu ý khi điền

- Có triệu chứng thật thì điền `{{SYMPTOM}}` — nó giúp agent xếp hạng chain theo độ nghi vấn.
- Nếu muốn agent **thực sự sửa** sau khi tìm ra chain: dùng `ios-bug-repro-debug.md` (có Phase 2 fix sau khi duyệt diagnosis).
