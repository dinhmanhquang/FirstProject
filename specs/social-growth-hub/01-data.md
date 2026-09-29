# Social Growth Hub — 01 Data

Đọc kèm: `00-overview.md` (mục [0], [1], [2]).

---

## [3] Data Models & State

### 3.1 Quy ước chung

- ID: `String @id @default(cuid())`.
- Timestamp: `createdAt DateTime @default(now())`, `updatedAt DateTime @updatedAt`; lưu UTC, hiển thị theo `Asia/Ho_Chi_Minh`.
- Soft-delete: chỉ áp dụng cho `Post`, `Link`, `AutomationRule`, `ReplyTemplate`, `KnowledgeItem`, `Product` qua cột `deletedAt DateTime?`. Mọi truy vấn list mặc định thêm `deletedAt: null`. Các bảng khác xóa cứng.
- Mọi bảng nghiệp vụ có `orgId String` + `@@index([orgId])` + relation tới `Organization` với `onDelete: Cascade`.
- Bí mật (access token, refresh token) lưu dạng chuỗi đã mã hóa bởi `encryptSecret()`; tên cột kết thúc bằng `Enc`.
- JSON: dùng `Json` của Prisma; cấu trúc JSON được cố định bằng Zod schema trong `src/lib/validations/*` và type trong `src/types/index.ts`.

### 3.2 `prisma/schema.prisma` (đầy đủ)

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ===== Enums =====

enum Role {
  OWNER
  MANAGER
  EDITOR
  SEEDER
}

enum Plan {
  INTERNAL
}

enum Platform {
  FACEBOOK_PAGE
  INSTAGRAM
  TIKTOK
  YOUTUBE
  ZALO_OA
}

enum SocialAccountStatus {
  ACTIVE
  TOKEN_EXPIRED
  DISCONNECTED
  ERROR
}

enum MediaType {
  IMAGE
  VIDEO
}

enum PostStatus {
  DRAFT
  SCHEDULED
  PUBLISHING
  PUBLISHED
  PARTIALLY_FAILED
  FAILED
}

enum VariantStatus {
  PENDING
  PUBLISHING
  PUBLISHED
  FAILED
}

enum TrendSource {
  GOOGLE_TRENDS
  YOUTUBE_POPULAR
  KEYWORD_WATCH
  OWN_CHANNEL
}

enum TrendStatus {
  NEW
  USED
  IGNORED
}

enum InteractionType {
  COMMENT
  MESSAGE
}

enum InteractionStatus {
  OPEN
  REPLIED
  ESCALATED
  IGNORED
}

enum Intent {
  PRICE_ASK
  PRODUCT_QUESTION
  ORDER_STATUS
  COMPLAINT
  REFUND
  PRAISE
  SPAM
  OTHER
}

enum Sentiment {
  POSITIVE
  NEUTRAL
  NEGATIVE
}

enum ReplyMode {
  MANUAL
  AI_ASSISTED
  AUTO
}

enum ReplyStatus {
  DRAFT
  SENDING
  SENT
  FAILED
}

enum CampaignStatus {
  ACTIVE
  PAUSED
  DONE
}

enum SeedingTaskStatus {
  TODO
  DONE
  SKIPPED
}

enum RuleTriggerType {
  NEW_COMMENT
  NEW_MESSAGE
  POST_ENGAGEMENT_THRESHOLD
  TREND_RELEVANT
}

enum JobStatus {
  RUNNING
  COMPLETED
  FAILED
}

// ===== Auth (Auth.js) =====

model User {
  id            String       @id @default(cuid())
  name          String?
  email         String       @unique
  emailVerified DateTime?
  image         String?
  passwordHash  String?
  accounts      Account[]
  sessions      Session[]
  memberships   Membership[]
  createdAt     DateTime     @default(now())
  updatedAt     DateTime     @updatedAt
}

model Account {
  id                String  @id @default(cuid())
  userId            String
  type              String
  provider          String
  providerAccountId String
  refresh_token     String?
  access_token      String?
  expires_at        Int?
  token_type        String?
  scope             String?
  id_token          String?
  session_state     String?
  user              User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerAccountId])
  @@index([userId])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime

  @@unique([identifier, token])
}

// ===== Tenant =====

model Organization {
  id        String   @id @default(cuid())
  name      String
  slug      String   @unique
  niche     String   @default("") // Mô tả ngành hàng, dùng trong prompt AI
  plan      Plan     @default(INTERNAL)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  memberships      Membership[]
  socialAccounts   SocialAccount[]
  media            Media[]
  posts            Post[]
  postVariants     PostVariant[]
  trends           Trend[]
  interactions     Interaction[]
  replies          Reply[]
  replyTemplates   ReplyTemplate[]
  knowledgeItems   KnowledgeItem[]
  products         Product[]
  fans             Fan[]
  links            Link[]
  linkClicks       LinkClick[]
  linkHubs         LinkHub[]
  seedingCampaigns SeedingCampaign[]
  seedingTargets   SeedingTarget[]
  seedingTasks     SeedingTask[]
  automationRules  AutomationRule[]
  ruleRuns         RuleRun[]
  insightSnapshots InsightSnapshot[]
  postMetrics      PostMetric[]
  settings         Setting[]
  jobRuns          JobRun[]
  aiUsages         AiUsage[]
}

