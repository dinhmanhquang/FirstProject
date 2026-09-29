# ShopPulse — Delta Spec · TikTok Account Health Rating & mở rộng

Ngày: 2026-09-29 · Áp dụng cho: `specs/shop-pulse/` (00–05) · Loại: Change Request

Đọc kèm: `01-data.md` §3.1–§3.7, `02-api.md` §4.0, `03-ui.md` §6.4, `05-phases.md`.

---

## [0] Ngữ cảnh và nguồn

### 0.1 Yêu cầu

User yêu cầu tham khảo tính năng mới của TikTok Shop (bài trên TikTok Seller University Việt Nam, `knowledge_id=7309068566251270`) và mở rộng spec.

### 0.2 Nguồn đã dùng

Bài user gửi không truy cập được từ môi trường viết spec (host bị chặn). Delta này dựa trên:

| Nguồn | Nội dung rút ra |
|---|---|
| TikTok Seller University VN — "Đánh giá sức khỏe tài khoản" (`knowledge_id=8055182777779984`) | AHR là điểm 0–1.000 phản ánh sức khoẻ chính sách của tài khoản người bán trong 90 ngày gần nhất. Người bán mới bắt đầu với 200 điểm. Công thức: `AHR = 200 + điểm cộng từ đơn hoàn thành (90 ngày) − điểm trừ do vi phạm chính sách (90 ngày)`. Mức: 200–1.000 "khoẻ mạnh"; 151–199 "cần cải thiện"; 1–150 "có nguy cơ bị vô hiệu hoá"; 0 = tài khoản bị vô hiệu hoá. Xem trước từ 12/05/2026; thay thế dần Điểm vi phạm từ giữa tháng 6; thay thế hoàn toàn từ tháng 7/2026. |
| TikTok Seller University TH / PH — "Account Health Rating" | Cùng công thức và mức. Điểm cộng từ đơn hoàn thành được tính và cộng theo tuần. |
| adbeacon.com, moras.ai, bebolddigital.com (nguồn phụ, 2026) | Mốc hạn chế khi điểm rơi xuống 150 / 100 / 50 (hạn chế đăng sản phẩm mới và tham gia mega campaign trong 7 / 14 / 28 ngày), 0 = vô hiệu hoá. Điểm cộng: 4 điểm mỗi 200 đơn hoàn thành, tối đa 20 điểm / tuần. **Chưa xác nhận trên trang VN — không đưa vào logic, chỉ đưa vào text hướng dẫn kèm ghi chú "kiểm tra trong Seller Center".** |
| TikTok Seller University US — "Growth Center / Shop Diagnostics" | TikTok gợi ý nhiệm vụ theo chẩn đoán shop, có mục "For you / Available / In progress". Đây là hướng đi trùng với Task Engine của ShopPulse; không sync được vì không có API. Ghi Out of Scope. |

### 0.3 Assumptions Log (bổ sung)

| Giả định | Lý do | Ảnh hưởng nếu sai |
|---|---|---|
| Bài user gửi nói về Account Health Rating | Đây là thay đổi lớn nhất về sức khoẻ shop của TikTok Shop VN trong 2026 và khớp mô tả "tính năng mới". | Nếu bài nói về tính năng khác: user paste nội dung, viết Delta Spec mới; Delta này vẫn đúng vì AHR đã có hiệu lực. |
| Điểm vi phạm TikTok không còn dùng cho shop VN từ 07/2026 | Trang VN ghi "thay thế hoàn toàn từ tháng 7". | Nếu shop nào còn thấy Điểm vi phạm: bật lại ngưỡng cũ bằng cách thêm chỉ số qua Delta Spec khác; dữ liệu cũ không mất vì chưa có shop nào build. |
| Ngưỡng WARNING nội bộ cho AHR = 260, CRITICAL = 199 | CRITICAL trùng mức "cần cải thiện" chính thức; WARNING là đệm 60 điểm để xử lý trước khi rơi khỏi mức "khoẻ mạnh". | Trưởng nhóm chỉnh trong `/settings/thresholds`. |
| Mốc hạn chế 150 / 100 / 50 không đưa vào code | Chỉ có ở nguồn phụ. | Nếu user xác nhận: thêm bảng `AhrMilestone` qua Delta Spec. |
| Nhật ký vi phạm nhập tay | Không có API. | Nếu có API: thêm connector; model không đổi. |

