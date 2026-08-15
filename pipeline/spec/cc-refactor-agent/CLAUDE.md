# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Project overview

cc_agent runs Lean 4 proof golfing with Claude Code. `scripts/run_golf.py` reads an eval JSONL of
theorems, `scripts/preprocessor.py` copies each theorem's source file to a per-task temp `.lean`
file (parallel-safe), and `scripts/runner.py` launches one `claude -p` session per theorem that
shortens the proof while keeping the file compiling. `tools/check_proof.py` is the scoring tool the
agent calls; per-task artifacts and an aggregate `summary.json` land under `--output-dir`.

## Commands

```bash
source .venv/bin/activate

bash setup.sh                                   # one-time: lean4-skills plugin, lean-lsp MCP, uv sync
python -m scripts.run_golf setup-project        # lake exe cache get + lake build for each workspace/ project
python -m scripts.run_golf cleanup --project-root workspace/<project>   # remove leftover temp .lean files
```

There is no test suite in this repo.

Main run (retrieval + skills, Haiku, 15 workers, per-task budgets). `price.jsonl` is not shipped —
supply your own or drop `--price-jsonl`:

```bash
python -m scripts.run_golf run \
  --project-root workspace/putnam2025 \
  --output-dir results/putnam2025_with_retrieval_with_skill \
  --enable-retrieval true \
  --service-url http://127.0.0.1:8010/retrieve \
  --price-jsonl workspace/putnam2025/price.jsonl \
  --model haiku \
  --parallel \
  --max-workers 15 \
  --max-turns 99999999 \
  2>&1 | tee putnam2025_with_skill_with_retrieval.log
```

Flags and defaults: `--jsonl-file` (else auto-discovers `<project-root>/eval/eval_<folder>.jsonl`),
`--output-dir results/golf`, `--max-turns 20`, `--timeout-minutes 120` (`0` = unlimited),
`--parallel false --max-workers 1`, `--model` (`opus`/`sonnet`/`haiku` aliases or full ID),
`--effort low|medium|high|max`, `--no-skills`, `--filter-name`, `--max-tasks`, `--cleanup true`.

Retrieval service (start before `--enable-retrieval`; the runner health-checks `/health` first):

```bash
python scripts/retrieval_service.py --model-path <ckpt> --index-path <faiss> \
  --metadata-path <meta.json> --port 8010 --cuda-visible-devices 1
```

