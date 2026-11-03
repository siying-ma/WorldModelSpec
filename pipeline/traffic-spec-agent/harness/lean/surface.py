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
import json
import re
from functools import lru_cache
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

_CTOR_DOC = re.compile(r"^[ \t]*/--((?:(?!-/).)*)-/[ \t]*\n(?=[ \t]*\| (\w+))", re.S | re.M)


def _constructor_docs(listing: str) -> list[tuple[str, str]]:
    """(`Inductive.constructor`, doc) for each constructor of an inductive listing that carries a
    doc comment."""
    def owner(pos: int) -> str:
        found = re.findall(r"\binductive (\w+)", listing[:pos])
        return found[-1] + "." if found else ""
    return [(owner(m.start()) + m.group(2), " ".join(m.group(1).split())) for m in _CTOR_DOC.finditer(listing)]


def _without_constructor_docs(listing: str) -> str:
    """The listing with its constructors' doc comments taken out: they are shown in
    `formula_restrictions`, once."""
    return _CTOR_DOC.sub("", listing)


def _language_listing() -> str:
    return _block(_read("Language/Formula.lean"), "mutual\n  /-- A quantity. -/", r"^end\b")


def formula_restrictions() -> str:
    """What a formula may not say, in Core's own words: the contracts of the static checks
    (`Rule.check`, `Concept.check` in `Language/RuleEval.lean`) and the doc comments Core puts on
    the constructors of `Term`, `Formula` and `ArgSort` it restricts. Part of the formula language,
    so the planner and the coder read the same text."""
    ev = _read("Language/RuleEval.lean")

    def check_doc(ns: str) -> str:
        i = ev.index(f"namespace {ns}\n")
        j = ev.index(f"\nend {ns}", i)
        m = re.search(r"^def check\b", ev[i:j], re.M)
        return " ".join(_doc_before(ev, i + m.start()).removeprefix("/--").removesuffix("-/").split())
    rows = [f"- `Rule.check`: {check_doc('Rule')}", f"- `Concept.check`: {check_doc('Concept')}"]
    rows += [f"- `{n}`: {d}" for n, d in _constructor_docs(_language_listing())]
    rows += [f"- `{n}`: {d}" for n, d in _constructor_docs(_inductive(_read("Language/Concept.lean"), "ArgSort"))]
    return ("### What a formula may not say (`Language/RuleEval.lean`, `Language/Formula.lean`, `Language/Concept.lean`)\n"
            "The static checks a rule and a concept are held to before any trace, and what Core states a formula may not do with "
            "the constructors it restricts:\n" + "\n".join(rows) + "\n")


def formula_language() -> str:
    t = _read("Language/Formula.lean"); time = _read("Foundations/Time.lean")
    return ("### Formula language (`library/TrafficSpec/Core/Language/Formula.lean`; `Measure` from `Foundations/Time.lean`)\n```lean\n"
            + _inductive(t, "Arg") + "\n" + _inductive(t, "CmpOp") + "\n" + _inductive(time, "Measure") + "\n"
            + _without_constructor_docs(_language_listing()) + "end\n```\n"
            "Notes. `Arg.var` names a binder or a quantifier variable; `Arg.lit` an enumeration spelling or an\n"
            "attribute selector (`\"x\"`, `\"y\"`, `\"width\"`, `\"length\"`, `\"lateral\"`, `\"longitudinal\"`, a side);\n"
            "`Arg.nat` a count. Quantifiers `existsRegion k v φ`/`forallRegion` range over the scene's structures of\n"
            "kind `k` (an `Arg.lit` spelling, or a concept's literal formal) or of a kind that refines `k`, and the\n"
            "structures that may be of it where the source cannot tell; `existsDevice`/`forallDevice` over its\n"
            "devices of a kind, `existsUser`/`forallUser` over its road users, the bound ones included (`same a b`\n"
            "excludes the subject); the variable is an `Arg.var` inside `φ`. `rises φ` is φ here and not at the\n"
            "previous observation; `definedWhen pre φ` is undefined (unknown) where `pre` fails; `Term.sinceRise φ`\n"
            "the seconds since φ last became true; `Term.aggregate op v φ t` the min/max/median/count of `t` over the\n"
            "road users `v` satisfying φ. `Term.cond φ a b` is `a` where φ holds and `b` where it does not; a\n"
            "comparison over it is decided wherever both selections decide it alike, so a condition that selects\n"
            "among bounds is written with it. `holdsFor m d s φ`: φ held at every observation in\n"
            "the window of length `d` (a `Term`, usually `.param`) behind, measured in time or path of subject `s`:\n"
            "`m = .time` is the last `d` seconds, `m = .path` the last `d` of distance the subject travelled, so a\n"
            "window the words state as a distance travelled is a `.path` window;\n"
            "`within` looks ahead; `atLast m d s ψ φ`: φ at the last observation in the window behind at which ψ held\n"
            "(false where ψ held nowhere in a covered window). A window that reaches past the start of the trace is unknown (`windowTruncated`),\n"
            "so a witness of a rule that looks back names `window`. `rule id map` / `ruleApplies id map`: `map` pairs\n"
            "the composed rule's binder names with this rule's variables.\n\n" + formula_restrictions())


