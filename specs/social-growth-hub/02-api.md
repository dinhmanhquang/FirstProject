# Social Growth Hub — 02 API Contracts

Đọc kèm: `00-overview.md` (mục [7] phân quyền), `01-data.md` (types).

---

## [4] API Contracts

### 4.1 Quy ước chung

- Base path: `/api`. Route handler Next.js App Router, mọi handler bọc bởi `apiHandler()` trong `src/lib/api.ts`.
- Auth: mọi route yêu cầu session trừ nhóm `auth/*`, `webhooks/*`. Cột **Role** ghi role tối thiểu theo bảng phân quyền mục [7]; `*` = mọi role.
- Request body: JSON, validate bằng Zod schema ghi tên trong bảng (file `src/lib/validations/*`).
- Pagination: query `?page=1&limit=20` (limit 1–100, mặc định 20), response `{ data: T[], meta: { page, limit, total, totalPages } }`.
- Timestamp: ISO 8601 UTC. ID: cuid.
- Response thành công: `200` với body JSON; tạo mới: `201`; xóa: `204` không body.
- Lỗi: `{ error: { code, message, details? } }`. Bảng lỗi chung áp dụng cho mọi route:

| HTTP | code | message (tiếng Việt) |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Dữ liệu không hợp lệ. (kèm `details`) |
| 401 | `UNAUTHORIZED` | Bạn cần đăng nhập để tiếp tục. |
| 403 | `FORBIDDEN` | Bạn không có quyền thực hiện thao tác này. |
| 404 | `NOT_FOUND` | Không tìm thấy dữ liệu. |
| 409 | `CONFLICT` | Dữ liệu đã tồn tại. |
| 422 | `INVALID_STATE` | Trạng thái hiện tại không cho phép thao tác này. |
| 429 | `RATE_LIMITED` | Bạn thao tác quá nhanh, thử lại sau ít phút. |
| 429 | `AI_QUOTA_EXCEEDED` | Đã hết hạn mức AI trong ngày. |
| 502 | `PLATFORM_ERROR` | Nền tảng trả về lỗi: {detail} |
| 502 | `AI_ERROR` | Dịch vụ AI tạm thời lỗi, thử lại sau. |
| 500 | `INTERNAL_ERROR` | Có lỗi xảy ra, đội kỹ thuật đã được thông báo. |

Bảng lỗi từng route dưới đây chỉ ghi lỗi **ngoài** bảng chung.

`apiHandler(handler, { role?: Role })`: sinh `reqId`, gọi `getOrgContext()` (nếu route cần auth), kiểm tra role, bắt `ZodError` → 400, `ApiError` → mã tương ứng, `PlatformError` → 502, lỗi khác → 500 + log error.

### 4.2 Auth

#### POST `/api/auth/register` — không auth

Schema `registerSchema`:
```ts
z.object({
  name: z.string().min(2).max(60),
  email: z.string().email(),
  password: z.string().min(8).max(72).regex(/[A-Z]/).regex(/[0-9]/),
})
```
Response 201: `{ id: string, email: string }`.
Lỗi: 409 `CONFLICT` "Email đã được sử dụng."; 429 `RATE_LIMITED`.

#### `/api/auth/[...nextauth]` — Auth.js handlers (GET, POST), sinh bởi `src/auth.ts`.

### 4.3 Organization

#### GET `/api/org` — Role `*`
Response 200:
```json
{ "id": "...", "name": "Demo Shop", "slug": "demo-shop", "niche": "...", "plan": "INTERNAL", "membership": { "id": "...", "role": "OWNER" }, "memberCount": 4 }
```

#### POST `/api/org` — auth, chưa có membership
Schema `onboardingSchema`: `z.object({ name: z.string().min(2).max(80), niche: z.string().max(500).default("") })`.
Tạo `Organization` (slug = `toSlug(name)`, thêm hậu tố `-<nanoid4>` nếu trùng) + `Membership` role `OWNER`.
Response 201: như GET.
Lỗi: 409 `CONFLICT` "Bạn đã thuộc một tổ chức."; 422 `INVALID_STATE` "Hệ thống đã có tổ chức, hãy nhờ chủ sở hữu mời bạn." (khi `Organization.count() > 0`).

#### PATCH `/api/org` — Role `MANAGER`
Schema `orgSettingsSchema`: `z.object({ name: z.string().min(2).max(80).optional(), niche: z.string().max(500).optional() })`.
Response 200: như GET.

### 4.4 Social accounts (kênh)