model Membership {
  id        String   @id @default(cuid())
  orgId     String
  userId    String
  role      Role     @default(EDITOR)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  org  Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  user User         @relation(fields: [userId], references: [id], onDelete: Cascade)

  seedingTargets SeedingTarget[]
  replies        Reply[]
  posts          Post[]

  @@unique([orgId, userId])
  @@index([orgId])
  @@index([userId])
}

// ===== Channels =====

model SocialAccount {
  id              String              @id @default(cuid())
  orgId           String
  platform        Platform
  externalId      String // Page ID / IG user ID / TikTok open_id / YouTube channel ID / Zalo OA ID
  name            String
  avatarUrl       String?
  accessTokenEnc  String
  refreshTokenEnc String?
  tokenExpiresAt  DateTime?
  scopes          String[]            @default([])
  status          SocialAccountStatus @default(ACTIVE)
  lastSyncedAt    DateTime?
  lastError       String?
  metadata        Json                @default("{}") // platform-specific: { igBusinessId, pageId, uploadsPlaylistId }
  createdAt       DateTime            @default(now())
  updatedAt       DateTime            @updatedAt

  org              Organization      @relation(fields: [orgId], references: [id], onDelete: Cascade)
  variants         PostVariant[]
  interactions     Interaction[]
  insightSnapshots InsightSnapshot[]

  @@unique([orgId, platform, externalId])
  @@index([orgId])
}

// ===== Content =====

model Media {
  id          String    @id @default(cuid())
  orgId       String
  type        MediaType
  url         String
  pathname    String // pathname trong Vercel Blob, dùng để xóa
  mimeType    String
  sizeBytes   Int
  width       Int?
  height      Int?
  durationSec Int?
  createdAt   DateTime  @default(now())

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@index([orgId])
}

model Post {
  id           String     @id @default(cuid())
  orgId        String
  title        String // Tiêu đề nội bộ, không đăng
  baseContent  String // Nội dung gốc trước khi tách biến thể
  mediaIds     String[]   @default([])
  status       PostStatus @default(DRAFT)
  scheduledAt  DateTime?
  publishedAt  DateTime?
  trendId      String?
  campaignId   String?
  createdById  String // Membership.id
  ctaLinkId    String? // Link.id chèn vào cuối bài
  deletedAt    DateTime?
  createdAt    DateTime   @default(now())
  updatedAt    DateTime   @updatedAt

  org       Organization     @relation(fields: [orgId], references: [id], onDelete: Cascade)
  createdBy Membership       @relation(fields: [createdById], references: [id])
  trend     Trend?           @relation(fields: [trendId], references: [id])
  campaign  SeedingCampaign? @relation(fields: [campaignId], references: [id])
  ctaLink   Link?            @relation(fields: [ctaLinkId], references: [id])
  variants  PostVariant[]
  seedingTasks SeedingTask[]

  @@index([orgId, status, scheduledAt])
  @@index([orgId, deletedAt])
}

model PostVariant {
  id              String        @id @default(cuid())
  orgId           String
  postId          String
  socialAccountId String
  content         String
  hashtags        String[]      @default([])
  mediaIds        String[]      @default([])
  status          VariantStatus @default(PENDING)
  externalPostId  String?
  externalUrl     String?
  publishedAt     DateTime?
  errorMessage    String?
  attempts        Int           @default(0)
  createdAt       DateTime      @default(now())
  updatedAt       DateTime      @updatedAt

  org           Organization  @relation(fields: [orgId], references: [id], onDelete: Cascade)
  post          Post          @relation(fields: [postId], references: [id], onDelete: Cascade)
  socialAccount SocialAccount @relation(fields: [socialAccountId], references: [id], onDelete: Cascade)
  interactions  Interaction[]
  metrics       PostMetric[]

  @@unique([postId, socialAccountId])
  @@index([orgId, status])
  @@index([socialAccountId, externalPostId])
}

// ===== Trends =====

model Trend {
  id              String      @id @default(cuid())
  orgId           String
  source          TrendSource
  externalKey     String // URL hoặc keyword để chống trùng
  title           String
  url             String?
  rawScore        Int         @default(0) // Lượt tìm kiếm / view từ nguồn
  relevanceScore  Int? // 0-100 do AI chấm
  aiSummary       String?
  suggestedAngles Json        @default("[]") // string[] tối đa 3
  status          TrendStatus @default(NEW)
  capturedAt      DateTime    @default(now())
  scoredAt        DateTime?
  createdAt       DateTime    @default(now())
  updatedAt       DateTime    @updatedAt

  org   Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  posts Post[]

  @@unique([orgId, source, externalKey])
  @@index([orgId, status, relevanceScore])
}

// ===== Inbox =====

model Interaction {
  id               String            @id @default(cuid())
  orgId            String
  socialAccountId  String
  type             InteractionType
  externalId       String
  parentExternalId String?
  postVariantId    String?
  fanId            String
  content          String
  attachmentUrls   String[]          @default([])
  intent           Intent?
  sentiment        Sentiment?
  confidence       Float? // 0-1
  escalate         Boolean           @default(false)
  status           InteractionStatus @default(OPEN)
  receivedAt       DateTime
  classifiedAt     DateTime?
  createdAt        DateTime          @default(now())
  updatedAt        DateTime          @updatedAt

  org           Organization  @relation(fields: [orgId], references: [id], onDelete: Cascade)
  socialAccount SocialAccount @relation(fields: [socialAccountId], references: [id], onDelete: Cascade)
  postVariant   PostVariant?  @relation(fields: [postVariantId], references: [id])
  fan           Fan           @relation(fields: [fanId], references: [id])
  replies       Reply[]

  @@unique([socialAccountId, externalId])
  @@index([orgId, status, receivedAt])
  @@index([orgId, fanId])
}

