# Task 1 — LegalIR · hai bản v3 chạy song song

Cả hai file sinh ra từ `../DSC2026_Task1_LegalIR_AITeamVN_v2.ipynb`. Bản v2 **không bị sửa** —
mọi số liệu cũ vẫn còn để đối chiếu.

| | `DSC2026_Task1_v3A_rerank_input.ipynb` | `DSC2026_Task1_v3B_finetune_reranker.ipynb` |
|---|---|---|
| Câu hỏi nó trả lời | reranker yếu vì **model** hay vì **input sai**? | fine-tune reranker được thêm bao nhiêu? |
| `PROFILE` | `v3a_rerank_input` | `v3b_ft_reranker` |
| `MAX_CHUNKS_PER_DOC` | **150** (giữ nguyên → dùng lại cache embedding cũ) | **2500** |
| `CHUNKER_VER` | `''` → `_CAPTAG` rỗng, tên cache như v2 | `'t1'` → `_CAPTAG='_m2500_t1'`, cache riêng |
| Encode lại corpus | **không** | có, ~20 phút |
| GPU | ~1h | ~3–4h |
| Chạy tới đâu | hết Stage 7B rồi đọc kết quả | hết Stage 9 |

## Chạy song song được không

**Kaggle: được.** Mỗi notebook là một container riêng, `/kaggle/working` riêng, nên không thể
ghi đè cache của nhau. Kaggle cho 2 session GPU đồng thời. Đổi lại quota 30h/tuần cháy gấp
đôi và hai bản không chia sẻ được embedding (B phải encode riêng).

**Colab: chỉ an toàn nhờ `_CAPTAG`.** Cả hai mount cùng My Drive. Bản v2 đặt tên thư mục
embedding theo `TAG = <model>_c{CHUNK_CHARS}` — không có `PROFILE`, không có cap → hai session
sẽ ghi đè shard `.npy` của nhau **trong im lặng**. Hai bản v3 đưa cap vào `TAG` và
`CHUNKS_REL`, nên A (`_c3000`) và B (`_c3000_m2500_t1`) ghi vào hai thư mục khác nhau.
**Đừng làm A và B trùng cả `MAX_CHUNKS_PER_DOC` lẫn `CHUNKER_VER`** khi chạy song song trên
Colab — trùng là hai bản dùng chung một `TAG`.

## Đổi so với v2 (ngoài các cell mới)

5 chỗ, đều ở cell Config trừ hai cái cuối:

1. `PROFILE` — tách cache, `experiments.csv` và tên file nộp.
2. `MAX_CHUNKS_PER_DOC` + `CHUNKER_VER` + `_CAPTAG` mới.
3. `CHUNKS_REL` và `TAG` chứa `_CAPTAG` — sửa một lỗi thật của v2: đổi cap mà tên cache không
   đổi thì `cache_path()` trả về parquet/shard cũ mà không báo gì.
4. `DO_FINETUNE = False` ở cả hai bản. `recall@100 = 0.9897` → retriever đã xong việc,
   fine-tune bi-encoder tốn thêm một lần encode lại toàn corpus để tối ưu cái đã hết chỗ.

## Cơ sở số liệu (đo trên `train.json` + corpus, không phải suy đoán)

| Đo | Giá trị | Hệ quả |
|---|---|---|
| Phân bố gold/câu | 6447 câu 1 gold · 485 câu 2 · 68 câu ≥3 | 92% single-gold → tối ưu cho rank-1, bỏ qua diversity |
| Tổng chunk (`CHUNK_CHARS=3000`, cap 150) | ~154.000 | markdown v2 ghi ~500k là số cũ |
| Chunk/doc toàn corpus | mean 18 · p50 11 | |
| Chunk/doc **của gold doc** | mean 45 · **p50 30** · p90 117 | reranker đọc 3 chunk = ~10% nội dung |
| Gold doc bị cap 150 cắt | **6,3%** số lần xuất hiện (41/8532 doc bị cap) | bỏ cap chỉ thêm 3,5% chunk |
| Độ dài gold vs corpus | p50 64k vs 22k ký tự | gold dài gấp ~3 lần |
| Query có số hiệu văn bản (`15/2020/NĐ-CP`) | 30/7000 | **không đủ để làm exact-match booster** |
| Văn bản có `passage` rỗng | **20** (không có cả field `name`) | 0 chunk → dense không bao giờ truy hồi được |
| Trong đó từng là gold | **6** | **9 câu hỏi train mất trắng** — trần recall bị hạ |

## Hai lỗi dữ liệu tìm ra khi chạy bản A