#### GET `/api/social-accounts` — Role `*`
Response 200:
```json
{ "data": [ { "id": "...", "platform": "FACEBOOK_PAGE", "externalId": "...", "name": "...", "avatarUrl": null, "status": "ACTIVE", "tokenExpiresAt": "...", "lastSyncedAt": "...", "lastError": null, "capabilities": ["PUBLISH_TEXT", "..."] } ] }
```
Không phân trang (≤ 50 kênh / org).

#### GET `/api/social-accounts/connect/[platform]` — Role `MANAGER`
`platform` ∈ enum Platform (lowercase trong URL: `facebook_page`, `instagram`, `tiktok`, `youtube`, `zalo_oa`).
Sinh `state` = nanoid 24 lưu vào cookie `sgh_oauth_state` (httpOnly, 10 phút, value = `<state>:<orgId>:<platform>`), redirect 302 tới URL OAuth do `buildAuthUrl(platform, state)` trả về.
Lỗi: 400 `VALIDATION_ERROR` "Nền tảng không hỗ trợ."

#### GET `/api/social-accounts/callback/[platform]` — Role `MANAGER`
Query: `code`, `state`. Kiểm tra `state` khớp cookie. Gọi `exchangeCode(platform, code)` → danh sách tài khoản (Facebook trả nhiều Page; Instagram lấy IG Business gắn Page; các nền tảng khác trả 1). Upsert `SocialAccount` theo `(orgId, platform, externalId)`, token mã hóa, `status: ACTIVE`. Với Facebook Page: gọi `POST /{pageId}/subscribed_apps` với `subscribed_fields=feed,messages`.
Redirect 302 `/channels?connected=<count>`; lỗi → `/channels?error=<code>`.
Lỗi (query `error`): `state_mismatch`, `exchange_failed`, `no_accounts`.

#### DELETE `/api/social-accounts/[id]` — Role `MANAGER`
Đặt `status: DISCONNECTED`, xóa `accessTokenEnc` = chuỗi rỗng mã hóa. Không xóa bản ghi (giữ lịch sử variant / interaction).
Response 204.

#### POST `/api/social-accounts/[id]/sync` — Role `MANAGER`
Enqueue job `sync-interactions` và `sync-insights` cho kênh này.
Response 202: `{ "queued": true }`.
Lỗi: 422 `INVALID_STATE` "Kênh chưa kết nối." khi status ≠ ACTIVE.

### 4.5 Media

#### POST `/api/media` — Role `EDITOR` — `multipart/form-data`
Field `file`. Giới hạn: IMAGE ≤ 10 MB (`image/jpeg`, `image/png`, `image/webp`); VIDEO ≤ 500 MB (`video/mp4`, `video/quicktime`). Upload lên Vercel Blob với pathname `orgs/<orgId>/media/<cuid>.<ext>`, `access: "public"`.
Response 201: `{ "id", "type", "url", "mimeType", "sizeBytes", "width", "height", "durationSec" }` (width/height/durationSec `null` nếu không đọc được).
Lỗi: 400 `VALIDATION_ERROR` "Định dạng tệp không hỗ trợ." / "Tệp vượt quá dung lượng cho phép."

#### GET `/api/media` — Role `*` — `?page&limit&type`
Response 200: `Paginated<Media>` sắp xếp `createdAt desc`.

#### DELETE `/api/media/[id]` — Role `EDITOR`
Xóa blob + bản ghi. Lỗi: 422 `INVALID_STATE` "Tệp đang được dùng trong bài viết." nếu `id` xuất hiện trong `Post.mediaIds` hoặc `PostVariant.mediaIds` của bài chưa xóa.

### 4.6 Posts

#### GET `/api/posts` — Role `*`
Query `listPostsSchema`: `page`, `limit`, `status?: PostStatus`, `from?: ISO`, `to?: ISO` (lọc theo `scheduledAt` hoặc `publishedAt`), `search?: string(max 100)`.
Response 200: `Paginated<PostListItem>`:
```json
{ "id", "title", "status", "scheduledAt", "publishedAt", "platforms": ["FACEBOOK_PAGE"], "variantCount": 2, "createdBy": { "id", "name" }, "createdAt" }
```

