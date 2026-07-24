#!/usr/bin/env python3
"""
extract_features.py — Step 1 (full): build one compact feature record per repo.

Unlike corpus_survey.py (a fast, imports-only glimpse), this produces the rich
per-repo record that feeds the LLM classifier in Step 3. Each record bundles the
reliable structured signals plus small excerpts of natural-language context,
kept to a bounded, comparable size (~1–3k tokens) regardless of repo size.

Per repo it collects:
  * deps               — dependency set from lake-manifest.json
  * mathlib_areas      — Mathlib.<Area> histogram (top level)
  * mathlib_submods    — Mathlib.<Area>.<Sub> histogram (two levels, top-N)
  * import_roots       — non-Mathlib import roots (Batteries, Aesop, local, …)
  * structure_flags    — transferable-pattern greps grouped by target domain
  * decl_names         — sample of theorem/def/structure/inductive names
  * proof_health       — sorry/admit, custom axiom, and example counts
  * naming             — snake_case conformance of lemma/theorem names (mathlib_conv)
  * readme_excerpt     — first ~300 words of the README (badges stripped)
  * readme_domain_hits — target keywords found in the README (word-boundary matched)
  * blueprint          — presence + first ~150 words of any .tex (informal math)
  * docstrings         — a few /-- … -/ excerpts
  * metadata           — description, topics, stars, archived, license, commit

Outputs:
  <out-dir>/features.jsonl              one JSON record per line
  <out-dir>/sample_payloads.txt         rendered LLM-ready text for first --samples repos

Usage:
    python extract_features.py \\
        --corpus-dir /path/to/lean_corpus \\
        --out-dir    features_out \\
        --samples    5
"""

import argparse
import json
import os
import re
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed

SKIP_DIRS = {".lake", ".git"}
MAX_FILE_BYTES = 2_000_000

IMPORT_RE = re.compile(r"^\s*import\s+([A-Za-z_][\w.]*)", re.MULTILINE)

DECL_RE = re.compile(
    r"^\s*(?:@\[[^\]]*\]\s*)*"
    r"(?:private\s+|protected\s+|noncomputable\s+|nonrec\s+|scoped\s+|local\s+|partial\s+|unsafe\s+)*"
    r"(theorem|lemma|def|abbrev|structure|inductive|class|instance)\s+([A-Za-z_][\w'.]*)",
    re.MULTILINE,
)

DOCSTRING_RE = re.compile(r"/--(.*?)-/", re.DOTALL)
SNAKE_RE = re.compile(r"^[a-z][a-z0-9]*(_[a-z0-9]+)*'?$")

# --- proof-health signals (maturity / reusability) -------------------------
# sorry/admit  -> unfinished proofs (incomplete formalization)
# axiom        -> user-declared assumptions (Lean's trusted built-ins propext/
#                 Classical.choice/Quot.sound are NOT written with this keyword,
#                 so this counts only custom, repo-introduced axioms)
# example      -> anonymous, non-reusable checks; tutorials/tests are mostly these
SORRY_RE   = re.compile(r"\b(?:sorry|admit)\b")
AXIOM_RE   = re.compile(r"^\s*axiom\s+[A-Za-z_]", re.MULTILINE)
EXAMPLE_RE = re.compile(r"^\s*example\b", re.MULTILINE)

