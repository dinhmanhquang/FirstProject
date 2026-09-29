# ShopPulse — Master Spec · 00 Overview

Đọc kèm: `01-data.md`, `02-api.md`, `03-ui.md`, `04-tests.md`, `05-phases.md`.

Phần này chứa [0] Tier / Assumptions / Out of Scope, [1] Init & Stack, [2] Folder Structure, [7] Non-Functional Requirements, [10] CLAUDE.md của project đích.

---

## [0] Tier, Assumptions Log & Out of Scope

**Product Tier: B — Internal, public-ready.**

### 0.1 Tóm tắt sản phẩm

ShopPulse là web app theo dõi **sức khoẻ vận hành** của nhiều gian hàng Shopee và TikTok Shop trong một tổ chức. App nhận chỉ số vận hành theo ngày (nhập tay hoặc import CSV), tính **Health Score 0–100** cho từng shop theo ngưỡng cấu hình được, và **tự sinh nhiệm vụ** cho nhân viên vận hành khi chỉ số vượt ngưỡng hoặc theo checklist hằng ngày.

Người dùng: nhân viên vận hành sàn (STAFF), trưởng nhóm vận hành (MANAGER), chủ tổ chức (OWNER).

### 0.2 Kết quả nghiên cứu làm cơ sở thiết kế

Nghiên cứu thực hiện ngày 2026-09-29, nguồn công khai.

| Nguồn / sản phẩm | Điều rút ra | Quyết định trong spec |
|---|---|---|
| Shopee Seller Centre — mục "Hiệu quả hoạt động" và hệ thống Sao Quả Tạ | Chỉ số vận hành cốt lõi: Tỷ lệ đơn không thành công (NFR), Tỷ lệ giao hàng trễ (LSR), Thời gian chuẩn bị hàng, Tỷ lệ phản hồi chat, Thời gian phản hồi, Đánh giá shop, Điểm phạt. Điểm phạt cộng dồn theo quý, reset thứ Hai đầu quý; NFR ≥ 10% hoặc LSR ≥ 10% bị cộng điểm phạt. | Catalog chỉ số Shopee gồm đúng 10 chỉ số ở `01-data.md` §3.3. Ngưỡng CRITICAL mặc định của NFR và LSR = 10. |
| TikTok Shop Seller Center — "Hiệu suất người bán" / "Sức khoẻ gian hàng" | Chỉ số cốt lõi: Late Dispatch Rate (LDR, ngưỡng 4%), Seller-Fault Cancellation Rate (SFCR, ngưỡng 2.5%), Negative Review Rate, Điểm vi phạm (tối đa 48, xoá sau 180 ngày), Shop Performance Score (0–5, các mốc 2.5 / 3.5 / 4.0). | Catalog chỉ số TikTok gồm đúng 8 chỉ số. Ngưỡng CRITICAL mặc định LDR = 4, SFCR = 2.5. |
| Sapo, Nhanh.vn, BigSeller, MISA eShop, AutoShopee Shop Manager | Tất cả tập trung vào đồng bộ đơn, tồn kho, chat. Không có sản phẩm nào chuyển chỉ số sức khoẻ thành **nhiệm vụ có người phụ trách, hạn xử lý và trạng thái**. | ShopPulse không làm quản lý đơn / tồn kho. Giá trị cốt lõi = Health Score + Task Engine. |
| Mô tả công việc nhân viên vận hành sàn (TopCV, 123job) | Việc lặp mỗi ngày: xử lý đơn chờ, trả lời chat tồn, phản hồi đánh giá 1–3 sao, theo dõi chỉ số, cập nhật listing. | Checklist routine hằng ngày gồm 4 nhiệm vụ cố định (`01-data.md` §3.6) sinh tự động lúc 07:00 giờ Việt Nam. |
| Shopee Open Platform, TikTok Shop Partner Center | Cả hai API đều yêu cầu đăng ký partner, duyệt app và uỷ quyền từng shop; token Shopee hết hạn sau 4 giờ. | v1 nhập dữ liệu thủ công + CSV. Interface `PlatformConnector` được khai báo sẵn (`src/lib/connectors/types.ts`), implementation API nằm trong Out of Scope. |

