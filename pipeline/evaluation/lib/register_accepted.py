"""Rewrite a library copy's registry (TrafficSpec/Index.lean) so it holds exactly the rules and
concepts a run holds, and nothing a coding session may still be writing.

    python3 register_accepted.py <library copy> <run results dir> <pipeline root>

What a run holds is the harness's own read-only view of it (`base_view`): its accepted records and
those of its base chain, a later run's record replacing an earlier one of the same id, and a base
node of a law the run planned again left out. A fenced version is kept on disk but not registered,
as the harness keeps it out of every registry build. Files on disk that no record names are removed
from the copy, so a half-written node never enters the monitor's build. The registered rules and
the law each formalizes are written to `registered.json` beside the copy. Only the copy is touched.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main(lib: Path, run_dir: Path, pipeline_root: Path) -> None:
    sys.path.insert(0, str(pipeline_root))
    from harness.model import nodeid  # module and namespace names, as the harness derives them
    from harness.store import paths
    from harness.store.state import base_view

    if run_dir.resolve() != paths.run_dir(run_dir.name).resolve():
        sys.exit(f"{run_dir} is not a run of {paths.RESULTS}")
    view = base_view(run_dir.name)
    fenced = set(view["fenced"])
    nodes = [n for n in view["nodes"] if n not in fenced]
    concepts = [c for c in view["concepts"] if c not in fenced]
    if not nodes:
        sys.exit(f"{run_dir} holds no accepted node: nothing to evaluate")

    keep = {nodeid.rule_path(n) for n in view["nodes"]} | {nodeid.concept_path(c) for c in view["concepts"]}
    for sub in ("TrafficSpec/Rules", "TrafficSpec/Concepts"):
        for f in (lib / sub).rglob("*.lean"):
            if f.relative_to(lib).as_posix() not in keep:
                f.unlink()
    missing = sorted(k for k in keep if not (lib / k).exists())
    if missing:
        sys.exit(f"accepted files missing from the library: {missing}")

    imports = "".join(f"import {nodeid.rule_module(n)}\n" for n in nodes) + \
              "".join(f"import {nodeid.concept_module(c)}\n" for c in concepts)
    rules = ",\n".join(f"  {nodeid.rule_namespace(n)}.rule" for n in nodes)
    cons = ",\n".join(f"  {nodeid.concept_namespace(c)}.concept" for c in concepts)
    (lib / "TrafficSpec" / "Index.lean").write_text(
        "import TrafficSpec.Core\n" + imports + "namespace TrafficSpec\n"
        f"def allRules : List Rule := [\n{rules}\n]\n"
        f"def allConcepts : List Concept := [\n{cons}\n]\n"
        "end TrafficSpec\n", encoding="utf-8")
    (lib.parent / "registered.json").write_text(json.dumps(
        {"run": run_dir.name, "chain": view["chain"], "fenced": sorted(fenced),
         "rules": {n: {"law": view["nodes"][n]["law_refs"][0], "accepted_by": view["provenance"].get(n)} for n in nodes},
         "concepts": concepts}, indent=1) + "\n", encoding="utf-8")
    print(f"   registered {len(nodes)} rule(s): {', '.join(nodes)}; {len(concepts)} concept(s)"
          + (f"; fenced, not registered: {', '.join(sorted(fenced))}" if fenced else ""))


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
