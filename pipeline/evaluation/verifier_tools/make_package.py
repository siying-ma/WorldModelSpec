"""Build a self-contained verifier package from one run of the pipeline.

    python3 make_package.py <run> [--out DIR] [--no-build] [--tar]

The package's sources: `../verifier/template/` (the `verify` command, its Python API, `install.sh` and
the package README) and `lean_src/Explain.lean` (a link to the delivered package's copy, the one
source of the explainer).

The package holds: the full split's Core, the rules and concepts the run holds (its accepted
records and its base chain's, fenced ones left out, as the harness's own view gives them), the
monitor, the run's reading, the rule-to-law table, the ontology's atom ids, and the `verify`
command with its Python API (`template/`). The pipeline tree is only read: the library is copied,
and the harness code that names the run's records is imported without writing bytecode.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
EVAL = HERE.parent
TEMPLATE = EVAL / "verifier" / "template"
PIPELINE = EVAL.parent / "traffic-spec-agent"
LIB = PIPELINE / "library"

LAKEFILE = """import Lake
open Lake DSL

package «traffic-verifier» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

-- The frozen Core of the full split, the registered rules and concepts, and the index.
@[default_target]
lean_lib «TrafficSpec» where
  srcDir := "."

-- The monitor: decodes a trace at run time and evaluates the registered rules.
lean_exe «monitor» where
  root := `Main

-- Why a rule has its verdict at one observation: the obligation walked with the monitor's evaluator.
lean_exe «explain» where
  root := `Explain
"""


def digest(paths) -> str:
    h = hashlib.sha256()
    for p in sorted(paths):
        h.update(p.as_posix().encode()); h.update(p.read_bytes())
    return h.hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("run")
    ap.add_argument("--out", type=Path)
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--tar", action="store_true", help="also write <out>.tar.gz (without the build directory)")
    a = ap.parse_args()
    run_dir = PIPELINE / "results" / a.run
    if not (run_dir / "reading.json").exists():
        sys.exit(f"no run {a.run} under {PIPELINE / 'results'}")
    out = (a.out or Path.cwd() / f"traffic-verifier-{a.run}").resolve()
    if out.exists():
        sys.exit(f"{out} exists: remove it or choose --out")
    lean = out / "lean"

    # 1. The library: root files, the full split's Core, the run's rules and concepts.
    shutil.copytree(TEMPLATE, out, ignore=shutil.ignore_patterns("__pycache__"))
    lean.mkdir()
    for f in ("Main.lean", "TrafficSpec.lean", "lean-toolchain", "lake-manifest.json"):
        shutil.copy2(LIB / f, lean / f)
    (lean / "lakefile.lean").write_text(LAKEFILE, encoding="utf-8")
    shutil.copy2(HERE / "lean_src" / "Explain.lean", lean / "Explain.lean")
    # Core as the library holds it, then the full split's variant files over it (the library may
    # hold the training variant; the monitor needs the full one).
    shutil.copytree(LIB / "TrafficSpec" / "Core", lean / "TrafficSpec" / "Core")
    shutil.copy2(LIB / "TrafficSpec" / "Core.lean", lean / "TrafficSpec" / "Core.lean")
    shutil.copytree(LIB / "splits" / "full" / "TrafficSpec", lean / "TrafficSpec", dirs_exist_ok=True)
    for sub in ("Rules", "Concepts"):
        if (LIB / "TrafficSpec" / sub).exists():
            shutil.copytree(LIB / "TrafficSpec" / sub, lean / "TrafficSpec" / sub)
    snap = run_dir / "library_snapshot" / "TrafficSpec"
    if snap.exists():                      # an archived run: its own rule and concept files win
        for sub in ("Rules", "Concepts"):
            if (snap / sub).exists():
                shutil.copytree(snap / sub, lean / "TrafficSpec" / sub, dirs_exist_ok=True)
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    subprocess.run([sys.executable, "-B", str(EVAL / "lib" / "register_accepted.py"), str(lean), str(run_dir),
                    str(PIPELINE)], check=True, env=env)
    registered = json.loads((out / "registered.json").read_text())
    (out / "registered.json").unlink()

    # 2. Data: reading, rule-to-law table with the posted law text, atom ids, a default manifest.
    data = out / "data"
    data.mkdir()
    shutil.copy2(run_dir / "reading.json", data / "reading.json")
    corpus = {}
    for line in (PIPELINE / "laws" / "full_list" / "laws.jsonl").read_text(encoding="utf-8").splitlines():
        if line.strip():
            d = json.loads(line); corpus[d["id"]] = d
    rules = {r: {"law": v["law"], "title": corpus.get(v["law"], {}).get("title", ""),
                 "text": corpus.get(v["law"], {}).get("text", "")} for r, v in registered["rules"].items()}
    (data / "rules.json").write_text(json.dumps({"run": a.run, "chain": registered["chain"], "rules": rules},
                                                indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    ids_src = (lean / "TrafficSpec/Core/Vocab/Ontology/Ids.lean").read_text(encoding="utf-8")
    ids = re.findall(r'"([^"]+)"', ids_src.split("def atomIds : List String := [", 1)[1].split("]", 1)[0])
    (data / "atom_ids.json").write_text(json.dumps(ids, indent=1) + "\n")
    (data / "default_manifest.json").write_text(json.dumps(
        {"source": "default: every atom observed", "reid_gap": 0, "atoms": {i: "exact" for i in ids}}, indent=1) + "\n")

    # 3. Provenance.
    def git(*args):
        try:
            return subprocess.run(["git", "-C", str(PIPELINE), *args], capture_output=True, text=True).stdout.strip()
        except OSError:
            return ""
    (out / "PROVENANCE.json").write_text(json.dumps({
        "built": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "run": a.run, "chain": registered["chain"],
        "rules": sorted(rules), "concepts": registered["concepts"], "fenced": registered["fenced"],
        "git_commit": git("rev-parse", "HEAD"), "git_dirty": bool(git("status", "--porcelain", "--", ".")),
        "core_sha256": digest(list((lean / "TrafficSpec" / "Core").rglob("*.lean"))),
        "atoms": len(ids)}, indent=1) + "\n")
    print(f"== package for run {a.run} in {out}: {len(rules)} rule(s), {len(registered['concepts'])} concept(s)")

    # 4. Build, and optionally pack the source (the build directory is left out).
    if a.tar:
        with tarfile.open(f"{out}.tar.gz", "w:gz") as t:
            t.add(out, arcname=out.name, filter=lambda ti: None if "/.lake" in ti.name else ti)
        print(f"== wrote {out}.tar.gz")
    if not a.no_build:
        subprocess.run(["bash", str(out / "install.sh")], check=True)


if __name__ == "__main__":
    main()
