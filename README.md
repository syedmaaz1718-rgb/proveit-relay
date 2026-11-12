# The Relay (ProveIt take-home) - development source

Status: dev tree, current as of 2026-11-12 (re-freeze #12; RECOVERY_STATUS.md is a labelled historical snapshot of the Nov 10-11 recovery, not current state). Real quality numbers come only from the graded runs in `evidence_runs/` and `report/results.csv`; nothing here claims unmeasured quality. Pack-coverage measurements (offline source review, offline/source_coverage_review.json) are not answer correctness. Provider mid-stream errors surface as explicit provider_error results (never silent, never relabelled refusals); a failed audit can re-attach claims to a better same-paper span exactly once (tests/test_provider_error_reattach.py).

## What it is
A question-answering service over three papers (Attention Is All You Need, Moshi, Dynamic Chunking). Pipeline: intake (bounded queue / fail-fast) -> retrieve (BM25 over page-aware chunks, `offline/toc_index`) -> evidence draft (JSON claims citing span IDs) -> ID check -> audit call -> cited answer or honest refusal. Governor, 429 retry/backoff, daily-budget degradation (retrieval-only cards, no model call) and an end-to-end deadline apply to the evidence path via `Pipeline.handle_evidence` (tests/test_handle_evidence.py).

## Requirements
Python 3, `pip install -r requirements.txt` (tiktoken for token counts, PyMuPDF only for rebuilding the PDF-outline index). Report PDF: reportlab.

## Run
- Offline UI preview (no model): `RELAY_DATA=<fresh scratch dir with data/chunks_*.jsonl> python3 src/standin.py` and `python3 src/console.py`, open http://127.0.0.1:8420. Evidence mode only replays recorded real answers (ui/replay.json) under a REPLAY badge. The stand-in server is dev-only load simulation and is never shown as a model.
- Live (needs your own free-tier Groq key in a file, never in source): `GROQ_KEY_FILE=/path/to/keyfile python3 src/console.py`. It uses a scratch copy of `offline/toc_index`. The live UI/service path (`Pipeline.handle_evidence`) ran against the real provider on 2026-11-12 (3 questions, 6 calls: 2 correct cited answers, 1 safe refusal; evidence_runs/real_ui_route_2026-11-12); unit/integration coverage is tests/test_handle_evidence.py and tests/test_e2e_standin.py.
- Variants (env, default off): `RELAY_PACK=hybrid`, `RELAY_DECOMP=model|entity`, `RELAY_TITLE_BOOST`, `RELAY_INPUT_CAP`. Defaults are the frozen retest configuration (`report/FROZEN_RETEST_HASHES.txt`).

## Tests (all offline, no network)
```
python3 tests/test_decompose.py
python3 tests/test_hybrid_pack.py
python3 tests/test_evidence_answer.py
python3 tests/test_handle_evidence.py
python3 tests/test_e2e_standin.py
python3 tests/test_json_repair.py
python3 tests/test_provider_error_reattach.py
python3 tests/test_benchmark_aggregate.py
python3 tests/deadline_regression.py
```
All nine pass as of 2026-11-12 (re-freeze #12).

## Report
`cd report && python3 ../offline/make_tables.py` rebuilds tables.md from `results.csv`; `python3 typeset_report.py <font>` writes the 2-page draft PDF (last build: font 7.8; lower the size if it overflows 2 pages). Grades come only from source review via the fixed `report/GRADING_RUBRIC.md`.

## Hosted demo deployment (Render)

`render_start.sh` + `deploy/` are deploy-only glue; the project code is unchanged.

- The gate (`deploy/http_gate.py`) is the only public listener. Both consoles stay on loopback.
- Default (no code): the demo console replays recorded real answers (REPLAY badge) and runs the labelled stand-in Relay Lab. No model key is present.
- With `GROQ_API_KEY` set in the host environment, a second console runs the real model on loopback. It is reachable only with a valid access code (`https://<host>/?code=...`, which sets an HttpOnly cookie). Model-calling requests on the live route are capped per-IP and globally per UTC day (persisted to disk).
- Build: `cat payload.b64.* | base64 -d | tar xz && pip install -r requirements.txt`  Start: `bash render_start.sh`