# Transferable-pattern greps, grouped by target domain. Booleans per repo.
STRUCTURE_FLAGS = {
    # traffic / self-driving
    "state_machine":   re.compile(r"inductive\s+\w*State\b|\bTransition\b|\bstep\s*:"),
    "reachability":    re.compile(r"Relation\.ReflTransGen|\bReachable\b|\bReaches\b"),
    "safety_invariant":re.compile(r"\bInvariant\b|\bSafe(ty)?\b|\bne_collision\b|\bnoCollision\b"),
    # tightened: dropped bare \bLanguage\b (fires on "the Lean language"); require
    # a genuine automata token instead.
    "automata":        re.compile(r"Computability\.|\bDFA\b|\bNFA\b|\bAutomaton\b|\bRegularExpression\b|\bFormalLang"),
    "temporal":        re.compile(r"\bLTL\b|\bCTL\b|\bAlways\b|\bEventually\b|\bUntil\b"),
    # physion / physics
    "ode":             re.compile(r"Analysis\.ODE|\bODE\b|\bHasDerivAt\b|\bgronwall\b", re.I),
    "deriv":           re.compile(r"\bfderiv\b|\bderiv\b|\bHasFDerivAt\b"),
    "dynamics":        re.compile(r"Dynamics\.|\bflow\b|\borbit\b"),
    "physics_vocab":   re.compile(r"\bvelocity\b|\bforce\b|\bmomentum\b|\brigid\b|\bkinematic|\bmass\b", re.I),
    "measure":         re.compile(r"MeasureTheory\.|\bMeasurable\b"),
    # visual generation / geometry
    "geometry_euclid": re.compile(r"Geometry\.Euclidean|EuclideanSpace|\bInnerProductSpace\b"),
    "affine_coord":    re.compile(r"\bAffineMap\b|\bAffineSubspace\b|\bcoord|\bcollinear\b", re.I),
    "graphics":        re.compile(r"\bSVG\b|\brender\b|\bcanvas\b|\bpixel\b|\bdraw\b", re.I),
    # DSL / program synthesis
    "dsl_ast":         re.compile(r"inductive\s+\w*(Expr|Term|Ast|Prog|Stmt)\b"),
    "interpreter":     re.compile(r"\bdef\s+eval\b|\bdenote\b|\binterp\b"),
    # tightened: dropped bare \bconstraint\b / \bsolver\b (both common in pure
    # math); require an explicit synthesis / solver-in-context token.
    "synthesis":       re.compile(r"program\s+synthesi[sz]|\bSyGuS\b|\bSMT\b|constraint\s+solv|sketch\s+synthesi", re.I),
}

# README domain keywords → target buckets.
# Matched with WORD BOUNDARIES (see domain_hits), so short substrings like "ode"
# ⊂ model/node or "train" ⊂ constraint no longer produce false hits. Generic
# single words that were pure noise ("ode", "train", "signal", "force", "vector",
# "language", "motion", "shape", "image", "figure") have been dropped in favour
# of discriminative words and multi-word phrases.
_DOMAIN_KW_RAW = {
    "traffic":   ["traffic", "vehicle", "self-driving", "autonomous driving",
                  "railway", "interlocking", "collision avoidance", "lane",
                  "pedestrian", "intersection"],
    "physion":   ["physics", "rigid body", "kinematic", "kinematics",
                  "differential equation", "newtonian", "trajectory",
                  "dynamical system", "simulation"],
    "visual":    ["geometry", "rendering", "graphics", "svg", "raster",
                  "bounding box", "polygon", "diagram", "drawing", "scene graph"],
    "synthesis": ["program synthesis", "domain-specific language", "dsl",
                  "interpreter", "operational semantics", "denotational",
                  "grammar", "type system", "compiler"],
}
DOMAIN_KEYWORDS = {
    target: [(w, re.compile(rf"\b{re.escape(w)}\b", re.I)) for w in words]
    for target, words in _DOMAIN_KW_RAW.items()
}

README_MAX_WORDS = 450
BLUEPRINT_MAX_WORDS = 150

# README sections whose *heading* marks them as non-substantive boilerplate.
# We drop these sections so the excerpt budget is spent on what the repo is
# about, not on build/install/license chatter.
BOILERPLATE_HEADINGS = re.compile(
    r"^(?:installation|install|build(?:ing)?|how\s+to\s+build|usage|getting\s+started|"
    r"quick\s*start|setup|set\s+up|licen[cs]e|contributing|contribution|contributors|"
    r"table\s+of\s+contents|contents|requirements?|dependenc(?:y|ies)|"
    r"acknowledge?ments?|citation|references?|development|tests?|testing|ci|"
    r"changelog|todo)\b",
    re.I,
)
MAX_DOCSTRINGS = 4
DOCSTRING_MAX_WORDS = 40
MAX_DECL_NAMES = 30
MAX_SUBMODS = 15


# ---------------------------------------------------------------------------
# IO helpers
# ---------------------------------------------------------------------------

def read_text(path):
    try:
        if os.path.getsize(path) > MAX_FILE_BYTES:
            return ""
        with open(path, errors="replace") as f:
            return f.read()
    except Exception:
        return ""


def parse_dependencies(repo_path):
    manifest = None
    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        if "lake-manifest.json" in files:
            manifest = os.path.join(root, "lake-manifest.json")
            break
    if not manifest:
        return set()
    try:
        with open(manifest, errors="replace") as f:
            data = json.load(f)
    except Exception:
        return set()
    names = set()
    for pkg in data.get("packages", []) if isinstance(data.get("packages"), list) else []:
        if isinstance(pkg, dict):
            if pkg.get("name"):
                names.add(str(pkg["name"]).lower())
            else:
                for v in pkg.values():
                    if isinstance(v, dict) and v.get("name"):
                        names.add(str(v["name"]).lower())
    return names


