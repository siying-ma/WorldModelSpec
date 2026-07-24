"""Steps 2+3: LLM domain classification of the Lean repo corpus (self-hosted gpt-oss-20b).

Reads features.jsonl (output of extract_features.py) and, for every repo, asks
gpt-oss-20b to do two things in one worker pass:

  Stage 2 (triage, ALL repos)
      Assign multi-label domain tags from a fixed taxonomy, and flag which of the
      four TARGET domains the repo is plausibly a source of *borrowable* formal
      ideas for. Cheap, short output.

  Stage 3 (deep, CANDIDATES only)
      For repos flagged as a candidate for >=1 target in Stage 2, score relevance
      to each target in [0,1] with a concrete borrowable artifact and a one-line
      rationale. This is what answers "how many repos are relevant to the 4
      target domains".

The four target domains (scored on borrowable *structure*, not topic match):
  physion              physics / physical-reasoning formalization, dynamics/ODEs,
                       or evaluation-predicate ("judge a state/trajectory") structure.
  traffic              rule systems, state machines, reachability/safety invariants,
                       temporal or deontic logic (traffic / self-driving rulebooks).
  mathlib_conventions  idiomatic, well-styled Lean/Mathlib library worth imitating
                       for naming/structure conventions (NOT merely depends on Mathlib).
  visual_gen           geometry, graphics/rendering, DSL/AST + interpreter, or
                       program synthesis (visual generation via program synthesis).

Reuses the multi-GPU worker pattern from judge_queries_copy.py: one vLLM instance
per GPU, input sharded round-robin, harmony reasoning traces stripped via
parse_chat_output, per-shard line-buffered outputs merged at the end.

Outputs (in --output-dir):
  triage.jsonl            one row per repo: full_name, tags, candidates, is_candidate, raw
  classification.jsonl    one row per deep-classified repo: full_name, relevance{...}, confidence, raw
  classify_failures.jsonl rows whose triage or deep output could not be parsed
  domains_summary.json    corpus-level counts relevant to each target at several thresholds

Example
-------
    python classify_repos.py \\
        --features   features_out/features.jsonl \\
        --output-dir classify_out \\
        --gpus 0 1 2 3
"""

import os
import argparse
import json
import multiprocessing
import re
import sys
import time
import traceback
from pathlib import Path

# --------------------------------------------------------------------------- #
# Taxonomy and target domains
# --------------------------------------------------------------------------- #

# Fixed multi-label tag vocabulary. The model must choose from these exact
# tokens; anything else it emits is dropped at parse time.
DOMAIN_TAGS = [
    "algebra", "analysis", "topology", "geometry", "number_theory",
    "logic_set_theory", "category_theory", "probability_measure",
    "combinatorics", "order_lattice", "linear_algebra",
    "differential_equations", "dynamical_systems", "physics_formalization",
    "automata_formal_languages", "type_theory_pl", "program_semantics",
    "program_synthesis_dsl", "software_verification", "hardware_verification",
    "cryptography", "data_structures_algorithms", "graph_theory", "game_theory",
    "competition_math", "education_tutorial", "tooling_metaprogramming", "other",
]
TAG_SET = set(DOMAIN_TAGS)

TARGETS = ["physion", "traffic", "mathlib_conventions", "visual_gen"]

TARGET_DEFS = (
    "- physion: physics / physical-reasoning formalization, dynamics or ODEs, or an\n"
    "  evaluation-predicate structure (a spec that judges whether a state or trajectory\n"
    "  is valid) — transferable to critiquing generated videos.\n"
    "- traffic: rule systems, state machines, reachability / safety invariants, temporal\n"
    "  or deontic (obligation/permission) logic — transferable to traffic and self-driving\n"
    "  rulebooks.\n"
    "- mathlib_conventions: an idiomatic, well-styled Lean/Mathlib library worth imitating\n"
    "  for naming and structuring conventions. This is about STYLE, not topic; merely\n"
    "  depending on Mathlib is NOT enough — the code must exemplify good conventions.\n"
    "- visual_gen: geometry, graphics / rendering, a DSL / AST plus an interpreter, or\n"
    "  program synthesis — transferable to visual generation via program synthesis."
)