### 0.4 Out of Scope (bổ sung)

13. Không sync nhiệm vụ gợi ý từ TikTok Growth Center / Shop Diagnostics.
14. Không dự báo điểm AHR sẽ cộng từ đơn hoàn thành (công thức cộng điểm chưa xác nhận trên trang VN).
15. Không tự động đọc danh sách vi phạm từ Seller Center; người dùng nhập tay vào Nhật ký vi phạm.

---

## [1] Tóm tắt thay đổi

| Mã | Loại | Nội dung |
|---|---|---|
| D1 | [REMOVE] | Chỉ số `tiktok_violation_points` khỏi catalog, types, seed, action hint, `vi.json`. |
| D2 | [ADD] | Chỉ số `tiktok_ahr` (Đánh giá sức khỏe tài khoản) + helper mức AHR chính thức + badge trong UI. |
| D3 | [ADD] | Loại quy tắc `TREND`: sinh nhiệm vụ khi một chỉ số **giảm mạnh** trong N ngày, dù chưa vượt ngưỡng. |
| D4 | [ADD] | Nhật ký vi phạm & khiếu nại (`ViolationRecord`) cho cả Shopee và TikTok, tự sinh nhiệm vụ "Nộp khiếu nại trước hạn". |
| D5 | [MODIFY] | Seed, `vi.json`, tests, phases tương ứng. |

Số chỉ số TikTok giữ nguyên 8; tổng catalog vẫn 18.

---

## [2] D1 + D2 — Chỉ số AHR

### 2.1 `src/types/index.ts` [MODIFY]

```ts
// [REMOVE] "tiktok_violation_points" khỏi TiktokMetricKey
// [ADD]
export type TiktokMetricKey =
  | "tiktok_ldr"
  | "tiktok_sfcr"
  | "tiktok_nrr"
  | "tiktok_ahr"
  | "tiktok_sps"
  | "tiktok_pending_orders"
  | "tiktok_pending_chats"
  | "tiktok_low_ratings";

export type AhrTier = "HEALTHY" | "NEEDS_IMPROVEMENT" | "AT_RISK" | "DEACTIVATED";

export interface AhrTierInfo {
  tier: AhrTier;
  min: number;
  max: number;
  labelKey: string; // vi.json: ahr.tiers.<tier>
}
```

### 2.2 `src/lib/metrics/catalog.ts` [MODIFY]

Xoá dòng `tiktok_violation_points`. Thêm, đặt ngay sau `tiktok_nrr`:

```ts
{ key: "tiktok_ahr", platform: "TIKTOK", labelKey: "metrics.tiktok_ahr.label", unit: "POINTS", direction: "HIGHER_IS_BETTER", min: 0, max: 1000, decimals: 0, defaultWarning: 260, defaultCritical: 199, defaultWeight: 3 },
```

`vi.json`:

| key | giá trị |
|---|---|
| metrics.tiktok_ahr.label | Đánh giá sức khỏe tài khoản (AHR) |
| metrics.tiktok_ahr.hint | Điểm 0–1000 trong Seller Center > Sức khỏe tài khoản. Mức chính thức: 200–1000 khoẻ mạnh, 151–199 cần cải thiện, 1–150 nguy cơ vô hiệu hoá. |
| ahr.tiers.HEALTHY | Khoẻ mạnh |
| ahr.tiers.NEEDS_IMPROVEMENT | Cần cải thiện |
| ahr.tiers.AT_RISK | Nguy cơ vô hiệu hoá |
| ahr.tiers.DEACTIVATED | Đã vô hiệu hoá |
| ahr.badge | AHR {value} · {tier} |

Xoá 2 key `metrics.tiktok_violation_points.*`.

### 2.3 `src/lib/metrics/ahr.ts` [ADD]

```ts
import type { AhrTier, AhrTierInfo } from "@/types";

export const AHR_TIERS: readonly AhrTierInfo[] = [
  { tier: "HEALTHY", min: 200, max: 1000, labelKey: "ahr.tiers.HEALTHY" },
  { tier: "NEEDS_IMPROVEMENT", min: 151, max: 199, labelKey: "ahr.tiers.NEEDS_IMPROVEMENT" },
  { tier: "AT_RISK", min: 1, max: 150, labelKey: "ahr.tiers.AT_RISK" },
  { tier: "DEACTIVATED", min: 0, max: 0, labelKey: "ahr.tiers.DEACTIVATED" },
];

export function getAhrTier(value: number): AhrTier {
  const v = Math.round(value);
  if (v <= 0) return "DEACTIVATED";
  if (v <= 150) return "AT_RISK";
  if (v <= 199) return "NEEDS_IMPROVEMENT";
  return "HEALTHY";
}
```

