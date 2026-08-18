# UIT Data Science Challenge 2026 — Task 1: LegalIR
## Truy vấn văn bản pháp luật tiếng Việt (Legal Information Retrieval)

> Tài liệu này tóm tắt **đầy đủ** yêu cầu của Task 1, tổng hợp từ: Thể lệ cuộc thi (PDF),
> `DSC2026_Task1_LegalIR_Data_Overview.docx`, email "Dữ liệu Vòng Public Test – Task 1",
> email "Cập nhật QUAN TRỌNG về độ đo đánh giá", email "Đăng ký Mô hình", và mã nguồn chấm điểm
> `Scoring-Program-Task-LegalIR/scoring.py`.
>
> Khi có mâu thuẫn giữa các nguồn, **email cập nhật mới nhất + mã nguồn chấm điểm** là căn cứ cuối cùng.

---

## 1. Tổng quan bài toán

| Mục | Nội dung |
|---|---|
| **Tên** | Task 1 – Legal Information Retrieval (LegalIR) |
| **Mục tiêu** | Với một câu hỏi pháp luật, hệ thống xác định (các) văn bản hành chính/pháp lý chứa thông tin cần thiết và trả về **ID** của văn bản đó |
| **Input** | Một câu hỏi tiếng Việt cần truy vấn thông tin pháp luật |
| **Output** | Danh sách `document_id` của các văn bản chứa thông tin để trả lời câu hỏi |
| **Loại bài toán** | Document-level retrieval / ranking (không phải trích xuất đoạn, không phải sinh văn bản) |
| **Codabench** | https://www.codabench.org/competitions/17715/ |

### Bối cảnh (theo thể lệ)
Khối lượng văn bản pháp luật Việt Nam tăng nhanh cả về số lượng lẫn độ phức tạp; người dân, doanh nghiệp
và cơ quan quản lý gặp khó khăn khi tra cứu, đối chiếu quy định. Task 1 yêu cầu các đội xây dựng phương pháp
truy vấn văn bản pháp luật **dựa trên mô hình ngôn ngữ lớn**, hướng tới độ chính xác cao, khả năng mở rộng tốt
và tiềm năng ứng dụng thực tế.

### Ví dụ mẫu
```json
"147194": {
  "question": "Việc tổ chức vận động, tiếp nhận, sử dụng nguồn đóng góp tự nguyện được thực hiện dựa trên nguyên tắc nào?",
  "answer": ["177504"]
}
```

---

## 2. Dữ liệu

### 2.1. Các tệp dữ liệu (cấp theo timeline)

| Tệp | Nội dung |
|---|---|
| `train.json` | Tập huấn luyện cho các đội phát triển phương pháp |
| `warmup.json` | Tập mẫu vòng Warm-up (làm quen bài toán + quy trình submission) |
| `public-official.json` | Tập dùng trong giai đoạn **Public Test** (cấu hình chính thức) |
| `private-official.json` | Tập chính thức của **Private Test** |
| `selected-contexts.zip` | Kho văn bản (corpus) được chọn; giải nén thành nhiều tệp `context_*.json` |

**Link dữ liệu Public Test (BTC cung cấp):**
https://drive.google.com/drive/folders/1e4XctfiDz9TNPuxYtNJ3Uoaz0vQ9gB1t?usp=sharing

### 2.2. Định dạng tệp câu hỏi

`train.json` — JSON Object, key là `id` của câu hỏi:
```json
{
  "86666": {
    "question": "Thời hạn cấp đăng ký xe máy của người nước ngoài làm việc tại Việt Nam là bao lâu?",
    "answer": ["280282"]
  }
}
```

`public-official.json` — cùng cấu trúc nhưng trường `answer` là `null` (cần dự đoán):
```json
{
  "38096": {
    "question": "Đề nghị xem xét lại quyết định đình chỉ tiến hành thủ tục phá sản được xem xét, giải quyết trong thời hạn bao nhiêu ngày làm việc?",
    "answer": null
  }
}
```

### 2.3. Định dạng một văn bản trong corpus (`context_*.json`)

| Trường | Ý nghĩa |
|---|---|
| `id` | Mã định danh duy nhất của văn bản (**đây chính là `document_id` cần trả về**) |
| `name` | Tiêu đề văn bản |
| `link` | Đường dẫn nguồn (thuvienphapluat.vn) |
| `passage` | Nội dung văn bản dùng để truy vấn |

