# ShopPulse — Delta Spec · TikTok Issue Center & mở rộng

Ngày: 2026-09-29 · Áp dụng cho: `specs/shop-pulse/` (00–05) **sau** `delta-2026-09-29-tiktok-ahr.md` · Loại: Change Request

Đọc kèm: `01-data.md` §3.3–§3.7, `02-api.md` §4.5, `03-ui.md` §6.3, §6.5, `delta-2026-09-29-tiktok-ahr.md`.

---

## [0] Ngữ cảnh và nguồn

### 0.1 Nguồn

TikTok Shop Seller University VN — Feature Guide › Seller › Returns & Refunds › **Issue Center** (ngày 28/09/2026, áp dụng Việt Nam). User đã paste toàn văn. Sự thật rút ra (nguyên văn số liệu):

| Mục | Nội dung |
|---|---|
| Vị trí | Seller Center > Orders > Help & Automations > tab Issue Center. Dashboard có **5 insight**, mỗi insight 1 summary card, nút Check / Check Now dẫn tới trang Manage Return hoặc Manage Order đã lọc sẵn. |
| Insight 1 — chỉ số ảnh hưởng hiển thị | 4 chỉ số đơn hàng: **Shop Performance Score (SPS)**; **Negative Review Rate (NRR)** 7 ngày gần nhất; **Late Dispatch Rate (LDR)** 7 ngày gần nhất; **Seller Fault Refund Rate (SFRR)** 7 ngày gần nhất. |
| Insight 2 | Yêu cầu trả hàng / hoàn tiền có cửa sổ khiếu nại **đóng trong 24 giờ tới**. |
| Insight 3 | Yêu cầu trả hàng hiện chưa khiếu nại được nhưng **sắp đủ điều kiện** (speedy refund đang vận chuyển, platform takeover đang chờ sàn xem xét). |
| Insight 4 | Yêu cầu trả hàng sẽ bị **sàn tự động chấp nhận nếu không xử lý trong 24 giờ**. |
| Insight 5 | Đơn bị **sàn huỷ**, chia 3 lý do: giao hàng thất bại; hàng hư hỏng / thất lạc khi vận chuyển; quá hạn lấy hàng (collection timeout). |
| Email | Đăng ký nhận email hằng ngày cho insight 2 và 4 (bài ghi 9:30 AM ở phần hướng dẫn và 9:00 AM giờ địa phương ở FAQ). |
| Dữ liệu | 14 ngày gần nhất, làm mới mỗi lần mở trang. Tài khoản chính và tài khoản phụ có quyền Manage Return / Manage Order đều xem được. |

### 0.2 Điều rút ra cho ShopPulse

1. TikTok chốt 4 chỉ số ảnh hưởng hiển thị: SPS, NRR, LDR, SFRR. Catalog hiện có SPS, NRR, LDR, SFCR — thiếu **SFRR**.
2. Issue Center là **hàng đợi việc có hạn 24 giờ** (khiếu nại sắp đóng, tự động chấp nhận). Đây chính là loại việc Task Engine phải đẩy lên URGENT với hạn tính bằng giờ, không phải 24 giờ như rule mặc định.
3. Đơn bị sàn huỷ theo 3 lý do là chỉ số vận hành rõ ràng; "quá hạn lấy hàng" do shop, hai lý do còn lại do vận chuyển.
4. Ý tưởng "1 dashboard gom mọi vấn đề cần chú ý" đúng với nhu cầu của nhân viên vận hành nhiều shop → ShopPulse thêm panel **"Cần xử lý ngay"** gom các chỉ số có hạn của mọi shop.
5. Nhân viên vào Issue Center mỗi sáng sau email 9:00–9:30 → thêm routine riêng cho shop TikTok.

### 0.3 Assumptions Log (bổ sung)

