# Context cho Agent - Task 2: LegalQA

> Bản context được rà soát ngày 17/08/2026 theo múi giờ Asia/Saigon. Đây là nguồn context cục bộ dành cho mọi agent làm việc trong `Task 2/`. Nếu BTC phát hành thông báo mới sau ngày này, phải đọc và cập nhật lại trước khi tiếp tục.

## 1. Nhiệm vụ

Với một câu hỏi pháp luật tiếng Việt, hệ thống phải tạo câu trả lời bằng ngôn ngữ tự nhiên, dựa trên căn cứ trong corpus pháp luật do BTC cung cấp.

Mục tiêu xếp hạng chính thức:

1. **METEOR là độ đo chính.**
2. **ROUGE-L là độ đo phụ/tham khảo.**

Tại thời điểm rà soát, cuộc thi đang ở vòng Public Test, từ 06/08/2026 đến hết 18/09/2026. Private Test dự kiến diễn ra từ 19/09/2026 đến 23/09/2026.

## 2. Thứ tự ưu tiên nguồn thông tin

Khi các tài liệu có nội dung không thống nhất, áp dụng thứ tự ưu tiên sau:

1. Các thông báo/đính chính mới hơn của BTC, đặc biệt:
   - `../[DSC@UIT 2026] Cập nhật QUAN TRỌNG về độ đo đánh giá và mô tả bài toán cuộc thi.docx`
   - `../[DSC@UIT 2026] Đăng ký Mô hình Cuộc thi Khoa học Dữ liệu UIT 2026.docx`
2. Dữ liệu thực tế, `Scoring-Program-Task-LegalQA/scoring.py` và package `rouge_score/` đi kèm đối với hành vi chấm có thể thực thi.
3. `DSC2026_Task2_LegalQA_Data_Overview.docx`, `[DSC@UIT 2026] Dữ liệu Vòng Public Test – Task 2_ LegalQA.docx` và thông báo Warm-up.
4. `../UIT_DSC2026_Thể_lệ.pdf` đối với các quy định chung.
5. Nội dung trong `../reports/` chỉ là sản phẩm nội bộ của đội, không phải nguồn chính thức từ BTC.

### Các điểm không thống nhất đã xác định

- Thông báo Public Test gọi file test là `public_test.json`, nhưng file được cung cấp và Data Overview dùng tên `public-official.json`. Trong code phải dùng đúng tên file thực tế `public-official.json`.
- Hai bản Data Overview trong thư mục Task 2 giống nhau hoàn toàn ở cấp byte, cùng SHA-256 `ADD8AE1E232A9F339C92EE6FF8D4FC1085D9C9A5DFC2D1B1042EF2C979F9524E`.
- Thể lệ PDF yêu cầu câu trả lời minh bạch, có khả năng giải thích và trích dẫn căn cứ. Tuy nhiên, scorer tự động chỉ đo độ tương đồng từ vựng. Phải tối ưu đúng scorer nhưng vẫn bảo đảm câu trả lời có căn cứ và không bịa thông tin.

## 3. Các ràng buộc bắt buộc