**1. 20 văn bản có `passage` rỗng và không có field `name`.** Tiêu đề của chúng chỉ được vá từ
slug trong `link` ở Stage 1, nhưng `chunk_doc()` **chỉ chunk `passage`** nên chúng nhận 0 chunk
→ dense retrieval không bao giờ truy hồi được. 6/20 doc này từng là gold và **9 câu hỏi train
mất trắng** (mọi gold của chúng nằm trong nhóm đó). Lỗi này có sẵn trong v2.

- **Bản A** chỉ *báo cáo* (cell 7B.2 in số doc 0 chunk + số câu mất trắng, kèm bao nhiêu câu
  thuộc val). Không vá, vì sửa chunker là phải encode lại — mất đúng thứ làm A rẻ.
- **Bản B** vá: doc không sinh được chunk nào thì phát một **chunk chỉ chứa tiêu đề**. Tiêu đề
  vá từ slug link có loại văn bản + chủ đề + năm, đủ để khớp ở mức chủ đề.

**2. `TAG`/`CHUNKS_REL` không chứa phiên bản chunker.** Vá chunker mà tên cache không đổi thì
`cache_path()` trả về parquet + shard của chunker cũ **trong im lặng**. Vì thế có `CHUNKER_VER`:
bản B đặt `'t1'` → cache tách hẳn khỏi bản A.

## Lỗi mà Stage 7B sửa

`best_chunks_per_doc` của v2 chỉ xét chunk nằm trong **top-`CAND_CHUNKS`=1000 của toàn
corpus**. Một doc xếp hạng ~25 thường chỉ có 1–2 chunk lọt top-1000 → `RERANK_CHUNKS_PER_DOC=3`
không bao giờ được đáp ứng, và đúng những gold doc bị retriever xếp thấp (ca mà reranker phải
cứu) lại được cấp ít chunk nhất. `select_chunks` (cell 7B.2) lấy top-m **trong phạm vi từng
doc** từ full similarity row — `dense_search` đã tính row đó nên gần như miễn phí. Cell 7B.2
in ra so sánh chunk/doc thực nhận giữa selector cũ và mới.

## Đo bằng paired bootstrap

`N_VAL=1000`, recall@5 ≈ 0,9 → sai số chuẩn ≈ **0,0095**. Các con số trong log v2
(0,8768 / 0,8973 / 0,8996) lệch nhau đúng cỡ nhiễu đó. `compare()` ở 7B.1 so **ghép cặp theo
từng câu** và chỉ kết luận khi `P(A>B) > 0,95`.

## Thứ tự chạy

**Bản A** — Stage 0 → 7 (dùng cache) → 7B.1 → 7B.2 → 7B.3 → **7B.3b (grid, ~1h GPU)** →
7B.4a → 7B.4b → đọc bảng. Nếu có config thắng `dense` rõ: 9B → Stage 9 → nộp.

**Bản B** — Stage 0 → 7 (encode lại) → 7B.1 → 7B.2 → 7B.3 → 7B.4a → **8B.1 với `SMOKE=True`**
→ 8B.2 (~5 phút, xem loss có giảm) → đặt `SMOKE=False`, chạy lại 8B.1 + 8B.2 (~1–2h) → 8B.3
(chọn checkpoint) → 7B.3b → 7B.4b → 9B → Stage 9.

Bản B **không phụ thuộc kết quả bản A**: nó train ở `top30 × 8 chunk × maxlen 512`. Nếu A chỉ
ra hình dạng khác thắng rõ, sửa `FT_RR_MAXLEN` / `RERANK_TOP` / `RERANK_CHUNKS_PER_DOC` rồi
train lại — dữ liệu train ở 8B.1 rẻ, chỉ model là đắt.

## Chưa chạy thử

Toàn bộ code trong `Stage 8B` được viết mà **chưa từng thực thi** (máy local không có GPU và
chưa tải model). Vì thế `SMOKE = True` là mặc định: 300 câu / 30 bước, ~5 phút, để phát hiện
lỗi API trước khi đốt 3h GPU. Chỗ dễ vỡ nhất là API `CrossEncoderTrainer` + `LambdaLoss` của
sentence-transformers 5.4.0 và VRAM lúc train trên T4 15GB.

## Việc sau đó

LTR combiner (LightGBM LambdaRank) trên các feature đã cache — dense max/top2/rank, bm25
max/rank, reranker max/top2, `n_chunks`, `doc_len`. Để sau bản B vì feature mạnh nhất của nó
là điểm của reranker đã fine-tune. Cần một pass reranker trên 6000 câu train.
