# Social Growth Hub — Master Spec · 00 Overview

Đọc kèm: `01-data.md`, `02-api.md`, `03-ui.md`, `04-tests.md`, `05-phases.md`.

---

## [0] Tier, Assumptions Log & Out of Scope

**Product Tier: B — Internal, public-ready.**

Mô tả 2 câu: Social Growth Hub là hệ thống vận hành mạng xã hội tập trung cho team bán hàng: kết nối các kênh (Facebook Page, Instagram, TikTok, YouTube, Zalo OA), phát hiện xu hướng, sinh và lên lịch nội dung bằng AI, quản lý seeding vào cộng đồng, gom toàn bộ comment / tin nhắn vào một hộp thư có AI trả lời, xây hồ sơ fan và đo lường điều hướng người dùng về link đích (fanpage, nhóm, gian hàng). Mục tiêu đo được: tăng số fan có tương tác, giảm thời gian phản hồi xuống dưới 5 phút cho câu hỏi thường gặp, và biết chính xác kênh nào đưa được bao nhiêu click về nơi cần.

### Assumptions Log

| Giả định | Lý do | Ảnh hưởng nếu sai |
|---|---|---|
| Tier B | User chưa chọn tier; mặc định theo CLAUDE.md §3b | Tier A: bỏ `orgId`, bỏ role, gộp phase. Tier C: thêm billing, audit log, Sentry, phase Launch qua Delta Spec |
| Nền tảng v1 = Facebook Page, Instagram, TikTok, YouTube, Zalo OA | Năm nền tảng này có API chính thức cho ứng dụng bên thứ ba và phủ nhóm người dùng mua sắm online tại Việt Nam | Thêm Threads / X / Lemon8: Delta Spec thêm một file adapter trong `src/lib/platforms/` |
| Facebook Group KHÔNG đăng bài tự động qua API | Meta đã gỡ Groups API cho ứng dụng bên thứ ba từ 04/2024; không có endpoint hợp lệ | Seeding vào group thiết kế dạng bán tự động: hệ thống soạn biến thể nội dung, giao việc, đo click; người thật đăng. Nếu Meta mở lại API: Delta Spec thêm `FacebookGroupAdapter` |
| TikTok v1 chỉ đăng bài, không đọc / trả lời comment | Comment API của TikTok chỉ cấp qua đơn xét duyệt Business; Content Posting API cấp được cho app thường sau audit | Khi được cấp quyền: Delta Spec bổ sung `TikTokAdapter.fetchInteractions` và `replyToInteraction` |
| Không tạo, thuê, điều khiển tài khoản ảo hoặc tài khoản của người ngoài team | Vi phạm điều khoản của mọi nền tảng, rủi ro khóa Page và gian hàng liên kết | Nếu user yêu cầu: từ chối, giữ nguyên Out of Scope |
| Worker chạy tiến trình riêng (Railway), hàng đợi BullMQ trên Redis (Upstash) | Vercel serverless giới hạn thời gian chạy, không giữ được job polling và cron dài | Đổi nơi deploy worker: sửa mục [7], code không đổi |
| Nguồn xu hướng v1 = Google Trends RSS (geo VN), YouTube `mostPopular` (regionCode VN), keyword watchlist qua YouTube Search, số liệu kênh của chính org | Toàn bộ là nguồn công khai hoặc API chính thức, không scraping | Thêm nguồn: Delta Spec thêm một `TrendCollector` trong `src/lib/services/trend-service.ts` |
| LLM = Anthropic Claude qua `@anthropic-ai/sdk`: `claude-opus-5-5` cho sinh nội dung và soạn trả lời, `claude-haiku-4-5` cho phân loại hàng loạt | SDK chính thức, có structured output, có fallback server-side khi bị từ chối bởi bộ lọc an toàn | Đổi provider: chỉ sửa `src/lib/ai/client.ts` |
| Media lưu Vercel Blob | Cùng hệ sinh thái deploy web, không cần bucket riêng | Đổi sang R2 / S3: sửa `src/lib/storage.ts` |
| Thông báo nội bộ qua Telegram Bot | Team liên lạc bằng Telegram, Bot API miễn phí, không cần xét duyệt | Đổi sang Zalo nội bộ: sửa `src/lib/services/telegram.ts` |
| Auth = Auth.js v5 với Credentials (email + mật khẩu) và Google OAuth; một Organization duy nhất được tạo khi onboarding | Tier B: auth đầy đủ, role, Organization nhưng chỉ 1 org | Cho phép nhiều org: bỏ ràng buộc trong `POST /api/org` |
| Múi giờ cố định `Asia/Ho_Chi_Minh` cho mọi lịch đăng và báo cáo | Thị trường Việt Nam | Mở rộng thị trường: thêm cột `timezone` vào `Organization` |
| Bảng auth (`User`, `Account`, `Session`, `VerificationToken`) và `Organization` không có `orgId`; mọi bảng nghiệp vụ còn lại có `orgId` | Auth.js quản lý bảng auth ở mức toàn hệ thống; `Organization` là gốc tenant | Không có |
| Giới hạn AI mỗi org: 2.000 lượt gọi / ngày, đọc từ `Setting.ai.dailyCallLimit` | Kiểm soát chi phí, chuẩn bị hook cho quota theo plan sau này | Đổi số: sửa giá trị Setting, không sửa code |

### Out of Scope

Agent KHÔNG được build các mục sau:

1. Không tạo, đăng nhập, nuôi, hoặc điều khiển tài khoản ảo / tài khoản người ngoài team; không mua follower, like, comment.
2. Không đăng bài tự động vào Facebook Group qua bất kỳ kỹ thuật nào ngoài API chính thức (không Playwright / browser automation lên Facebook, TikTok, Instagram, Zalo, YouTube).
3. Không gửi tin nhắn chủ động (cold DM) tới người dùng chưa từng tương tác với kênh của org.
4. Không quản lý quảng cáo trả phí (Facebook Ads, TikTok Ads).
5. Không tích hợp gian hàng Shopee / Lazada / TikTok Shop (đồng bộ sản phẩm, đơn hàng). Bảng `Product` nhập tay.
6. Không billing, không trang pricing, không giới hạn theo plan (chuẩn bị sẵn hook: field `plan` trong `Organization`, `Setting.ai.dailyCallLimit`).
7. Không onboarding nhiều bước, không help docs, không trang ToS / Privacy (chuẩn bị sẵn hook: route `/onboarding` chỉ tạo org).
8. Không i18n đa ngôn ngữ; chỉ tiếng Việt trong `src/i18n/vi.json` (chuẩn bị sẵn hook: helper `t()`).
9. Không dark mode.
10. Không mobile app; web responsive tới 375px là đủ.
11. Không livestream automation, không tạo video / ảnh bằng AI; media do người upload.
12. Không audit log, không Sentry, không xóa tài khoản người dùng (tier C).
13. Không realtime (WebSocket / SSE); inbox làm mới bằng TanStack Query `refetchInterval` 30 giây.
14. Không Threads, X, Lemon8, Facebook Reels riêng lẻ (Reels đăng như video của Page).
15. Không đọc / trả lời comment TikTok và không đọc tin nhắn Instagram trong v1.

---

## [1] Project Initialization & Tech Stack

**Tên project:** `social-growth-hub`
**Slug spec:** `social-growth-hub`

### Stack

| Hạng mục | Lựa chọn | Version |
|---|---|---|
| Runtime | Node.js | 22.x LTS |
| Package manager | pnpm | 9.x |
| Framework web | Next.js (App Router) | 15.5.x |
| Ngôn ngữ | TypeScript strict | 5.6.x |
| UI | Tailwind CSS + shadcn/ui | 3.4.x + CLI mới nhất |
| ORM / DB | Prisma + PostgreSQL | 6.x + PostgreSQL 16 |
| Auth | Auth.js (next-auth) | 5.0.0-beta.x |
| Server state | TanStack Query | 5.x |
| Client state | Zustand | 5.x |
| Validation | Zod | 3.23.x |
| Queue | BullMQ + ioredis | 5.x + 5.x |
| LLM | @anthropic-ai/sdk | mới nhất |
| Storage | @vercel/blob | 0.27.x |
| Logging | pino | 9.x |
| Mật khẩu | bcryptjs | 2.4.x |
| Thời gian | date-fns + date-fns-tz | 4.x + 3.x |
| Test | Vitest + Playwright | 2.x + 1.48.x |
| Lint / format | ESLint + Prettier | config mặc định Next.js |
| Worker runner | tsx | 4.x |

Phase 1 bắt buộc chạy `pnpm view <pkg> version` cho từng package và ghi version chính xác vào `package.json` trước khi cài. Version trong bảng là minor tối thiểu.

### Init command

```bash
pnpm dlx create-next-app@15 social-growth-hub --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-pnpm --no-turbopack
cd social-growth-hub
pnpm dlx shadcn@latest init -d
pnpm dlx shadcn@latest add button card dialog input textarea select badge table tabs toast dropdown-menu sheet form label checkbox switch calendar popover command avatar separator skeleton scroll-area tooltip alert progress
```

### Dependencies

```bash
pnpm add @prisma/client next-auth@beta @auth/prisma-adapter zod @tanstack/react-query zustand bullmq ioredis @anthropic-ai/sdk @vercel/blob pino bcryptjs date-fns date-fns-tz nanoid fast-xml-parser
pnpm add -D prisma tsx vitest @vitejs/plugin-react @testing-library/react @testing-library/jest-dom jsdom @playwright/test @types/bcryptjs @types/node pino-pretty prettier prettier-plugin-tailwindcss
```

`dependencies`: `@prisma/client`, `next`, `react`, `react-dom`, `next-auth`, `@auth/prisma-adapter`, `zod`, `@tanstack/react-query`, `zustand`, `bullmq`, `ioredis`, `@anthropic-ai/sdk`, `@vercel/blob`, `pino`, `bcryptjs`, `date-fns`, `date-fns-tz`, `nanoid`, `fast-xml-parser`, cùng các package shadcn tự thêm (`class-variance-authority`, `clsx`, `tailwind-merge`, `lucide-react`, `@radix-ui/*`).

`devDependencies`: `prisma`, `tsx`, `typescript`, `vitest`, `@vitejs/plugin-react`, `@testing-library/react`, `@testing-library/jest-dom`, `jsdom`, `@playwright/test`, `@types/bcryptjs`, `@types/node`, `@types/react`, `@types/react-dom`, `pino-pretty`, `prettier`, `prettier-plugin-tailwindcss`, `eslint`, `eslint-config-next`, `tailwindcss`, `postcss`.