model Reply {
  id            String      @id @default(cuid())
  orgId         String
  interactionId String
  content       String
  mode          ReplyMode
  status        ReplyStatus @default(DRAFT)
  sentById      String? // Membership.id, null khi AUTO
  externalId    String?
  errorMessage  String?
  sentAt        DateTime?
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt

  org         Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  interaction Interaction  @relation(fields: [interactionId], references: [id], onDelete: Cascade)
  sentBy      Membership?  @relation(fields: [sentById], references: [id])

  @@index([orgId, interactionId])
}

model ReplyTemplate {
  id              String     @id @default(cuid())
  orgId           String
  name            String
  triggerKeywords String[]   @default([]) // so khớp lowercase, contains
  content         String // hỗ trợ {name}, {shop}
  platforms       Platform[] @default([])
  deletedAt       DateTime?
  createdAt       DateTime   @default(now())
  updatedAt       DateTime   @updatedAt

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@index([orgId, deletedAt])
}

model KnowledgeItem {
  id        String    @id @default(cuid())
  orgId     String
  question  String
  answer    String
  tags      String[]  @default([])
  deletedAt DateTime?
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@index([orgId, deletedAt])
}

model Product {
  id          String    @id @default(cuid())
  orgId       String
  name        String
  priceVnd    Int
  description String    @default("")
  links       Json      @default("{}") // { tiktokShop?: string, shopee?: string, lazada?: string, website?: string }
  active      Boolean   @default(true)
  deletedAt   DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@index([orgId, deletedAt])
}

// ===== Fans =====

model Fan {
  id               String   @id @default(cuid())
  orgId            String
  platform         Platform
  externalUserId   String
  displayName      String
  avatarUrl        String?
  commentCount     Int      @default(0)
  messageCount     Int      @default(0)
  score            Int      @default(0)
  tags             String[] @default([])
  notes            String   @default("")
  canMessage       Boolean  @default(false) // true khi Zalo follower hoặc đã nhắn Messenger trong 24h
  firstSeenAt      DateTime @default(now())
  lastSeenAt       DateTime @default(now())
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt

  org          Organization  @relation(fields: [orgId], references: [id], onDelete: Cascade)
  interactions Interaction[]

  @@unique([orgId, platform, externalUserId])
  @@index([orgId, score])
  @@index([orgId, lastSeenAt])
}

// ===== Links =====

model Link {
  id         String    @id @default(cuid())
  orgId      String
  slug       String
  title      String
  targetUrl  String
  utmSource  String?
  utmMedium  String?
  utmCampaign String?
  clickCount Int       @default(0)
  deletedAt  DateTime?
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt

  org    Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  clicks LinkClick[]
  posts  Post[]
  seedingTasks SeedingTask[]

  @@unique([slug])
  @@index([orgId, deletedAt])
}

model LinkClick {
  id           String   @id @default(cuid())
  orgId        String
  linkId       String
  seedingTaskId String?
  referer      String?
  userAgent    String?
  platformHint Platform? // suy ra từ referer / ?src=
  ipHash       String? // sha256(ip + ngày), không lưu IP thô
  clickedAt    DateTime @default(now())

  org  Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  link Link         @relation(fields: [linkId], references: [id], onDelete: Cascade)

  @@index([orgId, linkId, clickedAt])
}

model LinkHub {
  id        String   @id @default(cuid())
  orgId     String
  slug      String
  title     String
  bio       String   @default("")
  avatarUrl String?
  items     Json     @default("[]") // LinkHubItem[] (xem types)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@unique([slug])
  @@unique([orgId]) // Tier B: 1 hub / org
}

// ===== Seeding =====

model SeedingCampaign {
  id          String         @id @default(cuid())
  orgId       String
  name        String
  goal        String // Mô tả mục tiêu, dùng trong prompt sinh biến thể
  ctaLinkId   String? // Link.id dùng chung cho task
  status      CampaignStatus @default(ACTIVE)
  startAt     DateTime
  endAt       DateTime?
  createdAt   DateTime       @default(now())
  updatedAt   DateTime       @updatedAt

  org     Organization    @relation(fields: [orgId], references: [id], onDelete: Cascade)
  targets SeedingTarget[]
  tasks   SeedingTask[]
  posts   Post[]

  @@index([orgId, status])
}

model SeedingTarget {
  id           String   @id @default(cuid())
  orgId        String
  campaignId   String
  name         String // Tên group / cộng đồng
  url          String
  platform     Platform
  audienceNote String   @default("") // Mô tả đối tượng để AI viết đúng giọng
  assigneeId   String? // Membership.id người phụ trách đăng
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  org      Organization    @relation(fields: [orgId], references: [id], onDelete: Cascade)
  campaign SeedingCampaign @relation(fields: [campaignId], references: [id], onDelete: Cascade)
  assignee Membership?     @relation(fields: [assigneeId], references: [id])
  tasks    SeedingTask[]

  @@index([orgId, campaignId])
}

