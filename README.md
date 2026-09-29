# Spec Workshop — Quang Dương

Repo này chỉ chứa spec cho các dự án nội bộ của Quang Dương, viết theo phương pháp Spec-Driven Development.

- `CLAUDE.md` — hướng dẫn để Claude Code vào vai SDD Architect.
- `specs/<project-slug>/` — mỗi dự án một thư mục.

## Cách dùng

Mở Claude Code trên repo này (web, điện thoại hoặc desktop) và gõ một trong các câu:

- `Ý tưởng: [mô tả]` — dự án mới, Claude sẽ hỏi tier trước
- `Ý tưởng (tier A/B/C): [mô tả]` — dự án mới, bỏ qua câu hỏi tier
- `Thay đổi: [mô tả]` — Delta Spec cho spec đã có
- `Codebase có sẵn: [paste]` — Brownfield

Spec hoàn chỉnh được commit vào `specs/`. Khi bắt đầu build, copy thư mục spec đó sang project đích.
