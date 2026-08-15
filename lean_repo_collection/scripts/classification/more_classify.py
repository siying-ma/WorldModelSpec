"""Precision pass: identify the ACTUALLY-USEFUL applied / real-world-domain repos.

Motivation
----------
Stage-1 tag bucketing (bucket_applied.py) over-counts: a tag being present does
not mean the repo is a genuine, non-trivial formalization of a real-world domain.
The truly useful repos are rare (like the 3 real traffic repos). The 4-target deep
scores can't help either, because a genuine game-theory / crypto / economics repo
scores ~0 on physion/traffic/mathlib/visual.

So this runs a focused LLM pass (gpt-oss-120b over an OpenAI-compatible HTTP
server) over the KEEP set from bucket_applied. Per repo it asks: what real-world
domain (if any) does this actually model, is it a genuine applied formalization or
just pure math / CS infra / a tutorial / a toy, how useful is it, and is it vision
related. This gives a precise useful-set and an X-ray of the under-explored
`other` bucket.

Deterministic pre-filter is intentionally minimal (drop only zero-declaration
repos) so small standalone repos survive; the LLM judges triviality via `kind`.

Outputs (in --out-dir):
  applied_reclass.jsonl   per repo: orig_class, orig_tags, real_world_domain, kind,
                          useful, vision_related, rationale, raw
  applied_useful.csv      the useful set (kind=applied_domain & useful>=threshold),
                          sorted by useful desc
  other_analysis.json     kind distribution + domain histogram + top-useful within
                          the Stage-1 'other' bucket
  applied_reclass_summary.json  corpus-level rollup

Usage
-----
    vllm serve openai/gpt-oss-120b --port 8005          # separately
    python applied_reclassify_http.py \\
        --triage   classify_out/triage.jsonl \\
        --features features_out/features.jsonl \\
        --out-dir  classify_out/applied_reclass \\
        --api-base http://localhost:8005/v1 \\
        --model    openai/gpt-oss-120b \\
        --concurrency 20
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import json
import re
import time
from collections import Counter, defaultdict
from pathlib import Path

import aiohttp

# --------------------------------------------------------------------------- #
# Tag taxonomy groups + keep-class logic (mirrors bucket_applied.py)
# --------------------------------------------------------------------------- #

APPLIED = {
    "physics_formalization", "dynamical_systems", "game_theory",
    "software_verification", "hardware_verification", "cryptography",
}
CORE_MATH = {
    "algebra", "analysis", "topology", "geometry", "number_theory",
    "logic_set_theory", "category_theory", "probability_measure",
    "combinatorics", "order_lattice", "linear_algebra",
    "differential_equations", "graph_theory", "competition_math",
}
CORE_CS = {
    "automata_formal_languages", "type_theory_pl", "program_semantics",
    "program_synthesis_dsl", "data_structures_algorithms",
    "tooling_metaprogramming",
}
SPECIAL = {"education_tutorial", "other"}
KEEP_CLASSES = {"applied", "education_applied", "other_standalone", "untagged"}


def classify_tags(tags):
    T = set(tags)
    applied = sorted(T & APPLIED)
    has_core = bool((T & CORE_MATH) or (T & CORE_CS))
    if applied:
        return "applied", applied
    if "education_tutorial" in T and not has_core:
        return "education_applied", []
    if "other" in T:
        return "other_standalone", []
    if not T:
        return "untagged", []
    if (T & CORE_CS) and not (T & CORE_MATH):
        return "core_cs", []
    return "core_math", []


KIND_SET = {
    "applied_domain", "pure_math", "pure_cs_infra",
    "tutorial_or_toy", "empty_or_trivial", "fork_or_duplicate",
}

# --------------------------------------------------------------------------- #
# Payload rendering (mirrors extract_features.py)
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


def build_prompt(rec: dict) -> str:
    payload = render_payload(rec)
    return (
        "You are curating a corpus of Lean 4 repositories that formalize REAL-WORLD or\n"
        "APPLIED domains, to support a world-model / vision project. The vast majority of\n"
        "Lean repos are pure mathematics, CS infrastructure, teaching exercises, or toys\n"
        "-- those are NOT useful here. A repo is useful ONLY if it genuinely models a\n"
        "real-world system or applied domain: e.g. traffic / driving rules, the physical\n"
        "dynamics of moving objects, a specific game's rules, a cryptographic protocol, an\n"
        "economic or market mechanism, a biological process, hardware/protocol behavior,\n"
        "or graphics / rendering / visual generation. Being tagged with an applied-sounding\n"
        "keyword is NOT enough -- judge the actual content.\n"
        "\n"
        f"{payload}\n"
        "\n"
        "Answer with ONLY this JSON object, no prose:\n"
        "{\n"
        '  "real_world_domain": "<2-5 word label of the real-world/applied thing it models, or \\"none\\">",\n'
        '  "kind": "<one of: applied_domain | pure_math | pure_cs_infra | tutorial_or_toy | empty_or_trivial | fork_or_duplicate>",\n'
        '  "useful": <0-1 usefulness as a genuine, non-trivial real-world/applied formalization; reserve >0.6 for real domain models>,\n'
        '  "vision_related": <0-1 relevance to images / graphics / geometry-for-rendering / diagrams / visual generation>,\n'
        '  "rationale": "<one sentence>"\n'
        "}\n"
        "HARD RULE: if kind is not \"applied_domain\", useful must be <= 0.3."
    )


# --------------------------------------------------------------------------- #
# Parsing
# --------------------------------------------------------------------------- #

def _extract_last_json(text: str):
    if not text:
        return None
    s = text.replace("```json", "```").replace("```", "")
    last, depth, start = None, 0, -1
    for i, ch in enumerate(s):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            if depth > 0:
                depth -= 1
                if depth == 0 and start >= 0:
                    try:
                        last = json.loads(s[start:i + 1])
                    except Exception:
                        pass
    return last


def _clamp01(x):
    try:
        return max(0.0, min(1.0, float(x)))
    except (TypeError, ValueError):
        return 0.0


def parse_applied(text: str):
    obj = _extract_last_json(text)
    if not isinstance(obj, dict):
        return None
    kind = str(obj.get("kind", "")).strip().lower()
    if kind not in KIND_SET:
        kind = "pure_math"  # conservative default when the model is vague
    useful = _clamp01(obj.get("useful", 0.0))
    if kind != "applied_domain":
        useful = min(useful, 0.3)  # defensive re-application of the hard rule
    return {
        "real_world_domain": str(obj.get("real_world_domain", "none"))[:80],
        "kind": kind,
        "useful": useful,
        "vision_related": _clamp01(obj.get("vision_related", 0.0)),
        "rationale": str(obj.get("rationale", ""))[:300],
    }


# --------------------------------------------------------------------------- #
# IO + HTTP
# --------------------------------------------------------------------------- #

def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def load_jsonl(path: Path):
    out = []
    with path.open() as f:
        for line in f:
            line = line.strip()
            if line:
                out.append(json.loads(line))
    return out


async def call_chat(session, sem, cfg, prompt):
    payload = {
        "model": cfg["model"],
        "messages": [{"role": "user", "content": prompt}],
        "reasoning_effort": cfg["effort"],
        "temperature": cfg["temperature"],
        "top_p": cfg["top_p"],
        "max_tokens": cfg["max_tokens"],
    }
    url = cfg["api_base"].rstrip("/") + "/chat/completions"
    last = None
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
        except Exception as e:  # noqa: BLE001
            last = f"{type(e).__name__}: {e}"
            if attempt < cfg["retries"] - 1:
                await asyncio.sleep(cfg["backoff_s"] * (2 ** attempt))
    return None, last


# --------------------------------------------------------------------------- #
# Aggregation
# --------------------------------------------------------------------------- #

def aggregate(records, out_dir: Path, useful_threshold: float):
    kind_counts = Counter(r["kind"] for r in records)
    useful_set = [r for r in records
                  if r["kind"] == "applied_domain" and r["useful"] >= useful_threshold]
    useful_set.sort(key=lambda r: (-r["useful"], -r["vision_related"], r["full_name"]))

    domain_hist = Counter(r["real_world_domain"].lower().strip() for r in useful_set)
    vision_set = [r for r in useful_set if r["vision_related"] >= 0.5]

    # dedicated 'other'-bucket X-ray
    other = [r for r in records if r["orig_class"] == "other_standalone"]
    other_kinds = Counter(r["kind"] for r in other)
    other_useful = sorted([r for r in other if r["kind"] == "applied_domain"
                           and r["useful"] >= useful_threshold],
                          key=lambda r: -r["useful"])
    other_domains = Counter(r["real_world_domain"].lower().strip()
                            for r in other_useful)

    # useful CSV
    cols = ["full_name", "real_world_domain", "kind", "useful", "vision_related",
            "orig_class", "orig_tags", "rationale"]
    with (out_dir / "applied_useful.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in useful_set:
            w.writerow({
                "full_name": r["full_name"],
                "real_world_domain": r["real_world_domain"],
                "kind": r["kind"],
                "useful": f"{r['useful']:.2f}",
                "vision_related": f"{r['vision_related']:.2f}",
                "orig_class": r["orig_class"],
                "orig_tags": r["orig_tags"],
                "rationale": r["rationale"],
            })

    (out_dir / "other_analysis.json").write_text(json.dumps({
        "n_other": len(other),
        "kind_distribution": dict(other_kinds),
        "n_useful_in_other": len(other_useful),
        "domain_histogram": other_domains.most_common(),
        "useful_repos": [{"full_name": r["full_name"],
                          "real_world_domain": r["real_world_domain"],
                          "useful": round(r["useful"], 2),
                          "vision_related": round(r["vision_related"], 2),
                          "rationale": r["rationale"]} for r in other_useful],
    }, indent=2))

    summary = {
        "n_classified": len(records),
        "useful_threshold": useful_threshold,
        "kind_distribution": dict(kind_counts),
        "n_useful": len(useful_set),
        "n_useful_vision_related": len(vision_set),
        "useful_domain_histogram": domain_hist.most_common(40),
    }
    (out_dir / "applied_reclass_summary.json").write_text(json.dumps(summary, indent=2))

    print("=" * 70)
    print(f"Classified: {len(records)}   USEFUL (applied_domain & >= {useful_threshold}): "
          f"{len(useful_set)}   of which vision-related: {len(vision_set)}")
    print("\nkind distribution:")
    for k, n in kind_counts.most_common():
        print(f"  {k:20} {n:6}")
    print("\ntop real-world domains among useful repos:")
    for dom, n in domain_hist.most_common(20):
        print(f"  {dom[:40]:40} {n:4}")
    print(f"\n'other' bucket: {len(other)} repos -> {len(other_useful)} genuinely useful")
    print("  kinds:", dict(other_kinds))
    print("-" * 70)
    print(f"Useful set  -> {out_dir/'applied_useful.csv'}")
    print(f"'other' X-ray -> {out_dir/'other_analysis.json'}")
    print("=" * 70)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

async def run(args):
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    triage = load_jsonl(Path(args.triage))
    orig = {}   # full_name -> (class, tags)
    for r in triage:
        tags = r.get("tags") or []
        cls, _ = classify_tags(tags)
        orig[r.get("full_name")] = (cls, tags)

    feats = {r.get("full_name"): r for r in load_jsonl(Path(args.features))}

    # keep set (optionally restricted to 'other' via --only-other) with a
    # zero-declaration pre-filter
    targets = []
    n_empty = 0
    for name, (cls, tags) in orig.items():
        if cls not in KEEP_CLASSES:
            continue
        if args.only_other and cls != "other_standalone":
            continue
        rec = feats.get(name)
        if rec is None:
            continue
        if (rec.get("n_named_decls") or 0) == 0:
            n_empty += 1
            continue
        targets.append((name, cls, tags, rec))
    if args.limit > 0:
        targets = targets[: args.limit]
    log(f"KEEP set: {len(targets)} repos to re-classify "
        f"(skipped {n_empty} zero-declaration) via {args.model}")

    cfg = {
        "api_base": args.api_base, "model": args.model, "effort": args.effort,
        "temperature": args.temperature, "top_p": args.top_p,
        "max_tokens": args.max_tokens, "timeout_s": args.timeout_s,
        "retries": args.retries, "backoff_s": args.backoff_s,
    }

    records = []
    fout = open(out_dir / "applied_reclass.jsonl", "w", buffering=1)
    ffail = open(out_dir / "applied_reclass_failures.jsonl", "w", buffering=1)

    sem = asyncio.Semaphore(args.concurrency)
    connector = aiohttp.TCPConnector(limit=args.concurrency)

    async def one(name, cls, tags, rec):
        content, err = await call_chat(session, sem, cfg, build_prompt(rec))
        return name, cls, tags, content, err

    done = n_useful = n_fail = 0
    t0 = time.time()
    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = [asyncio.create_task(one(n, c, t, r)) for n, c, t, r in targets]
        for fut in asyncio.as_completed(tasks):
            name, cls, tags, content, err = await fut
            done += 1
            parsed = None if (err or content is None) else parse_applied(content)
            if parsed is None:
                ffail.write(json.dumps({"full_name": name, "error": err,
                                        "raw_output": content}, ensure_ascii=False) + "\n")
                n_fail += 1
            else:
                row = {"full_name": name, "orig_class": cls,
                       "orig_tags": ";".join(tags), **parsed, "raw_output": content}
                fout.write(json.dumps(row, ensure_ascii=False) + "\n")
                records.append(row)
                if parsed["kind"] == "applied_domain" and parsed["useful"] >= args.useful_threshold:
                    n_useful += 1
            if done % 100 == 0 or done == len(tasks):
                log(f"{done}/{len(tasks)} | useful={n_useful} fail={n_fail} | {time.time()-t0:.0f}s")
    fout.close()
    ffail.close()

    aggregate(records, out_dir, args.useful_threshold)
    print(f"Output dir: {out_dir}", flush=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--triage", required=True)
    ap.add_argument("--features", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--api-base", default="http://localhost:8005/v1")
    ap.add_argument("--model", default="openai/gpt-oss-120b")
    ap.add_argument("--concurrency", type=int, default=20)
    ap.add_argument("--effort", default="low", choices=["low", "medium", "high"])
    ap.add_argument("--max-tokens", type=int, default=16384)
    ap.add_argument("--temperature", type=float, default=0.2)
    ap.add_argument("--top-p", type=float, default=1.0)
    ap.add_argument("--timeout-s", type=float, default=600.0)
    ap.add_argument("--retries", type=int, default=3)
    ap.add_argument("--backoff-s", type=float, default=2.0)
    ap.add_argument("--useful-threshold", type=float, default=0.6)
    ap.add_argument("--only-other", action="store_true",
                    help="Re-classify only the Stage-1 'other' bucket (fast focused pass).")
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    asyncio.run(run(args))


if __name__ == "__main__":
    main()