Nguồn: ghn.vn (Sao Quả Tạ), bizfly.vn, 3tagency.vn, imta.edu.vn (điểm vi phạm TikTok), sellico.com và duoke.com (TikTok SPS 2026), racklify.com (LDR 4% / SFCR 2.5%), api2cart.com (Shopee Open Platform), partner.tiktokshop.com, topcv.vn.

### 0.3 Flow chính (đã chọn sau nghiên cứu)

1. **Sáng 07:00** — hệ thống sinh 4 nhiệm vụ routine cho mỗi shop ACTIVE, gán cho người phụ trách shop.
2. **Nhân viên mở Dashboard** — thấy lưới shop tô màu theo trạng thái (HEALTHY / WARNING / CRITICAL / NO_DATA), panel "Việc hôm nay" và cảnh báo shop chưa nhập chỉ số.
3. **Nhập chỉ số** — form 1 màn hình cho 1 shop, giá trị hôm qua được điền sẵn, chỉ sửa ô thay đổi, bấm Lưu. Hoặc import CSV nhiều ngày.
4. **Hệ thống tính Health Score** ngay khi lưu, so ngưỡng, sinh nhiệm vụ cảnh báo (WARNING → hạn 24 giờ, CRITICAL → hạn 4 giờ) và gửi thông báo in-app cho người phụ trách.
5. **Nhân viên xử lý nhiệm vụ** — mở nhiệm vụ, làm theo hướng dẫn hành động, ghi chú kết quả, đánh dấu Hoàn thành.
6. **Trưởng nhóm** xem xu hướng 30 ngày, so sánh shop, chỉnh ngưỡng và quy tắc sinh nhiệm vụ.

### 0.4 Assumptions Log

| Giả định | Lý do | Ảnh hưởng nếu sai |
|---|---|---|
| Product Tier = B | User không chỉ định; mặc định theo CLAUDE.md mục 3b. Người dùng là nhân viên vận hành nội bộ nhưng app có giá trị cho shop khác. | Nếu cần tier A: bỏ `orgId`, bỏ role, gộp phase — Delta Spec. Nếu tier C: thêm billing, OAuth, audit log — Delta Spec. |
| Dữ liệu chỉ số nhập tay hoặc CSV, không gọi API sàn | API hai sàn yêu cầu đăng ký partner và uỷ quyền shop; thời gian duyệt không kiểm soát được. | Nếu có API: viết implementation `PlatformConnector`, thêm bảng `ConnectorCredential` — Delta Spec, không đổi model hiện có. |
| Ngưỡng mặc định là **ngưỡng nội bộ**, không phải chính sách sàn | Sàn thay đổi chỉ tiêu theo thời kỳ và theo cấp shop; spec không được bịa chính sách. Giá trị seed lấy từ nguồn công khai ngày 2026-09-29 và được ghi rõ là mặc định chỉnh được. | Trưởng nhóm sửa ngưỡng trong `/settings/thresholds`; không cần deploy lại. |
| 1 tổ chức tại thời điểm launch, mọi bảng vẫn có `orgId` | Quy tắc tier B. | Không có. |
| Đơn vị "ngày" của app = ngày theo múi giờ `Asia/Ho_Chi_Minh` | Người dùng ở Việt Nam; sàn báo cáo theo ngày Việt Nam. | Nếu mở thị trường khác: thêm `timezone` vào `Organization` — Delta Spec. |
| Đăng nhập bằng email + mật khẩu, tài khoản do OWNER / MANAGER tạo | Tier B, không self-signup. | Nếu tier C: thêm signup + verify email. |
| Thông báo chỉ in-app | Tier B tối giản; email / Telegram cần dịch vụ ngoài. | Thêm channel qua `NotificationService.send()` — Delta Spec. |
| Health Score dùng trung bình có trọng số 3 mức (OK 100 / WARNING 50 / CRITICAL 0) | Đơn giản, giải thích được cho nhân viên; không cần lịch sử dài để tính. | Nếu cần mô hình khác: chỉ sửa `src/lib/metrics/health.ts`, có unit test bao phủ. |
| Nhiệm vụ cảnh báo không tự đóng khi chỉ số về mức OK | Tránh che giấu việc chưa xử lý; người dùng đóng thủ công. UI hiển thị badge "Chỉ số đã về ngưỡng OK". | Nếu muốn tự đóng: thêm cờ `autoClose` vào `TaskRule` — Delta Spec. |
| Deploy Vercel + Neon PostgreSQL | Mặc định tier B. | Đổi host: chỉ đổi biến env. |