model SeedingTask {
  id          String            @id @default(cuid())
  orgId       String
  campaignId  String
  targetId    String
  postId      String? // Bài gốc nếu task sinh từ Post
  content     String // Biến thể nội dung AI sinh, người đăng copy
  linkId      String? // Short link theo dõi riêng cho task
  status      SeedingTaskStatus @default(TODO)
  dueAt       DateTime
  doneAt      DateTime?
  proofUrl    String? // URL bài đã đăng do người đăng dán vào
  clickCount  Int               @default(0)
  createdAt   DateTime          @default(now())
  updatedAt   DateTime          @updatedAt

  org      Organization    @relation(fields: [orgId], references: [id], onDelete: Cascade)
  campaign SeedingCampaign @relation(fields: [campaignId], references: [id], onDelete: Cascade)
  target   SeedingTarget   @relation(fields: [targetId], references: [id], onDelete: Cascade)
  post     Post?           @relation(fields: [postId], references: [id])
  link     Link?           @relation(fields: [linkId], references: [id])

  @@index([orgId, status, dueAt])
  @@index([orgId, targetId])
}

// ===== Automation =====

model AutomationRule {
  id          String          @id @default(cuid())
  orgId       String
  name        String
  triggerType RuleTriggerType
  trigger     Json // RuleTrigger (xem types)
  conditions  Json            @default("[]") // RuleCondition[]
  actions     Json // RuleAction[] (≥ 1)
  enabled     Boolean         @default(true)
  runCount    Int             @default(0)
  lastRunAt   DateTime?
  deletedAt   DateTime?
  createdAt   DateTime        @default(now())
  updatedAt   DateTime        @updatedAt

  org  Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  runs RuleRun[]

  @@index([orgId, enabled, triggerType])
}

model RuleRun {
  id         String   @id @default(cuid())
  orgId      String
  ruleId     String
  eventType  RuleTriggerType
  eventRefId String // interactionId / postVariantId / trendId
  matched    Boolean
  actionsLog Json     @default("[]") // { action, ok, error? }[]
  ranAt      DateTime @default(now())

  org  Organization   @relation(fields: [orgId], references: [id], onDelete: Cascade)
  rule AutomationRule @relation(fields: [ruleId], references: [id], onDelete: Cascade)

  @@index([orgId, ruleId, ranAt])
}

// ===== Analytics =====

model InsightSnapshot {
  id              String   @id @default(cuid())
  orgId           String
  socialAccountId String
  date            DateTime @db.Date
  followers       Int      @default(0)
  reach           Int      @default(0)
  impressions     Int      @default(0)
  engagements     Int      @default(0)
  raw             Json     @default("{}")
  createdAt       DateTime @default(now())

  org           Organization  @relation(fields: [orgId], references: [id], onDelete: Cascade)
  socialAccount SocialAccount @relation(fields: [socialAccountId], references: [id], onDelete: Cascade)

  @@unique([socialAccountId, date])
  @@index([orgId, date])
}

model PostMetric {
  id            String   @id @default(cuid())
  orgId         String
  postVariantId String
  capturedAt    DateTime @default(now())
  likes         Int      @default(0)
  comments      Int      @default(0)
  shares        Int      @default(0)
  views         Int      @default(0)
  reach         Int      @default(0)

  org         Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)
  postVariant PostVariant  @relation(fields: [postVariantId], references: [id], onDelete: Cascade)

  @@index([orgId, postVariantId, capturedAt])
}

// ===== Settings & Ops =====

model Setting {
  id        String   @id @default(cuid())
  orgId     String
  key       String // SETTING_KEYS trong settings-provider.ts
  value     Json
  updatedAt DateTime @updatedAt

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@unique([orgId, key])
}

model JobRun {
  id         String    @id @default(cuid())
  orgId      String
  queue      String
  jobName    String
  jobId      String
  status     JobStatus
  error      String?
  startedAt  DateTime  @default(now())
  finishedAt DateTime?

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@index([orgId, queue, startedAt])
}

model AiUsage {
  id           String   @id @default(cuid())
  orgId        String
  purpose      String // generate_post | classify | draft_reply | score_trend | seeding_variants
  model        String
  inputTokens  Int
  outputTokens Int
  createdAt    DateTime @default(now())

  org Organization @relation(fields: [orgId], references: [id], onDelete: Cascade)

  @@index([orgId, createdAt])
}
```

### 3.3 `src/types/index.ts` (toàn bộ nội dung)

```ts
import type {
  Platform,
  Role,
  PostStatus,
  VariantStatus,
  Intent,
  Sentiment,
  InteractionStatus,
  InteractionType,
  TrendSource,
  TrendStatus,
  SeedingTaskStatus,
  CampaignStatus,
  RuleTriggerType,
  ReplyMode,
  SocialAccountStatus,
} from "@prisma/client";

export type {
  Platform,
  Role,
  PostStatus,
  VariantStatus,
  Intent,
  Sentiment,
  InteractionStatus,
  InteractionType,
  TrendSource,
  TrendStatus,
  SeedingTaskStatus,
  CampaignStatus,
  RuleTriggerType,
  ReplyMode,
  SocialAccountStatus,
};

// ===== API envelope =====

export interface ApiErrorBody {
  error: {
    code: ApiErrorCode;
    message: string;
    details?: { path: string; message: string }[];
  };
}

export type ApiErrorCode =
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "VALIDATION_ERROR"
  | "CONFLICT"
  | "RATE_LIMITED"
  | "PLATFORM_ERROR"
  | "AI_QUOTA_EXCEEDED"
  | "AI_ERROR"
  | "INVALID_STATE"
  | "INTERNAL_ERROR";

