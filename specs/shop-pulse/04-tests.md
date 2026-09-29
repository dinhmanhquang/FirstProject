# ShopPulse — Master Spec · 04 Tests

Đọc kèm: `01-data.md` (thuật toán), `02-api.md` (contract), `03-ui.md` (flow). File này là phần [8] Acceptance Tests.

---

## [8] Acceptance Tests

Quy ước: **[U]** = unit test Vitest trong `src/test/`, **[E]** = e2e Playwright trong `e2e/`. Test [U] không chạm DB (hàm thuần). Test [E] chạy trên DB seed (`pnpm db:seed` trước khi chạy).

### 8.1 Health Score — `src/test/health.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| H1 | Ngưỡng `shopee_nfr` LOWER_IS_BETTER warning 5, critical 10 | `evaluateMetric(4.99, t)` | Trả `"OK"` |
| H2 | Như H1 | `evaluateMetric(5, t)` | Trả `"WARNING"` |
| H3 | Như H1 | `evaluateMetric(10, t)` | Trả `"CRITICAL"` |
| H4 | Ngưỡng `shopee_rating` HIGHER_IS_BETTER warning 4.6, critical 4.3 | `evaluateMetric(4.6, t)` | Trả `"WARNING"` |
| H5 | Như H4 | `evaluateMetric(4.61, t)` | Trả `"OK"` |
| H6 | 2 chỉ số OK weight 1 và 1 chỉ số WARNING weight 2 | `computeHealth` | `score = 75`, `status = "WARNING"` |
| H7 | 1 chỉ số CRITICAL weight 3 và 5 chỉ số OK weight 1 | `computeHealth` | `score = 63`, `status = "CRITICAL"` (heavy critical) |
| H8 | 1 chỉ số CRITICAL weight 1 và 5 chỉ số OK weight 1 | `computeHealth` | `score = 83`, `status = "HEALTHY"` |
| H9 | Mảng metrics rỗng | `computeHealth` | `score = 0`, `status = "NO_DATA"`, `breakdown = []` |
| H10 | 1 chỉ số có `isEnabled = false` và 1 chỉ số OK | `computeHealth` | `breakdown.length = 1`, `score = 100` |
| H11 | Chỉ số có key không có trong thresholds | `computeHealth` | Bị bỏ qua, không throw |

### 8.2 Task engine — `src/test/engine.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| E1 | breakdown có `shopee_lsr` CRITICAL, rule CRITICAL cho `shopee_lsr` platform SHOPEE, `openDedupeKeys` rỗng | `generateAlertTasks` | 1 task, `priority = URGENT`, `dedupeKey = "<shopId>:shopee_lsr:CRITICAL"`, `dueAt = now + 4h`, `assigneeId = shop.assigneeId` |
| E2 | Như E1 nhưng `openDedupeKeys` chứa dedupeKey đó | `generateAlertTasks` | 0 task |
| E3 | breakdown có 1 chỉ số OK và 1 WARNING, chỉ có rule WARNING | `generateAlertTasks` | 1 task cho chỉ số WARNING |
| E4 | breakdown WARNING nhưng không có rule khớp level | `generateAlertTasks` | 0 task |
| E5 | 2 rule khớp: 1 `platform = null`, 1 `platform = SHOPEE` | `generateAlertTasks` | Task dùng rule `platform = SHOPEE` |
| E6 | breakdown CRITICAL, `openDedupeKeys` chứa key WARNING cùng chỉ số | `generateAlertTasks` | 1 task CRITICAL được tạo |
| E7 | titleTemplate `[{level}] {metricLabel} {value}{unit} – {shopName}` với ctx đầy đủ | `renderTemplate` | `"[Nguy cấp] Tỷ lệ giao hàng trễ 12.50% – Shop A"` |
| E8 | Template chứa `{unknown}` | `renderTemplate` | Giữ nguyên chuỗi `{unknown}` |

