# UIT Data Science Challenge 2026 — Task 2: LegalQA
## Trả lời câu hỏi pháp luật tiếng Việt (Legal Question Answering)

> Tài liệu này tóm tắt **đầy đủ** yêu cầu của Task 2, tổng hợp từ: Thể lệ cuộc thi (PDF),
> `DSC2026_Task2_LegalQA_Data_Overview.docx`, email "Khởi động Task 2 – LegalQA",
> email "Dữ liệu Vòng Public Test – Task 2", email "Cập nhật QUAN TRỌNG về độ đo đánh giá",
> email "Đăng ký Mô hình", và mã nguồn chấm điểm `Scoring-Program-Task-LegalQA/scoring.py`.
>
> Khi có mâu thuẫn giữa các nguồn, **email cập nhật mới nhất + mã nguồn chấm điểm** là căn cứ cuối cùng.

---

## 1. Tổng quan bài toán

| Mục | Nội dung |
|---|---|
| **Tên** | Task 2 – Legal Question Answering (LegalQA) |
| **Mục tiêu** | Với một câu hỏi pháp luật, hệ thống **truy xuất văn bản liên quan** và **tạo câu trả lời bằng văn xuôi** dựa trên căn cứ pháp lý |
| **Input** | Một câu hỏi pháp luật tiếng Việt |
| **Output** | Câu trả lời tự nhiên bằng **văn xuôi** (free-form text) |
| **Loại bài toán** | RAG — Retrieval + Generation (sinh văn bản, không phải chọn ID) |
| **Codabench** | https://www.codabench.org/competitions/17716/ (**độc lập** với Codabench Task 1) |

### Bối cảnh (theo thể lệ)
Cuộc thi hướng đến phát triển hệ thống có khả năng **hiểu, truy xuất và sinh câu trả lời chính xác** cho
câu hỏi về văn bản pháp luật tiếng Việt. Các đội xây dựng phương pháp NLP hiện đại dựa trên LLM, kết hợp
kỹ thuật **truy hồi thông tin, tinh chỉnh mô hình và đánh giá độ tin cậy** của câu trả lời. Hệ thống không
chỉ cần trả lời đúng mà còn phải đảm bảo **tính minh bạch, khả năng giải thích và trích dẫn căn cứ pháp lý phù hợp**.

### Ví dụ mẫu
```json
"id": {
  "question": "Trách nhiệm của tổ chức đấu thầu, bảo lãnh, đại lý phát hành",
  "answer": "Theo Điều 37 Nghị định 153/2020/NĐ-CP, được sửa đổi bởi khoản 26 Điều 1 Nghị định 65/2022/NĐ-CP (Có hiệu lực từ 16/09/2022) quy định cụ thể:\n- Tuân thủ quy định của pháp luật chứng khoán và quy định tại Điều 14 Nghị định này khi cung cấp dịch vụ đấu thầu, bảo lãnh, đại lý phát hành.\n- Thực hiện chế độ báo cáo theo quy định tại Nghị định này.\n- Trường hợp vi phạm quy định của pháp luật khi cung cấp dịch vụ tùy theo tính chất và mức độ vi phạm sẽ bị xử phạt vi phạm hành chính ... hoặc truy cứu trách nhiệm hình sự\nTrước đây, căn cứ Điều 37 Nghị định 153/2020/NĐ-CP quy định như sau: ..."
}
```

> 📌 **Quan sát then chốt về văn phong đáp án tham chiếu:** đáp án gold **không** phải câu trả lời ngắn gọn.
> Nó theo văn phong thuvienphapluat.vn: mở đầu bằng `"Theo Điều X ... quy định ..."`, **trích nguyên văn**
> điều khoản, và thường có phần `"Trước đây, căn cứ ... quy định như sau:"` liệt kê phiên bản cũ.
> Vì METEOR/ROUGE-L là độ đo **so khớp bề mặt token**, việc mô phỏng đúng văn phong + trích nguyên văn
> điều khoản có ảnh hưởng rất lớn tới điểm.

---

## 2. Dữ liệu

### 2.1. Các tệp dữ liệu (cấp theo timeline)