```json
{
  "link": "https://thuvienphapluat.vn/van-ban/Bo-may-hanh-chinh/Quyet-dinh-5868-QD-BYT-2018-...aspx",
  "name": "Quyet-dinh-5868-QD-BYT-2018-co-cau-to-chuc-cua-Vu-Trang-thiet-bi-va-Cong-trinh-y-te-396608",
  "passage": "BỘ Y TẾ\n-------\nCỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\n... QUYẾT ĐỊNH ...",
  "id": 740
}
```

> ⚠️ Lưu ý: `id` trong corpus là **số nguyên**, còn `answer` trong tập câu hỏi là **chuỗi** (`"177504"`).
> Khi chấm điểm hệ thống dùng `set(...) & set(...)` nên **phải xuất ID dạng chuỗi** trong submission.

### 2.4. Thống kê thực tế của bộ dữ liệu Public Test (đã tải về)

| Chỉ số | Giá trị |
|---|---|
| Số câu hỏi `train.json` | **7.000** |
| Số câu hỏi `public-official.json` | **1.000** |
| Số văn bản trong corpus (`context_*.json`) | **8.532** |
| Số đáp án trung bình / câu hỏi | **1,09** |
| Phân bố số đáp án | 1 đáp án: 6.447 · 2: 485 · 3: 53 · 4: 14 · 5: 1 |

**Hệ quả chiến lược:** ~92% câu hỏi chỉ có **đúng 1** văn bản đúng. Vì Precision là độ đo phụ, và
Recall được chuẩn hoá theo `|đáp án đúng|`, việc trả về đủ 5 ID gần như luôn tối ưu cho Recall
(mất Precision nhưng Precision chỉ dùng để phá hoà). Xem mục 4.4.

---

## 3. Độ đo đánh giá

> **Đây là điểm đã bị BTC đính chính 2 lần.** Kết luận cuối cùng:

| Độ đo | Vai trò | Mô tả |
|---|---|---|
| **Recall** | **Độ đo CHÍNH** (xếp hạng) | Tỷ lệ các văn bản đúng được hệ thống truy xuất |
| **Precision** | Độ đo phụ (tie-break) | Tỷ lệ các văn bản hệ thống truy xuất là đúng |

Lịch sử đính chính:
1. Email đầu: "Precision là chính, Recall là phụ" → **SAI, đã bị thu hồi**.
2. Email đính chính: "**Recall là metric chính**, nếu bằng Recall thì xét Precision".
3. Vì có thể lách luật bằng cách submit toàn bộ document-id để đạt Recall = 1, BTC thêm **ràng buộc tối đa 5 đáp án/câu hỏi** vào mã nguồn chấm điểm.

### 3.1. Công thức

Với câu hỏi thứ *i*, gọi `T_i` = tập `document_id` đúng, `P_i` = tập `document_id` hệ thống trả về:

```
Recall_i    = |T_i ∩ P_i| / |T_i|
Precision_i = |T_i ∩ P_i| / |P_i|

Recall    = (1/N) · Σ Recall_i
Precision = (1/N) · Σ Precision_i
```
với `N` là tổng số câu hỏi. Cả hai nằm trong [0, 1], càng cao càng tốt.

- Nếu hệ thống **không trả về văn bản nào** cho một câu hỏi → Precision (và Recall) của câu đó = **0**.
- Điểm trung bình tính trên **toàn bộ** câu hỏi, **bao gồm cả** các câu vi phạm ràng buộc.

### 3.2. Ràng buộc số lượng đáp án (BẮT BUỘC)

- Mỗi câu hỏi chỉ được đánh giá **tối đa 05 `document_id`**.
- Nếu một câu hỏi có **> 5** `document_id` → **Recall = 0 VÀ Precision = 0** cho câu hỏi đó.
- Nếu một câu hỏi có **0** `document_id` → Recall = 0 và Precision = 0.

### 3.3. Mã nguồn chấm điểm chính thức

BTC công khai tại: https://drive.google.com/file/d/12QTJfS_GlilTibz4k3jV1c8q8_BU0V36/view?usp=sharing
(bản local: `Task 1/Scoring-Program-Task-LegalIR/scoring.py`)