# --------------------------------------------------------------------------- #
# Payload rendering (mirrors extract_features.py:render_payload so the script is
# self-contained; keep in sync if the feature schema changes).
# --------------------------------------------------------------------------- #

def render_payload(rec: dict) -> str:
    def kv(d):
        return ", ".join(f"{k}:{v}" for k, v in d.items()) if d else "(none)"

    lines = [
        f"REPO: {rec.get('full_name')}",
        f"stars: {rec.get('stars')}  topics: {rec.get('topics')}",
        f"description: {rec.get('description') or '(none)'}",
        f"dependencies: {', '.join(rec.get('deps', [])) or '(none)'}",
        f"primary_area: {rec.get('primary_area')}",
        f"mathlib_areas: {kv(rec.get('mathlib_areas', {}))}",
        f"mathlib_submodules: {kv(rec.get('mathlib_submods', {}))}",
        f"import_roots: {kv(rec.get('import_roots', {}))}",
        f"structure_flags: {', '.join(rec.get('structure_flags', [])) or '(none)'}",
        f"declaration_kinds: {kv(rec.get('decl_kinds', {}))}",
        f"proof_health: sorry/admit:{rec.get('n_sorry')}  custom_axioms:{rec.get('n_axiom')}  "
        f"examples:{rec.get('n_example')}  named_decls:{rec.get('n_named_decls')}",
        f"sample_declarations: {', '.join(rec.get('decl_names', [])[:20]) or '(none)'}",
        f"snake_case_conformance: {rec.get('naming_snake_conformance')} "
        f"(over {rec.get('n_lemmas_sampled')} lemmas)",
        f"readme_domain_hits: {rec.get('readme_domain_hits') or '(none)'}",
        f"has_blueprint: {rec.get('has_blueprint')}",
    ]
    if rec.get("readme_excerpt"):
        lines.append(f"README_excerpt: {rec['readme_excerpt']}")
    if rec.get("blueprint_excerpt"):
        lines.append(f"blueprint_excerpt: {rec['blueprint_excerpt']}")
    if rec.get("docstrings"):
        lines.append("docstrings: " + " || ".join(rec["docstrings"]))
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Prompt builders
# --------------------------------------------------------------------------- #

def build_triage_prompt(rec: dict) -> str:
    payload = render_payload(rec)
    return (
        "You are classifying a Lean 4 GitHub repository by domain, from structured\n"
        "signals extracted from its code and README.\n"
        "\n"
        f"{payload}\n"
        "\n"
        "Task 1 - domain tags. List ALL tags that describe this repo's content, using\n"
        "the exact tokens from this fixed list (comma-separated, no other words):\n"
        f"{', '.join(DOMAIN_TAGS)}\n"
        "\n"
        "Task 2 - target-domain candidacy. For each of four target domains, decide\n"
        "whether this repo is even PLAUSIBLY worth a closer look as a source of\n"
        "BORROWABLE formal ideas (transferable structure, not necessarily the same\n"
        "topic). Answer yes only if a concrete transferable pattern exists; default no.\n"
        f"{TARGET_DEFS}\n"
        "\n"
        "Respond with EXACTLY these two lines and nothing else:\n"
        "<tags>tag1, tag2, ...</tags>\n"
        "<candidates>physion=yes|no; traffic=yes|no; mathlib_conventions=yes|no; visual_gen=yes|no</candidates>"
    )