| Giả định | Lý do | Ảnh hưởng nếu sai |
|---|---|---|
| Số liệu của 5 insight được nhân viên **đọc từ Issue Center và nhập tay** mỗi ngày | Không có API; Issue Center là màn hình web. | Nếu có API: connector, model không đổi. |
| Ngưỡng cho chỉ số đếm (COUNT) của Issue Center: WARNING = 1 với 2 chỉ số có hạn 24 giờ | Chỉ cần 1 yêu cầu bị tự động chấp nhận là mất tiền; phải sinh việc ngay. | Trưởng nhóm chỉnh trong `/settings/thresholds`. |
| SFRR và SFCR là 2 chỉ số khác nhau, giữ cả hai | Bài Issue Center nêu SFRR; nguồn 2026 trước đó nêu SFCR với ngưỡng 2.5%. | Nếu Seller Center chỉ còn 1 chỉ số: tắt chỉ số kia bằng `isEnabled = false`, không cần Delta. |
| Đơn bị sàn huỷ nhập theo **tổng 14 ngày** như Issue Center hiển thị | Khớp cách sàn trình bày, nhân viên chép số trực tiếp. | Nếu muốn theo ngày: đổi `period` của 3 chỉ số, ngưỡng chỉnh lại. |
| Không gửi email digest từ ShopPulse | Tier B, Out of Scope 5; TikTok đã có email riêng. | Thêm channel EMAIL vào `NotificationService` qua Delta khác. |

### 0.4 Out of Scope (bổ sung)

16. Không đọc danh sách ticket trả hàng / hoàn tiền hay đơn bị huỷ từ Seller Center; chỉ nhận **số lượng** do nhân viên nhập.
17. Không gửi email digest hằng ngày.
18. Không quản lý quy trình xử lý từng ticket trả hàng (đó là việc trên Seller Center).

---

## [1] Tóm tắt thay đổi

| Mã | Loại | Nội dung |
|---|---|---|
| I1 | [ADD] | 7 chỉ số TikTok mới theo Issue Center: `tiktok_sfrr`, `tiktok_returns_appeal_closing`, `tiktok_returns_review_due`, `tiktok_returns_appeal_opening`, `tiktok_cancel_delivery_failed`, `tiktok_cancel_damaged_lost`, `tiktok_cancel_collection_timeout`. |
| I2 | [ADD] | 2 field mới trong `MetricDefinition`: `group` (nhóm hiển thị trên form) và `period` (kỳ dữ liệu), áp cho toàn bộ catalog. |
| I3 | [MODIFY] | Rule ALERT mặc định có **override theo chỉ số** cho 2 chỉ số hạn 24 giờ: ưu tiên và hạn ngắn hơn. |
| I4 | [ADD] | Routine `check_issue_center` chỉ cho shop TIKTOK; `generateRoutineTasks` lọc theo `rule.platform`. |
| I5 | [ADD] | Panel Dashboard **"Cần xử lý ngay"** gom chỉ số có hạn của mọi shop (`DashboardSummaryDto.issues`). |
| I6 | [MODIFY] | `MetricEntryForm` chia section theo `group`; hint 7 ngày / 14 ngày; seed; tests; phases. |

Catalog sau Delta: Shopee 10 + TikTok 15 = **25** chỉ số. Seed: 25 `MetricThreshold`; 50 ALERT + 5 ROUTINE + 3 TREND = **58** `TaskRule`.

---

## [2] I1 + I2 — Catalog

### 2.1 Types [MODIFY] `src/types/index.ts`

```ts
export type TiktokMetricKey =
  | "tiktok_ldr"
  | "tiktok_sfcr"
  | "tiktok_sfrr"                        // [ADD]
  | "tiktok_nrr"
  | "tiktok_ahr"
  | "tiktok_sps"
  | "tiktok_returns_appeal_closing"      // [ADD]
  | "tiktok_returns_review_due"          // [ADD]
  | "tiktok_returns_appeal_opening"      // [ADD]
  | "tiktok_cancel_delivery_failed"      // [ADD]
  | "tiktok_cancel_damaged_lost"         // [ADD]
  | "tiktok_cancel_collection_timeout"   // [ADD]
  | "tiktok_pending_orders"
  | "tiktok_pending_chats"
  | "tiktok_low_ratings";

export type MetricGroup = "PERFORMANCE" | "AFTERSALES" | "CANCELLATIONS" | "WORKLOAD";
export type MetricPeriod = "CURRENT" | "LAST_7_DAYS" | "LAST_14_DAYS" | "ROLLING_90_DAYS" | "QUARTER_TO_DATE";

export interface MetricDefinition {
  // ... field cũ giữ nguyên
  group: MetricGroup;   // [ADD]
  period: MetricPeriod; // [ADD]
}

// CatalogItemDto [ADD 3 field]
group: MetricGroup;
period: MetricPeriod;
periodLabel: string; // vi.json periods.<period>
```

### 2.2 Bảng `group` / `period` cho toàn bộ catalog [MODIFY] `src/lib/metrics/catalog.ts`