#### POST `/api/posts` — Role `EDITOR`
Schema `createPostSchema`:
```ts
z.object({
  title: z.string().min(1).max(120),
  baseContent: z.string().min(1).max(5000),
  mediaIds: z.array(cuidSchema).max(10).default([]),
  ctaLinkId: cuidSchema.nullable().default(null),
  trendId: cuidSchema.nullable().default(null),
  campaignId: cuidSchema.nullable().default(null),
  variants: z.array(z.object({
    socialAccountId: cuidSchema,
    content: z.string().min(1),
    hashtags: z.array(z.string().regex(/^#?[\p{L}\p{N}_]+$/u)).max(30).default([]),
    title: z.string().max(100).nullable().default(null),
    mediaIds: z.array(cuidSchema).max(35).default([]),
  })).min(1),
})
```
Kiểm tra bổ sung trong `post-service.ts`: mỗi variant `content.length ≤ PLATFORM_LIMITS[platform].maxChars`, `hashtags.length ≤ maxHashtags`, `mediaIds.length ≤ maxMedia`; TikTok / YouTube / Instagram bắt buộc ≥ 1 media; YouTube bắt buộc `title`. Sai → 400 `VALIDATION_ERROR` với `details[].path = "variants[i].content"` và message `"Nội dung vượt {max} ký tự cho {platform}."`.
Response 201: `PostDetail` (xem GET `[id]`).

#### POST `/api/posts/generate` — Role `EDITOR` — `maxDuration = 60`
Schema `generatePostSchema`:
```ts
z.object({
  brief: z.string().min(10).max(2000),
  platforms: z.array(z.nativeEnum(Platform)).min(1),
  tone: z.enum(["FRIENDLY", "TRENDY", "PROFESSIONAL", "URGENT"]).default("FRIENDLY"),
  productIds: z.array(cuidSchema).max(3).default([]),
  trendId: cuidSchema.nullable().default(null),
  ctaLinkId: cuidSchema.nullable().default(null),
  includeHashtags: z.boolean().default(true),
})
```
Gọi `generatePostVariants()`. Response 200: `{ "variants": GeneratedVariant[] }` (1 phần tử / platform).
Lỗi: 429 `AI_QUOTA_EXCEEDED`; 502 `AI_ERROR`.

#### GET `/api/posts/[id]` — Role `*`
Response 200 `PostDetail`:
```json
{
  "id", "title", "baseContent", "mediaIds", "media": [Media], "status", "scheduledAt", "publishedAt",
  "trend": { "id", "title" } | null, "campaign": { "id", "name" } | null, "ctaLink": { "id", "slug", "targetUrl" } | null,
  "createdBy": { "id", "name" },
  "variants": [ { "id", "socialAccountId", "platform", "accountName", "content", "hashtags", "title", "mediaIds", "status", "externalUrl", "errorMessage", "publishedAt", "metrics": { "likes", "comments", "shares", "views", "reach", "capturedAt" } | null } ],
  "createdAt", "updatedAt"
}
```

#### PATCH `/api/posts/[id]` — Role `EDITOR`
Schema `updatePostSchema` = `createPostSchema.partial()` với `variants` là mảng đầy đủ (thay thế toàn bộ variants: xóa variant không còn, upsert theo `socialAccountId`).
Chỉ cho phép khi `status ∈ {DRAFT, SCHEDULED, FAILED}`; SCHEDULED → chuyển về DRAFT và xóa job đã lên lịch. Lỗi: 422 `INVALID_STATE` "Bài đã đăng, không sửa được."
Response 200: `PostDetail`.

#### DELETE `/api/posts/[id]` — Role `MANAGER`
Soft-delete (`deletedAt`), hủy job nếu SCHEDULED. Không xóa bài đã đăng trên nền tảng. Response 204.

#### POST `/api/posts/[id]/schedule` — Role `EDITOR`
Schema `scheduleSchema`: `z.object({ scheduledAt: z.string().datetime() })`, `scheduledAt` phải ≥ now + 2 phút, sai → 400 `VALIDATION_ERROR` "Thời gian đăng phải sau hiện tại ít nhất 2 phút."
Điều kiện: `status ∈ {DRAFT, FAILED, SCHEDULED}`, mọi variant thuộc kênh `ACTIVE` (không → 422 `INVALID_STATE` "Kênh {name} chưa kết nối."). Đặt `status: SCHEDULED`, enqueue `publish-post` với `delay = scheduledAt − now`, jobId = `publish:<postId>` (remove job cũ cùng id trước).
Response 200: `PostDetail`.

#### POST `/api/posts/[id]/publish` — Role `MANAGER`
Điều kiện như schedule. Đặt `status: PUBLISHING`, enqueue `publish-post` không delay.
Response 202: `PostDetail`.

### 4.7 Trends

#### GET `/api/trends` — Role `*`
Query `listTrendsSchema`: `page`, `limit`, `status?: TrendStatus` (mặc định `NEW`), `source?: TrendSource`, `minRelevance?: int 0-100`.
Sắp xếp: `relevanceScore desc nulls last, capturedAt desc`.
Response 200: `Paginated<Trend>` (trường như model, `suggestedAngles: string[]`).