### Scripts trong `package.json`

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "prisma generate && next build",
    "start": "next start",
    "lint": "next lint",
    "format": "prettier --write .",
    "typecheck": "tsc --noEmit && tsc --noEmit -p tsconfig.worker.json",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "db:migrate": "prisma migrate dev",
    "db:deploy": "prisma migrate deploy",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio",
    "worker": "tsx src/worker/index.ts",
    "worker:dev": "tsx watch src/worker/index.ts"
  }
}
```

### `.env.example` (nội dung đầy đủ)

```bash
# ===== App =====
# URL public của web app, không có dấu / cuối. Dùng cho OAuth callback, short link, webhook.
NEXT_PUBLIC_APP_URL=http://localhost:3000
# Môi trường: development | production | test
NODE_ENV=development

# ===== Database =====
# PostgreSQL connection string (Neon / Supabase / Railway đều dùng được)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/social_growth_hub

# ===== Redis (BullMQ) =====
# Upstash Redis dùng rediss:// (TLS). Local dev: redis://localhost:6379
REDIS_URL=redis://localhost:6379

# ===== Auth.js =====
# Sinh bằng: openssl rand -base64 32
AUTH_SECRET=change-me
# Google OAuth (Google Cloud Console > Credentials > OAuth 2.0 Client ID, redirect URI: {NEXT_PUBLIC_APP_URL}/api/auth/callback/google)
AUTH_GOOGLE_ID=
AUTH_GOOGLE_SECRET=
# Bật khi chạy sau proxy (Vercel): true
AUTH_TRUST_HOST=true

# ===== Mã hóa token nền tảng =====
# 32 byte hex (64 ký tự). Sinh bằng: openssl rand -hex 32. Mất key = mất toàn bộ token đã lưu.
TOKEN_ENCRYPTION_KEY=

# ===== Anthropic =====
ANTHROPIC_API_KEY=
# Model sinh nội dung / soạn trả lời
AI_MODEL_GENERATE=claude-opus-5-5
# Model phân loại comment / chấm điểm trend
AI_MODEL_CLASSIFY=claude-haiku-4-5

# ===== Storage =====
# Token từ Vercel Dashboard > Storage > Blob
BLOB_READ_WRITE_TOKEN=

# ===== Facebook / Instagram (Meta for Developers) =====
# App ID / Secret của Meta App; App phải có Facebook Login for Business + Instagram Graph API
META_APP_ID=
META_APP_SECRET=
# Chuỗi tự đặt để Meta xác minh webhook (GET /api/webhooks/facebook)
META_WEBHOOK_VERIFY_TOKEN=change-me
# Phiên bản Graph API, cố định
META_GRAPH_VERSION=v21.0

# ===== TikTok for Developers =====
TIKTOK_CLIENT_KEY=
TIKTOK_CLIENT_SECRET=

# ===== Google / YouTube Data API v3 =====
# Dùng chung OAuth client với Auth.js nếu cùng project GCP; scope youtube.upload + youtube.force-ssl
YOUTUBE_CLIENT_ID=
YOUTUBE_CLIENT_SECRET=
# API key (không OAuth) cho videos.list mostPopular và search.list
YOUTUBE_API_KEY=

# ===== Zalo Official Account =====
ZALO_APP_ID=
ZALO_APP_SECRET=
# Secret key OA dùng xác minh chữ ký webhook (Zalo Developers > OA > Webhook)
ZALO_OA_SECRET_KEY=

# ===== Telegram (thông báo nội bộ) =====
# Token từ @BotFather
TELEGRAM_BOT_TOKEN=

