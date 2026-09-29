# Social Growth Hub — 05 Phases

Đọc kèm: từng phase ghi rõ file spec cần đọc. Không nạp toàn bộ spec vào context một lúc.

---

## [9] Step-by-Step Implementation Prompt

### Quy tắc áp dụng cho MỌI phase

- Đọc `spec/00-overview.md` mục [0] và [2] một lần ở đầu Phase 1; các phase sau chỉ đọc file được chỉ định.
- Mỗi sub-phase ≤ 8 file. Làm xong sub-phase → chạy **Verify** → **Commit** → sang sub-phase kế.
- Lệnh verify tối thiểu mỗi sub-phase: `pnpm typecheck` → `0 errors`; `pnpm lint` → `0 errors`; `pnpm test` → all pass (tính cả test cũ).
- **STOP rule:** Không sang phase kế nếu Verify fail. Nếu fail 3 lần, dừng và báo cáo lỗi kèm log thay vì tự sửa spec.
- Mọi chuỗi UI mới → thêm key vào `src/i18n/vi.json` cùng sub-phase.
- Commit message: Conventional Commits, tiếng Anh, scope = module.

---

## Phase 1 — Setup

**Đọc:** `00-overview.md` mục [1], [2], [7], [10].

### 1.1 Khởi tạo project

