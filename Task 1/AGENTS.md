# Context cho Agent - Task 1: LegalIR

> Bản context được rà soát ngày 17/08/2026 theo múi giờ Asia/Saigon. Đây là nguồn context cục bộ dành cho mọi agent làm việc trong `Task 1/`. Nếu BTC phát hành thông báo mới sau ngày này, phải đọc và cập nhật lại trước khi tiếp tục.

## 1. Nhiệm vụ

Với một câu hỏi pháp luật tiếng Việt, hệ thống phải trả về ID của các văn bản chứa thông tin cần thiết để trả lời câu hỏi.

Mục tiêu xếp hạng chính thức:

1. **Macro Recall là độ đo chính.**
2. **Macro Precision chỉ dùng để phá hòa khi Recall bằng nhau.**

Tại thời điểm rà soát, cuộc thi đang ở vòng Public Test, từ 06/08/2026 đến hết 18/09/2026. Private Test dự kiến diễn ra từ 19/09/2026 đến 23/09/2026.

## 2. Thứ tự ưu tiên nguồn thông tin

Khi các tài liệu có nội dung không thống nhất, áp dụng thứ tự ưu tiên sau:

1. Các thông báo/đính chính mới hơn của BTC, đặc biệt:
   - `../[DSC@UIT 2026] Cập nhật QUAN TRỌNG về độ đo đánh giá và mô tả bài toán cuộc thi.docx`
   - `../[DSC@UIT 2026] Đăng ký Mô hình Cuộc thi Khoa học Dữ liệu UIT 2026.docx`
2. Dữ liệu thực tế và mã chấm `Scoring-Program-Task-LegalIR/scoring.py` đối với hành vi chấm có thể thực thi.
3. `DSC2026_Task1_LegalIR_Data_Overview.docx` và `[DSC@UIT 2026] Dữ liệu Vòng Public Test – Task 1_ LegalIR.docx`.
4. `../UIT_DSC2026_Thể_lệ.pdf` đối với các quy định chung.
5. Notebook và nội dung trong `../reports/` chỉ là sản phẩm nội bộ của đội, không phải nguồn chính thức từ BTC.

### Các điểm mâu thuẫn đã xác định

- Đoạn đầu của tài liệu cập nhật từng nói Precision là độ đo chính. Tuy nhiên, phần đính chính xuất hiện sau đó trong cùng chuỗi thông báo xác nhận **Recall là độ đo chính, Precision dùng để phá hòa**. Tài liệu Data Overview cũng xác nhận thứ tự này.
- Một thông báo nói rằng chỉ cần một câu có trên 5 dự đoán thì toàn bộ submission có thể bị 0. Tài liệu Data Overview và scorer được phát hành thực tế chỉ cho câu vi phạm nhận 0. Không được dựa vào khác biệt này: luôn giới hạn từ 1 đến 5 ID duy nhất cho mọi câu hỏi.
- Thông báo Public Test ghi `public_official.json`, nhưng file được cung cấp và Data Overview dùng tên `public-official.json`. Trong code phải dùng đúng tên file thực tế `public-official.json`.
- Hai bản Data Overview trong thư mục Task 1 giống nhau hoàn toàn ở cấp byte, cùng SHA-256 `E250CB1B82EBFCA2E43BAA3194FB26A0F2C3BDA84FB8B1192457C7E8E6D0B0E8`.

## 3. Các ràng buộc bắt buộc

