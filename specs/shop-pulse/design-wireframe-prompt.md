# ShopPulse — Danh sách tính năng & Prompt vẽ wireframe flow

Ngày: 2026-09-29 · Trạng thái spec: Master Spec (00–05) + Delta AHR + Delta Issue Center.

Phần A liệt kê tính năng hiện có. Phần B là prompt copy nguyên khối vào Claude Design.

---

## A. Tính năng hiện tại của ShopPulse

### A1. Đăng nhập & phân quyền
- Đăng nhập email + mật khẩu (không self-signup; OWNER / MANAGER tạo tài khoản).
- 3 role: **OWNER** (toàn quyền), **MANAGER** (mọi thứ trừ sửa OWNER), **STAFF** (xem, nhập chỉ số, xử lý nhiệm vụ của mình; không vào Cài đặt).
- Mọi dữ liệu thuộc 1 Organization (multi-tenant sẵn).

### A2. Quản lý shop
- Thêm / sửa / tạm dừng / xoá mềm shop trên **Shopee** hoặc **TikTok Shop**; gán người phụ trách.
- Danh sách shop sắp theo mức nguy hiểm; tìm kiếm, lọc theo sàn / trạng thái.

### A3. Nhập chỉ số theo ngày
- Form 1 màn hình cho 1 shop, **điền sẵn giá trị ngày gần nhất**, chỉ sửa ô thay đổi; ô trống không lưu.
- Catalog **25 chỉ số**: Shopee 10, TikTok 15; chia 4 nhóm: Hiệu suất · Trả hàng & khiếu nại · Đơn bị sàn huỷ · Việc tồn; mỗi chỉ số ghi rõ kỳ dữ liệu (7 ngày / 14 ngày / hiện tại / quý / 90 ngày).
- Import CSV nhiều ngày (`date,metric_key,value`), preview và báo lỗi từng dòng, file mẫu tải sẵn.
- Sau khi lưu: panel kết quả hiện Health Score mới, nhiệm vụ vừa sinh, nút "Nhập shop tiếp theo".

### A4. Health Score
- Điểm 0–100 mỗi shop mỗi ngày = trung bình có trọng số (OK 100 / Cảnh báo 50 / Nguy cấp 0).
- Trạng thái: **Ổn định ≥ 80 · Cảnh báo 50–79 · Nguy cấp < 50** (hoặc bất kỳ chỉ số trọng số 3 ở mức Nguy cấp) · Chưa có dữ liệu.
- Badge mức AHR chính thức của TikTok (Khoẻ mạnh / Cần cải thiện / Nguy cơ vô hiệu hoá / Đã vô hiệu hoá).
- Biểu đồ xu hướng 30 ngày mỗi chỉ số kèm 2 đường ngưỡng.

### A5. Task Engine (tự sinh nhiệm vụ)
- **ALERT**: chỉ số vượt ngưỡng → nhiệm vụ có hướng dẫn hành động từng bước; Cảnh báo = MEDIUM / 24 giờ, Nguy cấp = URGENT / 4 giờ; 2 chỉ số hạn 24 giờ của Issue Center (trả hàng cần duyệt gấp, sắp hết hạn khiếu nại) → HIGH / 6 giờ và URGENT / 2 giờ. Không sinh trùng khi nhiệm vụ cũ còn mở.
- **TREND**: chỉ số giảm mạnh trong 7 ngày (AHR ≥ 20 điểm, SPS ≥ 0.3, đánh giá Shopee ≥ 0.2) → nhiệm vụ HIGH dù chưa vượt ngưỡng.
- **ROUTINE** 07:00 mỗi ngày cho mỗi shop: Nhập chỉ số (10:00) · Xử lý đơn chờ (11:00) · Trả lời chat tồn (12:00) · Phản hồi đánh giá 1–3 sao (17:00) · **Kiểm tra Issue Center (11:00, chỉ TikTok)**.
- **Khiếu nại**: ghi vi phạm có hạn khiếu nại → nhiệm vụ "Nộp khiếu nại trước hạn", tự đóng khi cập nhật trạng thái đã nộp.