Màu badge: HEALTHY `#16A34A`, NEEDS_IMPROVEMENT `#D97706`, AT_RISK `#DC2626`, DEACTIVATED `#111827`.

### 2.4 Action hint [MODIFY] `src/lib/tasks/templates.ts`

Xoá dòng `tiktok_violation_points`. Thêm:

| metricKey | Action hint |
|---|---|
| tiktok_ahr | 1. Vào Seller Center > Sức khỏe tài khoản, mở mục điểm trừ 90 ngày, chụp màn hình từng vi phạm và ghi vào Nhật ký vi phạm của shop trong ShopPulse.\n2. Với vi phạm còn hạn khiếu nại, tạo khiếu nại ngay và cập nhật trạng thái trong Nhật ký.\n3. Kiểm tra mốc hạn chế hiện tại trong Seller Center và báo trưởng nhóm nếu shop đang bị hạn chế đăng sản phẩm hoặc tham gia chiến dịch. |

Seed rule ALERT cho `tiktok_ahr`: WARNING (`MEDIUM`, 24 giờ), CRITICAL (`URGENT`, 4 giờ) — giống các chỉ số khác. Xoá 2 rule của `tiktok_violation_points`. Tổng rule ALERT vẫn 36.

### 2.5 UI [MODIFY]

- `src/components/shops/AhrTierBadge.tsx` [ADD]: props `{ value: number; size?: "sm" | "md" }`. Text theo `ahr.badge`, `role="status"`.
- `MetricBreakdownTable.tsx` [MODIFY]: dòng `tiktok_ahr` hiển thị thêm `AhrTierBadge` cạnh giá trị.
- `ShopCard.tsx` [MODIFY]: shop TIKTOK có snapshot `tiktok_ahr` ở ngày mới nhất → hiện `AhrTierBadge size="sm"` dưới score. `ShopDto` [MODIFY] thêm `ahrValue: number | null` (null với shop SHOPEE hoặc chưa có snapshot).
- `MetricEntryForm.tsx` [MODIFY]: ô `tiktok_ahr` hiển thị `AhrTierBadge` realtime khi giá trị thay đổi.

### 2.6 Seed [MODIFY] `prisma/seed.ts`

Shop Demo TikTok 1: thay `tiktok_violation_points = 4` bằng `tiktok_ahr = 240 - i * 3` (i = 0..13) → ngày cuối 201, tạo xu hướng giảm để kích hoạt rule TREND ở mục [3].

---

## [3] D3 — Quy tắc TREND

### 3.1 Prisma [MODIFY]

```prisma
enum RuleType {
  ALERT
  ROUTINE
  TREND      // [ADD]
}

model TaskRule {
  // ... giữ nguyên các field cũ
  windowDays     Int?                       // [ADD] TREND: số ngày so sánh, 2..30
  deltaThreshold Decimal? @db.Decimal(10, 2) // [ADD] TREND: mức giảm tối thiểu để sinh task
}
```

Migration: `pnpm db:migrate --name add_trend_rules`.

### 3.2 Types [MODIFY]

```ts
// TaskRuleDto [ADD 2 field]
windowDays: number | null;
deltaThreshold: number | null;

// TemplateContext [ADD 2 field, optional]
delta?: string;       // mức giảm, format theo decimals
windowDays?: string;  // số ngày
```

### 3.3 `src/lib/tasks/trend.ts` [ADD]

```ts
export interface TrendInput {
  shop: { id: string; name: string; platform: Platform; assigneeId: string | null };
  date: string;                       // ngày mới nhất
  current: Record<string, number>;    // giá trị ngày `date` theo metricKey
  history: (metricKey: MetricKey, onOrBeforeDate: string) => { date: string; value: number } | null;
  rules: TaskRuleDto[];               // type TREND, isActive, platform null hoặc = shop.platform
  existingDedupeKeys: Set<string>;
  now: Date;
  render: (template: string, ctx: TemplateContext) => string;
  buildContext: (metricKey: MetricKey, value: number, delta: number, windowDays: number) => TemplateContext;
}

export function generateTrendTasks(input: TrendInput): GeneratedTask[]
```

