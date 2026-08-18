# Review tổng quan UIT Data Science Challenge 2026

## Phạm vi

- Đã đọc thể lệ PDF, các thông báo/overview DOCX, hai bộ train/public, toàn bộ 8.532 context JSON và hai scoring program.
- `Task 1/Code` được loại trừ tuyệt đối; không có file nào trong thư mục này được mở, tìm kiếm hay phân tích.
- Không sử dụng dữ liệu ngoài để tạo đề xuất.

## Kết luận điều hành

1. Task 1 phải tối ưu Recall trước, Precision chỉ dùng phá hòa. Với scorer hiện tại, mỗi câu hỏi nên trả về tối đa 5 document ID duy nhất; chiến lược mặc định hợp lý là top-5 vì thêm ứng viên không thể làm Recall giảm.
2. Task 2 phải tối ưu METEOR trước, ROUGE-L là phụ. Scorer không dùng tokenizer tiếng Việt cho METEOR mà tách bằng whitespace; câu trả lời quá ngắn sẽ mất nhiều điểm recall token.
3. Hai task dùng cùng corpus 8.532 văn bản, giống nhau byte-for-byte. Nên xây một nền tảng retrieval dùng chung rồi chuyên biệt hóa đầu ra cho từng task.
4. Corpus có văn bản rất dài: median khoảng 4.813 từ, p90 khoảng 18.406 từ, cực đại hơn 1,24 triệu từ. Không được embedding nguyên văn bản; phải phân đoạn theo cấu trúc pháp lý.
5. Dữ liệu JSON là UTF-8 hợp lệ. Hiện tượng mojibake khi đọc bằng một số lệnh PowerShell là lỗi hiển thị console, không phải lỗi corpus. Chỉ chuẩn hóa Unicode/newline/whitespace và kiểm tra checksum.
6. Có 20 context rỗng; trường `name` chỉ có ở 7.407/8.532 tệp. Pipeline phải chịu được thiếu title và passage rỗng.

## Ràng buộc bắt buộc

- Chỉ dùng dữ liệu BTC cung cấp; không gán nhãn thủ công, không lấy dữ liệu ngoài, không dùng data augmentation từ nguồn ngoài.
- Không dùng API trong quá trình xây dựng; mô hình phải tải về, chạy và kiểm soát cục bộ.
- Tổng tham số của toàn hệ thống trong từng task phải dưới 4 tỷ, tính cả embedding model, reranker và generator. Quantization/LoRA không làm giảm cách BTC tính số tham số.
- Chỉ dùng mô hình đã đăng ký và được BTC phê duyệt.
- Public Test: tối đa 10 submission/ngày. Private Test: tối đa 3 submission/ngày.
- Top 10 phải cung cấp mã nguồn để tái lập; top 1-3 phải nộp bài báo để kết quả được công nhận. Cần chuẩn bị Data Statement, Model Card, log huấn luyện và môi trường tái lập từ đầu.

## Phát hiện bảo mật P0

`codabench.txt` chứa thông tin đăng nhập dạng plaintext, đang được Git theo dõi và đã xuất hiện trong commit đầu tiên; repository có remote GitHub. Không nên giả định bí mật còn an toàn dù remote là private.

Hành động ngay:

1. Đổi mật khẩu Codabench và thu hồi phiên/token cũ.
2. Xóa credential khỏi lịch sử Git, không chỉ xóa ở commit mới.
3. Thêm `codabench.txt` vào `.gitignore`; chuyển bí mật sang biến môi trường hoặc secret manager cục bộ.
4. Kiểm tra access log/submission history và quyền Organization.
5. Không đưa credential vào log, notebook, Docker image hoặc artifact nộp bài.

## Chiến lược dùng chung hai task

```text
Corpus JSON
  -> chuẩn hóa + phân đoạn Điều/Khoản/Điểm
  -> chỉ mục BM25 word/char + dense index
  -> fusion top-N
  -> cross-encoder reranker
       -> Task 1: gom điểm chunk thành document, xuất top-5 ID
       -> Task 2: chọn evidence, sinh câu trả lời dài có căn cứ pháp lý
```

Một cấu hình ngân sách tham số an toàn là: dense retriever 200-600M + reranker 300-600M + generator 1.5-2.5B, tổng toàn hệ thống dưới 4B. Tên model cụ thể chỉ chốt sau khi đối chiếu danh sách BTC đã duyệt.

## Thứ tự ưu tiên

- P0: đổi credential; dựng local scorer và submission validator giống hệt mã chấm.
- P1: parser Điều/Khoản/Điểm, BM25 mạnh, baseline top-5 Task 1.
- P1: dense retriever + hard-negative reranker dùng chung.
- P1: pseudo-link context cho Task 2 và extractive-abstractive generator.
- P2: ensemble/fusion, metric-aware decoding, calibration và controlled leaderboard experiments.
- P2: Docker/README, seed/config/log, Data Statement, Model Card và khung bài báo.