# ===== Worker =====
# Số job publish chạy song song trong worker
WORKER_CONCURRENCY=5
# Bật cron trong worker (true) — tắt khi chạy nhiều instance worker để tránh trùng lịch
WORKER_ENABLE_CRON=true
# Chỉ cho môi trường test: true -> registry trả MockAdapter, không gọi nền tảng thật
PLATFORM_MOCK=false
# Mức log: debug | info | warn | error
LOG_LEVEL=info
```

---

## [2] Folder & File Structure

Đường dẫn tuyệt đối từ root `social-growth-hub/`. Dòng ghi `(auto)` là file sinh tự động, không viết tay.

```text
social-growth-hub/
├── .env.example                          # Mẫu biến môi trường (mục [1])
├── .gitignore                            # (auto) create-next-app; thêm dòng .env, /playwright-report, /test-results
├── .prettierrc                           # {"semi": true, "singleQuote": false, "plugins": ["prettier-plugin-tailwindcss"]}
├── CLAUDE.md                             # Mục [10]
├── README.md                             # Cách chạy local, deploy, biến env
├── components.json                       # (auto) shadcn
├── eslint.config.mjs                     # (auto) Next.js
├── next.config.ts                        # images.remotePatterns cho *.public.blob.vercel-storage.com, graph.facebook.com, *.cdninstagram.com, i.ytimg.com, *.tiktokcdn.com
├── package.json                          # Scripts mục [1]
├── playwright.config.ts                  # baseURL = NEXT_PUBLIC_APP_URL, testDir = e2e, webServer = pnpm dev
├── pnpm-lock.yaml                        # (auto)
├── postcss.config.mjs                    # (auto)
├── tailwind.config.ts                    # (auto) shadcn; content bao gồm ./src/**/*.{ts,tsx}
├── tsconfig.json                         # (auto) strict: true, paths @/* -> src/*
├── tsconfig.worker.json                  # extends tsconfig.json; include src/worker, src/lib, src/types; module NodeNext
├── vitest.config.ts                      # environment jsdom, setupFiles src/__tests__/setup.ts, alias @ -> src
├── prisma/
│   ├── schema.prisma                     # Toàn bộ schema mục [3] (01-data.md)
│   ├── seed.ts                           # Seed data mục [3]
│   └── migrations/                       # (auto) prisma migrate
├── e2e/
│   ├── auth.spec.ts                      # E2E đăng nhập + onboarding
│   ├── post-flow.spec.ts                 # E2E tạo bài -> lên lịch
│   └── inbox-flow.spec.ts                # E2E trả lời comment thủ công
└── src/
    ├── middleware.ts                     # Bảo vệ route (app)/* và /api/* trừ auth, webhooks, public
    ├── auth.ts                           # Cấu hình Auth.js: providers, callbacks, PrismaAdapter
    ├── i18n/
    │   └── vi.json                       # Toàn bộ chuỗi UI tiếng Việt
    ├── types/
    │   └── index.ts                      # Type dùng chung (01-data.md)
    ├── stores/
    │   ├── ui-store.ts                   # Zustand: sidebar, dialog đang mở
    │   ├── post-editor-store.ts          # Zustand: state trình soạn bài
    │   └── inbox-store.ts                # Zustand: filter + interaction đang chọn
    ├── hooks/
    │   ├── use-org.ts                    # useOrg(): org hiện tại + membership + role
    │   ├── use-channels.ts               # Query/mutation SocialAccount
    │   ├── use-posts.ts                  # Query/mutation Post
    │   ├── use-trends.ts                 # Query/mutation Trend
    │   ├── use-inbox.ts                  # Query/mutation Interaction + Reply
    │   ├── use-fans.ts                   # Query/mutation Fan
    │   ├── use-links.ts                  # Query/mutation Link + LinkHub
    │   ├── use-seeding.ts                # Query/mutation Seeding*
    │   ├── use-rules.ts                  # Query/mutation AutomationRule
    │   ├── use-analytics.ts              # Query analytics
    │   └── use-settings.ts               # Query/mutation Setting, Template, Knowledge, Product, Team
    ├── lib/
    │   ├── prisma.ts                     # Singleton PrismaClient
    │   ├── logger.ts                     # pino instance, format JSON, level LOG_LEVEL
    │   ├── api.ts                        # apiHandler(), ApiError, ok(), paginate()
    │   ├── auth-helpers.ts               # requireSession(), requireRole(), getOrgContext()
    │   ├── crypto.ts                     # encryptSecret(), decryptSecret() AES-256-GCM
    │   ├── storage.ts                    # uploadMedia(), deleteMedia() qua Vercel Blob
    │   ├── i18n.ts                       # t(key, params)
    │   ├── slug.ts                       # toSlug(), randomSlug()
    │   ├── time.ts                       # nowVN(), toVN(), formatVN(), TIMEZONE
    │   ├── utils.ts                      # (auto) shadcn cn()
    │   ├── settings/
    │   │   ├── settings-provider.ts      # interface SettingsProvider + SETTING_KEYS + defaults
    │   │   └── db-settings-provider.ts   # DbSettingsProvider đọc bảng Setting, fallback env
    │   ├── validations/
    │   │   ├── auth.ts                   # registerSchema, loginSchema, onboardingSchema
    │   │   ├── social-account.ts         # connectSchema, listChannelsSchema
    │   │   ├── post.ts                   # createPostSchema, updatePostSchema, generatePostSchema, scheduleSchema
    │   │   ├── media.ts                  # uploadMediaSchema
    │   │   ├── trend.ts                  # listTrendsSchema, updateTrendSchema, ideasSchema
    │   │   ├── inbox.ts                  # listInboxSchema, updateInteractionSchema, replySchema, draftSchema
    │   │   ├── fan.ts                    # listFansSchema, updateFanSchema, messageFanSchema
    │   │   ├── link.ts                   # createLinkSchema, updateLinkSchema, linkHubSchema
    │   │   ├── seeding.ts                # campaignSchema, targetSchema, taskUpdateSchema
    │   │   ├── rule.ts                   # ruleSchema, triggerSchema, conditionSchema, actionSchema
    │   │   ├── settings.ts               # orgSettingsSchema, aiSettingsSchema, telegramSettingsSchema, templateSchema, knowledgeSchema, productSchema, inviteSchema
    │   │   └── common.ts                 # paginationSchema, cuidSchema, dateRangeSchema
    │   ├── ai/
    │   │   ├── client.ts                 # Anthropic singleton + generateStructured() + quota
    │   │   ├── prompts.ts                # Toàn bộ system prompt (hằng string)
    │   │   ├── schemas.ts                # Zod schema output của AI
    │   │   ├── generate-post.ts          # generatePostVariants()
    │   │   ├── classify-interaction.ts   # classifyInteraction()
    │   │   ├── draft-reply.ts            # draftReply()
    │   │   ├── score-trend.ts            # scoreTrends()
    │   │   └── seeding-variants.ts       # generateSeedingVariants()
    │   ├── platforms/
    │   │   ├── types.ts                  # interface PlatformAdapter + kiểu dữ liệu chuẩn hóa
    │   │   ├── registry.ts               # getAdapter(platform)
    │   │   ├── oauth.ts                  # buildAuthUrl(), exchangeCode() cho từng platform
    │   │   ├── facebook.ts               # FacebookPageAdapter
    │   │   ├── instagram.ts              # InstagramAdapter
    │   │   ├── tiktok.ts                 # TikTokAdapter
    │   │   ├── youtube.ts                # YouTubeAdapter
    │   │   ├── zalo.ts                   # ZaloOaAdapter
    │   │   └── mock.ts                   # MockAdapter, chỉ dùng khi NODE_ENV=test và PLATFORM_MOCK=true
    │   ├── services/
    │   │   ├── post-service.ts           # CRUD Post + PostVariant, chuyển trạng thái
    │   │   ├── publish-service.ts        # publishVariant(): gọi adapter, cập nhật kết quả
    │   │   ├── interaction-service.ts    # upsertInteraction(), listInbox(), escalate()
    │   │   ├── reply-service.ts          # sendReply(), decideAutoReply()
    │   │   ├── fan-service.ts            # upsertFan(), recalcScore(), tagFan()
    │   │   ├── trend-service.ts          # collectTrends() từ 4 nguồn, upsertTrend()
    │   │   ├── link-service.ts           # createLink(), resolveLink(), recordClick(), hub CRUD
    │   │   ├── seeding-service.ts        # campaign/target/task CRUD, assignTasks()
    │   │   ├── rule-engine.ts            # evaluateRules(event), runActions()
    │   │   ├── analytics-service.ts      # overview(), byChannel(), topPosts(), funnel()
    │   │   ├── insights-service.ts       # syncInsights(), syncPostMetrics()
    │   │   ├── telegram.ts               # sendTelegram(chatId, text)
    │   │   └── team-service.ts           # invite(), changeRole(), removeMember()
    │   └── queue/
    │       ├── queues.ts                 # Định nghĩa Queue + connection ioredis
    │       └── jobs.ts                   # enqueuePublish(), enqueueRunRules(), … + JobData types
    ├── worker/
    │   ├── index.ts                      # Khởi tạo Worker cho từng queue + cron repeatable
    │   └── processors/
    │       ├── publish-post.ts           # Job publish-post
    │       ├── sync-interactions.ts      # Job sync-interactions (poll YouTube, Facebook fallback)
    │       ├── sync-insights.ts          # Job sync-insights (daily)
    │       ├── refresh-trends.ts         # Job refresh-trends (6h)
    │       ├── classify-and-reply.ts     # Job classify-and-reply (mỗi interaction mới)
    │       ├── run-rules.ts              # Job run-rules (mỗi event)
    │       ├── recalc-fans.ts            # Job recalc-fans (daily)
    │       ├── seeding-generate.ts       # Job seeding-generate (khi tạo task)
    │       └── token-check.ts            # Job token-check (daily): token sắp hết hạn -> Telegram
    ├── app/
    │   ├── layout.tsx                    # Root layout: font, QueryClientProvider, Toaster
    │   ├── globals.css                   # (auto) Tailwind + shadcn tokens
    │   ├── providers.tsx                 # QueryClientProvider + SessionProvider
    │   ├── (auth)/
    │   │   ├── layout.tsx                # Layout giữa màn hình, không sidebar
    │   │   ├── login/page.tsx            # Trang đăng nhập
    │   │   ├── register/page.tsx         # Trang đăng ký
    │   │   └── onboarding/page.tsx       # Tạo Organization
    │   ├── (app)/
    │   │   ├── layout.tsx                # AppSidebar + AppHeader; redirect nếu chưa có org
    │   │   ├── dashboard/page.tsx
    │   │   ├── channels/page.tsx
    │   │   ├── trends/page.tsx
    │   │   ├── content/page.tsx
    │   │   ├── content/new/page.tsx
    │   │   ├── content/[postId]/page.tsx
    │   │   ├── calendar/page.tsx
    │   │   ├── inbox/page.tsx
    │   │   ├── fans/page.tsx
    │   │   ├── fans/[fanId]/page.tsx
    │   │   ├── seeding/page.tsx
    │   │   ├── seeding/[campaignId]/page.tsx
    │   │   ├── links/page.tsx
    │   │   ├── automations/page.tsx
    │   │   ├── analytics/page.tsx
    │   │   └── settings/page.tsx
    │   ├── (public)/
    │   │   ├── l/[slug]/route.ts         # GET: ghi click, redirect 302
    │   │   └── hub/[slug]/page.tsx       # Trang bio link công khai
    │   └── api/
    │       ├── auth/[...nextauth]/route.ts
    │       ├── auth/register/route.ts
    │       ├── org/route.ts
    │       ├── social-accounts/route.ts
    │       ├── social-accounts/[id]/route.ts
    │       ├── social-accounts/[id]/sync/route.ts
    │       ├── social-accounts/connect/[platform]/route.ts
    │       ├── social-accounts/callback/[platform]/route.ts
    │       ├── posts/route.ts
    │       ├── posts/generate/route.ts
    │       ├── posts/[id]/route.ts
    │       ├── posts/[id]/schedule/route.ts
    │       ├── posts/[id]/publish/route.ts
    │       ├── media/route.ts
    │       ├── media/[id]/route.ts
    │       ├── trends/route.ts
    │       ├── trends/refresh/route.ts
    │       ├── trends/[id]/route.ts
    │       ├── trends/[id]/ideas/route.ts
    │       ├── inbox/route.ts
    │       ├── inbox/[id]/route.ts
    │       ├── inbox/[id]/reply/route.ts
    │       ├── inbox/[id]/draft/route.ts
    │       ├── fans/route.ts
    │       ├── fans/[id]/route.ts
    │       ├── fans/[id]/message/route.ts
    │       ├── links/route.ts
    │       ├── links/[id]/route.ts
    │       ├── link-hub/route.ts
    │       ├── seeding/campaigns/route.ts
    │       ├── seeding/campaigns/[id]/route.ts
    │       ├── seeding/campaigns/[id]/targets/route.ts
    │       ├── seeding/campaigns/[id]/generate/route.ts
    │       ├── seeding/tasks/route.ts
    │       ├── seeding/tasks/[id]/route.ts
    │       ├── rules/route.ts
    │       ├── rules/[id]/route.ts
    │       ├── analytics/overview/route.ts
    │       ├── analytics/channels/route.ts
    │       ├── analytics/posts/route.ts
    │       ├── analytics/funnel/route.ts
    │       ├── settings/route.ts
    │       ├── templates/route.ts
    │       ├── templates/[id]/route.ts
    │       ├── knowledge/route.ts
    │       ├── knowledge/[id]/route.ts
    │       ├── products/route.ts
    │       ├── products/[id]/route.ts
    │       ├── team/route.ts
    │       ├── team/[membershipId]/route.ts
    │       ├── webhooks/facebook/route.ts
    │       └── webhooks/zalo/route.ts
    ├── components/
    │   ├── ui/                           # (auto) shadcn
    │   ├── layout/
    │   │   ├── app-sidebar.tsx
    │   │   ├── app-header.tsx
    │   │   └── page-header.tsx
    │   ├── shared/
    │   │   ├── data-table.tsx
    │   │   ├── empty-state.tsx
    │   │   ├── error-state.tsx
    │   │   ├── loading-state.tsx
    │   │   ├── platform-badge.tsx
    │   │   ├── confirm-dialog.tsx
    │   │   ├── stat-card.tsx
    │   │   └── date-range-picker.tsx
    │   ├── channels/
    │   │   ├── channel-card.tsx
    │   │   └── connect-channel-dialog.tsx
    │   ├── trends/
    │   │   ├── trend-card.tsx
    │   │   └── trend-filters.tsx
    │   ├── content/
    │   │   ├── post-editor.tsx
    │   │   ├── variant-editor.tsx
    │   │   ├── media-uploader.tsx
    │   │   ├── ai-generate-dialog.tsx
    │   │   ├── schedule-dialog.tsx
    │   │   ├── post-status-badge.tsx
    │   │   └── post-table.tsx
    │   ├── calendar/
    │   │   └── calendar-grid.tsx
    │   ├── inbox/
    │   │   ├── interaction-list.tsx
    │   │   ├── interaction-detail.tsx
    │   │   ├── reply-composer.tsx
    │   │   ├── intent-badge.tsx
    │   │   └── inbox-filters.tsx
    │   ├── fans/
    │   │   ├── fan-table.tsx
    │   │   ├── fan-profile.tsx
    │   │   └── fan-tag-input.tsx
    │   ├── seeding/
    │   │   ├── campaign-form.tsx
    │   │   ├── campaign-table.tsx
    │   │   ├── target-form.tsx
    │   │   └── seeding-task-card.tsx
    │   ├── links/
    │   │   ├── link-form.tsx
    │   │   ├── link-table.tsx
    │   │   └── link-hub-editor.tsx
    │   ├── automations/
    │   │   ├── rule-form.tsx
    │   │   └── rule-card.tsx
    │   ├── analytics/
    │   │   ├── overview-cards.tsx
    │   │   ├── channel-compare-table.tsx
    │   │   ├── top-posts-table.tsx
    │   │   ├── growth-chart.tsx
    │   │   └── funnel-bars.tsx
    │   └── settings/
    │       ├── org-settings-form.tsx
    │       ├── ai-settings-form.tsx
    │       ├── telegram-settings-form.tsx
    │       ├── team-table.tsx
    │       ├── template-table.tsx
    │       ├── knowledge-table.tsx
    │       └── product-table.tsx
    └── __tests__/
        ├── setup.ts                      # import @testing-library/jest-dom/vitest
        ├── crypto.test.ts
        ├── slug.test.ts
        ├── time.test.ts
        ├── validations.test.ts
        ├── settings-provider.test.ts
        ├── rule-engine.test.ts
        ├── reply-policy.test.ts
        ├── fan-score.test.ts
        ├── link-service.test.ts
        ├── trend-service.test.ts
        ├── publish-service.test.ts
        ├── seeding-service.test.ts
        ├── analytics-service.test.ts
        ├── ai-client.test.ts
        ├── webhooks.test.ts
        └── adapters/
            ├── facebook.test.ts
            ├── instagram.test.ts
            ├── tiktok.test.ts
            ├── youtube.test.ts
            └── zalo.test.ts
