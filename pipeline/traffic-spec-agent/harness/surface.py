"""The Core surface an agent is shown, generated from the Lean files and cited to them.

Nothing here is typed by hand: the formula language comes from Formula.lean, the atom names and
argument kinds from Ontology/Ids.lean and Semantics.lean, the derived concepts from Derived.lean,
the enumeration spellings from the generated codecs, the builders from Builders.lean, the rule
and scenario fields from Rule.lean and Builders.lean.
"""
from __future__ import annotations
import re
from pathlib import Path
from . import paths


def _read(name: str) -> str:
    return (paths.CORE / name).read_text(encoding="utf-8")


def _block(text: str, start: str, end_pat: str) -> str:
    i = text.index(start)
    m = re.search(end_pat, text[i:], re.M)
    return text[i:i + m.start()] if m else text[i:]


def _inductive(text: str, name: str) -> str:
    return _block(text, f"inductive {name}", r"^\s*deriving|^end\b")


def _structure(text: str, name: str) -> str:
    return _block(text, f"structure {name}", r"^\s*deriving")


def formula_language() -> str:
    t = _read("Formula.lean")
    return ("### Formula language (`library/TrafficSpec/Core/Formula.lean`)\n```lean\n"
            + _inductive(t, "Arg") + "\n" + _inductive(t, "CmpOp") + "\n"
            + _block(t, "mutual\n  /-- A quantity. -/", r"^end\b") + "end\n```\n")


def rule_and_scenario() -> str:
    r = _read("Rule.lean"); b = _read("Builders.lean")
    return ("### The `Rule`, `Binder` and `Scenario` values (`Rule.lean`, `Builders.lean`)\n```lean\n"
            + _structure(r, "Binder") + "\n" + _structure(r, "Rule") + "\n" + _structure(b, "Scenario") + "```\n")


def atoms_table() -> str:
    ids = re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', _read("Ontology/Ids.lean").split("derivedIds")[0], re.M)
    sem = _read("Semantics.lean")
    sorts = _block(sem, "def atomArgSorts", r"^/--|^def knowsAtom")
    bools = re.search(r"boolAtomNames : List String := \[(.*?)\]", sem, re.S).group(1)
    meas = re.search(r"measureNames : List String := \[(.*?)\]", sem, re.S).group(1)
    return ("### Atoms (`Ontology/Ids.lean`; Lean name = id with `.` → `_`)\n"
            + ", ".join(f"`{i.replace('.', '_')}`" for i in ids) + "\n\n"
            "Attribute accessors and their spellings — Boolean (`Semantics.evalAtomE`):\n```\n" + bools.strip() + "\n```\n"
            "Quantity-valued (`Semantics.evalMeasure`, use as `Term.measure`):\n```\n" + meas.strip() + "\n```\n"
            "Argument kinds per position (`Semantics.atomArgSorts`; `none` marks a literal position):\n```lean\n" + sorts + "```\n")


def derived_table() -> str:
    d = _read("Derived.lean")
    arms = re.findall(r'^\s*\| ("drv_\w+"), (\[[^\]]*\]), (\[[^\]]*\]) =>', d, re.M)
    lines = [f"{n} args {a} params {p}" for n, a, p in arms]
    sorts = _block(d, "def argSorts", r"^private def side")
    return ("### Derived concepts (`Derived.lean`: `evalB`/`evalQ` arms give arity and parameter count)\n```\n"
            + "\n".join(lines) + "\n```\nArgument kinds (`Derived.argSorts`):\n```lean\n" + sorts + "```\n")


def enumerations() -> str:
    out = ["### Enumeration spellings (`Ontology/*.lean`, `ofString`)"]
    for f in sorted((paths.CORE / "Ontology").glob("*.lean")):
        if f.name == "Ids.lean":
            continue
        t = f.read_text(encoding="utf-8")
        for name, body in re.findall(r"namespace (\w+)\ndef ofString[^\n]*\n(.*?)\n  \| _ =>", t, re.S):
            spell = re.findall(r'\| "([^"]+)"', body)
            out.append(f"- `{name}`: " + ", ".join(f"`{s}`" for s in spell))
    return "\n".join(out) + "\n"


def builders() -> str:
    b = _read("Builders.lean")
    sigs = [l for l in b.splitlines() if re.match(r"^def \w+", l) and "namespace" not in l]
    return "### Builders (`Builders.lean`, namespace `Build`; witnesses are built with these only)\n```lean\n" + "\n".join(sigs) + "\n```\n"


def core_surface() -> str:
    return "\n".join([formula_language(), rule_and_scenario(), atoms_table(), derived_table(), enumerations(), builders()])


def derived_reads() -> dict[str, list[str]]:
    """Which atoms (Lean names) each derived concept reads (`Derived.reads`)."""
    d = _read("Derived.lean")
    block = _block(d, "def reads", r"^\s*\| _ => \[\]")
    out = {}
    for name, items in re.findall(r'\| "(drv_\w+)" => \[([^\]]*)\]', block):
        out[name] = re.findall(r'"([a-z]+_\w+)"', items)
    return out


def atom_id_of(lean_name: str, atom_ids: set[str]) -> str | None:
    """The atom id a Lean name reads: the longest id whose `family_name` form prefixes it."""
    n = {"rel_ahead_in_lane": "rel_ahead_behind_in_lane", "rel_behind_in_lane": "rel_ahead_behind_in_lane"}.get(lean_name, lean_name)
    best = None
    for a in atom_ids:
        d = a.replace(".", "_")
        if n == d or n.startswith(d + "_"):
            if best is None or len(a) > len(best):
                best = a
    return best