#### POST `/api/trends/refresh` — Role `EDITOR`
Enqueue `refresh-trends` cho org. Giới hạn 1 lần / 10 phút / org (kiểm tra `JobRun` gần nhất) → vượt: 429 `RATE_LIMITED` "Vừa làm mới xu hướng, thử lại sau 10 phút."
Response 202: `{ "queued": true }`.

#### PATCH `/api/trends/[id]` — Role `EDITOR`
Schema `updateTrendSchema`: `z.object({ status: z.enum(["NEW", "USED", "IGNORED"]) })`.
Response 200: `Trend`.

#### POST `/api/trends/[id]/ideas` — Role `EDITOR` — `maxDuration = 60`
Schema `ideasSchema`: `z.object({ platforms: z.array(z.nativeEnum(Platform)).min(1) })`.
Gọi `generatePostVariants()` với `brief = trend.title + "\n" + trend.aiSummary + "\nGóc tiếp cận: " + angles.join("; ")`. Response 200: `{ "variants": GeneratedVariant[] }`.

### 4.8 Inbox

#### GET `/api/inbox` — Role `*`
Query `listInboxSchema`: `page`, `limit` (mặc định 50), `status?: InteractionStatus`, `platforms?: Platform[]` (CSV), `intents?: Intent[]` (CSV), `sentiments?: Sentiment[]` (CSV), `search?: string(max 100)`, `fanId?`.
Sắp xếp `receivedAt desc`.
Response 200: `Paginated<InboxItem>`:
```json
{ "id", "type", "platform", "accountName", "content", "attachmentUrls", "intent", "sentiment", "confidence", "escalate", "status", "receivedAt",
  "fan": { "id", "displayName", "avatarUrl", "score", "tags" },
  "post": { "id", "title", "externalUrl" } | null,
  "lastReply": { "id", "content", "mode", "status", "sentAt" } | null,
  "draft": { "id", "content" } | null }
```

#### GET `/api/inbox/[id]` — Role `*`
Response 200: `InboxItem` + `replies: Reply[]` (asc) + `fanHistory: { id, content, receivedAt, status }[]` (5 interaction gần nhất của cùng fan).

#### PATCH `/api/inbox/[id]` — Role `EDITOR`
Schema `updateInteractionSchema`: `z.object({ status: z.enum(["OPEN", "IGNORED", "ESCALATED"]).optional(), intent: z.nativeEnum(Intent).optional() })`.
Chuyển từ `ESCALATED` sang khác yêu cầu Role `MANAGER`.
Response 200: `InboxItem`.

#### POST `/api/inbox/[id]/draft` — Role `EDITOR` — `maxDuration = 60`
Gọi `draftReply()`; tạo hoặc thay `Reply` `status: DRAFT`, `mode: AI_ASSISTED` của interaction (tối đa 1 draft / interaction).
Response 200: `{ "reply": { "id", "content", "mode", "status" } }`.

#### POST `/api/inbox/[id]/reply` — Role `EDITOR`
Schema `replySchema`: `z.object({ content: z.string().min(1).max(2000), replyId: cuidSchema.optional() })` — `replyId` là draft đang sửa.
Gọi `sendReply()` với `mode = replyId ? AI_ASSISTED : MANUAL`, `sentById = membershipId`. Thành công: interaction → `REPLIED`.
Response 200: `{ "reply": Reply, "interaction": InboxItem }`.
Lỗi: 422 `INVALID_STATE` "Nền tảng không hỗ trợ trả lời loại tương tác này." (thiếu capability); 502 `PLATFORM_ERROR`.

### 4.9 Fans

#### GET `/api/fans` — Role `*`
Query `listFansSchema`: `page`, `limit`, `platform?`, `tag?`, `minScore?`, `search?` (displayName contains, case-insensitive), `sort?: "score" | "lastSeenAt"` (mặc định `score`), `order?: "asc" | "desc"` (mặc định `desc`).
Response 200: `Paginated<Fan>`.

#### GET `/api/fans/[id]` — Role `*`
Response 200: `Fan` + `interactions: InboxItem[]` (20 gần nhất) + `clicks: number` (LinkClick không gắn fan → luôn 0 trong v1; giữ field để mở rộng).

#### PATCH `/api/fans/[id]` — Role `EDITOR`
Schema `updateFanSchema`: `z.object({ tags: z.array(z.string().min(1).max(30)).max(20).optional(), notes: z.string().max(2000).optional() })`.
Response 200: `Fan`.

