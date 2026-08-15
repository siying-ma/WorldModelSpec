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

The LLM assigns each repo one CATEGORY from an applied-domain taxonomy anchored on
manually-classified examples (cs_algorithms_software, games, philosophy, logistics,
numerical_floating_point, entertainment, science, smart_contract_crypto,
traffic_autonomous, graphics_visual, physics_dynamics, other_applied) or a
not-useful category (pure_math, cs_infra, tutorial_or_toy, fork_or_duplicate,
empty_or_trivial). Deterministic pre-filter is minimal (drop only zero-declaration
repos) so small standalone repos survive.

Outputs (in --out-dir):
  applied_reclass.jsonl   per repo: orig_class, orig_tags, category, real_world_domain,
                          useful, vision_related, proof_status, rescued, rationale, raw
  applied_useful.csv      the useful set (applied category & useful>=threshold),
                          grouped by category, proof-backed first
  categories.json         category counts + per-category useful lists (+ other_applied)
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


# Applied-domain category taxonomy (anchored on manually-classified examples).
# A repo in one of these is USEFUL supplementary material.
APPLIED_CATEGORIES = {
    "cs_algorithms_software",    # verified algorithms / code-gen / software correctness (VERINA, CLEVER, human-eval-lean)
    "games",                     # board/card/video games, puzzles, engines (Chess.lean, functorio, Raylib.lean, sts_lean)
    "philosophy",                # philosophy, social choice, ethics, decision theory (phiLean, lean-social-choice)
    "logistics",                 # planning/scheduling/logistics/operational specs (lean-spec)
    "numerical_floating_point",  # floating point, interval arithmetic, numerical methods (interval)
    "entertainment",             # music/art/creative/recreational (Prismriver)
    "science",                   # natural-science modelling: chem/bio/materials/experiments (LeanLJ)
    "smart_contract_crypto",     # blockchain / smart contracts / EVM / crypto-protocol verification (verity, Clear)
    "traffic_autonomous",        # traffic / driving / rail / vehicle behaviour
    "graphics_visual",           # graphics / rendering / SVG / diagrams / visual generation
    "physics_dynamics",          # physical dynamics / mechanics / motion / ODEs of physical systems
    "other_applied",             # a genuine standalone real-world / applied domain not covered above
}
# Everything here is NOT useful for the corpus.
NOT_USEFUL_CATEGORIES = {
    "pure_math", "cs_infra", "tutorial_or_toy", "fork_or_duplicate", "empty_or_trivial",
}
CATEGORY_SET = APPLIED_CATEGORIES | NOT_USEFUL_CATEGORIES

# deep-classification targets, used to rescue mis-tagged applied repos.
TARGET_KEYS = ["physion", "traffic", "visual_gen"]

# Mathlib / fork skip (for --no-tag-filter, which reads the raw feature corpus).
MATHLIB_FORK_MAX_FILES = 2500
_MATHLIB_NAME_RE = re.compile(r"(^|[/_-])mathlib", re.IGNORECASE)


def is_mathlib_or_fork(rec: dict) -> bool:
    name = (rec.get("full_name") or rec.get("repo") or "").lower()
    if _MATHLIB_NAME_RE.search(name) or "mathlib" in name:
        return True
    if (rec.get("n_lean_files") or 0) >= MATHLIB_FORK_MAX_FILES:
        return True
    return False

# Rank for sorting: proofs preferred over specs (supplementary material must be
# checkable, not just specified).
PROOF_RANK = {"proof_backed": 0, "some_proofs": 1, "incomplete": 2, "spec_only": 3}


