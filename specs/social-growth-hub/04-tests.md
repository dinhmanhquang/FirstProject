# Social Growth Hub — 04 Acceptance Tests

Đọc kèm: `02-api.md`, `03-ui.md` (mục 6.7 services).

---

## [8] Acceptance Tests

Quy ước:
- **Unit** = Vitest, file trong `src/__tests__/`. DB dùng Prisma với `DATABASE_URL` trỏ tới database test `social_growth_hub_test` (script `pnpm test` chạy `prisma migrate deploy` trước qua `globalSetup` trong `vitest.config.ts`). Mỗi test file tạo org riêng bằng `createTestOrg()` trong `src/__tests__/setup.ts` và xóa sau `afterAll`.
- Gọi nền tảng và AI trong unit test được mock bằng `vi.mock("@/lib/platforms/registry")` và `vi.mock("@/lib/ai/client")`.
- **E2E** = Playwright, file trong `e2e/`, chạy trên DB đã seed (`pnpm db:seed`), đăng nhập bằng `owner@demo.local / Password123!`. E2E chỉ cho happy path.
- Mỗi test case ghi ID `T-<nhóm>-<số>`; agent đặt tên `it()` bắt đầu bằng ID đó.

### 8.1 Crypto & utils — unit (`crypto.test.ts`, `slug.test.ts`, `time.test.ts`)

- **T-UTIL-01** Given `TOKEN_ENCRYPTION_KEY` hợp lệ, When `encryptSecret("abc")` rồi `decryptSecret`, Then trả `"abc"` và chuỗi mã hóa có đúng 3 phần phân cách `:`.
- **T-UTIL-02** Given chuỗi mã hóa bị sửa 1 ký tự ở phần cipher, When `decryptSecret`, Then throw `Error("DECRYPT_FAILED")`.
- **T-UTIL-03** Given `"Đèn ngủ LED cảm ứng!!"`, When `toSlug`, Then `"den-ngu-led-cam-ung"`.
- **T-UTIL-04** Given `"2026-09-29"`, When `startOfDayVN`, Then ISO = `"2026-09-28T17:00:00.000Z"`.
- **T-UTIL-05** Given `199000`, When `formatVnd`, Then `"199.000đ"`.

### 8.2 Validations — unit (`validations.test.ts`)

- **T-VAL-01** Given body `createPostSchema` với `hashtags: ["#tết2027", "decor"]`, When parse, Then pass.
- **T-VAL-02** Given `hashtags: ["bad tag"]`, When parse, Then fail với `path = "variants.0.hashtags.0"`.
- **T-VAL-03** Given `createLinkSchema` với `targetUrl: "javascript:alert(1)"`, When parse, Then fail.
- **T-VAL-04** Given `ruleSchema` với trigger `TREND_RELEVANT` và action `REPLY_TEMPLATE`, When gọi validator trong `POST /api/rules` (hàm `validateRuleCompatibility`), Then trả lỗi message chứa `"REPLY_TEMPLATE"`.

### 8.3 Settings provider — unit (`settings-provider.test.ts`)

- **T-SET-01** Given org không có `Setting`, When `get(orgId, "ai.autoReplyMode")`, Then `"DRAFT_ONLY"`.
- **T-SET-02** Given `set(orgId, "ai.dailyCallLimit", 5)`, When `get` ngay sau đó, Then `5` (cache đã bị xóa).

### 8.4 Auth & org — e2e (`auth.spec.ts`) + unit

- **T-AUTH-01 (e2e)** Given DB trống user `new@demo.local`, When đăng ký qua `/register` rồi đăng nhập, Then chuyển tới `/onboarding` và hiển thị "Hệ thống đã có tổ chức, hãy nhờ chủ sở hữu mời bạn." (vì seed đã có org).
- **T-AUTH-02 (e2e)** Given user `owner@demo.local`, When đăng nhập, Then chuyển tới `/dashboard` và sidebar hiện "Tổng quan".
- **T-AUTH-03 (unit)** Given `requireRole(ctx role EDITOR, "MANAGER")`, When gọi, Then throw `ApiError` status 403 code `FORBIDDEN`.
- **T-AUTH-04 (unit)** Given user `seeder@demo.local` gọi `GET /api/analytics/overview`, When apiHandler chạy, Then 403.

### 8.5 Channels — unit (`adapters/*.test.ts`, mock `fetch`)

