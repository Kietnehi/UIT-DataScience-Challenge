$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'Task 1\Code\v3_parallel\dsc2026-task1-v3b-finetune-reranker-improved.ipynb'
$targetPath = Join-Path $root 'Task 1\Code\v3_parallel\dsc2026-task1-v10-document-lambdarank.ipynb'

$nb = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8 | ConvertFrom-Json

# V10 token chunking phải có cache identity riêng; không bao giờ đọc nhầm shard của char chunker cũ.
$configSource = $nb.cells[3].source -join ''
$configSource = $configSource.Replace('CHUNK_CHARS        = 3000', 'CHUNK_CHARS        = 2048')
$configSource = $configSource.Replace('MAX_CHUNKS_PER_DOC = 2500', 'MAX_CHUNKS_PER_DOC = 5000')
$configSource = $configSource.Replace("CHUNKER_VER = 't1'", "CHUNKER_VER = 'tok512o64_v10mi'")
$nb.cells[3].source = @($configSource)

function New-MarkdownCell([string]$id, [string]$text) {
    [pscustomobject]@{
        cell_type = 'markdown'
        id = $id
        metadata = [pscustomobject]@{}
        source = @($text)
    }
}

function New-CodeCell([string]$id, [string]$text) {
    [pscustomobject]@{
        cell_type = 'code'
        execution_count = $null
        id = $id
        metadata = [pscustomobject]@{}
        outputs = @()
        source = @($text)
    }
}

$tokenChunkCell = New-CodeCell 'v10-token-chunker' @'
#@title Build token-aware legal chunks
import os, re, time
import pandas as pd
from transformers import AutoTokenizer

TOKEN_BODY_SIZE = 512
TOKEN_OVERLAP = 64
CHUNKS_REL = f'chunks_c{CHUNK_CHARS}{_CAPTAG}.parquet'
CHUNKS_PQ = f'{ART}/{CHUNKS_REL}'

# Chỉ dùng tokenizer của approved bi-encoder; không có model/dữ liệu ngoài nào được thêm.
TOKENIZER_PATH = (FT_BIENCODER_PATH
                  if FT_BIENCODER_PATH and os.path.isdir(FT_BIENCODER_PATH)
                  else BIENCODER)
CHUNK_TOKENIZER = AutoTokenizer.from_pretrained(
    TOKENIZER_PATH, use_fast=True, local_files_only=os.path.isdir(TOKENIZER_PATH))
print('tokenizer <-', TOKENIZER_PATH)
LEGAL_UNIT_RE = re.compile(
    r'(?im)(?=^(?:chương\s+[ivxlcdm\d]+|mục\s+\d+|điều\s+\d+[a-z]?)\s*[\.\:\-]?)')
ARTICLE_HEAD_RE = re.compile(r'(?im)^(điều\s+\d+[a-z]?[^\n]{0,180})')

def _token_windows(text, size=TOKEN_BODY_SIZE, overlap=TOKEN_OVERLAP):
    ids = CHUNK_TOKENIZER.encode(str(text), add_special_tokens=False)
    if not ids:
        return []
    out, start = [], 0
    while start < len(ids):
        end = min(start + size, len(ids))
        piece = CHUNK_TOKENIZER.decode(
            ids[start:end], skip_special_tokens=True,
            clean_up_tokenization_spaces=False).strip()
        if piece:
            out.append(piece)
        if end >= len(ids):
            break
        start = max(start + 1, end - overlap)
    return out

def chunk_doc(title, passage):
    passage = str(passage or '').strip()
    if not passage:
        return []
    units = [x.strip() for x in LEGAL_UNIT_RE.split(passage) if x.strip()]
    if not units:
        units = [passage]
    chunks = []
    for unit in units:
        m = ARTICLE_HEAD_RE.search(unit)
        heading = m.group(1).strip() if m else ''
        for j, window in enumerate(_token_windows(unit)):
            # Cửa sổ sau của một Điều vẫn giữ heading để cross-encoder biết vị trí pháp lý.
            if j and heading and not window.lower().startswith(heading.lower()):
                window = f'{heading}\n{window}'
            chunks.append(window)
    # View phần đầu chứa số hiệu/cơ quan/trích yếu; rất hữu ích cho query có citation.
    head = _token_windows(passage, TOKEN_BODY_SIZE, 0)
    if head:
        chunks.insert(0, head[0])
    chunks = list(dict.fromkeys(x for x in chunks if x.strip()))
    return chunks[:MAX_CHUNKS_PER_DOC]

def build_chunks(corpus):
    rows, n_titleonly = [], 0
    for n, r in enumerate(corpus.itertuples(index=False)):
        cs = chunk_doc(r.title, r.passage)
        if not cs:
            cs, n_titleonly = [''], n_titleonly + 1
        for c in cs:
            rows.append((r.doc_id, f'{r.title}. {c}'.strip()))
        if (n + 1) % 1000 == 0:
            print(f'  {n+1}/{len(corpus)} doc -> {len(rows)} token chunks', flush=True)
    print('title-only documents:', n_titleonly)
    df = pd.DataFrame(rows, columns=['doc_id', 'text'])
    df.to_parquet(CHUNKS_PQ, index=False)
    return df

t0 = time.time()
_cpq = cache_path(CHUNKS_REL)
if _cpq:
    chunks = pd.read_parquet(_cpq)
    print('load V10 token-chunk cache <-', _cpq)
else:
    chunks = build_chunks(corpus)
print('%d token chunks | %.1fs' % (len(chunks), time.time() - t0))

