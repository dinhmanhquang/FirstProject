# ShopPulse — Master Spec · 05 Phases

Đọc kèm: từng phase ghi rõ file spec cần đọc. Không nạp toàn bộ spec vào context. File này là phần [9] Step-by-Step Implementation Prompt.

---

## [9] Lộ trình thực hiện

**STOP rule (áp dụng cho mọi phase):** Không sang phase kế nếu Verify fail. Nếu fail 3 lần, dừng và báo cáo lỗi kèm log thay vì tự sửa spec.

**Quy tắc chung:**

- Mỗi phase ≤ 8 file viết tay (file sinh tự động không tính).
- Trước mỗi commit: `pnpm typecheck && pnpm lint && pnpm test` phải pass.
- Commit message theo Conventional Commits, tiếng Anh.
- Tier B: 7 phase, phase 3–5 chia thành sub-phase a/b/c.

---

### Phase 1 — Setup

**Đọc:** `00-overview.md` mục [1], [2], [7], [10].

**Mục tiêu:** Khởi tạo project chạy được `pnpm dev`, có Postgres local, lint / test / typecheck pass với 0 file logic.

**Files (viết tay):** `package.json` (scripts + version), `.env.example`, `.prettierrc`, `docker-compose.yml`, `vitest.config.ts`, `playwright.config.ts`, `vercel.json`, `CLAUDE.md`.

**Steps:**

1. Chạy `pnpm view <pkg> version` cho mọi package ở §1.2; ghi khác biệt vào `CLAUDE.md` mục "Version drift".
2. Chạy init command §1.3 (create-next-app, shadcn init, shadcn add).
3. Cài dependencies §1.4 với version đã xác nhận: `pnpm add <deps>` và `pnpm add -D <devDeps>`.
4. Ghi scripts §1.5 vào `package.json`.
5. Tạo `.env.example` §1.6; copy thành `.env`, sinh `AUTH_SECRET` và `CRON_SECRET` bằng openssl.
6. Tạo `docker-compose.yml` (postgres:16, `POSTGRES_DB=shop_pulse`, port 5432) và chạy `docker compose up -d`.
7. Tạo `vitest.config.ts`, `playwright.config.ts`, `vercel.json`, `.prettierrc`; sửa `tsconfig.json` thêm `noUncheckedIndexedAccess`; thêm security headers vào `next.config.ts`.
8. Copy thư mục spec vào `spec/`. Tạo `CLAUDE.md` theo §[10]. Thêm `.env` và `/test-results` vào `.gitignore`.
9. Tạo `src/test/smoke.test.ts` với 1 test `expect(1 + 1).toBe(2)` (xoá ở Phase 2).

**Verify:**

```bash
pnpm typecheck        # → 0 errors
pnpm lint             # → ✔ No ESLint warnings or errors
pnpm test             # → 1 passed
docker compose ps     # → postgres  running
pnpm dev &  sleep 8 && curl -s -o /dev/null -w "%{http_code}" http://localhost:3000  # → 200
```

**Commit:** `chore(setup): scaffold next 15 app with tooling and spec`

---

### Phase 2 — Data & Types

**Đọc:** `01-data.md` §3.1, §3.2, §3.3, §3.10, §3.11, §3.13.

**Mục tiêu:** Schema, migration đầu tiên, types, catalog, settings provider và seed chạy được.

**Files:** `prisma/schema.prisma`, `prisma/seed.ts`, `src/types/index.ts`, `src/lib/db.ts`, `src/lib/metrics/catalog.ts`, `src/lib/settings/provider.ts`, `src/lib/settings/defaults.ts`, `src/lib/connectors/types.ts`.

**Steps:**