**Mục tiêu:** Project Next.js chạy được, đủ cấu hình build / lint / test / worker.
**Files:** `package.json`, `.env.example`, `.prettierrc`, `next.config.ts`, `tsconfig.worker.json`, `vitest.config.ts`, `playwright.config.ts`, `CLAUDE.md`.
**Steps:**
1. Chạy init command và shadcn add theo mục [1].
2. Với mỗi package trong bảng stack: `pnpm view <pkg> version`, ghi version chính xác vào `package.json`, rồi `pnpm install`.
3. Ghi scripts đúng như mục [1]; thêm script `"vercel-build": "prisma migrate deploy && prisma generate && next build"`.
4. Tạo `.env.example` nguyên văn mục [1]; copy thành `.env` với giá trị local (Postgres + Redis local qua Docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:16` và `docker run -d -p 6379:6379 redis:7`).
5. Tạo `tsconfig.worker.json`, `vitest.config.ts` (environment jsdom, alias `@`, `globalSetup` trỏ `src/__tests__/setup.ts` sẽ tạo ở 1.2), `playwright.config.ts`, `.prettierrc`, `next.config.ts` (remotePatterns mục [2]).
6. Ghi `CLAUDE.md` nguyên văn mục [10]. Copy thư mục spec vào `spec/`.
**Verify:**
```bash
pnpm install && pnpm typecheck && pnpm lint && pnpm build
```
Expected: `0 errors`, build thành công.
**Commit:** `chore(setup): scaffold next.js app with tooling`

### 1.2 Thư viện lõi

**Mục tiêu:** Các util nền dùng ở mọi nơi.
**Files:** `src/lib/prisma.ts`, `src/lib/logger.ts`, `src/lib/crypto.ts`, `src/lib/slug.ts`, `src/lib/time.ts`, `src/lib/i18n.ts`, `src/i18n/vi.json`, `src/__tests__/setup.ts`.
**Steps:**
1. Implement theo signature `03-ui.md` mục 6.4.
2. `vi.json` khởi tạo với nhóm `nav.*`, `common.*` (Lưu, Hủy, Xóa, Thử lại, Đang tải…), `validation.*` (mục 6.9), `error.*` (message bảng lỗi chung `02-api.md` 4.1).
3. `setup.ts`: import jest-dom; export `createTestOrg()` (tạo Organization + 1 User OWNER với email `test-<nanoid>@test.local`, trả `{ orgId, membershipId, userId }`) và `cleanupTestOrg(orgId)`; `globalSetup` chạy `prisma migrate deploy` trên `DATABASE_URL` test (Phase 2 mới có schema; ở phase này export hàm rỗng).
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(core): add prisma client, logger, crypto, slug, time, i18n`

### 1.3 Test util + README

**Files:** `src/__tests__/crypto.test.ts`, `src/__tests__/slug.test.ts`, `src/__tests__/time.test.ts`, `README.md`.
**Steps:** Viết test T-UTIL-01…05 (`04-tests.md` 8.1). README: cách chạy local (Docker Postgres/Redis, `.env`, `pnpm db:migrate`, `pnpm db:seed`, `pnpm dev`, `pnpm worker:dev`), bảng biến env, deploy.
**Verify:** `pnpm test` → 5 test pass.
**Commit:** `test(core): cover crypto, slug and time utils`

---

## Phase 2 — Data & Types

**Đọc:** `01-data.md`, `02-api.md` mục 4.1–4.3.

### 2.1 Schema, types, settings, seed

**Files:** `prisma/schema.prisma`, `src/types/index.ts`, `prisma/seed.ts`, `src/lib/validations/common.ts`, `src/lib/settings/settings-provider.ts`, `src/lib/settings/db-settings-provider.ts`, `src/__tests__/settings-provider.test.ts`.
**Steps:**
1. Copy schema nguyên văn mục 3.2; `pnpm db:migrate --name init`.
2. Copy `src/types/index.ts` nguyên văn mục 3.3.
3. `common.ts`: `paginationSchema`, `cuidSchema` (`z.string().regex(/^c[a-z0-9]{24}$/)`), `dateRangeSchema`, Zod `errorMap` toàn cục (mục 6.9).
4. Settings provider theo 3.5; seed theo 3.6, idempotent.
5. Cập nhật `globalSetup` trong `setup.ts` để chạy `prisma migrate deploy`.
**Verify:**
```bash
pnpm db:migrate && pnpm db:seed && pnpm db:seed && pnpm typecheck && pnpm test
```
Expected: seed chạy 2 lần không lỗi; `settings-provider.test.ts` (T-SET-01, 02) pass.
**Commit:** `feat(data): add prisma schema, shared types, settings provider and seed`

### 2.2 Auth, org, API wrapper

**Files:** `src/auth.ts`, `src/middleware.ts`, `src/lib/auth-helpers.ts`, `src/lib/api.ts`, `src/lib/validations/auth.ts`, `src/app/api/auth/[...nextauth]/route.ts`, `src/app/api/auth/register/route.ts`, `src/app/api/org/route.ts`.
**Steps:** Theo `00-overview.md` [7] Auth flow và `02-api.md` 4.2–4.3, `03-ui.md` 6.4 (`apiHandler`). Rate limit in-memory cho register.
**Verify:**
```bash
pnpm dev & sleep 8
curl -s -X POST localhost:3000/api/auth/register -H 'content-type: application/json' -d '{"name":"Test User","email":"t1@test.local","password":"Password123!"}' -w '\n%{http_code}\n'
curl -s localhost:3000/api/org -w '\n%{http_code}\n'
```
Expected: `201` với `{ id, email }`; `401` với body `{"error":{"code":"UNAUTHORIZED",...}}`. `pnpm typecheck && pnpm lint` → 0 errors.
**Commit:** `feat(auth): add auth.js config, middleware, org onboarding and api handler`

### 2.3 Stores + validations (phần 1)

**Files:** `src/stores/ui-store.ts`, `src/stores/post-editor-store.ts`, `src/stores/inbox-store.ts`, `src/lib/validations/post.ts`, `src/lib/validations/social-account.ts`, `src/lib/validations/media.ts`, `src/lib/validations/trend.ts`, `src/lib/validations/inbox.ts`.
**Steps:** Store copy nguyên văn 3.4. Schema theo `02-api.md` từng route.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(state): add zustand stores and request schemas for posts, channels, inbox`

### 2.4 Validations (phần 2)

**Files:** `src/lib/validations/fan.ts`, `src/lib/validations/link.ts`, `src/lib/validations/seeding.ts`, `src/lib/validations/rule.ts` (gồm `validateRuleCompatibility()`), `src/lib/validations/settings.ts`, `src/__tests__/validations.test.ts`.
**Verify:** `pnpm test` → T-VAL-01…04 pass.
**Commit:** `feat(validation): add schemas for fans, links, seeding, rules, settings`

---

## Phase 3 — API, adapters, AI, worker

**Đọc:** `02-api.md`, `03-ui.md` mục 6.5–6.8, `04-tests.md` mục tương ứng.

### 3.1 Platform core + Meta adapters

**Files:** `src/lib/platforms/types.ts`, `src/lib/platforms/registry.ts`, `src/lib/platforms/oauth.ts`, `src/lib/platforms/facebook.ts`, `src/lib/platforms/instagram.ts`, `src/__tests__/adapters/facebook.test.ts`, `src/__tests__/adapters/instagram.test.ts`.
**Steps:**
1. `platforms/types.ts`: re-export type từ `@/types` + `platformFetch(platform, url, init)` bọc `fetch` với `AbortSignal.timeout(30000)` và map lỗi → `PlatformError`.
2. `registry.ts`: map 5 adapter; TikTok/YouTube/Zalo tạm là stub throw `Error("NOT_IMPLEMENTED")` cho tới 3.2; khi `NODE_ENV=test && PLATFORM_MOCK=true` trả `MockAdapter` (import động, file tạo ở Phase 6 — ở phase này để nhánh `if` với comment `TODO(phase-6)`).
3. Implement Facebook / Instagram theo bảng 6.6; oauth cho 2 nền tảng này.
4. Test T-CH-01, 02, 05, 06, 08 với `vi.stubGlobal("fetch", ...)`.
**Verify:** `pnpm test` → adapter tests pass; `pnpm typecheck`.
**Commit:** `feat(platforms): add adapter contract, registry, oauth, facebook and instagram adapters`

### 3.2 TikTok, YouTube, Zalo, storage, telegram

**Files:** `src/lib/platforms/tiktok.ts`, `src/lib/platforms/youtube.ts`, `src/lib/platforms/zalo.ts`, `src/__tests__/adapters/tiktok.test.ts`, `src/__tests__/adapters/youtube.test.ts`, `src/__tests__/adapters/zalo.test.ts`, `src/lib/storage.ts`, `src/lib/services/telegram.ts`.
**Steps:** Theo 6.6, 6.7 (`sendTelegram`), 6.4 (`storage`). Hoàn thiện `oauth.ts` cho 3 nền tảng còn lại (sửa file đã có). Test T-CH-03, 04, 07.
**Verify:** `pnpm test && pnpm typecheck`
**Commit:** `feat(platforms): add tiktok, youtube, zalo adapters, blob storage and telegram notifier`

### 3.3 Queue + channel API + insights

**Files:** `src/lib/queue/queues.ts`, `src/lib/queue/jobs.ts`, `src/lib/services/insights-service.ts`, `src/app/api/social-accounts/route.ts`, `src/app/api/social-accounts/[id]/route.ts`, `src/app/api/social-accounts/[id]/sync/route.ts`, `src/app/api/social-accounts/connect/[platform]/route.ts`, `src/app/api/social-accounts/callback/[platform]/route.ts`.
**Verify:**
```bash
pnpm typecheck && pnpm lint
curl -s -o /dev/null -w '%{http_code}\n' localhost:3000/api/social-accounts/connect/tiktok
```
Expected: `401` (chưa đăng nhập). Đăng nhập bằng trình duyệt, mở `/api/social-accounts/connect/facebook_page` → redirect tới `facebook.com/…/dialog/oauth`.
**Commit:** `feat(channels): add bullmq queues, channel connect/callback routes and insights sync`

### 3.4 AI layer

**Files:** `src/lib/ai/client.ts`, `src/lib/ai/prompts.ts`, `src/lib/ai/schemas.ts`, `src/lib/ai/generate-post.ts`, `src/lib/ai/classify-interaction.ts`, `src/lib/ai/draft-reply.ts`, `src/lib/ai/score-trend.ts`, `src/lib/ai/seeding-variants.ts`.
**Steps:** Theo 6.5. Prompt copy nguyên văn. Không truyền `thinking`, không `temperature`. Viết test T-AI-01…04 vào `src/__tests__/ai-client.test.ts` (file thêm vào cây thư mục tại đây; mock `anthropic.beta.messages.create`).
**Verify:** `pnpm test && pnpm typecheck`
**Commit:** `feat(ai): add anthropic client wrapper, prompts and structured generators`

### 3.5 Posts & media API

**Files:** `src/lib/services/post-service.ts`, `src/lib/services/publish-service.ts`, `src/app/api/posts/route.ts`, `src/app/api/posts/generate/route.ts`, `src/app/api/posts/[id]/route.ts`, `src/app/api/posts/[id]/schedule/route.ts`, `src/app/api/posts/[id]/publish/route.ts`, `src/app/api/media/route.ts`.
**Steps:** Theo 4.5, 4.6, 6.7. Test T-POST-01…06 vào `src/__tests__/publish-service.test.ts`.
**Verify:** `pnpm test && pnpm typecheck`
**Commit:** `feat(posts): add post crud, schedule/publish flow and media upload`

### 3.6 Inbox API

**Files:** `src/lib/services/interaction-service.ts`, `src/lib/services/reply-service.ts`, `src/lib/services/fan-service.ts`, `src/app/api/inbox/route.ts`, `src/app/api/inbox/[id]/route.ts`, `src/app/api/inbox/[id]/reply/route.ts`, `src/app/api/inbox/[id]/draft/route.ts`, `src/app/api/media/[id]/route.ts`.
**Steps:** Theo 4.8, 6.7. Test T-INB-01…07, 09 vào `src/__tests__/reply-policy.test.ts`; T-FAN-01…04 vào `src/__tests__/fan-score.test.ts`.
**Verify:** `pnpm test && pnpm typecheck`
**Commit:** `feat(inbox): add interaction ingestion, auto-reply policy and reply routes`

### 3.7 Fans, links, hub, redirect

**Files:** `src/app/api/fans/route.ts`, `src/app/api/fans/[id]/route.ts`, `src/app/api/fans/[id]/message/route.ts`, `src/lib/services/link-service.ts`, `src/app/api/links/route.ts`, `src/app/api/links/[id]/route.ts`, `src/app/api/link-hub/route.ts`, `src/app/(public)/l/[slug]/route.ts`.
**Steps:** Test T-LNK-01…06 vào `src/__tests__/link-service.test.ts`.
**Verify:**
```bash
pnpm test && pnpm typecheck
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' localhost:3000/l/fanpage
```
Expected: `302 https://example.com/fanpage` (seed).
**Commit:** `feat(links): add fans api, short links, link hub and click tracking`

### 3.8 Trends & seeding (phần 1)

**Files:** `src/lib/services/trend-service.ts`, `src/app/api/trends/route.ts`, `src/app/api/trends/refresh/route.ts`, `src/app/api/trends/[id]/route.ts`, `src/app/api/trends/[id]/ideas/route.ts`, `src/lib/services/seeding-service.ts`, `src/app/api/seeding/campaigns/route.ts`, `src/app/api/seeding/campaigns/[id]/route.ts`.
**Steps:** Test T-TR-01…04 (`trend-service.test.ts`), T-SD-01…03, 05 (`seeding-service.test.ts`).
**Verify:** `pnpm test && pnpm typecheck`
**Commit:** `feat(trends): add trend collectors, scoring and seeding campaigns`

### 3.9 Seeding (phần 2), rules, analytics service

**Files:** `src/app/api/seeding/campaigns/[id]/targets/route.ts`, `src/app/api/seeding/campaigns/[id]/generate/route.ts`, `src/app/api/seeding/tasks/route.ts`, `src/app/api/seeding/tasks/[id]/route.ts`, `src/lib/services/rule-engine.ts`, `src/app/api/rules/route.ts`, `src/app/api/rules/[id]/route.ts`, `src/lib/services/analytics-service.ts`.
**Steps:** Test T-RULE-01…05 (`rule-engine.test.ts`), T-AN-01…04 (`analytics-service.test.ts`).
**Verify:** `pnpm test && pnpm typecheck`
**Commit:** `feat(automation): add seeding tasks, rule engine and analytics queries`

### 3.10 Analytics API, settings, team

**Files:** `src/app/api/analytics/overview/route.ts`, `src/app/api/analytics/channels/route.ts`, `src/app/api/analytics/posts/route.ts`, `src/app/api/analytics/funnel/route.ts`, `src/app/api/settings/route.ts`, `src/lib/services/team-service.ts`, `src/app/api/team/route.ts`, `src/app/api/team/[membershipId]/route.ts`.
**Verify:** `pnpm typecheck && pnpm lint && pnpm test`
**Commit:** `feat(api): add analytics, settings and team routes`

### 3.11 Templates, knowledge, products, webhooks

**Files:** `src/app/api/templates/route.ts`, `src/app/api/templates/[id]/route.ts`, `src/app/api/knowledge/route.ts`, `src/app/api/knowledge/[id]/route.ts`, `src/app/api/products/route.ts`, `src/app/api/products/[id]/route.ts`, `src/app/api/webhooks/facebook/route.ts`, `src/app/api/webhooks/zalo/route.ts`.
**Steps:** Test T-WH-01…04 vào `src/__tests__/webhooks.test.ts` (thêm vào cây thư mục tại đây).
**Verify:**
```bash
pnpm test && pnpm typecheck
curl -s "localhost:3000/api/webhooks/facebook?hub.mode=subscribe&hub.verify_token=change-me&hub.challenge=123"
```
Expected: `123`.
**Commit:** `feat(api): add templates, knowledge, products and platform webhooks`

### 3.12 Worker (phần 1)

**Files:** `src/worker/index.ts`, `src/worker/processors/publish-post.ts`, `src/worker/processors/sync-interactions.ts`, `src/worker/processors/sync-insights.ts`, `src/worker/processors/refresh-trends.ts`, `src/worker/processors/classify-and-reply.ts`, `src/worker/processors/run-rules.ts`.
**Steps:** Theo 6.8. `index.ts` đăng ký Worker mỗi queue với `concurrency = WORKER_CONCURRENCY` (queue `ai`: 2), cron repeatable khi `WORKER_ENABLE_CRON=true`, graceful shutdown SIGTERM. Test T-INB-08 vào `reply-policy.test.ts`.
**Verify:**
```bash
pnpm typecheck && pnpm test
pnpm worker & sleep 5; kill %1
```
Expected: log JSON `{"msg":"worker started","queues":["publish","sync","ai","rules","trends","maintenance"]}` rồi `"worker stopped"`.
**Commit:** `feat(worker): add bullmq worker with publish, sync, trend, classify and rule processors`

### 3.13 Worker (phần 2) + test còn lại

**Files:** `src/worker/processors/recalc-fans.ts`, `src/worker/processors/seeding-generate.ts`, `src/worker/processors/token-check.ts`, `src/__tests__/seeding-service.test.ts` (bổ sung T-SD-04), `src/__tests__/trend-service.test.ts` (bổ sung nếu thiếu), `src/__tests__/publish-service.test.ts` (bổ sung nếu thiếu).
**Verify:** `pnpm test && pnpm typecheck && pnpm lint` — toàn bộ test unit trong `04-tests.md` (trừ e2e) pass.
**Commit:** `feat(worker): add fan recalc, seeding generation and token check jobs`

---

## Phase 4 — UI components

**Đọc:** `03-ui.md` mục [5] 5.3–5.4 và [6] 6.1–6.3.

### 4.1 Layout + shell

**Files:** `src/app/layout.tsx`, `src/app/providers.tsx`, `src/app/(app)/layout.tsx`, `src/app/(auth)/layout.tsx`, `src/components/layout/app-sidebar.tsx`, `src/components/layout/app-header.tsx`, `src/components/layout/page-header.tsx`, `src/components/shared/data-table.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`; mở `/dashboard` (tạm hiển thị "Tổng quan" trống) thấy sidebar 12 mục.
**Commit:** `feat(ui): add app shell, sidebar, header and data table`

### 4.2 Shared components + useOrg

**Files:** `src/components/shared/empty-state.tsx`, `error-state.tsx`, `loading-state.tsx`, `platform-badge.tsx`, `confirm-dialog.tsx`, `stat-card.tsx`, `date-range-picker.tsx`, `src/hooks/use-org.ts`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add shared state components and org hook`

### 4.3 Hooks (phần 1)

**Files:** `src/hooks/use-channels.ts`, `use-posts.ts`, `use-trends.ts`, `use-inbox.ts`, `use-fans.ts`, `use-links.ts`, `use-seeding.ts`, `use-rules.ts`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(hooks): add tanstack query hooks for core resources`

### 4.4 Hooks (phần 2) + channels, trends, content list

**Files:** `src/hooks/use-analytics.ts`, `src/hooks/use-settings.ts`, `src/components/channels/channel-card.tsx`, `src/components/channels/connect-channel-dialog.tsx`, `src/components/trends/trend-card.tsx`, `src/components/trends/trend-filters.tsx`, `src/components/content/post-status-badge.tsx`, `src/components/content/post-table.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add channel, trend and post list components`

### 4.5 Editor + calendar + inbox filters

**Files:** `src/components/content/post-editor.tsx`, `variant-editor.tsx`, `media-uploader.tsx`, `ai-generate-dialog.tsx`, `schedule-dialog.tsx`, `src/components/calendar/calendar-grid.tsx`, `src/components/inbox/inbox-filters.tsx`, `src/components/inbox/intent-badge.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add post editor, media uploader, ai dialog, calendar and inbox filters`

### 4.6 Inbox, fans, seeding (phần 1)

**Files:** `src/components/inbox/interaction-list.tsx`, `interaction-detail.tsx`, `reply-composer.tsx`, `src/components/fans/fan-table.tsx`, `fan-profile.tsx`, `fan-tag-input.tsx`, `src/components/seeding/campaign-form.tsx`, `campaign-table.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add inbox detail, reply composer, fan and campaign components`

### 4.7 Seeding (phần 2), links, automations

**Files:** `src/components/seeding/target-form.tsx`, `seeding-task-card.tsx`, `src/components/links/link-form.tsx`, `link-table.tsx`, `link-hub-editor.tsx`, `src/components/automations/rule-form.tsx`, `rule-card.tsx`, `src/components/analytics/overview-cards.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add seeding task, link, hub and rule components`

### 4.8 Analytics + settings (phần 1)

**Files:** `src/components/analytics/channel-compare-table.tsx`, `top-posts-table.tsx`, `growth-chart.tsx`, `funnel-bars.tsx`, `src/components/settings/org-settings-form.tsx`, `ai-settings-form.tsx`, `telegram-settings-form.tsx`, `team-table.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add analytics visuals and settings forms`

### 4.9 Settings (phần 2)

**Files:** `src/components/settings/template-table.tsx`, `knowledge-table.tsx`, `product-table.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`
**Commit:** `feat(ui): add template, knowledge and product tables`

---

## Phase 5 — Pages & State

**Đọc:** `03-ui.md` mục [5] 5.1–5.4.

### 5.1 Auth pages + dashboard + kênh + trend + content

**Files:** `src/app/(auth)/login/page.tsx`, `register/page.tsx`, `onboarding/page.tsx`, `src/app/(app)/dashboard/page.tsx`, `channels/page.tsx`, `trends/page.tsx`, `content/page.tsx`, `content/new/page.tsx`.
**Steps:** Mỗi page đủ 4 state theo 5.3. Dashboard gọi `GET /api/analytics/overview` + các query phụ qua `useAnalytics` và `dashboard()` (bổ sung route `GET /api/analytics/overview?dashboard=1` trả `DashboardData` — sửa file `analytics/overview/route.ts`).
**Verify:** `pnpm typecheck && pnpm lint`; đăng nhập `owner@demo.local`, duyệt 5 trang không lỗi console.
**Commit:** `feat(pages): add auth, dashboard, channels, trends and content pages`

### 5.2 Post detail, calendar, inbox, fans, seeding, links

**Files:** `src/app/(app)/content/[postId]/page.tsx`, `calendar/page.tsx`, `inbox/page.tsx`, `fans/page.tsx`, `fans/[fanId]/page.tsx`, `seeding/page.tsx`, `seeding/[campaignId]/page.tsx`, `links/page.tsx`.
**Verify:** `pnpm typecheck && pnpm lint`; duyệt 8 trang với seed data, mỗi trang hiện dữ liệu seed.
**Commit:** `feat(pages): add post detail, calendar, inbox, fans, seeding and links pages`

### 5.3 Automations, analytics, settings, public hub

**Files:** `src/app/(app)/automations/page.tsx`, `analytics/page.tsx`, `settings/page.tsx`, `src/app/(public)/hub/[slug]/page.tsx`.
**Verify:**
```bash
pnpm typecheck && pnpm lint
curl -s -o /dev/null -w '%{http_code}\n' localhost:3000/hub/demo-shop
curl -s -o /dev/null -w '%{http_code}\n' localhost:3000/hub/khong-ton-tai
```
Expected: `200`, `404`.
**Commit:** `feat(pages): add automations, analytics, settings and public link hub`

---

## Phase 6 — Integration & Tests

**Đọc:** `04-tests.md` (e2e), `03-ui.md` 5.2 flows.

### 6.1 Mock adapter + e2e

**Files:** `src/lib/platforms/mock.ts`, `e2e/auth.spec.ts`, `e2e/post-flow.spec.ts`, `e2e/inbox-flow.spec.ts`, `README.md` (bổ sung mục chạy e2e).
**Steps:**
1. `MockAdapter` implement đủ `PlatformAdapter`, mọi hàm trả kết quả giả (`externalPostId = "mock-" + nanoid(8)`). Hoàn thiện nhánh `PLATFORM_MOCK` trong `registry.ts`.
2. `playwright.config.ts` `webServer.env`: `NODE_ENV=test`, `PLATFORM_MOCK=true`, `DATABASE_URL` test; `globalSetup` chạy `pnpm db:seed`.
3. Viết T-AUTH-01, 02, T-POST-07, 08, T-INB-10.
**Verify:**
```bash
pnpm test && pnpm test:e2e
```
Expected: unit all pass; e2e 5 pass.
**Commit:** `test(e2e): add playwright flows for auth, post scheduling and inbox reply`

### 6.2 Kiểm tra chéo spec

**Files:** không tạo file mới; sửa file có lỗi phát hiện.
**Steps:**
1. Chạy script kiểm tra chuỗi tiếng Việt hardcode trong component / page:
```bash
grep -rnP "[ĂÂĐÊÔƠƯăâđêôơư]|[\x{1EA0}-\x{1EF9}]" src/components src/app --include=*.tsx | grep -v "i18n" | grep -v "// i18n-ignore" || echo "OK"
```
Expected: `OK` (mọi chuỗi qua `t()`).
2. Chạy `grep -rn "graph.facebook.com\|open.tiktokapis.com\|googleapis.com\|openapi.zalo.me" src --include=*.ts -l` → chỉ file trong `src/lib/platforms/` và `src/lib/services/trend-service.ts`.
3. Chạy `grep -rn "new Anthropic(" src -l` → chỉ `src/lib/ai/client.ts`.
4. Với mỗi route trong `02-api.md` 4.16: xác nhận file route tồn tại (`ls`).
**Verify:** 4 bước trên đúng expected; `pnpm typecheck && pnpm lint && pnpm test`.
**Commit:** `chore: enforce i18n, adapter and ai client boundaries`

---

## Phase 7 — Polish & Docs

**Đọc:** `00-overview.md` [7] (accessibility, performance, deploy).

### 7.1 Accessibility, performance, docs

**Files:** `README.md`, `CLAUDE.md`, `next.config.ts`, `src/app/(app)/layout.tsx`, `src/components/layout/app-sidebar.tsx`, `src/i18n/vi.json`.
**Steps:**
1. Rà mọi nút icon có `aria-label`; form có `Label htmlFor`; dialog đóng bằng Esc.
2. `next.config.ts` thêm `headers()` với `X-Frame-Options: DENY` (trừ `/hub/*`), `Referrer-Policy: strict-origin-when-cross-origin`.
3. Lazy import `growth-chart.tsx`, `link-hub-editor.tsx`, `rule-form.tsx` bằng `next/dynamic`.
4. README: mục Deploy (Vercel + Railway + Neon + Upstash), đăng ký webhook Meta / Zalo, xin quyền TikTok Content Posting API, checklist biến env production.
5. Cập nhật `CLAUDE.md` nếu có lệnh mới.
**Verify:**
```bash
pnpm build && pnpm typecheck && pnpm lint && pnpm test && pnpm test:e2e
pnpm dlx @lhci/cli autorun --collect.url=http://localhost:3000/login --collect.numberOfRuns=1 --assert.assertions.categories:accessibility=0.9
```
Expected: build OK, mọi test pass, Lighthouse accessibility ≥ 0.9.
**Commit:** `chore(polish): harden headers, lazy load heavy components, finalize docs`

---

## Tổng kết phase

| Phase | Sub-phase | Số file | Kết quả |
|---|---|---|---|
| 1 Setup | 1.1–1.3 | 20 | Project chạy, util lõi, test util |
| 2 Data & Types | 2.1–2.4 | 29 | Schema, types, auth, stores, validations |
| 3 API & worker | 3.1–3.13 | 101 | Toàn bộ API, adapter, AI, worker, unit test |
| 4 UI components | 4.1–4.9 | 59 | Mọi component + hooks |
| 5 Pages | 5.1–5.3 | 20 | Mọi trang, 4 state |
| 6 Integration | 6.1–6.2 | 5 | Mock adapter, e2e, kiểm tra ranh giới |
| 7 Polish | 7.1 | 6 | A11y, headers, docs |