### 0.5 Out of Scope

Agent KHÔNG được build các mục sau:

1. Không gọi API Shopee / TikTok Shop / Lazada; không scraping Seller Center bằng Playwright. Chỉ khai báo interface `PlatformConnector` để thêm sau.
2. Không quản lý đơn hàng, tồn kho, sản phẩm, chat khách hàng, đánh giá. App chỉ nhận **số liệu tổng hợp**.
3. Không billing, không trang pricing, không giới hạn quota. `Organization.plan` có sẵn giá trị `FREE` để thêm sau.
4. Không self-signup, không OAuth, không verify email, không quên mật khẩu. OWNER đặt lại mật khẩu cho thành viên trong `/settings/members`.
5. Không thông báo email / Telegram / Zalo / push. Chỉ in-app. `NotificationService` chuẩn bị sẵn hook `channel`.
6. Không đa ngôn ngữ. UI tiếng Việt, chuỗi tách vào `src/i18n/vi.json` để thêm `en.json` sau.
7. Không dark mode.
8. Không admin panel cross-org, không onboarding wizard, không trang ToS / Privacy.
9. Không export báo cáo PDF / Excel. Có sẵn file mẫu CSV import.
10. Không audit log, không Sentry. Chỉ structured logging bằng pino.
11. Không mobile app. Web responsive tới 375px.
12. Không hỗ trợ Lazada trong v1. Enum `Platform` chỉ có `SHOPEE`, `TIKTOK`.

---

## [1] Project Initialization & Tech Stack

### 1.1 Tên và mô tả

- **Tên project:** `shop-pulse`
- **Mô tả:** Web app nội bộ theo dõi sức khoẻ vận hành nhiều gian hàng Shopee và TikTok Shop, tính Health Score theo ngày và tự sinh nhiệm vụ cho nhân viên vận hành. Dữ liệu nhập tay hoặc import CSV; kiến trúc sẵn sàng mở public.

### 1.2 Stack và version

| Thành phần | Package | Version |
|---|---|---|
| Runtime | Node.js | 22.x LTS |
| Package manager | pnpm | 10.x |
| Framework | `next` | 15.5.4 |
| UI runtime | `react`, `react-dom` | 19.1.1 |
| Ngôn ngữ | `typescript` | 5.9.2 |
| CSS | `tailwindcss` | 4.1.13 |
| Component | shadcn/ui (CLI `shadcn@3.3.1`) | — |
| ORM | `prisma`, `@prisma/client` | 6.16.2 |
| DB | PostgreSQL | 16 |
| Auth | `next-auth` | 5.0.0-beta.29 |
| Password hash | `bcryptjs` | 3.0.2 |
| Client state | `zustand` | 5.0.8 |
| Server state | `@tanstack/react-query` | 5.90.2 |
| Validation | `zod` | 3.25.76 |
| Form | `react-hook-form`, `@hookform/resolvers` | 7.63.0, 5.2.2 |
| Chart | `recharts` | 3.2.1 |
| CSV | `papaparse` | 5.5.3 |
| Date | `date-fns`, `@date-fns/tz` | 4.1.0, 1.4.1 |
| Icon | `lucide-react` | 0.544.0 |
| Logging | `pino` | 9.10.0 |
| Unit test | `vitest`, `@vitest/coverage-v8` | 3.2.4 |
| E2E test | `@playwright/test` | 1.55.0 |
| Script runner | `tsx` | 4.20.5 |
| Lint / format | `eslint` (config của Next), `prettier` | 9.x, 3.6.2 |

**Quy tắc pin version:** trước khi cài, agent chạy `pnpm view <pkg> version` cho từng package trong bảng. Nếu version trong bảng không tồn tại trên registry, dùng version patch mới nhất cùng minor và ghi vào `CLAUDE.md` của project đích mục "Version drift".

### 1.3 Init command

```bash
pnpm dlx create-next-app@15.5.4 shop-pulse --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-pnpm --no-turbopack
cd shop-pulse
pnpm dlx shadcn@3.3.1 init --defaults
pnpm dlx shadcn@3.3.1 add button card input label select table badge dialog dropdown-menu form sheet tabs toast tooltip textarea checkbox separator skeleton alert progress
```

### 1.4 Dependencies