export interface PageMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Paginated<T> {
  data: T[];
  meta: PageMeta;
}

// ===== Org context =====

export interface OrgContext {
  userId: string;
  orgId: string;
  membershipId: string;
  role: Role;
}

// ===== Platform adapter =====

export type PlatformCapability =
  | "PUBLISH_TEXT"
  | "PUBLISH_IMAGE"
  | "PUBLISH_VIDEO"
  | "PUBLISH_LINK"
  | "READ_COMMENTS"
  | "REPLY_COMMENT"
  | "READ_MESSAGES"
  | "REPLY_MESSAGE"
  | "INSIGHTS"
  | "BROADCAST";

export const PLATFORM_CAPABILITIES: Record<Platform, PlatformCapability[]> = {
  FACEBOOK_PAGE: [
    "PUBLISH_TEXT",
    "PUBLISH_IMAGE",
    "PUBLISH_VIDEO",
    "PUBLISH_LINK",
    "READ_COMMENTS",
    "REPLY_COMMENT",
    "READ_MESSAGES",
    "REPLY_MESSAGE",
    "INSIGHTS",
  ],
  INSTAGRAM: ["PUBLISH_IMAGE", "PUBLISH_VIDEO", "READ_COMMENTS", "REPLY_COMMENT", "INSIGHTS"],
  TIKTOK: ["PUBLISH_VIDEO", "PUBLISH_IMAGE", "INSIGHTS"],
  YOUTUBE: ["PUBLISH_VIDEO", "READ_COMMENTS", "REPLY_COMMENT", "INSIGHTS"],
  ZALO_OA: ["PUBLISH_TEXT", "PUBLISH_IMAGE", "PUBLISH_LINK", "READ_MESSAGES", "REPLY_MESSAGE", "INSIGHTS", "BROADCAST"],
};

export const PLATFORM_LIMITS: Record<Platform, { maxChars: number; maxHashtags: number; maxMedia: number }> = {
  FACEBOOK_PAGE: { maxChars: 63206, maxHashtags: 30, maxMedia: 10 },
  INSTAGRAM: { maxChars: 2200, maxHashtags: 30, maxMedia: 10 },
  TIKTOK: { maxChars: 2200, maxHashtags: 30, maxMedia: 35 },
  YOUTUBE: { maxChars: 5000, maxHashtags: 15, maxMedia: 1 },
  ZALO_OA: { maxChars: 2000, maxHashtags: 0, maxMedia: 9 },
};

export interface PublishInput {
  content: string;
  hashtags: string[];
  media: { url: string; type: "IMAGE" | "VIDEO"; mimeType: string }[];
  linkUrl?: string;
  title?: string; // YouTube title / TikTok title
}

export interface PublishResult {
  externalPostId: string;
  externalUrl: string | null;
  publishedAt: Date;
}

export interface NormalizedInteraction {
  externalId: string;
  parentExternalId: string | null;
  type: InteractionType;
  externalPostId: string | null;
  fromUserId: string;
  fromName: string;
  fromAvatarUrl: string | null;
  content: string;
  attachmentUrls: string[];
  receivedAt: Date;
}

export interface NormalizedMetric {
  externalPostId: string;
  likes: number;
  comments: number;
  shares: number;
  views: number;
  reach: number;
}

export interface NormalizedInsight {
  date: Date;
  followers: number;
  reach: number;
  impressions: number;
  engagements: number;
  raw: Record<string, unknown>;
}

export interface AdapterCredentials {
  accessToken: string;
  refreshToken: string | null;
  tokenExpiresAt: Date | null;
  externalId: string;
  metadata: Record<string, unknown>;
}

export interface PlatformAdapter {
  platform: Platform;
  capabilities: PlatformCapability[];
  publish(creds: AdapterCredentials, input: PublishInput): Promise<PublishResult>;
  fetchInteractions(creds: AdapterCredentials, since: Date): Promise<NormalizedInteraction[]>;
  replyToInteraction(
    creds: AdapterCredentials,
    interaction: { externalId: string; type: InteractionType; fromUserId: string },
    content: string,
  ): Promise<{ externalId: string }>;
  fetchPostMetrics(creds: AdapterCredentials, externalPostIds: string[]): Promise<NormalizedMetric[]>;
  fetchInsights(creds: AdapterCredentials, date: Date): Promise<NormalizedInsight>;
  refreshToken(creds: AdapterCredentials): Promise<AdapterCredentials>;
  parseWebhook?(body: unknown): NormalizedInteraction[];
}

export class PlatformError extends Error {
  constructor(
    public platform: Platform,
    public code: string,
    message: string,
    public retryable: boolean,
  ) {
    super(message);
    this.name = "PlatformError";
  }
}

// ===== AI =====

export interface GeneratedVariant {
  platform: Platform;
  content: string;
  hashtags: string[];
  title: string | null;
}

export interface ClassificationResult {
  intent: Intent;
  sentiment: Sentiment;
  confidence: number; // 0-1
  escalate: boolean;
  reason: string;
}

export interface TrendScore {
  externalKey: string;
  relevanceScore: number; // 0-100
  summary: string;
  angles: string[]; // 3 phần tử
}

// ===== Link hub =====

export interface LinkHubItem {
  id: string; // nanoid 8
  label: string;
  linkId: string; // Link.id
  icon: "shop" | "group" | "zalo" | "facebook" | "tiktok" | "youtube" | "instagram" | "website";
  order: number;
}