def build_deep_prompt(rec: dict, tags: list[str]) -> str:
    payload = render_payload(rec)
    tag_line = ", ".join(tags) if tags else "(none assigned)"
    return (
        "You are assessing how useful a Lean 4 repository is as a source of BORROWABLE\n"
        "formal ideas for four target domains. Topical match is rare and NOT required -\n"
        "score the transferable STRUCTURE (proof patterns, lemma libraries, DSLs,\n"
        "invariants, spec/judge predicates), not the subject matter.\n"
        "\n"
        f"{payload}\n"
        "\n"
        f"Preliminary domain tags: {tag_line}\n"
        "\n"
        "Target domains:\n"
        f"{TARGET_DEFS}\n"
        "\n"
        "Score each target's relevance in [0,1] with this rubric:\n"
        "  0.0 = no transferable content\n"
        "  0.3 = shares an abstract pattern only\n"
        "  0.6 = a reusable proof technique / structure\n"
        "  0.9 = a directly reusable lemma library / DSL\n"
        "Name the single most concrete borrowable artifact (or \"none\") and give a\n"
        "one-sentence rationale. If artifact is \"none\", score must be <= 0.2.\n"
        "\n"
        "Respond with ONLY this JSON object, no prose, no code fence:\n"
        '{\n'
        '  "physion": {"score": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "traffic": {"score": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "mathlib_conventions": {"score": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "visual_gen": {"score": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "confidence": 0.0\n'
        '}'
    )


# --------------------------------------------------------------------------- #
# Output parsers
# --------------------------------------------------------------------------- #

_TAGS_RE = re.compile(r"<tags>(.*?)</tags>", re.IGNORECASE | re.DOTALL)
_CANDS_RE = re.compile(r"<candidates>(.*?)</candidates>", re.IGNORECASE | re.DOTALL)


def parse_triage(text: str):
    """Return (tags:list[str], candidates:dict[target->bool]) or (None, None) if
    neither block is present. Unknown tags are dropped; missing targets default
    to False. Uses the LAST block so echoed examples don't shadow the verdict."""
    if not text:
        return None, None
    tag_m = _TAGS_RE.findall(text)
    cand_m = _CANDS_RE.findall(text)
    if not tag_m and not cand_m:
        return None, None

    tags = []
    if tag_m:
        for tok in re.split(r"[,\s]+", tag_m[-1].strip()):
            t = tok.strip().lower()
            if t in TAG_SET and t not in tags:
                tags.append(t)

    candidates = {t: False for t in TARGETS}
    if cand_m:
        block = cand_m[-1].lower()
        for t in TARGETS:
            m = re.search(rf"{t}\s*=\s*(yes|no)", block)
            if m:
                candidates[t] = (m.group(1) == "yes")
    return tags, candidates


def _extract_last_json(text: str):
    """Extract the last balanced top-level {...} object from text and json.loads
    it. Tolerates ```json fences and trailing prose. Returns dict or None."""
    if not text:
        return None
    s = text.replace("```json", "```").replace("```", "")
    # scan for balanced brace groups, keep the last that parses
    last = None
    depth = 0
    start = -1
    for i, ch in enumerate(s):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            if depth > 0:
                depth -= 1
                if depth == 0 and start >= 0:
                    chunk = s[start:i + 1]
                    try:
                        last = json.loads(chunk)
                    except Exception:
                        pass
    return last


def _clamp01(x):
    try:
        v = float(x)
    except (TypeError, ValueError):
        return 0.0
    return max(0.0, min(1.0, v))


def parse_deep(text: str):
    """Return a normalized relevance dict {target:{score,artifact,rationale}, confidence}
    or None if no JSON object could be recovered."""
    obj = _extract_last_json(text)
    if not isinstance(obj, dict):
        return None
    out = {}
    for t in TARGETS:
        cell = obj.get(t) or {}
        if not isinstance(cell, dict):
            cell = {}
        out[t] = {
            "score": _clamp01(cell.get("score", 0.0)),
            "artifact": str(cell.get("artifact", "none"))[:200],
            "rationale": str(cell.get("rationale", ""))[:300],
        }
    out["confidence"] = _clamp01(obj.get("confidence", 0.0))
    return out


