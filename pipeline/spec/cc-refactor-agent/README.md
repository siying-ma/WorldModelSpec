# cc_agent

Claude Code agent system for Lean 4 proof optimization (proof golfing). It reads a JSONL of
theorems, creates one isolated temp `.lean` file per theorem (parallel-safe), and launches a
`claude -p` session per theorem that iteratively shortens the proof while keeping the file
compiling. Results, per-attempt progress, and cost/token usage are recorded per task.

## Setup

All commands below are run from the repository root.

```bash
# 1) One-time: installs lean4-skills plugin (project scope), lean-lsp MCP server, and runs `uv sync`
bash setup.sh
source .venv/bin/activate

# 2) Add Lean projects under ./workspace (already present: putnam2025)
#    Each project must be a direct child of ./workspace and contain
#    eval/eval_<project_folder_name>.jsonl (produced by the lean-refactor data_extraction pipeline).
rsync -av --exclude='.lake' /path/to/old-project/ ./workspace/<new_project_name>/

# 3) Build every Lean project under ./workspace (lake exe cache get + lake build)
python -m scripts.run_golf setup-project
```

Requirements: Claude Code CLI, `uv`/`uvx`, Python ≥ 3.10, `lake`/elan.

## How to run

Canonical run (retrieval + skills, Haiku, 15 parallel workers, per-task budgets from `price.jsonl`):

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

The eval JSONL is auto-discovered at `<project-root>/eval/eval_<project_folder_name>.jsonl`
(override with `--jsonl-file`). `price.jsonl` is not shipped with the workspace projects — either
supply your own or drop `--price-jsonl` to run without per-task budget caps.

### Options (`run`)

| Option | Default | Meaning |
| --- | --- | --- |
| `--project-root` | (required) | Lean project root; also the cwd for each `claude` process |
| `--jsonl-file` | auto-discovered | Explicit eval JSONL override |
| `--output-dir` | `results/golf` | Per-task artifacts + `summary.json` |
| `--max-turns` | `20` | Max turns per Claude session |
| `--timeout-minutes` | `120` | Per-task wall-clock limit; `0` = no limit |
| `--parallel` / `--max-workers` | `False` / `1` | `ThreadPoolExecutor` fan-out, one temp file per task |
| `--model` | CLI default | `opus`→`claude-opus-4-6`, `sonnet`→`claude-sonnet-4-6`, `haiku`→`claude-haiku-4-5-20251001`, or a full ID |
| `--effort` | CLI default | `low` \| `medium` \| `high` \| `max` |
| `--enable-retrieval` / `--service-url` | `False` | Retrieval-augmented prompt; `/health` is checked before the run starts |
| `--price-jsonl` | none | Per-task `--max-budget-usd` caps |
| `--no-skills` | `False` | Disable lean4-skills; use the lean-lsp-only prompt |
| `--filter-name` / `--max-tasks` | none | Run one theorem / cap task count |
| `--cleanup` | `True` | Remove temp `.lean` files after the run |

Other commands:

```bash
python -m scripts.run_golf setup-project [--workspace-dir workspace]
python -m scripts.run_golf cleanup --project-root workspace/<project>   # remove leftover temp .lean files
```

Installing the package also exposes a `cc-golf` console script equivalent to `python -m scripts.run_golf`.

### Run modes

> Only `prompts/prompt_golf_with_retrieval_tool.txt` is currently present in this checkout, so
> retrieval mode is the only one that runs as-is. The other two modes are implemented in
> `runner.build_prompt` but fail with `FileNotFoundError` until their templates are restored.

- **Skills (default)** — prompt `prompts/prompt_golf.txt` *(missing)*; agent may use `/lean4:golf`,
  `/lean4:refactor`, plus lean-lsp MCP.
- **No skills** (`--no-skills`) — prompt `prompts/prompt_golf_no_skill.txt` *(missing)*, lean-lsp MCP
  only. The runner aborts the task if any lean4 plugin is still enabled, so disable it first:
  `claude plugin disable lean4@lean4-skills`.
- **Retrieval** (`--enable-retrieval true --service-url ...`) — prompt
  `prompts/prompt_golf_with_retrieval_tool.txt`; the agent writes a Lean snippet to its
  `search_query_<name>.txt` and calls `tools/retrieve_examples.py` for refactoring strategies.
  Retrieval takes precedence over `--no-skills` when both are set.

Start the retrieval service first (same host:port as `--service-url`):

```bash
python scripts/retrieval_service.py \
  --model-path /path/to/embedding/checkpoint \
  --index-path /path/to/strategies_index.faiss \
  --metadata-path /path/to/strategies_index.meta.json \
  --port 8010 \
  --cuda-visible-devices 1
```

### Budget caps (`--price-jsonl`)