| Tệp | Nội dung |
|---|---|
| `train.json` | Tập huấn luyện cho các đội phát triển phương pháp |
| `warmup.json` | Tập mẫu vòng Warm-up (làm quen bài toán + quy trình submission) |
| `public-official.json` | Tập dùng trong giai đoạn **Public Test** (email BTC gọi là `public_test.json`) |
| `private-official.json` | Tập chính thức của **Private Test** |
| `selected-contexts.zip` | Corpus văn bản pháp luật phục vụ truy xuất; gồm nhiều tệp `context_*.json` |

**Link dữ liệu Public Test (BTC cung cấp):**
https://drive.google.com/drive/folders/1DLV97_w3obLrxRdWRXmuv38CQHaBUxgk?usp=sharing

**Link tài nguyên Warm-up:**
https://drive.google.com/drive/folders/10KMKmFchncbqpxTjievbJrtzgYtFempp?usp=sharing

> Cấu trúc dữ liệu Public Test và Private Test **tương tự** dữ liệu Warm-up; chỉ nội dung và tập đánh giá khác nhau.

### 2.2. Định dạng tệp câu hỏi

`train.json` — JSON Object, key là `id` của câu hỏi:
```json
{
  "<id>": {
    "question": "Trách nhiệm của tổ chức đấu thầu, bảo lãnh, đại lý phát hành",
    "answer": "Theo Điều 37 Nghị định 153/2020/NĐ-CP, ..."
  }
}
```

`public-official.json` — cùng cấu trúc nhưng `answer` là `null` (cần sinh ra):
```json
{
  "<id>": {
    "question": "Mẫu thông báo thay đổi người đại diện theo pháp luật",
    "answer": null
  }
}
```

### 2.3. Định dạng một văn bản trong corpus (`context_*.json`)

| Trường | Ý nghĩa |
|---|---|
| `id` | Mã định danh duy nhất của văn bản |
| `name` | Tiêu đề văn bản |
| `link` | Đường dẫn nguồn (thuvienphapluat.vn) |
| `passage` | Nội dung văn bản dùng làm **ngữ cảnh / căn cứ** |

```json
{
  "link": "https://thuvienphapluat.vn/van-ban/Bo-may-hanh-chinh/Quyet-dinh-5868-QD-BYT-2018-...aspx",
  "name": "Quyet-dinh-5868-QD-BYT-2018-co-cau-to-chuc-cua-Vu-Trang-thiet-bi-va-Cong-trinh-y-te-396608",
  "passage": "BỘ Y TẾ\n-------\nCỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\n... QUYẾT ĐỊNH ...",
  "id": 740
}
```

> ⚠️ Task 2 **không cung cấp nhãn văn bản đúng** cho từng câu hỏi. Corpus chỉ là kho ngữ cảnh —
> phần retrieval là **không giám sát**, các đội tự thiết kế.

### 2.4. Thống kê thực tế của bộ dữ liệu Public Test (đã tải về)

| Chỉ số | Giá trị |
|---|---|
| Số câu hỏi `train.json` | **7.000** |
| Số câu hỏi `public-official.json` | **1.000** |
| Số văn bản trong corpus (`context_*.json`) | **8.532** |
| Độ dài câu hỏi trung bình | **~88 ký tự** (rất ngắn, nhiều câu là cụm danh từ, không có dấu `?`) |
| Độ dài đáp án trung bình | **~1.576 ký tự** |
| Đáp án ngắn nhất / dài nhất | **129 / 10.755 ký tự** |

**Hệ quả chiến lược:**
- Đáp án gold **rất dài** (trung bình ~1.5k ký tự ≈ 400–500 token). Câu trả lời quá ngắn sẽ bị METEOR/ROUGE-L phạt nặng ở thành phần Recall.
- Câu hỏi rất ngắn và nhiều câu ở dạng **tiêu đề điều luật** (vd. `"Mẫu thông báo thay đổi người đại diện theo pháp luật"`) → truy hồi lexical (BM25) trên tiêu đề/điều khoản có thể rất mạnh.
- Cần **kiểm soát độ dài sinh ra** (`max_new_tokens`) cho phù hợp phân phối độ dài gold.

---

## 3. Độ đo đánh giá

Câu trả lời do hệ thống sinh ra được so sánh với **câu trả lời tham chiếu do chuyên gia pháp lý xây dựng**.