Thuật toán:

1. Với mỗi rule `r` (đã sắp `createdAt asc`), lấy `cur = current[r.metricKey]`; không có → bỏ qua.
2. `pastDate = date − r.windowDays` (ngày lịch). `past = history(r.metricKey, pastDate)`; `null` hoặc `past.date < date − r.windowDays − 3` (cho phép lệch tối đa 3 ngày vì thiếu dữ liệu) → bỏ qua.
3. `direction` lấy từ catalog. `delta = direction === "HIGHER_IS_BETTER" ? past.value − cur : cur − past.value`.
4. `delta < r.deltaThreshold` → bỏ qua.
5. `dedupeKey = \`${shop.id}:trend:${r.metricKey}:${date}\``; đã tồn tại → bỏ qua.
6. Tạo `GeneratedTask` với `metricLevel = null`, `metricKey = r.metricKey`, `metricValue = cur`, `snapshotDate = date`, `dueAt = now + r.dueInHours giờ`, `assigneeId = shop.assigneeId`.

`renderTemplate` [MODIFY]: hỗ trợ thêm `{delta}` và `{windowDays}` (tổng 10 placeholder).

### 3.4 Seed rule TREND (tạo trong `createDefaultSettings`)

Template chung: `titleTemplate = "[Xu hướng] {metricLabel} giảm {delta}{unit} trong {windowDays} ngày – {shopName}"`, `descriptionTemplate = "Ngày {date}: {metricLabel} hiện {value}{unit}, giảm {delta}{unit} so với {windowDays} ngày trước.\n\nViệc cần làm:\n" + action hint của chỉ số`.

| platform | metricKey | windowDays | deltaThreshold | priority | dueInHours |
|---|---|---|---|---|---|
| TIKTOK | tiktok_ahr | 7 | 20 | HIGH | 24 |
| TIKTOK | tiktok_sps | 7 | 0.3 | HIGH | 24 |
| SHOPEE | shopee_rating | 7 | 0.2 | HIGH | 24 |

Tổng `TaskRule` seed: 36 ALERT + 4 ROUTINE + 3 TREND = **43** (cập nhật lệnh Verify Phase 2 từ 40 → 43).

### 3.5 Service [MODIFY] `src/lib/services/metric-service.ts`

Trong `upsertSnapshots`, sau bước sinh ALERT (chỉ khi `date` là ngày mới nhất của shop): gọi `generateTrendTasks` với `history` đọc `MetricSnapshot` có `date <= onOrBeforeDate` sắp `date desc` lấy 1. Insert cùng transaction. Task TREND có `priority HIGH` không gửi notification (chỉ URGENT mới gửi, giữ quy tắc cũ).

### 3.6 API / validation [MODIFY] `ruleSchema`

```ts
windowDays: z.number().int().min(2).max(30, { message: "validation.windowDaysRange" }).nullable().default(null),
deltaThreshold: z.number().positive({ message: "validation.deltaPositive" }).nullable().default(null),
// superRefine [ADD]:
// TREND: metricKey bắt buộc, level phải null, routineKey phải null, windowDays và deltaThreshold bắt buộc ("validation.ruleTrendFields"); platform (nếu có) phải khớp metricKey.
// ALERT / ROUTINE: windowDays và deltaThreshold phải null.
```

`GET /api/settings/rules?type=` chấp nhận thêm `TREND`.

`vi.json` [ADD]: `validation.windowDaysRange` "Số ngày so sánh từ 2 đến 30", `validation.deltaPositive` "Mức giảm phải lớn hơn 0", `validation.ruleTrendFields` "Quy tắc xu hướng cần chỉ số, số ngày và mức giảm", `rules.types.TREND` "Xu hướng".

### 3.7 UI [MODIFY]

- `RuleForm.tsx`: khi `type = TREND` hiện 2 ô `windowDays`, `deltaThreshold`; ẩn `level`, `routineKey`.
- `RuleTable.tsx`: cột "Mức" hiển thị `giảm ≥ {deltaThreshold} / {windowDays} ngày` với rule TREND.
- `TaskItem.tsx`: task có `metricKey != null` và `metricLevel == null` hiển thị badge `Xu hướng` màu `#7C3AED`.