- **T-CH-01** Given Facebook `exchangeCode` trả 2 Page, When callback xử lý, Then tạo 2 `SocialAccount` FACEBOOK_PAGE với token đã mã hóa (không bằng token gốc).
- **T-CH-02** Given Graph API trả `{ error: { code: 190 } }`, When `FacebookPageAdapter.publish`, Then throw `PlatformError` code `TOKEN_EXPIRED`, `retryable = false`.
- **T-CH-03** Given `fetch` trả 500, When `YouTubeAdapter.fetchPostMetrics`, Then `PlatformError.retryable === true`.
- **T-CH-04** Given `TikTokAdapter`, When `replyToInteraction`, Then throw `PlatformError` code `NOT_SUPPORTED`.
- **T-CH-05** Given webhook body Facebook comment `verb: "add"` từ user khác Page, When `parseWebhook`, Then trả 1 `NormalizedInteraction` type COMMENT với `externalPostId` đúng.
- **T-CH-06** Given webhook body comment có `from.id === pageId`, When `parseWebhook`, Then trả `[]`.
- **T-CH-07** Given Zalo event `user_send_text`, When `ZaloOaAdapter.parseWebhook`, Then 1 interaction type MESSAGE, `fromUserId = sender.id`.
- **T-CH-08** Given Instagram container poll trả `IN_PROGRESS` 2 lần rồi `FINISHED`, When `publish`, Then gọi `media_publish` đúng 1 lần.

### 8.6 Posts — unit (`publish-service.test.ts`) + e2e (`post-flow.spec.ts`)

- **T-POST-01 (unit)** Given variant TIKTOK không có media, When `validateVariants`, Then có lỗi `"TIKTOK yêu cầu ít nhất 1 ảnh hoặc video."`.
- **T-POST-02 (unit)** Given variant INSTAGRAM content 2.201 ký tự, When `validateVariants`, Then lỗi `"Nội dung vượt 2200 ký tự cho INSTAGRAM."`.
- **T-POST-03 (unit)** Given post 2 variant, adapter FB thành công, adapter YT throw retryable, When `publishPost`, Then Post `PARTIALLY_FAILED`, variant FB `PUBLISHED` có `externalPostId`, variant YT `FAILED` `attempts = 1`.
- **T-POST-04 (unit)** Given post có `ctaLinkId` và variant FACEBOOK_PAGE thành công, When `publishPost`, Then `replyToInteraction` được gọi với content chứa `/l/<slug>?src=facebook_page`.
- **T-POST-05 (unit)** Given `schedulePost` với `scheduledAt = now + 1 phút`, When gọi, Then throw `ApiError` 400 message `"Thời gian đăng phải sau hiện tại ít nhất 2 phút."`.
- **T-POST-06 (unit)** Given post SCHEDULED, When `updatePost`, Then status về `DRAFT` và `enqueuePublish` job cũ bị remove (mock `queue.remove` gọi với `"publish:"+postId`).
- **T-POST-07 (e2e)** Given đăng nhập owner, When vào `/content/new`, nhập tiêu đề "E2E bài test", nội dung, chọn kênh "Demo Shop Page", bấm "Lưu nháp", Then chuyển tới `/content/<id>` và badge "Nháp".
- **T-POST-08 (e2e)** Given bài nháp ở T-POST-07, When bấm "Lên lịch", chọn ngày mai 20:00, xác nhận, Then toast "Đã lên lịch đăng." — bài xuất hiện ở `/calendar` đúng ngày.

### 8.7 AI generate — unit (mock `generateStructured`)

- **T-AI-01** Given mock trả 2 variant FB + TT, When `generatePostVariants(platforms [FB, TT])`, Then trả 2 phần tử đúng platform và `AiUsage` được ghi 1 dòng `purpose = "generate_post"`.
- **T-AI-02** Given `AiUsage` hôm nay = `ai.dailyCallLimit`, When `generateStructured`, Then throw `ApiError` 429 `AI_QUOTA_EXCEEDED` và không gọi Anthropic.
- **T-AI-03** Given Anthropic trả `stop_reason: "refusal"`, When `generateStructured`, Then `ApiError` 502 `AI_ERROR` message `"AI từ chối yêu cầu này."`.
- **T-AI-04** Given lần 1 trả JSON hỏng, lần 2 hợp lệ, When `generateStructured`, Then trả kết quả lần 2 và Anthropic được gọi đúng 2 lần.

### 8.8 Inbox & auto-reply — unit (`reply-policy.test.ts`) + e2e (`inbox-flow.spec.ts`)