### A6. Dashboard "Tổng quan hôm nay"
- 4 thẻ đếm shop theo trạng thái; toggle "Chỉ shop của tôi".
- Cảnh báo shop chưa nhập chỉ số hôm nay (nút Nhập ngay).
- Panel **"Cần xử lý ngay"**: gom chỉ số có hạn của mọi shop (yêu cầu trả hàng, đơn chờ, chat tồn, đánh giá thấp), mỗi dòng dẫn tới nhiệm vụ hoặc form nhập.
- Lưới thẻ shop (sàn, score, trạng thái, AHR, việc mở, người phụ trách).
- Panel "Việc hôm nay" + "Quá hạn".

### A7. Quản lý nhiệm vụ
- Danh sách có bộ lọc (trạng thái, shop, người, ưu tiên, hạn), nhóm Quá hạn / Hôm nay / Sắp tới; badge AUTO / MANUAL / Xu hướng.
- Chi tiết: 4 trạng thái Mở → Đang làm → Hoàn thành / Bỏ qua (bắt buộc lý do); ghi chú kết quả; badge "Chỉ số đã về ngưỡng OK".
- Tạo nhiệm vụ thủ công (Sheet) từ trang Nhiệm vụ hoặc trang Shop.

### A8. Nhật ký vi phạm & khiếu nại
- Tab trên trang shop: ghi vi phạm (ngày, điểm trừ, lý do, mã, hạn khiếu nại), trạng thái Chưa khiếu nại / Đã nộp / Chấp nhận / Từ chối.
- Tóm tắt "Điểm trừ 90 ngày · Khiếu nại đang chờ".

### A9. Thông báo in-app
- Chuông + số chưa đọc; gửi khi có nhiệm vụ URGENT / HIGH gấp, khi được gán việc, khi shop rơi xuống Nguy cấp.

### A10. Cài đặt (OWNER / MANAGER)
- **Ngưỡng**: bảng 25 chỉ số, sửa Cảnh báo / Nguy cấp / Trọng số / Bật.
- **Quy tắc**: bật tắt, sửa mẫu tiêu đề / mô tả, thêm quy tắc ALERT / ROUTINE / TREND.
- **Thành viên**: tạo tài khoản, đổi role, khoá, đặt lại mật khẩu.

### A11. Nền tảng
- Cron 07:00 sinh routine; log JSON; rate limit login và import; responsive tới 375px; tiếng Việt tách file i18n.

---

## B. Prompt cho Claude Design (copy toàn bộ khối dưới)

