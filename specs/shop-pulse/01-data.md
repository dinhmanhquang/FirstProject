# ShopPulse — Master Spec · 01 Data

Đọc kèm: `00-overview.md` (mục [0], [1]). File này là phần [3] Data Models & State.

---

## [3] Data Models & State

### 3.1 Prisma schema

File `prisma/schema.prisma`, nội dung đầy đủ:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  OWNER
  MANAGER
  STAFF
}

enum Platform {
  SHOPEE
  TIKTOK
}

enum ShopStatus {
  ACTIVE
  PAUSED
}

enum MetricSource {
  MANUAL
  CSV
}

enum HealthStatus {
  HEALTHY
  WARNING
  CRITICAL
  NO_DATA
}

enum MetricLevel {
  OK
  WARNING
  CRITICAL
}

enum MetricDirection {
  LOWER_IS_BETTER
  HIGHER_IS_BETTER
}

enum RuleType {
  ALERT
  ROUTINE
}

enum TaskPriority {
  LOW
  MEDIUM
  HIGH
  URGENT
}

enum TaskStatus {
  OPEN
  IN_PROGRESS
  DONE
  SKIPPED
}

enum TaskSource {
  AUTO
  MANUAL
}

enum NotificationType {
  TASK_CREATED
  TASK_ASSIGNED
  SHOP_CRITICAL
}

model Organization {
  id        String   @id @default(cuid())
  name      String
  slug      String   @unique
  plan      String   @default("FREE")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  users         User[]
  shops         Shop[]
  thresholds    MetricThreshold[]
  rules         TaskRule[]
  tasks         Task[]
  snapshots     MetricSnapshot[]
  healthScores  HealthScore[]
  notifications Notification[]
  importJobs    ImportJob[]
}

model User {
  id           String   @id @default(cuid())
  orgId        String
  email        String   @unique
  passwordHash String
  name         String
  role         Role     @default(STAFF)
  isActive     Boolean  @default(true)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  org              Organization     @relation(fields: [orgId], references: [id])
  assignedShops    Shop[]           @relation("ShopAssignee")
  assignedTasks    Task[]           @relation("TaskAssignee")
  createdTasks     Task[]           @relation("TaskCreator")
  createdSnapshots MetricSnapshot[]
  importJobs       ImportJob[]
  notifications    Notification[]

  @@index([orgId])
}

model Shop {
  id             String     @id @default(cuid())
  orgId          String
  platform       Platform
  name           String
  externalShopId String?
  assigneeId     String?
  status         ShopStatus @default(ACTIVE)
  note           String?
  createdAt      DateTime   @default(now())
  updatedAt      DateTime   @updatedAt
  deletedAt      DateTime?

  org          Organization     @relation(fields: [orgId], references: [id])
  assignee     User?            @relation("ShopAssignee", fields: [assigneeId], references: [id])
  snapshots    MetricSnapshot[]
  healthScores HealthScore[]
  tasks        Task[]
  importJobs   ImportJob[]

  @@unique([orgId, platform, name])
  @@index([orgId, status])
  @@index([assigneeId])
}

model MetricThreshold {
  id            String          @id @default(cuid())
  orgId         String
  platform      Platform
  metricKey     String
  direction     MetricDirection
  warningValue  Decimal         @db.Decimal(10, 2)
  criticalValue Decimal         @db.Decimal(10, 2)
  weight        Int             @default(1)
  isEnabled     Boolean         @default(true)
  updatedAt     DateTime        @updatedAt

  org Organization @relation(fields: [orgId], references: [id])

  @@unique([orgId, metricKey])
  @@index([orgId, platform])
}

model MetricSnapshot {
  id          String       @id @default(cuid())
  orgId       String
  shopId      String
  date        DateTime     @db.Date
  metricKey   String
  value       Decimal      @db.Decimal(10, 2)
  source      MetricSource
  createdById String
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  org       Organization @relation(fields: [orgId], references: [id])
  shop      Shop         @relation(fields: [shopId], references: [id])
  createdBy User         @relation(fields: [createdById], references: [id])

  @@unique([shopId, date, metricKey])
  @@index([orgId, shopId, date])
}

model HealthScore {
  id         String       @id @default(cuid())
  orgId      String
  shopId     String
  date       DateTime     @db.Date
  score      Int
  status     HealthStatus
  breakdown  Json
  computedAt DateTime     @default(now())

  org  Organization @relation(fields: [orgId], references: [id])
  shop Shop         @relation(fields: [shopId], references: [id])

  @@unique([shopId, date])
  @@index([orgId, date])
}

model TaskRule {
  id                  String       @id @default(cuid())
  orgId               String
  type                RuleType
  platform            Platform?
  metricKey           String?
  level               MetricLevel?
  routineKey          String?
  titleTemplate       String
  descriptionTemplate String
  priority            TaskPriority
  dueInHours          Int
  isActive            Boolean      @default(true)
  createdAt           DateTime     @default(now())
  updatedAt           DateTime     @updatedAt

  org   Organization @relation(fields: [orgId], references: [id])
  tasks Task[]

  @@index([orgId, type, isActive])
}

model Task {
  id            String       @id @default(cuid())
  orgId         String
  shopId        String
  ruleId        String?
  source        TaskSource
  title         String
  description   String
  priority      TaskPriority
  status        TaskStatus   @default(OPEN)
  assigneeId    String?
  createdById   String?
  metricKey     String?
  metricLevel   MetricLevel?
  metricValue   Decimal?     @db.Decimal(10, 2)
  snapshotDate  DateTime?    @db.Date
  dedupeKey     String?
  dueAt         DateTime
  completedAt   DateTime?
  completionNote String?
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt

  org       Organization @relation(fields: [orgId], references: [id])
  shop      Shop         @relation(fields: [shopId], references: [id])
  rule      TaskRule?    @relation(fields: [ruleId], references: [id], onDelete: SetNull)
  assignee  User?        @relation("TaskAssignee", fields: [assigneeId], references: [id])
  createdBy User?        @relation("TaskCreator", fields: [createdById], references: [id])

  @@unique([dedupeKey])
  @@index([orgId, status, dueAt])
  @@index([orgId, shopId, status])
  @@index([assigneeId, status])
}