def proof_profile(rec: dict) -> dict:
    """Deterministic proof-content signal from extracted features. Prefers repos
    that actually PROVE theorems/lemmas over spec-only (defs/structures) repos and
    over sorry-riddled ones."""
    dk = rec.get("decl_kinds", {}) or {}
    n_proved = int(dk.get("theorem", 0)) + int(dk.get("lemma", 0))
    n_total = sum(int(v) for v in dk.values())
    n_sorry = int(rec.get("n_sorry", 0) or 0)
    ratio = (n_proved / n_total) if n_total else 0.0
    if n_proved == 0:
        status = "spec_only"
    elif n_sorry > 0.5 * n_proved:
        status = "incomplete"
    elif n_proved >= 5 and ratio >= 0.2 and n_sorry <= max(2, 0.1 * n_proved):
        status = "proof_backed"
    else:
        status = "some_proofs"
    return {"n_proved": n_proved, "n_total_decls": n_total,
            "proof_ratio": round(ratio, 2), "n_sorry": n_sorry,
            "proof_status": status}

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
        "You are curating Lean 4 repositories that formalize REAL-WORLD or APPLIED domains,\n"
        "for a world-model / vision project. Classify the repo into exactly ONE category.\n"
        "Most Lean repos are pure mathematics, generic proof-assistant / CS infrastructure,\n"
        "teaching exercises, or toys -- those are NOT useful. A repo is useful only if it\n"
        "genuinely models a real-world system or applied domain. Being tagged with an\n"
        "applied-sounding keyword is NOT enough -- judge the actual content.\n"
        "\n"
        f"{payload}\n"
        "\n"
        "CATEGORIES -- choose exactly one token.\n"
        "APPLIED (useful):\n"
        "  cs_algorithms_software   : verified algorithms, verified code generation,\n"
        "                             program/software correctness, coding benchmarks\n"
        "                             (e.g. VERINA, CLEVER, human-eval-lean).\n"
        "  games                    : board / card / video games, puzzles, game engines or\n"
        "                             mechanics (e.g. Chess, Factorio-like, Raylib graphics,\n"
        "                             Slay-the-Spire).\n"
        "  philosophy               : philosophy, social-choice theory, ethics, decision\n"
        "                             theory (e.g. social choice).\n"
        "  logistics                : planning, scheduling, logistics, or formal specs of\n"
        "                             real operational systems.\n"
        "  numerical_floating_point : floating-point, interval arithmetic, numerical methods\n"
        "                             with real computation.\n"
        "  entertainment            : music, art, or other creative / recreational projects.\n"
        "  science                  : natural-science modelling -- chemistry, biology,\n"
        "                             materials, physics experiments (e.g. Lennard-Jones).\n"
        "  smart_contract_crypto    : blockchain, smart contracts, EVM, or cryptographic-\n"
        "                             protocol verification.\n"
        "  traffic_autonomous       : traffic, driving, rail, or vehicle behaviour / safety.\n"
        "  graphics_visual          : graphics, rendering, SVG, diagrams, or visual generation.\n"
        "  physics_dynamics         : physical dynamics, mechanics, motion, or ODEs of\n"
        "                             physical systems.\n"
        "  other_applied            : a genuine standalone real-world / applied domain not\n"
        "                             covered above.\n"
        "NOT USEFUL:\n"
        "  pure_math          : general mathematics with no real-world modelling.\n"
        "  cs_infra           : proof-assistant tooling, metaprogramming, tactic libraries,\n"
        "                       parsers, PL / type theory, generic data structures.\n"
        "  tutorial_or_toy    : teaching exercises, demos, toys.\n"
        "  fork_or_duplicate  : a fork / mirror of another project.\n"
        "  empty_or_trivial   : essentially empty or trivial.\n"
        "\n"
        "Then score in [0,1]:\n"
        "  useful         = quality as a genuine, non-trivial applied formalization. Reserve\n"
        "                   > 0.6 for real domain models. These repos are SUPPLEMENTARY\n"
        "                   MATERIAL whose correctness must be checkable, so PREFER repos that\n"
        "                   actually PROVE theorems / lemmas (see proof_health and\n"
        "                   declaration_kinds above); a repo that only states specifications /\n"
        "                   definitions with no proved theorems, or is riddled with `sorry`,\n"
        "                   is weaker -- lower useful.\n"
        "  vision_related = does the domain have a natural VISUAL or SPATIAL SCENE a vision /\n"
        "                   world-model would perceive? HIGH: traffic / driving scenes, board\n"
        "                   & video games with spatial state (chess, Go, puzzles, tile / grid\n"
        "                   worlds), physical motion / collisions / rigid bodies, geometry /\n"
        "                   shapes / diagrams, graphics / rendering / SVG / images. LOW:\n"
        "                   philosophy, social choice, logistics, smart contracts, crypto,\n"
        "                   verified code / algorithms, floating-point, pure analysis.\n"
        "\n"
        "Answer with ONLY this JSON object, no prose:\n"
        "{\n"
        '  "category": "<one category token from the lists above>",\n'
        '  "real_world_domain": "<2-5 word specific label, or \\"none\\">",\n'
        '  "useful": <0-1, see above>,\n'
        '  "vision_related": <0-1, see above>,\n'
        '  "rationale": "<one sentence>"\n'
        "}\n"
        "HARD RULE: if category is in the NOT USEFUL group, useful must be <= 0.3."
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
    cat = str(obj.get("category", "")).strip().lower()
    if cat not in CATEGORY_SET:
        cat = "pure_math"  # conservative default when the model is vague
    useful = _clamp01(obj.get("useful", 0.0))
    if cat in NOT_USEFUL_CATEGORIES:
        useful = min(useful, 0.3)  # defensive re-application of the hard rule
    return {
        "category": cat,
        "real_world_domain": str(obj.get("real_world_domain", "none"))[:80],
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
    category_counts = Counter(r["category"] for r in records)
    useful_set = [r for r in records
                  if r["category"] in APPLIED_CATEGORIES and r["useful"] >= useful_threshold]
    # proof-backed repos preferred over spec-only (supplementary material must be
    # checkable), then usefulness and vision relevance; grouped by category.
    useful_set.sort(key=lambda r: (r["category"],
                                    PROOF_RANK.get(r.get("proof_status"), 9),
                                    -r["useful"], -r["vision_related"], r["full_name"]))

    per_category = defaultdict(list)
    for r in useful_set:
        per_category[r["category"]].append(r)
    vision_set = [r for r in useful_set if r["vision_related"] >= 0.5]
    proof_dist = Counter(r.get("proof_status") for r in useful_set)

    # useful CSV (grouped by category, proof-backed first within each)
    cols = ["full_name", "category", "real_world_domain", "useful", "vision_related",
            "proof_status", "n_proved", "n_sorry", "rescued",
            "orig_class", "orig_tags", "rationale"]
    with (out_dir / "applied_useful.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in useful_set:
            w.writerow({
                "full_name": r["full_name"],
                "category": r["category"],
                "real_world_domain": r["real_world_domain"],
                "useful": f"{r['useful']:.2f}",
                "vision_related": f"{r['vision_related']:.2f}",
                "proof_status": r.get("proof_status"),
                "n_proved": r.get("n_proved"),
                "n_sorry": r.get("n_sorry"),
                "rescued": r.get("rescued", 0),
                "orig_class": r["orig_class"],
                "orig_tags": r["orig_tags"],
                "rationale": r["rationale"],
            })

    # per-category repo lists (useful set), incl. the important other_applied bucket
    def brief(r):
        return {"full_name": r["full_name"], "real_world_domain": r["real_world_domain"],
                "useful": round(r["useful"], 2), "vision_related": round(r["vision_related"], 2),
                "proof_status": r.get("proof_status"), "rescued": r.get("rescued", 0),
                "rationale": r["rationale"]}

    (out_dir / "categories.json").write_text(json.dumps({
        "category_counts_all": dict(category_counts),
        "useful_threshold": useful_threshold,
        "useful_per_category": {c: [brief(r) for r in per_category[c]]
                                for c in sorted(per_category)},
        "other_applied": [brief(r) for r in per_category.get("other_applied", [])],
    }, indent=2))

    summary = {
        "n_classified": len(records),
        "useful_threshold": useful_threshold,
        "category_counts_all": dict(category_counts),
        "n_useful": len(useful_set),
        "n_useful_vision_related": len(vision_set),
        "useful_counts_per_category": {c: len(per_category[c]) for c in sorted(per_category)},
        "useful_proof_status_distribution": dict(proof_dist),
    }
    (out_dir / "applied_reclass_summary.json").write_text(json.dumps(summary, indent=2))

    print("=" * 72)
    print(f"Classified: {len(records)}   USEFUL (applied & >= {useful_threshold}): "
          f"{len(useful_set)}   vision-related: {len(vision_set)}")
    print("\nuseful repos per applied category:")
    for c in sorted(APPLIED_CATEGORIES):
        n = len(per_category.get(c, []))
        if n:
            print(f"  {c:26} {n:5}")
    print("\nnot-useful categories (set aside):")
    for c in sorted(NOT_USEFUL_CATEGORIES):
        print(f"  {c:26} {category_counts.get(c,0):5}")
    print("\nuseful set by proof status (proof-backed preferred):")
    for st in ["proof_backed", "some_proofs", "incomplete", "spec_only"]:
        print(f"  {st:20} {proof_dist.get(st,0):6}")
    print("-" * 72)
    print(f"Useful set (per-category CSV) -> {out_dir/'applied_useful.csv'}")
    print(f"Per-category lists + other_applied -> {out_dir/'categories.json'}")
    print("=" * 72)


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

    # Rescue map: repos the deep pass judged relevant to ANY target, so genuine
    # applied repos (e.g. the traffic ones) that Stage-1 mis-tagged into core
    # buckets are NOT dropped from the keep set.
    rescue_scores = {}
    if args.classification:
        for r in load_jsonl(Path(args.classification)):
            rel = r.get("relevance", {})
            mt = max([float(rel.get(t, {}).get("topical", 0.0)) for t in TARGET_KEYS], default=0.0)
            ms = max([float(rel.get(t, {}).get("structural", 0.0)) for t in TARGET_KEYS], default=0.0)
            rescue_scores[r.get("full_name")] = (mt, ms)

    # ---- select which repos to classify ----
    targets = []
    n_empty = n_rescued = n_forks = 0
    if args.no_tag_filter:
        # Route the ENTIRE corpus through the LLM: tags NEVER remove anything, so a
        # mis-tagged applied repo cannot be dropped. Only mathlib/forks and empty
        # repos are skipped. The LLM's not-useful categories are the sole filter.
        for name, rec in feats.items():
            if not args.keep_mathlib_forks and is_mathlib_or_fork(rec):
                n_forks += 1
                continue
            if (rec.get("n_named_decls") or 0) == 0:
                n_empty += 1
                continue
            cls, tags = orig.get(name, ("untagged", []))
            targets.append((name, cls, tags, rec, False))
        mode = (f"NO-TAG-FILTER (whole corpus minus {n_forks} mathlib/forks, "
                f"{n_empty} zero-declaration)")
    else:
        # tag-based keep set (+ deep-score rescue) with a zero-declaration pre-filter
        for name, (cls, tags) in orig.items():
            rec = feats.get(name)
            if rec is None:
                continue
            keep = cls in KEEP_CLASSES
            rescued = False
            if not keep and not args.only_other and name in rescue_scores:
                mt, ms = rescue_scores[name]
                if mt >= args.rescue_topical or ms >= args.rescue_structural:
                    keep, rescued = True, True
            if args.only_other and cls != "other_standalone":
                keep = False
            if not keep:
                continue
            if (rec.get("n_named_decls") or 0) == 0:
                n_empty += 1
                continue
            if rescued:
                n_rescued += 1
            targets.append((name, cls, tags, rec, rescued))
        mode = (f"KEEP set (rescued {n_rescued} mis-tagged, skipped "
                f"{n_empty} zero-declaration)")
    if args.limit > 0:
        targets = targets[: args.limit]
    log(f"{mode}: {len(targets)} repos to classify via {args.model}")

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

    async def one(name, cls, tags, rec, rescued):
        content, err = await call_chat(session, sem, cfg, build_prompt(rec))
        return name, cls, tags, rec, rescued, content, err

    done = n_useful = n_fail = 0
    t0 = time.time()
    async with aiohttp.ClientSession(connector=connector) as session:
        tasks = [asyncio.create_task(one(n, c, t, r, x)) for n, c, t, r, x in targets]
        for fut in asyncio.as_completed(tasks):
            name, cls, tags, rec, rescued, content, err = await fut
            done += 1
            parsed = None if (err or content is None) else parse_applied(content)
            if parsed is None:
                ffail.write(json.dumps({"full_name": name, "error": err,
                                        "raw_output": content}, ensure_ascii=False) + "\n")
                n_fail += 1
            else:
                row = {"full_name": name, "orig_class": cls, "orig_tags": ";".join(tags),
                       "rescued": int(rescued), **proof_profile(rec), **parsed,
                       "raw_output": content}
                fout.write(json.dumps(row, ensure_ascii=False) + "\n")
                records.append(row)
                if parsed["category"] in APPLIED_CATEGORIES and parsed["useful"] >= args.useful_threshold:
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
    ap.add_argument("--classification", default="",
                    help="Optional classification.jsonl; rescues mis-tagged applied "
                         "repos (e.g. the traffic ones) that landed in core buckets.")
    ap.add_argument("--rescue-topical", type=float, default=0.3,
                    help="Rescue a non-keep repo if its max target topical >= this.")
    ap.add_argument("--rescue-structural", type=float, default=0.5,
                    help="Rescue a non-keep repo if its max target structural >= this.")
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
    ap.add_argument("--no-tag-filter", action="store_true",
                    help="Route the ENTIRE corpus through the LLM (tags never drop a repo); "
                         "only mathlib/forks and empty repos are skipped. Highest recall, "
                         "most LLM calls. Overrides --only-other.")
    ap.add_argument("--keep-mathlib-forks", action="store_true",
                    help="With --no-tag-filter, do not skip Mathlib and its forks/mirrors.")
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    asyncio.run(run(args))


if __name__ == "__main__":
    main()