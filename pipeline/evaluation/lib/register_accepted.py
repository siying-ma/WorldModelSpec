"""Rewrite a library copy's registry (TrafficSpec/Index.lean) so it holds exactly the rules and
concepts a run accepted, and nothing a coding session may still be writing.

    python3 register_accepted.py <library copy> <run results dir> <pipeline root>

The run's accepted records (accepted_nodes.jsonl, accepted_concepts.jsonl) name what is registered;
files on disk that no record names are removed from the copy, so a half-written node never enters
the monitor's build. Only the copy is touched.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def records(path: Path, key: str) -> list[str]:
    if not path.exists():
        return []
    return [json.loads(l)[key] for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]


def main(lib: Path, run_dir: Path, pipeline_root: Path) -> None:
    sys.path.insert(0, str(pipeline_root))
    from harness.model import nodeid  # module and namespace names, as the harness derives them

    nodes = records(run_dir / "accepted_nodes.jsonl", "node_id")
    concepts = records(run_dir / "accepted_concepts.jsonl", "concept_id")
    opts = json.loads((run_dir / "options.json").read_text(encoding="utf-8")) if (run_dir / "options.json").exists() else {}
    if opts.get("base_run"):                                      # a test run also carries its base run's records
        base = run_dir.parent / opts["base_run"]
        nodes = records(base / "accepted_nodes.jsonl", "node_id") + nodes
        concepts = records(base / "accepted_concepts.jsonl", "concept_id") + concepts
    if not nodes:
        sys.exit(f"{run_dir} has no accepted node: nothing to evaluate")

    keep = {nodeid.rule_path(n) for n in nodes} | {nodeid.concept_path(c) for c in concepts}
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
    print(f"   registered {len(nodes)} rule(s): {', '.join(nodes)}; {len(concepts)} concept(s)")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