# --------------------------------------------------------------------------- #
# Generic helpers (from judge_queries_copy.py)
# --------------------------------------------------------------------------- #

def log(tag: str, msg: str) -> None:
    ts = time.strftime("%H:%M:%S")
    print(f"[{ts}][{tag}] {msg}", flush=True)


def load_jsonl(path: Path) -> list[dict]:
    records = []
    with path.open("r") as f:
        for line in f:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    return records


def shard_records(records, num_shards):
    shards = [[] for _ in range(num_shards)]
    for i, rec in enumerate(records):
        shards[i % num_shards].append((i, rec))
    return shards


def concat_files(srcs, dest) -> int:
    n = 0
    with dest.open("w") as out:
        for src in srcs:
            if not Path(src).exists():
                continue
            with open(src, "r") as f:
                for line in f:
                    out.write(line)
                    if line.endswith("\n"):
                        n += 1
                    elif line:
                        out.write("\n")
                        n += 1
    return n


# --------------------------------------------------------------------------- #
# Per-GPU worker: triage over the whole shard, then deep over its candidates.
# --------------------------------------------------------------------------- #

def worker(
    gpu_id, shard, model, hf_home,
    triage_max_tokens, deep_max_tokens, temperature, top_p,
    triage_effort, deep_effort, batch_size,
    triage_path, deep_path, fail_path,
) -> None:
    os.environ["CUDA_VISIBLE_DEVICES"] = str(gpu_id)
    if hf_home:
        os.environ["HF_HOME"] = hf_home           # must be set before vLLM import
    tag = f"gpu{gpu_id}"

    try:
        log(tag, f"Importing vLLM (CUDA_VISIBLE_DEVICES={gpu_id}) ...")
        from vllm import LLM, SamplingParams
        try:
            from vllm.entrypoints.harmony_utils import parse_chat_output
        except Exception:
            parse_chat_output = None   # fall back to raw text on older vLLM

        log(tag, f"Loading model {model} ...")
        llm = LLM(model=model, tensor_parallel_size=1, trust_remote_code=True)
        log(tag, "Model ready.")

        triage_sp = SamplingParams(n=1, max_tokens=triage_max_tokens,
                                   temperature=temperature, top_p=top_p)
        deep_sp = SamplingParams(n=1, max_tokens=deep_max_tokens,
                                 temperature=temperature, top_p=top_p)

        def final_text(sample):
            raw = sample.text
            if parse_chat_output is not None:
                try:
                    _, ft, _ = parse_chat_output(list(sample.token_ids))
                    return raw, (ft or raw)
                except Exception:
                    return raw, raw
            return raw, raw

        fj = open(triage_path, "w", buffering=1)
        fd = open(deep_path, "w", buffering=1)
        ff = open(fail_path, "w", buffering=1)

        # ---- Stage 2: triage over the whole shard ----
        candidates = []   # (rec, tags) needing deep classification
        n_done = n_cand = n_fail = 0
        t_start = time.time()
        for bstart in range(0, len(shard), batch_size):
            batch = shard[bstart: bstart + batch_size]
            messages = [[{"role": "user", "content": build_triage_prompt(rec)}]
                        for _, rec in batch]
            t0 = time.time()
            outputs = llm.chat(messages=messages, sampling_params=triage_sp,
                               chat_template_kwargs={"reasoning_effort": triage_effort})
            for (_, rec), req_out in zip(batch, outputs):
                raw, ftext = final_text(req_out.outputs[0])
                tags, cands = parse_triage(ftext)
                if tags is None:
                    ff.write(json.dumps({"stage": "triage", "full_name": rec.get("full_name"),
                                         "raw_output": raw}, ensure_ascii=False) + "\n")
                    n_fail += 1
                    continue
                is_cand = any(cands.values())
                fj.write(json.dumps({
                    "full_name": rec.get("full_name"),
                    "tags": tags,
                    "candidates": cands,
                    "is_candidate": is_cand,
                    "raw_output": raw,
                }, ensure_ascii=False) + "\n")
                if is_cand:
                    candidates.append((rec, tags))
                    n_cand += 1
            fj.flush()
            n_done += len(batch)
            log(tag, f"triage {n_done}/{len(shard)} in {time.time()-t0:.1f}s "
                     f"| candidates={n_cand} unparse={n_fail}")

        # ---- Stage 3: deep classification over candidates only ----
        n_deep = n_deep_fail = 0
        for bstart in range(0, len(candidates), batch_size):
            batch = candidates[bstart: bstart + batch_size]
            messages = [[{"role": "user", "content": build_deep_prompt(rec, tags)}]
                        for rec, tags in batch]
            t0 = time.time()
            outputs = llm.chat(messages=messages, sampling_params=deep_sp,
                               chat_template_kwargs={"reasoning_effort": deep_effort})
            for (rec, _), req_out in zip(batch, outputs):
                raw, ftext = final_text(req_out.outputs[0])
                rel = parse_deep(ftext)
                if rel is None:
                    ff.write(json.dumps({"stage": "deep", "full_name": rec.get("full_name"),
                                         "raw_output": raw}, ensure_ascii=False) + "\n")
                    n_deep_fail += 1
                    continue
                fd.write(json.dumps({
                    "full_name": rec.get("full_name"),
                    "relevance": {t: rel[t] for t in TARGETS},
                    "confidence": rel["confidence"],
                    "raw_output": raw,
                }, ensure_ascii=False) + "\n")
                n_deep += 1
            fd.flush()
            log(tag, f"deep {min(bstart+batch_size, len(candidates))}/{len(candidates)} "
                     f"in {time.time()-t0:.1f}s | deep_ok={n_deep} deep_unparse={n_deep_fail}")

        fj.close(); fd.close(); ff.close()
        log(tag, f"Done in {time.time()-t_start:.1f}s | triaged={n_done} candidates={n_cand} "
                 f"deep_ok={n_deep} failures={n_fail + n_deep_fail}")

    except Exception:
        log(tag, "WORKER FAILED with exception:")
        traceback.print_exc(file=sys.stdout)
        sys.stdout.flush()
        raise


