# ShopPulse — Master Spec · 02 API

Đọc kèm: `01-data.md` (types, catalog, engine). File này là phần [4] API Contracts.

---

## [4] API Contracts

### 4.0 Quy ước chung

- Base path: `/api`. Mọi route là Next.js Route Handler (`route.ts`), runtime `nodejs`.
- Auth: session JWT của Auth.js đọc bằng `auth()` trong `src/lib/api/guard.ts`. Cột **Auth** trong từng route ghi role tối thiểu. Thiếu session → `401`. Sai role → `403`.
- Mọi truy vấn có `orgId = session.orgId`. Tài nguyên thuộc org khác → `404 NOT_FOUND` (không lộ tồn tại).
- Request body: JSON, validate bằng Zod schema trong `src/lib/validation/*`. Lỗi → `400 VALIDATION_ERROR` với `details = zodError.flatten()`.
- Response thành công: `200` với body là object; tạo mới trả `201`. Danh sách phân trang: `{ data, meta }` với `meta = { page, limit, total, totalPages }`. `page` mặc định 1, `limit` mặc định 20, tối đa 100.
- Timestamp: ISO 8601 UTC (`2026-09-29T03:00:00.000Z`). Ngày nghiệp vụ: `YYYY-MM-DD`.
- ID: cuid.
- Lỗi luôn có dạng:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Dữ liệu không hợp lệ", "details": {} } }
```

Bảng mã lỗi dùng chung (`src/lib/api/errors.ts`):

| HTTP | code | message (tiếng Việt) |
|---|---|---|
| 400 | VALIDATION_ERROR | Dữ liệu không hợp lệ |
| 400 | CSV_INVALID | File CSV không hợp lệ |
| 401 | UNAUTHORIZED | Bạn cần đăng nhập |
| 403 | FORBIDDEN | Bạn không có quyền thực hiện thao tác này |
| 404 | NOT_FOUND | Không tìm thấy dữ liệu |
| 409 | CONFLICT | Dữ liệu đã tồn tại |
| 413 | PAYLOAD_TOO_LARGE | File vượt quá 1 MB |
| 429 | RATE_LIMITED | Bạn thao tác quá nhanh, thử lại sau |
| 500 | INTERNAL_ERROR | Lỗi hệ thống, đã ghi log |

Helper `src/lib/api/response.ts`:

```ts
export function ok<T>(data: T, status = 200): Response
export function paginated<T>(data: T[], meta: PageMeta): Response
export function fail(error: ApiError): Response
export async function withHandler(req: Request, fn: () => Promise<Response>): Promise<Response> // try/catch, log, map ApiError / ZodError
```

Helper `src/lib/api/guard.ts`:

```ts
export async function requireSession(): Promise<SessionUser>            // throw ApiError 401
export async function requireRole(roles: Role[]): Promise<SessionUser>  // throw ApiError 403
```

---

### 4.1 Auth

#### `GET|POST /api/auth/[...nextauth]`

Do Auth.js xử lý. Provider Credentials nhận `{ email, password }`. Rate limit 10 / 15 phút / IP trên `POST /api/auth/callback/credentials`.

Zod `loginSchema` (`src/lib/validation/auth.ts`):

```ts
export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email({ message: "validation.email" }),
  password: z.string().min(8, { message: "validation.passwordMin" }).max(72, { message: "validation.passwordMax" }),
});
```

Lỗi đăng nhập trả về qua Auth.js `CredentialsSignin`; UI hiển thị `auth.errors.invalid` ("Email hoặc mật khẩu không đúng") hoặc `auth.errors.inactive` ("Tài khoản đã bị khoá").

---

### 4.2 Metrics catalog

#### `GET /api/metrics/catalog` — Auth: STAFF

Response 200:

```json
{
  "data": [
    { "key": "shopee_nfr", "platform": "SHOPEE", "label": "Tỷ lệ đơn không thành công", "hint": "…", "unit": "PERCENT", "unitLabel": "%", "direction": "LOWER_IS_BETTER", "min": 0, "max": 100, "decimals": 2 }
  ]
}
```

Không có lỗi ngoài 401.

---

### 4.3 Shops

#### `GET /api/shops` — Auth: STAFF

Query (`src/lib/validation/shop.ts` → `shopListQuerySchema`):

```ts
export const shopListQuerySchema = z.object({
  status: z.enum(["ACTIVE", "PAUSED", "ALL"]).default("ACTIVE"),
  platform: z.enum(["SHOPEE", "TIKTOK"]).optional(),
  q: z.string().trim().max(100).optional(),
});
```

Response 200: `{ "data": ShopDto[] }` (không phân trang; giới hạn tự nhiên ≤ 200 shop / org; sắp xếp: CRITICAL → WARNING → NO_DATA → HEALTHY, rồi `name asc`).

#### `POST /api/shops` — Auth: MANAGER

```ts
export const createShopSchema = z.object({
  platform: z.enum(["SHOPEE", "TIKTOK"], { message: "validation.platform" }),
  name: z.string().trim().min(2, { message: "validation.shopNameMin" }).max(80, { message: "validation.shopNameMax" }),
  externalShopId: z.string().trim().max(64).regex(/^[A-Za-z0-9_.-]*$/, { message: "validation.externalShopId" }).nullable().default(null),
  assigneeId: z.string().cuid().nullable().default(null),
  note: z.string().trim().max(500).nullable().default(null),
});
```

Response 201: `ShopDto`.

| HTTP | code | Khi |
|---|---|---|
| 400 | VALIDATION_ERROR | Schema fail; `assigneeId` không thuộc org hoặc không active → `details.fieldErrors.assigneeId = ["validation.assigneeInvalid"]` |
| 409 | CONFLICT | Trùng (orgId, platform, name) với shop chưa xoá |

#### `GET /api/shops/[shopId]` — Auth: STAFF

Response 200: `ShopDetailDto`. 404 nếu không thuộc org hoặc đã soft-delete.

#### `PATCH /api/shops/[shopId]` — Auth: MANAGER

```ts
export const updateShopSchema = createShopSchema.omit({ platform: true }).partial().extend({
  status: z.enum(["ACTIVE", "PAUSED"]).optional(),
});
```

Response 200: `ShopDto`. Lỗi: 400, 404, 409 (trùng tên).

#### `DELETE /api/shops/[shopId]` — Auth: MANAGER

Soft-delete: đặt `deletedAt = now`, `status = PAUSED`. Task OPEN / IN_PROGRESS của shop chuyển `SKIPPED` với `completionNote = "Shop đã bị xoá"`. Response 200: `{ "id": "<shopId>", "deletedAt": "<iso>" }`. Lỗi: 404.

---

### 4.4 Metric snapshots

#### `GET /api/shops/[shopId]/metrics` — Auth: STAFF

```ts
export const metricsQuerySchema = z.object({
  from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, { message: "validation.date" }),
  to: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, { message: "validation.date" }),
}).refine((v) => v.from <= v.to, { message: "validation.dateRange", path: ["to"] })
  .refine((v) => differenceInCalendarDays(parseISO(v.to), parseISO(v.from)) <= 92, { message: "validation.dateRangeMax", path: ["to"] });