| key | group | period |
|---|---|---|
| shopee_nfr | PERFORMANCE | LAST_7_DAYS |
| shopee_lsr | PERFORMANCE | LAST_7_DAYS |
| shopee_prep_time | PERFORMANCE | LAST_7_DAYS |
| shopee_response_rate | PERFORMANCE | LAST_7_DAYS |
| shopee_response_time | PERFORMANCE | LAST_7_DAYS |
| shopee_rating | PERFORMANCE | CURRENT |
| shopee_penalty_points | PERFORMANCE | QUARTER_TO_DATE |
| shopee_pending_orders | WORKLOAD | CURRENT |
| shopee_pending_chats | WORKLOAD | CURRENT |
| shopee_low_ratings | WORKLOAD | CURRENT |
| tiktok_ldr | PERFORMANCE | LAST_7_DAYS |
| tiktok_sfcr | PERFORMANCE | LAST_7_DAYS |
| tiktok_sfrr | PERFORMANCE | LAST_7_DAYS |
| tiktok_nrr | PERFORMANCE | LAST_7_DAYS |
| tiktok_ahr | PERFORMANCE | ROLLING_90_DAYS |
| tiktok_sps | PERFORMANCE | CURRENT |
| tiktok_returns_appeal_closing | AFTERSALES | CURRENT |
| tiktok_returns_review_due | AFTERSALES | CURRENT |
| tiktok_returns_appeal_opening | AFTERSALES | CURRENT |
| tiktok_cancel_delivery_failed | CANCELLATIONS | LAST_14_DAYS |
| tiktok_cancel_damaged_lost | CANCELLATIONS | LAST_14_DAYS |
| tiktok_cancel_collection_timeout | CANCELLATIONS | LAST_14_DAYS |
| tiktok_pending_orders | WORKLOAD | CURRENT |
| tiktok_pending_chats | WORKLOAD | CURRENT |
| tiktok_low_ratings | WORKLOAD | CURRENT |

Thứ tự trong `METRIC_CATALOG` = thứ tự bảng trên (form nhập và bảng chỉ số hiển thị theo thứ tự này).

### 2.3 Định nghĩa 7 chỉ số mới [ADD]

```ts
{ key: "tiktok_sfrr", platform: "TIKTOK", labelKey: "metrics.tiktok_sfrr.label", unit: "PERCENT", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 1.5, defaultCritical: 2.5, defaultWeight: 3, group: "PERFORMANCE", period: "LAST_7_DAYS" },
{ key: "tiktok_returns_appeal_closing", platform: "TIKTOK", labelKey: "metrics.tiktok_returns_appeal_closing.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 1, defaultCritical: 5, defaultWeight: 2, group: "AFTERSALES", period: "CURRENT" },
{ key: "tiktok_returns_review_due", platform: "TIKTOK", labelKey: "metrics.tiktok_returns_review_due.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 1, defaultCritical: 5, defaultWeight: 3, group: "AFTERSALES", period: "CURRENT" },
{ key: "tiktok_returns_appeal_opening", platform: "TIKTOK", labelKey: "metrics.tiktok_returns_appeal_opening.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 3, defaultCritical: 10, defaultWeight: 1, group: "AFTERSALES", period: "CURRENT" },
{ key: "tiktok_cancel_delivery_failed", platform: "TIKTOK", labelKey: "metrics.tiktok_cancel_delivery_failed.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 3, defaultCritical: 10, defaultWeight: 1, group: "CANCELLATIONS", period: "LAST_14_DAYS" },
{ key: "tiktok_cancel_damaged_lost", platform: "TIKTOK", labelKey: "metrics.tiktok_cancel_damaged_lost.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 2, defaultCritical: 5, defaultWeight: 1, group: "CANCELLATIONS", period: "LAST_14_DAYS" },
{ key: "tiktok_cancel_collection_timeout", platform: "TIKTOK", labelKey: "metrics.tiktok_cancel_collection_timeout.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 1, defaultCritical: 3, defaultWeight: 2, group: "CANCELLATIONS", period: "LAST_14_DAYS" },
```

Ngưỡng là nội bộ mặc định; SFRR mượn ngưỡng SFCR (1.5 / 2.5) vì bài không nêu ngưỡng.

### 2.4 `vi.json` [ADD / MODIFY]