def rule_and_scenario() -> str:
    r = _read("Language/Rule.lean"); b = _read("Evidence/Builders.lean"); p = _read("Vocab/Params.lean")
    return ("### The `Rule`, `Binder`, `Operationalization` and `Scenario` values (`Language/Rule.lean`, `Vocab/Params.lean`, `Evidence/Builders.lean`)\n```lean\n"
            + _structure(r, "Binder") + "\n" + _structure(r, "Rule") + "\n" + _structure(p, "Operationalization") + "\n"
            + _inductive(r, "Verdict") + "\n" + _structure(b, "Scenario") + "```\n"
            "`AsmId` and `ParamName` are `String`. A witness's `expected` is `.violated`, `.compliant`, `.notApplicable`\n"
            "or `.unknown []` (compared by tag). `grounding` maps binder names to track ids; `window` is a closed range\n"
            "of timestamps (milliseconds). `boundary` is set only on a scenario the plan declares a history boundary for:\n"
            "that witness stays unknown for a window truncated at its trace's start, and for nothing else.\n")


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
    abstract = abstract_kinds()
    for name, pairs in _codecs().items():
        out.append(f"- `{name}`: " + ", ".join(f"`{s}`→`.{c}`" for s, c in pairs)
                   + (f" (abstract, read by a formula only and never a structure's label or unobserved kind: {', '.join(f'`{s}`' for s in sorted(abstract))})"
                      if name == "StructureKind" and abstract else ""))
    return "\n".join(out) + "\n"


def _codecs() -> dict[str, list[tuple[str, str]]]:
    """Enumeration name → [(spelling, constructor)] its `ofString` accepts (`Vocab/Ontology/*.lean`);
    a parametrized constructor is spelt `ctor(<value of its parameter's enumeration>)`."""
    out: dict[str, list[tuple[str, str]]] = {}
    for f in sorted((paths.CORE / "Vocab" / "Ontology").glob("*.lean")):
        if f.name in ("Ids.lean", "Dimensions.lean"):
            continue
        t = f.read_text(encoding="utf-8")
        for name, body in re.findall(r"namespace (\w+)\ndef ofString[^\n]*\n(.*?)\ndef toString", t, re.S):
            pairs = re.findall(r'\| "([^"]+)" => some \.(\w+)', body)
            pairs += [(f"{ctor}(<{ptype}>)", re.sub(r"_(\w)", lambda m: m.group(1).upper(), ctor))
                      for ctor, ptype in re.findall(r'if s\.startsWith "(\w+)\(".*?\n\s*\((\w+)\.ofString', body, re.S)]
            out[name] = pairs
    return out


def kind_refinements() -> dict[str, str]:
    """Region kind spelling → the spelling of the kind it refines, from the generated
    `StructureKind.parent?` (`Vocab/Ontology/Structure.lean`)."""
    spell = {ctor: s for s, ctor in _codecs().get("StructureKind", [])}
    body = re.search(r"def parent\? : StructureKind → Option StructureKind\n(.*?)\n\s*\| _ => none", _read("Vocab/Ontology/Structure.lean"), re.S)
    pairs = re.findall(r"\| \.(\w+) => some \.(\w+)", body.group(1)) if body else []
    return {spell[c]: spell[p] for c, p in pairs if c in spell and p in spell}


def abstract_kinds() -> set[str]:
    """The spellings of the abstract region kinds, from the generated `StructureKind.isAbstract`
    (`Vocab/Ontology/Structure.lean`): a formula reads them, no trace writes them."""
    spell = {ctor: s for s, ctor in _codecs().get("StructureKind", [])}
    body = re.search(r"def isAbstract : StructureKind → Bool\n(.*?)\n\s*\| _ => false", _read("Vocab/Ontology/Structure.lean"), re.S)
    return {spell[c] for c in re.findall(r"\| \.(\w+) => true", body.group(1)) if c in spell} if body else set()


#: The exporter of Core's declared region-argument kinds (`TraceLint.regionArgKinds`), and the
#: version of the JSON this module reads from it.
REGION_KINDS_EXPORTER = paths.REPO / "scripts" / "RegionKinds.lean"
REGION_KINDS_SCHEMA = 2


class RegionKindsUnavailable(RuntimeError):
    """The export failed, or lacks an entry a signature needs: the region-kind check cannot run."""


def _signature_args(sig: str) -> list:
    """A case-vocabulary signature `name(track, region, 'a' | 'b')` as a list of arguments: each a
    sort, or the list of literal spellings the position takes."""
    inner = sig.split(" params ")[0]
    inner = inner[inner.index("(") + 1:inner.rindex(")")]
    return [a if a in ("track", "region", "device") else re.findall(r"'([^']*)'", a)
            for a in (x.strip() for x in inner.split(",")) if a]


def _region_signatures(onto) -> list[tuple[str, str, list]]:
    """(Lean name, atom id, arguments) of every dispatch signature that takes a region."""
    out = []
    for row in case_catalogue(onto):
        for sig in row["signatures"]:
            args = _signature_args(sig)
            if "region" in args:
                out.append((row["name"], row["atom"], args))
    return out


def region_kinds_cache() -> tuple:
    """The export's cache key, what it is computed from, and the cache file it names."""
    import hashlib
    from ..tools import split
    h = hashlib.sha256()
    for f in sorted(paths.CORE.rglob("*.lean")):
        h.update(str(f.relative_to(paths.CORE)).encode()); h.update(f.read_bytes())
    key_inputs = {"schema": REGION_KINDS_SCHEMA, "split": split.active(), "core": h.hexdigest(),
                  "exporter": hashlib.sha256(REGION_KINDS_EXPORTER.read_bytes()).hexdigest()}
    key = hashlib.sha256(json.dumps(key_inputs, sort_keys=True).encode()).hexdigest()[:24]
    return key, key_inputs, paths.LIBRARY / ".lake" / "region_kinds" / f"{key}.json"