// ===== Automation =====

export type RuleTrigger =
  | { type: "NEW_COMMENT"; platforms: Platform[] }
  | { type: "NEW_MESSAGE"; platforms: Platform[] }
  | { type: "POST_ENGAGEMENT_THRESHOLD"; metric: "likes" | "comments" | "shares" | "views"; gte: number }
  | { type: "TREND_RELEVANT"; minRelevance: number };

export type RuleCondition =
  | { field: "content"; op: "contains_any" | "not_contains_any"; values: string[] }
  | { field: "intent"; op: "in"; values: Intent[] }
  | { field: "sentiment"; op: "in"; values: Sentiment[] }
  | { field: "fanScore"; op: "gte" | "lte"; value: number };

export type RuleAction =
  | { type: "REPLY_TEMPLATE"; templateId: string }
  | { type: "TAG_FAN"; tag: string }
  | { type: "NOTIFY_TELEGRAM"; message: string }
  | { type: "ESCALATE" }
  | { type: "CREATE_DRAFT_FROM_TREND"; platforms: Platform[] }
  | { type: "PIN_CTA_COMMENT"; linkId: string };

export interface RuleEvent {
  type: RuleTriggerType;
  orgId: string;
  refId: string;
  payload: {
    platform?: Platform;
    content?: string;
    intent?: Intent | null;
    sentiment?: Sentiment | null;
    fanId?: string;
    fanScore?: number;
    metric?: { likes: number; comments: number; shares: number; views: number };
    relevanceScore?: number;
  };
}

// ===== Settings =====

export type AutoReplyMode = "OFF" | "DRAFT_ONLY" | "AUTO_SAFE";

export interface OrgSettings {
  "org.timezone": string; // "Asia/Ho_Chi_Minh"
  "org.brandVoice": string; // Mô tả giọng văn
  "org.shopName": string; // Tên shop hiển thị trong reply, thay {shop}
  "ai.autoReplyMode": AutoReplyMode;
  "ai.autoReplyMinConfidence": number; // 0.8
  "ai.dailyCallLimit": number; // 2000
  "ai.safeIntents": Intent[]; // ["PRICE_ASK","PRODUCT_QUESTION","PRAISE","OTHER"]
  "telegram.chatId": string;
  "telegram.notifyEscalation": boolean;
  "telegram.notifyPublishFailed": boolean;
  "telegram.notifySeedingTask": boolean;
  "trends.keywords": string[];
  "trends.minRelevanceToNotify": number; // 70
}

export type SettingKey = keyof OrgSettings;

// ===== Analytics =====

export interface AnalyticsOverview {
  range: { from: string; to: string };
  followersTotal: number;
  followersDelta: number;
  postsPublished: number;
  engagements: number;
  interactionsReceived: number;
  interactionsReplied: number;
  avgFirstResponseMinutes: number | null;
  linkClicks: number;
  escalatedOpen: number;
}

export interface ChannelStat {
  socialAccountId: string;
  platform: Platform;
  name: string;
  followers: number;
  followersDelta: number;
  postsPublished: number;
  engagements: number;
  engagementRate: number; // engagements / reach, 0 nếu reach = 0
  linkClicks: number;
}

export interface TopPost {
  postId: string;
  variantId: string;
  platform: Platform;
  title: string;
  publishedAt: string;
  likes: number;
  comments: number;
  shares: number;
  views: number;
  externalUrl: string | null;
}

export interface FunnelStats {
  reach: number;
  engagements: number;
  linkClicks: number;
  hubClicks: number;
}

// ===== Dashboard =====

export interface DashboardData {
  overview: AnalyticsOverview;
  upcomingPosts: { id: string; title: string; scheduledAt: string; platforms: Platform[] }[];
  openEscalations: number;
  newTrends: number;
  seedingTasksDue: number;
  channelsNeedAttention: { id: string; name: string; platform: Platform; status: SocialAccountStatus }[];
}
```

### 3.4 Zustand stores

`src/stores/ui-store.ts`

```ts
import { create } from "zustand";

interface UiState {
  sidebarCollapsed: boolean;
  toggleSidebar: () => void;
  activeDialog: "connect-channel" | "ai-generate" | "schedule" | "confirm" | null;
  openDialog: (d: UiState["activeDialog"]) => void;
  closeDialog: () => void;
}

export const useUiStore = create<UiState>((set) => ({
  sidebarCollapsed: false,
  toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
  activeDialog: null,
  openDialog: (activeDialog) => set({ activeDialog }),
  closeDialog: () => set({ activeDialog: null }),
}));
```

`src/stores/post-editor-store.ts`

```ts
import { create } from "zustand";
import type { Platform } from "@/types";

export interface EditorVariant {
  socialAccountId: string;
  platform: Platform;
  content: string;
  hashtags: string[];
  title: string | null;
  mediaIds: string[];
}