| key | giá trị |
|---|---|
| metrics.tiktok_sfrr.label | Tỷ lệ hoàn tiền do người bán (SFRR) |
| metrics.tiktok_sfrr.hint | % đơn hoàn tiền do lỗi shop, 7 ngày gần nhất. Xem tại Issue Center > Insight 1 > Check. |
| metrics.tiktok_returns_appeal_closing.label | Yêu cầu trả hàng sắp hết hạn khiếu nại (24 giờ) |
| metrics.tiktok_returns_appeal_closing.hint | Số yêu cầu trả hàng / hoàn tiền có cửa sổ khiếu nại đóng trong 24 giờ tới. Issue Center > Insight 2. |
| metrics.tiktok_returns_review_due.label | Yêu cầu trả hàng cần duyệt gấp (tự động chấp nhận sau 24 giờ) |
| metrics.tiktok_returns_review_due.hint | Số yêu cầu sẽ bị sàn tự động chấp nhận nếu không xử lý trong 24 giờ. Issue Center > Insight 4. |
| metrics.tiktok_returns_appeal_opening.label | Yêu cầu trả hàng sắp mở cửa sổ khiếu nại |
| metrics.tiktok_returns_appeal_opening.hint | Số yêu cầu chưa khiếu nại được nhưng sắp đủ điều kiện. Issue Center > Insight 3. |
| metrics.tiktok_cancel_delivery_failed.label | Đơn sàn huỷ: giao hàng thất bại |
| metrics.tiktok_cancel_delivery_failed.hint | Số đơn bị sàn huỷ vì không giao được, 14 ngày. Issue Center > Insight 5. |
| metrics.tiktok_cancel_damaged_lost.label | Đơn sàn huỷ: hư hỏng / thất lạc |
| metrics.tiktok_cancel_damaged_lost.hint | Số đơn bị sàn huỷ vì hàng hư hỏng hoặc thất lạc khi vận chuyển, 14 ngày. Issue Center > Insight 5. |
| metrics.tiktok_cancel_collection_timeout.label | Đơn sàn huỷ: quá hạn lấy hàng |
| metrics.tiktok_cancel_collection_timeout.hint | Số đơn bị sàn huỷ vì không bàn giao đúng hạn, 14 ngày. Issue Center > Insight 5. |
| metrics.tiktok_ldr.hint [MODIFY] | % đơn bàn giao trễ hoặc quá SLA, 7 ngày gần nhất. Issue Center > Insight 1. |
| metrics.tiktok_nrr.hint [MODIFY] | % đánh giá tiêu cực, 7 ngày gần nhất. Issue Center > Insight 1. |
| metrics.tiktok_sps.hint [MODIFY] | Shop Performance Score 0–5. Issue Center > Insight 1. |
| groups.PERFORMANCE | Hiệu suất |
| groups.AFTERSALES | Trả hàng & khiếu nại |
| groups.CANCELLATIONS | Đơn bị sàn huỷ |
| groups.WORKLOAD | Việc tồn |
| periods.CURRENT | tại thời điểm nhập |
| periods.LAST_7_DAYS | 7 ngày gần nhất |
| periods.LAST_14_DAYS | 14 ngày gần nhất |
| periods.ROLLING_90_DAYS | 90 ngày gần nhất |
| periods.QUARTER_TO_DATE | quý hiện tại |

### 2.5 Action hint [ADD] `DEFAULT_ACTION_HINTS`