model Notification {
  id        String           @id @default(cuid())
  orgId     String
  userId    String
  type      NotificationType
  title     String
  body      String
  link      String
  readAt    DateTime?
  createdAt DateTime         @default(now())

  org  Organization @relation(fields: [orgId], references: [id])
  user User         @relation(fields: [userId], references: [id])

  @@index([userId, readAt, createdAt])
}

model ImportJob {
  id           String   @id @default(cuid())
  orgId        String
  shopId       String
  fileName     String
  rowCount     Int
  successCount Int
  errorCount   Int
  errors       Json
  createdById  String
  createdAt    DateTime @default(now())

  org       Organization @relation(fields: [orgId], references: [id])
  shop      Shop         @relation(fields: [shopId], references: [id])
  createdBy User         @relation(fields: [createdById], references: [id])

  @@index([orgId, shopId, createdAt])
}
```

**Quy tắc dữ liệu:**

- Soft-delete chỉ áp dụng cho `Shop` (`deletedAt`). Mọi truy vấn shop mặc định thêm `deletedAt: null`. Shop đã xoá vẫn giữ snapshot, task, health để đối chiếu.
- `MetricSnapshot.date`, `HealthScore.date`, `Task.snapshotDate` là ngày theo `APP_TIMEZONE`, lưu dạng `YYYY-MM-DD` (Postgres `date`).
- `Task.dedupeKey`:
  - Task ALERT: `${shopId}:${metricKey}:${level}` — chỉ 1 task ALERT mở cho mỗi cặp (shop, chỉ số, mức). Khi task chuyển DONE / SKIPPED, `dedupeKey` được đặt về `null` để lần vượt ngưỡng sau sinh task mới.
  - Task ROUTINE: `${shopId}:routine:${routineKey}:${date}`.
  - Task MANUAL: `null`.
- `HealthScore.breakdown` là JSON có kiểu `MetricEvaluation[]` (mục 3.2).
- `ImportJob.errors` là JSON có kiểu `CsvRowError[]` (mục 3.2), giới hạn 200 phần tử đầu.
- `MetricThreshold` tồn tại cho **mọi** `metricKey` trong catalog của org (seed khi tạo org). PUT thresholds chỉ sửa giá trị, không tạo / xoá dòng.

### 3.2 `src/types/index.ts`

Toàn bộ nội dung file:

```ts
import type {
  HealthStatus,
  MetricDirection,
  MetricLevel,
  MetricSource,
  Platform,
  Role,
  RuleType,
  ShopStatus,
  TaskPriority,
  TaskSource,
  TaskStatus,
  NotificationType,
} from "@prisma/client";

export type {
  HealthStatus,
  MetricDirection,
  MetricLevel,
  MetricSource,
  Platform,
  Role,
  RuleType,
  ShopStatus,
  TaskPriority,
  TaskSource,
  TaskStatus,
  NotificationType,
};

// ---------- Metric catalog ----------

export type MetricUnit = "PERCENT" | "HOURS" | "DAYS" | "POINTS" | "STARS" | "COUNT";

export type ShopeeMetricKey =
  | "shopee_nfr"
  | "shopee_lsr"
  | "shopee_prep_time"
  | "shopee_response_rate"
  | "shopee_response_time"
  | "shopee_rating"
  | "shopee_penalty_points"
  | "shopee_pending_orders"
  | "shopee_pending_chats"
  | "shopee_low_ratings";

export type TiktokMetricKey =
  | "tiktok_ldr"
  | "tiktok_sfcr"
  | "tiktok_nrr"
  | "tiktok_violation_points"
  | "tiktok_sps"
  | "tiktok_pending_orders"
  | "tiktok_pending_chats"
  | "tiktok_low_ratings";

export type MetricKey = ShopeeMetricKey | TiktokMetricKey;

export interface MetricDefinition {
  key: MetricKey;
  platform: Platform;
  labelKey: string; // key trong vi.json: metrics.<key>.label
  unit: MetricUnit;
  direction: MetricDirection;
  min: number;
  max: number;
  decimals: 0 | 1 | 2;
  defaultWarning: number;
  defaultCritical: number;
  defaultWeight: 1 | 2 | 3;
}

export interface ThresholdConfig {
  metricKey: MetricKey;
  platform: Platform;
  direction: MetricDirection;
  warningValue: number;
  criticalValue: number;
  weight: number;
  isEnabled: boolean;
}

// ---------- Health ----------

export interface MetricInput {
  key: MetricKey;
  value: number;
}

export interface MetricEvaluation {
  key: MetricKey;
  value: number;
  level: MetricLevel;
  warningValue: number;
  criticalValue: number;
  weight: number;
  points: 0 | 50 | 100;
}

export interface HealthResult {
  score: number; // 0..100, số nguyên
  status: HealthStatus;
  breakdown: MetricEvaluation[];
}

// ---------- DTO trả về từ API ----------

export interface CatalogItemDto {
  key: MetricKey;
  platform: Platform;
  label: string;
  hint: string;
  unit: MetricUnit;
  unitLabel: string;
  direction: MetricDirection;
  min: number;
  max: number;
  decimals: 0 | 1 | 2;
}

export interface UpsertResult {
  date: string;
  saved: number;
  health: HealthScoreDto;
  createdTasks: Array<{ id: string; title: string; priority: TaskPriority }>;
}