#### POST `/api/fans/[id]/message` — Role `MANAGER`
Schema `messageFanSchema`: `z.object({ content: z.string().min(1).max(2000) })`.
Chỉ khi `fan.platform === "ZALO_OA"` và `fan.canMessage === true` hoặc `fan.platform === "FACEBOOK_PAGE"` và `lastSeenAt` trong 24 giờ. Gửi qua `adapter.replyToInteraction` với `type: MESSAGE`. Tạo `Interaction` type MESSAGE (content rỗng, status REPLIED) + `Reply` để lưu lịch sử.
Response 200: `{ "reply": Reply }`.
Lỗi: 422 `INVALID_STATE` "Không thể nhắn tin cho fan này theo chính sách nền tảng."

### 4.10 Links & Hub

#### GET `/api/links` — Role `*` — `page`, `limit`, `search?`
Response 200: `Paginated<Link & { shortUrl: string }>` (`shortUrl = NEXT_PUBLIC_APP_URL + "/l/" + slug`).

#### POST `/api/links` — Role `EDITOR`
Schema `createLinkSchema`:
```ts
z.object({
  title: z.string().min(1).max(80),
  slug: z.string().regex(/^[a-z0-9-]{3,40}$/).optional(), // không có -> randomSlug(6)
  targetUrl: z.string().url().refine((u) => /^https?:\/\//.test(u), "Chỉ chấp nhận http/https"),
  utmSource: z.string().max(50).optional(),
  utmMedium: z.string().max(50).optional(),
  utmCampaign: z.string().max(80).optional(),
})
```
Response 201: `Link & { shortUrl }`. Lỗi: 409 `CONFLICT` "Slug đã tồn tại."

#### PATCH `/api/links/[id]` — Role `EDITOR` — `updateLinkSchema = createLinkSchema.omit({ slug: true }).partial()`
#### DELETE `/api/links/[id]` — Role `MANAGER` — soft-delete; `/l/<slug>` trả 404 sau đó.

#### GET `/api/link-hub` — Role `*`
Response 200: `LinkHub & { items: (LinkHubItem & { shortUrl, clickCount })[], publicUrl }` hoặc `null` nếu chưa tạo.

#### PUT `/api/link-hub` — Role `EDITOR`
Schema `linkHubSchema`:
```ts
z.object({
  slug: z.string().regex(/^[a-z0-9-]{3,40}$/),
  title: z.string().min(1).max(60),
  bio: z.string().max(300).default(""),
  avatarUrl: z.string().url().nullable().default(null),
  items: z.array(z.object({
    id: z.string().min(1),
    label: z.string().min(1).max(40),
    linkId: cuidSchema,
    icon: z.enum(["shop", "group", "zalo", "facebook", "tiktok", "youtube", "instagram", "website"]),
    order: z.number().int().min(0),
  })).max(12),
})
```
Upsert theo `orgId`. Response 200: như GET. Lỗi: 409 `CONFLICT` "Slug đã tồn tại."

#### GET `/l/[slug]` — public (route handler trong `(public)`)
Tìm `Link` theo slug, `deletedAt: null`. Ghi `LinkClick` (referer, userAgent, `platformHint` từ query `?src=` ∈ Platform lowercase hoặc từ referer domain: facebook.com → FACEBOOK_PAGE, instagram.com → INSTAGRAM, tiktok.com → TIKTOK, youtube.com → YOUTUBE, zalo.me → ZALO_OA), `seedingTaskId` từ query `?t=`. Tăng `Link.clickCount`; nếu có `t` tăng `SeedingTask.clickCount`. Redirect 302 tới `targetUrl` + UTM params (nếu có).
Không tìm thấy → 404 trang text "Link không tồn tại."

### 4.11 Seeding

#### GET `/api/seeding/campaigns` — Role `SEEDER` — `page`, `limit`, `status?`
Response 200: `Paginated<{ id, name, goal, status, startAt, endAt, targetCount, taskCounts: { TODO, DONE, SKIPPED }, clickCount }>`.

#### POST `/api/seeding/campaigns` — Role `MANAGER`
Schema `campaignSchema`:
```ts
z.object({
  name: z.string().min(1).max(100),
  goal: z.string().min(10).max(1000),
  ctaLinkId: cuidSchema.nullable().default(null),
  startAt: z.string().datetime(),
  endAt: z.string().datetime().nullable().default(null),
})
```
Response 201: `CampaignDetail` (như list item + `targets: SeedingTarget[]`).

#### GET `/api/seeding/campaigns/[id]` — Role `SEEDER` → `CampaignDetail` + `tasks: SeedingTask[]` (SEEDER chỉ thấy task có `target.assigneeId === membershipId`).
#### PATCH `/api/seeding/campaigns/[id]` — Role `MANAGER` — `campaignSchema.partial()` + `status?: CampaignStatus`.
#### DELETE `/api/seeding/campaigns/[id]` — Role `MANAGER` — xóa cứng (cascade target, task). 204.