| metricKey | Action hint |
|---|---|
| tiktok_sfrr | 1. Vào Seller Center > Orders > Help & Automations > Issue Center > Insight 1 > Check, xem danh sách đơn hoàn tiền do shop trong 7 ngày.\n2. Phân loại nguyên nhân (sai hàng, thiếu hàng, hư hỏng do đóng gói).\n3. Sửa quy trình đóng gói hoặc kiểm hàng tương ứng và ghi kết quả vào nhiệm vụ. |
| tiktok_returns_appeal_closing | 1. Vào Issue Center > Insight 2 > Check Now.\n2. Với từng ticket: quyết định khiếu nại hay không, nộp bằng chứng ngay trong phiên làm việc này.\n3. Cập nhật số còn lại vào ShopPulse sau khi xử lý. |
| tiktok_returns_review_due | 1. Vào Issue Center > Insight 4 > Check Now NGAY.\n2. Duyệt hoặc từ chối từng yêu cầu trước hạn 24 giờ để tránh sàn tự động chấp nhận.\n3. Cập nhật số còn lại vào ShopPulse sau khi xử lý. |
| tiktok_returns_appeal_opening | 1. Vào Issue Center > Insight 3 > Check Now, ghi lại mã ticket.\n2. Chuẩn bị bằng chứng trước; kiểm tra lại mỗi sáng cho tới khi nút khiếu nại mở. |
| tiktok_cancel_delivery_failed | 1. Vào Issue Center > Insight 5 > Check Now (lý do giao hàng thất bại).\n2. Liên hệ khách xác nhận địa chỉ / số điện thoại với đơn giá trị cao.\n3. Nếu tập trung ở một đơn vị vận chuyển, báo trưởng nhóm. |
| tiktok_cancel_damaged_lost | 1. Vào Issue Center > Insight 5 > Check Now (lý do hư hỏng / thất lạc).\n2. Tạo yêu cầu bồi thường với đơn vị vận chuyển cho từng đơn.\n3. Rà quy cách đóng gói sản phẩm dễ vỡ. |
| tiktok_cancel_collection_timeout | 1. Vào Issue Center > Insight 5 > Check Now (lý do quá hạn lấy hàng).\n2. Kiểm tra lịch lấy hàng và tồn kho của các đơn đó; đây là lỗi vận hành của shop.\n3. Bàn giao mọi đơn Chờ giao trong ngày; báo trưởng nhóm nếu thiếu nhân lực. |

---

## [3] I3 + I4 — Rule override và routine theo sàn

### 3.1 Override rule ALERT mặc định [MODIFY] `src/lib/settings/defaults.ts`

```ts
export interface AlertRuleParams { priority: TaskPriority; dueInHours: number }

const DEFAULT_ALERT_PARAMS: Record<MetricLevel, AlertRuleParams> = {
  OK: { priority: "LOW", dueInHours: 0 },          // không dùng
  WARNING: { priority: "MEDIUM", dueInHours: 24 },
  CRITICAL: { priority: "URGENT", dueInHours: 4 },
};

const ALERT_PARAM_OVERRIDES: Partial<Record<MetricKey, Partial<Record<MetricLevel, AlertRuleParams>>>> = {
  tiktok_returns_review_due: {
    WARNING: { priority: "HIGH", dueInHours: 6 },
    CRITICAL: { priority: "URGENT", dueInHours: 2 },
  },
  tiktok_returns_appeal_closing: {
    WARNING: { priority: "HIGH", dueInHours: 6 },
    CRITICAL: { priority: "URGENT", dueInHours: 2 },
  },
  tiktok_cancel_collection_timeout: {
    WARNING: { priority: "HIGH", dueInHours: 12 },
  },
};

export function getDefaultAlertRuleParams(metricKey: MetricKey, level: "WARNING" | "CRITICAL"): AlertRuleParams
```

`createDefaultSettings` dùng hàm này khi seed rule ALERT. Rule đã tồn tại không bị ghi đè (idempotent).

Task HIGH không gửi notification theo quy tắc cũ (chỉ URGENT). [MODIFY] `01-data.md` §3.9: gửi `TASK_CREATED` cho task AUTO có `priority ∈ {HIGH, URGENT}` **và** `dueInHours ≤ 6` của rule, tức mọi task sinh từ 2 chỉ số hạn 24 giờ đều có thông báo.

### 3.2 Routine theo sàn [MODIFY] `src/lib/tasks/routines.ts`

- `RoutineDefinition` [ADD] `platform: Platform | null`.
- `generateRoutineTasks`: chỉ áp rule có `rule.platform === null` hoặc `rule.platform === shop.platform`.
- [ADD] routine:

```ts
{ routineKey: "check_issue_center", platform: "TIKTOK", titleKey: "routines.check_issue_center.title", descriptionKey: "routines.check_issue_center.description", priority: "HIGH", dueHourLocal: 11 },
```

`vi.json`:

| key | giá trị |
|---|---|
| routines.check_issue_center.title | Kiểm tra Issue Center – {shopName} |
| routines.check_issue_center.description | Mở Seller Center > Orders > Help & Automations > Issue Center. Đọc 5 insight, xử lý ngay insight 2 và 4 (hạn 24 giờ), rồi nhập số của nhóm "Trả hàng & khiếu nại" và "Đơn bị sàn huỷ" vào ShopPulse. |