### 8.3 Routine — `src/test/routines.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| R1 | 2 shop ACTIVE, 4 rule ROUTINE active, `existingDedupeKeys` rỗng, date `2026-09-29` | `generateRoutineTasks` | 8 task; task `enter_metrics` có `dueAt` = `2026-09-29T03:00:00.000Z` (10:00 Việt Nam) |
| R2 | Như R1, `existingDedupeKeys` chứa 3 key của shop 1 | `generateRoutineTasks` | 5 task |
| R3 | 1 rule ROUTINE `isActive = false` | `generateRoutineTasks` | Không có task của rule đó |

### 8.4 CSV — `src/test/csv.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| C1 | Nội dung file mẫu `metrics-template.csv`, platform SHOPEE | `parseMetricsCsv` | `valid.length = 3`, `errors = []`, `rowCount = 3` |
| C2 | Header `ngay,chi_so,gia_tri` | `parseMetricsCsv` | `errors = [{ line: 1, field: "row", message: "validation.csv.header" }]`, `valid = []` |
| C3 | Dòng có `metric_key = tiktok_ldr`, platform SHOPEE | `parseMetricsCsv` | Lỗi `field: "metric_key"`, dòng khác vẫn valid |
| C4 | Dòng có `value = 150` cho `shopee_nfr` | `parseMetricsCsv` | Lỗi `field: "value"`, message `validation.csv.value` |
| C5 | Dòng có `date = 2030-01-01` | `parseMetricsCsv` | Lỗi `field: "date"`, message `validation.csv.date` |
| C6 | 2 dòng trùng (date, metric_key) giá trị 1 và 2 | `parseMetricsCsv` | `valid` có 1 phần tử với `value = 2` |
| C7 | 5 001 dòng dữ liệu | `parseMetricsCsv` | Lỗi `validation.csv.tooManyRows`, `valid = []` |
| C8 | Có dòng trống giữa file | `parseMetricsCsv` | Dòng trống bị bỏ qua, không lỗi |

### 8.5 Date helpers — `src/test/date.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| D1 | `now = 2026-09-28T17:30:00Z` | `todayInAppTz(now)` | `"2026-09-29"` |
| D2 | `now = 2026-09-28T16:30:00Z` | `todayInAppTz(now)` | `"2026-09-28"` |
| D3 | `date = "2026-09-29"`, hour 10 | `localDateAtHour(date, 10)` | `2026-09-29T03:00:00.000Z` |
| D4 | latest `"2026-09-27"`, now `2026-09-29T02:00:00Z` | `staleDays(latest, now)` | `2` |

### 8.6 Validation — `src/test/validation.test.ts` [U]

| # | Given | When | Then |
|---|---|---|---|
| V1 | `{ platform: "SHOPEE", name: "A" }` | `createShopSchema.safeParse` | fail, `fieldErrors.name = ["validation.shopNameMin"]` |
| V2 | `{ platform: "LAZADA", name: "Shop A" }` | `createShopSchema.safeParse` | fail, `fieldErrors.platform` có message |
| V3 | thresholds item LOWER_IS_BETTER `warningValue 10, criticalValue 5` | `thresholdsPutSchema.safeParse` | fail, message `validation.thresholdOrderLower` |
| V4 | thresholds item HIGHER_IS_BETTER `warningValue 4.6, criticalValue 4.3` | `thresholdsPutSchema.safeParse` | success |
| V5 | rule ALERT thiếu `level` | `ruleSchema.safeParse` | fail, message `validation.ruleAlertFields` |
| V6 | rule ROUTINE `dueInHours = 25` | `ruleSchema.safeParse` | fail, message `validation.routineDueHour` |
| V7 | task `dueAt` trong quá khứ | `createTaskSchema.safeParse` | fail, `fieldErrors.dueAt = ["validation.dueAtFuture"]` |
| V8 | task list query `status=OPEN,DONE` | `taskListQuerySchema.parse` | `status = ["OPEN", "DONE"]` |
| V9 | upsertMetrics `values = {}` | `upsertMetricsSchema.safeParse` | fail, message `validation.metricsEmpty` |

### 8.7 Auth — `e2e/auth.spec.ts` [E]