#### POST `/api/seeding/campaigns/[id]/targets` — Role `MANAGER`
Schema `targetSchema`:
```ts
z.object({
  name: z.string().min(1).max(100),
  url: z.string().url(),
  platform: z.nativeEnum(Platform),
  audienceNote: z.string().max(500).default(""),
  assigneeId: cuidSchema.nullable().default(null),
})
```
Response 201: `SeedingTarget`.

#### PATCH `/api/seeding/campaigns/[id]/targets` — Role `MANAGER`
Body: `z.object({ targetId: cuidSchema }).merge(targetSchema.partial())`. Response 200: `SeedingTarget`.

#### DELETE `/api/seeding/campaigns/[id]/targets?targetId=` — Role `MANAGER`
Xóa cứng target và task của nó. Response 204.

#### POST `/api/seeding/campaigns/[id]/generate` — Role `MANAGER`
Schema: `z.object({ postId: cuidSchema.nullable().default(null), brief: z.string().max(2000).optional(), dueInHours: z.number().int().min(1).max(168).default(48) })` — phải có `postId` hoặc `brief`.
Với mỗi target chưa có task `TODO` cho `postId` này: tạo `SeedingTask` (`content` = placeholder `"Đang sinh nội dung..."`, `dueAt = now + dueInHours`), tạo `Link` riêng (slug random, targetUrl = campaign.ctaLink.targetUrl, utmSource = platform lowercase, utmMedium = "seeding", utmCampaign = campaign.name slug) nếu campaign có `ctaLinkId`; enqueue `seeding-generate` với `taskIds`.
Response 202: `{ "created": number }`.
Lỗi: 422 `INVALID_STATE` "Campaign chưa có target." / "Campaign đã kết thúc."

#### GET `/api/seeding/tasks` — Role `SEEDER` — `page`, `limit`, `status?`, `campaignId?`, `mine?: boolean`
SEEDER bắt buộc `mine = true` (server ép). Response 200: `Paginated<SeedingTaskItem>`:
```json
{ "id", "campaign": { "id", "name" }, "target": { "id", "name", "url", "platform" }, "content", "shortUrl": string | null, "status", "dueAt", "doneAt", "proofUrl", "clickCount", "assignee": { "id", "name" } | null }
```

#### PATCH `/api/seeding/tasks/[id]` — Role `SEEDER` (chỉ task được giao) / `MANAGER` (mọi task)
Schema `taskUpdateSchema`: `z.object({ status: z.enum(["DONE", "SKIPPED", "TODO"]).optional(), proofUrl: z.string().url().nullable().optional(), content: z.string().min(1).max(5000).optional() })`.
`status: DONE` → `doneAt = now`. Response 200: `SeedingTaskItem`.

### 4.12 Automation rules

#### GET `/api/rules` — Role `MANAGER` → `{ data: AutomationRule[] }` (không phân trang, ≤ 100).
#### POST `/api/rules` — Role `MANAGER`
Schema `ruleSchema`:
```ts
z.object({
  name: z.string().min(1).max(80),
  trigger: triggerSchema, // discriminatedUnion theo RuleTrigger (types)
  conditions: z.array(conditionSchema).max(10).default([]),
  actions: z.array(actionSchema).min(1).max(5),
  enabled: z.boolean().default(true),
})
```
`triggerType` suy ra từ `trigger.type`. Kiểm tra: `REPLY_TEMPLATE.templateId` tồn tại trong org; `PIN_CTA_COMMENT.linkId` tồn tại; `CREATE_DRAFT_FROM_TREND` chỉ với trigger `TREND_RELEVANT`; `REPLY_TEMPLATE` / `TAG_FAN` / `ESCALATE` chỉ với `NEW_COMMENT` / `NEW_MESSAGE`; `PIN_CTA_COMMENT` chỉ với `POST_ENGAGEMENT_THRESHOLD`. Sai → 400 `VALIDATION_ERROR` "Hành động {type} không dùng được với trigger {trigger}."
Response 201: `AutomationRule`.
#### PATCH `/api/rules/[id]` — `ruleSchema.partial()`. #### DELETE `/api/rules/[id]` — soft-delete. 204.
#### GET `/api/rules/[id]` → `AutomationRule & { recentRuns: RuleRun[] }` (20 gần nhất).

### 4.13 Analytics

Query chung `dateRangeSchema`: `from`, `to` (ISO date `YYYY-MM-DD`, theo `Asia/Ho_Chi_Minh`; mặc định 30 ngày gần nhất; tối đa 365 ngày).