DOC_IDS = corpus.doc_id.tolist()
DOC2IX = {d: i for i, d in enumerate(DOC_IDS)}
import numpy as np
CHUNK2DOC = np.array([DOC2IX[d] for d in chunks.doc_id], dtype=np.int32)
print('chunk/doc mean: %.1f | body=%d tokens overlap=%d | cache=%s' %
      (len(chunks) / len(corpus), TOKEN_BODY_SIZE, TOKEN_OVERLAP, CHUNKS_REL))
chunks.text.str.len().describe()[['mean', '50%', 'max']]
'@
$nb.cells[10] = $tokenChunkCell

$nb.cells[0].source = @(@'
# DSC@UIT 2026 — Task 1: LegalIR — **V10 token-aware + multi-instance + LambdaRank**

V10 dùng đúng hai pretrained model đã có trong V3B:

- `AITeamVN/Vietnamese_Embedding_v2` (~0.6B)
- `AITeamVN/Vietnamese_Reranker` (~0.6B)

Tổng neural parameters khoảng 1.2B, dưới giới hạn 4B. LightGBM được train từ nhãn chính thức trong `train.json`; không dùng API, dữ liệu ngoài hoặc nhãn thủ công.

> **Compliance:** trước khi nộp chính thức, ghi cả hai checkpoint fine-tuned và LightGBM ranker vào Model Card/README; nếu biểu mẫu của BTC yêu cầu khai báo cả model cổ điển tự train thì phải bổ sung và chờ xác nhận. Notebook không tải dữ liệu hoặc model nào ngoài các input đã attach.

### Cách chạy Kaggle

1. Attach dữ liệu Task 1, scoring program và output Version 1 của notebook V3B.
2. Chọn 2×T4, để `RUN_PHASE=2`.
3. Run All. Mặc định `V10_BUILD_ONLY=False` chạy trọn gói. Nếu quota phiên ngắn, đặt `True` để chỉ tạo token cache + multi-instance checkpoint, Save Version, attach output đó rồi chạy lại với `False`.
4. V10 chấm candidate union bằng hai GPU, train LambdaRank trên CPU và chỉ bật V10 nếu qua untouched group gate.
5. Nếu gate không đạt, notebook không tạo ZIP mới; tiếp tục giữ submission V3B 0.9474.

### Thay đổi chính

- Candidate union: dense top-50 + BM25 top-10 + query-memory top-10.
- Token-aware legal chunking: 512-token body, 64-token overlap, giữ heading Điều.
- Multi-instance reranker: bag 4 chunk/document, train bằng document-level pairwise loss.
- Feature cấp document: dense, cross-encoder multi-chunk, BM25, query-memory, title/citation, document prior và độ dài.
- Calibration/gate được chia theo hash của normalized question; câu trùng chuẩn hóa luôn cùng phía.
- Exact-match override chỉ dùng các cặp trùng trong dữ liệu chính thức của BTC.
- Luôn xuất đúng 5 document ID duy nhất.
'@)

$v10Intro = New-MarkdownCell 'v10-intro' @'
---
## Stage 8D — V10 candidate union + document-level LambdaRank

V10 giữ nguyên dense encoder và checkpoint reranker đã được V3B chọn. Điểm mới là học cách phối hợp tín hiệu ở cấp **document** thay cho một trọng số RRF cố định.

Validation 1.000 câu được chia theo nhóm câu hỏi chuẩn hóa thành calibration và untouched gate. LambdaRank chỉ nhìn calibration khi quyết định có bật V10 hay không. Sau khi gate đạt, model production được fit lại trên toàn bộ 1.000 câu để tận dụng toàn bộ dữ liệu chính thức.
'@

$v10Base = New-CodeCell 'v10-base' @'
if RUN_PHASE == 2:
    #@title 8B.3 — Production baseline: chỉ load checkpoint-750, bỏ checkpoint/grid sweep cũ
    # V3B đã xác định checkpoint-750 + top30/m8/L768 + top2/RRF(1,3) là cấu hình thắng.
    # V10 khóa cấu hình này để tiết kiệm nhiều giờ T4, nhưng vẫn đo lại baseline trên đúng VAL_QIDS.
    load_query_model()
    V10_BASE_RERANKER = f'{FT_RERANKER_PATH}/checkpoint-750'
    assert os.path.isdir(V10_BASE_RERANKER), (
        'Không thấy checkpoint-750. Attach output Version 1 của notebook V3B rồi chạy RUN_PHASE=2.')
    RERANKER = V10_BASE_RERANKER
    RERANKERS.clear()
    BASE_CAND = dense_val
    V10_BASE_TAG = rerank_collect(
        VAL_QIDS, val_text, BASE_CAND, 30, 8, 768,
        tag='v10_baseline_checkpoint750_l768')
    BEST = {
        'tag': V10_BASE_TAG, 'pool': 'top2', 'tau': 0.5, 'lam': 0.2,
        'fuse': 'rrf', 'alpha': 0.0, 'wc': 1.0, 'wr': 3.0,
        'top': 30, 'm': 8, 'maxlen': 768,
    }
    best_preds = rank_from(
        V10_BASE_TAG, BASE_CAND, pool='top2', tau=0.5, lam=0.2,
        fuse='rrf', wc=1.0, wr=3.0)
    V10_BASE_METRIC = show('v10 frozen V3B baseline', best_preds)
    V10_KNOWN_OLD_VAL_RECALL = 0.9585
    V10_TOKEN_CHUNK_DELTA = (V10_BASE_METRIC['OFFICIAL_recall'] -
                             V10_KNOWN_OLD_VAL_RECALL)
    print('token-chunk delta vs known old V3B val:', round(V10_TOKEN_CHUNK_DELTA, 6))
    print('V10 baseline reranker ->', V10_BASE_RERANKER)
else:
    print('RUN_PHASE=1: train/cache V3B; V10 production chạy ở Version 2.')
'@

$v10MiIntro = New-MarkdownCell 'v10-mi-intro' @'
---
## Stage 8C — Multi-instance document-level reranker

Nhãn của Task 1 nằm ở cấp document, vì vậy V10 không ép một chunk bất kỳ của gold document thành toàn bộ supervision. Mỗi positive/negative document được biểu diễn bằng một bag gồm bốn chunk. Điểm document khả vi là `top1 + 0.2 × top2`; pairwise softplus loss buộc positive document đứng trên hard-negative document.

Hard negative được mine hoàn toàn từ dense + BM25 trên dữ liệu chính thức và được checkpoint-750 chấm. Model V10 bắt đầu từ checkpoint-750, không thêm pretrained model mới và thay thế checkpoint cũ khi inference nên tổng neural parameters vẫn khoảng 1.2B.
'@

$v10MiTrain = New-CodeCell 'v10-mi-train' @'
if RUN_PHASE == 2:
    #@title 8C.1 — Mine hard negatives và train document-bag reranker
    import gc, math, os, random, time
    import torch
    import torch.nn.functional as F
    from transformers import get_linear_schedule_with_warmup

    V10_MI_MODEL_REL = 'models/reranker-ft-v10-mi-token512'
    V10_MI_MODEL_LOCAL = f'{ART}/{V10_MI_MODEL_REL}'
    V10_MI_MODEL_CACHED = cache_path(V10_MI_MODEL_REL)
    if (V10_MI_MODEL_CACHED and
            not os.path.exists(f'{V10_MI_MODEL_CACHED}/config.json')):
        print('Bỏ qua multi-instance cache chưa hoàn chỉnh:', V10_MI_MODEL_CACHED)
        V10_MI_MODEL_CACHED = None
    V10_MI_MODEL_PATH = V10_MI_MODEL_CACHED or V10_MI_MODEL_LOCAL
    V10_MI_MINE_TOP = 20
    V10_MI_MINE_CHUNKS = 2
    V10_MI_BAG_CHUNKS = 4
    V10_MI_MAXLEN = 640
    V10_MI_STEPS = 3000
    V10_MI_ACCUM = 8
    V10_MI_LR = 2e-6
    V10_MI_POOL_LAMBDA = 0.2
    V10_BUILD_ONLY = False  #@param {type:'boolean'}
    V10_MI_TRAINED_NOW = False

    if V10_MI_MODEL_CACHED is None:
        print('V10 MI: mine candidates from official TRAIN_QIDS...', flush=True)
        _mi_qids = list(TRAIN_QIDS)
        _mi_texts = [QUESTIONS[q] for q in _mi_qids]
        _mi_dense = retrieve_dense(_mi_qids, _mi_texts)
        _mi_bm25 = retrieve_bm25(_mi_qids, _mi_texts)
        _mi_cand = {}
        for q in _mi_qids:
            xs = list(_mi_dense[q][:V10_MI_MINE_TOP]) + list(_mi_bm25[q][:5])
            _mi_cand[q] = list(dict.fromkeys(xs))

        # Base CE chỉ chấm hai chunk/doc để chọn false positive; bag train sau đó dùng bốn chunk.
        RERANKER = V10_BASE_RERANKER
        RERANKERS.clear()
        _mi_tag = rerank_collect(
            _mi_qids, _mi_texts, _mi_cand,
            V10_MI_MINE_TOP + 5, V10_MI_MINE_CHUNKS, V10_MI_MAXLEN,
            tag='v10_mine_checkpoint750_token512')

        _mi_pos_rep = select_chunks(
            _mi_qids, _mi_texts, {q: list(GOLD[q]) for q in _mi_qids},
            V10_MI_BAG_CHUNKS)

        # Lấy bốn chunk của các negative được chọn mà không cần cross-encode lần nữa.
        _mi_all_rep = select_chunks(
            _mi_qids, _mi_texts, _mi_cand, V10_MI_BAG_CHUNKS)
        _mi_records = []
        for q in _mi_qids:
            positives = [d for d in GOLD[q] if d in _mi_pos_rep[q]]
            scored = []
            for d in _mi_cand[q]:
                if d in GOLD[q] or d not in _mi_all_rep[q]:
                    continue
                s = RRC[_mi_tag][q].get(d, [])
                if s:
                    scored.append((pool_scores(s, 'top2', lam=V10_MI_POOL_LAMBDA), d))
            scored.sort(reverse=True)
            # Top false positives + một boundary candidate tạo curriculum thay vì chỉ một loại negative.
            negatives = [d for _, d in scored[:5]]
            boundary = [d for d in _mi_dense[q][4:12] if d not in GOLD[q] and d in _mi_all_rep[q]]
            for d in boundary:
                if d not in negatives:
                    negatives.append(d)
                if len(negatives) >= 7:
                    break
            if positives and negatives:
                _mi_records.append((q, positives, negatives))
        print('V10 MI training groups:', len(_mi_records))
        assert _mi_records, 'Không mine được multi-instance training groups.'

        # Nhả dense/query/reranker inference trước khi train trên một T4.
        free_dense()
        RERANKERS.clear()
        gc.collect()
        if torch.cuda.is_available():
            for _i in range(torch.cuda.device_count()):
                with torch.cuda.device(_i):
                    torch.cuda.empty_cache()

        from sentence_transformers import CrossEncoder
        _mi_ce = CrossEncoder(
            V10_BASE_RERANKER, num_labels=1,
            max_length=V10_MI_MAXLEN, device=DEV,
            activation_fn=torch.nn.Identity())
        _mi_net = _mi_ce.model
        _mi_tok = _mi_ce.tokenizer
        for p in _mi_net.get_input_embeddings().parameters():
            p.requires_grad_(False)
        if hasattr(_mi_net, 'gradient_checkpointing_enable'):
            _mi_net.gradient_checkpointing_enable(
                gradient_checkpointing_kwargs={'use_reentrant': False})
        _mi_net.train()

        _mi_opt = torch.optim.AdamW(
            [p for p in _mi_net.parameters() if p.requires_grad],
            lr=V10_MI_LR, weight_decay=0.01)
        _mi_rng = random.Random(SEED + 10)
        _mi_order = list(range(len(_mi_records)))
        _mi_rng.shuffle(_mi_order)
        _mi_steps = min(V10_MI_STEPS, len(_mi_order))
        _mi_updates = math.ceil(_mi_steps / V10_MI_ACCUM)
        _mi_sched = get_linear_schedule_with_warmup(
            _mi_opt, max(1, int(0.1 * _mi_updates)), _mi_updates)
        _mi_scaler = torch.cuda.amp.GradScaler(enabled=torch.cuda.is_available())

        def _mi_doc_score(query, chunk_indices):
            batch = _mi_tok(
                [query] * len(chunk_indices),
                [CHUNK_TEXTS[ci] for ci in chunk_indices],
                padding=True, truncation=True,
                max_length=V10_MI_MAXLEN, return_tensors='pt')
            batch = {k: v.to(DEV) for k, v in batch.items()}
            with torch.cuda.amp.autocast(enabled=torch.cuda.is_available()):
                logits = _mi_net(**batch).logits.reshape(-1).float()
                top = torch.topk(logits, k=min(2, len(logits))).values
                return top[0] + V10_MI_POOL_LAMBDA * (top[1] if len(top) > 1 else top[0])

        _mi_opt.zero_grad(set_to_none=True)
        _mi_loss_sum, _mi_t0 = 0.0, time.time()
        for step, ix in enumerate(_mi_order[:_mi_steps], 1):
            q, positives, negatives = _mi_records[ix]
            pd = _mi_rng.choice(positives)
            # Luân phiên false-positive rất khó và boundary negative để tránh overfit một kiểu lỗi.
            nd = negatives[(step - 1) % len(negatives)]
            pchunks = [ci for ci, _ in _mi_pos_rep[q][pd]][:V10_MI_BAG_CHUNKS]
            nchunks = [ci for ci, _ in _mi_all_rep[q][nd]][:V10_MI_BAG_CHUNKS]
            with torch.cuda.amp.autocast(enabled=torch.cuda.is_available()):
                ps = _mi_doc_score(QUESTIONS[q], pchunks)
                ns = _mi_doc_score(QUESTIONS[q], nchunks)
                loss = F.softplus(ns - ps) / V10_MI_ACCUM
            _mi_scaler.scale(loss).backward()
            _mi_loss_sum += float(loss.detach()) * V10_MI_ACCUM
            if step % V10_MI_ACCUM == 0 or step == _mi_steps:
                _mi_scaler.unscale_(_mi_opt)
                torch.nn.utils.clip_grad_norm_(_mi_net.parameters(), 1.0)
                _mi_scaler.step(_mi_opt)
                _mi_scaler.update()
                _mi_sched.step()
                _mi_opt.zero_grad(set_to_none=True)
            if step % 250 == 0:
                print('MI step %d/%d | mean loss %.4f | %.1f min' %
                      (step, _mi_steps, _mi_loss_sum / step,
                       (time.time() - _mi_t0) / 60), flush=True)

        os.makedirs(V10_MI_MODEL_LOCAL, exist_ok=True)
        _mi_ce.save_pretrained(V10_MI_MODEL_LOCAL)
        V10_MI_MODEL_PATH = V10_MI_MODEL_LOCAL
        V10_MI_TRAINED_NOW = True
        print('V10 multi-instance model ->', V10_MI_MODEL_PATH)
        del _mi_ce, _mi_net, _mi_opt, _mi_sched, _mi_scaler
        del _mi_pos_rep, _mi_all_rep, _mi_records
        gc.collect()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        load_query_model()
    else:
        print('V10 multi-instance cache <-', V10_MI_MODEL_PATH)

    assert os.path.exists(f'{V10_MI_MODEL_PATH}/config.json')
    RERANKER = V10_MI_MODEL_PATH
    RERANKERS.clear()
else:
    V10_MI_MODEL_PATH = None
    print('RUN_PHASE=1: bỏ qua V10 multi-instance training.')
'@

$v10Setup = New-CodeCell 'v10-setup' @'
if RUN_PHASE == 2 and not V10_BUILD_ONLY:
    #@title 8D.1 — Split theo nhóm + query memory + candidate union
    import hashlib, re, unicodedata
    from collections import Counter, defaultdict

    V10_DENSE_TOP = 50
    V10_BM25_TOP = 10
    V10_QMEM_TOP = 10
    V10_QMEM_K = 32
    V10_RERANK_TOP = V10_DENSE_TOP + V10_BM25_TOP + V10_QMEM_TOP
    V10_CHUNKS_PER_DOC = 8
    V10_MAXLEN = 640
    V10_MIN_GATE_GAIN = 0.0020
    V10_MIN_GATE_P = 0.75
    V10_MAX_UNSEEN_DROP = 0.0030
    V10_MIN_ESTIMATED_GAIN_VS_OLD = 0.0010

    def v10_norm_question(s):
        s = unicodedata.normalize('NFC', str(s)).lower()
        return re.sub(r'\s+', ' ', s).strip()

    # Hash normalized question: duplicate/near-exact normalized strings không thể rơi khác phía.
    V10_RANK_QIDS, V10_GATE_QIDS = [], []
    for q in VAL_QIDS:
        h = int(hashlib.sha256(v10_norm_question(QUESTIONS[q]).encode('utf-8')).hexdigest()[:8], 16)
        (V10_RANK_QIDS if h % 5 < 3 else V10_GATE_QIDS).append(q)
    assert V10_RANK_QIDS and V10_GATE_QIDS
    assert not ({v10_norm_question(QUESTIONS[q]) for q in V10_RANK_QIDS} &
                {v10_norm_question(QUESTIONS[q]) for q in V10_GATE_QIDS})
    print('V10 split: rank-train=%d | untouched-gate=%d' %
          (len(V10_RANK_QIDS), len(V10_GATE_QIDS)))

    # Memory chỉ lấy TRAIN_QIDS mà reranker đã dùng; validation vẫn out-of-sample.
    V10_MEM_QIDS = list(TRAIN_QIDS)
    V10_MEM_GOLD = [list(GOLD[q]) for q in V10_MEM_QIDS]
    V10_MEM_NORM = [v10_norm_question(QUESTIONS[q]) for q in V10_MEM_QIDS]
    V10_MEM_EMB = qmodel.encode(
        format_dense_queries([QUESTIONS[q] for q in V10_MEM_QIDS]),
        batch_size=64, normalize_embeddings=True, convert_to_tensor=True,
        show_progress_bar=True).to(DEV)
    if V10_MEM_EMB.dtype == torch.float32 and DEV.startswith('cuda'):
        V10_MEM_EMB = V10_MEM_EMB.half()

    def v10_qmemory(qids, qtexts, exclude_exact=False, batch=64):
        out = {}
        qids, qtexts = list(qids), list(qtexts)
        for i0 in range(0, len(qtexts), batch):
            qb = qtexts[i0:i0 + batch]
            qv = qmodel.encode(
                format_dense_queries(qb), batch_size=batch,
                normalize_embeddings=True, convert_to_tensor=True,
                show_progress_bar=False).to(V10_MEM_EMB.dtype)
            search_k = min(V10_QMEM_K + (16 if exclude_exact else 0), len(V10_MEM_QIDS))
            vals, inds = torch.topk(qv @ V10_MEM_EMB.T, k=search_k, dim=1)
            for q, qt, vv, ii in zip(qids[i0:i0 + batch], qb,
                                     vals.float().cpu().numpy(), inds.cpu().numpy()):
                per = defaultdict(lambda: [0.0, 0.0])
                used = 0
                for sim, j in zip(vv, ii):
                    j = int(j)
                    if exclude_exact and V10_MEM_NORM[j] == v10_norm_question(qt):
                        continue
                    rank = used
                    used += 1
                    for d in V10_MEM_GOLD[j]:
                        per[d][0] = max(per[d][0], float(sim))
                        per[d][1] += 1.0 / (rank + 1.0)
                    if used >= V10_QMEM_K:
                        break
                out[q] = dict(per)
        return out

    def v10_candidate_union(qids, dense, bm25, qmem):
        out = {}
        for q in qids:
            qm = sorted(qmem[q], key=lambda d: (qmem[q][d][0], qmem[q][d][1]), reverse=True)
            xs = list(dense[q][:V10_DENSE_TOP])
            xs += list(bm25[q][:V10_BM25_TOP])
            xs += qm[:V10_QMEM_TOP]
            out[q] = list(dict.fromkeys(xs))
        return out

    V10_VAL_QMEM = v10_qmemory(VAL_QIDS, val_text, exclude_exact=True)
    V10_VAL_CAND = v10_candidate_union(VAL_QIDS, dense_val, bm25_val, V10_VAL_QMEM)
    V10_CAND_RECALL = np.mean([
        len(GOLD[q] & set(V10_VAL_CAND[q])) / len(GOLD[q]) for q in VAL_QIDS
    ])
    print('V10 candidate recall=%.4f | mean=%.1f | max=%d' % (
        V10_CAND_RECALL,
        np.mean([len(x) for x in V10_VAL_CAND.values()]),
        max(map(len, V10_VAL_CAND.values()))))
else:
    print('Bỏ V10 rank setup (RUN_PHASE=1 hoặc V10_BUILD_ONLY=True).')
'@

$v10Score = New-CodeCell 'v10-score' @'
if RUN_PHASE == 2 and not V10_BUILD_ONLY:
    #@title 8D.2 — Chấm toàn bộ candidate union bằng multi-instance reranker trên 2×T4
    # RERANKER/BEST đã được Stage 8B.3 chọn. Chấm mọi nguồn trong union, không nối candidate
    # BM25/query-memory vào cuối mà chưa qua cross-encoder.
    V10_RERANKER = RERANKER
    RERANKERS.clear()
    V10_VAL_TAG = rerank_collect(
        VAL_QIDS, val_text, V10_VAL_CAND,
        V10_RERANK_TOP, V10_CHUNKS_PER_DOC, V10_MAXLEN,
        tag='v10_val_union_multiinstance_l640')
    print('V10 reranker:', V10_RERANKER)
else:
    print('Bỏ V10 union scoring (RUN_PHASE=1 hoặc V10_BUILD_ONLY=True).')
'@

$v10Ranker = New-CodeCell 'v10-ranker' @'
if RUN_PHASE == 2 and not V10_BUILD_ONLY:
    #@title 8D.3 — Feature cấp document, LambdaRank, untouched safety gate
    import math, pickle
    try:
        from lightgbm import LGBMRanker
    except ImportError as e:
        raise ImportError('Kaggle image cần package lightgbm. Hãy Add Input wheel lightgbm '
                          'do đội chuẩn bị sẵn; notebook không tự tải gì từ Internet.') from e

    V10_TITLE = dict(zip(corpus.doc_id, corpus.title))
    V10_DOC_PRIOR = Counter(d for q in TRAIN_QIDS for d in GOLD[q])
    V10_DOC_NCHUNK = {d: int(_npd[DOC2IX[d]]) for d in DOC_IDS}

    _word_re = re.compile(r'(?u)\b\w+\b')
    _docnum_re = re.compile(r'\b\d{1,4}\s*/\s*\d{4}\s*/[a-zđ\-]+\b', re.I)
    _article_re = re.compile(r'\b(?:điều|khoản|điểm)\s+\d+[a-z]?\b', re.I)
    _legal_types = ('luật', 'nghị định', 'thông tư', 'quyết định', 'nghị quyết', 'bộ luật')

    def _tokens(s):
        return set(_word_re.findall(v10_norm_question(s)))

    def _legal_matches(qtext, title):
        qn, tn = v10_norm_question(qtext), v10_norm_question(title)
        qnums, tnums = set(_docnum_re.findall(qn)), set(_docnum_re.findall(tn))
        qarts, tarts = set(_article_re.findall(qn)), set(_article_re.findall(tn))
        type_match = sum(int(x in qn and x in tn) for x in _legal_types)
        return float(bool(qnums & tnums)), float(bool(qarts & tarts)), float(type_match)

    V10_FEATURE_NAMES = [
        'dense_rank', 'bm25_rank', 'qmem_rank', 'ce_rank',
        'dense_score', 'ce_max', 'ce_top2', 'ce_mean3', 'ce_std', 'ce_n_high',
        'qmem_sim', 'qmem_vote', 'source_count',
        'title_jaccard', 'doc_number_match', 'article_match', 'legal_type_match',
        'log_doc_prior', 'log_chunk_count'
    ]

    def v10_make_features(qids, qtexts, cand, dense, bm25, qmem, tag, with_labels=True):
        X, y, groups, refs = [], [], [], []
        for q, qt in zip(qids, qtexts):
            docs = list(cand[q])
            dr = {d: i + 1 for i, d in enumerate(dense[q])}
            br = {d: i + 1 for i, d in enumerate(bm25[q])}
            qm_order = sorted(qmem[q], key=lambda d: (qmem[q][d][0], qmem[q][d][1]), reverse=True)
            qr = {d: i + 1 for i, d in enumerate(qm_order)}
            pooled = {d: pool_scores(RRC[tag][q].get(d, []), 'top2', lam=0.2) for d in docs}
            ce_order = sorted(docs, key=lambda d: -pooled[d])
            cr = {d: i + 1 for i, d in enumerate(ce_order)}
            qtok = _tokens(qt)
            for d in docs:
                scores = np.sort(np.asarray(RRC[tag][q].get(d, [-20.0]), dtype=float))[::-1]
                top1 = float(scores[0])
                top2 = float(scores[1] if len(scores) > 1 else scores[0])
                mean3 = float(scores[:3].mean())
                title = V10_TITLE.get(d, '') or ''
                ttok = _tokens(title)
                jac = len(qtok & ttok) / max(1, len(qtok | ttok))
                dm, am, tm = _legal_matches(qt, title)
                qm = qmem[q].get(d, (0.0, 0.0))
                source_count = int(d in dr and dr[d] <= V10_DENSE_TOP)
                source_count += int(d in br and br[d] <= V10_BM25_TOP)
                source_count += int(d in qr and qr[d] <= V10_QMEM_TOP)
                row = [
                    min(dr.get(d, 1001), 1001), min(br.get(d, 1001), 1001),
                    min(qr.get(d, 1001), 1001), cr[d],
                    float(RRC_DENSE[tag][q].get(d, -1.0)), top1,
                    top1 + 0.2 * top2, mean3, float(scores.std()),
                    float((scores > 0).sum()), float(qm[0]), float(qm[1]),
                    float(source_count), float(jac), dm, am, tm,
                    math.log1p(V10_DOC_PRIOR.get(d, 0)),
                    math.log1p(V10_DOC_NCHUNK.get(d, 0))
                ]
                X.append(row)
                if with_labels:
                    y.append(int(d in GOLD[q]))
                refs.append((q, d))
            groups.append(len(docs))
        return np.asarray(X, np.float32), np.asarray(y, np.int8), groups, refs

    def v10_fit_ranker(qids):
        qtexts = [QUESTIONS[q] for q in qids]
        X, y, groups, _ = v10_make_features(
            qids, qtexts, V10_VAL_CAND, dense_val, bm25_val,
            V10_VAL_QMEM, V10_VAL_TAG, with_labels=True)
        model = LGBMRanker(
            objective='lambdarank', metric='ndcg', eval_at=[5],
            n_estimators=300, learning_rate=0.03, num_leaves=15,
            min_child_samples=30, subsample=0.90, colsample_bytree=0.90,
            reg_lambda=2.0, random_state=SEED, n_jobs=-1, verbosity=-1)
        model.fit(X, y, group=groups)
        return model

    def v10_predict(model, qids, qtexts, cand, dense, bm25, qmem, tag):
        X, _, groups, refs = v10_make_features(
            qids, qtexts, cand, dense, bm25, qmem, tag, with_labels=False)
        score = model.predict(X)
        out, offset = {}, 0
        for q, n in zip(qids, groups):
            pairs = [(refs[offset + j][1], float(score[offset + j]), j) for j in range(n)]
            out[q] = [d for d, _, _ in sorted(pairs, key=lambda z: (-z[1], z[2]))]
            offset += n
        assert offset == len(refs)
        return out

    V10_GATE_MODEL = v10_fit_ranker(V10_RANK_QIDS)
    V10_GATE_PREDS_ALL = v10_predict(
        V10_GATE_MODEL, VAL_QIDS, val_text, V10_VAL_CAND,
        dense_val, bm25_val, V10_VAL_QMEM, V10_VAL_TAG)
    _gate_gold = {q: GOLD[q] for q in V10_GATE_QIDS}
    V10_GATE = compare(
        'v10 LambdaRank', {q: V10_GATE_PREDS_ALL[q] for q in V10_GATE_QIDS},
        'v3b checkpoint750', {q: best_preds[q] for q in V10_GATE_QIDS},
        gold=_gate_gold)
    show('v10 gate', {q: V10_GATE_PREDS_ALL[q] for q in V10_GATE_QIDS}, gold=_gate_gold)

    # Stress audit: gold document chưa từng có trong TRAIN_QIDS hoặc rank-train split.
    # Đây là nhóm gần với domain shift/private hơn và ngăn document-prior thắng nhờ memorization.
    _seen_gold_docs = set().union(*(GOLD[q] for q in (list(TRAIN_QIDS) + list(V10_RANK_QIDS))))
    V10_UNSEEN_QIDS = [q for q in V10_GATE_QIDS if GOLD[q].isdisjoint(_seen_gold_docs)]
    if V10_UNSEEN_QIDS:
        _unseen_gold = {q: GOLD[q] for q in V10_UNSEEN_QIDS}
        V10_UNSEEN = compare(
            'v10 unseen-doc', {q: V10_GATE_PREDS_ALL[q] for q in V10_UNSEEN_QIDS},
            'v3b unseen-doc', {q: best_preds[q] for q in V10_UNSEEN_QIDS},
            gold=_unseen_gold)
        print('unseen-document stress queries:', len(V10_UNSEEN_QIDS))
        V10_UNSEEN_OK = V10_UNSEEN['delta'] >= -V10_MAX_UNSEEN_DROP
    else:
        V10_UNSEEN_OK = True
        print('Không có unseen-document query trong gate; bỏ điều kiện stress audit.')

    # Gate delta đo phần MI+LambdaRank trên token chunks. Cộng delta token chunk toàn-val
    # để không chấp nhận một pipeline mới chỉ thắng baseline token nhưng vẫn thua V3B cũ.
    V10_ESTIMATED_GAIN_VS_OLD = V10_GATE['delta'] + V10_TOKEN_CHUNK_DELTA
    V10_ENABLED = (V10_GATE['delta'] >= V10_MIN_GATE_GAIN and
                   V10_GATE['p_better'] >= V10_MIN_GATE_P and
                   V10_UNSEEN_OK and
                   V10_ESTIMATED_GAIN_VS_OLD >= V10_MIN_ESTIMATED_GAIN_VS_OLD)
    print('V10_ENABLED =', V10_ENABLED,
          '| requires gate gain >=', V10_MIN_GATE_GAIN,
          'P(gain>0) >=', V10_MIN_GATE_P,
          'unseen drop <=', V10_MAX_UNSEEN_DROP,
          'estimated gain vs old >=', V10_MIN_ESTIMATED_GAIN_VS_OLD)
    print('estimated gain vs old V3B:', round(V10_ESTIMATED_GAIN_VS_OLD, 6))

    if V10_ENABLED:
        # Thiết kế đã qua untouched gate: fit production ranker bằng toàn bộ 1.000 val labels.
        V10_MODEL = v10_fit_ranker(VAL_QIDS)
        _imp = sorted(zip(V10_FEATURE_NAMES, V10_MODEL.feature_importances_),
                      key=lambda z: -z[1])
        print('feature importance:', _imp)
        with open(f'{ART}/v10_lambdarank.pkl', 'wb') as f:
            pickle.dump({'model': V10_MODEL, 'features': V10_FEATURE_NAMES}, f)
    else:
        V10_MODEL = None
        print('Gate không đạt: KHÔNG tạo submission V10; tiếp tục dùng ZIP V3B 0.9474 hiện có.')
else:
    V10_ENABLED, V10_MODEL = False, None
'@

$stage9 = New-MarkdownCell 'v10-stage9' @'
---
## Stage 9 — Public inference, exact-match override và đóng gói

Nếu V10 không qua gate, đường public tự động quay về V3B checkpoint-750. Không bao giờ xuất quá 5 ID.
'@

$publicCell = New-CodeCell 'v10-public' @'
if RUN_PHASE == 2 and not V10_BUILD_ONLY:
    #@title 9.1 — Public inference
    import time

    def v10_baseline_pipeline(qids, qtexts):
        d = retrieve_dense(qids, qtexts)
        tag = 'v10_public_fallback_checkpoint750'
        RERANKERS.clear()
        rerank_collect(qids, qtexts, d, BEST['top'], BEST['m'], BEST['maxlen'], tag=tag)
        return rank_from(tag, d, BEST['pool'], BEST['tau'], BEST['lam'],
                         BEST['fuse'], BEST['alpha'], BEST['wc'], BEST['wr'])

    pub_qids = list(PUBLIC)
    pub_text = [PUBLIC[q] for q in pub_qids]
    t0 = time.time()
    if V10_ENABLED:
        V10_PUB_DENSE = retrieve_dense(pub_qids, pub_text)
        V10_PUB_BM25 = retrieve_bm25(pub_qids, pub_text)
        V10_PUB_QMEM = v10_qmemory(pub_qids, pub_text, exclude_exact=False)
        V10_PUB_CAND = v10_candidate_union(
            pub_qids, V10_PUB_DENSE, V10_PUB_BM25, V10_PUB_QMEM)
        V10_PUB_TAG = rerank_collect(
            pub_qids, pub_text, V10_PUB_CAND,
            V10_RERANK_TOP, V10_CHUNKS_PER_DOC, V10_MAXLEN,
            tag='v10_public_union_multiinstance_l640')
        pub_preds = v10_predict(
            V10_MODEL, pub_qids, pub_text, V10_PUB_CAND,
            V10_PUB_DENSE, V10_PUB_BM25, V10_PUB_QMEM, V10_PUB_TAG)
        route = 'V10 LambdaRank'
        print(route, '| %d câu | %.1f phút' %
              (len(pub_qids), (time.time() - t0) / 60))
    else:
        pub_preds = None
        print('V10 bị safety gate từ chối; bỏ public inference và giữ submission V3B hiện có.')
else:
    print('RUN_PHASE=1: public inference thuộc Version 2.')
'@

$exactCell = New-CodeCell 'v10-exact' @'
if RUN_PHASE == 2 and not V10_BUILD_ONLY and V10_ENABLED:
    #@title 9.2 — Exact-match override, chỉ từ train chính thức của BTC
    from collections import defaultdict
    memory_sets = defaultdict(set)
    for item in train_raw.values():
        key = v10_norm_question(item['question'])
        memory_sets[key].add(tuple(sorted(set(map(str, item['answer'])))))
    memory = {
        key: list(next(iter(sets)))
        for key, sets in memory_sets.items()
        if len(sets) == 1 and 0 < len(next(iter(sets))) <= TOPK_SUBMIT
    }
    overridden = 0
    for q in pub_qids:
        known = memory.get(v10_norm_question(PUBLIC[q]), [])
        if known:
            old = list(map(str, pub_preds[q]))
            pub_preds[q] = known + [d for d in old if d not in set(known)]
            overridden += 1
    print('exact-match Public override:', overridden)
    assert overridden == 5, 'Expected exactly five organizer-provided Public duplicates'
elif RUN_PHASE == 2:
    print('Bỏ exact override vì V10 không qua gate và không tạo submission mới.')
'@

$zipCell = New-CodeCell 'v10-zip' @'
if RUN_PHASE == 2 and not V10_BUILD_ONLY and V10_ENABLED:
    #@title 9.3 — Validate bằng contract BTC + tạo ZIP
    import collections, json, os, zipfile

    def build_submission(preds, all_qids, corpus_ids):
        sub, filler = {}, [str(d) for d in DOC_IDS[:TOPK_SUBMIT]]
        for q in all_qids:
            ids, seen = [], set()
            for d in preds.get(q, []):
                d = str(d)
                if d not in seen and d in corpus_ids:
                    seen.add(d); ids.append(d)
                if len(ids) == TOPK_SUBMIT:
                    break
            for d in filler:
                if len(ids) == TOPK_SUBMIT:
                    break
                if d not in seen:
                    seen.add(d); ids.append(d)
            sub[q] = {'answer': ids}
        return sub

    def validate_submission(sub, all_qids, corpus_ids):
        errs = []
        if set(sub) != set(all_qids):
            errs.append('Question ID set không khớp public-official.json')
        for q, item in sub.items():
            a = item.get('answer')
            if not isinstance(a, list):
                errs.append(f'{q}: answer không phải list'); continue
            if len(a) != TOPK_SUBMIT:
                errs.append(f'{q}: phải có đúng {TOPK_SUBMIT} ID, hiện có {len(a)}')
            if len(a) != len(set(a)):
                errs.append(f'{q}: ID trùng')
            if any(not isinstance(d, str) for d in a):
                errs.append(f'{q}: ID không phải string')
            if any(d not in corpus_ids for d in a):
                errs.append(f'{q}: ID không tồn tại trong corpus')
        return errs

    corpus_ids = set(map(str, corpus.doc_id))
    sub = build_submission(pub_preds, list(PUBLIC), corpus_ids)
    errs = validate_submission(sub, list(PUBLIC), corpus_ids)
    assert not errs, '\n'.join(errs[:20])

    SUB_DIR = '/kaggle/working' if ON_KAGGLE else ART
    out_json = f'{SUB_DIR}/submission.json'
    out_zip = f'{SUB_DIR}/submission_v10_document_lambdarank.zip'
    with open(out_json, 'w', encoding='utf-8') as f:
        json.dump(sub, f, ensure_ascii=False)
    with zipfile.ZipFile(out_zip, 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(out_json, arcname='submission.json')
    with zipfile.ZipFile(out_zip) as z:
        assert z.namelist() == ['submission.json']
    print('OK ->', out_zip, '(%.0f KB)' % (os.path.getsize(out_zip) / 1e3))
    print('route: V10 token-aware + multi-instance + LambdaRank')
    print('phân bố số ID:', collections.Counter(len(v['answer']) for v in sub.values()))
elif RUN_PHASE == 2:
    print('Không tạo ZIP V10 vì safety gate không đạt. Dùng submission V3B 0.9474 hiện có.')
'@

$tail = @()
$tail += $v10Base
$tail += $v10MiIntro
$tail += $v10MiTrain
$tail += $v10Intro
$tail += $v10Setup
$tail += $v10Score
$tail += $v10Ranker
$tail += $stage9
$tail += $publicCell
$tail += $exactCell
$tail += $zipCell

# Giữ V3B đến hết cell load checkpoint (index 34). Bỏ checkpoint-600 và sweep 180 cấu hình
# đã hoàn tất ở notebook cũ; thay bằng baseline production gọn + V10.
$nb.cells = @($nb.cells[0..34]) + $tail
$nb.metadata | Add-Member -NotePropertyName v10 -NotePropertyValue ([pscustomobject]@{
    base_notebook = 'dsc2026-task1-v3b-finetune-reranker-improved.ipynb'
    compliance = 'official data only; no API; no manual labels; ~1.2B neural parameters'
    generated_by = 'scripts/build_task1_v10_notebook.ps1'
}) -Force

$json = $nb | ConvertTo-Json -Depth 100 -Compress
[System.IO.File]::WriteAllText($targetPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Output "Generated: $targetPath"