---

## [4] D4 — Nhật ký vi phạm & khiếu nại

### 4.1 Prisma [ADD]

```prisma
enum AppealStatus {
  NONE
  SUBMITTED
  ACCEPTED
  REJECTED
}

model ViolationRecord {
  id             String       @id @default(cuid())
  orgId          String
  shopId         String
  occurredAt     DateTime     @db.Date
  pointsDeducted Decimal      @db.Decimal(10, 2)
  reason         String
  referenceCode  String?
  appealStatus   AppealStatus @default(NONE)
  appealDeadline DateTime?    @db.Date
  appealNote     String?
  resolvedAt     DateTime?
  createdById    String
  createdAt      DateTime     @default(now())
  updatedAt      DateTime     @updatedAt

  org       Organization @relation(fields: [orgId], references: [id])
  shop      Shop         @relation(fields: [shopId], references: [id])
  createdBy User         @relation(fields: [createdById], references: [id])

  @@index([orgId, shopId, occurredAt])
}
```

Thêm quan hệ ngược `violations ViolationRecord[]` vào `Organization`, `Shop`, `User`. Migration: `pnpm db:migrate --name add_violation_records`.

Ý nghĩa `pointsDeducted`: TikTok = điểm AHR bị trừ; Shopee = điểm Sao Quả Tạ bị cộng. Cả hai đều là số dương.

### 4.2 Types [ADD]

```ts
export type AppealStatus = "NONE" | "SUBMITTED" | "ACCEPTED" | "REJECTED";

export interface ViolationDto {
  id: string;
  shopId: string;
  occurredAt: string;
  pointsDeducted: number;
  reason: string;
  referenceCode: string | null;
  appealStatus: AppealStatus;
  appealDeadline: string | null;
  appealNote: string | null;
  resolvedAt: string | null;
  createdBy: { id: string; name: string };
  createdAt: string;
}

export interface ViolationSummaryDto {
  last90DaysPoints: number;   // tổng pointsDeducted với occurredAt >= hôm nay − 89 ngày
  openAppeals: number;        // appealStatus = SUBMITTED
  pendingAppeals: number;     // appealStatus = NONE và appealDeadline >= hôm nay
}
```

`ShopDetailDto` [ADD] field `violationSummary: ViolationSummaryDto`.

### 4.3 API [ADD]

#### `GET /api/shops/[shopId]/violations` — Auth: STAFF

Query: `page`, `limit` (mặc định 20, tối đa 100), `appealStatus` (optional). Response 200: `{ data: ViolationDto[], meta, summary: ViolationSummaryDto }` sắp `occurredAt desc`.

#### `POST /api/shops/[shopId]/violations` — Auth: STAFF

```ts
export const createViolationSchema = z.object({
  occurredAt: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, { message: "validation.date" }),
  pointsDeducted: z.number().min(0, { message: "validation.pointsRange" }).max(1000, { message: "validation.pointsRange" }),
  reason: z.string().trim().min(5, { message: "validation.reasonMin" }).max(500, { message: "validation.reasonMax" }),
  referenceCode: z.string().trim().max(64).nullable().default(null),
  appealDeadline: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, { message: "validation.date" }).nullable().default(null),
  appealNote: z.string().trim().max(1000).nullable().default(null),
}).refine((v) => !v.appealDeadline || v.appealDeadline >= v.occurredAt, { message: "validation.appealDeadlineOrder", path: ["appealDeadline"] });
```

Xử lý: insert record; nếu `appealDeadline != null` và `appealDeadline >= hôm nay` → tạo task AUTO:

- `dedupeKey = \`${shopId}:violation:${violationId}:appeal\``
- `title = "Nộp khiếu nại vi phạm {referenceCode} trước {appealDeadline} – {shopName}"` (`referenceCode` null → thay bằng "(không mã)")
- `description = "Lý do: {reason}\nĐiểm trừ: {pointsDeducted}\n\nViệc cần làm:\n1. Chuẩn bị bằng chứng (ảnh, vận đơn, hội thoại).\n2. Nộp khiếu nại trong Seller Center trước hạn.\n3. Cập nhật trạng thái khiếu nại trong Nhật ký vi phạm của ShopPulse."`
- `priority = HIGH`, `dueAt = appealDeadline lúc 12:00 APP_TIMEZONE`, `assigneeId = shop.assigneeId`, `metricKey = null`, `ruleId = null`, `source = AUTO`.