- **T-INB-01** Given `upsertInteraction` 2 lần cùng `externalId`, When gọi, Then chỉ 1 `Interaction`, lần 2 `created = false`, `Fan.commentCount = 1`.
- **T-INB-02** Given mode `AUTO_SAFE`, intent `PRICE_ASK`, sentiment `NEUTRAL`, confidence 0.9, `capabilityOk`, When `decideAutoReply`, Then `{ action: "SEND", reason: "auto_safe" }`.
- **T-INB-03** Given mode `AUTO_SAFE`, intent `COMPLAINT`, escalate true, When `decideAutoReply`, Then `action: "DRAFT"`, `reason: "escalated"`.
- **T-INB-04** Given mode `DRAFT_ONLY`, intent `PRAISE`, confidence 0.99, When `decideAutoReply`, Then `action: "DRAFT"`, `reason: "draft_only"`.
- **T-INB-05** Given intent `SPAM`, mọi mode, When `decideAutoReply`, Then `SKIP`.
- **T-INB-06** Given `capabilityOk = false` (TikTok), When `decideAutoReply`, Then `DRAFT`, `reason: "platform_cannot_reply"`.
- **T-INB-07** Given template "Hỏi giá" keywords `["giá"]`, content `"Cái này GIÁ bao nhiêu"`, When `matchTemplate`, Then trả template đó; When `renderTemplate(content, { name: "Anh", shop: "Demo Shop" })`, Then thay đúng 2 biến.
- **T-INB-08** Given processor `classify-and-reply` với classification escalate true, When chạy, Then interaction `ESCALATED`, `sendTelegram` gọi 1 lần với text bắt đầu `"🚨 Cần xử lý"`.
- **T-INB-09** Given `sendReply` và adapter throw, When gọi, Then `Reply.status = FAILED`, interaction giữ `OPEN`, hàm throw `PlatformError`.
- **T-INB-10 (e2e)** Given seed có interaction OPEN "Decal này giá bao nhiêu ạ?", When vào `/inbox`, chọn nó, nhập "Dạ 89.000đ bạn nhé", bấm "Gửi" (adapter mock ở env test trả thành công qua `PLATFORM_MOCK=true`), Then interaction chuyển tab "Đã trả lời" và toast "Đã gửi trả lời.".

`PLATFORM_MOCK=true` (chỉ `NODE_ENV=test`): `registry.getAdapter` trả `MockAdapter` (file `src/lib/platforms/mock.ts`, thêm vào cây thư mục ở phase 6) — mọi hàm trả kết quả giả thành công.

### 8.9 Fans — unit (`fan-score.test.ts`)

- **T-FAN-01** Given `commentCount 5, messageCount 2, lastSeenAt = now − 3 ngày`, When `computeScore`, Then `16`.
- **T-FAN-02** Given cùng số nhưng `lastSeenAt = now − 40 ngày`, When `computeScore`, Then `8`.
- **T-FAN-03** Given fan score 25 chưa có tag, When `recalcAllScores`, Then `tags` chứa `"super_fan"`; fan score 4 có tag `super_fan` → tag bị bỏ, tag khác giữ nguyên.
- **T-FAN-04** Given fan FACEBOOK_PAGE `lastSeenAt = now − 2 ngày`, When `messageFan`, Then throw `ApiError` 422.

### 8.10 Links & Hub — unit (`link-service.test.ts`)

- **T-LNK-01** Given link không slug, When `createLink`, Then slug 6 ký tự `[a-z0-9]`.
- **T-LNK-02** Given link slug `"abc"` đã có, When `createLink` cùng slug, Then `ApiError` 409.
- **T-LNK-03** Given link `utmSource: "tiktok"`, targetUrl `https://x.com/p?a=1`, When `buildTargetUrl`, Then `https://x.com/p?a=1&utm_source=tiktok`.
- **T-LNK-04** Given referer `https://m.facebook.com/...`, src null, When `detectPlatformHint`, Then `FACEBOOK_PAGE`; Given src `"tiktok"`, Then `TIKTOK` (src ưu tiên).
- **T-LNK-05** Given `recordClick` với `taskId`, When gọi, Then `Link.clickCount + 1`, `SeedingTask.clickCount + 1`, `LinkClick.ipHash` có 16 ký tự.
- **T-LNK-06** Given `GET /l/<slug-xoa>` (link soft-deleted), When request, Then 404.

