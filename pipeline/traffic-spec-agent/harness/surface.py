"""The Core surface an agent is shown, generated from the Lean files and cited to them.

Nothing here is typed by hand: the formula language comes from Formula.lean, the atom accessors
from Atoms.lean, the argument kinds from Semantics.lean, the world records from World.lean, the
derived concepts from Derived.lean, the enumeration spellings and Lean constructors from the
generated codecs, the unit constructors from Units.lean, the builders and the scenario from
Builders.lean, the rule and its declarations from Rule.lean and Params.lean.

The surface is meant to be sufficient: a coding session that has it should not need to open a
Core file. Every section names the file it was cut from so that a session that does need more
knows where it is.
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


def _doc_before(text: str, pos: int) -> str:
    """The `/-- … -/` doc comment that ends right before `pos`, or ''."""
    head = text[:pos].rstrip()
    if not head.endswith("-/"):
        return ""
    j = head.rfind("/--")
    return head[j:] if j >= 0 else ""


def _signature(text: str, pos: int) -> str:
    """The declaration starting at `pos` up to (not including) the `:=` that ends its header — the
    first `:=` outside parentheses, so a default argument `(x : T := v)` stays in the signature."""
    depth, i = 0, pos
    while i < len(text):
        ch = text[i]
        if ch in "([{": depth += 1
        elif ch in ")]}": depth -= 1
        elif depth == 0 and text.startswith(":=", i): break
        i += 1
    return " ".join(text[pos:i].split())


def _def_lines(text: str, pattern: str) -> list[tuple[str, str]]:
    """(doc, signature) for every `def` whose name matches `pattern`."""
    out = []
    for m in re.finditer(r"^(?:private )?def (\w+)", text, re.M):
        if re.fullmatch(pattern, m.group(1)):
            out.append((_doc_before(text, m.start()), _signature(text, m.start())))
    return out


def _one_line_def(text: str, name: str) -> str:
    """A whole single-line definition `def name … := body`, or the signature if it spans lines."""
    m = re.search(rf"^def {re.escape(name)}\b[^\n]*", text, re.M)
    return m.group(0) if m else ""


# ---------------------------------------------------------------------------------------------

def formula_language() -> str:
    t = _read("Formula.lean"); time = _read("Time.lean")
    return ("### Formula language (`library/TrafficSpec/Core/Formula.lean`; `Measure` from `Time.lean`)\n```lean\n"
            + _inductive(t, "Arg") + "\n" + _inductive(t, "CmpOp") + "\n" + _inductive(time, "Measure") + "\n"
            + _block(t, "mutual\n  /-- A quantity. -/", r"^end\b") + "end\n```\n"
            "Notes. `Arg.var` names a binder or a quantifier variable; `Arg.lit` an enumeration spelling or an\n"
            "attribute selector (`\"x\"`, `\"y\"`, `\"width\"`, `\"length\"`, `\"lateral\"`, `\"longitudinal\"`, a side);\n"
            "`Arg.nat` a count. Quantifiers `existsRegion k v φ`/`forallRegion` range over the scene's structures of\n"
            "kind `k`, `existsDevice`/`forallDevice` over its devices of a kind, `existsUser`/`forallUser` over its\n"
            "road users; the variable is an `Arg.var` inside `φ`. `holdsFor m d s φ`: φ held at every observation in\n"
            "the window of length `d` (a `Term`, usually `.param`) behind, measured in time or path of subject `s`;\n"
            "`within` looks ahead. A window that reaches past the start of the trace is unknown (`windowTruncated`),\n"
            "so a witness of a rule that looks back names `window`. `rule id map` / `ruleApplies id map`: `map` pairs\n"
            "the composed rule's binder names with this rule's variables.\n")


def rule_and_scenario() -> str:
    r = _read("Rule.lean"); b = _read("Builders.lean"); p = _read("Params.lean")
    return ("### The `Rule`, `Binder`, `Operationalization` and `Scenario` values (`Rule.lean`, `Params.lean`, `Builders.lean`)\n```lean\n"
            + _structure(r, "Binder") + "\n" + _structure(r, "Rule") + "\n" + _structure(p, "Operationalization") + "\n"
            + _inductive(r, "Verdict") + "\n" + _structure(b, "Scenario") + "```\n"
            "`AsmId` and `ParamName` are `String`. A witness's `expected` is `.violated`, `.compliant`, `.notApplicable`\n"
            "or `.unknown []` (compared by tag). `grounding` maps binder names to track ids; `window` is a closed range\n"
            "of timestamps (milliseconds).\n")


def world_records() -> str:
    w = _read("World.lean")
    names = ["Kin", "Posture", "WarningLamp", "Signals", "RoadUser", "LaneInfo", "Structure", "CivilTime",
             "TimeWindow", "Conditions", "Device", "Env", "MeasuredRelation", "Scene"]
    parts = []
    for n in names:
        try:
            parts.append(_structure(w, n + " where"))
        except ValueError:
            continue
    return ("### The world a witness builds (`World.lean`)\n```lean\n" + "\n".join(parts) + "```\n"
            "Every `Option` field is `none` when unobserved, and an atom that reads a `none` field is unknown\n"
            "(`absentAtom`), never false. A witness that wants an atom decided sets the field it reads.\n")


def atom_accessors() -> str:
    a = _read("Atoms.lean")
    lines = []
    for m in re.finditer(r"^def (\w+) \(s : Scene\)", a, re.M):
        name = m.group(1)
        line = _one_line_def(a, name)
        if line.rstrip().endswith(":="):
            line = _signature(a, m.start()) + " :=  -- (body continues in Atoms.lean)"
        lines.append(line)
    return ("### Atom accessors (`Atoms.lean`): the name a formula uses, its arguments, and the scene field it reads\n"
            "```lean\n" + "\n".join(lines) + "\n```\n")


def atoms_table() -> str:
    ids = re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', _read("Ontology/Ids.lean").split("derivedIds")[0], re.M)
    sem = _read("Semantics.lean")
    sorts = _block(sem, "def atomArgSorts", r"^/--|^def knowsAtom")
    bools = re.search(r"boolAtomNames : List String := \[(.*?)\]", sem, re.S).group(1)
    meas = re.search(r"measureNames : List String := \[(.*?)\]", sem, re.S).group(1)
    return ("### Atom ids (`Ontology/Ids.lean`; a manifest, a claim and `Build.manifest` use the id, a formula uses the Lean name = id with `.` → `_`)\n"
            + ", ".join(f"`{i}`" for i in ids) + "\n\n"
            "Names a formula may use in `Formula.atom` (`Semantics.boolAtomNames`):\n```\n" + bools.strip() + "\n```\n"
            "Names a formula may use in `Term.measure` (`Semantics.measureNames`):\n```\n" + meas.strip() + "\n```\n"
            "Argument kinds per position (`Semantics.atomArgSorts`; `none` marks a literal position such as a side or a selector):\n```lean\n" + sorts + "```\n")


def derived_table() -> str:
    d = _read("Derived.lean")
    arms = {n: (a, p) for n, a, p in re.findall(r'^\s*\| "(drv_\w+)", (\[[^\]]*\]), (\[[^\]]*\]) =>', d, re.M)}
    entries = []
    for doc, sig in _def_lines(d, r"drv_\w+"):
        name = sig.split()[1]
        arity = arms.get(name)
        doc1 = " ".join(doc.replace("/--", "").replace("-/", "").split())
        entries.append(f"{sig}\n    -- {doc1}" + (f"\n    -- formula form: args {arity[0]} params {arity[1]}" if arity else ""))
    sorts = _block(d, "def argSorts", r"^private def side")
    return ("### Derived concepts (`Derived.lean`): Lean signature (the parameters after the tracks are the formula's `params`, in order), contract, formula arity\n"
            "```lean\n" + "\n".join(entries) + "\n```\nArgument kinds (`Derived.argSorts`):\n```lean\n" + sorts + "```\n"
            "A Boolean concept is `.derived \"drv_x\" args params`; a `QR`-valued one is `Term.quantity \"drv_x\" args params`.\n")


def enumerations() -> str:
    out = ["### Enumeration spellings (`Ontology/*.lean`): `Arg.lit` spelling → Lean constructor (for `existsRegion .kind`, `Build.*`, class lists)"]
    for f in sorted((paths.CORE / "Ontology").glob("*.lean")):
        if f.name == "Ids.lean":
            continue
        t = f.read_text(encoding="utf-8")
        for name, body in re.findall(r"namespace (\w+)\ndef ofString[^\n]*\n(.*?)\n  \| _ =>", t, re.S):
            pairs = re.findall(r'\| "([^"]+)" => some \.(\w+)', body)
            out.append(f"- `{name}`: " + ", ".join(f"`{s}`→`.{c}`" for s, c in pairs))
    return "\n".join(out) + "\n"


def units_table() -> str:
    u = _read("Units.lean")
    lines = [l for l in u.splitlines() if re.match(r"^def (metres|centimetres|millimetres|kilometres|inches|feet|yards|miles|seconds|milliseconds|minutes|hours|metresPerSecond|kmh|mph|metresPerSecondSq|degrees|millidegrees|ratio|percent|micrometres\w*)\b", l)]
    return ("### Units constructors (`Units.lean`, namespace `Units`; every quantity in a witness or a declared literal is written through one)\n"
            "```lean\n" + "\n".join(lines) + "\n```\n`Q` is an exact rational: `Q.zero`, `Q.ofInt n`, `Q.mk' num den`, `Q.add/sub/mul/div/neg/half`; "
            "`Vec := Q × Q`, +x east, +y north. A `Term.lit q .metre` (or `.second`, `.metrePerSecond`, `.metrePerSecondSq`, `.degree`, `.degreePerSecond`, `.ratio`, `.count`) carries a unit tag.\n")


def builders() -> str:
    b = _read("Builders.lean")
    entries = []
    for doc, sig in _def_lines(b, r"\w+"):
        if sig.split()[1] in {"run"}:
            continue
        doc1 = " ".join(doc.replace("/--", "").replace("-/", "").split())
        entries.append((f"-- {doc1}\n" if doc1 else "") + sig)
    return ("### Builders (`Builders.lean`, namespace `Build`; witnesses are built with these and record-update syntax `{ x with field := some v }`)\n"
            "```lean\n" + "\n".join(entries) + "\n```\n"
            "`Build.scene` derives occupancy from geometry (a user is in every region whose polygon contains its\n"
            "position) unless `occupies` is given; `occupancyObserved` is every user built. `Build.trace n t0 dt f`\n"
            "calls `f k t` for `k < n` at `t = t0 + k·dt` (dt in seconds, timestamps in milliseconds).\n"
            "`Build.manifest [\"<atom id>\", …]` observes every atom except the listed ids: the `blind` witness.\n")


def core_surface() -> str:
    return "\n".join([formula_language(), rule_and_scenario(), atoms_table(), atom_accessors(), derived_table(),
                      enumerations(), world_records(), units_table(), builders()])


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