Response 201: `ViolationDto`. Lỗi: 400, 404.

#### `PATCH /api/shops/[shopId]/violations/[violationId]` — Auth: STAFF

Body: `createViolationSchema.partial().extend({ appealStatus: z.enum(["NONE","SUBMITTED","ACCEPTED","REJECTED"]).optional() })`, cùng refine.

Quy tắc:

- `appealStatus` chuyển từ `NONE` sang giá trị khác → task khiếu nại (theo `dedupeKey`) nếu đang OPEN / IN_PROGRESS chuyển `DONE`, `completionNote = "Trạng thái khiếu nại: {appealStatus}"`, `completedAt = now`.
- `appealStatus` = `ACCEPTED` hoặc `REJECTED` → `resolvedAt = now`; quay về `SUBMITTED` / `NONE` → `resolvedAt = null`.

Response 200: `ViolationDto`. Lỗi: 400, 404.

#### `DELETE /api/shops/[shopId]/violations/[violationId]` — Auth: MANAGER

Xoá cứng; task khiếu nại liên quan nếu còn mở → `SKIPPED`, `completionNote = "Bản ghi vi phạm đã bị xoá"`. Response 200: `{ id }`. Lỗi: 403, 404.

`vi.json` [ADD]: `validation.pointsRange` "Điểm từ 0 đến 1000", `validation.reasonMin` "Lý do tối thiểu 5 ký tự", `validation.reasonMax` "Lý do tối đa 500 ký tự", `validation.appealDeadlineOrder` "Hạn khiếu nại phải từ ngày vi phạm trở đi", nhóm `violations.*` (tiêu đề tab "Vi phạm & khiếu nại", cột, trạng thái: NONE "Chưa khiếu nại", SUBMITTED "Đã nộp", ACCEPTED "Được chấp nhận", REJECTED "Bị từ chối", empty "Chưa ghi nhận vi phạm nào.", deleteConfirm "Xoá bản ghi vi phạm này?").

### 4.4 UI [ADD / MODIFY]

- `src/app/(app)/shops/[shopId]/page.tsx` [MODIFY]: thêm `Tabs` dưới HealthGauge: "Chỉ số" (nội dung cũ) · "Vi phạm & khiếu nại" (`ViolationTable`). Cạnh HealthGauge hiện dòng `Điểm trừ 90 ngày: {last90DaysPoints} · Khiếu nại đang chờ: {openAppeals}`.
- `src/components/violations/ViolationTable.tsx` [ADD]: props `{ shopId: string; canDelete: boolean }`. Hook `useViolations(shopId)`. Cột: Ngày, Điểm trừ, Lý do, Mã tham chiếu, Hạn khiếu nại (đỏ nếu < 2 ngày và status NONE), Trạng thái (Select đổi ngay → PATCH), Sửa, Xoá. Nút "Ghi nhận vi phạm" mở `Sheet` chứa `ViolationForm`. Empty → `EmptyState` `violations.empty`.
- `src/components/violations/ViolationForm.tsx` [ADD]: props `{ shopId: string; initial?: ViolationDto; onSuccess: () => void }`. Field theo schema; `appealDeadline` là `input type="date"`.
- `src/hooks/useViolations.ts` [ADD]: `{ list(page, appealStatus), create, update, remove }`; query key `["shops", shopId, "violations", { page, appealStatus }]`; invalidate thêm `["shops", shopId]` và `["tasks"]`.
- `src/lib/services/violation-service.ts` [ADD]: `listViolations`, `createViolation` (kèm tạo task), `updateViolation` (kèm đóng task), `deleteViolation`, `getViolationSummary`.
- `src/lib/validation/violation.ts` [ADD].
- Dashboard `StaleShopsAlert` không đổi. `TodayTasksPanel` tự hiển thị task khiếu nại vì là task thường.

Cây thư mục `00-overview.md` [ADD] các file trên vào đúng thư mục (`components/violations/`, `hooks/`, `lib/services/`, `lib/validation/`, `app/api/shops/[shopId]/violations/route.ts`, `app/api/shops/[shopId]/violations/[violationId]/route.ts`).