```python
recall = np.array([
    len(set(y_true[k]) & set(y_pred.get(k, set()))) / len(y_true[k])
    if len(y_pred.get(k)) > 0 and len(y_pred.get(k)) <= 5 else 0
    for k in ids_truth]).mean()

precision = np.array([
    len(set(y_true[k]) & set(y_pred.get(k, set()))) / len(y_pred[k])
    if len(y_pred.get(k)) > 0 and len(y_pred.get(k)) <= 5 else 0
    for k in ids_preds]).mean()
```

**Những điều rút ra từ mã nguồn (rất quan trọng):**
1. `y_pred` được đọc dưới dạng `{k: v['answer']}` → submission **bắt buộc** có trường `answer`.
2. **Số lượng key trong submission phải bằng đúng số key trong reference**, nếu không → `raise Exception` (submission fail, không có điểm).
3. `y_pred.get(k)` trả về `None` nếu **thiếu key** → `len(None)` gây `TypeError` → **crash toàn bộ bài nộp**. Vì vậy phải trả lời **đủ 100%** câu hỏi và **đúng key**.
4. So sánh bằng `set()` trên **chuỗi**; reference `y_true[k]` là **list ID dạng chuỗi**. ID số nguyên sẽ không khớp.
5. Không có ngưỡng thứ hạng (không phải MRR/nDCG) — thứ tự các ID trong danh sách **không ảnh hưởng** điểm.

---

## 4. Nộp bài

### 4.1. Định dạng file

Nộp **một tệp `submission.zip`** chứa **duy nhất** tệp `submission.json`:

```
submission.zip
└── submission.json
```

`submission.json` — JSON Object:
```json
{
  "147194": { "answer": ["177504", "740"] },
  "38096":  { "answer": ["112233"] }
}
```

### 4.2. Checklist trước khi nộp

- [ ] `submission.zip` chứa **đúng 1 file** tên `submission.json` (đặt ở gốc zip, không nằm trong thư mục con).
- [ ] Số lượng key = **1.000** (Public Test) và trùng khớp hoàn toàn với key của `public-official.json`.
- [ ] Mỗi key có object với trường `answer` là **list**.
- [ ] Mỗi list có **≥ 1 và ≤ 5** phần tử.
- [ ] Mọi `document_id` là **string**, không phải int.
- [ ] Không có ID trùng lặp trong cùng một list (trùng lặp làm giảm Precision vì `len(y_pred[k])` đếm cả bản sao, trong khi `set()` khử trùng).

### 4.3. Giới hạn lượt nộp

| Vòng | Giới hạn |
|---|---|
| Warm-up | Không giới hạn cụ thể (làm quen hệ thống) |
| **Public Test** | **10 bài/ngày** — leaderboard hiển thị kết quả **tốt nhất trong ngày** |
| **Private Test** | **03 bài/ngày** — kết quả cuối lấy từ phương pháp cho điểm **cao nhất** trên private test |

### 4.4. Ghi chú chiến lược về số lượng đáp án

Vì Recall là độ đo chính và Recall được chia cho `|T_i|` (không chia cho `|P_i|`):
- Trả về **5 ID** không bao giờ làm giảm Recall so với trả về ít hơn — chỉ làm giảm Precision.
- Với 92% câu hỏi chỉ có 1 đáp án đúng, trả 5 ID → Precision tối đa ≈ 0,2 cho các câu đó.
- Precision **chỉ được dùng khi Recall bằng nhau tuyệt đối** — xác suất rất thấp trên 1.000 câu.
- ⚠️ Tuyệt đối **không trả > 5 ID** (bị 0 cả hai độ đo) và **không bỏ trống** câu nào.

---

## 5. Quy định về mô hình (Điều 4 Thể lệ + email BTC)

### 5.1. Giới hạn tham số — 4 tỷ

- **Tổng số tham số của TOÀN BỘ hệ thống** phải **< 4 tỷ**.
- Giới hạn tính trên **tất cả thành phần** trong pipeline: mô hình sinh, mô hình **embedding**, **reranker**, cross-encoder, và **cả lớp embedding** của từng mô hình.
  → Ví dụ: bi-encoder 1B + reranker 2B + LLM 1.5B = 4,5B → **VI PHẠM**.