def read_metadata(repo_path):
    p = os.path.join(repo_path, "metadata.json")
    if os.path.exists(p):
        try:
            with open(p, errors="replace") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


# ---------------------------------------------------------------------------
# README / blueprint
# ---------------------------------------------------------------------------

def strip_markdown(text):
    lines = []
    for ln in text.splitlines():
        s = ln.strip()
        if s.startswith("![") or s.startswith("[!") or s.startswith("<"):
            continue  # badges / html
        s = re.sub(r"[#*`>_]", "", s)
        lines.append(s)
    return "\n".join(lines)


def substantive_readme(readme_raw):
    """Drop boilerplate sections (install/build/license/…) from a markdown
    README and return the remaining text, preamble (title/intro) first.

    Only ATX headings (``# …``) are used to delimit sections — that keeps the
    logic robust against ``---`` thematic breaks / YAML front matter that would
    trip setext detection. A heading matching BOILERPLATE_HEADINGS switches the
    section off; the next content heading switches it back on. If filtering
    removes everything (unusual layout), fall back to the raw README so we never
    hand the classifier an empty excerpt.
    """
    kept = []
    keep_current = True   # text before the first heading is always kept
    for ln in readme_raw.splitlines():
        m = re.match(r"^\s*#{1,6}\s+(.*\S)\s*$", ln)
        if m:
            heading = m.group(1).strip()
            keep_current = not BOILERPLATE_HEADINGS.match(heading)
            if keep_current:
                kept.append(heading)   # keep the heading text as context
            continue
        if keep_current:
            kept.append(ln)
    text = "\n".join(kept)
    return text if text.strip() else readme_raw


def find_readme(repo_path):
    # root first, then shallow
    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if fname.lower().startswith("readme"):
                return read_text(os.path.join(root, fname))
    return ""


def find_blueprint(repo_path):
    """Locate a blueprint .tex and return (has_blueprint, clean_excerpt).

    Prefers .tex files under a path containing 'blueprint' (the Lean convention),
    then falls back to any .tex. The excerpt drops %-comment lines, starts after
    \\begin{document} when present, and strips TeX commands/markup so the words
    returned are actual mathematical prose rather than preamble noise.
    """
    tex_paths = []
    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if fname.endswith(".tex"):
                tex_paths.append(os.path.join(root, fname))
    if not tex_paths:
        return False, ""

    preferred = [p for p in tex_paths if "blueprint" in p.lower()]
    chosen = (preferred or tex_paths)[0]
    txt = read_text(chosen)

    # drop full-line TeX comments
    body = "\n".join(ln for ln in txt.splitlines() if not ln.lstrip().startswith("%"))
    # skip preamble
    m = re.search(r"\\begin\{document\}", body)
    if m:
        body = body[m.end():]
    # strip commands (\foo, \foo*) then residual markup chars
    body = re.sub(r"\\[A-Za-z]+\*?", " ", body)
    body = re.sub(r"[%\\{}$&]", " ", body)
    words = body.split()
    return True, " ".join(words[:BLUEPRINT_MAX_WORDS])


def first_words(text, n):
    return " ".join(text.split()[:n])


def domain_hits(readme_clean):
    """Word-boundary keyword hits per target bucket (case-insensitive)."""
    hits = {}
    for target, pairs in DOMAIN_KEYWORDS.items():
        found = [w for (w, pat) in pairs if pat.search(readme_clean)]
        if found:
            hits[target] = found
    return hits


# ---------------------------------------------------------------------------
# Per-repo analysis
# ---------------------------------------------------------------------------