| # | Given | When | Then |
|---|---|---|---|
| A1 | Chưa đăng nhập | Mở `/` | Redirect tới `/login?next=%2F` |
| A2 | Ở `/login` | Nhập `SEED_OWNER_EMAIL` + `SEED_OWNER_PASSWORD`, bấm Đăng nhập | URL `/`, thấy heading "Tổng quan hôm nay" |
| A3 | Ở `/login` | Nhập mật khẩu sai | Thấy text "Email hoặc mật khẩu không đúng", vẫn ở `/login` |
| A4 | Đăng nhập là staff@example.com | Mở `/settings/thresholds` | Redirect `/` và toast "Bạn không có quyền thực hiện thao tác này" |
| A5 | Đã đăng nhập | Bấm menu user > Đăng xuất | URL `/login` |

### 8.8 Nhập chỉ số → nhiệm vụ — `e2e/metrics-to-task.spec.ts` [E]

| # | Given | When | Then |
|---|---|---|---|
| M1 | Đăng nhập staff, shop "Shop Demo Shopee 2" | Mở `/shops/<id>/metrics`, thấy form | Ô `shopee_nfr` điền sẵn `1.50` (giá trị hôm qua), ngày mặc định hôm nay |
| M2 | Ở form M1 | Nhập `shopee_lsr = 12`, bấm Lưu | Toast "Đã lưu 10 chỉ số"; panel kết quả hiển thị status "Nguy cấp" và 1 nhiệm vụ mới có tiêu đề bắt đầu bằng `[Nguy cấp] Tỷ lệ giao hàng trễ 12.00%` |
| M3 | Sau M2 | Mở `/tasks` | Thấy nhiệm vụ trên ở nhóm "Quá hạn / Hôm nay" với badge URGENT và tên shop |
| M4 | Sau M2 | Lưu lại form với `shopee_lsr = 12` lần nữa | Không tạo thêm nhiệm vụ (đếm nhiệm vụ URGENT của shop không đổi) |
| M5 | Mở nhiệm vụ M2 | Chọn trạng thái Hoàn thành, ghi chú "Đã bàn giao 12 đơn", bấm Cập nhật | Badge trạng thái "Hoàn thành", `completedAt` hiển thị |
| M6 | Ở `/shops/<id>/import` | Upload file có 1 dòng sai `value` và 2 dòng đúng | Kết quả: "Thành công 2 · Lỗi 1", bảng lỗi có dòng 3 |
| M7 | Ở `/` | Xem SummaryCards | Thẻ "Nguy cấp" đếm ≥ 1, ShopCard "Shop Demo Shopee 2" có badge "Nguy cấp" |

### 8.9 Cron — `e2e/metrics-to-task.spec.ts` (test bổ sung) [E]

| # | Given | When | Then |
|---|---|---|---|
| K1 | Server chạy, `CRON_SECRET` đã đặt | `request.post("/api/cron/daily", { headers: { Authorization: "Bearer <secret>" } })` | 200, `createdTasks ≥ 0`; gọi lần 2 → `createdTasks = 0` |
| K2 | Không header | `request.post("/api/cron/daily")` | 401, `error.code = "UNAUTHORIZED"` |

### 8.10 Phân quyền API — `src/test/validation.test.ts` không bao phủ; kiểm tra qua e2e `request` trong `e2e/auth.spec.ts` [E]

| # | Given | When | Then |
|---|---|---|---|
| P1 | Cookie session của staff | `PUT /api/settings/thresholds` | 403 `FORBIDDEN` |
| P2 | Cookie session của staff | `POST /api/shops` | 403 `FORBIDDEN` |
| P3 | Cookie session của manager | `PATCH /api/members/<ownerId>` body `{ role: "STAFF" }` | 403 `FORBIDDEN` |
| P4 | Không cookie | `GET /api/shops` | 401 `UNAUTHORIZED` |

### 8.11 Coverage tối thiểu

`pnpm test -- --coverage` phải đạt ≥ 90% statements cho 5 file: `src/lib/metrics/health.ts`, `src/lib/metrics/csv.ts`, `src/lib/tasks/engine.ts`, `src/lib/tasks/routines.ts`, `src/lib/tasks/templates.ts`. Cấu hình `coverage.include` trong `vitest.config.ts` đúng 5 file này.