def region_kinds_export() -> list[dict]:
    """Core's declared region-argument kinds (`TraceLint.regionArgKinds`, printed by
    `scripts/RegionKinds.lean`): one entry `{name, position, admitted}` per region argument of a
    dispatch name, `position` its index in the full argument list, `admitted` a list of kind
    spellings or `any`. Cached under `library/.lake/region_kinds/`, keyed on the active split, the
    digest of Core, the exporter's text and the schema version; a failed export raises
    `RegionKindsUnavailable`, and no fallback is read."""
    from . import lean
    key, key_inputs, cache = region_kinds_cache()
    if key in _REGION_KINDS:
        return _REGION_KINDS[key]
    if not cache.exists():
        with lean.evaluation_lock(paths.LIBRARY):
            code, out = lean.lean_run(paths.LIBRARY, REGION_KINDS_EXPORTER)
        if code != 0:
            raise RegionKindsUnavailable(f"the region-kind export failed (exit {code}): {out.strip()[-2000:]}")
        try:
            entries = json.loads(out.strip().splitlines()[-1])["entries"]
        except (ValueError, KeyError, IndexError) as e:
            raise RegionKindsUnavailable(f"the region-kind export printed no entries ({e}): {out.strip()[-2000:]}")
        from ..store import jsonl
        cache.parent.mkdir(parents=True, exist_ok=True)
        jsonl.write_atomic(cache, json.dumps({"key": key_inputs, "entries": entries}, ensure_ascii=False))
    try:
        entries = json.loads(cache.read_text(encoding="utf-8"))["entries"]
    except (ValueError, KeyError) as e:
        raise RegionKindsUnavailable(f"the cached region-kind export {cache} is unreadable: {e}")
    _REGION_KINDS[key] = entries
    return entries


_REGION_KINDS: dict[str, list[dict]] = {}


def region_argument_kinds(onto) -> dict[str, tuple[str, list[list[frozenset[str] | None]]]]:
    """Lean name of every atom or primitive with a region argument → (its atom id, for each of its
    signatures, for each region argument in order the kind spellings Core declares there, `None`
    where it declares any), from `region_kinds_export`, looked up by the name and the argument's
    index in the full argument list. A region argument the table has no entry for raises
    `RegionKindsUnavailable`: a missing entry is never read as any."""
    stamp = (id(onto), tuple((str(f), f.stat().st_mtime_ns, f.stat().st_size)
                             for f in sorted(paths.CORE.rglob("*.lean")) + [REGION_KINDS_EXPORTER]))
    if stamp in _ARGUMENT_KINDS:
        return _ARGUMENT_KINDS[stamp]
    table = {(e.get("name"), e.get("position")): e.get("admitted") for e in region_kinds_export()}
    out: dict[str, tuple[str, list[list[frozenset[str] | None]]]] = {}
    for name, aid, args in _region_signatures(onto):
        row = []
        for i in (i for i, a in enumerate(args) if a == "region"):
            admitted = table.get((name, i))
            if not admitted:
                raise RegionKindsUnavailable(f"Core declares no region kinds for argument {i} of {name}{args}")
            row.append(None if admitted == "any" else frozenset(admitted))
        out.setdefault(name, (aid, []))[1].append(row)
    _ARGUMENT_KINDS[stamp] = out
    return out


_ARGUMENT_KINDS: dict[tuple, dict] = {}


def enumeration_spellings() -> dict[str, set[str]]:
    """Enumeration name → the `Arg.lit` spellings its `ofString` accepts (`Vocab/Ontology/*.lean`);
    a parametrized one is spelt `ctor(<Enumeration>)`, its parameter one of that enumeration's spellings."""
    return {name: {s for s, _ in pairs} for name, pairs in _codecs().items()}


def units_table() -> str:
    from ..model import units
    u = _read("Foundations/Units.lean")
    ctors = set(units.constructors())
    lines = [l for l in u.splitlines() if (m := re.match(r"^def (\w+)\b", l)) and m.group(1) in ctors]
    tags = ", ".join(f"`{units.lean_unit(c)}`" for c in units.CORE_UNITS)
    return ("### Units constructors (`Foundations/Units.lean`, namespace `Units`; every quantity in a witness or a declared literal is written through one)\n"
            "```lean\n" + "\n".join(lines) + "\n```\n`Q` is an exact rational: `Q.zero`, `Q.ofInt n`, `Q.mk' num den`, `Q.add/sub/mul/div/neg/half`; "
            f"`Vec := Q × Q`, +x east, +y north. A `Term.lit q <unit>` carries one of the unit tags {tags}.\n")


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
            + _without_constructor_docs(_inductive(c, "ArgSort")) + "\n" + _structure(c, "ConceptParam") + "\n" + _inductive(c, "ConceptBody") + "\n"
            + _structure(c, "Concept where") + "\n" + _structure(c, "Instance") + "```\n"
            "A rule calls a concept by its Lean name (the id with `.` → `_`): `.derived \"drv_<family>_<name>\" args params`\n"
            "for a formula concept, `Term.quantity \"drv_<family>_<name>\" args params` for a quantity; `args` fill the\n"
            "formals in order (a track formal takes a variable bound to a road user, a region formal a variable bound\n"
            "to a region — the one the caller singles out, bound by its own region quantifier — a literal formal a\n"
            "spelling among its values, a nat a count; each variable's innermost binding decides its sort, and the\n"
            "gate checks every call against these sorts), `params` fill the formal parameters in order with constant\n"
            "terms (`.param \"p.…\"` of the reading,\n"
            "or a declared literal). Inside a concept's body every `.var` is a formal or bound in the body and every\n"
            "`.param` is a formal parameter: a body never names a reading parameter. The call is expanded before\n"
            "evaluation, so its atoms count as the caller's.\n")


