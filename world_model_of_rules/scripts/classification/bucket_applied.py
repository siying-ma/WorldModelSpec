"""Further-classify the corpus from Stage-1 triage tags to surface APPLIED /
real-world-domain Lean repos (the broad net for the world-model / vision corpus).

Deterministic, no LLM calls. Reads triage.jsonl (which carries the Stage-1 domain
tags for EVERY repo, candidate or not) and groups the 28-tag taxonomy into:

  APPLIED     physics_formalization, dynamical_systems, game_theory,
              software_verification, hardware_verification, cryptography
              -> real-world / domain-modeling repos (KEEP)
  CORE_MATH   algebra, analysis, topology, geometry, number_theory,
              logic_set_theory, category_theory, probability_measure,
              combinatorics, order_lattice, linear_algebra,
              differential_equations, graph_theory, competition_math
              -> pure-math infrastructure (set aside; too generic)
  CORE_CS     automata_formal_languages, type_theory_pl, program_semantics,
              program_synthesis_dsl, data_structures_algorithms,
              tooling_metaprogramming
              -> CS infrastructure (set aside)
  SPECIAL     education_tutorial (KEEP only if NOT co-tagged core CS/math, i.e.
              a tutorial ABOUT a real-world domain), other (KEEP: niche/standalone)

Each repo is assigned a single `class` by priority:
  applied > education_applied > other_standalone > untagged > core_cs > core_math

The KEEP set = {applied, education_applied, other_standalone, untagged}. Even
tags with only 1-2 repos are surfaced (standalone repos are useful).

Optionally joins classification.jsonl to attach the per-target topical/structural
scores (visual_gen first, since vision is the headline goal).

Outputs (in --out-dir):
  tag_histogram.csv        tag, group, n_repos
  applied_candidates.csv   one row per KEEP repo, with tags, class, co_core, scores
  buckets.json             per-tag repo lists + per-class lists + the keep set
  (prints a summary table)

Usage
-----
    python bucket_applied.py \\
        --triage classify_out/triage.jsonl \\
        --classification classify_out/classification.jsonl \\
        --out-dir classify_out/applied
"""

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

# --------------------------------------------------------------------------- #
# Tag taxonomy groups (must cover all 28 Stage-1 tags)
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

ALL_TAGS = APPLIED | CORE_MATH | CORE_CS | SPECIAL

TARGETS = ["visual_gen", "physion", "traffic", "mathlib_conventions"]  # visual first

KEEP_CLASSES = {"applied", "education_applied", "other_standalone", "untagged"}


def group_of(tag: str) -> str:
    if tag in APPLIED:
        return "applied"
    if tag in CORE_MATH:
        return "core_math"
    if tag in CORE_CS:
        return "core_cs"
    if tag in SPECIAL:
        return "special"
    return "unknown"


def classify(tags: list[str]):
    """Return (class, applied_tags:list, co_core:bool)."""
    T = set(tags)
    applied = sorted(T & APPLIED)
    core_math = T & CORE_MATH
    core_cs = T & CORE_CS
    has_core = bool(core_math or core_cs)
    co_core = has_core  # flag: keep-repo that also carries a core CS/math tag

    if applied:
        return "applied", applied, co_core
    if "education_tutorial" in T and not has_core:
        return "education_applied", [], co_core
    if "other" in T:
        return "other_standalone", [], co_core
    if not T:
        return "untagged", [], False
    if core_cs and not core_math:
        return "core_cs", [], co_core
    return "core_math", [], co_core


# --------------------------------------------------------------------------- #
# IO
# --------------------------------------------------------------------------- #

def load_jsonl(path: Path):
    out = []
    with path.open() as f:
        for line in f:
            line = line.strip()
            if line:
                out.append(json.loads(line))
    return out