1. Viết `schema.prisma` đúng §3.1 (kể cả `onDelete: SetNull` cho `Task.rule`).
2. `pnpm db:migrate --name init` → thư mục `prisma/migrations/<ts>_init`.
3. Viết `src/types/index.ts` đúng §3.2; `src/lib/db.ts` singleton PrismaClient (pattern globalThis cho dev).
4. Viết `catalog.ts` đúng §3.3 (18 chỉ số).
5. Viết `provider.ts`, `defaults.ts` (§3.10), `connectors/types.ts` (§3.11).
6. Viết `seed.ts` §3.13. Phần tính health và sinh task trong seed tạm gọi hàm rỗng `TODO` trả `[]` — Phase 3b sẽ thay bằng service thật. Xoá `src/test/smoke.test.ts`.
7. Chạy `pnpm db:seed`.

**Verify:**

```bash
pnpm typecheck                                   # → 0 errors
pnpm lint                                        # → clean
pnpm prisma validate                             # → The schema is valid
pnpm db:seed                                     # → exit 0
pnpm prisma db execute --stdin <<< "SELECT count(*) FROM \"MetricThreshold\";"   # → 18
pnpm prisma db execute --stdin <<< "SELECT count(*) FROM \"TaskRule\";"          # → 40
pnpm prisma db execute --stdin <<< "SELECT count(*) FROM \"Shop\";"              # → 4
```

**Commit:** `feat(data): add prisma schema, types, metric catalog and seed`

---

### Phase 3a — Core logic (thuần, có unit test)

**Đọc:** `01-data.md` §3.4–§3.8; `03-ui.md` §6.9 (date, i18n); `04-tests.md` §8.1–§8.6.

**Mục tiêu:** Toàn bộ thuật toán không phụ thuộc DB, có test.

**Files:** `src/lib/date.ts`, `src/lib/i18n.ts`, `src/i18n/vi.json`, `src/lib/metrics/health.ts`, `src/lib/metrics/csv.ts`, `src/lib/tasks/templates.ts`, `src/lib/tasks/engine.ts`, `src/lib/tasks/routines.ts`.

**Steps:**

1. Viết `vi.json` đủ 19 nhóm cấp 1 (03-ui.md §6.10) với mọi chuỗi trong spec.
2. Viết `date.ts`, `i18n.ts`.
3. Viết `health.ts` (§3.4), `csv.ts` (§3.8), `templates.ts` (§3.7), `engine.ts` (§3.5), `routines.ts` (§3.6).
4. Viết test `src/test/health.test.ts`, `csv.test.ts`, `templates.test.ts` (E7, E8), `engine.test.ts`, `routines.test.ts`, `date.test.ts` đúng bảng ở 04-tests.md.

Chia 2 commit: commit 1 gồm `vi.json`, `date.ts`, `i18n.ts`, `health.ts`, `csv.ts`, `health.test.ts`, `csv.test.ts`, `date.test.ts` (8 file); commit 2 gồm `templates.ts`, `engine.ts`, `routines.ts`, `templates.test.ts`, `engine.test.ts`, `routines.test.ts` (6 file).

**Verify:**

```bash
pnpm typecheck                     # → 0 errors
pnpm test -- --coverage            # → all pass; coverage ≥ 90% statements cho 5 file ở 04-tests.md §8.11
```

**Commit 1:** `feat(core): add i18n, date helpers, health score and csv parser`
**Commit 2:** `feat(core): add task templates, alert engine and routines`

---

### Phase 3b — Auth, API infrastructure, validation

**Đọc:** `00-overview.md` §7.1–§7.4; `02-api.md` §4.0, §4.1; `03-ui.md` §6.10; `04-tests.md` §8.6.

**Mục tiêu:** Đăng nhập được bằng API, có guard, response helper, rate limit, mọi Zod schema.

**Files:** `src/lib/auth.config.ts`, `src/lib/auth.ts`, `src/app/api/auth/[...nextauth]/route.ts`, `src/middleware.ts`, `src/lib/api/errors.ts`, `src/lib/api/response.ts`, `src/lib/api/guard.ts`, `src/lib/rate-limit.ts`.