---

## [5] D5 — Tests bổ sung (`04-tests.md`)

### 5.1 `src/test/ahr.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| AH1 | — | `getAhrTier(200)` | `"HEALTHY"` |
| AH2 | — | `getAhrTier(199)` | `"NEEDS_IMPROVEMENT"` |
| AH3 | — | `getAhrTier(150)` | `"AT_RISK"` |
| AH4 | — | `getAhrTier(0)` | `"DEACTIVATED"` |
| AH5 | Ngưỡng `tiktok_ahr` warning 260, critical 199 | `evaluateMetric(199, t)` | `"CRITICAL"`; `evaluateMetric(260, t)` → `"WARNING"`; `evaluateMetric(261, t)` → `"OK"` |

### 5.2 `src/test/trend.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| T1 | `tiktok_ahr` hôm nay 201, 7 ngày trước 240, rule window 7 delta 20 | `generateTrendTasks` | 1 task, title chứa `giảm 39điểm trong 7 ngày`, `dedupeKey = "<shopId>:trend:tiktok_ahr:<date>"` |
| T2 | Như T1 nhưng 7 ngày trước 215 | `generateTrendTasks` | 0 task (delta 14 < 20) |
| T3 | Không có snapshot trong cửa sổ 7 + 3 ngày | `generateTrendTasks` | 0 task |
| T4 | `shopee_rating` hôm nay 4.5, 7 ngày trước 4.8, rule delta 0.2 | `generateTrendTasks` | 1 task, delta hiển thị `0.30` |
| T5 | Chỉ số LOWER_IS_BETTER `tiktok_ldr` hôm nay 1, 7 ngày trước 3, rule delta 1 | `generateTrendTasks` | 0 task (chỉ số cải thiện, delta âm) |
| T6 | `existingDedupeKeys` chứa key của ngày đó | `generateTrendTasks` | 0 task |

### 5.3 `src/test/validation.test.ts` [U, bổ sung]

| # | Given | When | Then |
|---|---|---|---|
| V10 | rule TREND thiếu `deltaThreshold` | `ruleSchema.safeParse` | fail, message `validation.ruleTrendFields` |
| V11 | violation `appealDeadline` trước `occurredAt` | `createViolationSchema.safeParse` | fail, path `appealDeadline` |

### 5.4 `e2e/violations.spec.ts` [E]

| # | Given | When | Then |
|---|---|---|---|
| VL1 | Đăng nhập staff, shop "Shop Demo TikTok 1", tab "Vi phạm & khiếu nại" | Ghi nhận vi phạm: ngày hôm nay, 10 điểm, lý do "Giao trễ đơn X", hạn khiếu nại hôm nay + 3 | Bảng có 1 dòng; `/tasks` có task tiêu đề bắt đầu `Nộp khiếu nại vi phạm` với badge HIGH |
| VL2 | Sau VL1 | Đổi trạng thái sang "Đã nộp" | Task trên chuyển "Hoàn thành", ghi chú `Trạng thái khiếu nại: SUBMITTED` |
| VL3 | Mở `/shops/<id>` | Xem dòng tóm tắt | `Điểm trừ 90 ngày: 10` |
| VL4 | Seed shop Demo TikTok 1 (AHR 240 → 201) | Mở `/tasks?status=OPEN,IN_PROGRESS&shopId=<id>` | Có task badge "Xu hướng" cho AHR |

Coverage §8.11 [MODIFY]: thêm `src/lib/metrics/ahr.ts` và `src/lib/tasks/trend.ts` vào danh sách ≥ 90%.

---

## [6] Phase thực hiện

Áp dụng sau khi hoàn thành Phase 7 của `05-phases.md`, hoặc gộp vào lộ trình gốc nếu chưa bắt đầu build (khuyến nghị: gộp — D1/D2 vào Phase 2–3a, D3 vào Phase 3a/3d/5, D4 vào phase riêng bên dưới). Nếu build từ đầu với Delta này, lệnh Verify Phase 2 đổi `TaskRule` count thành **43**.

**STOP rule** như `05-phases.md`.

### Phase 8a — AHR + TREND core

**Đọc:** Delta [2], [3]; `01-data.md` §3.4, §3.5.