def build_score_map(classification_path: Path):
    """full_name -> {target: (topical, structural), confidence}."""
    m = {}
    if not classification_path or not classification_path.exists():
        return m
    for r in load_jsonl(classification_path):
        rel = r.get("relevance", {})
        cell = {t: (float(rel.get(t, {}).get("topical", 0.0)),
                    float(rel.get(t, {}).get("structural", 0.0))) for t in TARGETS}
        cell["confidence"] = float(r.get("confidence", 0.0))
        m[r.get("full_name")] = cell
    return m


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--triage", required=True, help="Path to triage.jsonl")
    ap.add_argument("--classification", default="",
                    help="Optional classification.jsonl to attach topical/structural scores")
    ap.add_argument("--out-dir", required=True)
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    rows = load_jsonl(Path(args.triage))
    scores = build_score_map(Path(args.classification)) if args.classification else {}

    tag_hist = Counter()
    unknown_tags = Counter()
    class_counts = Counter()
    per_tag_repos = defaultdict(list)      # tag -> [full_name]
    keep_records = []                      # rows for applied_candidates.csv
    per_class = defaultdict(list)          # class -> [full_name]

    for r in rows:
        name = r.get("full_name")
        tags = [t for t in (r.get("tags") or [])]
        for t in tags:
            tag_hist[t] += 1
            per_tag_repos[t].append(name)
            if t not in ALL_TAGS:
                unknown_tags[t] += 1
        cls, applied_tags, co_core = classify(tags)
        class_counts[cls] += 1
        per_class[cls].append(name)

        if cls in KEEP_CLASSES:
            rec = {
                "full_name": name,
                "class": cls,
                "applied_tags": ";".join(applied_tags),
                "all_tags": ";".join(tags),
                "co_core": int(co_core),
            }
            sc = scores.get(name)
            if scores:  # only add score columns if a classification file was given
                for t in TARGETS:
                    top, struc = (sc[t] if sc else (0.0, 0.0))
                    rec[f"{t}_topical"] = f"{top:.2f}"
                    rec[f"{t}_structural"] = f"{struc:.2f}"
                rec["confidence"] = f"{(sc['confidence'] if sc else 0.0):.2f}"
                rec["deep_classified"] = int(sc is not None)
            keep_records.append(rec)

    # ---- tag_histogram.csv ----
    with (out_dir / "tag_histogram.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["tag", "group", "n_repos"])
        for tag, n in tag_hist.most_common():
            w.writerow([tag, group_of(tag), n])

    # ---- applied_candidates.csv (sorted: applied first, then by visual_gen struct) ----
    class_rank = {"applied": 0, "education_applied": 1, "other_standalone": 2, "untagged": 3}

    def sort_key(rec):
        vg = float(rec.get("visual_gen_structural", 0.0) or 0.0) if scores else 0.0
        return (class_rank.get(rec["class"], 9), rec["co_core"], -vg, rec["full_name"])

    keep_records.sort(key=sort_key)
    cols = ["full_name", "class", "applied_tags", "all_tags", "co_core"]
    if scores:
        for t in TARGETS:
            cols += [f"{t}_topical", f"{t}_structural"]
        cols += ["confidence", "deep_classified"]
    with (out_dir / "applied_candidates.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for rec in keep_records:
            w.writerow(rec)

    # ---- buckets.json ----
    buckets = {
        "n_triaged": len(rows),
        "n_keep": len(keep_records),
        "class_counts": dict(class_counts),
        "keep_classes": sorted(KEEP_CLASSES),
        "applied_tag_lists": {t: sorted(set(per_tag_repos[t]))
                              for t in sorted(APPLIED) if t in per_tag_repos},
        "special_tag_lists": {t: sorted(set(per_tag_repos[t]))
                              for t in sorted(SPECIAL) if t in per_tag_repos},
        "per_class_repos": {c: sorted(v) for c, v in per_class.items()},
    }
    (out_dir / "buckets.json").write_text(json.dumps(buckets, indent=2))

    # ---- printed summary ----
    print("=" * 68)
    print(f"Triaged repos: {len(rows)}   KEEP (applied/real-world): {len(keep_records)}")
    print("\nclass breakdown:")
    for c in ["applied", "education_applied", "other_standalone", "untagged",
              "core_cs", "core_math"]:
        mark = " (keep)" if c in KEEP_CLASSES else ""
        print(f"  {c:20} {class_counts.get(c,0):6}{mark}")

    print("\nAPPLIED tag counts (the real-world buckets, incl. long tail):")
    for t in sorted(APPLIED, key=lambda x: -tag_hist.get(x, 0)):
        print(f"  {t:26} {tag_hist.get(t,0):6}")
    print(f"  {'education_tutorial':26} {tag_hist.get('education_tutorial',0):6}  "
          f"(kept only when not core CS/math)")
    print(f"  {'other':26} {tag_hist.get('other',0):6}")

    if unknown_tags:
        print("\nWARNING: tags not in the known taxonomy:", dict(unknown_tags))

    print("-" * 68)
    print(f"Applied candidate list -> {out_dir/'applied_candidates.csv'}")
    print(f"Per-tag / per-class repo lists -> {out_dir/'buckets.json'}")
    print(f"Tag histogram -> {out_dir/'tag_histogram.csv'}")
    print("=" * 68)


if __name__ == "__main__":
    main()