def concepts_table(accepted: dict[str, dict]) -> str:
    """The catalogue of accepted concepts: what a plan may reuse and a rule may call."""
    if not accepted:
        return "### Concept catalogue\n(no concept accepted yet: a manoeuvre, a state of motion or a relation over time a span needs is proposed as a concept record)\n"
    out = ["### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)",
           "| id | kind | contract | definition | args | params | reads | calls | planned users | accepted callers |",
           "|---|---|---|---|---|---|---|---|---|---|"]
    for cid, rec in sorted(accepted.items()):
        args = ", ".join(f"{a.get('name')}:{a.get('sort')}" + (f"{a.get('values')}" if a.get("sort") == "literal" else "") for a in rec.get("args", []))
        params = ", ".join(f"{p.get('name')} ({p.get('unit')})" for p in rec.get("params", []))
        built = "; ".join(" ".join(str(a).split()) for a in rec.get("approximations", []))
        contract = " ".join(str(rec.get("contract", "")).split()) + (f" **As built, more narrowly or broadly than these words:** {built}" if built else "")
        calls = ", ".join(f"`{r}`" for r in rec.get("refs", [])) or "no concept"
        out.append(f"| `{cid}` | {rec.get('kind')} | {contract} | {rec.get('definition') or ''} | {args} | {params} | "
                   f"{', '.join(rec.get('reads', []))} | {calls} | {len(rec.get('used_by', []))} | {len(rec.get('callers', []))} |")
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


# ---------------------------------------------------------------------------------------------
# What a reviewer is taught: the case language, the catalogue a case may use, the lint's contract
# ---------------------------------------------------------------------------------------------
#: JSON shape of each Lean type a constructor argument can have.
_JSON_OF_TYPE = {"Formula": "formula", "Term": "term", "Arg": "argument", "List Arg": "[argument, …]",
                 "List Term": "[term, …]", "String": "string", "Nat": "natural number", "Measure": '"time" | "path"',
                 "CmpOp": '"lt" | "le" | "eq" | "ge" | "gt"', "AggOp": '"min" | "max" | "median" | "count"',
                 "Q": '{"num": integer, "den": positive integer}', "PUnit'": "a unit spelling below", "ParamName": "string",
                 "AsmId": "string", "IntId": "string"}
#: Constructors a case may not use; `derived` and `quantity` are admitted for primitives only.
CASE_BANNED = {"param", "rule", "ruleApplies"}


def _ctor_signatures(text: str, inductive: str) -> dict[str, list[str]]:
    """Constructor → argument types, from an inductive's declaration in Formula.lean."""
    start = text.index(f"inductive {inductive}")
    body = text[start:]
    body = body[:re.search(r"\n  (?:/--|inductive )|\nend\b", body[1:]).start() + 1]
    out = {}
    for m in re.finditer(r"^\s+\| (\w+)((?: \([^)]*\))*)", body, re.M):
        types = []
        for group in re.findall(r"\(([^)]*)\)", m.group(2)):
            names, t = group.split(":", 1)
            types += [t.strip()] * len(names.split())
        out[m.group(1)] = types
    return out


def _top_level(text: str, sep: str = ",") -> list[str]:
    """`text` split at `sep` outside parentheses and brackets."""
    out, depth, cur = [], 0, ""
    for ch in text:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == sep and depth == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def _encoder_arms(text: str, fn: str) -> dict[str, list[tuple[str, str]]]:
    """Constructor → [(JSON key, value shape)] from Export.lean's encoder `fn`, the shapes taken
    from the constructor's argument types in Formula.lean."""
    block = _block(text, f"partial def {fn}", r"^  partial def |^end\b")
    sigs = _ctor_signatures(_read("Language/Formula.lean"), fn.split(".")[0])
    out = {}
    for m in re.finditer(r"^\s+\| \.(\w+)((?: [\wφψ']+)*) =>[ \t]*\n?\s*Json\.mkObj \[(.*)\]\s*$", block, re.M):
        ctor, vars_, items = m.group(1), m.group(2).split(), m.group(3)
        types = dict(zip(vars_, sigs.get(ctor, [])))
        keys = []
        for item in _top_level(items):
            km = re.match(r'\("(\w+)", (.*)\)$', item)
            if not km:
                continue
            key, expr = km.group(1), km.group(2)
            if expr.startswith("Json.arr #["):
                vs = re.findall(r"([\wφψ']+)\.toJson", expr)
                shape = "[" + ", ".join(_JSON_OF_TYPE.get(types.get(v, ""), "value") for v in vs) + "]"
            elif expr.startswith("args "):
                shape = _JSON_OF_TYPE["List Arg"]
            elif expr.startswith("Json.arr (ps.map"):
                shape = _JSON_OF_TYPE["List Term"]
            elif expr.startswith("Json.mkObj (map"):
                shape = "object of strings"
            else:
                call = re.match(r"\w+\.toJson ([\wφψ']+)$", expr)        # `Formula.toJson φ`
                v = call.group(1) if call else re.match(r"([\wφψ'.]+)", expr).group(1).split(".")[0]
                t = types.get(v, "")
                shape = _JSON_OF_TYPE.get(t, "value")
            keys.append((key, shape))
        out[ctor] = keys
    return out


def _units_spelled() -> list[str]:
    return re.findall(r'=> "(\w+)"', _block(_read("Language/Export.lean"), "def PUnit'.toJson", r"^def Q\.toJson"))