### 8.11 Trends — unit (`trend-service.test.ts`, mock `fetch` + `scoreTrends`)

- **T-TR-01** Given RSS Google Trends 3 item, When collector `GOOGLE_TRENDS.collect`, Then 3 trend với `rawScore` số nguyên.
- **T-TR-02** Given trend đã tồn tại `status USED`, When `collectTrends` gặp lại cùng `externalKey`, Then `status` vẫn `USED`, `relevanceScore` không bị ghi đè.
- **T-TR-03** Given `scoreTrends` trả score 85 và `minRelevanceToNotify 70`, When `collectTrends`, Then `enqueueRunRules` gọi với event `TREND_RELEVANT` và `sendTelegram` gọi 1 lần.
- **T-TR-04** Given thiếu `YOUTUBE_API_KEY`, When `YOUTUBE_POPULAR.collect`, Then trả `[]` không throw.

### 8.12 Seeding — unit (`seeding-service.test.ts`)

- **T-SD-01** Given campaign 3 target, `ctaLinkId` có, When `createTasks({ postId })`, Then 3 task TODO, mỗi task có `linkId` riêng với `utmMedium = "seeding"`, `enqueueSeedingGenerate` gọi với 3 taskIds.
- **T-SD-02** Given đã có task TODO cho `(target, postId)`, When `createTasks` lại, Then `created = 0`.
- **T-SD-03** Given viewer SEEDER không phải assignee, When `updateTask`, Then `ApiError` 404.
- **T-SD-04** Given `generateSeedingVariants` mock trả content chứa `"{link}"`, When processor `seeding-generate` chạy, Then `task.content` chứa `/l/<slug>?t=<taskId>` và không còn `"{link}"`.
- **T-SD-05** Given `updateTask({ status: "DONE", proofUrl })`, When gọi, Then `doneAt` khác null.

### 8.13 Rule engine — unit (`rule-engine.test.ts`)

- **T-RULE-01** Given rule `NEW_COMMENT platforms [FACEBOOK_PAGE]`, event platform TIKTOK, When `matchesTrigger`, Then false.
- **T-RULE-02** Given condition `content contains_any ["giá"]`, event content `"GIÁ bao nhiêu"`, When `matchesConditions`, Then true (không phân biệt hoa thường, dấu).
- **T-RULE-03** Given rule 2 action `[REPLY_TEMPLATE, TAG_FAN]`, `sendReply` throw, When `runActions`, Then log action 1 `ok false`, action 2 vẫn chạy `ok true`, `RuleRun` được ghi.
- **T-RULE-04** Given đã có `RuleRun(ruleId, eventType, refId)`, When `evaluateRules` cùng event, Then rule không chạy lại.
- **T-RULE-05** Given rule `POST_ENGAGEMENT_THRESHOLD likes gte 100`, event metric likes 120, action `PIN_CTA_COMMENT`, When `runActions`, Then adapter FB `replyToInteraction` gọi 1 lần.

### 8.14 Analytics — unit (`analytics-service.test.ts`)

- **T-AN-01** Given 2 kênh với snapshot ngày `from` (100, 50) và ngày `to` (130, 60), When `overview`, Then `followersTotal 190`, `followersDelta 40`.
- **T-AN-02** Given 2 interaction có reply SENT sau 5 và 15 phút, 1 interaction chưa reply, When `overview`, Then `avgFirstResponseMinutes = 10`.
- **T-AN-03** Given snapshot `engagements 50`, `reach 0`, When `byChannel`, Then `engagementRate = 0`.
- **T-AN-04** Given 3 LinkClick, 1 có referer chứa `/hub/`, When `funnel`, Then `linkClicks 3`, `hubClicks 1`.

### 8.15 Webhooks — unit (test route handler trực tiếp)

- **T-WH-01** Given `GET /api/webhooks/facebook?hub.mode=subscribe&hub.verify_token=<đúng>&hub.challenge=123`, When gọi, Then 200 body `"123"`.
- **T-WH-02** Given `POST /api/webhooks/facebook` với chữ ký sai, When gọi, Then 401 và không tạo interaction.
- **T-WH-03** Given chữ ký đúng, body 1 comment cho Page ACTIVE, When gọi, Then 200, 1 `Interaction`, `enqueueClassifyAndReply` gọi 1 lần.
- **T-WH-04** Given Zalo `follow` event, When `POST /api/webhooks/zalo`, Then `Fan.canMessage = true`.