- GET `/api/analytics/overview` — Role `EDITOR` → `AnalyticsOverview`.
- GET `/api/analytics/channels` — Role `EDITOR` → `{ data: ChannelStat[] }`.
- GET `/api/analytics/posts` — Role `EDITOR` — thêm `limit` (mặc định 10, max 50), `sort: "views" | "likes" | "comments" | "shares"` → `{ data: TopPost[] }`.
- GET `/api/analytics/funnel` — Role `EDITOR` → `FunnelStats`.

Công thức trong `analytics-service.ts`:
- `followersTotal` = tổng `followers` của snapshot ngày `to` (hoặc ngày gần nhất ≤ `to`) mỗi kênh ACTIVE.
- `followersDelta` = followersTotal − tổng followers snapshot ngày `from`.
- `engagements` = tổng `InsightSnapshot.engagements` trong range.
- `avgFirstResponseMinutes` = trung bình `(firstReply.sentAt − interaction.receivedAt)` theo phút cho interaction có reply SENT trong range; `null` nếu không có.
- `engagementRate` = `engagements / reach` làm tròn 4 chữ số; reach = 0 → 0.
- `hubClicks` = LinkClick có `referer` chứa `/hub/`.

### 4.14 Settings, templates, knowledge, products, team

#### GET `/api/settings` — Role `EDITOR` → `OrgSettings` (đầy đủ, đã merge default).
#### PUT `/api/settings` — Role `MANAGER`
Schema `settingsUpdateSchema`: object partial của `OrgSettings` với ràng buộc: `ai.autoReplyMinConfidence` 0.5–1; `ai.dailyCallLimit` 0–100000; `trends.keywords` ≤ 30 mục, mỗi mục ≤ 50 ký tự; `telegram.chatId` regex `^-?\d{1,20}$` hoặc rỗng; `org.timezone` chỉ nhận `"Asia/Ho_Chi_Minh"`.
Ghi từng key qua `settingsProvider.set`. Query `?testTelegram=1` (nút "Gửi tin thử" trong UI gửi query này): sau khi lưu, gọi `sendTelegram(orgId, "Social Growth Hub đã kết nối Telegram thành công.")` và trả thêm `telegramTest: { ok, error? }`. Response 200: `OrgSettings & { telegramTest?: { ok: boolean; error?: string } }`.

#### Templates — `/api/templates`, `/api/templates/[id]` — GET Role `*`, POST/PATCH/DELETE Role `EDITOR`
Schema `templateSchema`: `z.object({ name: z.string().min(1).max(60), triggerKeywords: z.array(z.string().min(1).max(40)).max(20).default([]), content: z.string().min(1).max(1000), platforms: z.array(z.nativeEnum(Platform)).default([]) })`.

#### Knowledge — `/api/knowledge`, `/api/knowledge/[id]` — GET Role `*`, POST/PATCH/DELETE Role `EDITOR`
Schema `knowledgeSchema`: `z.object({ question: z.string().min(3).max(300), answer: z.string().min(1).max(2000), tags: z.array(z.string().max(30)).max(10).default([]) })`.

#### Products — `/api/products`, `/api/products/[id]` — GET Role `*`, POST/PATCH/DELETE Role `EDITOR`
Schema `productSchema`: `z.object({ name: z.string().min(1).max(120), priceVnd: z.number().int().min(0).max(1_000_000_000), description: z.string().max(2000).default(""), links: z.object({ tiktokShop: z.string().url().optional(), shopee: z.string().url().optional(), lazada: z.string().url().optional(), website: z.string().url().optional() }).default({}), active: z.boolean().default(true) })`.

List các bảng trên: `Paginated<T>`, mặc định `limit = 50`, lọc `deletedAt: null`, sắp `updatedAt desc`. DELETE = soft-delete, 204.

#### Team
- GET `/api/team` — Role `*` → `{ data: { membershipId, userId, name, email, image, role, createdAt }[] }`.
- POST `/api/team` — Role `OWNER` — Schema `inviteSchema`: `z.object({ email: z.string().email(), role: z.enum(["MANAGER", "EDITOR", "SEEDER"]) })`. Nếu `User` với email đã tồn tại → tạo `Membership`. Nếu chưa → tạo `User` (không passwordHash) + `Membership`; người đó đăng nhập bằng Google cùng email hoặc dùng "Quên mật khẩu" (Out of Scope) → v1: response chứa `note: "Người dùng cần đăng nhập bằng Google với email này."`. Response 201.
  Lỗi: 409 `CONFLICT` "Người dùng đã trong team."