def analyze_repo(repo_path):
    areas = Counter()       # Mathlib.<Area>
    submods = Counter()     # Mathlib.<Area>.<Sub>
    roots = Counter()       # import root
    per_file_decls = []     # list-of-lists, one per .lean file (for round-robin sampling)
    decl_kinds = Counter()
    docstrings = []
    flags = {k: False for k in STRUCTURE_FLAGS}
    lemma_names = []
    n_lean = n_lines = 0
    n_sorry = n_axiom = n_example = 0

    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if not fname.endswith(".lean"):
                continue
            n_lean += 1
            text = read_text(os.path.join(root, fname))
            if not text:
                continue
            n_lines += text.count("\n") + 1

            # proof-health counts
            n_sorry += len(SORRY_RE.findall(text))
            n_axiom += len(AXIOM_RE.findall(text))
            n_example += len(EXAMPLE_RE.findall(text))

            for module in IMPORT_RE.findall(text):
                parts = module.split(".")
                r = parts[0]
                roots[r] += 1
                if r == "Mathlib" and len(parts) > 1:
                    areas[parts[1]] += 1
                    if len(parts) > 2:
                        submods[f"{parts[1]}.{parts[2]}"] += 1

            file_decls = []
            for kind, name in DECL_RE.findall(text):
                decl_kinds[kind] += 1
                short = name.split(".")[-1]
                file_decls.append(name)
                if kind in ("theorem", "lemma"):
                    lemma_names.append(short)
            if file_decls:
                per_file_decls.append(file_decls)

            if len(docstrings) < MAX_DOCSTRINGS:
                for d in DOCSTRING_RE.findall(text):
                    ds = " ".join(d.split())
                    if len(ds) > 15:
                        docstrings.append(first_words(ds, DOCSTRING_MAX_WORDS))
                    if len(docstrings) >= MAX_DOCSTRINGS:
                        break

            for name, pat in STRUCTURE_FLAGS.items():
                if not flags[name] and pat.search(text):
                    flags[name] = True

    # Round-robin the declaration sample across files: take the 1st decl from
    # each file, then the 2nd from each, … up to MAX_DECL_NAMES. This gives the
    # classifier a cross-file view instead of dumping the first file's decls.
    decl_names = []
    depth = 0
    while len(decl_names) < MAX_DECL_NAMES and per_file_decls:
        advanced = False
        for fdecls in per_file_decls:
            if depth < len(fdecls):
                decl_names.append(fdecls[depth])
                advanced = True
                if len(decl_names) >= MAX_DECL_NAMES:
                    break
        if not advanced:
            break
        depth += 1

    # snake_case conformance over lemma/theorem names (mathlib_conv signal)
    if lemma_names:
        snake = sum(1 for nm in lemma_names if SNAKE_RE.match(nm))
        conformance = round(snake / len(lemma_names), 3)
    else:
        conformance = None

    deps = parse_dependencies(repo_path)
    meta = read_metadata(repo_path)

    readme_raw = find_readme(repo_path)
    readme_body = substantive_readme(readme_raw)      # drop install/build/license sections
    readme_clean = strip_markdown(readme_body)
    readme_excerpt = first_words(readme_clean, README_MAX_WORDS)
    r_hits = domain_hits(readme_clean)                # hits searched over full substantive body

    has_bp, bp_excerpt = find_blueprint(repo_path)

    primary_area = areas.most_common(1)[0][0] if areas else "non-mathlib"

    # named, reusable declarations (theorem/lemma/def/abbrev/structure/inductive/
    # class/instance) vs. anonymous examples — a library-vs-tutorial signal.
    n_named_decls = sum(decl_kinds.values())

    record = {
        "deps": sorted(deps),
        "uses_mathlib": ("mathlib" in deps) or bool(areas),
        "primary_area": primary_area,
        "mathlib_areas": dict(areas.most_common()),
        "mathlib_submods": dict(submods.most_common(MAX_SUBMODS)),
        "import_roots": dict(roots.most_common(15)),
        "structure_flags": [k for k, v in flags.items() if v],
        "decl_kinds": dict(decl_kinds),
        "decl_names": decl_names,
        "n_named_decls": n_named_decls,
        "n_sorry": n_sorry,
        "n_axiom": n_axiom,
        "n_example": n_example,
        "naming_snake_conformance": conformance,
        "n_lemmas_sampled": len(lemma_names),
        "readme_excerpt": readme_excerpt,
        "readme_domain_hits": r_hits,
        "has_blueprint": has_bp,
        "blueprint_excerpt": bp_excerpt,
        "docstrings": docstrings,
        "n_lean_files": n_lean,
        "n_lines": n_lines,
        "description": meta.get("description"),
        "topics": meta.get("topics", []),
        "stars": meta.get("stars"),
        "archived": meta.get("archived"),
        "license": meta.get("license"),
        "commit_sha": meta.get("commit_sha"),
    }
    return record


# ---------------------------------------------------------------------------
# Render an LLM-ready payload from a record
# ---------------------------------------------------------------------------