**Files (8):** `prisma/schema.prisma`, `src/types/index.ts`, `src/lib/metrics/catalog.ts`, `src/lib/metrics/ahr.ts`, `src/lib/tasks/trend.ts`, `src/lib/tasks/templates.ts`, `src/i18n/vi.json`, `src/lib/settings/defaults.ts`.

**Steps:** sửa enum + field TaskRule; `pnpm db:migrate --name add_trend_rules`; xoá `tiktok_violation_points`, thêm `tiktok_ahr`; viết `ahr.ts`, `trend.ts`; mở rộng `renderTemplate`; cập nhật seed rule (43); cập nhật `vi.json`.

**Verify:**

```bash
pnpm typecheck && pnpm lint
pnpm prisma validate
```

**Commit:** `feat(metrics): replace violation points with account health rating and add trend rules`

### Phase 8b — Tests + seed + service

**Files (6):** `src/test/ahr.test.ts`, `src/test/trend.test.ts`, `src/test/validation.test.ts`, `prisma/seed.ts`, `src/lib/services/metric-service.ts`, `src/lib/validation/settings.ts`.

**Verify:**

```bash
pnpm test -- --coverage        # AH1–AH5, T1–T6, V10 pass; coverage ≥ 90% cho ahr.ts, trend.ts
pnpm db:seed
pnpm prisma db execute --stdin <<< "SELECT count(*) FROM \"TaskRule\";"   # → 43
curl -s -b cookies.txt "http://localhost:3000/api/tasks?shopId=<tiktok1>&status=OPEN" | grep -o '"metricKey":"tiktok_ahr","metricLevel":null'   # → khớp (task TREND)
```

**Commit:** `feat(engine): wire trend tasks into metric upsert with tests and seed`

### Phase 8c — Violation log: data + API

**Files (7):** `prisma/schema.prisma`, `src/types/index.ts`, `src/lib/validation/violation.ts`, `src/lib/services/violation-service.ts`, `src/app/api/shops/[shopId]/violations/route.ts`, `src/app/api/shops/[shopId]/violations/[violationId]/route.ts`, `src/lib/services/shop-service.ts` (thêm `violationSummary`, `ahrValue`).

**Steps:** model + `pnpm db:migrate --name add_violation_records`; service; routes; DTO.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
curl -s -b cookies.txt -X POST http://localhost:3000/api/shops/<tiktok1>/violations -H "Content-Type: application/json" -d '{"occurredAt":"'$(date +%F)'","pointsDeducted":10,"reason":"Giao tre don X","appealDeadline":"'$(date -d "+3 days" +%F)'"}' | grep -o '"appealStatus":"NONE"'   # → khớp
curl -s -b cookies.txt "http://localhost:3000/api/tasks?shopId=<tiktok1>&status=OPEN" | grep -o 'Nộp khiếu nại vi phạm'   # → khớp
```

**Commit:** `feat(violations): add violation records api with appeal tasks`

### Phase 8d — Violation log + AHR UI

**Files (8):** `src/components/shops/AhrTierBadge.tsx`, `src/components/violations/ViolationTable.tsx`, `src/components/violations/ViolationForm.tsx`, `src/hooks/useViolations.ts`, `src/app/(app)/shops/[shopId]/page.tsx`, `src/components/shops/MetricBreakdownTable.tsx`, `src/components/shops/ShopCard.tsx`, `src/components/settings/RuleForm.tsx`.

Commit 2 (3 file): `src/components/settings/RuleTable.tsx`, `src/components/tasks/TaskItem.tsx`, `src/components/metrics/MetricEntryForm.tsx`.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
# Trình duyệt: /shops/<tiktok1> có badge "AHR 201 · Khoẻ mạnh", tab "Vi phạm & khiếu nại" hoạt động; /settings/rules tạo được rule Xu hướng.
```

**Commit 1:** `feat(ui): add ahr tier badge and violation log tab`
**Commit 2:** `feat(ui): show trend rules and trend tasks`

### Phase 8e — E2E + docs

**Files (3):** `e2e/violations.spec.ts`, `README.md`, `CLAUDE.md` (link Delta).

**Verify:**

```bash
pnpm db:seed && pnpm test:e2e     # → 22 passed (18 cũ + VL1–VL4)
pnpm build
```

**Commit:** `test(e2e): cover violation log and trend tasks`
