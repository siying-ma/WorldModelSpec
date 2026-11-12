"""Regenerate the two registries from the rule, concept and witness files on disk."""
from __future__ import annotations
import json
from pathlib import Path
from ..store import jsonl, paths
from ..model import nodeid


#: How a witness is held, by the gate and by the library's verification alike: Core's `Scenario.run`,
#: except that a `blind` witness Core refuses is admitted where its mask is what leaves it unknown.
#: Masking an atom that a rule reads only inside operators looking into the past (`since`, `rises`,
#: `once`, …) leaves their search unsettled back to the trace start, so the unknown carries a window
#: truncated there beside the masked atom. Such a witness passes when, run as a history boundary,
#: it is unknown for masked atoms and truncations alone, and the same trace with nothing masked is
#: decided (compliant or violated): only the mask differs, so the mask is the cause. Any other reason
#: is still refused, and a trace unknown with nothing masked lacks a history the mask does not
#: explain, so it is refused too.
WITNESS_RUN_DEFS = '''/-- A witness held as the gate holds it: Core's `Scenario.run`, and a `blind` witness Core refuses
    admitted only where its mask is the cause: unknown for masked atoms and windows truncated at the
    trace start, and decided on the same trace with nothing masked. -/
def witnessRun (rules : List TrafficSpec.Rule) (sc : TrafficSpec.Scenario) (cs : List TrafficSpec.Concept) :
    Except String TrafficSpec.Verdict :=
  match sc.run rules cs with
  | .ok v => .ok v
  | .error e =>
    if sc.name != "blind" || !sc.boundary.isEmpty || sc.manifest.absentIds.isEmpty then .error e
    else match ({ sc with boundary := "the masked observations" } : TrafficSpec.Scenario).run rules cs with
      | .error _ => .error e
      | .ok v =>
        let full : TrafficSpec.Scenario := { sc with manifest := TrafficSpec.Build.manifest [] sc.manifest.reidGap }
        let decides := fun (x : TrafficSpec.Verdict) =>
          match ({ full with expected := x } : TrafficSpec.Scenario).run rules cs with
          | .ok _ => true
          | .error _ => false
        if decides .compliant || decides .violated then .ok v
        else .error s!"{e}; with nothing masked the same trace is unknown too, so the mask does not explain the history it lacks"
'''


def rule_files() -> list[Path]:
    return sorted(paths.RULES_DIR.rglob("*.lean")) if paths.RULES_DIR.exists() else []


def concept_files() -> list[Path]:
    return sorted(paths.CONCEPTS_DIR.rglob("*.lean")) if paths.CONCEPTS_DIR.exists() else []


def witness_files() -> list[Path]:
    """Node witnesses: everything under the witness tree except the concept witnesses."""
    if not paths.WITNESS_DIR.exists():
        return []
    return sorted(p for p in paths.WITNESS_DIR.rglob("*.lean") if paths.CONCEPT_WITNESS_DIR not in p.parents)


def concept_witness_files() -> list[Path]:
    return sorted(paths.CONCEPT_WITNESS_DIR.rglob("*.lean")) if paths.CONCEPT_WITNESS_DIR.exists() else []


def node_ids() -> list[str]:
    return [p.stem for p in rule_files()]


def concept_ids() -> list[str]:
    return [nodeid.concept_id_of_path(str(p.relative_to(paths.LIBRARY))) for p in concept_files()]


def _lean_list(items: list[str]) -> str:
    return "[" + (chr(10) + "  " + ("," + chr(10) + "  ").join(items) + chr(10) if items else "") + "]"


def inactive_file() -> Path:
    """The records of the library no registry carries (`ids`): fenced versions and what calls them,
    kept on disk as historical evidence. Written by the loop, read by every registry build."""
    return paths.LIBRARY / ".inactive.json"


def inactive() -> set[str]:
    f = inactive_file()
    if not f.exists():
        return set()
    try:
        return set(json.loads(f.read_text(encoding="utf-8")).get("ids", []))
    except (json.JSONDecodeError, AttributeError):
        return set()


def set_inactive(ids: set[str], run_id: str) -> bool:
    """Record the inactive records; returns whether the set changed."""
    if set(ids) == inactive() and inactive_file().exists():
        return False
    jsonl.write_atomic(inactive_file(), json.dumps({"run": run_id, "ids": sorted(ids)}, indent=1))
    return True


def registered(only_nodes: list[str] | None = None, only_concepts: list[str] | None = None,
               keep: set[str] | frozenset = frozenset()) -> tuple[list[str], list[str]]:
    """The rule and concept ids a registry carries, in file order: the files on disk, or with
    `only_*` those ids alone (a gate run while other sessions are coding registers the accepted
    nodes and its own, not theirs). An inactive record is registered by none, except one `keep`
    names (a gate's own subject, and what it calls, when the subject is a fenced record checked
    again)."""
    off = inactive() - set(keep)
    ids = [i for i in node_ids() if i not in off and (only_nodes is None or i in set(only_nodes))]
    cids = [c for c in concept_ids() if c not in off and (only_concepts is None or c in set(only_concepts))]
    return ids, cids