Thêm 6 file validation `src/lib/validation/{auth,shop,metrics,task,settings,member}.ts` và `src/lib/logger.ts`, `src/test/validation.test.ts` — tổng 17 file, chia làm 2 commit trong cùng phase (commit 1: 8 file auth / api infra; commit 2: 8 file validation + logger + test).

**Steps:**

1. `auth.config.ts`: providers rỗng, `pages.signIn = "/login"`, callbacks `jwt` / `session` gắn `orgId`, `role`, `name`, `email`; `authorized` cho middleware.
2. `auth.ts`: `NextAuth({ ...authConfig, providers: [Credentials({ authorize })] })`; `authorize` validate `loginSchema`, tìm user theo email, `bcrypt.compare`, `isActive`; áp `checkRateLimit("login", ip, 10, 900000)`.
3. `middleware.ts` matcher §7.1.
4. `errors.ts` (class `ApiError(status, code, messageKey, details?)` + bảng mã), `response.ts`, `guard.ts`.
5. Viết 6 schema validation đúng `02-api.md`.
6. `logger.ts`; `withHandler` log 1 dòng / request §7.4.
7. `validation.test.ts` V1–V9.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test    # → pass
pnpm dev & sleep 8
curl -s -X POST http://localhost:3000/api/auth/callback/credentials -H "Content-Type: application/json" -d '{"email":"owner@example.com","password":"ChangeMe123!"}' -c cookies.txt -o /dev/null -w "%{http_code}"   # → 200 hoặc 302
curl -s -b cookies.txt http://localhost:3000/api/auth/session | grep -o '"role":"OWNER"'   # → "role":"OWNER"
```

**Commit 1:** `feat(auth): add credentials auth, middleware and api helpers`
**Commit 2:** `feat(validation): add zod schemas and logger`

---

### Phase 3c — API routes: shops, metrics, dashboard

**Đọc:** `02-api.md` §4.2–§4.5; `01-data.md` §3.4, §3.5, §3.9; `03-ui.md` §6.9 (services).

**Files:** `src/lib/services/shop-service.ts`, `src/lib/services/metric-service.ts`, `src/lib/notifications/service.ts`, `src/app/api/metrics/catalog/route.ts`, `src/app/api/shops/route.ts`, `src/app/api/shops/[shopId]/route.ts`, `src/app/api/shops/[shopId]/metrics/route.ts`, `src/app/api/shops/[shopId]/health/route.ts`.

Thêm `src/app/api/shops/[shopId]/import/route.ts`, `src/app/api/dashboard/summary/route.ts`, `src/lib/services/task-service.ts` (chỉ `insertGeneratedTasks`, `toTaskDto`) — commit 2.

**Steps:**

1. `shop-service.ts`: list (sắp xếp §4.3), create (409), get, update, softDelete (skip task).
2. `metric-service.ts`: `upsertSnapshots` transaction 3 bước §4.4; `recomputeHealth`; `getPreviousValues`.
3. `notifications/service.ts` §3.9.
4. Route handlers dùng `withHandler` + `requireSession` / `requireRole`.
5. `import/route.ts`: multipart, size, type, parse, upsert theo ngày, `ImportJob`, rate limit.
6. `dashboard/summary/route.ts` §4.5.
7. Cập nhật `prisma/seed.ts` gọi service thật thay `TODO`; chạy lại `pnpm db:seed`.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
pnpm db:seed
# với cookies.txt từ Phase 3b:
curl -s -b cookies.txt http://localhost:3000/api/shops | grep -o '"name":"Shop Demo Shopee 1"'       # → khớp
curl -s -b cookies.txt http://localhost:3000/api/dashboard/summary | grep -o '"critical":[0-9]*'      # → "critical":1
SHOP=$(curl -s -b cookies.txt http://localhost:3000/api/shops | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).data.find(x=>x.name==="Shop Demo Shopee 2").id))')
curl -s -b cookies.txt -X POST http://localhost:3000/api/shops/$SHOP/metrics -H "Content-Type: application/json" -d "{\"date\":\"$(date +%F)\",\"values\":{\"shopee_lsr\":12}}" | grep -o '"status":"CRITICAL"'   # → "status":"CRITICAL"
```