| Độ đo | Vai trò | Mô tả |
|---|---|---|
| **METEOR** | **Độ đo CHÍNH** (xếp hạng) | Đánh giá tương đồng dựa trên mức khớp token, kết hợp Precision, Recall và mức độ liên tục/thứ tự của token khớp |
| **ROUGE-L** | Độ đo phụ (tham khảo) | Đánh giá tương đồng dựa trên **Longest Common Subsequence (LCS)**, phản ánh mức bảo toàn nội dung và thứ tự thông tin |

**Quy tắc xếp hạng:** METEOR là độ đo chính để xếp hạng các đội; ROUGE-L là độ đo phụ dùng để tham khảo và
đánh giá bổ sung chất lượng câu trả lời. Giá trị càng cao càng tốt (thang [0, 1]).

### 3.1. Mã nguồn chấm điểm chính thức

BTC công khai tại: https://drive.google.com/file/d/1HS5SqEZIoWiOqzNwtUdzvAnug8zNdXsJ/view?usp=sharing
(bản local: `Task 2/Scoring-Program-Task-LegalQA/scoring.py`)

```python
from nltk.translate.meteor_score import meteor_score
from rouge_score import rouge_scorer

rouge_scoring = rouge_scorer.RougeScorer(['rougeL'], use_stemmer=False)

def build_in_tokenizer(string_sent):
    # Dung pyvi cho tokenizer
    # return ViTokenizer.tokenize(str(string_sent))
    # Khong dung Tokenizer
    return string_sent

y_pred = {k: v['answer'] for k, v in y_pred.items()}

rouge_result = np.array([
    rouge_scoring.score(str(y_true[k]), str(y_pred[k]))['rougeL'].fmeasure
    for k in ids_preds]).mean()

meteor_result = np.array([
    meteor_score([str(y_true[k]).split()], str(y_pred[k]).split())
    for k in ids_preds]).mean()

return {'rouge': rouge_result, 'meteor': meteor_result}
```

**Những điều rút ra từ mã nguồn (rất quan trọng):**

1. **KHÔNG dùng tokenizer tiếng Việt.** Dòng `ViTokenizer` (pyvi) đã bị **comment out**. Tokenizer thực tế:
   - **METEOR**: tách bằng `.split()` — **tách theo khoảng trắng thuần**. Dấu câu dính liền từ (`"pháp,"` ≠ `"pháp"`) → **dấu câu ảnh hưởng trực tiếp tới điểm**.
   - **ROUGE-L**: dùng tokenizer mặc định của `rouge_score`, tức là **lowercase + loại ký tự không phải `[a-z0-9]`**. Với tiếng Việt có dấu, ký tự Unicode có dấu **bị loại bỏ**, làm ROUGE-L trên tiếng Việt méo mó nghiêm trọng → ROUGE-L chỉ có giá trị tham khảo, đúng như BTC nói.
   - ⇒ **Tối ưu cho METEOR**, không tối ưu cho ROUGE-L.
2. `meteor_score` dùng **WordNet** (`nltk.download('wordnet')`, `omw-1.4`) cho stage synonym-matching. WordNet tiếng Anh gần như không khớp từ tiếng Việt → METEOR ở đây chủ yếu là **exact match trên token phân tách theo khoảng trắng**, cộng với phạt fragmentation (thứ tự/độ liên tục).
3. METEOR có trọng số nghiêng về **Recall** (công thức chuẩn: `Fmean = P·R / (α·P + (1-α)·R)` với α = 0.9, tức Recall chiếm ưu thế). → **Trả lời dài, phủ nhiều nội dung gold** thường có lợi.
4. `y_pred` đọc dưới dạng `{k: v['answer']}` → submission **bắt buộc** có trường `answer`.
5. **Số lượng key trong submission phải bằng đúng số key trong reference**, nếu không → `raise Exception` (submission fail).
6. Vòng lặp duyệt theo `ids_preds` và truy cập `y_true[k]`/`y_pred[k]` trực tiếp → **key sai/thiếu ⇒ KeyError ⇒ crash toàn bộ bài nộp**. Key phải trùng **chính xác** với reference.
7. `str(...)` được áp lên giá trị → nếu trả `null`, chuỗi `"None"` sẽ được đem đi so khớp (điểm ≈ 0), không crash — nhưng **tuyệt đối tránh**.