```json
{
  "dependencies": {
    "@date-fns/tz": "1.4.1",
    "@hookform/resolvers": "5.2.2",
    "@prisma/client": "6.16.2",
    "@tanstack/react-query": "5.90.2",
    "bcryptjs": "3.0.2",
    "date-fns": "4.1.0",
    "lucide-react": "0.544.0",
    "next": "15.5.4",
    "next-auth": "5.0.0-beta.29",
    "papaparse": "5.5.3",
    "pino": "9.10.0",
    "react": "19.1.1",
    "react-dom": "19.1.1",
    "react-hook-form": "7.63.0",
    "recharts": "3.2.1",
    "zod": "3.25.76",
    "zustand": "5.0.8"
  },
  "devDependencies": {
    "@playwright/test": "1.55.0",
    "@types/bcryptjs": "2.4.6",
    "@types/node": "22.18.6",
    "@types/papaparse": "5.3.16",
    "@types/react": "19.1.13",
    "@types/react-dom": "19.1.9",
    "@vitest/coverage-v8": "3.2.4",
    "eslint": "9.36.0",
    "eslint-config-next": "15.5.4",
    "prettier": "3.6.2",
    "prisma": "6.16.2",
    "tsx": "4.20.5",
    "typescript": "5.9.2",
    "vitest": "3.2.4"
  }
}
```

### 1.5 Scripts trong `package.json`

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "prisma generate && next build",
    "start": "next start",
    "lint": "next lint",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "db:migrate": "prisma migrate dev",
    "db:deploy": "prisma migrate deploy",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio"
  },
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

### 1.6 `.env.example`

```bash
# --- Database ---
# Chuỗi kết nối PostgreSQL 16. Local: docker compose (xem README). Production: Neon.
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/shop_pulse?schema=public"

# --- Auth.js ---
# Secret ký JWT session. Sinh bằng: openssl rand -base64 32
AUTH_SECRET="replace-with-openssl-rand-base64-32"
# URL gốc của app. Local: http://localhost:3000. Production: https://<domain>
AUTH_URL="http://localhost:3000"
# Bắt buộc true khi chạy sau proxy (Vercel).
AUTH_TRUST_HOST="true"

# --- Cron ---
# Secret cho route POST /api/cron/daily. Vercel Cron gửi header Authorization: Bearer <CRON_SECRET>.
CRON_SECRET="replace-with-openssl-rand-hex-32"

# --- Seed ---
# Tài khoản OWNER đầu tiên, chỉ dùng bởi prisma/seed.ts.
SEED_OWNER_EMAIL="owner@example.com"
SEED_OWNER_PASSWORD="ChangeMe123!"
SEED_ORG_NAME="Demo Organization"

# --- Logging ---
# Một trong: debug | info | warn | error
LOG_LEVEL="info"

# --- App ---
# Múi giờ nghiệp vụ. Cố định trong v1.
APP_TIMEZONE="Asia/Ho_Chi_Minh"
```

---

## [2] Folder & File Structure

Đường dẫn tuyệt đối từ root `shop-pulse/`. Dòng có `(auto)` là file sinh tự động, không viết tay.

