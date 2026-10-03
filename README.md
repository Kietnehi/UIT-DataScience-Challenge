### Giới thiệu

Repo chứa lời giải của mình cho **Cuộc thi Khoa học Dữ liệu UIT 2026 (DSC@UIT 2026)**. Cuộc thi gồm hai bài toán xử lý văn bản pháp luật tiếng Việt:

| Task | Bài toán | Input → Output | Độ đo | Codabench |
| :---: | --- | --- | --- | :---: |
| **1** | **LegalIR** – Truy vấn văn bản pháp luật | Câu hỏi → tối đa **5** `document_id` | **Macro Recall** (chính), Macro Precision (phá hòa) | [17715](https://www.codabench.org/competitions/17715/) |
| **2** | **LegalQA** – Hỏi đáp pháp luật | Câu hỏi → câu trả lời bằng văn xuôi | **METEOR** (chính), ROUGE-L (tham khảo) | [17716](https://www.codabench.org/competitions/17716/) |

**Ràng buộc chính của BTC:** chỉ được dùng các pretrained model có trong danh sách đã duyệt, tổng số tham số neural **≤ 4B**, và chỉ dùng dữ liệu chính thức (`train.json` + corpus `context_*.json`).

### Kết quả

| Task | Bài toán | Thứ hạng |
| :---: | --- | :---: |
| **1** | LegalIR – Truy vấn văn bản pháp luật | 🏆 **Top 20 / 72 đội** |
| **2** | LegalQA – Hỏi đáp pháp luật | 🏆 **Top 14 / 42 đội** |

### Dữ liệu

| Chỉ số (Task 1) | Giá trị |
| --- | ---: |
| Câu hỏi `train.json` | 7.000 |
| Câu hỏi `public-official.json` | 1.000 |
| Văn bản trong corpus | 8.532 |
| Số đáp án trung bình / câu hỏi | 1,09 |

Mỗi văn bản trong corpus có các trường `id`, `name`, `link` (thuvienphapluat.vn) và `passage`. Đáp án gold của Task 2 viết theo văn phong thuvienphapluat.vn: mở đầu bằng *"Theo Điều X …"* rồi trích nguyên văn điều khoản.

### Task 1 – LegalIR

Pipeline nền (v3B) là hybrid retrieval kết hợp với cross-encoder rerank:

```
question ─┬─► BM25 (chunk)   ─┐
          └─► dense (chunk)  ─┴─► RRF fuse ─► top-N doc ─► cross-encoder rerank ─► top-5 document_id
```

- **Embedding:** `AITeamVN/Vietnamese_Embedding_v2` (~0.6B), fine-tune trên `train.json`
- **Reranker:** `AITeamVN/Vietnamese_Reranker` (~0.6B), fine-tune với hard negative
- **Tổng tham số:** ~1.2B (dưới giới hạn 4B)

Các phiên bản thử nghiệm nằm trong `Task 1/Code/v3_parallel/`:

| Phiên bản | Ý tưởng chính |
| --- | --- |
| `v3A` | Sửa bộ chọn chunk và đo lại baseline |
| `v3B` | Fine-tune reranker (checkpoint-750 là baseline chính) |
| `v3C` | Mở rộng ứng viên từ BM25, dense-title và số hiệu văn bản, có fallback về v3B |
| `v4` | Reranker học với hard negative và nhiều positive chunk |
| `v5` | Thay reranker bằng `Prism-Qwen3.5-Reranker-2B` / `bge-reranker-v2-gemma`, có cổng an toàn |
| `v6` / `v7` | LambdaRank stacker (LTR) + query memory, kiểm tra trên holdout theo nhóm |
| `v8.1` | Hard negative + rerank trên toàn bộ union ứng viên, `max_length=768` |
| `v9` | Ensemble checkpoint-750 và checkpoint-600 bằng rank fusion |
| `v10` | Chunk theo token cho văn bản luật + LambdaRank multi-instance ở cấp văn bản |

### Task 2 – LegalQA

Hướng tiếp cận **extraction-first**: METEOR so khớp token trên bề mặt, nên trích nguyên văn điều khoản luật cho điểm cao hơn để mô hình tự diễn đạt lại.

```
question → BM25 + Vietnamese_Embedding_v2 → RRF → Vietnamese_Reranker (fine-tune)
         → chọn evidence span (LightGBM / LambdaRank selector) → ghép câu trả lời trích nguyên văn
```

| Notebook | Nội dung |
| --- | --- |
| `DSC2026_Task2_LegalQA_Pipeline.ipynb` | Pipeline A: BM25 + embedding + reranker + LightGBM selector (generator tùy chọn) |
| `DSC2026_Task2_LegalQA_Pipeline_C_LegalGRPO.ipynb` | Biến thể C: generator `qwen3-1.7b-vietnamese-legal-grpo`, dùng lại cache retrieval của A |
| `dsc2026-task2-legalqa-pipeline-b-vilegalqwen3.ipynb` | V4: selector rank-aware (so sánh LightGBM regressor với LambdaRank) |
| `dsc2026-task2-legalqa-pipeline-v4-ranker.ipynb` | V6: reranker học hard negative + selector theo answer memory |

Thư mục `private-pipeline/` chứa các notebook đã chỉnh lại để chạy trên dữ liệu **Private Test**. Trong đó có thêm bản thử ViLegalBERT zero-shot và bản fine-tune LoRA `Qwen3.5-2B` làm bộ chọn evidence.

### Cấu trúc thư mục

```
UIT DS Challenge/
├── Task 1/
│   ├── CHALLENGE_TASK1_LegalIR.md        # Tóm tắt đề bài, dữ liệu, độ đo
│   ├── LegalR - Public Test/             # train.json, public-official.json
│   ├── Scoring-Program-Task-LegalIR/     # Mã chấm điểm chính thức của BTC
│   └── Code/v3_parallel/                 # Các notebook v3A → v10
├── Task 2/
│   ├── CHALLENGE_TASK2_LegalQA.md
│   ├── LegalQA - Public Test/
│   ├── Scoring-Program-Task-LegalQA/     # scoring.py + rouge_score
│   └── Code/                             # Các pipeline LegalQA
├── private-pipeline/                     # Notebook và dữ liệu cho vòng Private Test
├── scripts/                              # Script sinh notebook (build_task1_v10_notebook.ps1)
└── *.pdf / *.docx                        # Thể lệ, danh sách mô hình, thông báo của BTC
```

### Cách chạy

1. Mở notebook trên **Kaggle** (GPU T4 ×2) hoặc Google Colab.
2. Attach dữ liệu `train.json`, `public-official.json` (hoặc `private-official.json`) và corpus `selected-contexts.zip`.
3. Chạy lần lượt các cell. Kết quả trung gian được cache trong `/kaggle/working/artifacts`, nên nếu session bị ngắt thì chạy tiếp từ chỗ đã dừng.
4. Notebook tự đóng gói file submission `.zip` theo đúng định dạng Codabench.

Muốn chấm điểm local thì dùng `scoring.py` trong thư mục `Scoring-Program-Task-*` của từng task.

### Timeline cuộc thi

| Thời gian | Nội dung |
| --- | --- |
| 01/08 – 05/08/2026 | Vòng Warm-up |
| 06/08 – 18/09/2026 | Vòng Public Test |
| 19/09 – 23/09/2026 | Vòng Private Test |
| 24/09 – 24/10/2026 | Top 10 viết bài báo khoa học |
| 13/11/2026 | Bế mạc |

## Tác giả & Tài khoản GitHub

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&height=120&section=header" alt="header" />
</p>

| |
| :---: |
| <a href="https://github.com/Kietnehi"><img src="https://github-readme-stats.vercel.app/api?username=Kietnehi&show_icons=true&hide_title=true&hide=issues,contribs,prs&rank_icon=github&hide_border=true" alt="GitHub stats của Kietnehi" /></a> |
| <img src="https://github.com/Kietnehi.png" width="80" alt="Trương Phú Kiệt" /> |
| <b><a href="https://github.com/Kietnehi">Trương Phú Kiệt</a></b> |
| AI Engineer |
| <p align="center"><img src="https://img.shields.io/github/followers/Kietnehi?style=for-the-badge" alt="Followers của Kietnehi" /> <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github-star-counter.workers.dev%2Fuser%2FKietnehi&query=%24.stars&style=for-the-badge&color=yellow&label=Stars&logo=github" alt="Stars của Kietnehi" /> <a href="https://github.com/Kietnehi"><img src="https://img.shields.io/badge/Profile-GitHub-181717?style=for-the-badge&logo=github" alt="GitHub của Kietnehi" /></a></p> |

<p align="center">
  <a href="https://github.com/Kietnehi/UIT-DataScience-Challenge">
    <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&pause=1000&color=236AD3&center=true&vCenter=true&width=600&lines=UIT+Data+Science+Challenge+2026;Task+1%3A+Vietnamese+LegalIR;Task+2%3A+Vietnamese+LegalQA" alt="UIT Data Science Challenge 2026" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/UIT-Data_Science_Challenge_2026-0056D2?style=flat-square" alt="UIT Data Science Challenge 2026" />
  <img src="https://img.shields.io/badge/Tasks-LegalIR_%26_LegalQA-FF4B4B?style=flat-square" alt="LegalIR và LegalQA" />
</p>

### Tech Stack

<p align="center">
  <img src="https://skillicons.dev/icons?i=python,pytorch,sklearn,docker,git" alt="Python, PyTorch, scikit-learn, Docker và Git" />
</p>

### UIT DATA SCIENCE CHALLENGE 2026

<p align="center">
  <a href="https://github.com/Kietnehi/UIT-DataScience-Challenge">
    <img src="https://img.shields.io/github/stars/Kietnehi/UIT-DataScience-Challenge?style=for-the-badge&color=yellow" alt="Stars" />
    <img src="https://img.shields.io/github/forks/Kietnehi/UIT-DataScience-Challenge?style=for-the-badge&color=orange" alt="Forks" />
    <img src="https://img.shields.io/github/issues/Kietnehi/UIT-DataScience-Challenge?style=for-the-badge&color=red" alt="Issues" />
  </a>
</p>

<!-- Quote động -->
<p align="center">
  <img src="https://quotes-github-readme.vercel.app/api?type=horizontal&theme=dark" alt="Daily Quote" />
</p>

<p align="center">
  <i>Thank you for stopping by! Don’t forget to give this repo a <b>⭐️ Star</b> if you find it useful.</i>
</p>

<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&height=80&section=footer" alt="footer" />
</p>