---

## 4. Nộp bài

### 4.1. Định dạng file

Theo cùng quy ước với Task 1 và theo mã nguồn chấm điểm: nộp **`submission.zip`** chứa **duy nhất**
tệp **`submission.json`**. Định dạng submission **không thay đổi so với Vòng Warm-up**.

```
submission.zip
└── submission.json
```

`submission.json` — JSON Object, key là `id` câu hỏi, giá trị là object có trường `answer` **kiểu string**:
```json
{
  "12345": { "answer": "Theo Điều 37 Nghị định 153/2020/NĐ-CP quy định cụ thể: ..." },
  "67890": { "answer": "Căn cứ khoản 2 Điều 5 Thông tư ... như sau: ..." }
}
```

> ⚠️ Khác biệt so với Task 1: `answer` ở Task 2 là **một chuỗi văn xuôi**, không phải list ID.

### 4.2. Checklist trước khi nộp

- [ ] `submission.zip` chứa **đúng 1 file** tên `submission.json` (ở gốc zip, không nằm trong thư mục con).
- [ ] Số lượng key = **1.000** (Public Test) và trùng khớp hoàn toàn với key của `public-official.json`.
- [ ] Mỗi key có object với trường `answer` là **string không rỗng**, không `null`.
- [ ] Không bỏ trống câu nào (key thiếu ⇒ crash toàn bộ submission).
- [ ] Đảm bảo JSON escape đúng ký tự `\n` trong câu trả lời.
- [ ] Encoding **UTF-8**.

### 4.3. Giới hạn lượt nộp

| Vòng | Giới hạn |
|---|---|
| Warm-up | Không giới hạn cụ thể (làm quen hệ thống) |
| **Public Test** | **10 bài/ngày** — leaderboard hiển thị kết quả **tốt nhất trong ngày** |
| **Private Test** | **03 bài/ngày** — kết quả cuối lấy từ phương pháp cho điểm **cao nhất** trên private test |

### 4.4. Ghi chú chiến lược về sinh câu trả lời

Vì METEOR ở cấu hình này chủ yếu là so khớp token theo khoảng trắng và thiên về Recall:
- **Bám sát văn phong đáp án gold**: mở đầu `"Theo Điều X ... quy định ..."`, trích nguyên văn điều khoản, giữ định dạng gạch đầu dòng `- ` và đánh số `1. 2. 3.`.
- **Trích nguyên văn passage** từ văn bản truy hồi được thường ăn điểm cao hơn diễn giải lại bằng lời của mô hình.
- **Kiểm soát độ dài**: quá ngắn → mất Recall; quá dài → mất Precision và tăng phạt fragmentation. Nên hiệu chỉnh theo phân phối độ dài gold (~1.5k ký tự).
- **Dấu câu quan trọng** với METEOR (`.split()` không tách dấu câu) — giữ dấu câu giống văn phong gold.
- Cân nhắc **baseline retrieval-only**: trả về trực tiếp đoạn văn bản pháp lý liên quan nhất, đã cho điểm khá tốt ở dạng bài này; dùng làm mốc so sánh trước khi thêm bước sinh.

---

## 5. Quy định về mô hình (Điều 4 Thể lệ + email BTC)

### 5.1. Giới hạn tham số — 4 tỷ

- **Tổng số tham số của TOÀN BỘ hệ thống** phải **< 4 tỷ**.
- Giới hạn tính trên **tất cả thành phần** trong pipeline: **mô hình sinh (generator), mô hình embedding, reranker** và mọi mô hình khác — bao gồm **cả lớp embedding** của từng mô hình.
  → Ví dụ RAG: embedding 0.3B + reranker 0.5B + generator 3B = 3.8B → **hợp lệ**; nếu generator 4B → **vi phạm**.