Seed `TaskRule` ROUTINE cho routine này có `platform = "TIKTOK"`. 4 routine cũ có `platform = null`.

---

## [4] I5 — Panel "Cần xử lý ngay" trên Dashboard

### 4.1 Types [ADD]

```ts
export interface IssueItemDto {
  shopId: string;
  shopName: string;
  platform: Platform;
  metricKey: MetricKey;
  value: number;
  level: "WARNING" | "CRITICAL";
  date: string;          // ngày snapshot
  isStale: boolean;      // date < hôm nay
  taskId: string | null; // task OPEN / IN_PROGRESS có dedupeKey `${shopId}:${metricKey}:${level}`
}

// DashboardSummaryDto [ADD]
issues: IssueItemDto[];
```

### 4.2 Logic [ADD] `src/lib/metrics/issues.ts`

```ts
export const ISSUE_METRIC_KEYS: readonly MetricKey[] = [
  "tiktok_returns_review_due",
  "tiktok_returns_appeal_closing",
  "tiktok_cancel_collection_timeout",
  "tiktok_returns_appeal_opening",
  "shopee_pending_orders",
  "tiktok_pending_orders",
  "shopee_pending_chats",
  "tiktok_pending_chats",
  "shopee_low_ratings",
  "tiktok_low_ratings",
];

export function buildIssueItems(input: {
  shops: Array<{ id: string; name: string; platform: Platform }>;
  latest: Array<{ shopId: string; metricKey: MetricKey; value: number; date: string }>; // snapshot mới nhất của từng (shop, metric)
  thresholds: Record<string, ThresholdConfig>;
  openTasks: Array<{ id: string; dedupeKey: string }>;
  today: string;
}): IssueItemDto[]
```

Thuật toán: với mỗi `latest` có `metricKey ∈ ISSUE_METRIC_KEYS` → `level = evaluateMetric(value, thresholds[metricKey])`; `OK` → bỏ. Sắp: `level` CRITICAL trước; rồi theo thứ tự `ISSUE_METRIC_KEYS`; rồi `value desc`. Tối đa 20 phần tử. `taskId` tra từ `openTasks` theo `dedupeKey`.

`GET /api/dashboard/summary` [MODIFY]: thêm `issues` (query snapshot mới nhất bằng `DISTINCT ON (shopId, metricKey) ... ORDER BY date DESC`, chỉ shop ACTIVE).

### 4.3 UI [ADD] `src/components/dashboard/IssueCenterPanel.tsx`

Props `{ issues: IssueItemDto[] }`. Đặt ngay dưới `StaleShopsAlert`, trên grid shop. Ẩn khi rỗng.

```text
┌ Cần xử lý ngay (4) ───────────────────────────────────────────────────────┐
│ ● NC  Shop C · TikTok  Yêu cầu trả hàng cần duyệt gấp: 6      [Mở nhiệm vụ]│
│ ● CB  Shop C · TikTok  Sắp hết hạn khiếu nại: 2               [Mở nhiệm vụ]│
│ ● CB  Shop A · Shopee  Đơn chờ xử lý: 24  (dữ liệu hôm qua)   [Nhập chỉ số]│
└────────────────────────────────────────────────────────────────────────────┘
```

- Nút: `taskId` có → "Mở nhiệm vụ" → `/tasks/[taskId]`; không → "Nhập chỉ số" → `/shops/[shopId]/metrics`.
- `isStale` → text `dashboard.issues.stale` "(dữ liệu {date})" màu xám.
- `vi.json`: `dashboard.issues.title` "Cần xử lý ngay ({count})", `dashboard.issues.openTask` "Mở nhiệm vụ", `dashboard.issues.enter` "Nhập chỉ số".
- `TodayTasksPanel` giữ nguyên.

---

## [5] I6 — Form nhập, seed

### 5.1 `MetricEntryForm.tsx` [MODIFY]

- Chia ô nhập thành section theo `group`, thứ tự: PERFORMANCE → AFTERSALES → CANCELLATIONS → WORKLOAD; tiêu đề section = `groups.<group>`; section không có chỉ số (Shopee không có AFTERSALES, CANCELLATIONS) không render.
- Dưới mỗi label hiện `periodLabel` trong ngoặc: "Tỷ lệ giao hàng trễ (LDR) (7 ngày gần nhất)".
- Section AFTERSALES có dòng trợ giúp `metrics.issueCenterHelp`: "Số liệu lấy từ Seller Center > Orders > Help & Automations > Issue Center. Để trống ô chưa có số."
- Ô trống không gửi lên (giữ quy tắc cũ); nhân viên nhập nhanh nhóm PERFORMANCE mà không bắt buộc nhập đủ 15 ô.