- Mô hình tạo bằng **distillation** vẫn hợp lệ nếu mô hình sau distill có tổng tham số < 4 tỷ.
- **LoRA / Quantization / GPTQ / AWQ / GGUF** **KHÔNG** làm thay đổi số lượng tham số.
  → Mô hình 7B quantize 4-bit vẫn là 7B → **VI PHẠM**, dù chạy nhẹ như model 2B.

### 5.2. Đăng ký mô hình — BẮT BUỘC

- Chỉ được dùng mô hình **đã đăng ký và được BTC phê duyệt**.
- Thời gian đăng ký: **06/08/2026 – 18/09/2026**; có thể gửi lại biểu mẫu nhiều lần để bổ sung.
- Biểu mẫu: https://forms.gle/HWE7tcxzWq63Kxv28
- Danh sách đã duyệt: https://docs.google.com/spreadsheets/d/1c5jzsYezWho1WGLRfMKWOaFPLIk_GTnXP5vV8AOWM2Q/edit
- Mô hình đã có trong danh sách duyệt thì **không cần đăng ký lại**.
- **Bài nộp dùng mô hình chưa đăng ký/chưa duyệt sẽ KHÔNG được công nhận.**
- Muốn bổ sung mô hình mới: gửi đề xuất **trước 10 ngày** so với hạn chót Private Test; BTC phản hồi trong **5 ngày làm việc**.

### 5.3. Cấm API và mô hình đóng

- **Cấm mọi API**, kể cả API **phi thương mại/miễn phí**, trong toàn bộ quá trình xây dựng và phát triển hệ thống.
- Cấm LLM **thương mại** hoặc **mã nguồn đóng**.
- Chỉ chấp nhận mô hình **mã nguồn mở** mà đội có thể **tải về, vận hành và kiểm soát trực tiếp**, không qua bên thứ ba.
- Mô hình có giấy phép **nghiên cứu/giáo dục/phi thương mại** được chấp nhận nếu đáp ứng các quy định khác.

---

## 6. Quy định về dữ liệu (Điều 4 & Điều 9)

- ✅ Chỉ được dùng **bộ dữ liệu chính thức do BTC phát hành**.
- ❌ **Cấm** gán nhãn thủ công.
- ❌ **Cấm** thu thập dữ liệu ngoài (crawl thêm văn bản pháp luật, dùng dataset công khai khác…).
- ❌ **Cấm** data augmentation từ **nguồn bên ngoài**.
- ✅ **Ngoại lệ được BTC làm rõ:** dữ liệu dùng để pretrain LLM/embedding model **không** bị xem là "dữ liệu từ nguồn khác". Dùng pretrained model là dùng mô hình ước lượng phân phối, không phải dùng trực tiếp ngữ liệu đó.
- ❌ Cấm dữ liệu chứa **thông tin cá nhân nhạy cảm chưa ẩn danh** (Luật Bảo vệ Dữ liệu Cá nhân 2023).
- 📄 Mỗi bài nộp phải kèm **"Data Statement"** và **"Model Card"**: nguồn gốc dữ liệu, quy trình tiền xử lý, phương pháp huấn luyện, chỉ số đánh giá, biện pháp giảm thiểu rủi ro.

---

## 7. Timeline

| Thời gian | Nội dung |
|---|---|
| 01/07 – 16/08/2026 | Đăng ký tham gia cuộc thi (khóa lúc **23h59 ngày 16/08/2026**) |
| 01/08 – 05/08/2026 | **Vòng khởi động (Warm-up)** |
| **06/08 – 18/09/2026** | **Vòng Public Test** |
| 06/08 – 18/09/2026 | Đăng ký mô hình pretrained với BTC |
| **19/09 – 23/09/2026** | **Vòng Private Test** |
| 24/09 – 24/10/2026 | Top 10 viết bài báo khoa học |
| 25/10 – 30/10/2026 | Phản biện bài báo |
| 13/11/2026 | Bế mạc cuộc thi |

---

## 8. Quy định tổ chức & tài khoản

