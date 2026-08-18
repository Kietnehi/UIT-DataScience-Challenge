# Proposal Task 1 - LegalIR

## 1. Mục tiêu tối ưu

Scorer tính macro Recall và macro Precision theo từng câu hỏi. Recall là metric xếp hạng chính; Precision chỉ phá hòa. Mỗi câu hỏi có hơn 5 dự đoán bị tính 0 ở chính câu hỏi đó theo mã scorer.

Quy tắc xuất kết quả:

- Đúng đủ 1.000 question ID của public/private input.
- `answer` phải là list document ID dạng string.
- Không rỗng, không trùng ID, không quá 5 ID.
- Mặc định xuất top-5 duy nhất. Chỉ xuất ít hơn khi hệ thống có bằng chứng rất mạnh rằng toàn bộ gold đã được bao phủ, vì Recall là ưu tiên tuyệt đối.

## 2. Đặc điểm dữ liệu quyết định thiết kế

- Train: 7.000 câu; số gold document trung bình 1,09.
- Phân bố số gold: 6.447 câu có 1 document; 485 có 2; 53 có 3; 14 có 4; 1 có 5.
- Tổng 7.637 liên kết question-document, tương ứng 3.105 document gold duy nhất.
- Có document xuất hiện tới 109 lần; document popularity là feature hữu ích nhưng chỉ nên dùng như prior nhỏ.
- Corpus: 8.532 document; median 4.813 từ, p90 18.406 từ, có outlier hơn 1,24 triệu từ.
- 20 passage rỗng; 1.125 tệp thiếu `name`.

## 3. Kiến trúc đề xuất

### 3.1 Tiền xử lý pháp lý

1. Đọc JSON UTF-8; chuẩn hóa Unicode NFC, CRLF/newline và khoảng trắng nhưng giữ nguyên số hiệu, dấu `/`, `-`, `%`, đơn vị tiền và cấu trúc liệt kê.
2. Trích metadata từ `link`: loại văn bản, số hiệu, năm, cơ quan/lĩnh vực từ slug khi `name` thiếu.
3. Chia passage theo thứ tự: tiêu đề văn bản -> Chương/Mục -> Điều -> Khoản -> Điểm. Với đoạn không có cấu trúc, dùng cửa sổ 250-450 token, overlap 60-100 token.
4. Mỗi chunk luôn mang `document_id`, tiêu đề suy ra, số Điều/Khoản và vị trí trong văn bản.
5. Loại bỏ chunk rỗng/gần trùng trong nội bộ document, nhưng không xóa document ID.

### 3.2 Candidate generation đa kênh

- BM25 word n-gram trên text đã chuẩn hóa.
- BM25/TF-IDF character n-gram để chịu lỗi chính tả, viết tắt và số hiệu văn bản.
- Exact legal-reference channel cho chuỗi như `90/2017/NĐ-CP`, `Điều 17`, tiền/phần trăm/ngày tháng.
- Dense bi-encoder fine-tune bằng 7.637 positive pairs.
- Hợp nhất bằng Reciprocal Rank Fusion; lấy khoảng 80-150 document candidates.

Không encode nguyên document. Dense index đặt ở cấp chunk; điểm document là max hoặc top-k softmax pooling trên các chunk.

### 3.3 Huấn luyện retriever

- Positive chunk ban đầu: chunk BM25 tốt nhất bên trong gold document.
- Sau warm-up, dùng multiple-instance learning: document là positive nếu bất kỳ chunk nào phù hợp.
- In-batch negatives + hard negatives từ top BM25/dense nhưng không thuộc gold.
- Tăng tỷ trọng hard negative cùng số hiệu gần giống, cùng lĩnh vực, cùng tên Điều nhưng khác văn bản.
- Distill điểm của reranker về retriever để cải thiện Recall@100 mà không tăng tham số khi inference.

### 3.4 Reranker và gom điểm document

- Cross-encoder chấm `(question, title + article chunk)` cho top 80-150 document.
- Mỗi document chỉ rerank 2-4 chunk tốt nhất để kiểm soát chi phí.
- Document score gồm: reranker, dense, BM25 word, char, exact-reference, title match và popularity prior nhỏ.
- Học linear/GBDT calibrator trên out-of-fold predictions; objective ưu tiên Recall@5.
- Có diversity penalty nhẹ để tránh top-5 đều là các phiên bản gần trùng của cùng một văn bản khi câu hỏi có khả năng multi-document.

## 4. Validation đúng với leaderboard

Thiết lập hai lớp validation:

1. 5-fold query split để so sánh nhanh và tạo OOF score.
2. Document-disjoint stress split hoặc split theo connected components của đồ thị question-document để đo khả năng tổng quát hóa.

Luôn chạy nguyên bản `scoring.py` của BTC và báo cáo:

- Macro Recall chính thức.
- Macro Precision chính thức.
- Recall@1/3/5, hit-rate@5.
- Recall theo số gold document, độ dài câu hỏi, độ dài document và nhóm có/không có số hiệu pháp lý.

## 5. Ma trận thí nghiệm

| ID | Thí nghiệm | Kỳ vọng |
|---|---|---|
| IR-00 | BM25 word, document-level | Baseline tái lập |
| IR-01 | Chunk theo Điều/Khoản + BM25 | Tăng recall trên văn bản dài |
| IR-02 | Word + char + exact-reference RRF | Tăng robustness và bắt số hiệu |
| IR-03 | Dense bi-encoder | Tăng semantic recall |
| IR-04 | Hard-negative mining vòng 1 | Giảm nhầm văn bản gần nghĩa |
| IR-05 | Cross-encoder reranker | Tăng chất lượng top-5 |
| IR-06 | Score calibration + doc pooling | Tối ưu trực tiếp Recall@5 |
| IR-07 | 2-seed/model fusion trong ngân sách <4B | Giảm variance |

Chỉ đưa một thay đổi chính vào mỗi submission public; lưu hash model/config/submission và điểm để tránh overfit leaderboard.

## 6. Acceptance criteria

- Local submission validator bắt mọi lỗi key, kiểu dữ liệu, ID trùng, ID ngoài corpus và list >5.
- Kết quả deterministic với seed cố định.
- Không có data ngoài/API/manual labeling.
- Tổng tham số được tính và ghi rõ cho từng thành phần, dưới 4B.
- Có Docker/lockfile, README chạy offline, log và model card.