### 5.2 `MetricBreakdownTable.tsx` [MODIFY]

Thêm cột nhóm dạng dòng tiêu đề phụ (row header) theo `group`, cùng thứ tự với form.

### 5.3 Seed [MODIFY] `prisma/seed.ts`

Shop Demo TikTok 1, thêm 7 chỉ số cho 14 ngày:

- `tiktok_sfrr = 1.2`
- `tiktok_returns_appeal_closing = i >= 12 ? 2 : 0`
- `tiktok_returns_review_due = i === 13 ? 6 : 0`
- `tiktok_returns_appeal_opening = 1`
- `tiktok_cancel_delivery_failed = 2`
- `tiktok_cancel_damaged_lost = 0`
- `tiktok_cancel_collection_timeout = i >= 10 ? 1 : 0`

Ngày cuối: `tiktok_returns_review_due = 6` → CRITICAL → task URGENT hạn 2 giờ; `tiktok_returns_appeal_closing = 2` → WARNING → task HIGH hạn 6 giờ; `tiktok_cancel_collection_timeout = 1` → WARNING → task HIGH hạn 12 giờ.

Cập nhật lệnh Verify Phase 2 / 8b: `MetricThreshold` = **25**, `TaskRule` = **58**.

---

## [6] Tests bổ sung

### 6.1 `src/test/catalog.test.ts` [U, ADD]

| # | Given | When | Then |
|---|---|---|---|
| CT1 | `METRIC_CATALOG` | đếm | 25 phần tử, `key` không trùng |
| CT2 | Mọi phần tử | kiểm tra | có `group` và `period` hợp lệ; `defaultWarning` / `defaultCritical` đúng chiều theo `direction` |
| CT3 | `getMetricsForPlatform("TIKTOK")` | đếm | 15; `getMetricsForPlatform("SHOPEE")` → 10 |

### 6.2 `src/test/defaults.test.ts` [U, ADD]

| # | Given | When | Then |
|---|---|---|---|
| DF1 | — | `getDefaultAlertRuleParams("tiktok_returns_review_due", "CRITICAL")` | `{ priority: "URGENT", dueInHours: 2 }` |
| DF2 | — | `getDefaultAlertRuleParams("tiktok_returns_appeal_closing", "WARNING")` | `{ priority: "HIGH", dueInHours: 6 }` |
| DF3 | — | `getDefaultAlertRuleParams("tiktok_cancel_collection_timeout", "CRITICAL")` | `{ priority: "URGENT", dueInHours: 4 }` (không override → mặc định) |
| DF4 | — | `getDefaultAlertRuleParams("shopee_nfr", "WARNING")` | `{ priority: "MEDIUM", dueInHours: 24 }` |

### 6.3 `src/test/issues.test.ts` [U, ADD]

| # | Given | When | Then |
|---|---|---|---|
| IS1 | 2 shop; latest có `tiktok_returns_review_due = 6` (shop C) và `shopee_pending_orders = 24` (shop A), ngưỡng mặc định; openTasks có task cho shop C | `buildIssueItems` | 2 item; item đầu là shop C level CRITICAL với `taskId` khác null; item 2 shop A WARNING `taskId = null` |
| IS2 | latest có `tiktok_returns_review_due = 0` | `buildIssueItems` | 0 item |
| IS3 | latest có `shopee_nfr = 12` (không thuộc ISSUE_METRIC_KEYS) | `buildIssueItems` | 0 item |
| IS4 | 25 item hợp lệ | `buildIssueItems` | trả về 20 item |
| IS5 | snapshot `date` = hôm qua | `buildIssueItems` | `isStale = true` |

### 6.4 `src/test/routines.test.ts` [U, MODIFY]

| # | Given | When | Then |
|---|---|---|---|
| R4 | 1 shop SHOPEE, 1 shop TIKTOK, 4 routine `platform null` + 1 routine `platform TIKTOK` | `generateRoutineTasks` | 9 task; shop SHOPEE không có task `check_issue_center` |

### 6.5 `e2e/issue-center.spec.ts` [E, ADD]

