"""The Core surface an agent is shown, generated from the Lean files and cited to them.

Nothing here is typed by hand: the formula language comes from Formula.lean, the atom accessors
from Atoms.lean, the argument kinds from Semantics.lean, the world records from World.lean, the
primitives from Primitives.lean, the enumeration spellings and Lean constructors from the
generated codecs, the unit constructors from Units.lean, the builders and the scenario from
Builders.lean, the rule and its declarations from Rule.lean and Params.lean.

The surface is meant to be sufficient: a coding session that has it should not need to open a
Core file. Every section names the file it was cut from so that a session that does need more
knows where it is.
"""
from __future__ import annotations
import re
from pathlib import Path
from ..store import paths


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
    t = _read("Language/Formula.lean"); time = _read("Foundations/Time.lean")
    return ("### Formula language (`library/TrafficSpec/Core/Language/Formula.lean`; `Measure` from `Foundations/Time.lean`)\n```lean\n"
            + _inductive(t, "Arg") + "\n" + _inductive(t, "CmpOp") + "\n" + _inductive(time, "Measure") + "\n"
            + _block(t, "mutual\n  /-- A quantity. -/", r"^end\b") + "end\n```\n"
            "Notes. `Arg.var` names a binder or a quantifier variable; `Arg.lit` an enumeration spelling or an\n"
            "attribute selector (`\"x\"`, `\"y\"`, `\"width\"`, `\"length\"`, `\"lateral\"`, `\"longitudinal\"`, a side);\n"
            "`Arg.nat` a count. Quantifiers `existsRegion k v φ`/`forallRegion` range over the scene's structures of\n"
            "kind `k` (an `Arg.lit` spelling, or a concept's literal formal), `existsDevice`/`forallDevice` over its\n"
            "devices of a kind, `existsUser`/`forallUser` over its road users, the bound ones included (`same a b`\n"
            "excludes the subject); the variable is an `Arg.var` inside `φ`. `rises φ` is φ here and not at the\n"
            "previous observation; `definedWhen pre φ` is undefined (unknown) where `pre` fails; `Term.sinceRise φ`\n"
            "the seconds since φ last became true; `Term.aggregate op v φ t` the min/max/median/count of `t` over the\n"
            "road users `v` satisfying φ. `holdsFor m d s φ`: φ held at every observation in\n"
            "the window of length `d` (a `Term`, usually `.param`) behind, measured in time or path of subject `s`;\n"
            "`within` looks ahead. A window that reaches past the start of the trace is unknown (`windowTruncated`),\n"
            "so a witness of a rule that looks back names `window`. `rule id map` / `ruleApplies id map`: `map` pairs\n"
            "the composed rule's binder names with this rule's variables.\n")


def rule_and_scenario() -> str:
    r = _read("Language/Rule.lean"); b = _read("Evidence/Builders.lean"); p = _read("Vocab/Params.lean")
    return ("### The `Rule`, `Binder`, `Operationalization` and `Scenario` values (`Language/Rule.lean`, `Vocab/Params.lean`, `Evidence/Builders.lean`)\n```lean\n"
            + _structure(r, "Binder") + "\n" + _structure(r, "Rule") + "\n" + _structure(p, "Operationalization") + "\n"
            + _inductive(r, "Verdict") + "\n" + _structure(b, "Scenario") + "```\n"
            "`AsmId` and `ParamName` are `String`. A witness's `expected` is `.violated`, `.compliant`, `.notApplicable`\n"
            "or `.unknown []` (compared by tag). `grounding` maps binder names to track ids; `window` is a closed range\n"
            "of timestamps (milliseconds).\n")


def world_records() -> str:
    w = _read("Vocab/World.lean")
    names = ["Kin", "Posture", "WarningLamp", "Signals", "RoadUser", "LaneInfo", "Structure", "CivilTime",
             "TimeWindow", "Conditions", "Device", "Env", "MeasuredRelation", "Scene"]
    parts = []
    for n in names:
        try:
            parts.append(_structure(w, n + " where"))
        except ValueError:
            continue
    return ("### The world a witness builds (`Vocab/World.lean`)\n```lean\n" + "\n".join(parts) + "```\n"
            "Every `Option` field is `none` when unobserved, and an atom that reads a `none` field is unknown\n"
            "(`absentAtom`), never false. A witness that wants an atom decided sets the field it reads.\n")