- PATCH `/api/team/[membershipId]` — Role `OWNER` — `z.object({ role: z.enum(["MANAGER", "EDITOR", "SEEDER"]) })`. Không đổi role của OWNER → 422 `INVALID_STATE` "Không thể đổi vai trò chủ sở hữu."
- DELETE `/api/team/[membershipId]` — Role `OWNER` — không xóa chính mình / OWNER → 422. 204.

### 4.15 Webhooks

#### GET `/api/webhooks/facebook` — public
Query `hub.mode=subscribe`, `hub.verify_token`, `hub.challenge`. Token khớp `META_WEBHOOK_VERIFY_TOKEN` → 200 text `hub.challenge`; sai → 403.

#### POST `/api/webhooks/facebook` — public, xác minh chữ ký
Body theo Graph webhook (`object: "page" | "instagram"`, `entry[]`). Tìm `SocialAccount` theo `entry.id` (Page ID hoặc IG ID) với `status: ACTIVE`; không có → bỏ qua entry. Gọi `adapter.parseWebhook(body)` → `NormalizedInteraction[]` → `upsertInteraction()` → enqueue `classify-and-reply` mỗi interaction mới. Bỏ qua comment / message do chính Page gửi (`from.id === externalId`).
Luôn trả 200 `{ "received": true }` trong ≤ 5 giây (xử lý nặng đẩy vào queue).

#### POST `/api/webhooks/zalo` — public, xác minh chữ ký
Body theo Zalo OA webhook v3 (`event_name`: `user_send_text`, `user_send_image`, `follow`, `unfollow`; `oa_id`, `sender.id`, `message`). `follow` → upsert `Fan` với `canMessage: true`; `unfollow` → `canMessage: false`; `user_send_*` → `NormalizedInteraction` type MESSAGE → upsert + enqueue. Trả 200 `{ "received": true }`.

### 4.16 Ma trận route ↔ Zod schema ↔ type

| Route | Schema request | Type response |
|---|---|---|
| POST /api/auth/register | registerSchema | `{ id, email }` |
| POST /api/org | onboardingSchema | Org |
| PATCH /api/org | orgSettingsSchema | Org |
| GET /api/social-accounts/connect/[platform] | — | redirect |
| POST /api/media | uploadMediaSchema (form) | Media |
| GET /api/posts | listPostsSchema | Paginated<PostListItem> |
| POST /api/posts | createPostSchema | PostDetail |
| POST /api/posts/generate | generatePostSchema | `{ variants: GeneratedVariant[] }` |
| PATCH /api/posts/[id] | updatePostSchema | PostDetail |
| POST /api/posts/[id]/schedule | scheduleSchema | PostDetail |
| GET /api/trends | listTrendsSchema | Paginated<Trend> |
| PATCH /api/trends/[id] | updateTrendSchema | Trend |
| POST /api/trends/[id]/ideas | ideasSchema | `{ variants }` |
| GET /api/inbox | listInboxSchema | Paginated<InboxItem> |
| PATCH /api/inbox/[id] | updateInteractionSchema | InboxItem |
| POST /api/inbox/[id]/reply | replySchema | `{ reply, interaction }` |
| GET /api/fans | listFansSchema | Paginated<Fan> |
| PATCH /api/fans/[id] | updateFanSchema | Fan |
| POST /api/fans/[id]/message | messageFanSchema | `{ reply }` |
| POST /api/links | createLinkSchema | Link |
| PATCH /api/links/[id] | updateLinkSchema | Link |
| PUT /api/link-hub | linkHubSchema | LinkHub |
| POST /api/seeding/campaigns | campaignSchema | CampaignDetail |
| POST /api/seeding/campaigns/[id]/targets | targetSchema | SeedingTarget |
| POST /api/seeding/campaigns/[id]/generate | generateSeedingSchema | `{ created }` |
| PATCH /api/seeding/tasks/[id] | taskUpdateSchema | SeedingTaskItem |
| POST /api/rules | ruleSchema | AutomationRule |
| GET /api/analytics/* | dateRangeSchema | AnalyticsOverview / ChannelStat[] / TopPost[] / FunnelStats |
| PUT /api/settings | settingsUpdateSchema | OrgSettings |
| POST /api/templates | templateSchema | ReplyTemplate |
| POST /api/knowledge | knowledgeSchema | KnowledgeItem |
| POST /api/products | productSchema | Product |
| POST /api/team | inviteSchema | TeamMember |
| PATCH /api/team/[membershipId] | changeRoleSchema | TeamMember |

Các schema `listPostsSchema`, `generateSeedingSchema`, `changeRoleSchema`, `settingsUpdateSchema`, `uploadMediaSchema` đặt trong file validations tương ứng (`post.ts`, `seeding.ts`, `settings.ts`, `settings.ts`, `media.ts`).