- Mô hình tạo bằng **distillation** vẫn hợp lệ nếu mô hình sau distill có tổng tham số < 4 tỷ.
- **LoRA / Quantization / GPTQ / AWQ / GGUF** **KHÔNG** làm thay đổi số lượng tham số.
  → Mô hình 7B quantize 4-bit vẫn là 7B → **VI PHẠM**, dù chạy nhẹ như model 2B.
  Lý do BTC nêu: dùng mô hình > 4 tỷ đồng nghĩa dùng nhiều thông tin pretrained hơn → **bất công bằng**.

### 5.2. Đăng ký mô hình — BẮT BUỘC

- Chỉ được dùng mô hình **đã đăng ký và được BTC phê duyệt**.
- Thời gian đăng ký: **06/08/2026 – 18/09/2026**; có thể gửi lại biểu mẫu nhiều lần để bổ sung/cập nhật.
- Biểu mẫu: https://forms.gle/HWE7tcxzWq63Kxv28
- Danh sách đã duyệt: https://docs.google.com/spreadsheets/d/1c5jzsYezWho1WGLRfMKWOaFPLIk_GTnXP5vV8AOWM2Q/edit
- Mô hình đã có trong danh sách duyệt thì **không cần đăng ký lại**.
- **Bài nộp dùng mô hình chưa đăng ký/chưa duyệt sẽ KHÔNG được công nhận.**
- Muốn bổ sung mô hình mới: gửi đề xuất **trước 10 ngày** so với hạn chót Private Test; BTC phản hồi trong **5 ngày làm việc**.

### 5.3. Cấm API và mô hình đóng

- **Cấm mọi API**, kể cả API **phi thương mại/miễn phí**, trong toàn bộ quá trình xây dựng và phát triển hệ thống.
- Cấm LLM **thương mại** hoặc **mã nguồn đóng**.
- BTC chỉ chấp nhận mô hình/hệ thống **mã nguồn mở** mà đội "có thể cầm được, nắm được, kiểm soát được" — tải về, vận hành trực tiếp, **không thông qua bên trung gian**.
- Mô hình có giấy phép **nghiên cứu/giáo dục/phi thương mại** được chấp nhận nếu đáp ứng các quy định khác.

---

## 6. Quy định về dữ liệu (Điều 4 & Điều 9)

- ✅ Chỉ được dùng **bộ dữ liệu chính thức do BTC phát hành**.
- ❌ **Cấm** gán nhãn thủ công.
- ❌ **Cấm** thu thập dữ liệu ngoài (crawl thêm thuvienphapluat, dùng dataset LegalQA công khai khác…).
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
| **06/11/2026** | **Hội thảo khoa học** trình bày kết quả các nhóm dự thi *(chỉ nêu ở Nội dung 2)* |
| 13/11/2026 | Bế mạc cuộc thi |

---

## 8. Quy định tổ chức & tài khoản

### 8.1. Đăng ký đội
- Mỗi đội **01 – 05 thành viên**; nhóm trưởng điền biểu mẫu bằng **email sinh viên** do trường/viện cấp.
- Đối tượng: sinh viên các trường ĐH tại Việt Nam khu vực **Đông Nam Bộ và Tây Nam Bộ**.
- Một cá nhân **chỉ được ở một đội duy nhất**; trùng thành viên → **hủy tư cách tất cả đội liên quan**.
- Lệ phí **100.000 đ** (bao gồm cả 02 subtask), nộp trước **23h59 ngày 16/08/2026**.
- Sau khóa đăng ký, thay đổi tên đội/thành viên phải gửi `dsc@uit.edu.vn`, chỉ có hiệu lực khi BTC chấp thuận qua email; **tối đa 02 lần** và chỉ trước 16/08/2026.
- Lệ phí chỉ hoàn khi BTC hủy cuộc thi.
- Thành viên Ban Chỉ đạo/BTC/vận hành hệ thống chấm điểm **không đủ điều kiện dự thi**.
- BTC có quyền yêu cầu xuất trình giấy tờ tùy thân bất cứ lúc nào; khai sai → hủy tư cách, không hoàn lệ phí.