- Chỉ được sử dụng dữ liệu do BTC cung cấp.
- Không được thu thập hoặc crawl dữ liệu pháp luật bên ngoài.
- Không được gán nhãn thủ công.
- Không được tăng cường dữ liệu bằng nguồn bên ngoài.
- Dữ liệu đã dùng để pretrained một mô hình hợp lệ không bị xem là dữ liệu ngoài mà đội trực tiếp sử dụng. Tuy nhiên, bản thân mô hình vẫn phải đáp ứng tất cả quy định.
- Không được sử dụng bất kỳ API nào trong quá trình xây dựng hệ thống, kể cả API thương mại hoặc phi lợi nhuận.
- Chỉ được dùng mô hình/hệ thống mã nguồn mở hoặc open-weight mà đội có thể tải về, tự chạy và kiểm soát trực tiếp.
- Tổng số tham số của **toàn bộ hệ thống trong Task 2 phải nhỏ hơn 4 tỷ**, tính cả embedding model, retriever, reranker, generator và mọi thành phần học máy khác.
- LoRA, quantization, GPTQ, AWQ, GGUF hoặc kỹ thuật giảm bộ nhớ không làm giảm cách BTC tính tổng số tham số.
- Mô hình distillation được phép nếu tổng tham số thực tế của hệ thống sau distillation vẫn dưới 4 tỷ.
- Mọi mô hình sử dụng phải được đăng ký và BTC phê duyệt. Chỉ nhỏ hơn 4 tỷ là chưa đủ.
- Thời gian đăng ký mô hình: 06/08/2026 đến hết 18/09/2026.
- Form đăng ký: <https://forms.gle/HWE7tcxzWq63Kxv28>.
- Danh sách mô hình đã duyệt: <https://docs.google.com/spreadsheets/d/1c5jzsYezWho1WGLRfMKWOaFPLIk_GTnXP5vV8AOWM2Q/edit?usp=sharing>.
- Public Test: tối đa 10 submission/ngày.
- Private Test: tối đa 3 submission/ngày.
- Phải nộp bằng đúng Organization đã đăng ký trên Codabench. Cấu hình hiện tại của repository dùng tên `SGU_LegalMind`.
- Codabench Task 2: <https://www.codabench.org/competitions/17716/>.
- Codabench Task 1 và Task 2 là hai hệ thống độc lập; phải tham gia và được duyệt riêng.
- Top 10 phải cung cấp mã nguồn có thể tái lập, theo giấy phép MIT, và có thể bị yêu cầu gửi log/cấu hình môi trường trong 48 giờ.
- Cần chuẩn bị README, môi trường khóa phiên bản, seed, checksum, Data Statement và Model Card ngay từ đầu.
- Top 1-3 phải hoàn thành bài báo khoa học theo quy định để kết quả được công nhận chính thức.

## 4. Hợp đồng dữ liệu cục bộ

Các đường dẫn chính:

- `LegalQA - Public Test/train.json`
- `LegalQA - Public Test/public-official.json`
- `LegalQA - Public Test/selected-contexts/selected-contexts/context_*.json`

Train và Public Test đều là JSON Object ở cấp cao nhất, với key là question ID dạng chuỗi:

```json
{
  "82051": {
    "question": "Vận chuyển động vật ... thì bị xử phạt thế nào?",
    "answer": "Căn cứ khoản 3 ..."
  }
}
```

### Thống kê

- Train: 7.000 mẫu.
- Public Test: 1.000 mẫu.
- Trong train, `question` và `answer` đều là chuỗi không rỗng.
- Trong Public Test, toàn bộ `answer` là `null`.
- Question ID giữa train và public không trùng nhau và phải giữ nguyên dạng chuỗi.
- Độ dài câu hỏi trung vị khoảng 85 ký tự trong cả train và public.
- Độ dài answer train trung vị: 1.410 ký tự, khoảng 312 từ tách bằng khoảng trắng.
- P90: 2.612 ký tự, khoảng 576 từ.
- P95: 3.145 ký tự, khoảng 692 từ.
- Answer dài nhất: 10.755 ký tự, khoảng 2.435 từ.
- 6.760/7.000 answer chứa các từ khóa trích dẫn pháp luật phổ biến như Điều, Khoản, Nghị định, Thông tư hoặc Luật.
- 30 answer chứa URL.
- 2.833 answer chứa từ `hình`, thường do đáp án nguồn có đuôi biên tập như chú thích hình hoặc câu hỏi liên quan. Đây là nhiễu nhãn cần được tính đến khi phân tích metric.

### Câu Public Test trùng chính xác với train

Public QID `129859` trùng với train QID `88019` sau khi chuẩn hóa:

> Cơ quan chủ trì soạn thảo văn bản quy phạm pháp luật có những trách nhiệm gì trong việc lồng ghép vấn đề bình đẳng giới vào văn bản?

Đây là dữ liệu chính thức do BTC cung cấp. Phải dùng exact-match để tái sử dụng trực tiếp answer train cho public item này trước khi chạy mô hình.

### Trùng lặp và quan hệ giữa hai task

- Task 2 train có 16 nhóm câu hỏi trùng nhau sau chuẩn hóa.
- Các answer trong cùng nhóm có thể khác nhau về nội dung và độ dài.
- Khi cross-validation, phải đặt toàn bộ câu cùng nhóm vào một fold.
- Phải chấm theo reference cụ thể của từng record; không được tự gộp hoặc viết lại nhãn bằng tay.
- Có 22 câu hỏi chuẩn hóa trùng chính xác giữa train Task 1 và train Task 2.
- Có 1 câu hỏi trùng giữa hai tập public.
- Điều này cho phép xây dựng nền tảng retrieval chung từ dữ liệu chính thức.
- Chia sẻ corpus giống nhau là an toàn. Tuy nhiên, việc dùng label của task này để huấn luyện task kia không được BTC nói rõ. Quy định chung chỉ nói “dữ liệu BTC cung cấp”, vì vậy phải xin BTC xác nhận trước khi phụ thuộc vào cross-task label trong hệ thống thi chính thức.

## 5. Corpus và các trường hợp biên

Corpus Task 1 và Task 2 giống nhau hoàn toàn ở cấp byte:

- 8.532 file JSON cho mỗi task.
- Manifest SHA-256: `7d5f58b0825c16286c0bc5620eb778c0347ff97ea9711cfa3d1810057cd4a6a2`.
- Nên tạo một index read-only dùng chung thay vì tiền xử lý và lưu trữ hai lần.

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
- Tất cả link đều thuộc `thuvienphapluat.vn`.
- Có 1.125 file thiếu trường `name`. Pipeline phải suy ra title dự phòng từ URL và không được yêu cầu `name` luôn tồn tại.
- Có 20 passage rỗng, với ID: `10533`, `131890`, `149317`, `177151`, `181693`, `187338`, `191261`, `196918`, `208668`, `210808`, `232489`, `255762`, `263763`, `288457`, `34810`, `55497`, `56098`, `57978`, `67660`, `71014`.
- Độ dài passage trung vị: 23.112 ký tự, tương đương khoảng 4.813 từ tách bằng khoảng trắng.
- P90: 90.141 ký tự, khoảng 18.406 từ.
- Văn bản lớn nhất là document `68843`, có 5.983.358 ký tự, khoảng 1.242.409 từ.
- Không được embedding nguyên văn bản hoặc chỉ cắt phần đầu một cách âm thầm.
- Có 5 nhóm passage trùng hash, bao phủ 29 document. Dù nội dung trùng nhau, vẫn phải giữ từng document ID riêng biệt.

Ưu tiên chia đoạn theo cấu trúc pháp lý:

1. Chương.
2. Mục.
3. Điều.
4. Khoản.
5. Điểm.
6. Nếu không nhận diện được cấu trúc thì dùng cửa sổ token có overlap.

Mỗi chunk phải giữ document ID, title/link, citation, vị trí và thứ tự. Task 2 cần truy xuất được evidence span cụ thể, không chỉ document ID.

## 6. Hành vi chính xác của scorer

Mã chấm chính thức: `Scoring-Program-Task-LegalQA/scoring.py`.

Scorer xuất:

- `meteor`: METEOR trung bình, là metric chính.
- `rouge`: ROUGE-L F-measure trung bình, là metric phụ.

### METEOR

- Hàm `build_in_tokenizer` trả nguyên chuỗi đầu vào.
- Phần dùng PyVi đã bị comment.
- METEOR được gọi theo dạng:

```python
meteor_score([reference.split()], prediction.split())
```