**Commit 1:** `feat(api): add shop and metric routes with health recompute`
**Commit 2:** `feat(api): add csv import and dashboard summary`

---

### Phase 3d — API routes: tasks, settings, members, notifications, cron

**Đọc:** `02-api.md` §4.6–§4.11; `01-data.md` §3.6.

**Files:** `src/lib/services/task-service.ts` (hoàn thiện), `src/lib/services/member-service.ts`, `src/app/api/tasks/route.ts`, `src/app/api/tasks/[taskId]/route.ts`, `src/app/api/settings/thresholds/route.ts`, `src/app/api/settings/rules/route.ts`, `src/app/api/settings/rules/[ruleId]/route.ts`, `src/app/api/members/route.ts`.

Commit 2: `src/app/api/members/[userId]/route.ts`, `src/app/api/notifications/route.ts`, `src/app/api/notifications/read-all/route.ts`, `src/app/api/cron/daily/route.ts`.

**Steps:**

1. `task-service.ts`: `listTasks` (filter + sort + phân trang), `createManualTask`, `updateTask` với toàn bộ quy tắc §4.6 (403 STAFF, SKIPPED cần note, khôi phục dedupeKey, 409).
2. Thresholds GET / PUT; rules GET / POST / PATCH / DELETE; members GET / POST / PATCH với quy tắc §4.9.
3. Notifications GET (unreadCount) / read-all.
4. `cron/daily/route.ts`: hỗ trợ GET + POST, `timingSafeEqual`, chạy `generateRoutineTasks` cho mọi org.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
curl -s -b cookies.txt "http://localhost:3000/api/tasks?status=OPEN,IN_PROGRESS" | grep -o '"totalPages":[0-9]*'   # → có số
curl -s -X POST http://localhost:3000/api/cron/daily -H "Authorization: Bearer $CRON_SECRET" # → {"date":"...","orgCount":1,"createdTasks":N}
curl -s -X POST http://localhost:3000/api/cron/daily -H "Authorization: Bearer $CRON_SECRET" | grep -o '"createdTasks":0'   # → "createdTasks":0
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/api/cron/daily   # → 401
```

**Commit 1:** `feat(api): add task and settings routes`
**Commit 2:** `feat(api): add members, notifications and daily cron`

---

### Phase 4a — UI foundation: layout, common, hooks

**Đọc:** `03-ui.md` §5.2, §6.1, §6.2, §6.8; `01-data.md` §3.12.

**Files:** `src/lib/api-client.ts`, `src/stores/ui-store.ts`, `src/stores/task-filter-store.ts`, `src/app/layout.tsx` (Providers), `src/app/(app)/layout.tsx`, `src/components/layout/AppSidebar.tsx`, `src/components/layout/AppHeader.tsx`, `src/components/layout/NotificationBell.tsx`.

Commit 2: `src/components/common/{PageHeader,EmptyState,StatusPanel,ConfirmDialog}.tsx`, `src/hooks/{useDashboard,useShops,useMetrics,useTasks}.ts` (8 file).

Commit 3: `src/hooks/{useSettings,useNotifications}.ts`, `src/app/providers.tsx` (3 file).

**Steps:**

1. `api-client.ts` §6.8; `src/app/providers.tsx` ("use client", `QueryClientProvider` + `Toaster`) được `src/app/layout.tsx` bọc quanh `children`.
2. 2 store Zustand §3.12.
3. `(app)/layout.tsx`: `auth()`, không session → `redirect("/login")`; render header + sidebar + children; đọc `?denied=1` → toast.
4. Common components và 6 hooks.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
pnpm dev & sleep 8
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/          # → 307 (redirect /login khi chưa login)
curl -s -b cookies.txt http://localhost:3000/ | grep -o "ShopPulse"    # → ShopPulse
```