def atom_accessors() -> str:
    a = _read("Vocab/Atoms.lean")
    lines = []
    for m in re.finditer(r"^def (\w+) \(s : Scene\)", a, re.M):
        name = m.group(1)
        line = _one_line_def(a, name)
        if line.rstrip().endswith(":="):
            line = _signature(a, m.start()) + " :=  -- (body continues in Vocab/Atoms.lean)"
        lines.append(line)
    return ("### Atom accessors (`Vocab/Atoms.lean`): the name a formula uses, its arguments, and the scene field it reads\n"
            "```lean\n" + "\n".join(lines) + "\n```\n")


def atoms_table() -> str:
    ids = re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', _read("Vocab/Ontology/Ids.lean").split("primitiveIds")[0], re.M)
    sem = _read("Language/Semantics.lean")
    sorts = _block(sem, "def atomArgSorts", r"^/--|^def knowsAtom")
    bools = re.search(r"boolAtomNames : List String := \[(.*?)\]", sem, re.S).group(1)
    meas = re.search(r"measureNames : List String := \[(.*?)\]", sem, re.S).group(1)
    return ("### Atom ids (`Vocab/Ontology/Ids.lean`; a manifest, a claim and `Build.manifest` use the id, a formula uses the Lean name = id with `.` → `_`)\n"
            + ", ".join(f"`{i}`" for i in ids) + "\n\n"
            "Names a formula may use in `Formula.atom` (`Semantics.boolAtomNames`):\n```\n" + bools.strip() + "\n```\n"
            "Names a formula may use in `Term.measure` (`Semantics.measureNames`):\n```\n" + meas.strip() + "\n```\n"
            "Argument kinds per position (`Semantics.atomArgSorts`; `none` marks a literal position such as a side or a selector):\n```lean\n" + sorts + "```\n")


def primitives_table() -> str:
    d = _read("Vocab/Primitives.lean")
    arms = {n: (a, p) for n, a, p in re.findall(r'^\s*\| "(prim_\w+)", (\[[^\]]*\]), (\[[^\]]*\]) =>', d, re.M)}
    entries = []
    for doc, sig in _def_lines(d, r"prim_\w+"):
        name = sig.split()[1]
        arity = arms.get(name)
        doc1 = " ".join(doc.replace("/--", "").replace("-/", "").split())
        entries.append(f"{sig}\n    -- {doc1}" + (f"\n    -- formula form: args {arity[0]} params {arity[1]}" if arity else ""))
    sorts = _block(d, "def argSorts", r"^private def tid")
    return ("### Primitives (`Vocab/Primitives.lean`): Lean signature (the parameters after the tracks are the formula's `params`, in order), contract, formula arity\n"
            "```lean\n" + "\n".join(entries) + "\n```\nArgument kinds (`Primitives.argSorts`):\n```lean\n" + sorts + "```\n"
            "A Boolean primitive is `.derived \"prim_x\" args params`; a `QR`-valued one is `Term.quantity \"prim_x\" args params`.\n")


def enumerations() -> str:
    out = ["### Enumeration spellings (`Vocab/Ontology/*.lean`): `Arg.lit` spelling → Lean constructor (the spelling for `existsRegion (.lit \"kind\")` and literal arguments, the constructor for `Build.*` and class lists)"]
    for f in sorted((paths.CORE / "Vocab" / "Ontology").glob("*.lean")):
        if f.name == "Ids.lean":
            continue
        t = f.read_text(encoding="utf-8")
        for name, body in re.findall(r"namespace (\w+)\ndef ofString[^\n]*\n(.*?)\n  \| _ =>", t, re.S):
            pairs = re.findall(r'\| "([^"]+)" => some \.(\w+)', body)
            out.append(f"- `{name}`: " + ", ".join(f"`{s}`→`.{c}`" for s, c in pairs))
    return "\n".join(out) + "\n"


