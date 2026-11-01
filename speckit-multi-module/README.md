# Speckit Multi-Module — bộ spec-kit tái sử dụng theo kiến trúc isowords

Bộ kit này đóng gói hai thứ rút ra từ dự án isowords:

1. **Flow spec-driven development (Spec Kit)** — `/speckit-specify` → `/speckit-clarify` →
   `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` (kèm `/speckit-analyze`,
   `/speckit-checklist`).
2. **Kiến trúc multi-module (hyper-modularization)** — toàn bộ app chia thành hàng chục
   module SwiftPM nhỏ trong **một** root `Package.swift`, phân layer chặt, mỗi feature là
   một module chạy/test độc lập.

Copy kit này vào **bất kỳ dự án Swift/SwiftPM nào** là bạn có ngay flow đó, không cần đi
lại từ đầu. Nội dung kỹ thuật chi tiết nằm trong [ARCHITECTURE.md](ARCHITECTURE.md)
(bằng tiếng Anh, để agent đọc khi lập kế hoạch).

## Cấu trúc kit

```
speckit-multi-module/
├── README.md                        ← file này (hướng dẫn triển khai, tiếng Việt)
├── ARCHITECTURE.md                  ← kiến trúc multi-module distilled từ isowords
└── .specify/
    ├── memory/
    │   └── constitution.md          ← "hiến pháp" 8 nguyên tắc multi-module
    ├── templates/
    │   ├── spec-template.md         ← khung spec cho /speckit-specify
    │   ├── plan-template.md         ← khung plan cho /speckit-plan (có gate Constitution Check + Module Decomposition)
    │   ├── tasks-template.md        ← khung tasks cho /speckit-tasks
    │   └── checklist-template.md    ← khung checklist cho /speckit-checklist
    └── scripts/
        └── bash/
            ├── setup-plan.sh        ← resolve feature dir + copy plan template (dùng bởi /speckit-plan)
            ├── setup-tasks.sh       ← resolve feature dir + copy tasks template (dùng bởi /speckit-tasks)
            └── create-new-module.sh ← scaffold module mới: Sources/<Name>, Tests/<Name>Tests + snippet Package.swift
```

## Triển khai vào dự án bất kỳ (3 bước)

1. Copy `.specify/` vào root của dự án đích:

   ```sh
   cp -R /path/to/speckit-multi-module/.specify /path/to/target-project/
   ```

2. Copy `ARCHITECTURE.md` vào root (hoặc `docs/`) của dự án đích — `/speckit-plan` sẽ
   đọc nó cùng constitution khi thiết kế:

   ```sh
   cp /path/to/speckit-multi-module/ARCHITECTURE.md /path/to/target-project/
   ```

3. Mở `.specify/memory/constitution.md`, thay `[PROJECT_NAME]` bằng tên dự án, hiệu chỉnh
   phầnTechnical Context nếu khác mặc định (platform, version TCA…).

Yêu cầu duy nhất: dự án đích là **git repo** (các script dùng `git rev-parse` để tìm root;
nếu không có git, script vẫn fallback theo vị trí của chính nó).

## Flow sử dụng

| Lệnh | Việc gì | Tạo ra |
|---|---|---|
| `/speckit-specify <mô tả>` | viết spec từ mô tả tiếng tự nhiên (WHAT/WHY, không phải HOW) | `specs/NNN-<short-name>/spec.md` |
| `/speckit-clarify` | hỏi đáp tối đa 3 câu để xử lý điểm chưa chắc | cập nhật `spec.md` |
| `/speckit-plan` | kế hoạch kỹ thuật, **phân rã module**, check 8 gate của constitution | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` |
| `/speckit-tasks` | danh sách task theo user story, đánh `[P]` chỗ chạy song song | `tasks.md` |
| `/speckit-implement` | hiện thực code theo `tasks.md` | code + test |
| `/speckit-analyze`, `/speckit-checklist` | rà soát nhất quán spec/plan/tasks, checklist tùy chọn | báo cáo |

Scripts `setup-plan.sh` / `setup-tasks.sh` được các lệnh trên **tự gọi** — bạn không cần
chạy tay. Script duy nhất bạn chủ động dùng là:

```sh
bash .specify/scripts/bash/create-new-module.sh HomeFeature
# → tạo Sources/HomeFeature/ + Tests/HomeFeatureTests/ (có file skeleton)
#   và in snippet .target/.product/.testTarget để dán vào Package.swift
```

## Kiến trúc được đóng gói trong kit (tóm tắt)

Kit mã hóa các quy ước isowords đang dùng thật:

| Quy ước ở isowords | Thể hiện trong kit |
|---|---|
| 90+ module trong một `Package.swift`, `Sources/` phẳng, phân nhóm bằng `// MARK: - shared/client/server` | Constitution I, VIII + ARCHITECTURE.md §1, §5 |
| Dependency chặt: App → AppFeature → *Feature/*Core → Styleguide/TcaHelpers/*Client → third-party, không cycle | Constitution II + gate trong plan-template |
| Client tách interface/live (`ApiClient` ↔ `ApiClientLive`, live chỉ được link vào app) | Constitution III + ARCHITECTURE.md §4 |
| Một feature = một module `*Feature`, reducer trừ hậu tố (`Home` trong `HomeFeature`) | Constitution IV + ARCHITECTURE.md §3, §4 |
| `Tests/<Module>Tests` mirror từng module, `__Snapshots__` exclude, mock tập trung | Constitution V + ARCHITECTURE.md §6 |
| Feature chạy/test/preview độc lập, không cần build cả app (preview app targets) | Constitution VI + ARCHITECTURE.md §7 |
| Biên module = biên API: mọi thứ expose cho consumer là `public`, nội bộ `private` | Constitution VII |

## Tùy chỉnh cho dự án khác

Kit mặc định cho **Swift 5.9+ / SwiftPM / TCA 1.x / iOS**. Nếu dự án đích khác stack,
giữ nguyên khung flow nhưng:

- sửa bảng **Technical Context** trong `plan-template.md`;
- đổi tên/nội dung nguyên tắc trong `constitution.md` cho đúng stack (ý nghĩa các layer và
  quy tắc dependency vẫn giữ nguyên);
- sửa skeleton code trong `create-new-module.sh` cho đúng ngôn ngữ.

Bản mẫu spec/plan/tasks vẫn giữ được vì chúng bất biến công nghệ trừ phần được đánh dấu.
