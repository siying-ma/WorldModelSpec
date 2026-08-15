"""Steps 2+3: LLM domain classification of the Lean repo corpus.

HTTP variant: instead of loading vLLM in-process on local GPUs, this submits
prompts over HTTP to an OpenAI-compatible server (e.g. `vllm serve
openai/gpt-oss-120b`) using the async aiohttp + semaphore pattern from
score_llm_judge_grpo_simple.py. All classification logic is unchanged.

Reads features.jsonl (output of extract_features.py) and, for every repo:

  Stage 2 (triage, ALL repos)
      Multi-label domain tags + candidacy flags for the four TARGET domains.

  Stage 3 (deep, CANDIDATES only)
      Per-target `topical` and `structural` scores in [0,1] with a concrete
      borrowable artifact and a one-line rationale.

Outputs (in --output-dir):
  triage.jsonl            one row per repo: full_name, tags, candidates, is_candidate, raw
  classification.jsonl    one row per deep-classified repo: full_name, relevance{...}, confidence, raw
  classify_failures.jsonl rows whose request failed or output could not be parsed
  repo_scores.csv         flat per-repo topical+structural table
  domains_summary.json    per-band repo lists + counts for both axes

Example
-------
    # start the server first (separately):
    #   vllm serve openai/gpt-oss-120b --port 8005
    python classify_repos_http.py \\
        --features   features_out/features.jsonl \\
        --output-dir classify_out \\
        --api-base   http://localhost:8005/v1 \\
        --model      openai/gpt-oss-120b \\
        --concurrency 20
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import json
import re
import time
from pathlib import Path

import aiohttp

# --------------------------------------------------------------------------- #
# Taxonomy and target domains
# --------------------------------------------------------------------------- #

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

TARGETS = ["physion", "traffic", "visual_gen"]

TARGET_DEFS = (
    "- physion:\n"
    "    ABOUT = formalizing physics, mechanics, or physical dynamics; ODEs describing\n"
    "      motion; or an evaluation predicate that judges whether a physical state or\n"
    "      trajectory is valid (transferable to critiquing generated videos).\n"
    "    BORROWABLE = reusable dynamics/ODE lemmas, conservation or invariant proofs,\n"
    "      or spec-as-judge predicates.\n"
    "    NOT physion = generic real analysis, measure theory, or probability with no\n"
    "      physical modeling (topical must be 0).\n"
    "- traffic:\n"
    "    ABOUT = formalizing traffic rules, road/rail networks, driving or vehicle\n"
    "      behavior, or multi-agent motion safety.\n"
    "    BORROWABLE = rulebook / deontic encodings, agent state machines with\n"
    "      safety-over-time invariants, or collision / reachability proofs.\n"
    "    NOT traffic = generic automata, temporal-logic libraries (LTL/CTL), or\n"
    "      verification frameworks that are not about agents, vehicles, or rules\n"
    "      (topical = 0, structural <= 0.4).\n"
    "- visual_gen:\n"
    "    ABOUT = generating images, SVG, vector graphics, diagrams, or scenes FROM a\n"
    "      program or spec (transferable to visual generation via program synthesis).\n"
    "    BORROWABLE = a graphics/geometry DSL that emits visual output, rendering\n"
    "      primitives, or program-synthesis-to-image machinery.\n"
    "    NOT visual_gen = pure geometry mathematics, data-plotting / charting\n"
    "      libraries, or generic DSL / interpreter / PL-semantics repos with no visual\n"
    "      output (topical = 0, structural <= 0.4)."
)

# --------------------------------------------------------------------------- #
# Payload rendering (mirrors extract_features.py:render_payload)
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
        "<candidates>physion=yes|no; traffic=yes|no; visual_gen=yes|no</candidates>"
    )


def build_deep_prompt(rec: dict, tags: list[str]) -> str:
    payload = render_payload(rec)
    tag_line = ", ".join(tags) if tags else "(none assigned)"
    return (
        "You are assessing a Lean 4 repository against four target domains. For each\n"
        "target you give TWO separate scores, because 'this repo is ABOUT the domain'\n"
        "and 'this repo has a pattern I could BORROW for the domain' are different things.\n"
        "\n"
        f"{payload}\n"
        "\n"
        f"Preliminary domain tags: {tag_line}\n"
        "\n"
        "Target domains:\n"
        f"{TARGET_DEFS}\n"
        "\n"
        "For each target output two scores in [0,1]:\n"
        "  topical    = is this repo actually ABOUT the domain (its real subject matter)?\n"
        "               Most repos are 0. Reserve > 0.5 for repos whose content genuinely\n"
        "               IS the domain.\n"
        "  structural = does it contain a borrowable formal pattern transferable to the\n"
        "               domain, regardless of topic? Rubric: 0.0 none / 0.3 abstract\n"
        "               pattern only / 0.6 reusable technique / 0.9 directly reusable\n"
        "               library or DSL.\n"
        "\n"
        "HARD RULES (apply before scoring):\n"
        "  1. If the repo is general-purpose mathematics (measure theory, analysis,\n"
        "     algebra, number theory, lattice theory, topology, etc.) with no\n"
        "     domain-specific modeling, set BOTH scores <= 0.2 for EVERY target.\n"
        "  2. Do NOT give structural > 0.5 to more than TWO targets.\n"
        "  3. If artifact is \"none\": structural <= 0.2 and topical = 0.\n"
        "  4. Respect the per-target NOT / caps in the definitions above.\n"
        "\n"
        "Name the single most concrete borrowable artifact (or \"none\") and a one-sentence\n"
        "rationale per target.\n"
        "\n"
        "Respond with ONLY this JSON object, no prose, no code fence:\n"
        '{\n'
        '  "physion": {"topical": 0.0, "structural": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "traffic": {"topical": 0.0, "structural": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "visual_gen": {"topical": 0.0, "structural": 0.0, "artifact": "...", "rationale": "..."},\n'
        '  "confidence": 0.0\n'
        '}'
    )


# --------------------------------------------------------------------------- #
# Output parsers
# --------------------------------------------------------------------------- #

_TAGS_RE = re.compile(r"<tags>(.*?)</tags>", re.IGNORECASE | re.DOTALL)
_CANDS_RE = re.compile(r"<candidates>(.*?)</candidates>", re.IGNORECASE | re.DOTALL)


def parse_triage(text: str):
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
    if not text:
        return None
    s = text.replace("```json", "```").replace("```", "")
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
    obj = _extract_last_json(text)
    if not isinstance(obj, dict):
        return None
    out = {}
    for t in TARGETS:
        cell = obj.get(t) or {}
        if not isinstance(cell, dict):
            cell = {}
        artifact = str(cell.get("artifact", "none"))[:200]
        topical = _clamp01(cell.get("topical", 0.0))
        structural = _clamp01(cell.get("structural", 0.0))
        if artifact.strip().lower() in ("", "none", "n/a", "na"):
            topical = 0.0
            structural = min(structural, 0.2)
        out[t] = {
            "topical": topical,
            "structural": structural,
            "artifact": artifact,
            "rationale": str(cell.get("rationale", ""))[:300],
        }
    out["confidence"] = _clamp01(obj.get("confidence", 0.0))
    return out


# --------------------------------------------------------------------------- #
# Generic helpers
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


MATHLIB_FORK_MAX_FILES = 2500
_MATHLIB_NAME_RE = re.compile(r"(^|[/_-])mathlib", re.IGNORECASE)


def is_mathlib_or_fork(rec: dict) -> bool:
    name = (rec.get("full_name") or rec.get("repo") or "").lower()
    if _MATHLIB_NAME_RE.search(name) or "mathlib" in name:
        return True
    if (rec.get("n_lean_files") or 0) >= MATHLIB_FORK_MAX_FILES:
        return True
    return False


# --------------------------------------------------------------------------- #
# HTTP call to the OpenAI-compatible server (async, bounded by a semaphore)
# --------------------------------------------------------------------------- #

async def call_chat(session, sem, cfg, prompt, reasoning_effort, max_tokens):
    """POST one chat completion. Returns (content:str|None, error:str|None).
    Reads the final answer from choices[0].message.content, falling back to
    reasoning_content if the server put everything there (or content is empty)."""
    payload = {
        "model": cfg["model"],
        "messages": [{"role": "user", "content": prompt}],
        "reasoning_effort": reasoning_effort,
        "temperature": cfg["temperature"],
        "top_p": cfg["top_p"],
        "max_tokens": max_tokens,
    }
    url = cfg["api_base"].rstrip("/") + "/chat/completions"
    last_err = None
    for attempt in range(cfg["retries"]):
        try:
            async with sem:
                async with session.post(
                    url, json=payload,
                    timeout=aiohttp.ClientTimeout(total=cfg["timeout_s"]),
                ) as resp:
                    resp.raise_for_status()
                    data = await resp.json()
            msg = data["choices"][0]["message"]
            content = msg.get("content") or ""
            if not content.strip():
                content = msg.get("reasoning_content") or ""
            return content, None
        except Exception as e:  # noqa: BLE001 (network/JSON/HTTP errors all -> retry)
            last_err = f"{type(e).__name__}: {e}"
            if attempt < cfg["retries"] - 1:
                await asyncio.sleep(cfg["backoff_s"] * (2 ** attempt))
    return None, last_err


# --------------------------------------------------------------------------- #
# Stage runners
# --------------------------------------------------------------------------- #

async def run_triage(session, sem, cfg, repos, fj, ff):
    """Fire triage requests for all repos concurrently; write rows as they finish.
    Returns the list of (rec, tags) that are candidates for deep classification."""
    async def one(rec):
        content, err = await call_chat(session, sem, cfg, build_triage_prompt(rec),
                                       cfg["triage_effort"], cfg["triage_max_tokens"])
        return rec, content, err

    tasks = [asyncio.create_task(one(rec)) for rec in repos]
    candidates = []
    done = n_cand = n_fail = 0
    t0 = time.time()
    for fut in asyncio.as_completed(tasks):
        rec, content, err = await fut
        done += 1
        if err or content is None:
            ff.write(json.dumps({"stage": "triage", "full_name": rec.get("full_name"),
                                 "error": err, "raw_output": content}, ensure_ascii=False) + "\n")
            n_fail += 1
        else:
            tags, cands = parse_triage(content)
            if tags is None:
                ff.write(json.dumps({"stage": "triage", "full_name": rec.get("full_name"),
                                     "raw_output": content}, ensure_ascii=False) + "\n")
                n_fail += 1
            else:
                is_cand = any(cands.values())
                fj.write(json.dumps({
                    "full_name": rec.get("full_name"),
                    "tags": tags, "candidates": cands, "is_candidate": is_cand,
                    "raw_output": content,
                }, ensure_ascii=False) + "\n")
                if is_cand:
                    candidates.append((rec, tags))
                    n_cand += 1
        if done % 100 == 0 or done == len(tasks):
            log("triage", f"{done}/{len(tasks)} | candidates={n_cand} unparse/fail={n_fail} "
                          f"| {time.time()-t0:.0f}s")
    return candidates


async def run_deep(session, sem, cfg, candidates, fd, ff):
    async def one(rec, tags):
        content, err = await call_chat(session, sem, cfg, build_deep_prompt(rec, tags),
                                       cfg["deep_effort"], cfg["deep_max_tokens"])
        return rec, content, err

    tasks = [asyncio.create_task(one(rec, tags)) for rec, tags in candidates]
    done = n_ok = n_fail = 0
    t0 = time.time()
    for fut in asyncio.as_completed(tasks):
        rec, content, err = await fut
        done += 1
        rel = None if (err or content is None) else parse_deep(content)
        if rel is None:
            ff.write(json.dumps({"stage": "deep", "full_name": rec.get("full_name"),
                                 "error": err, "raw_output": content}, ensure_ascii=False) + "\n")
            n_fail += 1
        else:
            fd.write(json.dumps({
                "full_name": rec.get("full_name"),
                "relevance": {t: rel[t] for t in TARGETS},
                "confidence": rel["confidence"],
                "raw_output": content,
            }, ensure_ascii=False) + "\n")
            n_ok += 1
        if done % 100 == 0 or done == len(tasks):
            log("deep", f"{done}/{len(tasks)} | ok={n_ok} unparse/fail={n_fail} "
                        f"| {time.time()-t0:.0f}s")


# --------------------------------------------------------------------------- #
# Aggregation
# --------------------------------------------------------------------------- #

def _make_bands(thresholds):
    th = sorted(thresholds)
    bands = [(th[-1], 1.01, f">={th[-1]:.2f}")]
    for i in range(len(th) - 1, 0, -1):
        bands.append((th[i - 1], th[i], f"{th[i-1]:.2f}-{th[i]:.2f}"))
    bands.append((0.0, th[0], f"<{th[0]:.2f}"))
    return bands


AXES = ["topical", "structural"]


def aggregate(classification_path: Path, thresholds, output_dir: Path, n_repos_total: int):
    recs = load_jsonl(classification_path) if classification_path.exists() else []
    bands = _make_bands(thresholds)

    counts = {ax: {t: {f"{th}": 0 for th in thresholds} for t in TARGETS} for ax in AXES}
    repos_by_band = {ax: {t: {label: [] for _, _, label in bands} for t in TARGETS}
                     for ax in AXES}
    rows = []

    for r in recs:
        rel = r.get("relevance", {})
        name = r.get("full_name")
        row = {"full_name": name, "confidence": float(r.get("confidence", 0.0))}
        cells = {}
        for t in TARGETS:
            cell = rel.get(t, {}) or {}
            top = float(cell.get("topical", 0.0))
            struc = float(cell.get("structural", 0.0))
            art = (cell.get("artifact") or "")[:120]
            cells[t] = (top, struc, art)
            row[f"{t}_topical"] = top
            row[f"{t}_structural"] = struc
        rows.append(row)

        for ax in AXES:
            idx = 0 if ax == "topical" else 1
            for t in TARGETS:
                score = cells[t][idx]
                for th in thresholds:
                    if score >= th:
                        counts[ax][t][f"{th}"] += 1
                for lo, hi, label in bands:
                    if lo <= score < hi:
                        repos_by_band[ax][t][label].append({
                            "full_name": name,
                            "topical": round(cells[t][0], 2),
                            "structural": round(cells[t][1], 2),
                            "artifact": cells[t][2],
                        })
                        break

    for ax in AXES:
        for t in TARGETS:
            for label in repos_by_band[ax][t]:
                repos_by_band[ax][t][label].sort(key=lambda x: -x[ax])

    csv_path = output_dir / "repo_scores.csv"
    cols = []
    for t in TARGETS:
        cols += [f"{t}_topical", f"{t}_structural"]
    with csv_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["full_name"] + cols + ["confidence"])
        for row in sorted(rows, key=lambda x: -max([x[f"{t}_topical"] for t in TARGETS] or [0])):
            w.writerow([row["full_name"]]
                       + [f"{row[c]:.2f}" for c in cols]
                       + [f"{row['confidence']:.2f}"])

    summary = {
        "n_repos_total": n_repos_total,
        "n_deep_classified": len(recs),
        "thresholds": list(thresholds),
        "counts_topical_per_target": counts["topical"],
        "counts_structural_per_target": counts["structural"],
        "repos_by_topical_band": repos_by_band["topical"],
        "repos_by_structural_band": repos_by_band["structural"],
    }
    (output_dir / "domains_summary.json").write_text(json.dumps(summary, indent=2))

    band_labels = [label for _, _, label in bands]
    print("=" * 76, flush=True)
    print(f"Repos total: {n_repos_total}   deep-classified: {len(recs)}", flush=True)
    for ax in AXES:
        print(f"\n[{ax.upper()}] repos per band", flush=True)
        header = "target".ljust(22) + "".join(lab.rjust(12) for lab in band_labels)
        print(header, flush=True)
        for t in TARGETS:
            line = t.ljust(22) + "".join(
                str(len(repos_by_band[ax][t][lab])).rjust(12) for lab in band_labels)
            print(line, flush=True)
    print("-" * 76, flush=True)
    print("Per-band repo lists (both axes) -> domains_summary.json", flush=True)
    print("Flat per-repo topical+structural table -> repo_scores.csv", flush=True)
    print("=" * 76, flush=True)
    return summary


# --------------------------------------------------------------------------- #
# Main (async)
# --------------------------------------------------------------------------- #

async def run(args) -> None:
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    repos = load_jsonl(Path(args.features))
    n_loaded = len(repos)

    if not args.keep_mathlib_forks:
        dropped = [r for r in repos if is_mathlib_or_fork(r)]
        repos = [r for r in repos if not is_mathlib_or_fork(r)]
        with (output_dir / "dropped_mathlib_forks.jsonl").open("w") as f:
            for r in dropped:
                f.write(json.dumps({"full_name": r.get("full_name"),
                                    "n_lean_files": r.get("n_lean_files")}) + "\n")
        print(f"Dropped {len(dropped)} mathlib/forks -> dropped_mathlib_forks.jsonl", flush=True)

    if args.limit > 0:
        repos = repos[: args.limit]
    print(f"Loaded {n_loaded}; classifying {len(repos)} repos via {args.api_base} "
          f"({args.model}).", flush=True)
    if not repos:
        print("No repos. Exiting.", flush=True)
        return

    cfg = {
        "api_base": args.api_base,
        "model": args.model,
        "temperature": args.temperature,
        "top_p": args.top_p,
        "triage_effort": args.triage_effort,
        "deep_effort": args.deep_effort,
        "triage_max_tokens": args.triage_max_tokens,
        "deep_max_tokens": args.deep_max_tokens,
        "timeout_s": args.timeout_s,
        "retries": args.retries,
        "backoff_s": args.backoff_s,
    }

    triage_path = output_dir / "triage.jsonl"
    class_path = output_dir / "classification.jsonl"
    fail_path = output_dir / "classify_failures.jsonl"

    sem = asyncio.Semaphore(args.concurrency)
    connector = aiohttp.TCPConnector(limit=args.concurrency)
    async with aiohttp.ClientSession(connector=connector) as session:
        with open(triage_path, "w", buffering=1) as fj, \
             open(fail_path, "w", buffering=1) as ff:
            candidates = await run_triage(session, sem, cfg, repos, fj, ff)
        print(f"Triage done: {len(candidates)} candidates for deep classification.", flush=True)
        with open(class_path, "w", buffering=1) as fd, \
             open(fail_path, "a", buffering=1) as ff:
            await run_deep(session, sem, cfg, candidates, fd, ff)

    aggregate(class_path, args.thresholds, output_dir, len(repos))
    print(f"Output dir: {output_dir}", flush=True)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--features", type=str, required=True)
    ap.add_argument("--output-dir", type=str, required=True)
    ap.add_argument("--api-base", type=str, default="http://localhost:8005/v1",
                    help="OpenAI-compatible base URL of the running server.")
    ap.add_argument("--model", type=str, default="openai/gpt-oss-120b")
    ap.add_argument("--concurrency", type=int, default=20,
                    help="Max in-flight requests (semaphore). 20 is a safe default.")
    ap.add_argument("--triage-max-tokens", type=int, default=16384)
    ap.add_argument("--deep-max-tokens", type=int, default=32768)
    ap.add_argument("--temperature", type=float, default=0.2)
    ap.add_argument("--top-p", type=float, default=1.0)
    ap.add_argument("--triage-effort", type=str, default="low",
                    choices=["low", "medium", "high"])
    ap.add_argument("--deep-effort", type=str, default="medium",
                    choices=["low", "medium", "high"])
    ap.add_argument("--timeout-s", type=float, default=600.0)
    ap.add_argument("--retries", type=int, default=3)
    ap.add_argument("--backoff-s", type=float, default=2.0,
                    help="Base backoff between retries (exponential).")
    ap.add_argument("--thresholds", type=float, nargs="+", default=[0.3, 0.5, 0.7])
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--keep-mathlib-forks", action="store_true")
    args = ap.parse_args()
    asyncio.run(run(args))


if __name__ == "__main__":
    main()