```text
Hãy vẽ một bản WIREFRAME FLOW chi tiết (low-fidelity, dạng user-flow diagram) cho ứng dụng web "ShopPulse" — công cụ nội bộ theo dõi sức khoẻ vận hành nhiều gian hàng Shopee và TikTok Shop, tính Health Score theo ngày và tự sinh nhiệm vụ cho nhân viên vận hành sàn thương mại điện tử tại Việt Nam.

YÊU CẦU CHUNG
- Một canvas lớn, mọi màn hình là khung wireframe trắng-xám (grayscale), chữ tiếng Việt. Chỉ dùng 4 màu nhấn cho trạng thái: xanh lá #16A34A (Ổn định), cam #D97706 (Cảnh báo), đỏ #DC2626 (Nguy cấp), xám #6B7280 (Chưa có dữ liệu); tím #7C3AED cho badge "Xu hướng".
- Mỗi màn hình: tiêu đề khung = đường dẫn + tên trang (ví dụ "/ — Tổng quan hôm nay"), bên trong vẽ layout thật (sidebar, header, card, bảng, form) với text mẫu cụ thể như tôi mô tả, không dùng lorem ipsum.
- MŨI TÊN: mỗi nút / link có điều hướng phải có một mũi tên đi từ đúng nút đó sang màn hình đích, nhãn mũi tên = tên nút. Mũi tên nét liền = người dùng bấm; nét đứt = hệ thống tự làm (tính điểm, sinh nhiệm vụ, gửi thông báo, cron).
- CHÚ THÍCH: mỗi tính năng có một callout đánh số (①, ②, …) màu vàng nhạt cạnh vùng liên quan, giải thích 1–2 câu tính năng làm gì và quy tắc chính. Góc dưới phải có LEGEND giải thích mũi tên, màu, callout.
- Bố cục canvas theo 4 SWIMLANE ngang, từ trên xuống: (1) "Hệ thống & nguồn dữ liệu ngoài", (2) "Nhân viên vận hành (STAFF)", (3) "Trưởng nhóm / Chủ tổ chức (MANAGER / OWNER)", (4) "Overlay / Sheet / Dialog". Màn hình đặt trong lane của vai trò dùng nhiều nhất; overlay đặt lane 4 và nối mũi tên về trang mở nó.
- Đánh số màn hình S1…S14 và overlay O1…O5 để dễ tham chiếu.

LANE 1 — HỆ THỐNG & NGUỒN DỮ LIỆU NGOÀI (vẽ dạng hộp tròn góc, không phải wireframe)
- X1 "Shopee Seller Centre — Hiệu quả hoạt động" và X2 "TikTok Seller Center — Issue Center (Orders > Help & Automations)": nguồn số liệu nhân viên đọc rồi nhập tay. Mũi tên nét đứt từ X1/X2 tới S7 (Nhập chỉ số) nhãn "nhân viên chép số liệu".
- SYS1 "Cron 07:00 mỗi ngày": mũi tên nét đứt tới SYS3 nhãn "sinh nhiệm vụ routine".
- SYS2 "Health Score Engine": nhận từ S7/S8, mũi tên nét đứt tới S5 (chi tiết shop) nhãn "cập nhật score & trạng thái" và tới SYS3 nhãn "chỉ số vượt ngưỡng / giảm mạnh".
- SYS3 "Task Engine (ALERT · TREND · ROUTINE · Khiếu nại)": mũi tên nét đứt tới S9 (Nhiệm vụ) nhãn "tạo nhiệm vụ" và tới SYS4.
- SYS4 "Thông báo in-app": mũi tên nét đứt tới chuông trên header của mọi trang (vẽ 1 mũi tên tới S2).
- Callout ① cạnh SYS2: "Health Score 0–100 = trung bình có trọng số của từng chỉ số (OK 100 / Cảnh báo 50 / Nguy cấp 0). ≥80 Ổn định, 50–79 Cảnh báo, <50 hoặc có chỉ số trọng số 3 ở mức Nguy cấp → Nguy cấp."
- Callout ② cạnh SYS3: "ALERT: vượt ngưỡng → nhiệm vụ có hướng dẫn hành động; Cảnh báo = MEDIUM/24h, Nguy cấp = URGENT/4h; riêng 2 chỉ số hạn 24h của Issue Center (trả hàng cần duyệt gấp, sắp hết hạn khiếu nại) = HIGH/6h và URGENT/2h. TREND: chỉ số giảm mạnh trong 7 ngày → HIGH. ROUTINE: 5 việc cố định mỗi sáng. Không sinh trùng khi nhiệm vụ cũ còn mở."

LANE 2 — NHÂN VIÊN VẬN HÀNH (STAFF)

S1 "/login — Đăng nhập": logo ShopPulse, ô Email, ô Mật khẩu, nút [Đăng nhập], dòng lỗi mẫu "Email hoặc mật khẩu không đúng". Mũi tên [Đăng nhập] → S2.

S2 "/ — Tổng quan hôm nay" (màn hình trung tâm, vẽ to nhất):
- Header: ☰ · ShopPulse · Tên tổ chức · chuông 🔔 (badge "3") · tên user ▾ (menu: Đăng xuất). Sidebar trái: Tổng quan, Shop, Nhiệm vụ, Thông báo, ― Cài đặt: Ngưỡng, Quy tắc, Thành viên (mục Cài đặt ghi chú "chỉ MANAGER/OWNER").
- Dòng tiêu đề "Tổng quan hôm nay · 29/09/2026" + toggle [Chỉ shop của tôi].
- 4 thẻ đếm: Ổn định 5 · Cảnh báo 2 · Nguy cấp 1 · Chưa có dữ liệu 1 (viền theo màu).
- Banner cam "⚠ 2 shop chưa nhập chỉ số hôm nay: Shop A (2 ngày) [Nhập ngay] · Shop B (1 ngày) [Nhập ngay]".
- Panel "Cần xử lý ngay (3)": dòng "● Nguy cấp · Shop C · TikTok · Yêu cầu trả hàng cần duyệt gấp: 6 [Mở nhiệm vụ]", "● Cảnh báo · Shop C · TikTok · Sắp hết hạn khiếu nại: 2 [Mở nhiệm vụ]", "● Cảnh báo · Shop A · Shopee · Đơn chờ xử lý: 24 (dữ liệu hôm qua) [Nhập chỉ số]".
- Cột trái "Sức khoẻ shop": lưới thẻ shop, mỗi thẻ: badge sàn, tên shop, số score lớn (45 / 92), badge trạng thái, dòng "AHR 201 · Khoẻ mạnh" (chỉ TikTok), "3 việc mở", "Phụ trách: Nam", "Cập nhật: hôm nay".
- Cột phải "Việc hôm nay (7) · Quá hạn (2)": danh sách dòng nhiệm vụ "● URGENT [Nguy cấp] Tỷ lệ giao hàng trễ 12.00% – Shop A · hạn 11:00", "● HIGH Nhập chỉ số hôm nay – Shop B · hạn 10:00", link [Xem tất cả nhiệm vụ].
- Mũi tên: [Nhập ngay] → S7; [Mở nhiệm vụ] → S10; [Nhập chỉ số] (panel) → S7; thẻ shop → S5; thẻ đếm → S3; dòng nhiệm vụ → S10; [Xem tất cả nhiệm vụ] → S9; chuông → S11; sidebar Shop → S3, Nhiệm vụ → S9, Thông báo → S11, Ngưỡng → S12, Quy tắc → S13, Thành viên → S14; Đăng xuất → S1.
- Callout ③ cạnh panel Cần xử lý ngay: "Gom các chỉ số có hạn xử lý của MỌI shop (yêu cầu trả hàng hạn 24h, đơn chờ, chat tồn, đánh giá thấp) vào một chỗ, sắp Nguy cấp trước; lấy ý tưởng từ Issue Center của TikTok nhưng cho cả Shopee."
- Callout ④ cạnh banner: "Shop không có chỉ số ngày hôm nay bị gắn 'chưa cập nhật'; nhân viên bấm Nhập ngay để vào form."

S3 "/shops — Danh sách shop": tiêu đề + nút [Thêm shop] (ghi chú "chỉ MANAGER"); bộ lọc [Sàn ▾] [Trạng thái ▾] [ô tìm kiếm]; bảng cột: Shop | Sàn | Score | Trạng thái | Phụ trách | Việc mở | Cập nhật | [Xem]. 3 dòng mẫu, sắp Nguy cấp trước. Mũi tên: [Thêm shop] → S4; [Xem] → S5.

S4 "/shops/new — Tạo shop": form: Sàn (radio Shopee / TikTok Shop), Tên shop, ID shop trên sàn (tuỳ nhập), Người phụ trách ▾, Ghi chú; nút [Huỷ] [Tạo shop]. Mũi tên: [Tạo shop] → S7 nhãn "tạo xong → nhập chỉ số đầu tiên"; [Huỷ] → S3. Callout ⑤: "Sau khi tạo, app đưa thẳng tới form nhập chỉ số kèm banner 'Nhập chỉ số đầu tiên để bắt đầu theo dõi'."

S5 "/shops/[id] — Chi tiết shop":
- Dòng đầu: ← Shop · "Shop A · Shopee · Phụ trách: Nam · ACTIVE" · nút [Nhập chỉ số] [Import CSV] [Sửa] [Tạo nhiệm vụ].
- Cột trái: vòng Health Gauge số "45" + "Nguy cấp" + "Cập nhật hôm nay" + dòng "Điểm trừ 90 ngày: 10 · Khiếu nại đang chờ: 1".
- Tabs: [Chỉ số] [Vi phạm & khiếu nại].
- Tab Chỉ số: bảng nhóm theo section (Hiệu suất / Trả hàng & khiếu nại / Đơn bị sàn huỷ / Việc tồn), cột: Chỉ số | Giá trị | Ngưỡng CB | Ngưỡng NC | Mức; dòng mẫu "Tỷ lệ giao hàng trễ | 12.00% | 5% | 10% | ● Nguy cấp"; dòng AHR có badge "AHR 201 · Khoẻ mạnh". Dưới bảng: "Xu hướng 30 ngày [Chỉ số ▾]" + line chart có 2 đường ngưỡng cam/đỏ. Dưới cùng: "Nhiệm vụ của shop (3 mở)" danh sách dòng.
- Tab Vi phạm & khiếu nại: nút [Ghi nhận vi phạm]; bảng: Ngày | Điểm trừ | Lý do | Mã | Hạn khiếu nại | Trạng thái ▾ | [Sửa] [Xoá]; dòng mẫu "29/09 | 10 | Giao trễ đơn X | VP-123 | 02/10 (đỏ) | Chưa khiếu nại ▾".
- Mũi tên: [Nhập chỉ số] → S7; [Import CSV] → S8; [Sửa] → S6; [Tạo nhiệm vụ] → O1; [Ghi nhận vi phạm] → O4; dòng nhiệm vụ → S10; ← Shop → S3.
- Callout ⑥ cạnh tab Vi phạm: "Nhật ký vi phạm dùng cho cả 2 sàn (điểm trừ AHR TikTok / điểm Sao Quả Tạ Shopee). Ghi hạn khiếu nại → hệ thống tự tạo nhiệm vụ 'Nộp khiếu nại trước hạn'; đổi trạng thái sang Đã nộp → nhiệm vụ tự Hoàn thành."
- Callout ⑦ cạnh biểu đồ: "Xu hướng 30 ngày; quy tắc TREND bắt trường hợp giảm mạnh dù chưa chạm ngưỡng."

S6 "/shops/[id]/edit — Sửa shop": form giống S4 (Sàn bị khoá), thêm Trạng thái ▾ (ACTIVE/PAUSED), nút [Lưu], nút đỏ [Xoá shop]. Mũi tên: [Lưu] → S5; [Xoá shop] → O5; ← → S5.

S7 "/shops/[id]/metrics — Nhập chỉ số":
- Dòng đầu "← Shop A · Nhập chỉ số · TikTok Shop", chọn Ngày [29/09/2026 ▾] (ghi chú "không chọn ngày tương lai").
- Section "Hiệu suất": ô "Tỷ lệ giao hàng trễ (LDR) (7 ngày gần nhất) [ 2.10 ] % · hôm qua 1.90", "Tỷ lệ huỷ do người bán (SFCR) [ ] %", "Tỷ lệ hoàn tiền do người bán (SFRR) [ ] %", "Tỷ lệ đánh giá tiêu cực [ ] %", "Đánh giá sức khoẻ tài khoản (AHR) (90 ngày) [ 201 ] điểm → badge Khoẻ mạnh", "Điểm hiệu suất shop (SPS) [ 4.2 ]".
- Section "Trả hàng & khiếu nại" (dòng trợ giúp: "Số liệu lấy từ Seller Center > Orders > Help & Automations > Issue Center"): "Sắp hết hạn khiếu nại (24 giờ) [ 2 ]", "Cần duyệt gấp (tự động chấp nhận sau 24 giờ) [ 6 ]", "Sắp mở cửa sổ khiếu nại [ 1 ]".
- Section "Đơn bị sàn huỷ (14 ngày)": "Giao hàng thất bại [ 2 ]", "Hư hỏng / thất lạc [ 0 ]", "Quá hạn lấy hàng [ 1 ]".
- Section "Việc tồn": "Đơn chờ xử lý [ 15 ]", "Chat chưa trả lời [ 3 ]", "Đánh giá 1–3 sao chưa phản hồi [ 1 ]".
- Nút [Huỷ] [Lưu chỉ số].
- Panel kết quả (vẽ như khung xuất hiện sau khi lưu): "Health Score: 45 · Nguy cấp (hôm qua: 78 · Cảnh báo)", "Nhiệm vụ mới sinh (2): ● URGENT [Nguy cấp] Yêu cầu trả hàng cần duyệt gấp 6 – Shop C · hạn 2 giờ; ● HIGH [Cảnh báo] Sắp hết hạn khiếu nại 2 – Shop C · hạn 6 giờ", nút [Xem nhiệm vụ] [Nhập shop tiếp theo: Shop D →].
- Mũi tên: [Lưu chỉ số] → SYS2 (nét đứt, nhãn "tính Health Score → sinh nhiệm vụ"); [Xem nhiệm vụ] → S9; [Nhập shop tiếp theo] → S7 (vòng lặp về chính nó, nhãn "shop kế tiếp chưa nhập"); ← → S5.
- Callout ⑧: "Form điền sẵn giá trị ngày gần nhất; chỉ sửa ô thay đổi; ô trống không lưu. Shopee có 10 chỉ số, TikTok 15, chia 4 nhóm, ghi rõ kỳ dữ liệu."

S8 "/shops/[id]/import — Import CSV": link [Tải file mẫu], dropzone "Kéo thả hoặc chọn file .csv (≤ 1 MB, ≤ 5000 dòng)", bảng preview 20 dòng (date | metric_key | value), dòng "30 dòng · 2 lỗi", nút [Import]; card kết quả "Thành công 28 · Lỗi 2 · Ngày ảnh hưởng 27/09, 28/09 · Nhiệm vụ sinh ra: 1" + bảng lỗi (dòng | cột | lỗi) + nút [Xem shop]. Mũi tên: [Import] → SYS2 (nét đứt); [Xem shop] → S5. Callout ⑨: "Định dạng cố định date,metric_key,value; lỗi từng dòng được báo, dòng đúng vẫn lưu; chỉ ngày mới nhất sinh nhiệm vụ."

S9 "/tasks — Nhiệm vụ": nút [Tạo nhiệm vụ]; bộ lọc [Trạng thái: Mở, Đang làm ▾] [Shop ▾] [Người: Tôi ▾] [Ưu tiên ▾] [Hạn ▾] [Xoá bộ lọc]; 3 nhóm: "Quá hạn (2)", "Hôm nay (5)", "Sắp tới (3)"; dòng mẫu "● URGENT [Nguy cấp] Yêu cầu trả hàng cần duyệt gấp 6 – Shop C · Nam · hạn 29/09 11:00 · AUTO", "● HIGH [Xu hướng] AHR giảm 39 điểm trong 7 ngày – Shop C · AUTO", "● HIGH Kiểm tra Issue Center – Shop C · hạn 11:00 · AUTO", "● LOW Rà lại mô tả 5 sản phẩm – Shop B · MANUAL"; phân trang. Mũi tên: dòng → S10; [Tạo nhiệm vụ] → O1. Callout ⑩: "Badge AUTO = hệ thống sinh (ALERT / TREND / ROUTINE / khiếu nại), MANUAL = người tạo. STAFF chỉ sửa nhiệm vụ của mình hoặc chưa gán."

S10 "/tasks/[id] — Chi tiết nhiệm vụ": tiêu đề "[URGENT] [Nguy cấp] Yêu cầu trả hàng cần duyệt gấp 6 – Shop C" + badge AUTO; dòng "Shop: Shop C (TikTok) [Mở shop] · Phụ trách: [Nam ▾] · Hạn: 29/09/2026 11:00"; dòng "Chỉ số: Yêu cầu trả hàng cần duyệt gấp · 6 · ngày 29/09" + alert xanh "✔ Chỉ số đã về ngưỡng OK ở lần nhập gần nhất"; khối Mô tả: "Việc cần làm: 1. Vào Issue Center > Insight 4 > Check Now NGAY. 2. Duyệt hoặc từ chối từng yêu cầu trước hạn 24 giờ… 3. Cập nhật số còn lại vào ShopPulse."; radio Trạng thái (● Mở ○ Đang làm ○ Hoàn thành ○ Bỏ qua), ô "Ghi chú kết quả", nút [Cập nhật]. Mũi tên: [Mở shop] → S5; [Cập nhật] → S9; ← → S9. Callout ⑪: "Mỗi nhiệm vụ tự sinh có hướng dẫn hành động từng bước và đường dẫn tới đúng màn hình Seller Center. Bỏ qua bắt buộc ghi lý do."

S11 "/notifications — Thông báo": nút [Đánh dấu tất cả đã đọc]; danh sách "● Nhiệm vụ URGENT mới: … – Shop C · 5 phút trước", "Bạn được gán: Cập nhật ảnh bìa – Shop B", "Shop A chuyển sang Nguy cấp". Mũi tên: dòng nhiệm vụ → S10; dòng shop → S5. Callout ⑫: "Chỉ thông báo in-app (chưa email / Telegram); gửi khi có nhiệm vụ URGENT hoặc HIGH gấp, khi được gán việc, khi shop rơi xuống Nguy cấp."

LANE 3 — TRƯỞNG NHÓM / CHỦ TỔ CHỨC

S12 "/settings/thresholds — Ngưỡng chỉ số": tabs [Shopee] [TikTok Shop]; bảng: Chỉ số | Chiều tốt | Cảnh báo | Nguy cấp | Trọng số ▾ | Bật ☑; dòng mẫu "Tỷ lệ giao hàng trễ (LDR) | Càng thấp | [4] | [8] | 3 | ☑", "AHR | Càng cao | [260] | [199] | 3 | ☑", "Cần duyệt gấp | Càng thấp | [1] | [5] | 3 | ☑"; dòng ghi chú "Ngưỡng là cài đặt nội bộ của tổ chức, không phải chính sách sàn"; nút [Lưu thay đổi]. Mũi tên: [Lưu thay đổi] → SYS2 (nét đứt, nhãn "áp dụng từ lần nhập tiếp theo"). Callout ⑬: "25 chỉ số, mỗi chỉ số có ngưỡng Cảnh báo / Nguy cấp / trọng số 1–3; tắt được từng chỉ số."

S13 "/settings/rules — Quy tắc sinh nhiệm vụ": tabs [Cảnh báo (ALERT)] [Routine] [Xu hướng (TREND)]; nút [Thêm quy tắc]; bảng: Loại | Sàn | Chỉ số / Routine | Mức | Ưu tiên | Hạn | Bật (switch) | [Sửa] [Xoá]; dòng mẫu "ALERT | TikTok | Cần duyệt gấp | Nguy cấp | URGENT | 2 giờ | ☑", "ROUTINE | TikTok | check_issue_center | — | HIGH | 11:00 | ☑", "TREND | TikTok | AHR | giảm ≥ 20 / 7 ngày | HIGH | 24 giờ | ☑". Mũi tên: [Thêm quy tắc] / [Sửa] → O2; [Xoá] → O5; switch → SYS3 (nét đứt). Callout ⑭: "Mẫu tiêu đề / mô tả dùng placeholder {shopName} {metricLabel} {value} {threshold} {delta}…; trưởng nhóm sửa được mà không cần lập trình."

S14 "/settings/members — Thành viên": nút [Thêm thành viên]; bảng: Tên | Email | Role | Đang hoạt động (switch) | [Sửa]; dòng mẫu "Chủ tổ chức | owner@… | OWNER", "Trưởng nhóm | manager@… | MANAGER", "Nhân viên | staff@… | STAFF". Mũi tên: [Thêm thành viên] / [Sửa] → O3. Callout ⑮: "Không self-signup; MANAGER tạo tài khoản, đổi role, khoá, đặt lại mật khẩu; không sửa được OWNER."

LANE 4 — OVERLAY / SHEET / DIALOG
- O1 "Sheet: Tạo nhiệm vụ": Shop ▾, Tiêu đề, Mô tả, Ưu tiên ▾ (MEDIUM), Người phụ trách ▾, Hạn (datetime, mặc định 17:00 hôm nay), [Huỷ] [Tạo]. Mũi tên [Tạo] → S9.
- O2 "Sheet: Quy tắc": Loại ▾ (ALERT / ROUTINE / TREND), Sàn ▾, Chỉ số ▾, Mức ▾ (ALERT), Số ngày + Mức giảm (TREND), Mã routine + Giờ đến hạn (ROUTINE), Mẫu tiêu đề, Mẫu mô tả, Ưu tiên ▾, Hạn (giờ), Bật ☑, [Lưu]. Mũi tên [Lưu] → S13.
- O3 "Sheet: Thành viên": Email, Tên, Role ▾, Mật khẩu (tạo) / Mật khẩu mới (sửa), [Lưu]. Mũi tên [Lưu] → S14.
- O4 "Sheet: Ghi nhận vi phạm": Ngày vi phạm, Điểm trừ, Lý do, Mã tham chiếu, Hạn khiếu nại (date), Ghi chú, [Lưu]. Mũi tên [Lưu] → S5 và nét đứt → SYS3 nhãn "tạo nhiệm vụ Nộp khiếu nại".
- O5 "Dialog xác nhận xoá": "Xoá shop Shop A? Nhiệm vụ đang mở sẽ bị bỏ qua." [Huỷ] [Xoá]. Mũi tên [Xoá] → S3.

FLOW CHÍNH CẦN LÀM NỔI BẬT (vẽ thêm một dải "Hành trình 1 ngày của nhân viên" ở mép trái canvas, đánh số bước, mỗi bước trỏ tới màn hình tương ứng):
1. 07:00 Cron sinh routine (SYS1 → SYS3 → S9).
2. Nhân viên đăng nhập, xem Tổng quan (S1 → S2).
3. Bấm Nhập ngay ở shop chưa cập nhật (S2 → S7), chép số từ Seller Center / Issue Center (X1, X2 → S7).
4. Lưu → hệ thống tính score, sinh nhiệm vụ, gửi thông báo (S7 → SYS2 → SYS3 → SYS4).
5. Nhập shop tiếp theo cho tới hết (S7 → S7).
6. Xử lý nhiệm vụ theo ưu tiên (S2 / S9 → S10), ghi chú, Hoàn thành.
7. Ghi vi phạm mới nếu có, nộp khiếu nại trước hạn (S5 tab Vi phạm → O4 → nhiệm vụ).
8. Cuối ngày trưởng nhóm xem xu hướng, chỉnh ngưỡng / quy tắc (S5, S12, S13).

Vẽ toàn bộ trên một canvas duy nhất, có thể zoom; giữ khoảng cách đủ để mũi tên không chồng chéo; mũi tên đi ra từ đúng vị trí nút.
```

---

## C. Ghi chú sử dụng

- Nếu Claude Design giới hạn độ dài, tách prompt theo lane: dán phần "YÊU CẦU CHUNG" + 1 lane mỗi lượt, giữ nguyên mã S1…S14 / O1…O5 / SYS1…SYS4 để mũi tên giữa các lượt vẫn khớp.
- Sau khi có wireframe, thay đổi nào về màn hình phải quay lại spec bằng `Thay đổi: …` để ra Delta Spec; wireframe không thay thế spec.
