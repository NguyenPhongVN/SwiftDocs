# Prompt Library — thư viện prompt dùng lại cho mọi dự án

Template prompt cho iOS development, dùng với agentic coding assistant (ZCode/Claude Code…).

## Cách dùng

1. Mở file prompt phù hợp.
2. Điền các placeholder `{{...}}` theo bảng trong file (cột ví dụ dùng BasicList để tham khảo).
3. Copy nguyên block **"Prompt (copy từ đây)"**, gửi cho agent ở **đầu session**.
4. Đọc phần "Lưu ý khi điền" cuối mỗi file nếu lần đầu dùng.

## Danh mục

### Review — READ-ONLY (an toàn: agent không sửa file, chỉ xuất report tiếng Việt)

| File | Mục đích |
|---|---|
| [ios-api-design-review.md](ios-api-design-review.md) | Thiết kế API public/package theo Swift API Design Guidelines + semver risk |
| [ios-code-quality-review.md](ios-code-quality-review.md) | Pass tổng quát: correctness, memory, concurrency, performance, error handling |
| [ios-concurrency-audit.md](ios-concurrency-audit.md) | Swift 6 strict concurrency: Sendable, actor isolation, task lifetime, migration plan |
| [ios-swiftui-performance-review.md](ios-swiftui-performance-review.md) | Bẫy performance SwiftUI: identity, re-evaluation storm, body work, rendering cost |
| [ios-memory-leak-hunt.md](ios-memory-leak-hunt.md) | Săn retain cycle / memory growth — mỗi leak phải nêu retaining chain đầy đủ |
| [ios-architecture-review.md](ios-architecture-review.md) | Kiến trúc: boundaries, state management, DI, navigation, growth path |
| [ios-accessibility-audit.md](ios-accessibility-audit.md) | VoiceOver, Dynamic Type, contrast, touch target, Reduced Motion |
| [ios-refactor-plan.md](ios-refactor-plan.md) | Kế hoạch refactor bảo toàn hành vi — plan-only, không thực thi |

### Agentic — agent được ghi file (đọc scope locks + stop conditions trước khi paste ⚠️)

| File | Mục đích |
|---|---|
| [ios-feature-implementation.md](ios-feature-implementation.md) | Implement feature trọn gói theo spec, có checkpoint và Done criteria |
| [ios-unit-test-writer.md](ios-unit-test-writer.md) | Sinh unit test — chỉ được ghi file trong thư mục Tests |
| [ios-bug-repro-debug.md](ios-bug-repro-debug.md) | Debug 2 pha: Phase 1 diagnose READ-ONLY → duyệt → Phase 2 fix + regression test |

## Workflow gợi ý

- **Pass review định kỳ:** `ios-code-quality-review.md` → các pass chuyên sâu (concurrency / performance / memory / architecture / a11y) theo finding nghi trọng.
- **Fix sau review:** `ios-refactor-plan.md` (plan) → duyệt step → `ios-feature-implementation.md` (execute).
- **Có bug:** `ios-bug-repro-debug.md` (diagnose → duyệt → fix).
- **Sau khi thêm API mới:** `ios-api-design-review.md` + `ios-unit-test-writer.md`.

## Convention

- File đặt tên `<miền>-<việc>.md`; mỗi prompt một file.
- Prompt body viết tiếng Anh; header/table/lưu ý tiếng Việt; report output tiếng Việt (identifier giữ tiếng Anh).
- Mọi claim không chắc phải mark `[uncertain]` — cấm bịa guideline/API/measurement.