- Chỉ được sử dụng dữ liệu do BTC cung cấp.
- Không được thu thập hoặc crawl dữ liệu pháp luật bên ngoài.
- Không được gán nhãn thủ công.
- Không được tăng cường dữ liệu bằng nguồn bên ngoài.
- Dữ liệu đã dùng để pretrained một mô hình hợp lệ không bị xem là dữ liệu ngoài mà đội trực tiếp sử dụng. Tuy nhiên, bản thân mô hình vẫn phải đáp ứng tất cả quy định.
- Không được sử dụng bất kỳ API nào trong quá trình xây dựng hệ thống, kể cả API thương mại hoặc phi lợi nhuận.
- Chỉ được dùng mô hình/hệ thống mã nguồn mở hoặc open-weight mà đội có thể tải về, tự chạy và kiểm soát trực tiếp.
- Tổng số tham số của **toàn bộ hệ thống trong Task 1 phải nhỏ hơn 4 tỷ**, tính cả embedding model, retriever, reranker, generator và mọi thành phần học máy khác.
- LoRA, quantization, GPTQ, AWQ, GGUF hoặc kỹ thuật giảm bộ nhớ không làm giảm cách BTC tính tổng số tham số.
- Mô hình distillation được phép nếu tổng tham số thực tế của hệ thống sau distillation vẫn dưới 4 tỷ.
- Mọi mô hình sử dụng phải được đăng ký và BTC phê duyệt. Chỉ nhỏ hơn 4 tỷ là chưa đủ.
- Thời gian đăng ký mô hình: 06/08/2026 đến hết 18/09/2026.
- Form đăng ký: <https://forms.gle/HWE7tcxzWq63Kxv28>.
- Danh sách mô hình đã duyệt: <https://docs.google.com/spreadsheets/d/1c5jzsYezWho1WGLRfMKWOaFPLIk_GTnXP5vV8AOWM2Q/edit?usp=sharing>.
- Public Test: tối đa 10 submission/ngày.
- Private Test: tối đa 3 submission/ngày.
- Phải nộp bằng đúng Organization đã đăng ký trên Codabench. Cấu hình hiện tại của repository dùng tên `SGU_LegalMind`.
- Codabench Task 1: <https://www.codabench.org/competitions/17715/>.
- Top 10 phải cung cấp mã nguồn có thể tái lập, theo giấy phép MIT, và có thể bị yêu cầu gửi log/cấu hình môi trường trong 48 giờ.
- Cần chuẩn bị README, môi trường khóa phiên bản, seed, checksum, Data Statement và Model Card ngay từ đầu.
- Top 1-3 phải hoàn thành bài báo khoa học theo quy định để kết quả được công nhận chính thức.

## 4. Hợp đồng dữ liệu cục bộ

Các đường dẫn chính:

- `LegalR - Public Test/train.json`
- `LegalR - Public Test/public-official.json`
- `LegalR - Public Test/selected-contexts/selected-contexts/context_*.json`

Train và Public Test đều là JSON Object ở cấp cao nhất, với key là question ID dạng chuỗi:

```json
{
  "86666": {
    "question": "Thời hạn cấp đăng ký xe máy ...?",
    "answer": ["280282"]
  }
}
```

### Thống kê

- Train: 7.000 mẫu.
- Public Test: 1.000 mẫu.
- `question` luôn là chuỗi không rỗng.
- Trong train, `answer` luôn là danh sách document ID dạng chuỗi.
- Trong Public Test, toàn bộ `answer` là `null`.
- Question ID giữa train và public không trùng nhau.
- Không được chuyển question ID thành số.
- Train có tổng cộng 7.637 liên kết question-document.
- Có 3.105 document ID gold duy nhất.
- Toàn bộ document ID gold đều tồn tại trong corpus.
- Độ dài câu hỏi trung vị: 86 ký tự trong train và 84 ký tự trong public.

Phân bố số văn bản gold trên mỗi câu hỏi:

| Số văn bản gold | Số câu hỏi |
|---:|---:|
| 1 | 6.447 |
| 2 | 485 |
| 3 | 53 |
| 4 | 14 |
| 5 | 1 |

### Các câu Public Test trùng chính xác với train

Có 5 câu Public Test trùng với câu train sau khi chuẩn hóa khoảng trắng và chữ thường. Đây là dữ liệu chính thức do BTC cung cấp, vì vậy phải xử lý bằng luật exact-match trước khi chạy mô hình:

| Public QID | Train QID | Document ID đã biết | Câu hỏi |
|---|---|---|---|
| `122394` | `120616` | `305788` | Chỉ số đánh giá chất lượng dịch vụ sự nghiệp công về thái độ phục vụ trong quá trình lập quy trình gồm những gì? |
| `106660` | `149172` | `21398` | Công ty cổ phần là gì? |
| `116190` | `153558` | `52090` | Hội đồng kiểm tra kết quả tập sự hành nghề luật sư là gì? |
| `76264` | `134012` | `193708` | Phạt nguội là gì? |
| `90994` | `105124` | `268645` | Quỹ bình ổn giá xăng dầu được thực hiện như thế nào? |

Không được để các câu trùng nhau lọt vào các fold validation khác nhau. Train có 16 nhóm câu trùng sau chuẩn hóa. Một số nhóm có nhãn hợp lệ khác nhau, ví dụ:

- `tham nhũng là gì?`
- `mức hưởng bảo hiểm xã hội một lần được quy định như thế nào?`
- `đối tượng nào được trang bị vũ khí quân dụng?`

Đây là nhiễu hoặc tính đa nghĩa của dữ liệu. Không được tự sửa nhãn bằng tay. Khi chia fold, phải group theo câu hỏi đã chuẩn hóa.

## 5. Corpus và các trường hợp biên

Corpus Task 1 và Task 2 giống nhau hoàn toàn ở cấp byte:

- 8.532 file JSON cho mỗi task.
- Manifest SHA-256: `7d5f58b0825c16286c0bc5620eb778c0347ff97ea9711cfa3d1810057cd4a6a2`.

Cấu trúc thông thường:

```json
{
  "id": 740,
  "name": "Quyet-dinh-...",
  "link": "https://thuvienphapluat.vn/...",
  "passage": "..."
}
```

Các điểm quan trọng:

- Cả 8.532 corpus ID đều là số nguyên duy nhất và khớp với tên file `context_<id>.json`.
- Khi xuất submission, phải chuyển document ID thành chuỗi.
- Tất cả link đều thuộc `thuvienphapluat.vn`.
- Có 1.125 file thiếu trường `name`. Pipeline phải suy ra title dự phòng từ URL và không được yêu cầu `name` luôn tồn tại.
- Có 20 passage rỗng, với ID: `10533`, `131890`, `149317`, `177151`, `181693`, `187338`, `191261`, `196918`, `208668`, `210808`, `232489`, `255762`, `263763`, `288457`, `34810`, `55497`, `56098`, `57978`, `67660`, `71014`.
- Độ dài passage trung vị: 23.112 ký tự, tương đương khoảng 4.813 từ tách bằng khoảng trắng.
- P90: 90.141 ký tự, khoảng 18.406 từ.
- Văn bản lớn nhất là document `68843`, có 5.983.358 ký tự, khoảng 1.242.409 từ.
- Không được embedding nguyên văn bản hoặc chỉ cắt phần đầu một cách âm thầm.
- Có 5 nhóm passage trùng hash, bao phủ 29 document. Trong đó 20 document là nhóm passage rỗng. Dù nội dung trùng nhau, vẫn phải giữ từng document ID riêng biệt.

Ưu tiên chia đoạn theo cấu trúc pháp lý:

1. Chương.
2. Mục.
3. Điều.
4. Khoản.
5. Điểm.
6. Nếu không nhận diện được cấu trúc thì dùng cửa sổ token có overlap.

Mỗi chunk phải giữ document ID, title/link, Điều/Khoản/Điểm, vị trí và thứ tự trong văn bản. Title hoặc text suy ra từ URL nên được index riêng để hỗ trợ file thiếu `name` hoặc có passage rỗng.

## 6. Hành vi chính xác của scorer

Mã chấm chính thức: `Scoring-Program-Task-LegalIR/scoring.py`.

Với mỗi câu hỏi `i`, nếu `1 <= len(P_i) <= 5`:

```text
Recall_i    = |set(T_i) ∩ set(P_i)| / len(T_i)
Precision_i = |set(T_i) ∩ set(P_i)| / len(P_i)
```

Nếu danh sách dự đoán rỗng hoặc có trên 5 phần tử, cả Recall và Precision của câu đó bằng 0. Điểm cuối cùng là trung bình không trọng số trên toàn bộ câu hỏi.

Hệ quả bắt buộc:

- Submission phải có chính xác cùng tập question ID với file input.
- Scorer ban đầu chỉ kiểm tra số lượng key, nhưng key thiếu hoặc thừa sẽ gây `TypeError`/`KeyError` ở bước sau và có thể làm hỏng toàn bộ submission.
- `answer` phải là list.
- Document ID phải là chuỗi. `"740"` có thể khớp; `740` không khớp với gold dạng chuỗi.
- Không bao giờ xuất quá 5 ID.
- Danh sách rỗng nhận 0 điểm.
- ID trùng lặp không làm tăng giao của hai tập hợp nhưng vẫn bị tính trong `len(P_i)`, do đó làm giảm Precision.
- Vì Recall là độ đo chính và thêm một ID hợp lệ, duy nhất không thể làm Recall giảm, mặc định an toàn là **xuất đúng 5 document ID duy nhất cho mỗi câu**.
- Chỉ xuất ít hơn 5 khi có thí nghiệm leaderboard có kiểm soát chứng minh lợi ích Precision phá hòa đáng để đánh đổi rủi ro Recall.
- Scorer xuất hai trường `recall` và `precision`. Thứ tự xếp hạng không được mã hóa trong `scoring.py`, vì vậy phải theo đính chính chính thức của BTC: Recall trước, Precision sau.