### 8.2. Codabench — Task 2
- Nhóm trưởng **đăng ký tài khoản Codabench bằng email sinh viên đã dùng khi đăng ký cuộc thi**.
- **Tạo Organization đúng tên đội** đã đăng ký với BTC (khuyến khích kèm viết tắt tên trường, vd. `UIT-DataBoost`); không chứa nội dung phản cảm, kỳ thị.
- Gửi yêu cầu tham gia tại: **https://www.codabench.org/competitions/17716/**
- BTC chỉ duyệt **đại diện nhóm trưởng** join vào Codabench.
- ⚠️ **Codabench Task 1 và Task 2 là hai hệ thống hoàn toàn độc lập** — tham gia cả hai task phải join riêng từng hệ thống.
- ⚠️ **Bắt buộc nộp bài bằng Organization đã đăng ký. Chỉ bài nộp qua đúng Organization mới hợp lệ.**
- Email liên lạc chính thức gửi tới **email nhóm trưởng**; đội phải phản hồi trong **48 giờ** khi có yêu cầu.
- Gặp lỗi hệ thống → đăng bài trên **Forum của Codabench**; thắc mắc khác reply trực tiếp email BTC.

---

## 9. Sau cuộc thi: mã nguồn, bài báo, sở hữu trí tuệ

### 9.1. Kiểm định & công khai mã nguồn (Điều 6)
- **Top 10** mỗi nội dung thi **phải gửi mã nguồn (giấy phép MIT)** để BTC tái lập kết quả trên Private Test.
- **Không cung cấp mã nguồn → hủy kết quả, thứ hạng và giải thưởng.**
- Top 10 phải trình bày phương pháp trong **Hội thảo khoa học** của cuộc thi.
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
| 1 | **METEOR là độ đo chính**, ROUGE-L chỉ tham khảo/bổ sung |
| 2 | Scorer **KHÔNG dùng pyvi** — METEOR tách token bằng `.split()` thuần khoảng trắng |
| 3 | ROUGE-L dùng tokenizer mặc định `rouge_score` → **loại ký tự tiếng Việt có dấu**, kém tin cậy |
| 4 | Đáp án gold **rất dài** (~1.5k ký tự) và theo văn phong trích nguyên văn điều luật |
| 5 | METEOR thiên về **Recall** → trả lời đủ dài, phủ nội dung gold |
| 6 | `answer` là **string văn xuôi**, không phải list ID |
| 7 | Không bỏ trống câu nào; **thiếu key ⇒ crash toàn bộ submission** |
| 8 | Số key submission phải **bằng đúng** số key reference |
| 9 | Nộp `submission.zip` chứa duy nhất `submission.json` |
| 10 | Public Test **10 bài/ngày**, Private Test **3 bài/ngày** |
| 11 | Tổng tham số toàn hệ thống **< 4 tỷ** (embedding + reranker + generator cộng lại) |
| 12 | **Quantization/LoRA KHÔNG giảm số tham số** |
| 13 | **Cấm mọi API**; chỉ mô hình open-source tự host |
| 14 | Mô hình phải được **đăng ký & phê duyệt** trước |
| 15 | Chỉ dùng dữ liệu BTC; cấm crawl thêm, cấm augment ngoài |
| 16 | Codabench Task 2 **độc lập** với Task 1; nộp qua đúng **Organization** |
| 17 | Top 10 nộp mã nguồn MIT + bài báo; Top 3 **bắt buộc** viết bài báo |

---

## Phụ lục: Liên kết quan trọng

| Mục | Link |
|---|---|
| Codabench Task 2 | https://www.codabench.org/competitions/17716/ |
| Codabench Task 1 | https://www.codabench.org/competitions/17715/ |
| Dữ liệu Public Test Task 2 | https://drive.google.com/drive/folders/1DLV97_w3obLrxRdWRXmuv38CQHaBUxgk |
| Tài nguyên Warm-up Task 2 | https://drive.google.com/drive/folders/10KMKmFchncbqpxTjievbJrtzgYtFempp |
| Mã nguồn chấm điểm Task 2 | https://drive.google.com/file/d/1HS5SqEZIoWiOqzNwtUdzvAnug8zNdXsJ/view |
| Biểu mẫu đăng ký mô hình | https://forms.gle/HWE7tcxzWq63Kxv28 |
| Danh sách mô hình đã duyệt | https://docs.google.com/spreadsheets/d/1c5jzsYezWho1WGLRfMKWOaFPLIk_GTnXP5vV8AOWM2Q/edit |
| Email BTC | dsc@uit.edu.vn |