**Commit 1:** `feat(ui): add app shell, stores and api client`
**Commit 2:** `feat(ui): add common components and core query hooks`
**Commit 3:** `feat(ui): add settings and notification hooks with providers`

---

### Phase 4b — Pages: login, dashboard, shops

**Đọc:** `03-ui.md` §5.1, §5.3 (Flow 1, 5), §5.4, §5.5, §6.3, §6.4.

**Files:** `src/app/(auth)/login/page.tsx`, `src/app/(app)/page.tsx`, `src/components/dashboard/{SummaryCards,ShopHealthGrid,TodayTasksPanel,StaleShopsAlert}.tsx`, `src/components/shops/ShopCard.tsx`, `src/components/shops/ShopStatusBadge.tsx`.

Commit 2: `src/app/(app)/shops/page.tsx`, `src/app/(app)/shops/new/page.tsx`, `src/app/(app)/shops/[shopId]/page.tsx`, `src/app/(app)/shops/[shopId]/edit/page.tsx`, `src/components/shops/{ShopForm,HealthGauge,MetricBreakdownTable,MetricTrendChart}.tsx`.

**Steps:**

1. Login page: form `loginSchema`, `signIn("credentials", { redirect: false })`, hiển thị lỗi, redirect `next`.
2. Dashboard đúng wireframe, 4 state.
3. Shops list, new, detail, edit đúng wireframe và §6.4.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
# Mở trình duyệt: đăng nhập owner → thấy "Tổng quan hôm nay", 4 thẻ đếm, ShopCard "Shop Demo Shopee 1" badge "Nguy cấp"
```

Kèm 1 e2e tạm: `e2e/auth.spec.ts` với A1, A2, A3 → `pnpm test:e2e` → 3 passed.

**Commit 1:** `feat(ui): add login and dashboard pages`
**Commit 2:** `feat(ui): add shop list, create, detail and edit pages`

---

### Phase 4c — Pages: metrics entry, import, tasks, notifications

**Đọc:** `03-ui.md` §5.3 (Flow 2, 3), §5.4, §5.5, §6.5, §6.6.

**Files:** `src/app/(app)/shops/[shopId]/metrics/page.tsx`, `src/app/(app)/shops/[shopId]/import/page.tsx`, `src/components/metrics/MetricEntryForm.tsx`, `src/components/metrics/CsvImportForm.tsx`, `public/templates/metrics-template.csv`.

Commit 2: `src/app/(app)/tasks/page.tsx`, `src/app/(app)/tasks/[taskId]/page.tsx`, `src/app/(app)/notifications/page.tsx`, `src/components/tasks/{TaskFilters,TaskList,TaskItem,TaskDetail,TaskForm}.tsx`.

**Steps:**

1. MetricEntryForm với schema động, điền sẵn, panel kết quả, "Nhập shop tiếp theo".
2. CsvImportForm với preview client (import `parseMetricsCsv` — đảm bảo `csv.ts` không import module server).
3. Tasks list (bộ lọc từ store + URL page), detail, form trong Sheet; notifications page.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
# Trình duyệt: Flow 1 và Flow 2 chạy trọn vẹn bằng tài khoản staff@example.com
```

**Commit 1:** `feat(ui): add metric entry and csv import pages`
**Commit 2:** `feat(ui): add task list, task detail and notifications pages`

---

### Phase 5 — Settings pages

**Đọc:** `03-ui.md` §5.3 (Flow 4), §5.4, §6.7; `02-api.md` §4.7–§4.9.

**Files:** `src/app/(app)/settings/layout.tsx`, `src/app/(app)/settings/thresholds/page.tsx`, `src/app/(app)/settings/rules/page.tsx`, `src/app/(app)/settings/members/page.tsx`, `src/components/settings/{ThresholdTable,RuleTable,RuleForm,MemberTable}.tsx`.