export interface UserDto {
  id: string;
  email: string;
  name: string;
  role: Role;
  isActive: boolean;
  createdAt: string;
}

export interface ShopDto {
  id: string;
  platform: Platform;
  name: string;
  externalShopId: string | null;
  assignee: { id: string; name: string } | null;
  status: ShopStatus;
  note: string | null;
  latestHealth: {
    date: string; // YYYY-MM-DD
    score: number;
    status: HealthStatus;
  } | null;
  staleDays: number | null; // null khi chưa có snapshot
  openTaskCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface ShopDetailDto extends ShopDto {
  latestBreakdown: MetricEvaluation[];
}

export interface MetricSnapshotDto {
  date: string;
  metricKey: MetricKey;
  value: number;
  source: MetricSource;
}

export interface HealthScoreDto {
  date: string;
  score: number;
  status: HealthStatus;
  breakdown: MetricEvaluation[];
}

export interface TaskDto {
  id: string;
  shop: { id: string; name: string; platform: Platform };
  source: TaskSource;
  title: string;
  description: string;
  priority: TaskPriority;
  status: TaskStatus;
  assignee: { id: string; name: string } | null;
  metricKey: MetricKey | null;
  metricLevel: MetricLevel | null;
  metricValue: number | null;
  snapshotDate: string | null;
  metricNowOk: boolean; // true khi chỉ số ở snapshot mới nhất đã về OK
  dueAt: string;
  isOverdue: boolean;
  completedAt: string | null;
  completionNote: string | null;
  createdAt: string;
}

export interface TaskRuleDto {
  id: string;
  type: RuleType;
  platform: Platform | null;
  metricKey: MetricKey | null;
  level: MetricLevel | null;
  routineKey: string | null;
  titleTemplate: string;
  descriptionTemplate: string;
  priority: TaskPriority;
  dueInHours: number;
  isActive: boolean;
}

export interface ThresholdDto extends ThresholdConfig {
  id: string;
  updatedAt: string;
}

export interface NotificationDto {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  link: string;
  readAt: string | null;
  createdAt: string;
}

export interface DashboardSummaryDto {
  date: string; // hôm nay theo APP_TIMEZONE
  counts: {
    healthy: number;
    warning: number;
    critical: number;
    noData: number;
  };
  shops: ShopDto[];
  tasksDueToday: TaskDto[];
  tasksOverdue: TaskDto[];
  staleShops: Array<{ id: string; name: string; platform: Platform; staleDays: number }>;
}

// ---------- CSV ----------

export interface CsvRow {
  line: number;
  date: string;
  metricKey: string;
  value: string;
}

export interface CsvRowError {
  line: number;
  field: "date" | "metric_key" | "value" | "row";
  message: string;
}

export interface CsvParseResult {
  valid: Array<{ date: string; metricKey: MetricKey; value: number }>;
  errors: CsvRowError[];
  rowCount: number;
}

// ---------- API envelope ----------

export interface ApiErrorBody {
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface PagedResponse<T> {
  data: T[];
  meta: PageMeta;
}

// ---------- Task engine ----------

export interface TemplateContext {
  shopName: string;
  platformLabel: string;
  metricLabel: string;
  value: string; // đã format theo decimals
  unit: string; // nhãn đơn vị tiếng Việt
  threshold: string;
  level: string;
  date: string; // dd/MM/yyyy
}

export interface GeneratedTask {
  shopId: string;
  ruleId: string;
  title: string;
  description: string;
  priority: TaskPriority;
  dueAt: Date;
  assigneeId: string | null;
  metricKey: MetricKey | null;
  metricLevel: MetricLevel | null;
  metricValue: number | null;
  snapshotDate: string | null;
  dedupeKey: string;
}

// ---------- Session ----------

export interface SessionUser {
  id: string;
  orgId: string;
  role: Role;
  name: string;
  email: string;
}
```

### 3.3 Catalog chỉ số — `src/lib/metrics/catalog.ts`

Giá trị `defaultWarning` / `defaultCritical` là **ngưỡng nội bộ mặc định**, chỉnh được trong `/settings/thresholds`.

```ts
import type { MetricDefinition, MetricKey, Platform } from "@/types";

export const METRIC_CATALOG: readonly MetricDefinition[] = [
  // ---- SHOPEE ----
  { key: "shopee_nfr", platform: "SHOPEE", labelKey: "metrics.shopee_nfr.label", unit: "PERCENT", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 5, defaultCritical: 10, defaultWeight: 3 },
  { key: "shopee_lsr", platform: "SHOPEE", labelKey: "metrics.shopee_lsr.label", unit: "PERCENT", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 5, defaultCritical: 10, defaultWeight: 3 },
  { key: "shopee_prep_time", platform: "SHOPEE", labelKey: "metrics.shopee_prep_time.label", unit: "DAYS", direction: "LOWER_IS_BETTER", min: 0, max: 30, decimals: 2, defaultWarning: 1.5, defaultCritical: 2, defaultWeight: 2 },
  { key: "shopee_response_rate", platform: "SHOPEE", labelKey: "metrics.shopee_response_rate.label", unit: "PERCENT", direction: "HIGHER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 80, defaultCritical: 70, defaultWeight: 2 },
  { key: "shopee_response_time", platform: "SHOPEE", labelKey: "metrics.shopee_response_time.label", unit: "HOURS", direction: "LOWER_IS_BETTER", min: 0, max: 168, decimals: 1, defaultWarning: 6, defaultCritical: 12, defaultWeight: 1 },
  { key: "shopee_rating", platform: "SHOPEE", labelKey: "metrics.shopee_rating.label", unit: "STARS", direction: "HIGHER_IS_BETTER", min: 0, max: 5, decimals: 2, defaultWarning: 4.6, defaultCritical: 4.3, defaultWeight: 2 },
  { key: "shopee_penalty_points", platform: "SHOPEE", labelKey: "metrics.shopee_penalty_points.label", unit: "POINTS", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 0, defaultWarning: 1, defaultCritical: 3, defaultWeight: 3 },
  { key: "shopee_pending_orders", platform: "SHOPEE", labelKey: "metrics.shopee_pending_orders.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 20, defaultCritical: 50, defaultWeight: 1 },
  { key: "shopee_pending_chats", platform: "SHOPEE", labelKey: "metrics.shopee_pending_chats.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 5, defaultCritical: 20, defaultWeight: 1 },
  { key: "shopee_low_ratings", platform: "SHOPEE", labelKey: "metrics.shopee_low_ratings.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 1, defaultCritical: 5, defaultWeight: 1 },
  // ---- TIKTOK ----
  { key: "tiktok_ldr", platform: "TIKTOK", labelKey: "metrics.tiktok_ldr.label", unit: "PERCENT", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 2, defaultCritical: 4, defaultWeight: 3 },
  { key: "tiktok_sfcr", platform: "TIKTOK", labelKey: "metrics.tiktok_sfcr.label", unit: "PERCENT", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 1.5, defaultCritical: 2.5, defaultWeight: 3 },
  { key: "tiktok_nrr", platform: "TIKTOK", labelKey: "metrics.tiktok_nrr.label", unit: "PERCENT", direction: "LOWER_IS_BETTER", min: 0, max: 100, decimals: 2, defaultWarning: 2, defaultCritical: 4, defaultWeight: 2 },
  { key: "tiktok_violation_points", platform: "TIKTOK", labelKey: "metrics.tiktok_violation_points.label", unit: "POINTS", direction: "LOWER_IS_BETTER", min: 0, max: 48, decimals: 0, defaultWarning: 4, defaultCritical: 12, defaultWeight: 3 },
  { key: "tiktok_sps", platform: "TIKTOK", labelKey: "metrics.tiktok_sps.label", unit: "STARS", direction: "HIGHER_IS_BETTER", min: 0, max: 5, decimals: 2, defaultWarning: 4, defaultCritical: 3.5, defaultWeight: 2 },
  { key: "tiktok_pending_orders", platform: "TIKTOK", labelKey: "metrics.tiktok_pending_orders.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 20, defaultCritical: 50, defaultWeight: 1 },
  { key: "tiktok_pending_chats", platform: "TIKTOK", labelKey: "metrics.tiktok_pending_chats.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 5, defaultCritical: 20, defaultWeight: 1 },
  { key: "tiktok_low_ratings", platform: "TIKTOK", labelKey: "metrics.tiktok_low_ratings.label", unit: "COUNT", direction: "LOWER_IS_BETTER", min: 0, max: 100000, decimals: 0, defaultWarning: 1, defaultCritical: 5, defaultWeight: 1 },
] as const;

export const METRIC_KEYS: readonly MetricKey[] = METRIC_CATALOG.map((m) => m.key);

export function getMetricDefinition(key: MetricKey): MetricDefinition {
  const def = METRIC_CATALOG.find((m) => m.key === key);
  if (!def) throw new Error(`Unknown metric key: ${key}`);
  return def;
}

export function getMetricsForPlatform(platform: Platform): MetricDefinition[] {
  return METRIC_CATALOG.filter((m) => m.platform === platform);
}

export function isMetricKey(value: string): value is MetricKey {
  return (METRIC_KEYS as readonly string[]).includes(value);
}
```

Nhãn tiếng Việt (ghi trong `vi.json`, key `metrics.<key>.label` và `metrics.<key>.hint`):

| key | label | hint (mô tả ngắn hiện dưới ô nhập) |
|---|---|---|
| shopee_nfr | Tỷ lệ đơn không thành công | % đơn bị huỷ / trả / giao thất bại do shop, kỳ 7 ngày theo Seller Centre |
| shopee_lsr | Tỷ lệ giao hàng trễ | % đơn giao sau hạn, theo Seller Centre |
| shopee_prep_time | Thời gian chuẩn bị hàng | Số ngày trung bình từ lúc đặt tới lúc bàn giao vận chuyển |
| shopee_response_rate | Tỷ lệ phản hồi chat | % chat được trả lời trong 12 giờ |
| shopee_response_time | Thời gian phản hồi | Số giờ trung bình trả lời chat |
| shopee_rating | Đánh giá shop | Điểm sao trung bình 1–5 |
| shopee_penalty_points | Điểm Sao Quả Tạ | Tổng điểm phạt trong quý hiện tại |
| shopee_pending_orders | Đơn chờ xử lý | Số đơn ở trạng thái Chờ lấy hàng lúc nhập |
| shopee_pending_chats | Chat chưa trả lời | Số hội thoại chưa phản hồi lúc nhập |
| shopee_low_ratings | Đánh giá 1–3 sao chưa phản hồi | Số đánh giá thấp chưa được shop trả lời |
| tiktok_ldr | Tỷ lệ giao hàng trễ (LDR) | % đơn bàn giao trễ hoặc quá SLA, theo Seller Center |
| tiktok_sfcr | Tỷ lệ huỷ do người bán (SFCR) | % đơn huỷ do lỗi shop |
| tiktok_nrr | Tỷ lệ đánh giá tiêu cực | % đánh giá 1–2 sao trên tổng đánh giá |
| tiktok_violation_points | Điểm vi phạm | Tổng điểm vi phạm đang có hiệu lực (tối đa 48) |
| tiktok_sps | Điểm hiệu suất shop (SPS) | Shop Performance Score 0–5 |
| tiktok_pending_orders | Đơn chờ xử lý | Số đơn ở trạng thái Chờ giao lúc nhập |
| tiktok_pending_chats | Chat chưa trả lời | Số hội thoại chưa phản hồi lúc nhập |
| tiktok_low_ratings | Đánh giá 1–3 sao chưa phản hồi | Số đánh giá thấp chưa được shop trả lời |

Nhãn đơn vị (`vi.json`, key `units.<unit>`): PERCENT → `%`, HOURS → `giờ`, DAYS → `ngày`, POINTS → `điểm`, STARS → `sao`, COUNT → `đơn vị`.

### 3.4 Thuật toán Health Score — `src/lib/metrics/health.ts`

```ts
import type { HealthResult, MetricEvaluation, MetricInput, MetricLevel, ThresholdConfig } from "@/types";

export function evaluateMetric(value: number, t: ThresholdConfig): MetricLevel {
  if (t.direction === "LOWER_IS_BETTER") {
    if (value >= t.criticalValue) return "CRITICAL";
    if (value >= t.warningValue) return "WARNING";
    return "OK";
  }
  if (value <= t.criticalValue) return "CRITICAL";
  if (value <= t.warningValue) return "WARNING";
  return "OK";
}

const POINTS: Record<MetricLevel, 0 | 50 | 100> = { OK: 100, WARNING: 50, CRITICAL: 0 };

export function computeHealth(
  metrics: MetricInput[],
  thresholds: Record<string, ThresholdConfig>,
): HealthResult {
  const breakdown: MetricEvaluation[] = [];
  for (const m of metrics) {
    const t = thresholds[m.key];
    if (!t || !t.isEnabled) continue;
    const level = evaluateMetric(m.value, t);
    breakdown.push({
      key: m.key,
      value: m.value,
      level,
      warningValue: t.warningValue,
      criticalValue: t.criticalValue,
      weight: t.weight,
      points: POINTS[level],
    });
  }
  if (breakdown.length === 0) return { score: 0, status: "NO_DATA", breakdown };

  const totalWeight = breakdown.reduce((s, b) => s + b.weight, 0);
  const weighted = breakdown.reduce((s, b) => s + b.points * b.weight, 0);
  const score = Math.round(weighted / totalWeight);

  const hasHeavyCritical = breakdown.some((b) => b.level === "CRITICAL" && b.weight >= 3);
  let status: HealthResult["status"];
  if (hasHeavyCritical || score < 50) status = "CRITICAL";
  else if (score < 80) status = "WARNING";
  else status = "HEALTHY";

  return { score, status, breakdown };
}
```

Quy tắc bổ sung do `metric-service.ts` thực hiện:

- Health của ngày D tính từ **đúng** các snapshot có `date = D`. Không lấy giá trị ngày trước để bù.
- `staleDays` của shop = số ngày từ `max(snapshot.date)` tới hôm nay (theo `APP_TIMEZONE`). Chưa có snapshot → `null`.
- Dashboard hiển thị `latestHealth` = `HealthScore` có `date` lớn nhất.

### 3.5 Task engine — `src/lib/tasks/engine.ts`

```ts
import type { GeneratedTask, HealthResult, MetricKey, TaskRuleDto, TemplateContext } from "@/types";

export interface EngineInput {
  shop: { id: string; name: string; platform: "SHOPEE" | "TIKTOK"; assigneeId: string | null };
  date: string; // YYYY-MM-DD
  health: HealthResult;
  rules: TaskRuleDto[]; // chỉ rule type ALERT, isActive = true
  openDedupeKeys: Set<string>; // dedupeKey của task OPEN / IN_PROGRESS hiện có
  now: Date;
  render: (template: string, ctx: TemplateContext) => string;
  buildContext: (metricKey: MetricKey, value: number, level: "WARNING" | "CRITICAL") => TemplateContext;
}

export function generateAlertTasks(input: EngineInput): GeneratedTask[]
```

Thuật toán `generateAlertTasks`:

1. Với mỗi `b` trong `health.breakdown` có `b.level !== "OK"`:
2. Tìm rule `r` trong `rules` thoả: `r.metricKey === b.key` **và** `r.level === b.level` **và** (`r.platform === null` hoặc `r.platform === shop.platform`). Nếu nhiều rule thoả, chọn rule có `platform !== null` trước; nếu vẫn nhiều, chọn rule có `createdAt` nhỏ nhất (rules được truyền vào đã sắp theo `createdAt asc`).
3. Không có rule → bỏ qua chỉ số đó.
4. `dedupeKey = \`${shop.id}:${b.key}:${b.level}\``. Nếu `openDedupeKeys.has(dedupeKey)` → bỏ qua (task đang mở).
5. Nếu `b.level === "CRITICAL"` và `openDedupeKeys.has(\`${shop.id}:${b.key}:WARNING\`)` → vẫn tạo task CRITICAL (task WARNING giữ nguyên).
6. Tạo `GeneratedTask` với `title = render(r.titleTemplate, ctx)`, `description = render(r.descriptionTemplate, ctx)`, `priority = r.priority`, `dueAt = now + r.dueInHours giờ`, `assigneeId = shop.assigneeId`, `metricKey = b.key`, `metricLevel = b.level`, `metricValue = b.value`, `snapshotDate = date`.
7. Trả về mảng theo thứ tự breakdown.

`metric-service.upsertSnapshots()` sau khi gọi engine: insert task trong transaction, rồi gọi `NotificationService.send()` cho mỗi task có `priority === "URGENT"` (mục 3.9).

### 3.6 Routine — `src/lib/tasks/routines.ts`

```ts
export interface RoutineDefinition {
  routineKey: "enter_metrics" | "process_orders" | "reply_chats" | "reply_low_ratings";
  titleKey: string;        // vi.json: routines.<routineKey>.title
  descriptionKey: string;  // vi.json: routines.<routineKey>.description
  priority: "HIGH" | "MEDIUM";
  dueHourLocal: number;    // giờ đến hạn trong ngày, theo APP_TIMEZONE
}

export const ROUTINE_DEFINITIONS: readonly RoutineDefinition[] = [
  { routineKey: "enter_metrics", titleKey: "routines.enter_metrics.title", descriptionKey: "routines.enter_metrics.description", priority: "HIGH", dueHourLocal: 10 },
  { routineKey: "process_orders", titleKey: "routines.process_orders.title", descriptionKey: "routines.process_orders.description", priority: "MEDIUM", dueHourLocal: 11 },
  { routineKey: "reply_chats", titleKey: "routines.reply_chats.title", descriptionKey: "routines.reply_chats.description", priority: "MEDIUM", dueHourLocal: 12 },
  { routineKey: "reply_low_ratings", titleKey: "routines.reply_low_ratings.title", descriptionKey: "routines.reply_low_ratings.description", priority: "MEDIUM", dueHourLocal: 17 },
];

export function generateRoutineTasks(input: {
  shops: Array<{ id: string; name: string; platform: "SHOPEE" | "TIKTOK"; assigneeId: string | null }>;
  date: string;
  rules: TaskRuleDto[]; // type ROUTINE, isActive = true
  existingDedupeKeys: Set<string>;
  render: (template: string, ctx: TemplateContext) => string;
}): GeneratedTask[]
```

Thuật toán: với mỗi shop ACTIVE × mỗi rule ROUTINE active → `dedupeKey = \`${shop.id}:routine:${rule.routineKey}:${date}\``; tồn tại → bỏ qua; ngược lại tạo task với `dueAt = date` lúc `dueHourLocal:00` theo `APP_TIMEZONE`, `assigneeId = shop.assigneeId`, `metricKey = null`. `TaskRule` ROUTINE lưu `dueInHours` = `dueHourLocal` (giờ trong ngày), `metricKey = null`, `level = null`.

Nội dung routine trong `vi.json`:

| routineKey | title | description |
|---|---|---|
| enter_metrics | Nhập chỉ số hôm nay – {shopName} | Mở Seller Center của {platformLabel}, vào mục Hiệu quả hoạt động, nhập đủ chỉ số của ngày {date} vào ShopPulse. |
| process_orders | Xử lý đơn chờ – {shopName} | Kiểm tra toàn bộ đơn ở trạng thái chờ lấy hàng / chờ giao. Xác nhận và in vận đơn cho đơn còn hạn trong 24 giờ trước. |
| reply_chats | Trả lời chat tồn – {shopName} | Trả lời mọi hội thoại chưa phản hồi. Ưu tiên hội thoại quá 6 giờ. |
| reply_low_ratings | Phản hồi đánh giá 1–3 sao – {shopName} | Trả lời mọi đánh giá 1–3 sao chưa phản hồi trong 48 giờ gần nhất theo mẫu của shop. |

### 3.7 Template & action hint — `src/lib/tasks/templates.ts`

```ts
export function renderTemplate(template: string, ctx: TemplateContext): string
```

Thay thế đúng 8 placeholder `{shopName}`, `{platformLabel}`, `{metricLabel}`, `{value}`, `{unit}`, `{threshold}`, `{level}`, `{date}`. Placeholder không có trong `ctx` giữ nguyên chuỗi. `platformLabel`: SHOPEE → `Shopee`, TIKTOK → `TikTok Shop`. `level`: WARNING → `Cảnh báo`, CRITICAL → `Nguy cấp`. `threshold` = `warningValue` khi level WARNING, `criticalValue` khi CRITICAL, format cùng `decimals` của chỉ số.

Template mặc định cho mọi rule ALERT (seed):

- `titleTemplate`: `[{level}] {metricLabel} {value}{unit} – {shopName}`
- `descriptionTemplate`: `Ngày {date}: {metricLabel} đang ở mức {value}{unit}, ngưỡng {level} là {threshold}{unit}.\n\nViệc cần làm:\n` + action hint theo bảng dưới.

`DEFAULT_ACTION_HINTS: Record<MetricKey, string>`:

| metricKey | Action hint |
|---|---|
| shopee_nfr | 1. Vào Seller Centre > Đơn hàng > Đơn huỷ, lọc 7 ngày, ghi nguyên nhân từng đơn.\n2. Tắt tạm sản phẩm hết hàng hoặc sai tồn.\n3. Báo trưởng nhóm nếu nguyên nhân là vận chuyển. |
| shopee_lsr | 1. Lọc đơn Chờ lấy hàng sắp quá hạn, bàn giao ngay trong ngày.\n2. Kiểm tra lịch lấy hàng của đơn vị vận chuyển.\n3. Nếu thiếu nhân lực đóng gói, báo trưởng nhóm. |
| shopee_prep_time | 1. Rà quy trình đóng gói, mục tiêu bàn giao trong 24 giờ.\n2. Bật chuẩn bị hàng trước cho sản phẩm bán chạy. |
| shopee_response_rate | 1. Trả lời toàn bộ chat tồn ngay.\n2. Bật trả lời tự động ngoài giờ trong Seller Centre. |
| shopee_response_time | 1. Phân ca trực chat, mục tiêu trả lời trong 1 giờ.\n2. Cập nhật FAQ trả lời nhanh. |
| shopee_rating | 1. Đọc toàn bộ đánh giá 1–3 sao trong 7 ngày, phân loại nguyên nhân.\n2. Liên hệ khách để xử lý, ghi kết quả vào nhiệm vụ. |
| shopee_penalty_points | 1. Vào Seller Centre > Hiệu quả hoạt động > Điểm phạt, chụp màn hình chi tiết vi phạm.\n2. Gửi trưởng nhóm để lập kế hoạch gỡ điểm. |
| shopee_pending_orders | 1. Xác nhận và in vận đơn toàn bộ đơn chờ.\n2. Ưu tiên đơn có hạn bàn giao gần nhất. |
| shopee_pending_chats | 1. Trả lời toàn bộ chat chưa phản hồi.\n2. Ưu tiên chat có đơn hàng đang chờ. |
| shopee_low_ratings | 1. Phản hồi từng đánh giá thấp theo mẫu.\n2. Ghi lại nguyên nhân để báo cáo tuần. |
| tiktok_ldr | 1. Vào Seller Center > Đơn hàng, lọc đơn quá hạn bàn giao, xử lý ngay.\n2. Kiểm tra lịch lấy hàng.\n3. Báo trưởng nhóm nếu lỗi từ đơn vị vận chuyển. |
| tiktok_sfcr | 1. Liệt kê đơn huỷ do shop trong 7 ngày và nguyên nhân.\n2. Đồng bộ tồn kho, tắt sản phẩm hết hàng. |
| tiktok_nrr | 1. Đọc đánh giá 1–2 sao trong 7 ngày, phân loại nguyên nhân.\n2. Liên hệ khách xử lý, ghi kết quả. |
| tiktok_violation_points | 1. Vào Seller Center > Sức khoẻ gian hàng > Vi phạm, chụp màn hình từng vi phạm.\n2. Gửi trưởng nhóm để quyết định khiếu nại. |
| tiktok_sps | 1. Xem chi tiết từng thành phần SPS trong Seller Center.\n2. Tạo nhiệm vụ con cho thành phần thấp nhất. |
| tiktok_pending_orders | 1. Xác nhận và in vận đơn toàn bộ đơn chờ.\n2. Ưu tiên đơn có hạn bàn giao gần nhất. |
| tiktok_pending_chats | 1. Trả lời toàn bộ chat chưa phản hồi.\n2. Ưu tiên chat có đơn hàng đang chờ. |
| tiktok_low_ratings | 1. Phản hồi từng đánh giá thấp theo mẫu.\n2. Ghi lại nguyên nhân để báo cáo tuần. |

Rule ALERT seed cho mỗi chỉ số: 2 rule — WARNING (`priority MEDIUM`, `dueInHours 24`) và CRITICAL (`priority URGENT`, `dueInHours 4`), `platform = platform của chỉ số`.

### 3.8 Định dạng CSV import — `src/lib/metrics/csv.ts`

File mẫu `public/templates/metrics-template.csv`:

```csv
date,metric_key,value
2026-09-28,shopee_nfr,3.20
2026-09-28,shopee_lsr,1.50
2026-09-28,shopee_rating,4.80
```

Quy tắc `parseMetricsCsv(text: string, platform: Platform): CsvParseResult`:

- Dòng đầu bắt buộc chính xác `date,metric_key,value` (không phân biệt hoa thường, cho phép dấu cách hai đầu). Sai → 1 lỗi `{ line: 1, field: "row", message: validation.csv.header }` và dừng.
- `date`: định dạng `YYYY-MM-DD`, không lớn hơn hôm nay theo `APP_TIMEZONE`. Sai → `validation.csv.date`.
- `metric_key`: phải thuộc `getMetricsForPlatform(platform)`. Sai → `validation.csv.metricKey`.
- `value`: số thập phân dùng dấu chấm, trong `[min, max]` của chỉ số. Sai → `validation.csv.value`.
- Dòng trống bỏ qua. Trùng (date, metric_key) trong cùng file → dòng sau ghi đè dòng trước, không báo lỗi.
- Tối đa 5 000 dòng dữ liệu; vượt → lỗi `{ line: 5002, field: "row", message: validation.csv.tooManyRows }` và dừng.

### 3.9 NotificationService — `src/lib/notifications/service.ts`

```ts
export interface SendNotificationInput {
  orgId: string;
  userIds: string[];
  type: NotificationType;
  title: string;
  body: string;
  link: string;
  channel: "IN_APP"; // hook: thêm "EMAIL" | "TELEGRAM" sau
}

export class NotificationService {
  static async send(input: SendNotificationInput): Promise<void>
}
```

Người nhận:

- Task URGENT sinh tự động: `shop.assigneeId` nếu có; nếu không, tất cả user role OWNER / MANAGER đang active trong org. `type = TASK_CREATED`, `link = /tasks/<taskId>`.
- Task được gán thủ công cho user khác người tạo: người được gán. `type = TASK_ASSIGNED`.
- Shop chuyển sang `CRITICAL` từ trạng thái khác (so với HealthScore ngày trước): OWNER / MANAGER. `type = SHOP_CRITICAL`, `link = /shops/<shopId>`.

### 3.10 SettingsProvider — `src/lib/settings/provider.ts`

```ts
export interface SettingsProvider {
  getThresholds(orgId: string): Promise<Record<string, ThresholdConfig>>;
  getAlertRules(orgId: string, platform: Platform): Promise<TaskRuleDto[]>;
  getRoutineRules(orgId: string): Promise<TaskRuleDto[]>;
}

export class DbSettingsProvider implements SettingsProvider { /* đọc từ Prisma */ }

export const settingsProvider: SettingsProvider = new DbSettingsProvider();
```

`src/lib/settings/defaults.ts`:

```ts
export async function createDefaultSettings(orgId: string): Promise<void>
```

Tạo `MetricThreshold` cho 18 chỉ số từ catalog và 36 `TaskRule` ALERT + 4 `TaskRule` ROUTINE theo mục 3.6, 3.7. Idempotent: bỏ qua dòng đã tồn tại.

### 3.11 PlatformConnector — `src/lib/connectors/types.ts`

```ts
export interface PlatformConnector {
  readonly platform: Platform;
  fetchDailyMetrics(input: { externalShopId: string; date: string }): Promise<MetricInput[]>;
}
```

Chỉ khai báo interface. Không có implementation trong v1.

### 3.12 Zustand stores

`src/stores/ui-store.ts`:

```ts
interface UiState {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
  setSidebarOpen: (open: boolean) => void;
}
export const useUiStore = create<UiState>()(...)
```

`src/stores/task-filter-store.ts` (persist key `shop-pulse.task-filters`):

```ts
interface TaskFilterState {
  status: TaskStatus[];        // mặc định ["OPEN", "IN_PROGRESS"]
  shopId: string | null;
  assigneeId: string | null;   // "me" = user hiện tại
  priority: TaskPriority | null;
  setFilter: (patch: Partial<Omit<TaskFilterState, "setFilter" | "reset">>) => void;
  reset: () => void;
}
export const useTaskFilterStore = create<TaskFilterState>()(persist(...))
```

Server state (shop, task, snapshot, settings, notifications, dashboard) dùng TanStack Query, không đưa vào Zustand. Query keys:

| Key | Dùng cho |
|---|---|
| `["dashboard", "summary"]` | GET /api/dashboard/summary |
| `["shops", { status }]` | GET /api/shops |
| `["shops", shopId]` | GET /api/shops/:id |
| `["shops", shopId, "metrics", { from, to }]` | GET /api/shops/:id/metrics |
| `["shops", shopId, "health", { from, to }]` | GET /api/shops/:id/health |
| `["tasks", filters, page]` | GET /api/tasks |
| `["tasks", taskId]` | GET /api/tasks/:id |
| `["settings", "thresholds"]` | GET /api/settings/thresholds |
| `["settings", "rules"]` | GET /api/settings/rules |
| `["members"]` | GET /api/members |
| `["notifications"]` | GET /api/notifications |
| `["metrics", "catalog"]` | GET /api/metrics/catalog |

`staleTime` mặc định 30 giây; `["notifications"]` refetch mỗi 60 giây.

### 3.13 Seed — `prisma/seed.ts`

Chạy bằng `pnpm db:seed`. Idempotent (upsert theo unique). Dữ liệu:

**Organization** (1): `{ name: SEED_ORG_NAME, slug: "demo-org", plan: "FREE" }`.

**User** (3), mật khẩu đều là `SEED_OWNER_PASSWORD`:

| email | name | role |
|---|---|---|
| `SEED_OWNER_EMAIL` | Chủ tổ chức | OWNER |
| manager@example.com | Trưởng nhóm vận hành | MANAGER |
| staff@example.com | Nhân viên vận hành | STAFF |

**Shop** (4):

| platform | name | externalShopId | assignee | status |
|---|---|---|---|---|
| SHOPEE | Shop Demo Shopee 1 | null | staff@example.com | ACTIVE |
| SHOPEE | Shop Demo Shopee 2 | null | manager@example.com | ACTIVE |
| TIKTOK | Shop Demo TikTok 1 | null | staff@example.com | ACTIVE |
| TIKTOK | Shop Demo TikTok 2 | null | null | PAUSED |

**MetricThreshold + TaskRule**: gọi `createDefaultSettings(orgId)`.

**MetricSnapshot**: 14 ngày gần nhất (hôm nay − 13 → hôm nay) cho 3 shop ACTIVE, đủ mọi chỉ số của platform, `source = MANUAL`, `createdBy = owner`. Giá trị sinh theo công thức cố định để tạo xu hướng:

- Shop Demo Shopee 1 (xu hướng xấu dần): `shopee_nfr = 2 + i * 0.7` (i = 0..13, i = 0 là ngày xa nhất), `shopee_lsr = 1 + i * 0.5`, `shopee_prep_time = 1.0`, `shopee_response_rate = 95 - i`, `shopee_response_time = 2`, `shopee_rating = 4.8`, `shopee_penalty_points = i >= 10 ? 1 : 0`, `shopee_pending_orders = 10 + i * 3`, `shopee_pending_chats = 2 + i`, `shopee_low_ratings = i >= 7 ? 2 : 0`.
- Shop Demo Shopee 2 (ổn định): mọi chỉ số ở mức OK: `shopee_nfr = 1.5`, `shopee_lsr = 1`, `shopee_prep_time = 0.8`, `shopee_response_rate = 96`, `shopee_response_time = 1.5`, `shopee_rating = 4.9`, `shopee_penalty_points = 0`, `shopee_pending_orders = 8`, `shopee_pending_chats = 1`, `shopee_low_ratings = 0`.
- Shop Demo TikTok 1 (cảnh báo): `tiktok_ldr = 2.5`, `tiktok_sfcr = 1.8`, `tiktok_nrr = 1`, `tiktok_violation_points = 4`, `tiktok_sps = 4.2`, `tiktok_pending_orders = 15`, `tiktok_pending_chats = 3`, `tiktok_low_ratings = 1`.

Sau khi insert snapshot, seed gọi `metric-service.recomputeHealth(shopId, date)` cho từng ngày và `generateAlertTasks` **chỉ cho ngày cuối** (hôm nay), để có sẵn nhiệm vụ mẫu.

**Task MANUAL** (2), shop Demo Shopee 2, `createdBy = manager`, `assignee = staff`:

| title | priority | status | dueAt |
|---|---|---|---|
| Cập nhật ảnh bìa shop theo chiến dịch 10.10 | MEDIUM | OPEN | hôm nay + 2 ngày 17:00 |
| Rà lại mô tả 5 sản phẩm bán chạy | LOW | IN_PROGRESS | hôm nay + 5 ngày 17:00 |

**Notification** (3) cho staff@example.com: 2 `TASK_CREATED` (link tới 2 task URGENT đầu tiên sinh ra), 1 `TASK_ASSIGNED` (link tới task manual đầu tiên). `readAt = null`.