| # | Given | When | Then |
|---|---|---|---|
| IC1 | Đăng nhập staff, mở `/shops/<tiktok1>/metrics` | Xem form | Có 4 section: Hiệu suất, Trả hàng & khiếu nại, Đơn bị sàn huỷ, Việc tồn; label LDR có "(7 ngày gần nhất)" |
| IC2 | Nhập `tiktok_returns_review_due = 6`, lưu | Xem panel kết quả | Có nhiệm vụ URGENT tiêu đề bắt đầu `[Nguy cấp] Yêu cầu trả hàng cần duyệt gấp`; hạn = giờ hiện tại + 2 giờ (sai số ≤ 2 phút) |
| IC3 | Mở `/` | Xem panel "Cần xử lý ngay" | Dòng đầu là Shop Demo TikTok 1 với "Yêu cầu trả hàng cần duyệt gấp: 6" và nút "Mở nhiệm vụ" |
| IC4 | `/shops/<shopee1>/metrics` | Xem form | Không có section "Trả hàng & khiếu nại" |
| IC5 | Gọi `POST /api/cron/daily` với secret | Xem `/tasks?shopId=<tiktok1>&status=OPEN` và `<shopee1>` | TikTok có task "Kiểm tra Issue Center – Shop Demo TikTok 1"; Shopee không có |

Coverage §8.11 [MODIFY]: thêm `src/lib/metrics/issues.ts`, `src/lib/settings/defaults.ts` (chỉ hàm `getDefaultAlertRuleParams`, tách ra file `src/lib/settings/alert-params.ts` để đo coverage riêng — cây thư mục [ADD] file này).

---

## [7] Phase thực hiện

Áp dụng sau Phase 8e của Delta AHR. Nếu build từ đầu: gộp I1/I2 vào Phase 2–3a, I3/I4 vào Phase 3a, I5 vào Phase 3c + 4b, I6 vào 4c; các lệnh Verify đếm 25 threshold / 58 rule.

**STOP rule** như `05-phases.md`.

### Phase 9a — Catalog, params, routine, tests

**Files (8):** `src/types/index.ts`, `src/lib/metrics/catalog.ts`, `src/lib/settings/alert-params.ts`, `src/lib/settings/defaults.ts`, `src/lib/tasks/routines.ts`, `src/lib/tasks/templates.ts`, `src/i18n/vi.json`, `src/test/catalog.test.ts`.

Commit 2 (3 file): `src/test/defaults.test.ts`, `src/test/routines.test.ts`, `prisma/seed.ts`.

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
pnpm db:seed
pnpm prisma db execute --stdin <<< "SELECT count(*) FROM \"MetricThreshold\";"   # → 25
pnpm prisma db execute --stdin <<< "SELECT count(*) FROM \"TaskRule\";"          # → 58
curl -s -b cookies.txt "http://localhost:3000/api/tasks?shopId=<tiktok1>&status=OPEN&priority=URGENT" | grep -o 'cần duyệt gấp'   # → khớp
```

**Commit 1:** `feat(metrics): add issue center metrics with groups, periods and alert overrides`
**Commit 2:** `test(metrics): cover catalog, alert params and platform routines`

### Phase 9b — Issues API + Dashboard panel

**Files (6):** `src/lib/metrics/issues.ts`, `src/test/issues.test.ts`, `src/app/api/dashboard/summary/route.ts`, `src/components/dashboard/IssueCenterPanel.tsx`, `src/app/(app)/page.tsx`, `src/lib/notifications/service.ts` (quy tắc gửi HIGH ≤ 6 giờ).

**Verify:**

```bash
pnpm typecheck && pnpm lint && pnpm test
curl -s -b cookies.txt http://localhost:3000/api/dashboard/summary | grep -o '"issues":\[{"shopId"'   # → khớp
```

**Commit:** `feat(dashboard): add issue panel aggregating deadline metrics across shops`

### Phase 9c — Form sections + E2E

**Files (4):** `src/components/metrics/MetricEntryForm.tsx`, `src/components/shops/MetricBreakdownTable.tsx`, `src/app/api/metrics/catalog/route.ts` (thêm `group`, `period`, `periodLabel`), `e2e/issue-center.spec.ts`.

**Verify:**

```bash
pnpm db:seed && pnpm test:e2e     # → 27 passed (22 + IC1–IC5)
pnpm build
```

**Commit:** `feat(ui): group metric entry by section and add issue center e2e`