`src/components/settings/MemberForm.tsx` là file thứ 9 → tách commit 2 cùng với chỉnh sửa nhỏ nếu có.

**Steps:**

1. Settings layout: kiểm tra role, Tabs 3 mục.
2. Thresholds: bảng inline-edit, dirty tracking, PUT.
3. Rules: bảng + Sheet form, Switch bật / tắt, xoá có confirm.
4. Members: bảng + form tạo / sửa / đặt lại mật khẩu.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
# Trình duyệt (manager@example.com): đổi ngưỡng shopee_lsr critical 10 → 15, lưu, reload thấy 15.
# Trình duyệt (staff@example.com): mở /settings/thresholds → về "/" kèm toast không có quyền.
```

**Commit 1:** `feat(settings): add thresholds, rules and members pages`
**Commit 2:** `feat(settings): add member form`

---

### Phase 6 — Integration & E2E tests

**Đọc:** `04-tests.md` §8.7–§8.10.

**Files:** `e2e/fixtures.ts`, `e2e/auth.spec.ts` (hoàn thiện A1–A5, P1–P4), `e2e/metrics-to-task.spec.ts` (M1–M7, K1–K2).

**Steps:**

1. `fixtures.ts`: helper `loginAs(page, email)` dùng tài khoản seed; helper `apiContext(role)` lấy cookie để gọi `request`.
2. Viết đủ test theo bảng. Trước khi chạy: `pnpm db:seed` (idempotent, reset dữ liệu seed).
3. Sửa bug phát hiện được trong code, không sửa test để né bug.

**Verify:**

```bash
pnpm db:seed
pnpm test:e2e        # → 18 passed (A1–A5, P1–P4, M1–M7, K1–K2)
pnpm test -- --coverage   # → ngưỡng §8.11 đạt
```

**Commit:** `test(e2e): add auth, permission and metrics-to-task flows`

---

### Phase 7 — Polish & Docs

**Đọc:** `00-overview.md` §7.5–§7.8; `03-ui.md` §5.6.

**Files:** `README.md`, `next.config.ts` (headers), `src/app/(app)/layout.tsx` (responsive drawer), `src/components/layout/AppSidebar.tsx` (aria), `CLAUDE.md` (Version drift cuối cùng).

**Steps:**

1. Rà accessibility §7.6: `aria-label` cho mọi nút icon, `role="status"` badge, focus ring.
2. Responsive §5.6 ở 375px, 768px, 1280px.
3. `README.md`: yêu cầu (Node 22, pnpm 10, Docker), các bước chạy local, seed, tài khoản demo, deploy Vercel + Neon, biến env production, cron.
4. `pnpm build` thành công; kiểm tra `pnpm start` tại :3000.
5. Log request §7.4 có đủ field.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm format:check && pnpm test && pnpm test:e2e
pnpm build            # → Compiled successfully, 0 type errors
pnpm start & sleep 5 && curl -s -I http://localhost:3000/login | grep -i "x-frame-options: DENY"   # → khớp
```

**Commit:** `chore(release): polish accessibility, responsive layout and docs`

---

## Tổng kết phase

| Phase | Nội dung | Số commit |
|---|---|---|
| 1 | Setup | 1 |
| 2 | Data & Types | 1 |
| 3a | Core logic + unit test | 2 |
| 3b | Auth, API infra, validation | 2 |
| 3c | API shops / metrics / dashboard | 2 |
| 3d | API tasks / settings / members / notifications / cron | 2 |
| 4a | UI shell, hooks | 3 |
| 4b | Login, dashboard, shops | 2 |
| 4c | Metrics, import, tasks, notifications | 2 |
| 5 | Settings | 2 |
| 6 | E2E | 1 |
| 7 | Polish & Docs | 1 |