```

Response 200:

```json
{ "data": [ { "date": "2026-09-28", "metricKey": "shopee_nfr", "value": 3.2, "source": "MANUAL" } ] }
```

Sắp xếp `date asc, metricKey asc`. Lỗi: 400, 404.

#### `POST /api/shops/[shopId]/metrics` — Auth: STAFF

Upsert toàn bộ chỉ số của **một ngày**.

```ts
export const upsertMetricsSchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, { message: "validation.date" }),
  values: z.record(z.string(), z.number({ message: "validation.number" })),
}).superRefine((v, ctx) => {
  // 1. date <= hôm nay theo APP_TIMEZONE, else ctx.addIssue path ["date"] message "validation.dateFuture"
  // 2. mỗi key phải thuộc catalog của platform shop, else path ["values", key] message "validation.metricKey"
  // 3. mỗi value trong [min, max] của chỉ số, else path ["values", key] message "validation.metricRange"
  // 4. values có ít nhất 1 key, else path ["values"] message "validation.metricsEmpty"
});
```

Xử lý (`metric-service.upsertSnapshots`), trong 1 transaction:

1. Upsert từng `MetricSnapshot` (unique `shopId, date, metricKey`), `source = MANUAL`, `createdById = session.id`.
2. Đọc **toàn bộ** snapshot của (shop, date) → `computeHealth` → upsert `HealthScore`.
3. Nếu `date` = ngày lớn nhất có snapshot của shop: chạy `generateAlertTasks`, insert task, gửi notification (01-data.md §3.5, §3.9). Ngày cũ hơn không sinh task.

Response 200:

```json
{
  "date": "2026-09-29",
  "saved": 10,
  "health": { "date": "2026-09-29", "score": 45, "status": "CRITICAL", "breakdown": [] },
  "createdTasks": [ { "id": "…", "title": "…", "priority": "URGENT" } ]
}
```

Lỗi: 400, 404.

#### `GET /api/shops/[shopId]/health` — Auth: STAFF

Query: `metricsQuerySchema` (from, to, ≤ 92 ngày). Response 200: `{ "data": HealthScoreDto[] }` sắp `date asc`. Lỗi: 400, 404.

#### `POST /api/shops/[shopId]/import` — Auth: STAFF

`Content-Type: multipart/form-data`, field `file` (CSV). Rate limit 5 / phút / user.

Xử lý:

1. Kiểm tra size ≤ 1 048 576 byte → else `413 PAYLOAD_TOO_LARGE`.
2. Kiểm tra `file.type === "text/csv"` hoặc tên kết thúc `.csv` → else `400 CSV_INVALID` với `details.reason = "validation.csv.type"`.
3. `parseMetricsCsv(text, shop.platform)`. Nếu `errors.length > 0` và `valid.length === 0` → `400 CSV_INVALID` với `details.errors = CsvRowError[]`.
4. Nhóm `valid` theo `date`, với mỗi ngày gọi `upsertSnapshots(source = "CSV")`. Chỉ ngày lớn nhất trong file (và là ngày lớn nhất của shop) sinh task.
5. Ghi `ImportJob`.

Response 200:

```json
{
  "importJobId": "…",
  "rowCount": 30,
  "successCount": 28,
  "errorCount": 2,
  "errors": [ { "line": 5, "field": "value", "message": "validation.csv.value" } ],
  "datesAffected": ["2026-09-27", "2026-09-28"],
  "createdTasks": [ { "id": "…", "title": "…", "priority": "URGENT" } ]
}
```

Lỗi: 400 CSV_INVALID, 404, 413, 429.

---

### 4.5 Dashboard

#### `GET /api/dashboard/summary` — Auth: STAFF

Không có query. Response 200: `DashboardSummaryDto`.

- `shops`: shop ACTIVE, sắp xếp như `GET /api/shops`.
- `counts`: đếm theo `latestHealth.status`; shop chưa có health → `noData`.
- `tasksDueToday`: task `status IN (OPEN, IN_PROGRESS)`, `dueAt` trong ngày hôm nay theo `APP_TIMEZONE`, sắp `priority desc (URGENT > HIGH > MEDIUM > LOW), dueAt asc`, tối đa 50.
- `tasksOverdue`: task `status IN (OPEN, IN_PROGRESS)`, `dueAt < now`, sắp `dueAt asc`, tối đa 50.
- `staleShops`: shop ACTIVE có `staleDays >= 1` hoặc `staleDays === null`; `staleDays null` hiển thị là `-1` trong DTO này để phân biệt.
- STAFF nhận cùng dữ liệu như MANAGER (không lọc theo assignee ở API; UI có toggle "Chỉ shop của tôi").

---

### 4.6 Tasks

#### `GET /api/tasks` — Auth: STAFF

```ts
export const taskListQuerySchema = z.object({
  status: z.string().transform((s) => s.split(",")).pipe(z.array(z.enum(["OPEN", "IN_PROGRESS", "DONE", "SKIPPED"]))).default("OPEN,IN_PROGRESS"),
  shopId: z.string().cuid().optional(),
  assigneeId: z.union([z.literal("me"), z.literal("none"), z.string().cuid()]).optional(),
  priority: z.enum(["LOW", "MEDIUM", "HIGH", "URGENT"]).optional(),
  source: z.enum(["AUTO", "MANUAL"]).optional(),
  due: z.enum(["today", "overdue", "week"]).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
```

`due=today`: `dueAt` trong ngày hôm nay; `overdue`: `dueAt < now`; `week`: `dueAt` từ đầu tuần (thứ Hai) tới cuối Chủ nhật hiện tại, theo `APP_TIMEZONE`.

Sắp xếp: `status asc (OPEN, IN_PROGRESS, DONE, SKIPPED)`, rồi `priority desc`, rồi `dueAt asc`.

Response 200: `{ "data": TaskDto[], "meta": PageMeta }`.

#### `POST /api/tasks` — Auth: STAFF

```ts
export const createTaskSchema = z.object({
  shopId: z.string().cuid({ message: "validation.shopRequired" }),
  title: z.string().trim().min(5, { message: "validation.taskTitleMin" }).max(120, { message: "validation.taskTitleMax" }),
  description: z.string().trim().max(2000, { message: "validation.taskDescriptionMax" }).default(""),
  priority: z.enum(["LOW", "MEDIUM", "HIGH", "URGENT"]).default("MEDIUM"),
  assigneeId: z.string().cuid().nullable().default(null),
  dueAt: z.string().datetime({ message: "validation.datetime" }),
}).refine((v) => new Date(v.dueAt).getTime() > Date.now(), { message: "validation.dueAtFuture", path: ["dueAt"] });
```

`source = MANUAL`, `createdById = session.id`, `dedupeKey = null`. Nếu `assigneeId` khác `session.id` → notification `TASK_ASSIGNED`. Response 201: `TaskDto`. Lỗi: 400 (shop / assignee không hợp lệ), 404 (shop).

#### `GET /api/tasks/[taskId]` — Auth: STAFF

Response 200: `TaskDto`. Lỗi: 404.

#### `PATCH /api/tasks/[taskId]` — Auth: STAFF

```ts
export const updateTaskSchema = z.object({
  status: z.enum(["OPEN", "IN_PROGRESS", "DONE", "SKIPPED"]).optional(),
  assigneeId: z.string().cuid().nullable().optional(),
  priority: z.enum(["LOW", "MEDIUM", "HIGH", "URGENT"]).optional(),
  dueAt: z.string().datetime().optional(),
  completionNote: z.string().trim().max(1000, { message: "validation.noteMax" }).optional(),
  title: z.string().trim().min(5).max(120).optional(),
  description: z.string().trim().max(2000).optional(),
}).refine((v) => Object.keys(v).length > 0, { message: "validation.empty" });
```

Quy tắc:

- STAFF chỉ được PATCH task có `assigneeId === session.id` hoặc `assigneeId === null`; ngược lại `403`.
- STAFF không được sửa `title`, `description`, `dueAt` của task `source = AUTO`; gửi các field đó → `403`.
- Chuyển sang `DONE` hoặc `SKIPPED`: đặt `completedAt = now`, `dedupeKey = null`. `SKIPPED` bắt buộc `completionNote` ≥ 5 ký tự → else `400` với `details.fieldErrors.completionNote = ["validation.skipNoteRequired"]`.
- Chuyển từ `DONE` / `SKIPPED` về `OPEN` / `IN_PROGRESS`: đặt `completedAt = null`; nếu là task AUTO, khôi phục `dedupeKey` theo công thức ở 01-data.md §3.1; nếu đã có task mở cùng `dedupeKey` → `409 CONFLICT`.
- `assigneeId` đổi sang user khác `session.id` → notification `TASK_ASSIGNED`.

Response 200: `TaskDto`. Lỗi: 400, 403, 404, 409.

---

### 4.7 Settings — thresholds

#### `GET /api/settings/thresholds` — Auth: STAFF

Response 200: `{ "data": ThresholdDto[] }` sắp `platform asc, metricKey asc`. Đủ 18 dòng.

#### `PUT /api/settings/thresholds` — Auth: MANAGER

```ts
export const thresholdsPutSchema = z.object({
  items: z.array(z.object({
    metricKey: z.string().refine(isMetricKey, { message: "validation.metricKey" }),
    warningValue: z.number({ message: "validation.number" }),
    criticalValue: z.number({ message: "validation.number" }),
    weight: z.number().int().min(1, { message: "validation.weightRange" }).max(3, { message: "validation.weightRange" }),
    isEnabled: z.boolean(),
  })).min(1),
}).superRefine((v, ctx) => {
  // với mỗi item, theo direction của catalog:
  // LOWER_IS_BETTER: warningValue < criticalValue, else path ["items", i, "criticalValue"] message "validation.thresholdOrderLower"
  // HIGHER_IS_BETTER: warningValue > criticalValue, else message "validation.thresholdOrderHigher"
  // cả hai giá trị trong [min, max] của catalog, else message "validation.metricRange"
});
```

Chỉ cập nhật các `metricKey` gửi lên. Response 200: `{ "data": ThresholdDto[] }` (đủ 18 dòng sau cập nhật). Không tính lại HealthScore cũ; ngưỡng mới áp dụng từ lần lưu snapshot tiếp theo. Lỗi: 400, 403.

---

### 4.8 Settings — rules

#### `GET /api/settings/rules` — Auth: STAFF

Query: `type` ∈ `ALERT | ROUTINE | ALL` (mặc định `ALL`). Response 200: `{ "data": TaskRuleDto[] }` sắp `type asc, platform asc, metricKey asc, level asc`.

#### `POST /api/settings/rules` — Auth: MANAGER

```ts
export const ruleSchema = z.object({
  type: z.enum(["ALERT", "ROUTINE"]),
  platform: z.enum(["SHOPEE", "TIKTOK"]).nullable().default(null),
  metricKey: z.string().refine(isMetricKey, { message: "validation.metricKey" }).nullable().default(null),
  level: z.enum(["WARNING", "CRITICAL"]).nullable().default(null),
  routineKey: z.string().trim().regex(/^[a-z0-9_]{3,40}$/, { message: "validation.routineKey" }).nullable().default(null),
  titleTemplate: z.string().trim().min(5, { message: "validation.templateMin" }).max(160, { message: "validation.templateMax" }),
  descriptionTemplate: z.string().trim().max(2000, { message: "validation.templateMax" }).default(""),
  priority: z.enum(["LOW", "MEDIUM", "HIGH", "URGENT"]),
  dueInHours: z.number().int().min(0).max(720, { message: "validation.dueInHoursRange" }),
  isActive: z.boolean().default(true),
}).superRefine((v, ctx) => {
  // ALERT: metricKey và level bắt buộc (message "validation.ruleAlertFields"); platform (nếu có) phải bằng platform của metricKey ("validation.rulePlatformMismatch"); routineKey phải null.
  // ROUTINE: routineKey bắt buộc ("validation.ruleRoutineFields"); metricKey, level phải null; dueInHours trong [0, 23] ("validation.routineDueHour").
});
```

Response 201: `TaskRuleDto`. Lỗi: 400, 403, 409 (ROUTINE trùng `routineKey` trong org).

#### `PATCH /api/settings/rules/[ruleId]` — Auth: MANAGER

Body: `ruleSchema.omit({ type: true }).partial()`, áp cùng superRefine sau khi merge với bản ghi hiện tại. Response 200: `TaskRuleDto`. Lỗi: 400, 403, 404.

#### `DELETE /api/settings/rules/[ruleId]` — Auth: MANAGER

Xoá cứng rule; task đã sinh giữ `ruleId = null` (`onDelete: SetNull` — thêm vào schema quan hệ `Task.rule`). Response 200: `{ "id": "<ruleId>" }`. Lỗi: 403, 404.

---

### 4.9 Members

#### `GET /api/members` — Auth: STAFF

Response 200: `{ "data": UserDto[] }` sắp `role asc (OWNER, MANAGER, STAFF), name asc`. Không trả `passwordHash`.

#### `POST /api/members` — Auth: MANAGER

```ts
export const createMemberSchema = z.object({
  email: z.string().trim().toLowerCase().email({ message: "validation.email" }),
  name: z.string().trim().min(2, { message: "validation.nameMin" }).max(60, { message: "validation.nameMax" }),
  role: z.enum(["MANAGER", "STAFF"]),
  password: z.string().min(8, { message: "validation.passwordMin" }).max(72, { message: "validation.passwordMax" }),
});
```

MANAGER không được tạo OWNER (schema đã loại). Response 201: `UserDto`. Lỗi: 400, 403, 409 (email đã tồn tại).

#### `PATCH /api/members/[userId]` — Auth: MANAGER

```ts
export const updateMemberSchema = z.object({
  name: z.string().trim().min(2).max(60).optional(),
  role: z.enum(["OWNER", "MANAGER", "STAFF"]).optional(),
  isActive: z.boolean().optional(),
  password: z.string().min(8).max(72).optional(),
}).refine((v) => Object.keys(v).length > 0, { message: "validation.empty" });
```

Quy tắc:

- MANAGER không được sửa user role OWNER và không được đặt `role = OWNER` → `403`.
- Không được tự đặt `isActive = false` cho chính mình → `400` với `details.fieldErrors.isActive = ["validation.selfDeactivate"]`.
- Hạ OWNER cuối cùng của org xuống role khác → `400` với `details.fieldErrors.role = ["validation.lastOwner"]`.
- Đổi `password` → hash lại; session JWT hiện có của user đó vẫn hợp lệ tới khi hết hạn (ghi nhận là giới hạn tier B).

Response 200: `UserDto`. Lỗi: 400, 403, 404.

---

### 4.10 Notifications

#### `GET /api/notifications` — Auth: STAFF

Query: `page`, `limit` (mặc định 20, tối đa 50), `unread` ∈ `true | false` (không truyền = tất cả). Response 200: `{ "data": NotificationDto[], "meta": PageMeta, "unreadCount": 3 }` sắp `createdAt desc`. Chỉ trả notification của `session.id`.

#### `POST /api/notifications/read-all` — Auth: STAFF

Body: `{ "ids": string[] }` (tối đa 100) hoặc `{}` = đánh dấu tất cả. Đặt `readAt = now` cho notification của user hiện tại. Response 200: `{ "updated": 5 }`.

---

### 4.11 Cron

#### `POST /api/cron/daily` — Auth: header `Authorization: Bearer <CRON_SECRET>`

Không dùng session. Sai / thiếu secret → `401 UNAUTHORIZED`. Cho phép cả `GET` (Vercel Cron gọi GET) với cùng kiểm tra.

Xử lý cho **mọi org**:

1. `date = hôm nay theo APP_TIMEZONE`.
2. Với mỗi org: lấy shop ACTIVE chưa xoá, rule ROUTINE active, dedupeKey routine đã có của ngày → `generateRoutineTasks` → insert.
3. Log 1 dòng `{ msg: "cron.daily", date, orgCount, createdTasks }`.

Response 200:

```json
{ "date": "2026-09-29", "orgCount": 1, "createdTasks": 12 }
```

Idempotent: gọi nhiều lần trong ngày không tạo trùng.