interface PostEditorState {
  postId: string | null;
  title: string;
  baseContent: string;
  mediaIds: string[];
  ctaLinkId: string | null;
  trendId: string | null;
  campaignId: string | null;
  selectedAccountIds: string[];
  variants: Record<string, EditorVariant>; // key = socialAccountId
  scheduledAt: string | null; // ISO
  dirty: boolean;
  load: (data: Partial<Omit<PostEditorState, "load" | "reset" | "setField" | "toggleAccount" | "setVariant" | "applyBaseToAll">>) => void;
  setField: <K extends "title" | "baseContent" | "mediaIds" | "ctaLinkId" | "trendId" | "campaignId" | "scheduledAt">(
    key: K,
    value: PostEditorState[K],
  ) => void;
  toggleAccount: (socialAccountId: string, platform: Platform) => void;
  setVariant: (socialAccountId: string, patch: Partial<EditorVariant>) => void;
  applyBaseToAll: () => void;
  reset: () => void;
}

const initial = {
  postId: null,
  title: "",
  baseContent: "",
  mediaIds: [] as string[],
  ctaLinkId: null,
  trendId: null,
  campaignId: null,
  selectedAccountIds: [] as string[],
  variants: {} as Record<string, EditorVariant>,
  scheduledAt: null,
  dirty: false,
};

export const usePostEditorStore = create<PostEditorState>((set, get) => ({
  ...initial,
  load: (data) => set({ ...initial, ...data, dirty: false }),
  setField: (key, value) => set({ [key]: value, dirty: true } as Partial<PostEditorState>),
  toggleAccount: (socialAccountId, platform) => {
    const { selectedAccountIds, variants, baseContent, mediaIds } = get();
    if (selectedAccountIds.includes(socialAccountId)) {
      const next = { ...variants };
      delete next[socialAccountId];
      set({ selectedAccountIds: selectedAccountIds.filter((id) => id !== socialAccountId), variants: next, dirty: true });
    } else {
      set({
        selectedAccountIds: [...selectedAccountIds, socialAccountId],
        variants: {
          ...variants,
          [socialAccountId]: { socialAccountId, platform, content: baseContent, hashtags: [], title: null, mediaIds },
        },
        dirty: true,
      });
    }
  },
  setVariant: (socialAccountId, patch) =>
    set((s) => ({ variants: { ...s.variants, [socialAccountId]: { ...s.variants[socialAccountId], ...patch } }, dirty: true })),
  applyBaseToAll: () =>
    set((s) => ({
      variants: Object.fromEntries(
        Object.entries(s.variants).map(([k, v]) => [k, { ...v, content: s.baseContent, mediaIds: s.mediaIds }]),
      ),
      dirty: true,
    })),
  reset: () => set(initial),
}));
```

`src/stores/inbox-store.ts`

```ts
import { create } from "zustand";
import type { InteractionStatus, Intent, Platform, Sentiment } from "@/types";

export interface InboxFilters {
  status: InteractionStatus | "ALL";
  platforms: Platform[];
  intents: Intent[];
  sentiments: Sentiment[];
  search: string;
}

interface InboxState {
  filters: InboxFilters;
  selectedId: string | null;
  setFilter: <K extends keyof InboxFilters>(key: K, value: InboxFilters[K]) => void;
  resetFilters: () => void;
  select: (id: string | null) => void;
}

const defaultFilters: InboxFilters = { status: "OPEN", platforms: [], intents: [], sentiments: [], search: "" };

export const useInboxStore = create<InboxState>((set) => ({
  filters: defaultFilters,
  selectedId: null,
  setFilter: (key, value) => set((s) => ({ filters: { ...s.filters, [key]: value } })),
  resetFilters: () => set({ filters: defaultFilters }),
  select: (selectedId) => set({ selectedId }),
}));
```

### 3.5 Settings mặc định (`src/lib/settings/settings-provider.ts`)

```ts
import type { OrgSettings, SettingKey } from "@/types";

export const SETTING_DEFAULTS: OrgSettings = {
  "org.timezone": "Asia/Ho_Chi_Minh",
  "org.brandVoice": "Thân thiện, gần gũi, xưng 'shop' và gọi khách là 'bạn'. Không dùng từ ngữ tiêu cực. Kết thúc bằng lời mời hành động rõ ràng.",
  "org.shopName": "",
  "ai.autoReplyMode": "DRAFT_ONLY",
  "ai.autoReplyMinConfidence": 0.8,
  "ai.dailyCallLimit": 2000,
  "ai.safeIntents": ["PRICE_ASK", "PRODUCT_QUESTION", "PRAISE", "OTHER"],
  "telegram.chatId": "",
  "telegram.notifyEscalation": true,
  "telegram.notifyPublishFailed": true,
  "telegram.notifySeedingTask": true,
  "trends.keywords": [],
  "trends.minRelevanceToNotify": 70,
};

export const SETTING_KEYS = Object.keys(SETTING_DEFAULTS) as SettingKey[];