JSONL with `{"name": ..., "total_cost": ...}` per line (`name` must match the eval JSONL).
`total_cost` is floored to 2 decimals and passed as `--max-budget-usd`; names missing from the
price file fall back to `$0.30` with a warning. Each task's budget is logged before it starts.

### Resume behavior

Re-running with the same `--output-dir` skips any task whose `result.json` has `success: true`.
Every other task dir (failed, interrupted, unreadable) is deleted and re-prepared from the original
source, and `summary.json` is rebuilt from surviving + fresh results.

## Output layout

```
results/<run>/
  summary.json                     # totals: improved count, tokens saved, avg reduction, cost, usage, per-task results
  <sanitized_theorem_name>/
    result.json                    # success, initial/final length, tokens_saved, reduction_pct, attempts, cost, tokens
    progress.jsonl                 # one row per check_proof call (attempt 0 = original proof)
    best_proof.txt                 # shortest verified-shorter proof so far
    current_proof.txt              # proof the agent last submitted
    claude_raw.jsonl               # raw stream-json transcript of the Claude session
    search_query_<name>.txt        # retrieval mode only
```

## Post-run verification

`check_proof.py` trusts the agent's `lean_diagnostic_messages` check, so re-verify final proofs
independently:

```bash
# Recompile each task's latest improved proof via the Lean LSP and write a report (no files modified)
.venv/bin/python -m scripts.verify_lean_client_results \
  --results-dir results/putnam2025_with_retrieval_with_skill \
  --problems-jsonl workspace/putnam2025/eval/eval_putnam2025.jsonl \
  --workspace-path workspace/putnam2025 \
  --output-path results/putnam2025_with_retrieval_with_skill/verify_report.jsonl \
  --max-concurrent-requests 5
```

`scripts/verify_putnam_results.py` does the same via the REPL-based verifier (problem header + proof).
It needs a mathlib4 checkout: `export DEFAULT_LEAN_WORKSPACE=/path/to/mathlib4` before running it.

## Key files

| Path | Role |
| --- | --- |
| `scripts/run_golf.py` | Fire CLI (`run`, `setup-project`, `cleanup`): path resolution, retrieval health check, price map, resume, summary writing |
| `scripts/runner.py` | Builds prompts, launches `claude -p --output-format stream-json`, parses cost/tokens, parallel executor, summary table |
| `scripts/preprocessor.py` | Loads eval JSONL, creates temp `.lean` + task artifacts, resume selection, temp-file cleanup |
| `scripts/task.py` | `GolfTaskMetadata` / `GolfTaskResult` dataclasses |
| `scripts/setup_project.py` | `lake exe cache get` + `lake build` for each project under `workspace/` |
| `scripts/retrieval_service.py` | FastAPI embedding + FAISS retrieval service (`/retrieve`, `/health`) |
| `scripts/verify_lean_client_results.py` / `verify_putnam_results.py` | Post-run verification reports (LSP-based / REPL-based) |
| `scripts/proof_utils.py` | `proof_length()` tokenizer (from goedels-poetry) |
| `tools/check_proof.py` | Agent-called tool: validates statement + file integrity, computes length, updates `best_proof.txt` and `progress.jsonl` |
| `tools/retrieve_examples.py` | Agent-called CLI that queries the retrieval service and formats strategies |
| `lean_worker/interaction.py` | `LeanInteractor`: leanclient LSP wrapper (temp files, code replacement, diagnostics) |
| `lean_worker/verifier_lean_client.py` | `LeanClientScheduler`: multi-process LSP verification |
| `lean_worker/verifier_slow.py` | REPL/`lake`-based verifier (`Lean4ServerScheduler`) |
| `lean_worker/scheduler.py` | `ProcessScheduler` base (queues, request statuses) |
| `prompts/prompt_golf_with_retrieval_tool.txt` | Retrieval-mode prompt template (the only template currently in the repo) |
| `setup.sh` | One-time plugin/MCP/venv setup |
| `config/example_config.yaml` | Sample settings for reference only — the Fire CLI takes flags, nothing reads this file |
| `claude_status_check.py` | Standalone helper: prints the active `claude auth status` account and plan |

## Input JSONL format

One object per line: `{"name", "path", "proof_length", "src", "signature", "contexts": [...]}`
— `path` is relative to the project root, `src` is the full statement + proof, `contexts` are
related declarations (first 10 are injected into the prompt).

## Key constraints

- The agent may only edit the target proof body; statement, other declarations, and imports must
  stay byte-identical (`check_proof.py` enforces both and prints the original to revert to).
- No helper lemmas or new declarations — optimization must be self-contained.
- Compilation is checked with `lean_diagnostic_messages` (severity 1), not `lake build`.
- Proof length is the custom tokenizer in `check_proof.py` / `scripts/proof_utils.py`.
