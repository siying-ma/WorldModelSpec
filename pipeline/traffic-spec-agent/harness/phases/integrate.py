"""Integrate: registries, whole-library build, every witness, composition DAG; revert on failure."""
from __future__ import annotations
import json
from pathlib import Path
from .. import index_sync, lean, paths, validate_a
from ..blueprint import Node
from ..reading import Reading
from ..state import Run
from .code import rollback, rollback_concept


def _witness_harness(reading_json: Path) -> str:
    return f'''import TrafficSpec
import TrafficSpecWitness
import TrafficSpec.Core.Decode
open TrafficSpec
def main : IO Unit := do
  let text ← IO.FS.readFile {json.dumps(str(reading_json))}
  let ρ ← match Decode.parse Decode.reading text with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; pure ({{}} : Reading)
  for f in TrafficSpecWitness.failures ρ do IO.println s!"FAIL\\t{{f}}"
  IO.println s!"RULES\\t{{allRules.length}}\\tSCENARIOS\\t{{TrafficSpecWitness.allScenarios.length}}"
  IO.println "DONE"
'''


def verify_library(work: Path, reading: Reading) -> tuple[bool, list[str]]:
    index_sync.write_index()
    ok, out = lean.lake_build(paths.LIBRARY)
    (work / "build.log").write_text(out, encoding="utf-8")
    if not ok:
        return False, ["library build failed"] + lean.errors(out)[:8]
    rj = work / "reading.json"; rj.write_text(reading.lean_json(), encoding="utf-8")
    h = work / "witness_harness.lean"; h.write_text(_witness_harness(rj), encoding="utf-8")
    ok, hout = lean.lean_run(paths.LIBRARY, h)
    (work / "witness_harness.out").write_text(hout, encoding="utf-8")
    fails = [l.split("\t", 1)[1] for l in hout.splitlines() if l.startswith("FAIL\t")]
    if not ok or "DONE" not in hout:
        return False, ["witness harness did not run"] + lean.errors(hout)[:8]
    return not fails, fails


def run_integrate(run: Run, accepted_now: list[Node], reading: Reading, baselines: dict[str, dict],
                  concepts_now: list[str] | None = None, concept_baselines: dict[str, dict] | None = None) -> tuple[list[str], list[str]]:
    """Returns (kept node ids, reverted ids with reasons). Nodes are reverted newest first; when none is
    left and the library still does not verify, the concepts accepted this iteration follow, newest first."""
    concepts_now = list(concepts_now or [])
    concept_baselines = concept_baselines or {}
    work = run.iter / "integrate"; work.mkdir(parents=True, exist_ok=True)
    kept = [n.id for n in accepted_now]
    reverted: list[str] = []
    all_nodes = {k: Node(v) for k, v in run.accepted_nodes.items()}
    all_nodes.update({n.id: n for n in accepted_now})
    cycles = validate_a.acyclic(all_nodes)
    if cycles:
        for n in reversed(accepted_now):
            if any(n.id in c for c in cycles):
                rollback(n.id, baselines.get(n.id, {})); kept.remove(n.id); reverted.append(f"{n.id}: {cycles[0]}")
    while True:
        ok, problems = verify_library(work, reading)
        if ok or not (kept or concepts_now):
            break
        if kept:
            victim = kept.pop()   # newest first
            rollback(victim, baselines.get(victim, {}))
        else:
            victim = concepts_now.pop()
            rollback_concept(victim, concept_baselines.get(victim, {}))
            run.accepted_concepts.pop(victim, None)
        reverted.append(f"{victim}: library did not verify ({problems[0] if problems else 'unknown'})")
    (work / "result.json").write_text(json.dumps({"kept": kept, "reverted": reverted}, ensure_ascii=False, indent=1), encoding="utf-8")
    return kept, reverted