export interface SettingsProvider {
  get<K extends SettingKey>(orgId: string, key: K): Promise<OrgSettings[K]>;
  getAll(orgId: string): Promise<OrgSettings>;
  set<K extends SettingKey>(orgId: string, key: K, value: OrgSettings[K]): Promise<void>;
}
```

`DbSettingsProvider` (`db-settings-provider.ts`): `get` đọc `Setting` theo `(orgId, key)`; không có → trả `SETTING_DEFAULTS[key]`. `set` upsert. Cache in-memory `Map<orgId, { at: number; values: OrgSettings }>` TTL 60 giây; `set` xóa cache của org.

### 3.6 Seed data (`prisma/seed.ts`)

Seed chạy idempotent bằng `upsert` theo khóa duy nhất. Mật khẩu seed: `Password123!` (bcrypt cost 12). Không seed `SocialAccount` thật; seed 1 `SocialAccount` giả với `status: DISCONNECTED` và token mã hóa của chuỗi `"seed-token"` để UI có dữ liệu.

**Organization** (1):

| id | name | slug | niche |
|---|---|---|---|
| `org_seed_0001` | Demo Shop | `demo-shop` | Bán đồ trang trí nhà cửa và phụ kiện gia đình trên sàn TMĐT |

**User + Membership** (4):

| email | name | role |
|---|---|---|
| owner@demo.local | Owner Demo | OWNER |
| manager@demo.local | Manager Demo | MANAGER |
| editor@demo.local | Editor Demo | EDITOR |
| seeder@demo.local | Seeder Demo | SEEDER |

**SocialAccount** (3, `DISCONNECTED`):

| platform | externalId | name |
|---|---|---|
| FACEBOOK_PAGE | `seed-page-1` | Demo Shop Page |
| TIKTOK | `seed-tiktok-1` | @demoshop |
| ZALO_OA | `seed-zalo-1` | Demo Shop OA |

**Product** (3):

| name | priceVnd | links.website |
|---|---|---|
| Decal dán tường hoa anh đào | 89000 | https://example.com/p/decal-hoa |
| Đèn ngủ LED cảm ứng | 159000 | https://example.com/p/den-led |
| Kệ gỗ treo tường 3 tầng | 249000 | https://example.com/p/ke-go |

**KnowledgeItem** (3): ship toàn quốc 2–4 ngày; đổi trả trong 7 ngày nếu lỗi nhà sản xuất; thanh toán COD hoặc chuyển khoản.

**ReplyTemplate** (3):

| name | triggerKeywords | content |
|---|---|---|
| Hỏi giá | `["giá", "bao nhiêu", "nhiêu tiền"]` | `Chào {name}, {shop} đã inbox báo giá cho bạn rồi nhé, bạn kiểm tra tin nhắn giúp shop ạ 💛` |
| Hỏi ship | `["ship", "giao hàng", "phí vận chuyển"]` | `{shop} ship toàn quốc 2–4 ngày, freeship đơn từ 199.000đ bạn nhé!` |
| Cảm ơn | `["cảm ơn", "đẹp quá", "xinh quá"]` | `Cảm ơn {name} nhiều nha, {shop} gửi tặng bạn mã giảm 10% ở tin nhắn nhé 🎁` |

**Link** (3): slug `shop-tiktok` → https://example.com/tiktok-shop; `nhom-zalo` → https://example.com/zalo-group; `fanpage` → https://example.com/fanpage.

**LinkHub** (1): slug `demo-shop`, 3 item trỏ 3 link trên.

**Trend** (3, source `GOOGLE_TRENDS`, status `NEW`): "Trang trí nhà đón Tết" (relevanceScore 85), "Đèn ngủ decor phòng" (78), "Xu hướng phòng khách tối giản" (64).

**Post** (3): 1 `DRAFT`, 1 `SCHEDULED` (scheduledAt = now + 1 ngày, 1 variant cho FACEBOOK_PAGE), 1 `PUBLISHED` (publishedAt = now − 2 ngày, 1 variant `PUBLISHED` externalPostId `seed-ext-1`, 1 `PostMetric` likes 120 comments 14 shares 6 views 3400 reach 5000).

**Fan** (3, FACEBOOK_PAGE): Nguyễn Minh Anh (score 12, tags `["hoi-gia"]`), Trần Bảo (score 4), Lê Thu Hà (score 25, tags `["super_fan"]`).

**Interaction** (3, gắn vào variant PUBLISHED): 1 `OPEN` intent `PRICE_ASK` "Decal này giá bao nhiêu ạ?"; 1 `REPLIED` intent `PRAISE` "Đẹp quá shop ơi" (có 1 `Reply` `SENT` mode `AUTO`); 1 `ESCALATED` intent `COMPLAINT` "Mình nhận hàng bị rách góc, xử lý sao đây?".

**SeedingCampaign** (1) "Seeding Tết 2027" + **SeedingTarget** (3): "Hội Decor Nhà Đẹp" (FACEBOOK_PAGE, assignee seeder), "Cộng đồng Mẹ Bỉm Sài Gòn" (FACEBOOK_PAGE, assignee seeder), "Nhóm Zalo Khách Thân Thiết" (ZALO_OA, assignee manager) + **SeedingTask** (3, mỗi target 1 task `TODO`, dueAt = now + 2 ngày).

**AutomationRule** (3):

| name | triggerType | conditions | actions |
|---|---|---|---|
| Tự trả lời hỏi giá | NEW_COMMENT (all platforms) | intent in [PRICE_ASK] | REPLY_TEMPLATE(Hỏi giá), TAG_FAN("hoi-gia") |
| Báo khiếu nại | NEW_COMMENT + NEW_MESSAGE | intent in [COMPLAINT, REFUND] | ESCALATE, NOTIFY_TELEGRAM("Có khiếu nại mới cần xử lý") |
| Trend nóng | TREND_RELEVANT minRelevance 80 | — | NOTIFY_TELEGRAM("Trend mới liên quan: {title}"), CREATE_DRAFT_FROM_TREND([FACEBOOK_PAGE, TIKTOK]) |

**Setting** (3): `org.shopName` = "Demo Shop"; `ai.autoReplyMode` = "DRAFT_ONLY"; `trends.keywords` = `["decal dán tường", "đèn ngủ", "decor phòng"]`.