def constructor_meanings() -> dict[str, dict[str, str]]:
    """What each term and formula constructor means, as the comment on its line in `Formula.lean`
    states it: {"term": {ctor: meaning}, "formula": {ctor: meaning}}."""
    t = _read("Language/Formula.lean")
    out = {}
    for what, start, stop in (("term", "inductive Term", "inductive Formula"), ("formula", "inductive Formula", "\nend")):
        i = t.index(start); j = t.index(stop, i + len(start))
        out[what] = {}
        for m in re.finditer(r"(?m)^\s*\| (\w+)\b([^\n]*?)--\s*([^\n]+)$", t[i:j]):
            greek = [g for grp in re.findall(r"\(([^():]*):\s*Formula\)", m.group(2)) for g in grp.split()]
            out[what][m.group(1)] = (m.group(3).strip(), greek)
    return out


def case_language() -> str:
    """Every JSON form a case may use, with its exact keys and what it means, generated from
    Export.lean's encoders and Formula.lean's constructors and their comments; how a case states a
    fact at an earlier observation; the units a literal may carry; the divergence fields that hold a
    case."""
    exp = _read("Language/Export.lean")
    meanings = constructor_meanings()
    forms = []
    for fn, what in (("Formula.toJson", "formula"), ("Term.toJson", "term")):
        for ctor, keys in _encoder_arms(exp, fn).items():
            if ctor in CASE_BANNED:
                continue
            if what == "formula" and ctor in ("and", "or"):                # `Decode.formula` joins two or more to the right
                keys = [(k, "[formula, formula, …]") for k, _s in keys]
            obj = "{" + ", ".join(f'"{k}": {s}' for k, s in keys) + "}"
            note = " — only a primitive (`prim_…`), never a concept" if ctor in ("derived", "quantity") else ""
            if ctor == "asm":
                note = (" — the trace declares the assumption `id` true at this observation; `{\"not\": {\"asm\": id}}` states "
                        "that it declares it false")
            if ctor in ("existsRegion", "forallRegion", "existsDevice", "forallDevice"):
                note = (f" — the value of `{keys[0][0]}` is the kind (`{{\"lit\": \"<kind>\"}}`), and `var` names the "
                        "variable the body reads")
            meaning, greek = meanings.get(what, {}).get(ctor, (None, []))
            fkeys = [k for k, shape in keys if shape == "formula"]
            names = ", ".join(f"{g} is `{k}`" for g, k in zip(greek, fkeys) if g in (meaning or ""))
            forms.append(f"- {what} `{keys[0][0] if keys else ctor}`: `{obj}`" + (f" — {meaning}" if meaning else "")
                         + (f" ({names})" if names else "") + note)
    return ("### The case language (`Core/Language/Export.lean`, read back strictly by `Decode.formula`)\n\n"
            "A case is one formula in this JSON. Every object carries exactly the keys of one form below: a key missing or\n"
            "added, a null, an array of the wrong length, a fractional `num` or a zero `den` is rejected. The constant formulas are\n"
            "the bare strings `\"tt\"` and `\"ff\"`, never objects. `and` and `or` take a list of two or more\n"
            "(`{\"and\": [a, b, c]}` is read as `{\"and\": [a, {\"and\": [b, c]}]}`); every other form whose value is a list\n"
            "(`implies`, `until`, `since`, `same`, `add`, `sub`, `mul`, `div`) takes exactly two: nest it for more.\n\n" + "\n".join(forms) + "\n\n"
            "A case is read at `at`. A window behind reads the scenes before `at`, a window ahead the scenes after it. A fact at\n"
            "an earlier observation is stated through a window behind, never one ahead:\n"
            "- φ held at some observation in the N s behind `at` (the subject a binder):\n"
            "  `{\"not\": {\"holds_for\": \"time\", \"length\": {\"lit\": {\"num\": N, \"den\": 1}, \"unit\": \"second\"}, \"subject\": \"<binder>\", \"body\": {\"not\": φ}}}`;\n"
            "- φ held at the earlier observation whose timestamp is t seconds (`kin_time` reads a scene's timestamp in seconds;\n"
            "  a scene's `t` and `at` are in milliseconds): the same, N reaching back to it, with φ replaced by\n"
            "  `{\"and\": [{\"cmp\": \"eq\", \"lhs\": {\"measure\": \"kin_time\", \"args\": []}, \"rhs\": {\"lit\": {\"num\": t, \"den\": 1}, \"unit\": \"second\"}}, φ]}`.\n\n"
            "- argument: `{\"var\": string}` (a binder of the grounding, an entity, or a quantifier's variable), `{\"lit\": string}`\n"
            "  (an enumeration spelling or a selector), or `{\"nat\": natural number}` (a count, never an entity id)\n"
            f"- a literal's `unit`: {', '.join(f'`{u}`' for u in _units_spelled())}; `{{\"num\": 27, \"den\": 2}}` is 13.5\n\n"
            "Not admitted in a case: a reading parameter (`param`), another rule (`rule`, `rule_applies`), a concept (a\n"
            "`derived` or `quantity` whose name is not `prim_…`), a division except by a non-zero literal, and `ru_aggregate`:\n"
            "a case names a road user's concrete classes.\n\n"
            "An assumption (`asm`) and a declared intention (`int`) are facts of the trace a case may state: the id is one the\n"
            "run's declarations catalogue under its kind (a case naming another is not admitted), and the judges are shown the\n"
            "id's meaning. A case holds only where the trace declares what it states, so an assumption the trace leaves\n"
            "undeclared is never stated, true or false. An intention's arguments are a road user and a region of the case.\n\n"
            "A divergence that carries a case adds three fields:\n"
            "- `case`: the formula, true at `at` on the trace, that states the facts the law's verdict turns on;\n"
            "- `entities`: `{\"<name>\": {\"kind\": \"track\" | \"region\" | \"device\", \"id\": natural number}}`, the regions,\n"
            "  devices and further tracks the case names, each present in the scene at `at` with that kind; entity names\n"
            "  differ from each other and from the binders, and no quantifier of the case reuses one;\n"
            "- `at`: the timestamp (milliseconds) of the scene at which the case is stated and the rule's verdict is read.\n"
            "A situation the vocabulary cannot state gives `unstatable` (the words of the situation the catalogue cannot\n"
            "state) instead of `case`, `entities` and `at`.\n")