```text
shop-pulse/
├── .env.example                     Mẫu biến môi trường (mục 1.6)
├── .gitignore                       (auto) create-next-app; thêm dòng ".env" và "/test-results"
├── .prettierrc                      { "semi": true, "singleQuote": false, "printWidth": 100 }
├── CLAUDE.md                        Hướng dẫn cho agent (mục [10])
├── README.md                        Cách chạy local, docker compose Postgres, seed
├── components.json                  (auto) shadcn init
├── docker-compose.yml               Service postgres:16 port 5432, db shop_pulse
├── eslint.config.mjs                (auto) create-next-app
├── next.config.ts                   { reactStrictMode: true }
├── package.json                     Mục 1.4, 1.5
├── playwright.config.ts             baseURL http://localhost:3000, testDir ./e2e, webServer "pnpm dev"
├── pnpm-lock.yaml                   (auto)
├── postcss.config.mjs               (auto) create-next-app
├── tsconfig.json                    (auto) + "strict": true, "noUncheckedIndexedAccess": true
├── vercel.json                      Cron: { "crons": [{ "path": "/api/cron/daily", "schedule": "0 0 * * *" }] }
├── vitest.config.ts                 environment node, include src/test/**/*.test.ts, alias @ → src
├── prisma/
│   ├── schema.prisma                Schema (01-data.md §3.1)
│   ├── seed.ts                      Seed org, users, shops, thresholds, rules, snapshots (01-data.md §3.7)
│   └── migrations/                  (auto) prisma migrate
├── spec/                            Bản copy thư mục specs/shop-pulse (đọc, không sửa)
├── e2e/
│   ├── fixtures.ts                  Helper login bằng tài khoản seed
│   ├── auth.spec.ts                 E2E đăng nhập / đăng xuất
│   └── metrics-to-task.spec.ts      E2E nhập chỉ số CRITICAL → nhiệm vụ xuất hiện
├── public/
│   └── templates/
│       └── metrics-template.csv     File mẫu import (01-data.md §3.8)
└── src/
    ├── middleware.ts                Bảo vệ route, redirect /login
    ├── types/
    │   └── index.ts                 Toàn bộ type dùng chung (01-data.md §3.2)
    ├── i18n/
    │   └── vi.json                  Chuỗi UI tiếng Việt (03-ui.md §6.6)
    ├── app/
    │   ├── layout.tsx               Root layout: font, Providers, Toaster
    │   ├── providers.tsx            "use client": QueryClientProvider + Toaster
    │   ├── globals.css              (auto) create-next-app + shadcn
    │   ├── (auth)/
    │   │   └── login/page.tsx       Trang đăng nhập
    │   ├── (app)/
    │   │   ├── layout.tsx           Layout có AppSidebar + AppHeader, yêu cầu session
    │   │   ├── page.tsx             Dashboard "/"
    │   │   ├── shops/page.tsx                       Danh sách shop
    │   │   ├── shops/new/page.tsx                   Tạo shop
    │   │   ├── shops/[shopId]/page.tsx              Chi tiết shop
    │   │   ├── shops/[shopId]/edit/page.tsx         Sửa shop
    │   │   ├── shops/[shopId]/metrics/page.tsx      Nhập chỉ số theo ngày
    │   │   ├── shops/[shopId]/import/page.tsx       Import CSV
    │   │   ├── tasks/page.tsx                       Danh sách nhiệm vụ
    │   │   ├── tasks/[taskId]/page.tsx              Chi tiết nhiệm vụ
    │   │   ├── notifications/page.tsx               Danh sách thông báo
    │   │   ├── settings/layout.tsx                  Tabs cài đặt, chỉ OWNER / MANAGER
    │   │   ├── settings/thresholds/page.tsx         Ngưỡng chỉ số
    │   │   ├── settings/rules/page.tsx              Quy tắc sinh nhiệm vụ
    │   │   └── settings/members/page.tsx            Thành viên
    │   └── api/
    │       ├── auth/[...nextauth]/route.ts          Auth.js handlers
    │       ├── dashboard/summary/route.ts           GET tổng quan
    │       ├── metrics/catalog/route.ts             GET catalog chỉ số
    │       ├── shops/route.ts                       GET list, POST create
    │       ├── shops/[shopId]/route.ts              GET, PATCH, DELETE
    │       ├── shops/[shopId]/metrics/route.ts      GET snapshots, POST upsert 1 ngày
    │       ├── shops/[shopId]/import/route.ts       POST CSV
    │       ├── shops/[shopId]/health/route.ts       GET lịch sử health
    │       ├── tasks/route.ts                       GET list, POST create thủ công
    │       ├── tasks/[taskId]/route.ts              GET, PATCH
    │       ├── settings/thresholds/route.ts         GET, PUT
    │       ├── settings/rules/route.ts              GET, POST
    │       ├── settings/rules/[ruleId]/route.ts     PATCH, DELETE
    │       ├── members/route.ts                     GET, POST
    │       ├── members/[userId]/route.ts            PATCH
    │       ├── notifications/route.ts               GET
    │       ├── notifications/read-all/route.ts      POST
    │       └── cron/daily/route.ts                  POST sinh routine tasks
    ├── components/
    │   ├── ui/                      (auto) shadcn add
    │   ├── common/
    │   │   ├── PageHeader.tsx       Tiêu đề trang + action bên phải
    │   │   ├── EmptyState.tsx       Trạng thái rỗng có CTA
    │   │   ├── StatusPanel.tsx      Loading skeleton / error + retry
    │   │   └── ConfirmDialog.tsx    Hộp thoại xác nhận
    │   ├── layout/
    │   │   ├── AppSidebar.tsx       Menu trái
    │   │   ├── AppHeader.tsx        Thanh trên: tên org, NotificationBell, user menu
    │   │   └── NotificationBell.tsx Chuông + số chưa đọc
    │   ├── dashboard/
    │   │   ├── SummaryCards.tsx     4 thẻ đếm trạng thái shop
    │   │   ├── ShopHealthGrid.tsx   Lưới ShopCard
    │   │   ├── TodayTasksPanel.tsx  Nhiệm vụ đến hạn hôm nay + quá hạn
    │   │   └── StaleShopsAlert.tsx  Cảnh báo shop chưa nhập chỉ số
    │   ├── shops/
    │   │   ├── ShopCard.tsx         Thẻ shop: tên, sàn, score, status, ngày cập nhật
    │   │   ├── ShopForm.tsx         Form tạo / sửa shop
    │   │   ├── ShopStatusBadge.tsx  Badge màu theo HealthStatus
    │   │   ├── HealthGauge.tsx      Vòng score 0–100
    │   │   ├── MetricBreakdownTable.tsx  Bảng chỉ số ngày mới nhất + mức
    │   │   └── MetricTrendChart.tsx Line chart 30 ngày cho 1 chỉ số
    │   ├── metrics/
    │   │   ├── MetricEntryForm.tsx  Form nhập toàn bộ chỉ số 1 ngày
    │   │   └── CsvImportForm.tsx    Upload + preview + kết quả import
    │   ├── tasks/
    │   │   ├── TaskFilters.tsx      Bộ lọc trạng thái / shop / người / ưu tiên
    │   │   ├── TaskList.tsx         Danh sách TaskItem, nhóm theo hạn
    │   │   ├── TaskItem.tsx         1 dòng nhiệm vụ
    │   │   ├── TaskDetail.tsx       Chi tiết + đổi trạng thái + ghi chú
    │   │   └── TaskForm.tsx         Tạo nhiệm vụ thủ công
    │   └── settings/
    │       ├── ThresholdTable.tsx   Bảng ngưỡng inline-edit
    │       ├── RuleTable.tsx        Bảng quy tắc
    │       ├── RuleForm.tsx         Form quy tắc
    │       ├── MemberTable.tsx      Bảng thành viên
    │       └── MemberForm.tsx       Form tạo thành viên / đặt lại mật khẩu
    ├── hooks/
    │   ├── useShops.ts              Query + mutation shop
    │   ├── useMetrics.ts            Query + mutation snapshot, import
    │   ├── useTasks.ts              Query + mutation task
    │   ├── useSettings.ts           Query + mutation thresholds, rules, members
    │   ├── useNotifications.ts      Query notifications, mutation read-all
    │   └── useDashboard.ts          Query summary
    ├── stores/
    │   ├── ui-store.ts              Zustand: sidebar, dialog đang mở
    │   └── task-filter-store.ts     Zustand: bộ lọc nhiệm vụ (persist localStorage)
    ├── lib/
    │   ├── db.ts                    PrismaClient singleton
    │   ├── auth.config.ts           Cấu hình Auth.js dùng được trong middleware (edge)
    │   ├── auth.ts                  NextAuth() với Credentials provider, callbacks
    │   ├── logger.ts                pino instance
    │   ├── rate-limit.ts            Token bucket in-memory theo IP
    │   ├── date.ts                  Hàm ngày theo APP_TIMEZONE
    │   ├── api-client.ts            fetch wrapper phía client, parse ApiError
    │   ├── i18n.ts                  t(key, params) đọc vi.json
    │   ├── api/
    │   │   ├── errors.ts            class ApiError + mã lỗi
    │   │   ├── response.ts          ok(), fail(), paginate()
    │   │   └── guard.ts             requireSession(), requireRole()
    │   ├── metrics/
    │   │   ├── catalog.ts           METRIC_CATALOG (01-data.md §3.3)
    │   │   ├── health.ts            evaluateMetric(), computeHealth()
    │   │   └── csv.ts               parseMetricsCsv()
    │   ├── tasks/
    │   │   ├── templates.ts         renderTemplate(), DEFAULT_ACTION_HINTS
    │   │   ├── engine.ts            generateAlertTasks()
    │   │   └── routines.ts          generateRoutineTasks(), ROUTINE_DEFINITIONS
    │   ├── settings/
    │   │   ├── provider.ts          interface SettingsProvider + DbSettingsProvider
    │   │   └── defaults.ts          createDefaultSettings(orgId)
    │   ├── connectors/
    │   │   └── types.ts             interface PlatformConnector (chưa có implementation)
    │   ├── notifications/
    │   │   └── service.ts           NotificationService.send()
    │   ├── services/
    │   │   ├── shop-service.ts      CRUD shop
    │   │   ├── metric-service.ts    upsertSnapshots() → recompute → engine
    │   │   ├── task-service.ts      list / create / update task
    │   │   └── member-service.ts    create / update member
    │   └── validation/
    │       ├── auth.ts              loginSchema
    │       ├── shop.ts              createShopSchema, updateShopSchema
    │       ├── metrics.ts           upsertMetricsSchema, metricsQuerySchema
    │       ├── task.ts              createTaskSchema, updateTaskSchema, taskListQuerySchema
    │       ├── settings.ts          thresholdsPutSchema, ruleSchema
    │       └── member.ts            createMemberSchema, updateMemberSchema
    └── test/
        ├── health.test.ts
        ├── engine.test.ts
        ├── routines.test.ts
        ├── csv.test.ts
        ├── templates.test.ts
        ├── date.test.ts
        └── validation.test.ts
```

