"""Regenerate the two registries from the rule and witness files on disk."""
from __future__ import annotations
import re
from pathlib import Path
from . import paths, nodeid


def rule_files() -> list[Path]:
    return sorted(paths.RULES_DIR.rglob("*.lean")) if paths.RULES_DIR.exists() else []


def witness_files() -> list[Path]:
    return sorted(p for p in paths.WITNESS_DIR.rglob("*.lean")) if paths.WITNESS_DIR.exists() else []


def node_ids() -> list[str]:
    return [p.stem for p in rule_files()]


def write_index() -> None:
    ids = node_ids()
    imports = "\n".join(f"import {nodeid.rule_module(i)}" for i in ids)
    body = ",\n  ".join(f"{nodeid.rule_namespace(i)}.rule" for i in ids)
    paths.INDEX_FILE.write_text(
        "/-\n  TrafficSpec.Index — generated registry of formalized rules (harness index_sync); do not edit.\n-/\n"
        "import TrafficSpec.Core\n" + (imports + "\n" if imports else "") +
        "namespace TrafficSpec\n/-- Every registered rule, in file order. -/\n"
        f"def allRules : List Rule := [{chr(10) + '  ' + body + chr(10) if body else ''}]\nend TrafficSpec\n",
        encoding="utf-8")
    wids = [p.stem for p in witness_files()]
    wimports = "\n".join(f"import {nodeid.witness_module(i)}" for i in wids)
    wbody = " ++\n  ".join(f"{nodeid.witness_namespace(i)}.scenarios" for i in wids)
    paths.WITNESS_ROOT_FILE.write_text(
        "/-\n  TrafficSpecWitness — generated registry of witnesses (harness index_sync); do not edit. Nothing\n"
        "  that runs the library imports this.\n-/\nimport TrafficSpec\nimport TrafficSpec.Core.Builders\n" +
        (wimports + "\n" if wimports else "") +
        "namespace TrafficSpecWitness\nopen TrafficSpec\n/-- Every registered scenario, in file order. -/\n"
        f"def allScenarios : List Scenario := {wbody if wbody else '[]'}\n"
        "/-- Run every witness against the registered rules with a reading; the failures, by name. -/\n"
        "def failures (ρ : Reading) : List String :=\n"
        "  allScenarios.filterMap fun sc =>\n"
        "    match ({ sc with reading := ρ } : Scenario).run allRules with\n"
        "    | .ok _ => none\n    | .error e => some e\nend TrafficSpecWitness\n",
        encoding="utf-8")