```

---

## [7] Non-Functional Requirements

### Auth flow

- Auth.js v5, strategy `jwt`, session tối đa 30 ngày, làm mới token mỗi 24 giờ.
- Providers: `Credentials` (email + mật khẩu, bcrypt cost 12) và `Google`.
- JWT callback gắn `userId`; session callback gắn `session.user.id`. `orgId` và `role` KHÔNG đưa vào JWT; mỗi request server đọc `Membership` theo `userId` qua `getOrgContext()` (1 query, cache 60 giây trong bộ nhớ tiến trình theo `userId`).
- Đăng ký: `POST /api/auth/register` tạo `User` với `passwordHash`; sau đó client gọi `signIn("credentials")`.
- Sau đăng nhập, nếu user chưa có `Membership` → redirect `/onboarding`. `/onboarding` tạo `Organization` + `Membership` role `OWNER`. Tier B: khi org đầu tiên đã tồn tại trong hệ thống, `/onboarding` chỉ cho phép tạo org nếu `Organization.count() === 0`; ngược lại hiển thị thông báo yêu cầu OWNER mời vào team.
- `src/middleware.ts` matcher: `["/((?!api/auth|api/webhooks|l/|hub/|_next|favicon.ico|login|register).*)"]`. Chưa đăng nhập → redirect `/login?next=<path>`. Với `/api/*` → trả 401 JSON.

### Phân quyền (role → cho phép)

| Hành động | OWNER | MANAGER | EDITOR | SEEDER |
|---|---|---|---|---|
| Xem dashboard, analytics | ✓ | ✓ | ✓ | ✗ |
| Kết nối / gỡ kênh | ✓ | ✓ | ✗ | ✗ |
| Tạo / sửa bài, lên lịch | ✓ | ✓ | ✓ | ✗ |
| Đăng ngay (`publish`) | ✓ | ✓ | ✗ | ✗ |
| Xóa bài | ✓ | ✓ | ✗ | ✗ |
| Inbox: xem, trả lời | ✓ | ✓ | ✓ | ✗ |
| Inbox: giải quyết ESCALATED | ✓ | ✓ | ✗ | ✗ |
| Fans: xem, gắn tag | ✓ | ✓ | ✓ | ✗ |
| Fans: gửi tin Zalo | ✓ | ✓ | ✗ | ✗ |
| Seeding: tạo campaign, target, giao việc | ✓ | ✓ | ✗ | ✗ |
| Seeding: xem và hoàn thành task được giao | ✓ | ✓ | ✓ | ✓ |
| Links / Hub | ✓ | ✓ | ✓ | ✗ |
| Automations | ✓ | ✓ | ✗ | ✗ |
| Settings: org, AI, Telegram | ✓ | ✓ | ✗ | ✗ |
| Settings: templates, knowledge, products | ✓ | ✓ | ✓ | ✗ |
| Team: mời, đổi role, xóa | ✓ | ✗ | ✗ | ✗ |
| Đổi role của OWNER | ✗ | ✗ | ✗ | ✗ |

Vi phạm → HTTP 403 `{ error: { code: "FORBIDDEN", message: "Bạn không có quyền thực hiện thao tác này." } }`.

### Bảo mật

- Mọi input qua Zod trước khi chạm DB. Sai → 400 `VALIDATION_ERROR` kèm `details` (mảng `{ path, message }`).
- Token nền tảng mã hóa AES-256-GCM (`src/lib/crypto.ts`), format lưu: `<iv_hex>:<tag_hex>:<cipher_hex>`. Không bao giờ trả token về client; API `GET /api/social-accounts` chỉ trả `tokenExpiresAt`.
- Rate limit: middleware in-memory theo IP cho `/api/auth/register` và `/api/auth/callback/credentials`: 10 request / 15 phút → 429 `RATE_LIMITED`. Tier B không cần rate limit per user cho API còn lại.
- Webhook Facebook: xác minh `X-Hub-Signature-256` bằng HMAC-SHA256 với `META_APP_SECRET`; sai → 401. Webhook Zalo: xác minh header `X-ZEvent-Signature` theo tài liệu Zalo OA v3 với `ZALO_OA_SECRET_KEY`; sai → 401.
- CORS: mặc định same-origin; route `/api/webhooks/*` không cần CORS vì là server-to-server.
- Multi-tenant: mọi truy vấn Prisma trong service nhận `orgId` làm tham số đầu tiên và luôn có `where: { orgId }`. Route `[id]` phải kiểm tra bản ghi thuộc `orgId` → không thuộc trả 404 `NOT_FOUND`, không trả 403.
- Không hardcode tên shop, ID Page, tài khoản vào code. Tất cả là dữ liệu trong DB hoặc env.
- Short link `/l/[slug]` chỉ redirect tới `targetUrl` có scheme `https://` hoặc `http://`; chặn `javascript:` và `data:` ở Zod schema.
- Nội dung do AI sinh ra không được gửi tự động nếu `AutoReplyMode !== "AUTO_SAFE"` (xem `reply-service.ts` trong `03-ui.md` mục [6]).

### Logging

- pino, JSON một dòng, level từ `LOG_LEVEL`. Dev dùng `pino-pretty` qua transport khi `NODE_ENV=development`.
- Trường bắt buộc mỗi log: `ts`, `level`, `msg`, `orgId` (nếu có), `reqId` (nanoid 10 ký tự sinh trong `apiHandler`), `jobId` (trong worker).
- API log 1 dòng khi kết thúc request: `{ method, path, status, durationMs }`.
- Worker log khi job start / complete / fail với `queue`, `jobName`, `attemptsMade`.
- Không log token, mật khẩu, nội dung tin nhắn khách (chỉ log `interactionId`).

### Performance target

- LCP trang `/dashboard` ≤ 2,5 giây trên mạng 4G mô phỏng.
- API p95 ≤ 500 ms cho route đọc; ≤ 1.500 ms cho route ghi không gọi AI.
- Route gọi AI (`/api/posts/generate`, `/api/inbox/[id]/draft`, `/api/trends/[id]/ideas`): timeout 60 giây, `maxDuration = 60` khai báo trong route.
- Inbox list: phân trang 50 bản ghi / trang, index trên `(orgId, status, receivedAt)`.
- Worker: job `publish-post` retry 3 lần, backoff exponential bắt đầu 30 giây; `sync-*` retry 2 lần.

### Accessibility

- Mọi nút icon có `aria-label`.
- Form dùng `<Label htmlFor>`; lỗi validation hiển thị bằng `aria-describedby`.
- Điều hướng bàn phím: Tab đi qua sidebar → nội dung chính; Dialog trap focus (shadcn mặc định).
- Contrast tối thiểu 4.5:1 cho text.

### i18n

- Mọi chuỗi UI trong `src/i18n/vi.json`, key dạng `namespace.key` (`inbox.empty.title`). `t(key, params)` trong `src/lib/i18n.ts` thay `{name}` bằng `params.name`. Key thiếu → trả về chính key và log warn.
- Nội dung do AI sinh và dữ liệu nền tảng không qua i18n.

### Deploy

| Thành phần | Nơi deploy | Ghi chú |
|---|---|---|
| Web (Next.js) | Vercel | Build command `pnpm build`; `prisma migrate deploy` chạy trong bước build qua script `vercel-build` = `prisma migrate deploy && prisma generate && next build` |
| Worker | Railway (service Node 22) | Start command `pnpm worker`; scale 1 instance khi `WORKER_ENABLE_CRON=true` |
| PostgreSQL | Neon (managed) | Region Singapore |
| Redis | Upstash | Region Singapore, TLS |
| Blob | Vercel Blob | Cùng project Vercel |

Biến env production = toàn bộ biến trong `.env.example` với giá trị thật; `NEXT_PUBLIC_APP_URL` là domain thật; `AUTH_TRUST_HOST=true`; `NODE_ENV=production`.

Webhook URL đăng ký với nền tảng:
- Meta: `{NEXT_PUBLIC_APP_URL}/api/webhooks/facebook` (subscriptions: `feed`, `messages` cho Page; `comments` cho Instagram).
- Zalo OA: `{NEXT_PUBLIC_APP_URL}/api/webhooks/zalo`.

---

## [10] CLAUDE.md của project đích

Nội dung đầy đủ file `CLAUDE.md` đặt tại root `social-growth-hub/`:

```markdown
# CLAUDE.md — social-growth-hub

## Project
Hệ thống vận hành mạng xã hội cho team bán hàng: kết nối kênh (Facebook Page, Instagram, TikTok, YouTube, Zalo OA), trend radar, sinh và lên lịch nội dung bằng AI, seeding bán tự động, inbox hợp nhất có AI trả lời, CRM fan, short link + bio hub, automation rules, analytics.

Spec đầy đủ trong `spec/` — đọc file được chỉ định cho từng phase trong `spec/05-phases.md`. Không tự sửa spec; nếu spec mâu thuẫn hoặc thiếu, dừng và báo cáo.

## Stack
Next.js 15 App Router · TypeScript strict · Tailwind + shadcn/ui · Prisma + PostgreSQL · Auth.js v5 · TanStack Query · Zustand · Zod · BullMQ + Redis · @anthropic-ai/sdk · Vercel Blob · pino · Vitest + Playwright · pnpm.

## Lệnh
- `pnpm dev` — web dev server
- `pnpm worker:dev` — worker (BullMQ) dev
- `pnpm typecheck` — tsc cho web + worker
- `pnpm lint` — ESLint
- `pnpm test` — Vitest
- `pnpm test:e2e` — Playwright
- `pnpm db:migrate` — Prisma migrate dev
- `pnpm db:seed` — seed dữ liệu mẫu

## Quy tắc
- Luôn chạy `pnpm typecheck && pnpm lint && pnpm test` trước khi commit. Commit message theo Conventional Commits, tiếng Anh.
- Code, identifier, comment: tiếng Anh. Chuỗi UI: tiếng Việt, đặt trong `src/i18n/vi.json`, dùng `t()`.
- Mọi truy vấn Prisma trên bảng nghiệp vụ phải có `where: { orgId }`. Không bao giờ truy vấn theo `id` đơn lẻ mà thiếu `orgId`.
- Không hardcode tên shop, ID Page, token, tài khoản. Tất cả từ DB hoặc env.
- Token nền tảng chỉ đi qua `encryptSecret` / `decryptSecret`; không log, không trả về client.
- Gọi AI chỉ qua `src/lib/ai/client.ts`. Không tạo client Anthropic ở nơi khác.
- Gọi nền tảng chỉ qua adapter trong `src/lib/platforms/`. Không `fetch` trực tiếp tới graph.facebook.com / open.tiktokapis.com / googleapis / openapi.zalo.me ở nơi khác.
- Không dùng browser automation (Playwright, Puppeteer) để thao tác lên mạng xã hội. Playwright chỉ dùng cho e2e test của chính app.
- Không tạo tài khoản ảo, không mua tương tác, không cold DM.

## File cấm sửa sau khi tạo
- `prisma/migrations/**` (chỉ thêm migration mới bằng `pnpm db:migrate`)
- `src/components/ui/**` (shadcn sinh; muốn đổi thì thêm component riêng)
- `src/i18n/vi.json` chỉ được THÊM key, không đổi tên key đã có

## Spec
- `spec/00-overview.md` — tier, assumptions, out of scope, stack, cấu trúc, NFR
- `spec/01-data.md` — schema, types, store, seed
- `spec/02-api.md` — API contracts
- `spec/03-ui.md` — routes, flows, states, components, services
- `spec/04-tests.md` — acceptance tests
- `spec/05-phases.md` — lộ trình phase + lệnh verify
```