---

## [7] Non-Functional Requirements (tier B)

### 7.1 Auth

- Auth.js v5, provider `Credentials` (email + mật khẩu). Hash `bcryptjs` cost 12.
- Session strategy `jwt`, `maxAge` 7 ngày (604800 giây). JWT chứa `sub` (userId), `orgId`, `role`, `name`, `email`.
- `src/middleware.ts` matcher: `["/((?!api/auth|api/cron|login|_next/static|_next/image|favicon.ico|templates).*)"]`. Không có session → redirect `/login?next=<path>`.
- Route `/api/*` (trừ `auth`, `cron`) không có session → `401 UNAUTHORIZED`.
- `User.isActive = false` → login thất bại với thông báo `auth.errors.inactive`.

### 7.2 Phân quyền

| Hành động | OWNER | MANAGER | STAFF |
|---|---|---|---|
| Xem dashboard, shop, nhiệm vụ, thông báo | ✔ | ✔ | ✔ |
| Nhập chỉ số, import CSV | ✔ | ✔ | ✔ |
| Tạo / sửa / hoàn thành nhiệm vụ | ✔ | ✔ | ✔ (chỉ nhiệm vụ gán cho mình hoặc chưa gán) |
| Tạo / sửa / xoá shop | ✔ | ✔ | ✘ |
| Sửa ngưỡng, quy tắc | ✔ | ✔ | ✘ |
| Tạo / sửa thành viên, đặt lại mật khẩu | ✔ | ✔ (không được sửa OWNER) | ✘ |
| Đổi role thành OWNER | ✔ | ✘ | ✘ |