def _dimensions() -> tuple[dict[str, tuple[int, int, int]], dict[str, tuple]]:
    """(measure → dimension, primitive → (result dimension or None, [parameter dimensions])) from
    the generated `Vocab/Ontology/Dimensions.lean`."""
    t = _read("Vocab/Ontology/Dimensions.lean")
    d = lambda s: tuple(int(x) for x in s.split(","))
    measures = {n: d(v) for n, v in re.findall(r'\("(\w+)", ⟨([-\d, ]+)⟩\)', t.split("def ofPrimitive")[0])}
    prims = {}
    for n, r, ps in re.findall(r'\("(\w+)", (none|some ⟨[-\d, ]+⟩), \[([^\]]*)\]\)', t.split("def ofPrimitive")[1]):
        prims[n] = (None if r == "none" else d(r[6:-1]), [d(p) for p in re.findall(r"⟨([-\d, ]+)⟩", ps)])
    return measures, prims


def render_dim(dim: tuple[int, int, int] | None) -> str:
    if dim is None:
        return "true / false"
    parts = [u if e == 1 else f"{u}^{e}" for u, e in zip(("m", "s", "deg"), dim) if e]
    return "·".join(parts) or "1 (no unit)"


def _dispatch_arms(fn_text: str) -> dict[str, list[tuple[list[str], str]]]:
    """name → [(argument variables, arm text)] for every `| "name", [args] =>` arm of a dispatcher."""
    out: dict[str, list[tuple[list[str], str]]] = {}
    arms = re.split(r"(?m)^  \| ", fn_text)
    for a in arms[1:]:
        m = re.match(r'"(\w+)", \[([^\]]*)\] =>', a)
        if m:
            out.setdefault(m.group(1), []).append(([v.strip() for v in m.group(2).split(",") if v.strip()], a))
    return out


def _atom_params(name: str, arm: str) -> list[str]:
    """The parameters an atom's arm of `evalAtomE` matches (`match ps with | [tol] => …`), named by
    its `parameterMissing` message: what a case must pass in `params`, each without a unit, as
    `Case.check` requires of an atom's parameters."""
    m = re.search(r"match ps with\s*\|\s*\[([^\]]*)\]\s*=>", arm)
    if not m:
        return []
    names = [v.strip() for v in m.group(1).split(",") if v.strip()]
    label = re.search(r'parameterMissing "([^"]*)"', arm)
    what = label.group(1).removeprefix(name).strip() if label else ""
    return [what or v for v in names] if len(names) == 1 else names


def _arg_sorts(sem: str) -> tuple[dict[str, list[str | None]], str]:
    block = _block(sem, "def atomArgSorts", r"^/--|^def defName")
    explicit = {}
    for names, sorts in re.findall(r'\| ((?:"\w+"\s*(?:\|\s*)?)+)=> some \[([^\]]*)\]', block.replace("\n  |", " |")):
        kinds = [{"t": "track", "r": "region", "d": "device"}.get(s.strip()) for s in sorts.split(",") if s.strip()]
        for n in re.findall(r'"(\w+)"', names):
            explicit[n] = kinds
    return explicit, block


def _sorts_of(name: str, explicit: dict) -> list[str | None]:
    if name in explicit:
        return explicit[name]
    if name.startswith("env_") or name == "kin_time":
        return []
    if name.startswith(("ru_", "kin_", "sig_")):
        return ["track", None, None]
    if name.startswith("st_"):
        return ["region", None, None]
    if name.startswith("dev_"):
        return ["device", None, None]
    return []


def _literal_spellings(arm: str, var: str, spell: dict[str, set[str]]) -> str:
    m = re.search(rf"enumLit (\w+)\.ofString {re.escape(var)}\b", arm)
    if m and m.group(1) in spell:
        return " | ".join(f"'{s}'" for s in sorted(spell[m.group(1)]))
    if re.search(rf"comp \(.*\) {re.escape(var)} name", arm):
        return "'x' | 'y'"
    lits = re.findall(r'\| \.s "(\w+)"', arm)
    if re.search(rf"match {re.escape(var)} with", arm) and lits:
        return " | ".join(f"'{s}'" for s in lits)
    return "literal"