Post-run verification (independent of the agent's own compile checks):

```bash
.venv/bin/python -m scripts.verify_lean_client_results \
  --results-dir results/<run> --problems-jsonl workspace/<proj>/eval/eval_<proj>.jsonl \
  --workspace-path workspace/<proj> --output-path results/<run>/verify_report.jsonl \
  --max-concurrent-requests 5
```

## Architecture

### Execution flow

1. **Load** — `load_tasks()` parses the eval JSONL into `GolfTaskMetadata` (paths, model, effort,
   retrieval settings).
2. **Resume** — `prepare_tasks_for_resume()` keeps task dirs whose `result.json` has
   `success: true`; every other task dir is deleted and re-prepared from the original source.
   `summary.json` is removed and rebuilt at the end.
3. **Prepare** — copy the original `.lean` to `<stem>_<sanitized_name>.lean` (same directory, so
   Lake resolves imports), seed `best_proof.txt`, `current_proof.txt`, and `progress.jsonl`
   (attempt 0 = original proof).
4. **Launch** — `claude -p --verbose --output-format stream-json --permission-mode bypassPermissions
   --max-turns N [--model] [--effort] [--max-budget-usd]`, cwd = project root, stream saved to
   `claude_raw.jsonl`. Agent loop: read best proof → edit temp file → `lean_diagnostic_messages`
   (severity 1) → write full theorem+proof to `current_proof.txt` → `check_proof.py` → keep or revert.
   Retrieval mode adds a `retrieve_examples.py` query before/after each attempt.
5. **Collect** — success = best recorded length < initial length; cost and token usage come from the
   final `type: "result"` line. Parallelism is a `ThreadPoolExecutor`; SIGINT/SIGTERM kills all live
   Claude subprocesses.
6. **Cleanup** — delete temp `.lean` files, write `summary.json`.

### Prompt selection (`runner.build_prompt`)

`enable_retrieval` → `prompts/prompt_golf_with_retrieval_tool.txt`; else `no_skills` →
`prompt_golf_no_skill.txt`; else `prompt_golf.txt`. **Only the retrieval template exists in this
checkout** — the other two paths raise `FileNotFoundError`, so runs must pass `--enable-retrieval
true` until those templates are restored. In `--no-skills` mode the runner shells out to
`claude plugin list` and raises if any lean4 plugin is still enabled — disable it with
`claude plugin disable lean4@lean4-skills`.

### Key files

- `scripts/run_golf.py` — Fire CLI (`run`, `setup-project`, `cleanup`), retrieval health check,
  price-map loading, resume orchestration, `summary.json`
- `scripts/runner.py` — prompt building, `claude -p` invocation, usage parsing, parallel execution,
  summary table
- `scripts/preprocessor.py` — JSONL loading, temp-file/artifact preparation, resume selection, cleanup
- `scripts/task.py` — `GolfTaskMetadata`, `GolfTaskResult`
- `scripts/setup_project.py` — build all Lean projects under `workspace/`
- `scripts/retrieval_service.py` — FastAPI + FAISS retrieval service (`/retrieve`, `/health`)
- `scripts/verify_lean_client_results.py`, `scripts/verify_putnam_results.py` — post-run
  verification reports (LSP-based / REPL-based)
- `scripts/proof_utils.py` — `proof_length()` tokenizer
- `tools/check_proof.py` — statement/file integrity checks, length computation, progress recording
- `tools/retrieve_examples.py` — CLI the agent uses to query the retrieval service (clears the query
  file after each call)
- `lean_worker/` — `interaction.py` (leanclient LSP wrapper), `verifier_lean_client.py`
  (`LeanClientScheduler`, multi-process), `verifier_slow.py` (REPL verifier; requires the
  `DEFAULT_LEAN_WORKSPACE` env var to point at a mathlib4 checkout), `scheduler.py` (base)
- `prompts/prompt_golf*.txt` — templates interpolated with `{name}`, `{temp_file_path}`,
  `{proof_length}`, `{current_proof_file}`, `{best_proof_file}`, `{progress_file}`, `{task_dir}`,
  `{check_proof_path}`, `{signature}`, `{formatted_contexts}`, `{service_url}`,
  `{search_query_file}` (the last two are retrieval-only)
- `config/example_config.yaml` — reference sample only; no code reads it (the CLI is flag-driven)
- `claude_status_check.py` — standalone helper that prints the active `claude auth status` account

### Data formats

- Eval JSONL line: `{"name", "path", "proof_length", "src", "signature", "contexts": [...]}`;
  `path` is relative to the project root, first 10 contexts go into the prompt.
- Price JSONL line: `{"name", "total_cost"}` → floored to 2 dp and passed as `--max-budget-usd`;
  missing names fall back to `$0.30` with a warning.
- Output dir: `results/<run>/summary.json` plus `results/<run>/<sanitized_name>/{result.json,
  progress.jsonl, best_proof.txt, current_proof.txt, claude_raw.jsonl, search_query_*.txt}`.

## Conventions & constraints

- The agent may only edit the target proof body — statement, other declarations, and imports must
  stay byte-identical; `check_proof.py` enforces this and prints the original proof to revert to.
- No helper lemmas or new declarations; optimization is self-contained.
- Compilation is checked with `lean_diagnostic_messages`, never `lake build`.
- Proof length is the custom tokenizer in `check_proof.py` (mirrors `scripts/proof_utils.py`) — keep
  the two in sync if either changes.
- Always pass `ensure_ascii=False` to `json.dump`/`json.dumps` (Lean source contains Unicode).
- Log files (`*.log`) and `results/` are run artifacts, not source; `results/` and `.claude/` are
  gitignored.