# --------------------------------------------------------------------------- #
# Aggregation
# --------------------------------------------------------------------------- #

def aggregate(classification_path: Path, thresholds, output_dir: Path, n_repos_total: int):
    recs = load_jsonl(classification_path) if classification_path.exists() else []
    counts = {t: {f"{th}": 0 for th in thresholds} for t in TARGETS}
    top_examples = {t: [] for t in TARGETS}
    for r in recs:
        rel = r.get("relevance", {})
        for t in TARGETS:
            score = float(rel.get(t, {}).get("score", 0.0))
            for th in thresholds:
                if score >= th:
                    counts[t][f"{th}"] += 1
            top_examples[t].append((score, r.get("full_name")))
    for t in TARGETS:
        top_examples[t] = [name for _, name in
                           sorted(top_examples[t], key=lambda x: -x[0])[:15]]

    summary = {
        "n_repos_total": n_repos_total,
        "n_deep_classified": len(recs),
        "thresholds": list(thresholds),
        "counts_relevant_per_target": counts,
        "top_repos_per_target": top_examples,
    }
    (output_dir / "domains_summary.json").write_text(json.dumps(summary, indent=2))

    print("=" * 64, flush=True)
    print(f"Repos total: {n_repos_total}   deep-classified: {len(recs)}", flush=True)
    header = "target".ljust(22) + "".join(f">= {th}".rjust(10) for th in thresholds)
    print(header, flush=True)
    for t in TARGETS:
        row = t.ljust(22) + "".join(str(counts[t][f'{th}']).rjust(10) for th in thresholds)
        print(row, flush=True)
    print("=" * 64, flush=True)
    return summary


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--features", type=str, required=True,
                    help="Path to features.jsonl from extract_features.py.")
    ap.add_argument("--output-dir", type=str, required=True)
    ap.add_argument("--model", type=str, default="openai/gpt-oss-20b")
    ap.add_argument("--hf-home", type=str, default=os.environ.get("HF_HOME", ""),
                    help="HF_HOME cache dir; set before vLLM import in each worker.")
    ap.add_argument("--gpus", type=int, nargs="+", default=[0, 1, 2, 3])
    ap.add_argument("--triage-max-tokens", type=int, default=16384,
                    help="Includes gpt-oss reasoning trace; raise if triage output is truncated.")
    ap.add_argument("--deep-max-tokens", type=int, default=32768)
    ap.add_argument("--temperature", type=float, default=0.2,
                    help="Low temp for reproducible classification (harness default was 1.0).")
    ap.add_argument("--top-p", type=float, default=1.0)
    ap.add_argument("--triage-effort", type=str, default="low",
                    choices=["low", "medium", "high"])
    ap.add_argument("--deep-effort", type=str, default="medium",
                    choices=["low", "medium", "high"])
    ap.add_argument("--batch-size", type=int, default=64)
    ap.add_argument("--thresholds", type=float, nargs="+", default=[0.3, 0.5, 0.7])
    ap.add_argument("--limit", type=int, default=0,
                    help="If >0, only classify the first N repos (smoke test).")
    args = ap.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    repos = load_jsonl(Path(args.features))
    if args.limit > 0:
        repos = repos[: args.limit]
    print(f"Loaded {len(repos)} repos from {args.features}.", flush=True)
    if not repos:
        print("No repos. Exiting.", flush=True)
        return

    n_gpus = len(args.gpus)
    shards = shard_records(repos, n_gpus)
    for g, sh in zip(args.gpus, shards):
        print(f"  shard gpu={g}: {len(sh)} repos", flush=True)

    triage_shard = [output_dir / f"_triage_{g}.jsonl" for g in args.gpus]
    deep_shard = [output_dir / f"_deep_{g}.jsonl" for g in args.gpus]
    fail_shard = [output_dir / f"_fail_{g}.jsonl" for g in args.gpus]

    print(f"Launching {n_gpus} workers ...", flush=True)
    procs = []
    for g, sh, tp, dp, fp in zip(args.gpus, shards, triage_shard, deep_shard, fail_shard):
        p = multiprocessing.Process(
            target=worker,
            args=(g, sh, args.model, args.hf_home,
                  args.triage_max_tokens, args.deep_max_tokens,
                  args.temperature, args.top_p,
                  args.triage_effort, args.deep_effort, args.batch_size,
                  str(tp), str(dp), str(fp)),
        )
        p.start()
        print(f"  Started PID {p.pid} -> gpu{g} ({len(sh)} repos)", flush=True)
        procs.append(p)
    for p in procs:
        p.join()

    failed = [args.gpus[i] for i, p in enumerate(procs) if p.exitcode != 0]
    if failed:
        print(f"WARNING: workers on gpus {failed} exited with errors.", flush=True)

    print("Merging shard outputs ...", flush=True)
    triage_path = output_dir / "triage.jsonl"
    classification_path = output_dir / "classification.jsonl"
    n_triage = concat_files(triage_shard, triage_path)
    n_deep = concat_files(deep_shard, classification_path)
    n_fail = concat_files(fail_shard, output_dir / "classify_failures.jsonl")

    if not failed:
        for p in triage_shard + deep_shard + fail_shard:
            if Path(p).exists():
                Path(p).unlink()

    print(f"Triaged: {n_triage}   deep-classified: {n_deep}   unparseable: {n_fail}", flush=True)
    aggregate(classification_path, args.thresholds, output_dir, len(repos))
    print(f"Output dir: {output_dir}", flush=True)

    if failed:
        sys.exit(1)


if __name__ == "__main__":
    multiprocessing.set_start_method("spawn")
    main()