def case_catalogue(onto) -> list[dict]:
    """Every atom and primitive a case may name, with its arguments, unit, contract and where a
    trace writes it: exactly what `Case.check` admits on the active Core (the dispatch tables of
    Semantics.lean, the class atoms of the generated codecs, the measures and primitives with a
    dimension), each with a contract from the run's ontology."""
    from ..phases.review import trace_place
    sem = _read("Language/Semantics.lean")
    bools = re.findall(r'"(\w+)"', re.search(r"boolAtomNames : List String := \[(.*?)\]", sem, re.S).group(1))
    measures_listed = re.findall(r'"(\w+)"', re.search(r"measureNames : List String := \[(.*?)\]", sem, re.S).group(1))
    dims, prims = _dimensions()
    spell = enumeration_spellings()
    classes = [f"ru_{k}" for k in sorted(spell.get("RoadUserClass", ()))] + [f"st_{k}" for k in sorted(spell.get("StructureKind", ()))] \
        + [f"dev_{k}" for k in sorted(spell.get("DeviceKind", ()))]
    explicit, _ = _arg_sorts(sem)
    atom_arms = _dispatch_arms(_block(sem, "def evalAtomE", r"^where"))
    measure_arms = _dispatch_arms(_block(sem, "def evalMeasure", r"^where"))
    prim_sorts = {}
    pblock = _block(_read("Vocab/Primitives.lean"), "def argSorts", r"^private def tid")
    for names, sorts in re.findall(r'\| ((?:"\w+"\s*(?:\|\s*)?)+)=> some \[([^\]]*)\]', pblock):
        kinds = ["device" if "device" in s else "region" if "region" in s else "track" for s in sorts.split(",") if s.strip()]
        for n in re.findall(r'"(\w+)"', names):
            prim_sorts[n] = kinds
    atom_ids = set(core_atom_ids())
    rows = []

    def entry(name: str, kind: str, signatures: list[str], dim) -> None:
        aid = atom_id_of(name, atom_ids) if not name.startswith("prim_") else name.replace("_", ".", 1)
        rows.append({"name": name, "kind": kind, "signatures": signatures, "unit": render_dim(dim), "dim": dim,
                     "contract": onto.contract(aid) if aid else "", "atom": aid,
                     "place": trace_place(name) if not name.startswith("prim_") else "computed by Core from the atoms it reads"})

    def sigs(name: str, arms: dict, sorts: list) -> list[str]:
        out = []
        for vars_, arm in arms.get(name, [([], "")]) if name in arms else [([f"a{i}" for i in range(len([s for s in sorts if s]))], "")]:
            parts = []
            for i, v in enumerate(vars_):
                s = sorts[i] if i < len(sorts) else None
                parts.append(s if s else _literal_spellings(arm, v, spell))
            out.append(f"{name}({', '.join(parts)})")
        return out
    for n in sorted(set(bools) - {"ru_aggregate"}):
        ps = [p for _vars, arm in atom_arms.get(n, []) for p in _atom_params(n, arm)]
        tail = f" params [{', '.join(f'{p}: {render_dim((0, 0, 0))}' for p in ps)}]" if ps else ""
        entry(n, "boolean atom", [s + tail for s in sigs(n, atom_arms, _sorts_of(n, explicit))], None)
    for n in classes:
        if n not in bools:
            entry(n, "boolean atom (class)", [f"{n}({_sorts_of(n, explicit)[0]})"], None)
    for n in measures_listed:
        if n in dims:
            entry(n, "measured atom", sigs(n, measure_arms, _sorts_of(n, explicit)), dims[n])
    for n, (res, ps) in sorted(prims.items()):
        arg = ", ".join(prim_sorts.get(n, []))
        par = ", ".join(render_dim(p) for p in ps)
        entry(n, "boolean primitive" if res is None else "quantity primitive",
              [f"{n}({arg})" + (f" params [{par}]" if ps else "")], res)
    return rows


def case_vocabulary(onto) -> str:
    rows = case_catalogue(onto)
    groups: dict[str, list[dict]] = {}
    for r in rows:
        groups.setdefault(r["atom"] or r["name"], []).append(r)
    out = ["### The case vocabulary (every atom and primitive a case may name; generated from the active Core and the run's ontology)", "",
           "A true/false atom is `{\"atom\": name, \"args\": [...], \"params\": [...]}`, its `params` the ones its row lists (`[]` where it lists none); an atom with a unit is",
           "`{\"measure\": name, \"args\": [...]}`; a Boolean primitive is `{\"derived\": name, …}`, a quantity primitive",
           "`{\"quantity\": name, …}`, its `params` literals in the units listed. Track, region and device positions take a",
           "variable (a binder or an entity). `<Enumeration>` in a spelling is one of that enumeration's spellings.", "",
           "| id | names a formula uses (arguments) → value | contract | in the trace |", "|---|---|---|---|"]
    for aid, rs in groups.items():
        names = "<br>".join(f"`{sig}` → {r['unit']}" for r in rs for sig in r["signatures"])
        places = "; ".join(dict.fromkeys(r["place"] for r in rs))
        out.append(f"| `{aid}` | {names} | {' '.join(str(rs[0]['contract']).split())} | {places} |")
    return "\n".join(out) + "\n"


def lint_contract() -> str:
    """The trace check's contract as `Core/Evidence/TraceLint.lean` states it in its module comment:
    what a written trace must satisfy, word for word."""
    t = _read("Evidence/TraceLint.lean")
    body = t[t.index("/-") + 2:t.index("-/")]
    lines = body.splitlines()[2:]                       # past the module name
    return "\n".join(l[2:] if l.startswith("  ") else l for l in lines).strip() + "\n"


# ---------------------------------------------------------------------------------------------
# The trace document: the keys the decoder reads, from `Runtime/Decode.lean`
# ---------------------------------------------------------------------------------------------
#: The decoder functions of the trace document, and the name each record goes by in the format.
_RECORDS = {"scene": "scene", "roadUser": "user (scene.users[])", "kin": "kin (user.kin)", "signals": "sig (user.sig)",
            "posture": "posture (user.posture)", "warningLamp": "warning lamp (sig.warning_lamps[])",
            "structure'": "structure (scene.structures[])", "laneInfo": "lane (structure.lane)",
            "device": "device (scene.devices[])", "conditions": "conditions (device.conditions)",
            "timeWindow": "time window (conditions.windows[])", "env": "env (scene.env)",
            "civilTime": "civil time (env.civil_time)", "relation": "relation (scene.relations[])",
            "declaredIntent": "intent (scene.intents[])"}
_SUB = {"roadUser": "user", "kin": "kin", "signals": "sig", "posture": "posture", "warningLamp": "warning lamp",
        "structure'": "structure", "laneInfo": "lane", "device": "device", "conditions": "conditions",
        "timeWindow": "time window", "env": "env", "civilTime": "civil time", "relation": "relation", "declaredIntent": "intent",
        "marking": "[marking type, marking colour]"}