def enumeration_spellings() -> dict[str, set[str]]:
    """Enumeration name → the `Arg.lit` spellings its `ofString` accepts (`Vocab/Ontology/*.lean`)."""
    out: dict[str, set[str]] = {}
    for f in sorted((paths.CORE / "Vocab" / "Ontology").glob("*.lean")):
        if f.name == "Ids.lean":
            continue
        t = f.read_text(encoding="utf-8")
        for name, body in re.findall(r"namespace (\w+)\ndef ofString[^\n]*\n(.*?)\n  \| _ =>", t, re.S):
            out[name] = {s for s, _ in re.findall(r'\| "([^"]+)" => some \.(\w+)', body)}
    return out


def units_table() -> str:
    u = _read("Foundations/Units.lean")
    lines = [l for l in u.splitlines() if re.match(r"^def (metres|centimetres|millimetres|kilometres|inches|feet|yards|miles|seconds|milliseconds|minutes|hours|metresPerSecond|kmh|mph|metresPerSecondSq|degrees|millidegrees|ratio|percent|micrometres\w*)\b", l)]
    return ("### Units constructors (`Foundations/Units.lean`, namespace `Units`; every quantity in a witness or a declared literal is written through one)\n"
            "```lean\n" + "\n".join(lines) + "\n```\n`Q` is an exact rational: `Q.zero`, `Q.ofInt n`, `Q.mk' num den`, `Q.add/sub/mul/div/neg/half`; "
            "`Vec := Q × Q`, +x east, +y north. A `Term.lit q .metre` (or `.second`, `.metrePerSecond`, `.metrePerSecondSq`, `.degree`, `.degreePerSecond`, `.ratio`, `.count`) carries a unit tag.\n")


def builders() -> str:
    b = _read("Evidence/Builders.lean")
    entries = []
    for doc, sig in _def_lines(b, r"\w+"):
        if sig.split()[1] in {"run"}:
            continue
        doc1 = " ".join(doc.replace("/--", "").replace("-/", "").split())
        entries.append((f"-- {doc1}\n" if doc1 else "") + sig)
    return ("### Builders (`Evidence/Builders.lean`, namespace `Build`; witnesses are built with these and record-update syntax `{ x with field := some v }`)\n"
            "```lean\n" + "\n".join(entries) + "\n```\n"
            "`Build.scene` derives occupancy from geometry (a user is in every region whose polygon contains its\n"
            "position) unless `occupies` is given; `occupancyObserved` is every user built. `Build.trace n t0 dt f`\n"
            "calls `f k t` for `k < n` at `t = t0 + k·dt` (dt in seconds, timestamps in milliseconds).\n"
            "`Build.manifest [\"<atom id>\", …]` observes every atom except the listed ids: the `blind` witness.\n")


def concept_language() -> str:
    c = _read("Language/Concept.lean")
    return ("### Concepts (`Language/Concept.lean`): the `Concept` a concept file declares, the `Instance` its witnesses build\n```lean\n"
            + _inductive(c, "ArgSort") + "\n" + _structure(c, "ConceptParam") + "\n" + _inductive(c, "ConceptBody") + "\n"
            + _structure(c, "Concept where") + "\n" + _structure(c, "Instance") + "```\n"
            "A rule calls a concept by its Lean name (the id with `.` → `_`): `.derived \"drv_<family>_<name>\" args params`\n"
            "for a formula concept, `Term.quantity \"drv_<family>_<name>\" args params` for a quantity; `args` fill the\n"
            "formals in order (a track formal takes a variable, a literal formal a spelling among its values, a nat a\n"
            "count), `params` fill the formal parameters in order with constant terms (`.param \"p.…\"` of the reading,\n"
            "or a declared literal). Inside a concept's body every `.var` is a formal or bound in the body and every\n"
            "`.param` is a formal parameter: a body never names a reading parameter. The call is expanded before\n"
            "evaluation, so its atoms count as the caller's.\n")


