# Proposal Task 2 - LegalQA

## 1. Mục tiêu tối ưu

METEOR là metric xếp hạng chính; ROUGE-L là metric phụ. Mã scorer hiện tại:

- METEOR tách token bằng `str.split()`; không dùng tokenizer tiếng Việt.
- ROUGE-L dùng `rouge_scorer` không stemming.
- So sánh raw answer string; key submission phải khớp đầy đủ tập question ID.

Do đó, câu trả lời phải bảo toàn token, cụm từ và thứ tự của căn cứ pháp lý. Câu trả lời ngắn, dù đúng ý, thường mất METEOR vì thiếu token recall.

## 2. Đặc điểm train

- 7.000 câu hỏi; không trùng ID với train Task 1.
- Độ dài answer: median 312 từ, p90 576, p95 692, tối đa 2.435 từ.
- 6.961/7.000 answer có nhiều dòng.
- 4.676 answer chứa `Căn cứ`; 6.007 chứa `như sau`; 4.458 có liệt kê đánh số; 3.098 có bullet.
- Corpus giống Task 1 hoàn toàn, nên retriever Task 1 là nền tảng evidence retrieval cho Task 2.
- Trích số hiệu văn bản tự động từ official answer tìm được candidate corpus cho 4.061/7.000 câu; 909 câu chỉ còn đúng một candidate. Đây là nguồn pseudo-label mạnh, không cần nhãn thủ công hay dữ liệu ngoài.

## 3. Kiến trúc đề xuất: evidence-first RAG cục bộ

### 3.1 Pseudo-link dữ liệu huấn luyện với corpus

Ưu tiên theo độ tin cậy:

1. Exact số hiệu văn bản trong answer/question -> candidate context.
2. Exact Điều/Khoản + số hiệu -> positive chunk.
3. Answer-to-chunk BM25/dense retrieval trong candidate document -> evidence span.
4. Với câu không có citation, dùng answer-aware retrieval trên official corpus để tạo silver evidence; chỉ nhận pseudo-label khi sparse và dense đồng thuận.

Pseudo-label phải được tạo hoàn toàn tự động từ dữ liệu BTC, lưu confidence và dùng weighting; không sửa nhãn bằng tay.

### 3.2 Retrieval khi inference

- Dùng pipeline Task 1 nhưng lấy top 20-50 document rồi rerank ở cấp Điều/Khoản.
- Chọn 3-8 evidence chunks có diversity, ưu tiên chuỗi Điều/Khoản/Điểm liên tiếp.
- Một tầng citation resolver kiểm tra số hiệu và quan hệ văn bản sửa đổi/bổ sung trong chính corpus.

### 3.3 Generator

- Decoder/seq2seq mã nguồn mở đã được BTC duyệt, cỡ khoảng 1.5-2.5B để tổng cả retriever/reranker dưới 4B.
- Fine-tune có giám sát trên 7.000 QA với evidence silver; curriculum từ evidence confidence cao đến thấp.
- Context packing theo citation và thứ tự pháp lý, không nhét nguyên document.
- Loss gồm token cross-entropy + tăng trọng số cho số hiệu, Điều/Khoản, con số, mức phạt, thời hạn và câu kết luận.
- Dùng copy-oriented decoding để giữ nguyên điều khoản và số liệu; generator chủ yếu nối, diễn giải và kết luận.

Khung answer nên học từ dữ liệu, thường là:

```text
Căn cứ [Điều/Khoản và văn bản] quy định như sau:
[trích các khoản liên quan theo đúng thứ tự]
Theo đó, [kết luận trực tiếp cho câu hỏi].
[biện pháp bổ sung/ngoại lệ nếu có].
```

Không ép template khi evidence không hỗ trợ; citation sai gây mất đồng thời độ đúng và overlap.

### 3.4 Metric-aware decoding

- Sinh 3-5 candidate bằng beam/diverse beam với length range học theo loại câu hỏi.
- Rerank candidate bằng mô hình cục bộ dự đoán OOF METEOR, kết hợp evidence coverage, citation consistency, numeric consistency và repetition penalty.
- Tối ưu độ dài theo bucket câu hỏi; tránh câu quá ngắn, nhưng cũng không copy hàng nghìn từ vì precision token sẽ giảm.
- Giữ cụm pháp lý và thứ tự điều khoản; chuẩn hóa whitespace cuối cùng nhưng không thay đổi punctuation/số hiệu tùy tiện.

## 4. Validation

5-fold OOF, đồng thời group theo citation/document silver để giảm leakage. Mỗi fold phải chạy đúng scorer BTC, bao gồm đúng version NLTK/ROUGE và resource WordNet.

Báo cáo:

- METEOR chính thức và ROUGE-L F.
- Theo answer-length bucket, có/không citation, single/multi-document và pseudo-label confidence.
- Citation exact match, number consistency, unsupported-claim rate bằng rule-based checker.
- Retrieval recall của silver evidence để tách lỗi retrieval khỏi lỗi generation.

## 5. Ma trận thí nghiệm

| ID | Thí nghiệm | Kỳ vọng |
|---|---|---|
| QA-00 | Nearest-neighbor answer theo question | Baseline cực rẻ |
| QA-01 | Retriever + extractive top clauses | Baseline grounded |
| QA-02 | Generator chỉ question | Đo giá trị pretrained/fine-tune |
| QA-03 | Generator + silver evidence | Tăng factuality và overlap |
| QA-04 | Citation/number weighted loss | Giảm lỗi căn cứ, con số |
| QA-05 | Candidate generation + metric reranker | Tăng METEOR trực tiếp |
| QA-06 | Shared retriever distillation từ Task 1 | Tăng evidence recall |
| QA-07 | 2-seed ensemble/rerank trong <4B | Giảm variance |

## 6. Submission và tái lập

- Submission phải có đúng toàn bộ ID, mỗi `answer` là string UTF-8, không có `None`.
- Kiểm tra JSON/ZIP bằng chính scorer trong container sạch trước khi submit.
- Lưu model/config/tokenizer hash, seed, retrieval index version và output hash.
- Không dùng API hay dữ liệu ngoài; chỉ mô hình đã đăng ký/phê duyệt.
- Chuẩn bị Docker/README offline, Data Statement, Model Card và ablation table cho bài báo.