def render_payload(rec):
    def kv(d):
        return ", ".join(f"{k}:{v}" for k, v in d.items()) if d else "(none)"

    lines = [
        f"REPO: {rec['full_name']}",
        f"stars: {rec.get('stars')}  topics: {rec.get('topics')}",
        f"description: {rec.get('description') or '(none)'}",
        f"dependencies: {', '.join(rec['deps']) or '(none)'}",
        f"primary_area: {rec['primary_area']}",
        f"mathlib_areas: {kv(rec['mathlib_areas'])}",
        f"mathlib_submodules: {kv(rec['mathlib_submods'])}",
        f"import_roots: {kv(rec['import_roots'])}",
        f"structure_flags: {', '.join(rec['structure_flags']) or '(none)'}",
        f"declaration_kinds: {kv(rec['decl_kinds'])}",
        f"proof_health: sorry/admit:{rec['n_sorry']}  custom_axioms:{rec['n_axiom']}  "
        f"examples:{rec['n_example']}  named_decls:{rec['n_named_decls']}",
        f"sample_declarations: {', '.join(rec['decl_names'][:20]) or '(none)'}",
        f"snake_case_conformance: {rec['naming_snake_conformance']} "
        f"(over {rec['n_lemmas_sampled']} lemmas)",
        f"readme_domain_hits: {rec['readme_domain_hits'] or '(none)'}",
        f"has_blueprint: {rec['has_blueprint']}",
    ]
    if rec["readme_excerpt"]:
        lines.append(f"README_excerpt: {rec['readme_excerpt']}")
    if rec["blueprint_excerpt"]:
        lines.append(f"blueprint_excerpt: {rec['blueprint_excerpt']}")
    if rec["docstrings"]:
        lines.append("docstrings: " + " || ".join(rec["docstrings"]))
    return "\n".join(lines)


def est_tokens(text):
    # rough: ~1.3 tokens per whitespace word
    return int(len(text.split()) * 1.3)


# ---------------------------------------------------------------------------
# Corpus walk + main
# ---------------------------------------------------------------------------

def iter_repos(corpus_dir):
    for owner in sorted(os.listdir(corpus_dir)):
        owner_path = os.path.join(corpus_dir, owner)
        if not os.path.isdir(owner_path) or owner in SKIP_DIRS:
            continue
        for repo in sorted(os.listdir(owner_path)):
            repo_path = os.path.join(owner_path, repo)
            if os.path.isdir(repo_path):
                yield owner, repo, repo_path


def _worker(task):
    """Top-level (picklable) worker for the process pool."""
    idx, owner, repo, path = task
    rec = analyze_repo(path)
    rec["owner"] = owner
    rec["repo"] = repo
    rec["full_name"] = f"{owner}/{repo}"
    return idx, rec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--corpus-dir", required=True)
    ap.add_argument("--out-dir", default="features_out")
    ap.add_argument("--samples", type=int, default=5,
                    help="How many rendered payloads to dump for inspection")
    ap.add_argument("--workers", type=int, default=os.cpu_count() or 4,
                    help="Parallel worker processes (default: CPU count). Use 1 to disable.")
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    jsonl_path = os.path.join(args.out_dir, "features.jsonl")
    sample_path = os.path.join(args.out_dir, "sample_payloads.txt")

    tasks = [(i, owner, repo, path)
             for i, (owner, repo, path) in enumerate(iter_repos(args.corpus_dir))]
    total = len(tasks)
    print(f"Repos to extract: {total}   workers: {args.workers}")

    n = 0
    tok_total = 0
    tok_max = 0
    samples = {}   # idx -> payload, for the first --samples repos (deterministic)

    def handle(idx, rec, fout):
        nonlocal n, tok_total, tok_max
        fout.write(json.dumps(rec) + "\n")
        payload = render_payload(rec)
        t = est_tokens(payload)
        tok_total += t
        tok_max = max(tok_max, t)
        if idx < args.samples:
            samples[idx] = payload
        n += 1
        if n % 500 == 0:
            print(f"  … {n}/{total} repos extracted", flush=True)

    with open(jsonl_path, "w") as fout:
        if args.workers <= 1:
            for task in tasks:
                idx, rec = _worker(task)
                handle(idx, rec, fout)
        else:
            with ProcessPoolExecutor(max_workers=args.workers) as pool:
                # chunksize keeps per-task IPC overhead low for many small repos
                for idx, rec in pool.map(_worker, tasks, chunksize=8):
                    handle(idx, rec, fout)

    with open(sample_path, "w") as fsample:
        for idx in sorted(samples):
            fsample.write(samples[idx] + "\n" + ("-" * 60) + "\n")

    avg = round(tok_total / n) if n else 0
    print(f"\nExtracted {n} repos → {jsonl_path}")
    print(f"Payload token estimate: avg {avg}, max {tok_max}")
    print(f"Sample payloads ({len(samples)}) → {sample_path}")


if __name__ == "__main__":
    main()