def concepts_table(accepted: dict[str, dict]) -> str:
    """The catalogue of accepted concepts: what a plan may reuse and a rule may call."""
    if not accepted:
        return "### Concept catalogue\n(no concept accepted yet: a manoeuvre, state or configuration a span needs is proposed as a concept record)\n"
    out = ["### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)",
           "| id | kind | contract | definition | args | params | reads | used by |", "|---|---|---|---|---|---|---|---|"]
    for cid, rec in sorted(accepted.items()):
        args = ", ".join(f"{a.get('name')}:{a.get('sort')}" + (f"{a.get('values')}" if a.get("sort") == "literal" else "") for a in rec.get("args", []))
        params = ", ".join(f"{p.get('name')} ({p.get('unit')})" for p in rec.get("params", []))
        out.append(f"| `{cid}` | {rec.get('kind')} | {' '.join(str(rec.get('contract', '')).split())} | {rec.get('definition') or ''} | {args} | {params} | "
                   f"{', '.join(rec.get('reads', []))} | {len(rec.get('used_by', []))} |")
    return "\n".join(out) + "\n"


def _keep_for(claimed: set[str] | None, accepted: dict[str, dict]) -> set[str] | None:
    """The atom ids, primitive ids and concept ids a session needs: what the record claims, what
    its claimed concepts read and reference, and what its claimed primitives read."""
    if claimed is None:
        return None
    keep = {c.split("=")[0] for c in claimed}
    reads = primitive_reads()
    atom_ids = set(core_atom_ids())
    for c in list(keep):
        for lean_name in reads.get(c.replace(".", "_"), []):
            aid = atom_id_of(lean_name, atom_ids)
            if aid:
                keep.add(aid)
        rec = accepted.get(c)
        if rec:
            keep |= set(rec.get("reads", [])) | set(rec.get("refs", []))
    return keep


def _cut_accessors(text: str, keep: set[str]) -> str:
    atom_ids = set(core_atom_ids())
    out = []
    for line in text.splitlines():
        m = re.match(r"^def (\w+) \(s : Scene\)", line)
        if m:
            aid = atom_id_of(m.group(1), atom_ids)
            if aid and aid not in keep:
                continue
        out.append(line)
    return "\n".join(out) + "\n"


def _cut_primitives(text: str, keep: set[str]) -> str:
    parts = re.split(r"(?=^def prim_)", text.split("```lean\n", 1)[1].split("```")[0], flags=re.M)
    kept = [p for p in parts if not p.startswith("def prim_") or ("prim." + p.split()[1][5:]) in keep]
    head, tail = text.split("```lean\n", 1)[0], text.split("```", 2)[2]
    return head + "```lean\n" + "".join(kept) + "```" + tail


def core_surface(accepted_concepts: dict[str, dict] | None = None, claimed: set[str] | None = None) -> str:
    """The whole surface, or, with `claimed`, the surface cut to the ids a record claims: the
    accessors of its atoms and of what its concepts and primitives read, its primitives, and the
    concepts it names. The language, the records, the spellings, the units and the builders are
    always whole, since a witness is built from them."""
    accepted = accepted_concepts or {}
    keep = _keep_for(claimed, accepted)
    concepts = accepted if keep is None else {k: v for k, v in accepted.items() if k in keep}
    accessors = atom_accessors() if keep is None else _cut_accessors(atom_accessors(), keep)
    prims = primitives_table() if keep is None else _cut_primitives(primitives_table(), keep)
    note = "" if keep is None else ("\n(The accessor and primitive tables are cut to what the record claims and what its concepts read; "
                                    "every other name is off limits for this task, and the whole tables are in the files named.)\n")
    return "\n".join([formula_language(), rule_and_scenario(), concept_language(), concepts_table(concepts),
                       atoms_table(), accessors + note, prims, enumerations(), world_records(), units_table(), builders()])


def primitive_reads() -> dict[str, list[str]]:
    """Which atoms (Lean names) each primitive reads (`Primitives.reads`); an arm may list several names."""
    d = _read("Vocab/Primitives.lean")
    block = _block(d, "def reads", r"^\s*\| _ => \[\]")
    out = {}
    for names, items in re.findall(r'\| ((?:"prim_\w+"(?: \| )?)+) => \[([^\]]*)\]', block):
        for name in re.findall(r'"(prim_\w+)"', names):
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


def core_atom_ids() -> list[str]:
    """The atom ids of the active Core (`Vocab/Ontology/Ids.lean`)."""
    return re.findall(r'^\s*"([a-z]+\.[a-z_]+)"', _read("Vocab/Ontology/Ids.lean").split("primitiveIds")[0], re.M)