## 7. Hợp đồng submission

Tạo `submission.zip`, bên trong chỉ có một file `submission.json` nằm ngay ở thư mục gốc của ZIP:

```json
{
  "147194": {
    "answer": ["177504", "740", "...", "...", "..."]
  }
}
```

Trước khi đóng gói, phải kiểm tra:

- Tập key khớp chính xác với input.
- Mỗi value là object có trường `answer` dạng list.
- Mỗi câu có từ 1 đến 5 ID chuỗi, duy nhất; mặc định nên đúng 5.
- Mọi ID đều tồn tại trong corpus 8.532 document.
- JSON UTF-8 hợp lệ, không có NaN.
- `submission.json` không nằm trong thư mục con của ZIP.
- Chạy scorer chính thức trên một fixture có nhãn và lưu lại kết quả cùng checksum.

## 8. Hướng mô hình đề xuất

Pipeline ưu tiên retrieval ở cấp chunk nhưng xếp hạng ở cấp document:

```text
question
  -> đặc trưng tham chiếu pháp lý chính xác + BM25 word/character
  -> dense retrieval ở cấp chunk
  -> fusion có hiệu chỉnh hoặc RRF
  -> cross-encoder rerank các chunk tốt nhất của mỗi document
  -> gom điểm về document
  -> xuất 5 document ID duy nhất
```

Validation phải:

- Dùng đúng scorer BTC.
- Báo cáo macro Recall và Precision.
- Báo cáo Recall@1, Recall@3, Recall@5 và candidate Recall@N.
- Chia fold theo nhóm câu hỏi đã chuẩn hóa.
- Có thêm document-disjoint stress split.
- Mine hard negative từ văn bản cùng chủ đề, cùng số hiệu hoặc citation gần giống nhưng không thuộc gold.
- Tối ưu Recall@5 ở cấp document, không tối ưu accuracy ở cấp chunk.

## 9. Trạng thái code hiện có

- `Code/DSC2026_Task1_LegalIR.ipynb`: biến thể dùng BKAI Vietnamese bi-encoder và BAAI reranker, tổng tham số được ghi khoảng 0,70B.
- `Code/DSC2026_Task1_LegalIR_AITeamVN.ipynb`: biến thể dùng AITeamVN embedding và reranker, tổng tham số được ghi khoảng 1,2B.
- Cả hai notebook đều có logic cache, retrieval, rerank, validation và đóng gói hữu ích.
- Tuy nhiên, cả hai có **0 code cell đã thực thi và 0 output được lưu**. Mọi con số Recall ghi trong Markdown chỉ là tuyên bố chưa được xác minh cho đến khi chạy tái lập thành công.
- Notebook AITeamVN ghi nhận giả thuyết rằng dense-only có thể tốt hơn RRF BM25+dense với trọng số bằng nhau. Phải kiểm chứng out-of-fold; không được mặc định hybrid luôn tốt hơn.
- Trước khi dùng bất kỳ model nào, phải kiểm tra model đó đã có trong danh sách BTC phê duyệt.

## 10. Checklist cho mọi agent

1. Đọc file này và scorer BTC trước khi sửa retrieval hoặc submission code.
2. Không dùng web, API, dữ liệu pháp luật bên ngoài hoặc nhãn thủ công.
3. Giữ chính xác kiểu dữ liệu question ID và document ID tại mọi boundary.
4. Tách biệt train, validation, public và private artifact.
5. Không tune trực tiếp dựa trên đáp án ẩn hoặc leaderboard một cách không kiểm soát.
6. Ghi log tên model, tổng tham số, trạng thái phê duyệt, manifest dữ liệu, commit code, seed, config, metric và SHA-256 của submission.
7. Toàn bộ pipeline phải tái lập được mà không cần API.
8. Không được làm lộ credential. `../codabench.txt` chứa thông tin đăng nhập plaintext, đang được Git theo dõi và đã xuất hiện trong lịch sử repository. Không đọc hoặc sao chép nội dung của file này vào prompt, log, notebook, Markdown, ảnh hay submission. Chủ repository cần đổi credential và xóa bí mật khỏi lịch sử Git.