- Vì vậy, text được tách bằng khoảng trắng trước khi NLTK thực hiện matching.
- Không có word segmentation dành cho tiếng Việt.
- Dấu câu gắn liền với token và độ dài câu trả lời ảnh hưởng trực tiếp đến điểm.
- Scorer tải NLTK resource `wordnet` và `omw-1.4`.
- Khi dựng local scorer hoặc container, phải pin phiên bản NLTK và cache đúng hai resource này để tái lập kết quả.

### ROUGE-L

- Scorer dùng package `rouge_score` đi kèm với `use_stemmer=False`.
- Tokenizer mặc định chuyển chữ thành chữ thường rồi thay mọi ký tự ngoài `[a-z0-9]` bằng khoảng trắng.
- Ký tự tiếng Việt có dấu và chữ `đ` bị cắt/bỏ thành các mảnh ASCII không tự nhiên.
- Đây là tokenizer không phù hợp về mặt ngôn ngữ, nhưng local evaluator vẫn phải khớp chính xác với code BTC. Không được tự sửa tokenizer rồi dùng metric mới để lựa chọn mô hình.

### Key và kiểu dữ liệu

- Scorer gọi `str(...)` trên answer, nhưng hợp đồng đúng vẫn là JSON string.
- Không được lợi dụng việc list/dict bị chuyển thành chuỗi Python.
- Scorer chỉ kiểm tra số lượng prediction và reference trước, sau đó truy cập bằng key.
- Key thiếu hoặc thừa có thể gây `KeyError` và làm hỏng toàn bộ submission.
- Validator phải yêu cầu tập question ID khớp chính xác.

### Hệ quả đối với tối ưu mô hình

- Tối ưu METEOR trước ROUGE-L.
- Một câu trả lời ngắn có thể đúng về pháp lý nhưng mất nhiều token recall so với reference dài.
- Không được copy toàn bộ context một cách mù quáng, vì phần không liên quan làm giảm token precision và tăng chi phí sinh.
- Phải hiệu chỉnh độ dài và cấu trúc answer theo loại câu hỏi bằng OOF METEOR.
- Cần bảo toàn citation, con số, đơn vị, ngoại lệ, thứ tự liệt kê và các cụm từ pháp lý xuất hiện trong reference.
- Ưu tiên cơ chế extractive hoặc copy-aware khi evidence hỗ trợ.
- Reference có thể chứa quy định cũ hoặc nhiễu biên tập. Leaderboard tự động thưởng lexical overlap, nhưng hệ thống nội bộ vẫn phải kiểm tra căn cứ, số liệu và unsupported claim.

## 7. Hợp đồng submission

Shape của answer mà scorer yêu cầu:

```json
{
  "80189": {
    "answer": "Căn cứ ... Theo đó, ..."
  }
}
```

Data Overview Task 2 cục bộ không ghi rõ tên ZIP và cấu trúc đóng gói. Thông báo Public Test nói format không thay đổi so với Warm-up. Vì vậy:

- Phải lấy sample/template Warm-up chính thức trên Codabench.
- Sao chép chính xác tên archive, tên file và đường dẫn bên trong.
- Nếu template dùng ZIP có `submission.json` ở root thì phải giữ đúng cấu trúc đó và không thêm file ngoài.
- Không được suy đoán quy tắc đóng gói chỉ từ Task 1.

Trước khi đóng gói, phải kiểm tra:

- Tập question ID khớp chính xác với input.
- Mỗi value là object có `answer` dạng chuỗi, không phải `null`.
- JSON UTF-8 hợp lệ, không có NaN hoặc Python representation ngoài ý muốn.
- Tên archive và internal path khớp template Warm-up chính thức.
- Chạy scorer BTC trên fixture có nhãn với đúng phiên bản NLTK/ROUGE và lưu kết quả cùng checksum.

## 8. Hướng mô hình đề xuất

Xây dựng hệ thống RAG cục bộ, ưu tiên evidence:

```text
question
  -> đặc trưng citation chính xác + BM25/character + dense retrieval
  -> fusion ở cấp document/chunk
  -> cross-encoder reranking
  -> chọn các span Điều/Khoản theo đúng thứ tự
  -> local open model sinh câu trả lời có căn cứ
  -> rerank candidate bằng OOF METEOR và kiểm tra grounding
```

Các hướng huấn luyện chỉ dùng dữ liệu BTC:

- Tự động liên kết citation trong answer như Điều, Khoản, Luật, Nghị định với document/chunk trong corpus.
- Lưu confidence cho pseudo-label; không sửa nhãn bằng tay.
- Với câu không có citation rõ ràng, dùng sự đồng thuận giữa sparse và dense answer-to-corpus retrieval để tạo silver evidence.
- Xây nearest-neighbor answer retrieval làm baseline rẻ, đặc biệt phải có exact-match trước.
- Sau đó so sánh với extractive grounded baseline và generative RAG.
- Chỉ dùng label Task 1 để fine-tune retriever/reranker Task 2 sau khi BTC xác nhận việc cross-task label là hợp lệ.
- Generator phải là model cục bộ đã được duyệt và phải để đủ ngân sách tham số cho retriever/reranker.
- Tổng tham số được tính cho toàn pipeline, không chỉ generator.
- Nếu tài nguyên cho phép, sinh nhiều candidate rồi rerank bằng mô hình dự đoán OOF METEOR kết hợp citation consistency, number consistency, evidence coverage, repetition penalty và unsupported-claim check.

Validation phải:

- Group theo câu hỏi đã chuẩn hóa.
- Khi đã có evidence link, group thêm theo source document/citation để giảm leakage.
- Báo cáo METEOR và ROUGE chính thức.
- Báo cáo theo bucket độ dài answer.
- Kiểm tra citation exact match và tính nhất quán của con số.
- Đo retrieval recall của silver evidence.
- Đo unsupported-claim rate để tách lỗi retrieval khỏi lỗi generation.

## 9. Trạng thái code hiện có

- Hiện không có notebook hoặc pipeline mô hình Task 2 trong thư mục này; chỉ có dữ liệu, tài liệu và scorer chính thức.
- Task 1 có hai notebook retrieval/reranking có thể tái sử dụng pattern kỹ thuật và shared corpus index.
- Các notebook Task 1 chưa được thực thi và không có output lưu sẵn; các metric ghi trong Markdown chưa phải kết quả đã xác minh.
- Dù corpus/index có thể dùng chung, artifact và config Task 2 phải tách khỏi Task 1.
- Codabench, question ID, metric, prediction và ngân sách tham số phải được quản lý riêng cho từng task.

## 10. Checklist cho mọi agent

1. Đọc file này, `Scoring-Program-Task-LegalQA/scoring.py` và `rouge_score/tokenize.py` trước khi sửa evaluator hoặc decoding.
2. Không dùng web, API, dữ liệu pháp luật bên ngoài hoặc nhãn thủ công.
3. Giữ chính xác question ID và kiểu chuỗi của answer.
4. Tách biệt train, validation, public và private artifact.
5. Group các câu hỏi trùng khi validation.
6. Ghi log tên model, tổng tham số, trạng thái phê duyệt, manifest dữ liệu, commit code, seed, config, phiên bản NLTK/ROUGE, metric và SHA-256 của submission.
7. Toàn bộ pipeline phải tái lập được mà không cần API. Model weights và NLTK resource phải được cache hoặc có hướng dẫn tải xác định, phù hợp quy định BTC.
8. Không được làm lộ credential. `../codabench.txt` chứa thông tin đăng nhập plaintext, đang được Git theo dõi và đã xuất hiện trong lịch sử repository. Không đọc hoặc sao chép nội dung của file này vào prompt, log, notebook, Markdown, ảnh hay submission. Chủ repository cần đổi credential và xóa bí mật khỏi lịch sử Git.