Vi phạm → `403 FORBIDDEN`. Mọi truy vấn DB luôn có điều kiện `orgId = session.orgId`.

### 7.3 Bảo mật

- Rate limit `POST /api/auth/callback/credentials`: 10 request / 15 phút / IP, bộ nhớ trong process (`src/lib/rate-limit.ts`). Vượt → `429 RATE_LIMITED`.
- Rate limit `POST /api/shops/[shopId]/import`: 5 request / phút / user.
- CSV: giới hạn 1 MB, tối đa 5 000 dòng, chỉ chấp nhận `text/csv` hoặc phần mở rộng `.csv`.
- Mọi input qua Zod trước khi chạm DB. Chuỗi được `trim()`.
- CORS: không đặt header CORS; chỉ same-origin.
- Header bảo mật trong `next.config.ts`: `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`.
- `CRON_SECRET` so sánh bằng `crypto.timingSafeEqual`.

### 7.4 Logging

- pino, JSON một dòng, level từ `LOG_LEVEL`.
- Mỗi request API log 1 dòng lúc kết thúc: `{ level, time, reqId, method, path, status, durationMs, orgId, userId }`.
- Lỗi 5xx log thêm `err.stack`. Không log mật khẩu, không log body request.

### 7.5 Performance

- LCP Dashboard ≤ 2.5 giây với 50 shop và 500 nhiệm vụ mở (đo trên Vercel, Chrome desktop).
- API p95 ≤ 400 ms cho `GET /api/dashboard/summary` với dữ liệu trên.
- `GET /api/shops/[shopId]/metrics` giới hạn `to - from ≤ 92` ngày.
- Index DB theo `01-data.md` §3.1.