def registry_source(only_nodes: list[str] | None = None, only_concepts: list[str] | None = None,
                    keep: set[str] | frozenset = frozenset()) -> tuple[str, str]:
    """A program's own registry, for a Lean program run while other sessions rebuild the generated
    one: (the import lines of Core and of every registered rule and concept module, the definitions
    of `TrafficSpec.allRules` and `TrafficSpec.allConcepts` over them). The ids are those
    `registered` selects, so the program sees what a build of the same registry would register."""
    ids, cids = registered(only_nodes, only_concepts, keep)
    imports = "import TrafficSpec.Core\n" + "".join(f"import {nodeid.rule_module(i)}\n" for i in ids) + \
        "".join(f"import {nodeid.concept_module(c)}\n" for c in cids)
    defs = ("namespace TrafficSpec\n"
            f"def allRules : List Rule := {_lean_list([f'{nodeid.rule_namespace(i)}.rule' for i in ids])}\n"
            f"def allConcepts : List Concept := {_lean_list([f'{nodeid.concept_namespace(c)}.concept' for c in cids])}\n"
            "end TrafficSpec\n")
    return imports, defs


def write_index(only_nodes: list[str] | None = None, only_concepts: list[str] | None = None, keep: set[str] | frozenset = frozenset()) -> None:
    """The registries over the ids `registered` selects."""
    off = inactive() - set(keep)
    ids, cids = registered(only_nodes, only_concepts, keep)
    imports = [f"import {nodeid.rule_module(i)}" for i in ids] + [f"import {nodeid.concept_module(c)}" for c in cids]
    paths.INDEX_FILE.write_text(
        "/-\n  TrafficSpec.Index — generated registry of formalized rules and concepts (harness index_sync);\n  do not edit.\n-/\n"
        "import TrafficSpec.Core\n" + ("\n".join(imports) + "\n" if imports else "") +
        "namespace TrafficSpec\n/-- Every registered rule, in file order. -/\n"
        f"def allRules : List Rule := {_lean_list([f'{nodeid.rule_namespace(i)}.rule' for i in ids])}\n"
        "/-- Every registered concept, in file order. -/\n"
        f"def allConcepts : List Concept := {_lean_list([f'{nodeid.concept_namespace(c)}.concept' for c in cids])}\n"
        "end TrafficSpec\n",
        encoding="utf-8")
    wids = [p.stem for p in witness_files() if p.stem not in off and (only_nodes is None or p.stem in set(only_nodes))]
    cwids = [c for c in (nodeid.concept_id_of_path(str(p.relative_to(paths.LIBRARY))) for p in concept_witness_files())
             if c not in off and (only_concepts is None or c in set(only_concepts))]
    wimports = [f"import {nodeid.witness_module(i)}" for i in wids] + [f"import {nodeid.concept_witness_module(c)}" for c in cwids]
    wbody = " ++\n  ".join(f"{nodeid.witness_namespace(i)}.scenarios" for i in wids) or "[]"
    cbody = " ++\n  ".join(f"{nodeid.concept_witness_namespace(c)}.scenarios" for c in cwids) or "[]"
    ibody = " ++\n  ".join(f"{nodeid.concept_witness_namespace(c)}.instances" for c in cwids) or "[]"
    tagged = _lean_list([f'("{i}", {nodeid.witness_namespace(i)}.scenarios)' for i in wids]
                        + [f'("{c}", {nodeid.concept_witness_namespace(c)}.scenarios)' for c in cwids])
    paths.WITNESS_ROOT_FILE.write_text(
        "/-\n  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing\n"
        "  that runs the library imports this.\n-/\nimport TrafficSpec\nimport TrafficSpec.Core.Evidence.Builders\n" +
        ("\n".join(wimports) + "\n" if wimports else "") +
        "namespace TrafficSpecWitness\nopen TrafficSpec\n" + WITNESS_RUN_DEFS + "/-- Every registered node scenario, in file order. -/\n"
        f"def allScenarios : List Scenario := {wbody}\n"
        "/-- Every registered concept instance and its scenarios, in file order. -/\n"
        f"def allInstances : List Concept.Instance := {ibody}\n"
        f"def allConceptScenarios : List Scenario := {cbody}\n"
        "/-- The rules every witness runs against: the registered rules and the concept instances. -/\n"
        "def witnessRules : List Rule := allRules ++ allInstances.filterMap (Concept.asRule allConcepts)\n"
        "/-- Every registered witness list, under the id of the node or concept that owns it. -/\n"
        f"def taggedScenarios : List (String × List Scenario) := {tagged}\n"
        "/-- Run every witness against the registered rules and concepts with a reading; each failure as\n"
        "    `<owner id>\\t<scenario>: <why>`, so a failure names the node or concept it belongs to. -/\n"
        "def failures (ρ : Reading) : List String :=\n"
        "  taggedScenarios.flatMap fun (owner, scs) => scs.filterMap fun sc =>\n"
        "    match witnessRun witnessRules ({ sc with reading := ρ } : Scenario) allConcepts with\n"
        "    | .ok _ => none\n    | .error e => some s!\"{owner}\\t{e}\"\nend TrafficSpecWitness\n",
        encoding="utf-8")