### 8.1. Đăng ký đội
- Mỗi đội **01 – 05 thành viên**; nhóm trưởng điền biểu mẫu bằng **email sinh viên** do trường/viện cấp.
- Đối tượng: sinh viên các trường ĐH tại Việt Nam khu vực **Đông Nam Bộ và Tây Nam Bộ**.
- Một cá nhân **chỉ được ở một đội duy nhất**; trùng thành viên → **hủy tư cách tất cả đội liên quan**.
- Lệ phí **100.000 đ** (bao gồm cả 2 subtask), nộp trước **23h59 ngày 16/08/2026**.
- Sau khóa đăng ký, thay đổi tên đội/thành viên phải gửi `dsc@uit.edu.vn`, chỉ có hiệu lực khi BTC chấp thuận qua email; **tối đa 02 lần** và chỉ trước 16/08/2026.
- Lệ phí chỉ hoàn khi BTC hủy cuộc thi.
- Thành viên Ban Chỉ đạo/BTC/vận hành hệ thống chấm điểm **không đủ điều kiện dự thi**.
- BTC có quyền yêu cầu xuất trình giấy tờ tùy thân bất cứ lúc nào; khai sai → hủy tư cách, không hoàn lệ phí.

### 8.2. Codabench
- Nhóm trưởng đăng ký Codabench bằng **email đã khai báo**.
- Tạo **Organization** đúng **tên đội** đã đăng ký (khuyến khích kèm viết tắt tên trường, vd. `UIT-DataBoost`); không chứa nội dung phản cảm, kỳ thị.
- ⚠️ **Bắt buộc nộp bài bằng Organization đã đăng ký. Chỉ bài nộp qua Organization mới hợp lệ.**
- BTC chỉ duyệt **nhóm trưởng** join Codabench.
- ⚠️ Codabench Task 1 và Task 2 là **hai hệ thống độc lập** — tham gia cả hai task phải join riêng từng hệ thống.
- Email liên lạc chính thức gửi tới **email nhóm trưởng**; đội phải phản hồi trong **48 giờ** khi có yêu cầu.
- Gặp lỗi hệ thống → đăng bài trên **Forum của Codabench**.

---

## 9. Sau cuộc thi: mã nguồn, bài báo, sở hữu trí tuệ

### 9.1. Kiểm định & công khai mã nguồn (Điều 6)
- **Top 10** mỗi nội dung thi **phải gửi mã nguồn (giấy phép MIT)** để BTC tái lập kết quả trên Private Test.
- **Không cung cấp mã nguồn → hủy kết quả, thứ hạng và giải thưởng.**
- BTC có quyền yêu cầu **log huấn luyện, cấu hình môi trường**; phải cung cấp trong **48 giờ**.

### 9.2. Đóng gói & tái lập (làm rõ qua email)
- Không bắt buộc Docker. Chấp nhận: push code lên **GitHub**, nén mã nguồn/trọng số thành **zip** gửi BTC, hoặc hình thức khác.
- Yêu cầu duy nhất: **README/tài liệu trình bày chi tiết từng bước tái lập** để BTC chạy lại ra kết quả.
- **Được phép tải trọng số từ Internet** khi chạy, miễn là trọng số thuộc mô hình mã nguồn mở / phi thương mại / mục đích giáo dục–nghiên cứu.

### 9.3. Bài báo khoa học (Điều 7)
- **Top 10 mỗi subtask** được yêu cầu trình bày giải pháp thành **toàn văn bài báo khoa học** trong kỷ yếu DSC UIT 2026.
- Mỗi bài được **ít nhất 2 phản biện** đánh giá.
- Bài được chấp thuận có thể đăng kỷ yếu, dự kiến được mời viết trong **số đặc biệt tạp chí Phát triển Khoa học và Công nghệ – ĐHQG-HCM**.
- **Top 1, 2, 3 BẮT BUỘC** viết và nộp bài báo để kết quả được **công nhận chính thức**.

### 9.4. Sở hữu trí tuệ (Điều 10)
- Quyền SHTT đối với giải pháp **thuộc về đội thi**.
- Nộp bài = cấp cho UIT và đối tác quyền **không độc quyền, miễn phí bản quyền, không thời hạn** để trưng bày, đào tạo, truyền thông **phi thương mại**.
- Đội đạt giải cam kết **công bố mã nguồn theo giấy phép mã nguồn mở trong 30 ngày** kể từ ngày chung kết.
- Thư viện/dữ liệu/mô hình bên thứ ba phải **trích dẫn đầy đủ** và tuân thủ giấy phép gốc.