### 7.6 Accessibility

- Mọi nút icon có `aria-label`. Form dùng `<label htmlFor>`. Badge trạng thái có text, không chỉ màu.
- Điều hướng bàn phím: Tab qua mọi control, Enter submit, Esc đóng dialog.
- Màu trạng thái: HEALTHY `#16A34A`, WARNING `#D97706`, CRITICAL `#DC2626`, NO_DATA `#6B7280`; contrast với nền trắng ≥ 4.5:1.

### 7.7 i18n

- Mọi chuỗi UI trong `src/i18n/vi.json`. Truy cập qua `t("dashboard.title")`. Không hardcode chuỗi tiếng Việt trong component.
- Thông báo lỗi Zod cũng lấy từ `vi.json` (key `validation.*`).

### 7.8 Deploy

- Vercel (Node 22 runtime), Postgres trên Neon.
- Biến env production: `DATABASE_URL`, `AUTH_SECRET`, `AUTH_URL`, `AUTH_TRUST_HOST=true`, `CRON_SECRET`, `LOG_LEVEL=info`, `APP_TIMEZONE=Asia/Ho_Chi_Minh`.
- Build command: `pnpm build`. Trước build: `pnpm db:deploy`.
- Vercel Cron theo `vercel.json`: `0 0 * * *` UTC = 07:00 Việt Nam.

---

## [10] CLAUDE.md của project đích

Nội dung đầy đủ file `shop-pulse/CLAUDE.md`:

```markdown
# CLAUDE.md — shop-pulse

## Project
Web app theo dõi sức khoẻ vận hành shop Shopee / TikTok Shop, tính Health Score và tự sinh nhiệm vụ. Tier B (internal, public-ready). Spec đầy đủ trong `spec/`.

## Stack
Next.js 15.5 App Router · TypeScript strict · Tailwind 4 · shadcn/ui · Prisma 6 + PostgreSQL 16 · Auth.js v5 (Credentials) · Zustand · TanStack Query · Zod · Vitest · Playwright · pnpm.

## Commands
- `pnpm dev` — chạy local (cần Postgres: `docker compose up -d`)
- `pnpm db:migrate` — tạo / áp migration dev
- `pnpm db:seed` — seed dữ liệu mẫu
- `pnpm typecheck` — tsc --noEmit
- `pnpm lint` — eslint
- `pnpm test` — unit test (Vitest)
- `pnpm test:e2e` — Playwright

## Rules
- ALWAYS run `pnpm typecheck && pnpm lint && pnpm test` before every commit. Không commit khi bất kỳ lệnh nào fail.
- Code, identifiers, comments, commit message: tiếng Anh. UI string: chỉ trong `src/i18n/vi.json`.
- Mọi truy vấn Prisma phải có điều kiện `orgId`.
- Không hardcode tên shop, ID sàn, tài khoản vào code. Tất cả là data.
- Không gọi API sàn, không scraping. Chỉ dùng interface trong `src/lib/connectors/types.ts`.
- Commit theo Conventional Commits: `feat(scope): ...`, `fix(scope): ...`, `test(scope): ...`, `chore(scope): ...`.

## Files không được sửa
- `spec/**` — nguồn sự thật; muốn đổi phải có Delta Spec.
- `prisma/migrations/**` — chỉ sinh bằng `prisma migrate dev`, không sửa tay.
- `src/components/ui/**` — sinh bởi shadcn; muốn thay đổi thì wrap component mới.
- `pnpm-lock.yaml` — chỉ thay đổi qua `pnpm add/remove`.

## Spec files
- `spec/00-overview.md` — tier, assumptions, stack, cấu trúc, NFR
- `spec/01-data.md` — schema, types, catalog chỉ số, store, seed
- `spec/02-api.md` — API contracts
- `spec/03-ui.md` — routes, flows, states, components, validation
- `spec/04-tests.md` — acceptance tests
- `spec/05-phases.md` — lộ trình phase (đọc phase hiện tại, không đọc cả file)

## Version drift
(Agent ghi vào đây package nào phải đổi version so với spec §1.2 và lý do.)
```