_PRIM = {"vec": "[x, y]", "num": "number", "bool": "bool", "nat": "nat", "int": "int", "str": "string"}


def _decoder_type(tok: str, key: str) -> str:
    if key == "extent":
        return "[half_length, half_width, half_height]"
    if key == "values":
        return "[[int.<name>, bool], ...]"
    if tok in _PRIM:
        return _PRIM[tok]
    if tok in _SUB:
        return _SUB[tok]
    m = re.match(r"\(enum (\w+)\.ofString\)", tok)
    if m:
        abstract = sorted(abstract_kinds()) if m.group(1) == "StructureKind" else []
        return f"a {m.group(1)} spelling" + (f" other than an abstract kind ({', '.join(abstract)})" if abstract else "")
    m = re.match(r"\(pair (\w+) (\w+)\)", tok)
    if m:
        return f"[{_PRIM.get(m.group(1), m.group(1))}, {_PRIM.get(m.group(2), m.group(2))}]"
    return "value"


def _decode_source() -> str:
    return (paths.CORE / "Runtime" / "Decode.lean").read_text(encoding="utf-8")


def decoder_keys(decode_source: str) -> dict[str, list[str]]:
    """Every key the trace decoder reads, per record, with its type and whether it is required: read
    from the decoder's source, so the format a reviewer writes in is the format that decodes."""
    out: dict[str, list[str]] = {}
    for m in re.finditer(r"^def (\w+'?) \(path : String\) \(j : Json\) : D \w+ := do\n(.*?)(?=^def |\Z)", decode_source, re.S | re.M):
        name, body = m.group(1), m.group(2)
        if name not in _RECORDS:
            continue
        rows = []
        for km in re.finditer(r"\b(opt|req|list|optList) j path \"([a-z_]+)\" (\([^)]*\)|[\w']+)", body):
            how, key, tok = km.groups()
            t = _decoder_type(tok, key)
            rows.append(f"`{key}` {('[' + t + ', ...]') if how in ('list', 'optList') else t}{' (required)' if how == 'req' else ''}")
        if name == "scene":
            rows.append("`occupancy_observed` true | [track, ...]")
        out[_RECORDS[name]] = rows
    return out


@lru_cache(maxsize=1)
def trace_schema() -> tuple[dict[str, frozenset], dict[tuple[str, str], str]]:
    """The keys the trace decoder reads, from the same table the trace format shows: (each record's
    keys, `(record, key)` → the record nested under that key). A trace is `{"scenes": [scene, ...]}`."""
    keys = decoder_keys(_decode_source())
    records = {label.split(" (")[0]: frozenset(m.group(1) for r in rows if (m := re.match(r"`([a-z_]+)`", r))) for label, rows in keys.items()}
    nested = {}
    for label in keys:
        m = re.match(r"(.+?) \(([\w ]+?)\.(\w+)(?:\[\])?\)$", label)
        if m:
            nested[(m.group(2), m.group(3))] = m.group(1)
    return records, nested


def _walk_keys(obj, record: str, path: str, out: list[str], drop: bool) -> None:
    records, nested = trace_schema()
    if not isinstance(obj, dict) or record not in records:
        return
    for k in list(obj):
        if k not in records[record]:
            out.append(f"{path}.{k}")
            if drop:
                del obj[k]
            continue
        child = nested.get((record, k))
        if child is None:
            continue
        v = obj[k]
        for i, e in enumerate(v if isinstance(v, list) else [v]):
            ident = (e.get("track", e.get("id", f"{e.get('a')}-{e.get('b')}" if "a" in e else i))) if isinstance(e, dict) else i
            _walk_keys(e, child, f"{path}.{k}" + (f"[{ident}]" if isinstance(v, list) else ""), out, drop)


def unread_keys(trace) -> list[str]:
    """The keys of a written trace the decoder does not read, by path (`scenes[t=0].users[1].kin.x`):
    Core never executes them, so they are no evidence of anything."""
    out: list[str] = []
    if not isinstance(trace, dict):
        return out
    out += [k for k in trace if k != "scenes"]
    for sc in trace.get("scenes") or [] if isinstance(trace.get("scenes"), list) else []:
        _walk_keys(sc, "scene", f"scenes[t={sc.get('t') if isinstance(sc, dict) else '?'}]", out, False)
    return out


def read_part(trace) -> dict:
    """A written trace with only the keys the decoder reads: what Core executes."""
    if not isinstance(trace, dict):
        return {}
    out = json.loads(json.dumps({"scenes": trace.get("scenes")} if "scenes" in trace else {}))
    for sc in out.get("scenes") or [] if isinstance(out.get("scenes"), list) else []:
        _walk_keys(sc, "scene", "", [], True)
    return out


def decoder_fields(decode_source: str) -> dict[str, dict[str, tuple[str, str]]]:
    """Per decoder of a record: the World field it fills → (the JSON key it reads, the decoder of
    a nested record or '')."""
    out: dict[str, dict[str, tuple[str, str]]] = {}
    for m in re.finditer(r"^def (\w+'?) \(path : String\) \(j : Json\) : D \w+ := do\n(.*?)(?=^def |\Z)", decode_source, re.S | re.M):
        fields = {}
        for fm in re.finditer(r"(\w+) := \(?← (?:opt|req|list|optList) j path \"([a-z_]+)\" (\([^)]*\)|[\w']+)", m.group(2)):
            sub = fm.group(3) if fm.group(3) in _SUB else ""
            fields[fm.group(1)] = (fm.group(2), sub)
        out[m.group(1)] = fields
    return out