---

## 10. Chuẩn mực hành vi & khiếu nại

- Nghiêm cấm: **đạo văn, tấn công hệ thống, thao túng bình chọn, trao đổi dữ liệu/mã nguồn không công khai giữa các đội**.
- Cấm quấy rối, phân biệt đối xử về giới tính, dân tộc, tôn giáo, khuyết tật.
- **Mức xử lý:** (i) lần đầu — cảnh cáo hoặc **trừ tối đa 20% tổng điểm**; (ii) tái phạm — **loại ngay lập tức**.
- **Khiếu nại:** gửi `dsc@uit.edu.vn` trong **48 giờ** kể từ khi công bố kết quả từng vòng; BTC phản hồi tối đa **07 ngày làm việc**; quyết định của Ban Chỉ đạo là **cuối cùng**.
- Bất khả kháng: BTC có quyền điều chỉnh lịch/hình thức/hủy cuộc thi, thông báo trước tối thiểu **72 giờ**.

---

## 11. Giải thưởng

Tổng: **25.000.000 đ** (nguồn kinh phí nhà trường), cho **mỗi nội dung thi**:

| Giải | Tiền thưởng | Kèm theo |
|---|---|---|
| 01 Giải Nhất | 12.000.000 đ | Giấy khen Trường ĐH CNTT, ĐHQG-HCM |
| 01 Giải Nhì | 8.000.000 đ | Giấy khen Trường ĐH CNTT, ĐHQG-HCM |
| 01 Giải Ba | 5.000.000 đ | Giấy khen Trường ĐH CNTT, ĐHQG-HCM |

**Tiêu chí xếp giải:** kết quả trên **scoreboard** của hệ thống đánh giá + **quyết định cuối cùng của Hội đồng Ban Giám khảo** tại Vòng Chung kết.

---

## 12. Tóm tắt "phải nhớ"

| # | Điều |
|---|---|
| 1 | **Recall là độ đo chính**, Precision chỉ để phá hoà |
| 2 | **Tối đa 5 document_id / câu hỏi** — vượt quá ⇒ 0 điểm câu đó |
| 3 | Không được bỏ trống câu nào; **thiếu key ⇒ crash toàn bộ submission** |
| 4 | Số key submission phải **bằng đúng** số key reference |
| 5 | ID phải là **string** |
| 6 | Nộp `submission.zip` chứa duy nhất `submission.json` |
| 7 | Public Test **10 bài/ngày**, Private Test **3 bài/ngày** |
| 8 | Tổng tham số toàn hệ thống **< 4 tỷ** (embedding + reranker + LLM cộng lại) |
| 9 | **Quantization/LoRA KHÔNG giảm số tham số** |
| 10 | **Cấm mọi API**; chỉ mô hình open-source tự host |
| 11 | Mô hình phải được **đăng ký & phê duyệt** trước |
| 12 | Chỉ dùng dữ liệu BTC; cấm crawl thêm, cấm augment ngoài |
| 13 | Nộp bài qua đúng **Organization** trên Codabench |
| 14 | Top 10 nộp mã nguồn MIT + bài báo; Top 3 **bắt buộc** viết bài báo |

---

## Phụ lục: Liên kết quan trọng

| Mục | Link |
|---|---|
| Codabench Task 1 | https://www.codabench.org/competitions/17715/ |
| Codabench Task 2 | https://www.codabench.org/competitions/17716/ |
| Dữ liệu Public Test Task 1 | https://drive.google.com/drive/folders/1e4XctfiDz9TNPuxYtNJ3Uoaz0vQ9gB1t |
| Mã nguồn chấm điểm Task 1 | https://drive.google.com/file/d/12QTJfS_GlilTibz4k3jV1c8q8_BU0V36/view |
| Biểu mẫu đăng ký mô hình | https://forms.gle/HWE7tcxzWq63Kxv28 |
| Danh sách mô hình đã duyệt | https://docs.google.com/spreadsheets/d/1c5jzsYezWho1WGLRfMKWOaFPLIk_GTnXP5vV8AOWM2Q/edit |
| Email BTC | dsc@uit.edu.vn |
