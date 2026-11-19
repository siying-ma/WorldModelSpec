"""The behaviour-property review's answers, their schemas and the adoption gate: the deterministic
step between the two reviewer models (the author, role A, and the second vendor's screen, role B')
and the property set the check runs on. No model is called here.

Reason: a property is checked against a law's rules only once the harness itself has decided, by a
fixed rule over schema-valid answers, that the two blind reviewers agree on it; the models' own
claims about adoption are never read.

Files (`review_schemas/`, beside this module):
- `bp_candidate.schema.json`: role A's answer (clauses, candidates, distinctions);
- `bp_screen.schema.json`: role B''s answer (items, clause assessments, missed obligations, uncovered
  situations, the law's behaviour);
- `bp_formula.schema.json`: the property language's formulas (a binder class, an antecedent);
- `bp_record.schema.json`, `bp_active_set.schema.json`, `bp_coverage.schema.json`: what the harness
  writes (one candidate's adoption, a law's active set with its withdrawals, one check's coverage);
- `bp_limits.json`: the bounds JSON Schema cannot state (byte sizes; candidates per clause).
Each count and length bound lives in exactly one file: a schema's own `maxItems` and `maxLength`,
read by the gate from the schema, or `bp_limits.json`. A bound is never truncated into a pass: an
answer beyond a schema bound is invalid as a whole; a candidate beyond a gate bound is refused and
recorded as a `count_or_size_refused` hole.

`startup_defects` checks the files before anything uses them: every schema is valid draft 2020-12
and closed (every object schema says `additionalProperties: false`), the gate's own enumerations and
bounds agree with the schemas', and the two prompt templates render with the schema text and the
property language exactly as given.

The gate (`adopt_answer`) takes the rounds of one generation, each `{"draft", "screen"}`, and the
context the prompts were rendered with. An answer that does not validate against its schema, or is
larger than its byte bound, makes the whole generation `failed`: no property is published and no
exemption can follow from it; the per-candidate checks still run on what parses and are kept only
as `diagnostics`. A schema-valid answer is processed candidate by candidate: each candidate passes or
fails the static checks (clauses located, quotes, exception polarity, the property language, the
per-clause bound) and then the screen's adoption rule, and every refusal is recorded with its reason
and, where it leaves a clause and category uncovered, its hole.

Identity. A property's `identity` is the digest of its normalized identity: its binders (name, class
and subject flag), antecedent, category and expected verdict, written as canonical JSON (keys sorted,
compact separators, Unicode kept, NFC). The display id and the clause are not part of it. Ordinary
normalization claims no detection of logically equivalent formulas: two properties whose JSON
differs are two identities. `antecedent_sha` (the antecedent's digest alone) is kept for reports only."""
from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from fractions import Fraction
from functools import lru_cache
from pathlib import Path

SCHEMA_DIR = Path(__file__).with_name("review_schemas")
FILES = {"draft": "bp_candidate.schema.json", "screen": "bp_screen.schema.json", "formula": "bp_formula.schema.json",
         "record": "bp_record.schema.json", "active_set": "bp_active_set.schema.json", "coverage": "bp_coverage.schema.json"}
LIMITS_FILE = "bp_limits.json"
CATEGORIES = ("must_detect", "must_not_flag")
EXPECTED = {"must_detect": "violated", "must_not_flag": "not_violated"}
DISTINCTIONS = ("action", "place", "time_or_order", "road_users", "feasibility")
RATINGS = ("full_match", "minor_deviation", "major_deviation", "cannot_rate")
ITEM_CAUSES = ("adoptable", "misreads_words", "not_expressible", "cannot_tell")
ASSESSMENTS = ("properties_given", "reason_confirmed", "reason_rejected")
LAW_BEHAVIOUR = ("checkable", "no_checkable_behaviour", "cannot_tell")
BEHAVIOUR_KINDS = ("purpose_or_policy", "permission_or_authorization", "definition_or_scope", "other")
HOLE_KINDS = ("no_adopted_property", "exemption_not_confirmed", "rejected", "expression_gap", "count_or_size_refused",
              "outside_fragment", "multi_binder_not_supported", "not_executed", "missed_obligation", "uncovered_situation")
NOT_EXECUTABLE = ("gap", "outside_language", "count_or_size")
#: The templates of the two roles and the placeholders each one's renderer supplies (held to the
#: templates by the doctor).
PLACEHOLDERS_BP_DRAFT = ("law", "definitions", "conventions", "atoms", "property_language", "round_two_feedback", "output_schema")
PLACEHOLDERS_BP_SCREEN = ("law", "definitions", "conventions", "atoms", "property_language", "clauses", "candidates", "output_schema")
TEMPLATES = {"bp_draft.md": ("draft", PLACEHOLDERS_BP_DRAFT), "bp_screen.md": ("screen", PLACEHOLDERS_BP_SCREEN)}
PROPERTY_LANGUAGE = "bp_property_language.md"
#: The property language's frames: the world-frame vector measures (positions apart, which are read
#: only through differences), and the measure whose components are in the frame of its first argument.
WORLD_VECTORS = ("st_lane_direction", "kin_heading", "kin_velocity", "kin_position", "dev_position", "st_region_geometry")
POSITIONS = ("kin_position", "dev_position", "st_region_geometry")
USER_FRAME = "rel_bearing"
COMPONENTS = ("x", "y")
#: Dimensions as exponents of (metre, second, degree, kilogram): of the measure table's unit words
#: and of the literal units the property language allows.
MEASURE_DIMS = {"m": (1, 0, 0, 0), "s": (0, 1, 0, 0), "1": (0, 0, 0, 0), "m/s": (1, -1, 0, 0), "m/s²": (1, -2, 0, 0),
                "deg/s": (0, -1, 1, 0), "deg": (0, 0, 1, 0), "kg": (0, 0, 0, 1), "1/m": (-1, 0, 0, 0)}
LITERAL_DIMS = {"metre": (1, 0, 0, 0), "second": (0, 1, 0, 0), "metre_per_second": (1, -1, 0, 0),
                "metre_per_second_sq": (1, -2, 0, 0), "degree": (0, 0, 1, 0), "degree_per_second": (0, -1, 1, 0),
                "per_metre": (-1, 0, 0, 0), "ratio": (0, 0, 0, 0), "count": (0, 0, 0, 0)}
ELLIPSIS = re.compile(r"\.\.\.|…")


class SchemaConfigError(RuntimeError):
    """The schema files, the gate and the renderer disagree: nothing may be adopted."""


# -- canonical JSON and digests ------------------------------------------------------------------------

def _nfc(x):
    if isinstance(x, str):
        return unicodedata.normalize("NFC", x)
    if isinstance(x, list):
        return [_nfc(v) for v in x]
    if isinstance(x, dict):
        return {_nfc(k): _nfc(v) for k, v in x.items()}
    return x


def canonical(x) -> str:
    """UTF-8 canonical JSON: keys sorted, compact separators, non-ASCII kept, strings in NFC."""
    return json.dumps(_nfc(x), sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def sha(x) -> str:
    return hashlib.sha256(canonical(x).encode("utf-8")).hexdigest()


def compact_bytes(x) -> int:
    return len(json.dumps(x, separators=(",", ":"), ensure_ascii=False).encode("utf-8"))


def identity_of(rec: dict) -> dict:
    """The normalized identity of a property (see the module's description): never its display id."""
    return {"binders": [{"name": b.get("name"), "cls": b.get("cls"), "subject": bool(b.get("subject", False))}
                        for b in rec.get("binders") or [] if isinstance(b, dict)],
            "antecedent": rec.get("antecedent"), "category": rec.get("category"), "expected": rec.get("expected")}


def identity(rec: dict) -> str:
    return sha(identity_of(rec))


def antecedent_sha(rec: dict) -> str:
    return sha(rec.get("antecedent"))


# -- the files --------------------------------------------------------------------------------------------

@lru_cache(maxsize=1)
def schemas() -> dict[str, dict]:
    return {k: json.loads((SCHEMA_DIR / f).read_text(encoding="utf-8")) for k, f in FILES.items()}


@lru_cache(maxsize=1)
def limits() -> dict:
    return json.loads((SCHEMA_DIR / LIMITS_FILE).read_text(encoding="utf-8"))


def _registry():
    from referencing import Registry, Resource
    return Registry().with_resources([(s["$id"], Resource.from_contents(s)) for s in schemas().values()])


@lru_cache(maxsize=None)
def _validator(kind: str, pointer: str = ""):
    from jsonschema import Draft202012Validator
    s = schemas()[kind]
    if pointer:
        s = {"$schema": s["$schema"], "$ref": f"{s['$id']}#{pointer}"}
    return Draft202012Validator(s, registry=_registry())


def errors(kind: str, value, pointer: str = "") -> list[str]:
    """Every place `value` departs from schema `kind` (or its sub-schema at `pointer`), by path."""
    out = []
    for e in sorted(_validator(kind, pointer).iter_errors(value), key=lambda e: [str(p) for p in e.absolute_path]):
        path = "".join(f"[{p}]" if isinstance(p, int) else f".{p}" for p in e.absolute_path) or "(answer)"
        out.append(f"{path}: {e.message[:300]}")
    return out


def bound(kind: str, *path: str, key: str = "maxItems") -> int:
    """A bound a schema states, at `path` (property names, `[]` for an array's items, `$name` for a
    definition): the one place that bound is written."""
    s = schemas()[kind]
    node = s
    for p in path:
        node = s["$defs"][p[1:]] if p.startswith("$") else (node["items"] if p == "[]" else node["properties"][p])
        if "$ref" in node and node["$ref"].startswith("#/$defs/"):
            node = s["$defs"][node["$ref"].rsplit("/", 1)[1]]
    return node[key]


def _object_schemas(node, where="#"):
    if isinstance(node, dict):
        if node.get("type") == "object" or "properties" in node:
            yield where, node
        for k, v in node.items():
            yield from _object_schemas(v, f"{where}/{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from _object_schemas(v, f"{where}/{i}")


def _open_objects(kind: str) -> list[str]:
    """Object schemas that admit fields they do not name. An object left open on purpose (a formula
    or a candidate quoted whole, whose structure another schema or the gate checks) says so by having
    no `properties` and a description."""
    bad = []
    for where, node in _object_schemas(schemas()[kind]):
        if {"allOf", "if", "then", "else", "not"} & set(where.split("/")):   # a conditional's partial schema, not an object's own
            continue
        if "properties" not in node and node.get("description"):
            continue
        if node.get("additionalProperties") is not False:
            bad.append(f"{FILES[kind]} {where}")
    return bad


def _enum_at(kind: str, *path: str) -> tuple:
    s = schemas()[kind]
    node = s
    for p in path:
        node = s["$defs"][p[1:]] if p.startswith("$") else (node["items"] if p == "[]" else node["properties"][p])
        if "$ref" in node and node["$ref"].startswith("#/$defs/"):
            node = s["$defs"][node["$ref"].rsplit("/", 1)[1]]
    return tuple(v for v in node["enum"] if v is not None)


def startup_defects() -> list[str]:
    """Every disagreement between the schema files, the gate and the renderer (empty: consistent)."""
    from jsonschema import Draft202012Validator
    out: list[str] = []
    try:
        ss, lim = schemas(), limits()
    except (OSError, ValueError) as e:
        return [f"the review schema files do not load: {e}"]
    for k, s in ss.items():
        try:
            Draft202012Validator.check_schema(s)
        except Exception as e:                                       # noqa: BLE001 - the library's own error types
            out.append(f"{FILES[k]} is not a valid draft 2020-12 schema: {str(e)[:200]}")
        if s.get("$schema") != "https://json-schema.org/draft/2020-12/schema" or s.get("$id") != f"urn:traffic-spec:{FILES[k].split('.')[0]}":
            out.append(f"{FILES[k]}: `$schema` or `$id` is not the one this gate reads")
        out += [f"{w}: an object schema that is not closed (`additionalProperties: false`)" for w in _open_objects(k)]
    b = lim.get("bytes") or {}
    if lim.get("schema") != "bp_limits/1" or set(b) != {"draft_answer", "screen_answer", "binder_class", "antecedent"} \
            or not all(isinstance(v, int) and not isinstance(v, bool) and v > 0 for v in b.values()) \
            or not (isinstance(lim.get("per_clause_candidates"), int) and lim["per_clause_candidates"] >= 1):
        out.append(f"{LIMITS_FILE}: it must state four positive byte bounds and a positive `per_clause_candidates`")
        return out
    try:
        checks = [
            (_enum_at("draft", "$candidate", "category"), CATEGORIES, "candidate categories"),
            (_enum_at("draft", "$no_property", "category"), CATEGORIES, "no_property categories"),
            (_enum_at("draft", "$candidate", "expected"), tuple(EXPECTED.values()), "expected verdicts"),
            (tuple(ss["draft"]["properties"]["distinctions"]["required"]), DISTINCTIONS, "distinctions"),
            (_enum_at("screen", "$condition", "rating"), RATINGS, "ratings"),
            (_enum_at("screen", "$item", "item_cause"), ITEM_CAUSES, "item causes"),
            (_enum_at("screen", "$clause_assessment", "assessment"), ASSESSMENTS, "clause assessments"),
            (_enum_at("screen", "$clause_assessment", "category"), CATEGORIES, "clause assessment categories"),
            (_enum_at("screen", "$uncovered_situation", "category"), CATEGORIES, "uncovered categories"),
            (_enum_at("screen", "$law_behaviour", "assessment"), LAW_BEHAVIOUR, "law behaviour"),
            (_enum_at("screen", "$law_behaviour", "kind"), BEHAVIOUR_KINDS, "law behaviour kinds"),
            (_enum_at("screen", "$condition", "distinction_changed"), DISTINCTIONS, "distinctions changed"),
            (_enum_at("coverage", "holes", "[]", "kind"), HOLE_KINDS, "hole kinds"),
            (_enum_at("record", "not_executable"), NOT_EXECUTABLE, "not executable"),
        ]
        out += [f"the gate's {what} {list(mine)} differ from the schema's {list(theirs)}" for theirs, mine, what in checks if tuple(theirs) != tuple(mine)]
        if bound("screen", "clause_assessments") != len(CATEGORIES) * bound("draft", "clauses"):
            out.append("bp_screen's clause_assessments bound is not one per clause and category of bp_candidate's clause bound")
        if bound("screen", "items") != bound("draft", "candidates"):
            out.append("bp_screen's items bound differs from bp_candidate's candidates bound")
        if lim["per_clause_candidates"] > bound("draft", "candidates"):
            out.append(f"{LIMITS_FILE}: per_clause_candidates exceeds the candidates bound")
        pats = {ss["draft"]["$defs"]["clause"]["properties"]["id"]["pattern"], ss["draft"]["$defs"]["candidate"]["properties"]["clause"]["pattern"],
                ss["screen"]["$defs"]["clause_assessment"]["properties"]["clause"]["pattern"],
                ss["screen"]["$defs"]["uncovered_situation"]["properties"]["clause"]["pattern"]}
        if len(pats) != 1:
            out.append(f"the clause id patterns of the schemas differ: {sorted(pats)}")
        if len({ss["draft"]["$defs"]["candidate"]["properties"]["id"]["pattern"], ss["screen"]["$defs"]["item"]["properties"]["id"]["pattern"],
                ss["record"]["properties"]["property"]["pattern"], ss["active_set"]["$defs"]["withdrawal"]["properties"]["property"]["pattern"]}) != 1:
            out.append("the property id patterns of the schemas differ")
    except (KeyError, TypeError, IndexError) as e:
        out.append(f"a schema lacks a field the gate reads: {e!r}")
    out += _renderer_defects()
    return out


def _renderer_defects() -> list[str]:
    from ..agents import render
    from ..store import paths
    out = []
    lang = paths.PROMPTS / PROPERTY_LANGUAGE
    if not lang.is_file():
        return [f"prompts/{PROPERTY_LANGUAGE} is missing"]
    for tmpl, (kind, ph) in TEMPLATES.items():
        f = paths.PROMPTS / tmpl
        if not f.is_file():
            out.append(f"prompts/{tmpl} is missing"); continue
        found = set(re.findall(r"\{([a-z_]+)\}", f.read_text(encoding="utf-8")))
        if found != set(ph):
            out.append(f"prompts/{tmpl}: placeholders {sorted(found)} differ from its renderer's {sorted(ph)}"); continue
        values = {p: f"<{p}>" for p in ph} | {"output_schema": schema_text(kind), "property_language": property_language()}
        text = render.render(tmpl, values)
        if schema_text(kind) not in text or json.loads(schema_text(kind)) != schemas()[kind] or property_language() not in text:
            out.append(f"prompts/{tmpl}: the rendered prompt does not carry its schema and the property language as the gate reads them")
    return out


@lru_cache(maxsize=1)
def _checked() -> tuple[str, ...]:
    return tuple(startup_defects())


def startup_check() -> None:
    """Refuse to adopt anything while the files disagree (computed once per process)."""
    bad = _checked()
    if bad:
        raise SchemaConfigError("; ".join(bad[:6]))


def schema_text(kind: str) -> str:
    """The schema as the prompts show it ({output_schema}): the file's text."""
    return (SCHEMA_DIR / FILES[kind]).read_text(encoding="utf-8")


def property_language() -> str:
    from ..store import paths
    return (paths.PROMPTS / PROPERTY_LANGUAGE).read_text(encoding="utf-8")


def answer_errors(kind: str, answer) -> list[str]:
    """Why an answer of role `kind` (`draft` or `screen`) is invalid as a whole: its schema errors,
    and its size beyond its byte bound (stated, never truncated)."""
    out = errors(kind, answer)
    cap = limits()["bytes"]["draft_answer" if kind == "draft" else "screen_answer"]
    n = compact_bytes(answer)
    if n > cap:
        out.append(f"(answer): {n} bytes as compact JSON, beyond the bound of {cap}")
    return out


# -- the context the prompts were rendered with ----------------------------------------------------------

MEASURE_ROW = re.compile(r"^\| `([a-z]+\.[a-z_]+)` \| `([a-z_]+)` \| ([^|]+?) \|\s*$")


def measure_table(ontology_text: str) -> dict[str, tuple[str, str]]:
    """The measures of the ontology's table of measured atoms: name → (atom id, unit word)."""
    out, inside = {}, False
    for line in ontology_text.splitlines():
        if line.startswith("## "):
            inside = bool(re.match(r"^## \d+\. Units of the measured atoms", line))
            continue
        m = MEASURE_ROW.match(line) if inside else None
        if m:
            out[m.group(2)] = (m.group(1), m.group(3).strip())
    return out


def conventions_text(ontology_text: str) -> str:
    """The ontology's section on what is not an atom (the corpus-wide conventions and approved abstractions)."""
    m = re.search(r"^## 9\. .*?(?=^## \d+\. |\Z)", ontology_text, re.M | re.S)
    return m.group(0) if m else ""


def context(law_text: str, definitions: list[str] | None = None, ontology_text: str = "", conventions: str | None = None) -> dict:
    """What the gate reads of the inputs both roles were shown: the law's words, the definitions'
    words, the conventions' words (an approved abstraction is quoted from them), the atoms' Lean
    names and the measures with their units."""
    from ..model import ontology as onto_mod
    atoms: dict[str, str] = {}
    for line in ontology_text.splitlines():
        r = onto_mod.ROW.match(line)
        if r and not r.group(1).startswith("prim."):
            atoms[r.group(1).replace(".", "_")] = r.group(1)
    conv = conventions_text(ontology_text) if conventions is None else conventions
    return {"law_text": law_text, "definitions": list(definitions or []), "conventions": conv,
            "atoms": atoms, "measures": measure_table(ontology_text)}


def context_for(run, law_id: str) -> dict:
    """The context of a run's law: its posted text, the definitions that apply to it, the run's ontology."""
    from ..model import corpus
    from ..store.state import chain_laws
    laws = {l.id: l for l in corpus.load_laws(run.opts.laws)}
    law = laws.get(law_id) or chain_laws(run).get(law_id)
    if law is None:
        raise KeyError(f"`{law_id}` is not a law of the run's corpus")
    defs: list[str] = []
    try:
        from .plan import definitions_for
        defs = [d.get("text", "") for d in definitions_for(run, [law])]
    except (OSError, KeyError, ValueError):
        defs = []
    onto = Path(run.opts.ontology).read_text(encoding="utf-8") if getattr(run.opts, "ontology", None) else ""
    return context(law.text, defs, onto)


# -- quotes and clauses -----------------------------------------------------------------------------------

_QUOTES = str.maketrans({"“": '"', "”": '"', "„": '"', "‟": '"', "″": '"',
                         "‘": "'", "’": "'", "‚": "'", "‛": "'", "′": "'"})


def norm(text: str) -> str:
    """Whitespace runs to one space and typographic quotes to straight ones (NFC), for locating a quote."""
    return re.sub(r"\s+", " ", unicodedata.normalize("NFC", str(text)).translate(_QUOTES)).strip()


def spans(hay: str, needle: str) -> list[tuple[int, int]]:
    """Every occurrence of `needle` in `hay` (both normalized), overlapping ones included."""
    h, n = norm(hay), norm(needle)
    if not n:
        return []
    out, i = [], h.find(n)
    while i >= 0:
        out.append((i, i + len(n)))
        i = h.find(n, i + 1)
    return out


def clause_key(law_text: str, quote: str, occurrence: int, source: str) -> str:
    return sha({"law": sha(norm(law_text)), "quote": norm(quote), "occurrence": occurrence, "source": source})


def _quotable(q: str, ctx: dict) -> bool:
    return bool(spans(ctx["law_text"], q) or any(spans(t, q) for t in ctx["definitions"]) or spans(ctx["conventions"], q))


# -- the property language (static checks) ---------------------------------------------------------------

def _walk_formula(f, bound_vars: frozenset, acc: dict) -> None:
    if not isinstance(f, dict):
        return
    if "and" in f or "or" in f:
        for g in f.get("and") or f.get("or") or []:
            _walk_formula(g, bound_vars, acc)
    elif "not" in f:
        _walk_formula(f["not"], bound_vars, acc)
    elif "implies" in f:
        for g in f["implies"]:
            _walk_formula(g, bound_vars, acc)
    elif any(q in f for q in ("exists_region", "forall_region", "exists_device", "forall_device")):
        v = f.get("var")
        if v in bound_vars:
            acc["errors"].append(f"the quantifier variable `{v}` shadows a variable already bound")
        _walk_formula(f.get("body"), bound_vars | {v}, acc)
    elif "exists_user" in f or "forall_user" in f:
        v = f.get("exists_user", f.get("forall_user"))
        if v in bound_vars:
            acc["errors"].append(f"the quantifier variable `{v}` shadows a variable already bound")
        _walk_formula(f.get("body"), bound_vars | {v}, acc)
    elif "atom" in f:
        acc["atoms"].append(f["atom"])
        _args(f.get("args") or [], bound_vars, acc)
    elif "cmp" in f:
        acc["cmps"].append(f)
        for side in ("lhs", "rhs"):
            _walk_term(f.get(side), bound_vars, acc)


def _args(args, bound_vars, acc):
    for a in args:
        if isinstance(a, dict) and "var" in a and a["var"] not in bound_vars:
            acc["errors"].append(f"the variable `{a['var']}` is bound by no binder or quantifier")


def _walk_term(t, bound_vars, acc):
    if not isinstance(t, dict):
        return
    if "measure" in t:
        acc["measures"].append(t["measure"])
        _args(t.get("args") or [], bound_vars, acc)
    for op in ("add", "sub", "mul"):
        for u in t.get(op) or []:
            _walk_term(u, bound_vars, acc)
    for op in ("neg", "abs"):
        if op in t:
            _walk_term(t[op], bound_vars, acc)


def _component(t) -> tuple | None:
    """A world-frame component read: (`free` | `pos`, the vector's key, `x` | `y`), else None."""
    if not isinstance(t, dict):
        return None
    if "measure" in t and t["measure"] in WORLD_VECTORS:
        args = t.get("args") or []
        comps = [i for i, a in enumerate(args) if isinstance(a, dict) and a.get("lit") in COMPONENTS]
        if len(comps) != 1:
            return None
        i = comps[0]
        key = canonical([t["measure"], [a if j != i else "*" for j, a in enumerate(args)]])
        return ("pos" if t["measure"] in POSITIONS else "free", key, args[i]["lit"])
    if "sub" in t and len(t["sub"]) == 2:                            # a difference of two positions' components
        a, b = (_component(u) for u in t["sub"])
        if a and b and a[0] == b[0] == "pos" and a[2] == b[2] and a[1] != b[1]:
            return ("free", canonical(["diff", a[1], b[1]]), a[2])
    return None


def _mul_pair(t) -> tuple | None:
    if isinstance(t, dict) and "mul" in t and len(t["mul"]) == 2:
        a, b = (_component(u) for u in t["mul"])
        if a and b and a[0] == b[0] == "free":
            return a, b
    return None


def _invariant(t) -> bool:
    """`t` is a dot product, the z of a cross product, or a squared magnitude of free world vectors."""
    if not isinstance(t, dict):
        return False
    op = "add" if "add" in t else "sub" if "sub" in t else None
    if op is None or len(t[op]) != 2:
        return False
    p, q = (_mul_pair(u) for u in t[op])
    if not p or not q:
        return False
    def same(pp, qq):                                              # the two products' vectors, as unordered pairs
        return sorted([pp[0][1], pp[1][1]]) == sorted([qq[0][1], qq[1][1]])
    if not same(p, q):
        return False
    pc, qc = sorted(c[2] for c in p), sorted(c[2] for c in q)
    if op == "add":                                                # x·x + y·y over the same two vectors
        return pc == ["x", "x"] and qc == ["y", "y"] or pc == ["y", "y"] and qc == ["x", "x"]
    if p[0][1] == p[1][1]:                                         # a cross product of a vector with itself is 0: not a reading
        return False
    return pc == qc == ["x", "y"] and {(c[1], c[2]) for c in p}.isdisjoint({(c[1], c[2]) for c in q})


def _frames(t) -> tuple[bool, set]:
    """(whether `t` reads world-frame components only through invariant terms, the frames it reads)."""
    if not isinstance(t, dict):
        return True, set()
    if _invariant(t):
        return True, {"world"}
    if "measure" in t:
        args = t.get("args") or []
        has_comp = any(isinstance(a, dict) and a.get("lit") in COMPONENTS for a in args)
        if t["measure"] in WORLD_VECTORS and has_comp:
            return False, {"world"}
        if t["measure"] == USER_FRAME and has_comp and args:
            return True, {("user", canonical(args[0]))}
        return True, set()
    ok, fr = True, set()
    for op in ("add", "sub", "mul"):
        for u in t.get(op) or []:
            o, f = _frames(u); ok, fr = ok and o, fr | f
    for op in ("neg", "abs"):
        if op in t:
            o, f = _frames(t[op]); ok, fr = ok and o, fr | f
    return ok, fr


def _dims(t, measures: dict, errs: list) -> tuple | None:
    if not isinstance(t, dict):
        return None
    if "measure" in t:
        unit = (measures.get(t["measure"]) or (None, None))[1]
        d = MEASURE_DIMS.get(unit)
        if d is None:
            errs.append(f"the measure `{t['measure']}` has no unit in the table of measured atoms")
        return d
    if "lit" in t:
        return LITERAL_DIMS.get(t.get("unit"))
    for op in ("add", "sub"):
        if op in t:
            a, b = (_dims(u, measures, errs) for u in t[op])
            if a is not None and b is not None and a != b:
                errs.append(f"`{op}` joins two terms of different units")
                return None
            return a if a is not None else b
    if "mul" in t:
        a, b = (_dims(u, measures, errs) for u in t["mul"])
        return None if a is None or b is None else tuple(x + y for x, y in zip(a, b))
    for op in ("neg", "abs"):
        if op in t:
            return _dims(t[op], measures, errs)
    return None


def _reads_measure(t) -> bool:
    if not isinstance(t, dict):
        return False
    if "measure" in t:
        return True
    return any(_reads_measure(u) for op in ("add", "sub", "mul") for u in t.get(op) or []) \
        or any(_reads_measure(t[op]) for op in ("neg", "abs") if op in t)


def _literals(t, whole_side: bool, out: list) -> None:
    """Each literal with whether it is a whole side of a comparison; each operator over literals alone."""
    if not isinstance(t, dict):
        return
    if "lit" in t:
        out.append((t, whole_side)); return
    subs = [u for op in ("add", "sub", "mul") for u in t.get(op) or []] + [t[op] for op in ("neg", "abs") if op in t]
    if subs and not _reads_measure(t):
        out.append(({"arith": t}, False))
    for u in subs:
        _literals(u, False, out)


def _figures(rec: dict) -> set[tuple[str, Fraction]]:
    """The figures the property's quoted law words state, in Core's units."""
    from ..model import units
    words = " ".join([str(rec.get("span_quote", ""))] + [str(c.get("quote", "")) for c in rec.get("conditions") or [] if isinstance(c, dict)]
                     + [str(c.get("quote", "")) for c in rec.get("exceptions") or [] if isinstance(c, dict)])
    return {(f.core, f.value) for f in units.stated_figures(words)}


def static_check(rec: dict, ctx: dict) -> tuple[list[str], str | None]:
    """The property-language checks of one schema-valid candidate: (reasons it is refused, the
    `not_executable` class: `outside_language` or `count_or_size`, None when it passes). A
    candidate with `gaps` passes them and is marked `gap` by the caller."""
    from ..model import units
    reasons: list[str] = []
    lim = limits()["bytes"]
    for i, b in enumerate(rec.get("binders") or []):
        if compact_bytes(b.get("cls")) > lim["binder_class"]:
            reasons.append(f"count_or_size_refused: binders[{i}].cls is {compact_bytes(b.get('cls'))} bytes, beyond {lim['binder_class']}")
    if compact_bytes(rec.get("antecedent")) > lim["antecedent"]:
        reasons.append(f"count_or_size_refused: the antecedent is {compact_bytes(rec.get('antecedent'))} bytes, beyond {lim['antecedent']}")
    if reasons:
        return reasons, "count_or_size"
    grammar = [f"binders[{i}].cls{e}" for i, b in enumerate(rec.get("binders") or []) for e in errors("formula", b.get("cls"))]
    grammar += [f"antecedent{e}" for e in errors("formula", rec.get("antecedent"))]
    if grammar:
        return [f"outside_language: {e}" for e in grammar[:6]], "outside_language"
    names = [b.get("name") for b in rec.get("binders") or []]
    acc = {"errors": [], "atoms": [], "measures": [], "cmps": []}
    if len(set(names)) != len(names):
        acc["errors"].append("two binders share a name")
    subjects = [b for b in rec.get("binders") or [] if b.get("subject")]
    if len(subjects) > 1:
        acc["errors"].append("more than one binder is marked the subject")
    for b in rec.get("binders") or []:
        _walk_formula(b.get("cls"), frozenset(names), acc)
    cls_reads = (list(acc["atoms"]), list(acc["measures"]))
    acc["atoms"], acc["measures"] = [], []
    _walk_formula(rec.get("antecedent"), frozenset(names), acc)
    for a in set(acc["atoms"]) | set(cls_reads[0]):
        if a not in ctx["atoms"]:
            acc["errors"].append(f"`{a}` is not an atom of the table of atoms")
    for m in set(acc["measures"]) | set(cls_reads[1]):
        if m not in ctx["measures"]:
            acc["errors"].append(f"`{m}` is not a measure of the table of measured atoms")
    figures = _figures(rec)
    for c in acc["cmps"]:
        sides = (c.get("lhs"), c.get("rhs"))
        if not any(_reads_measure(s) for s in sides):
            acc["errors"].append("a comparison none of whose sides reads a measure")
        dims = [_dims(s, ctx["measures"], acc["errors"]) for s in sides]
        if None not in dims and dims[0] != dims[1]:
            acc["errors"].append("the two sides of a comparison have different units")
        for s in sides:
            ok, fr = _frames(s)
            if not ok:
                acc["errors"].append("a coordinate, direction or vector component is fixed")
            users = {f for f in fr if isinstance(f, tuple)}
            if len(users) > 1 or (users and "world" in fr):
                acc["errors"].append("components of different frames")
            lits: list = []
            _literals(s, True, lits)
            for lit, whole in lits:
                if "arith" in lit:
                    acc["errors"].append("arithmetic over literals alone")
                    continue
                v = Fraction(lit["lit"]["num"], lit["lit"]["den"])
                if v == 0:
                    if not whole:
                        acc["errors"].append("a literal 0 inside a term (0 serves only as a whole side of a comparison)")
                    continue
                core = units.core_of_tag(lit.get("unit"))
                if core is None or (core, v) not in figures:
                    acc["errors"].append(f"the literal {v} {lit.get('unit')} is not a figure the property's quoted words state")
    read = {ctx["atoms"].get(a) for a in acc["atoms"]} | {(ctx["measures"].get(m) or (None,))[0] for m in acc["measures"]}
    read_cls = {ctx["atoms"].get(a) for a in cls_reads[0]} | {(ctx["measures"].get(m) or (None,))[0] for m in cls_reads[1]}
    read.discard(None); read_cls.discard(None)
    listed = set(rec.get("observations") or [])
    if read - listed:
        acc["errors"].append(f"observations omit atoms the antecedent reads: {sorted(read - listed)}")
    if listed - read - read_cls:
        acc["errors"].append(f"observations list atoms neither the antecedent nor a binder class reads: {sorted(listed - read - read_cls)}")
    if acc["errors"]:
        return [f"outside_language: {e}" for e in dict.fromkeys(acc["errors"])], "outside_language"
    return [], None


# -- the gate -------------------------------------------------------------------------------------------

def _diag_candidates(draft, ctx) -> list[dict]:
    """Per-candidate checks of an answer that is invalid as a whole: diagnostics only."""
    out = []
    for i, c in enumerate((draft or {}).get("candidates") or [] if isinstance(draft, dict) else []):
        if not isinstance(c, dict):
            out.append({"index": i, "reasons": ["not an object"]}); continue
        errs = errors("draft", c, "/$defs/candidate")
        if not errs:
            errs, _ = static_check(c, ctx)
        out.append({"index": i, "id": c.get("id"), "reasons": errs[:6]})
    return out


def gate_draft(draft: dict, ctx: dict, rnd: int, prior: dict | None = None, withdrawn: frozenset = frozenset()) -> dict:
    """The static checks of one schema-valid draft (G2–G9, G14). Returns the clauses (each with its
    `clause_key`, or `refused`), and every candidate with its static result."""
    law = ctx["law_text"]
    ids = [c["id"] for c in draft["clauses"]]
    clauses = []
    for c in draft["clauses"]:
        reasons = []
        if ids.count(c["id"]) > 1:
            reasons.append(f"the clause id {c['id']} is given more than once")
        if ELLIPSIS.search(c["quote"]):
            reasons.append("its quote has an ellipsis")
        found = spans(law, c["quote"])
        occ = c.get("occurrence")
        if not found:
            reasons.append("its quote is not words of the law")
        elif len(found) > 1 and occ is None:
            reasons.append(f"its quote occurs {len(found)} times and no occurrence is given")
        elif occ is not None and occ > len(found):
            reasons.append(f"its occurrence {occ} does not exist ({len(found)} found)")
        n = occ or 1
        clauses.append({**c, "occurrence": n, "span": found[n - 1] if found and n <= len(found) else None,
                        "clause_key": clause_key(law, c["quote"], n, "author") if found and n <= len(found) else None,
                        "refused": reasons})
    keys = [c["clause_key"] for c in clauses if c["clause_key"]]
    for c in clauses:
        if c["clause_key"] and keys.count(c["clause_key"]) > 1:
            c["refused"].append("another clause quotes the same words at the same occurrence")
    by_id = {c["id"]: c for c in clauses if ids.count(c["id"]) == 1}
    cids = [k["id"] for k in draft["candidates"]]
    per_clause: dict[str, int] = {}
    cap = limits()["per_clause_candidates"]
    out = []
    prior_keys = {k["candidate"]["id"]: k.get("clause_key") for k in (prior or {}).get("candidates", [])}
    for k in draft["candidates"]:
        reasons, ne = [], None
        if cids.count(k["id"]) > 1:
            reasons.append(f"the property id {k['id']} is given more than once")
        cl = by_id.get(k["clause"])
        if cl is None:
            reasons.append(f"its clause {k['clause']} is not a clause of the answer")
        elif cl["refused"]:
            reasons.append(f"its clause {k['clause']} is refused: {'; '.join(cl['refused'])}")
        elif not any(cl["span"][0] <= s and e <= cl["span"][1] for s, e in spans(law, k["span_quote"])):
            reasons.append("its span_quote does not lie inside its clause's words")
        if k["category"] == "must_detect" and any(x.get("use") != "excluded" for x in k["exceptions"]):
            reasons.append("an exception of a must_detect property is not excluded")
        for part in ("conditions", "exceptions"):
            for x in k[part]:
                if ELLIPSIS.search(x["quote"]):
                    reasons.append(f"a {part[:-1]} quote has an ellipsis")
                elif not _quotable(x["quote"], ctx):
                    reasons.append(f"the {part[:-1]} quote {x['quote'][:60]!r} is in neither the law, a definition shown nor the conventions")
        if ELLIPSIS.search(k["span_quote"]):
            reasons.append("its span_quote has an ellipsis")
        key = cl["clause_key"] if cl and not cl["refused"] else None
        ident = identity(k)
        if rnd == 2 and k["id"] in prior_keys and prior_keys[k["id"]] is not None and key != prior_keys[k["id"]]:
            reasons.append("a property kept from round one changed its clause")
        if ident in withdrawn:
            reasons.append("withdrawn: the operator withdrew a property of this identity")
        if not reasons:
            lang, ne = static_check(k, ctx)
            reasons += lang
        if not reasons and k["gaps"]:
            ne = "gap"
        if not reasons and ne is None:
            per_clause[k["clause"]] = per_clause.get(k["clause"], 0) + 1
            if per_clause[k["clause"]] > cap:
                reasons.append(f"count_or_size_refused: more than {cap} candidates of clause {k['clause']} pass the static checks")
                ne = "count_or_size"
        out.append({"candidate": k, "clause_key": key, "identity": ident, "antecedent_sha": antecedent_sha(k),
                    "static_ok": not reasons, "reasons": reasons, "not_executable": ne})
    return {"round": rnd, "clauses": clauses, "candidates": out}


def _abstraction_ok(a: dict | None, ctx: dict) -> bool:
    return bool(isinstance(a, dict) and str(a.get("section", "")).strip() and spans(ctx["conventions"], a.get("quote", "")))


def _rated(quote: str, ratings: list[dict]) -> list[dict]:
    q = norm(quote)
    return [r for r in ratings if norm(r["condition_quote"]) and (q in norm(r["condition_quote"]) or norm(r["condition_quote"]) in q)]


def _resolves(path, ante) -> bool:
    if not isinstance(path, str) or not path.strip():
        return False
    toks = [t for t in re.split(r"[./\[\]]+", path.strip()) if t]
    if toks and toks[0] == "antecedent":
        toks = toks[1:]
    node = ante
    for t in toks:
        if isinstance(node, list) and t.isdigit() and int(t) < len(node):
            node = node[int(t)]
        elif isinstance(node, dict) and t in node:
            node = node[t]
        else:
            return False
    return True


def gate_screen(d: dict, screen: dict, ctx: dict) -> dict:
    """The adoption of each statically passed candidate by the screen (G10–G13, G15, G16)."""
    law = ctx["law_text"]
    shown = [c for c in d["candidates"] if c["static_ok"] and c["not_executable"] is None]
    items: dict[str, list] = {}
    for it in screen["items"]:
        items.setdefault(it["id"], []).append(it)
    unc = screen["uncovered_situations"]
    for c in d["candidates"]:
        c["screen"], c["adopted"], c["adoption_reasons"] = None, False, []
    for c in shown:
        k, got = c["candidate"], items.get(c["candidate"]["id"], [])
        if len(got) != 1:
            c["adoption_reasons"].append("the screen gave no item for it" if not got else "the screen gave it more than one item")
            continue
        it = got[0]
        c["screen"] = it
        why = []
        for r in it["conditions"]:
            if r["rating"] == "minor_deviation" and not _abstraction_ok(r.get("approved_abstraction"), ctx):
                why.append(f"a minor deviation quotes no approved abstraction of the conventions ({r['condition_quote'][:60]!r})")
            elif r["rating"] not in ("full_match", "minor_deviation"):
                why.append(f"{r['rating']} on {r['condition_quote'][:60]!r}: {r['reason'][:200]}")
            if r["kind"] != "conclusion" and not _resolves(r.get("antecedent_path"), k["antecedent"]):
                why.append(f"the antecedent path {r.get('antecedent_path')!r} of {r['condition_quote'][:60]!r} does not resolve")
            for t in r["terms"]:
                if t["status"] != "grounded":
                    why.append(f"the term {t['term'][:40]!r} is {t['status']}")
        if it["conclusion_ok"] != "yes":
            why.append(f"conclusion_ok is {it['conclusion_ok']}")
        for x in k["conditions"]:
            if not _rated(x["quote"], it["conditions"]):
                why.append(f"the condition {x['quote'][:60]!r} is not rated")
        for x in k["exceptions"]:
            rs = [r for r in _rated(x["quote"], it["conditions"]) if r["kind"] == "exception"]
            if not rs:
                why.append(f"the exception {x['quote'][:60]!r} is not rated")
            elif any(r.get("exception_use") != x["use"] for r in rs):
                why.append(f"the exception {x['quote'][:60]!r} is rated as {rs[0].get('exception_use')}, the property uses it as {x['use']}")
        mine = spans(law, k["span_quote"])
        for u in unc:
            if u.get("clause") == k["clause"] and u.get("category") == k["category"]:
                theirs = spans(law, u["quote"])
                overlap = any(a < f and e < b for a, b in mine for e, f in theirs) if mine and theirs else \
                    (norm(u["quote"]) in norm(k["span_quote"]) or norm(k["span_quote"]) in norm(u["quote"]))
                if overlap:
                    why.append(f"it overlaps a situation the screen lists as uncovered ({u['quote'][:60]!r})")
        c["adopted"], c["adoption_reasons"] = not why, why
    # clause × category assessments (G11) and confirmed exemptions (G13)
    live = [c for c in d["clauses"] if not c["refused"]]
    count: dict[tuple, list] = {}
    for a in screen["clause_assessments"]:
        count.setdefault((a["clause"], a["category"]), []).append(a)
    assessments, holes = [], []
    for c in live:
        for cat in CATEGORIES:
            wrote = [k for k in d["candidates"] if k["candidate"]["clause"] == c["id"] and k["candidate"]["category"] == cat]
            reason = [n for n in c.get("no_property") or [] if n["category"] == cat]
            got = count.get((c["id"], cat), [])
            a = got[0] if len(got) == 1 else None
            consistent = a is not None and ((a["assessment"] == "properties_given" and bool(wrote))
                                            or (a["assessment"] != "properties_given" and bool(reason) and not wrote))
            if reason and wrote:
                holes.append({"kind": "rejected", "clause": c["id"], "clause_key": c["clause_key"], "category": cat,
                              "detail": "the author gave both properties and a reason for none: the reason is void"})
            confirmed = bool(consistent and a["assessment"] == "reason_confirmed" and reason
                             and any(c["span"][0] <= s and e <= c["span"][1] for s, e in spans(law, a["quote"])))
            if reason and not wrote and not confirmed:
                holes.append({"kind": "exemption_not_confirmed", "clause": c["id"], "clause_key": c["clause_key"], "category": cat,
                              "detail": "the screen did not confirm the author's reason" + ("" if a else " (no single assessment)")})
            if confirmed:
                assessments.append({"clause": c["id"], "category": cat, "agrees_no_property": True, "basis": a["quote"]})
            assessments_given = a["assessment"] if a else None
            c.setdefault("assessed", {})[cat] = {"given": assessments_given, "consistent": consistent, "confirmed": confirmed,
                                                 "count": len(got)}
    missed = []
    for m in screen["missed_obligations"]:
        located = bool(spans(law, m["quote"]))
        missed.append({**m, "located": located})
        holes.append({"kind": "missed_obligation", "clause": None, "clause_key": None, "category": None,
                      "detail": ("" if located else "(not words of the law) ") + m["quote"]})
    for u in unc:
        holes.append({"kind": "uncovered_situation", "clause": u.get("clause"), "category": u.get("category"),
                      "clause_key": next((c["clause_key"] for c in live if c["id"] == u.get("clause")), None),
                      "detail": f"{u['situation']} — {u['quote']}"})
    return {"assessments": assessments, "holes": holes, "missed": missed}


def _signals(d: dict, s: dict | None, screen: dict | None, ctx: dict) -> dict:
    """The zero-adoption signal groups E, M, N, U, read mechanically from the last round."""
    E, M, U = [], [], []
    for c in d["candidates"]:
        if c["candidate"]["gaps"]:
            E.append(f"{c['candidate']['id']}: the author marked a gap")
        if any(r.startswith(("outside_language", "count_or_size_refused")) for r in c["reasons"]):
            E.append(f"{c['candidate']['id']}: refused by the property language or a bound")
        elif c["reasons"]:
            E.append(f"{c['candidate']['id']}: refused by a format check")
    if screen is None:
        U.append("the screen's answer is missing or invalid")
        return {"E": E, "M": M, "N": False, "U": U}
    for it in screen["items"]:
        if it["item_cause"] == "not_expressible":
            E.append(f"{it['id']}: not expressible")
        if it["item_cause"] == "misreads_words":
            M.append(f"{it['id']}: misreads the words")
        if it["item_cause"] == "cannot_tell" or it["conclusion_ok"] == "cannot_tell":
            U.append(f"{it['id']}: the screen cannot tell")
        if it["conclusion_ok"] == "no":
            M.append(f"{it['id']}: the conclusion does not hold")
        for r in it["conditions"]:
            if any(t["status"] == "gap" for t in r["terms"]):
                E.append(f"{it['id']}: a term is a gap")
            if r["rating"] == "major_deviation" or (r["rating"] == "minor_deviation" and not _abstraction_ok(r.get("approved_abstraction"), ctx)):
                M.append(f"{it['id']}: {r['rating']}")
            if r["rating"] == "cannot_rate":
                U.append(f"{it['id']}: cannot rate")
        majors = any(r["rating"] == "major_deviation" for r in it["conditions"])
        consistent = {"adoptable": not majors and it["conclusion_ok"] == "yes"
                      and all(r["rating"] != "minor_deviation" or _abstraction_ok(r.get("approved_abstraction"), ctx) for r in it["conditions"]),
                      "misreads_words": majors or it["conclusion_ok"] == "no",
                      "not_expressible": not majors and it["conclusion_ok"] != "no", "cannot_tell": True}[it["item_cause"]]
        if not consistent:
            U.append(f"{it['id']}: item_cause {it['item_cause']} disagrees with its ratings")
    if any(a["assessment"] == "reason_rejected" for a in screen["clause_assessments"]):
        M.append("a reason for no property was rejected")
    if screen["missed_obligations"]:
        M.append("the clauses miss obligations")
    if any("overlaps a situation the screen lists as uncovered" in r for c in d["candidates"] for r in c.get("adoption_reasons", [])):
        M.append("a candidate overlaps an uncovered situation")
    lb = screen["law_behaviour"]
    wrote = bool(d["candidates"])
    if lb["assessment"] == "no_checkable_behaviour" and wrote:
        M.append("the screen finds no checkable behaviour, the author wrote properties")
    if lb["assessment"] == "checkable" and not wrote:
        M.append("the screen finds checkable behaviour, the author wrote none")
    if lb["assessment"] == "cannot_tell":
        U.append("the screen cannot tell whether the law decides checkable conduct")
    if lb["assessment"] == "no_checkable_behaviour" and not spans(d["law_text"], lb.get("quote", "")):
        U.append("the screen's law_behaviour quote is not words of the law")
    live = [c for c in d["clauses"] if not c["refused"]]
    N = (lb["assessment"] == "no_checkable_behaviour" and lb.get("kind") != "other" and bool(spans(d["law_text"], lb.get("quote", "")))
         and bool(lb["reason"].strip()) and not wrote and bool(live) and len(live) == len(d["clauses"])
         and all({n["category"] for n in c.get("no_property") or []} == set(CATEGORIES) for c in live)
         and all(c.get("assessed", {}).get(cat, {}).get("confirmed") for c in live for cat in CATEGORIES))
    return {"E": sorted(set(E)), "M": sorted(set(M)), "N": N, "U": sorted(set(U))}


def zero_cause(sig: dict, screen: dict | None) -> tuple[str, list[str]]:
    """The cause of a generation with no adopted property, and the reason codes the stage reads."""
    E, M, U, N = bool(sig["E"]), bool(sig["M"]), bool(sig["U"]), sig["N"]
    if N and not (E or M or U):
        return "no_checkable_behaviour", ["no_checkable_behaviour"]
    if (E and M) or (N and (E or M)):
        return "mixed", ["reviewer_problem", "meaning_disagreement"]
    if M and not (E or U):
        return "meaning_dispute", ["meaning_disagreement"]
    if E and not (M or U) and screen is not None and screen["law_behaviour"]["assessment"] == "checkable":
        return "reviewer_side", ["reviewer_problem"]
    return "unclear", ["unclear"]


def zero_causes(d: dict, screen: dict | None) -> list[str]:
    """The limits of the review a generation that adopted nothing shows, in the review stage's
    vocabulary of causes that are never the law's (`behaviour_review.NOT_THE_LAWS`): `missing_atom`
    (the author marked a gap, or the screen a term no atom carries), `not_expressible` (the screen
    found a candidate not expressible, or the property language or a bound refused one) and
    `cannot_tell` (the screen could not tell, could not rate, or could not tell whether the law decides
    checkable conduct)."""
    out = set()
    for c in d["candidates"]:
        if c["candidate"]["gaps"]:
            out.add("missing_atom")
        if any(r.startswith(("outside_language", "count_or_size_refused")) for r in c["reasons"]):
            out.add("not_expressible")
    for it in (screen or {}).get("items", []):
        if it["item_cause"] == "not_expressible":
            out.add("not_expressible")
        if it["item_cause"] == "cannot_tell" or it["conclusion_ok"] == "cannot_tell" or any(r["rating"] == "cannot_rate" for r in it["conditions"]):
            out.add("cannot_tell")
        if any(t["status"] == "gap" for r in it["conditions"] for t in r["terms"]):
            out.add("missing_atom")
    if screen is not None and screen["law_behaviour"]["assessment"] == "cannot_tell":
        out.add("cannot_tell")
    return sorted(out)


def adopt_answer(rounds: list[dict], ctx: dict, withdrawn: frozenset = frozenset()) -> dict:
    """One generation's property set from its rounds (each `{"draft", "screen"}`, round one first; a
    round's screen may be missing only when a later round follows). Returns the set's fields: `state`
    (`ok`, or `failed` when any answer is invalid as a whole: nothing then is published), `records`
    (the adopted candidates with `clause_key`, `identity` and `antecedent_sha`), `candidates` (the id of
    every candidate the last round wrote) and `rejected` (each of them not adopted, with its reasons),
    `clauses`, `uncovered`, `screen_assessments`, `holes`, `adoption` (one entry per candidate of the
    last round, the bp_record fields the set knows), `zero_adopted` (its `cause`, reason `codes`,
    `signals` and `causes`, `zero_causes`), `reasons` and, for an invalid answer, `diagnostics`. A
    generation has one or two rounds; any other count is refused like an invalid answer."""
    startup_check()
    if not rounds or len(rounds) > 2:
        return {"state": "failed", "records": [], "clauses": [], "uncovered": [], "adoption": [], "diagnostics": [],
                "reasons": [f"a generation has one or two rounds, not {len(rounds)}"]}
    invalid, diagnostics = [], []
    for i, r in enumerate(rounds, 1):
        for kind in ("draft", "screen"):
            ans = r.get(kind)
            if ans is None and kind == "screen" and i < len(rounds):
                continue
            errs = answer_errors(kind, ans)
            if errs:
                invalid += [f"round {i} {kind}: {e}" for e in errs[:8]]
                if kind == "draft":
                    diagnostics.append({"round": i, "candidates": _diag_candidates(ans, ctx)})
    if invalid:
        return {"state": "failed", "records": [], "clauses": [], "uncovered": [], "adoption": [],
                "reasons": ["an answer is invalid as a whole: no property set is published"] + invalid, "diagnostics": diagnostics}
    prior = None
    for i, r in enumerate(rounds, 1):
        d = gate_draft(r["draft"], ctx, i, prior, withdrawn)
        d["law_text"] = ctx["law_text"]
        prior = d
    last, screen = prior, rounds[-1]["screen"]
    s = gate_screen(last, screen, ctx)
    rnd = len(rounds)
    first_ids = {c["candidate"]["id"]: c for c in gate_draft(rounds[0]["draft"], ctx, 1, None, withdrawn)["candidates"]} if rnd > 1 else {}
    adoption, records, holes = [], [], list(s["holes"])
    for c in last["candidates"]:
        k = c["candidate"]
        reasons = c["reasons"] + c.get("adoption_reasons", [])
        if c["not_executable"] == "gap":
            reasons = reasons + ["expression_gap: the author marked words no atom carries"]
        adopted = c.get("adopted", False) and c["not_executable"] is None
        it = c.get("screen")
        adoption.append({"property": k["id"], "clause_key": c["clause_key"], "round": rnd, "candidate": k,
                         "candidate_sha": sha(k), "antecedent_sha": c["antecedent_sha"], "identity": c["identity"],
                         "static": {"ok": c["static_ok"], "reasons": c["reasons"]},
                         "screen": None if it is None else {"item_sha": sha(it), "conclusion_ok": it["conclusion_ok"],
                                                            "ratings": [{"condition_quote": r["condition_quote"], "kind": r["kind"],
                                                                         "rating": r["rating"], "exception_use": r.get("exception_use")}
                                                                        for r in it["conditions"]]},
                         "adoption": {"adopted": adopted, "reasons": reasons, "state": "adopted" if adopted else "rejected"},
                         "executable": c["not_executable"] is None and c["static_ok"], "not_executable": c["not_executable"]})
        if adopted:
            records.append({**k, "clause_key": c["clause_key"], "identity": c["identity"], "antecedent_sha": c["antecedent_sha"]})
        else:
            kind = ("count_or_size_refused" if c["not_executable"] == "count_or_size" else
                    "expression_gap" if c["not_executable"] == "gap" or any(t["status"] == "gap" for r in (it or {}).get("conditions", []) for t in r["terms"])
                    else "rejected")
            holes.append({"kind": kind, "clause": k["clause"], "clause_key": c["clause_key"], "category": k["category"],
                          "antecedent_sha": c["antecedent_sha"], "detail": f"{k['id']}: " + "; ".join(reasons)[:600]})
    kept = {c["candidate"]["id"] for c in last["candidates"]}
    for pid, c in first_ids.items():
        if pid not in kept:
            adoption.append({"property": pid, "clause_key": c["clause_key"], "round": 1, "candidate": c["candidate"],
                             "candidate_sha": sha(c["candidate"]), "antecedent_sha": c["antecedent_sha"], "identity": c["identity"],
                             "static": {"ok": c["static_ok"], "reasons": c["reasons"]}, "screen": None,
                             "adoption": {"adopted": False, "reasons": ["the author did not submit it again in round two"],
                                          "state": "dropped_in_round_two"},
                             "executable": False, "not_executable": c["not_executable"]})
    clauses = [{"id": c["id"], "quote": c["quote"], "occurrence": c["occurrence"], "clause_key": c["clause_key"],
                "no_property": [n for n in c.get("no_property") or []
                                if not any(k["candidate"]["clause"] == c["id"] and k["candidate"]["category"] == n["category"] for k in last["candidates"])],
                **({"refused": c["refused"]} if c["refused"] else {})}
               for c in last["clauses"]]
    for c in clauses:
        if c.get("refused"):
            holes.append({"kind": "rejected", "clause": c["id"], "clause_key": None, "category": None,
                          "detail": f"clause {c['id']} refused: {'; '.join(c['refused'])}"})
    # the screen's uncovered obligations and situations become clauses of their own for coverage: never covered
    uncovered = [{"clause": None, "kind": "missed_obligation", "quote": m["quote"], "located": m["located"]} for m in s["missed"]] \
        + [{"clause": None, "kind": "uncovered_situation", "within": u.get("clause"), "category": u.get("category"),
            "situation": u["situation"], "quote": u["quote"]} for u in screen["uncovered_situations"]] \
        + [{"clause": None, "kind": "refused_clause", "within": c["id"], "quote": c["quote"]} for c in clauses if c.get("refused")]
    out = {"state": "ok", "records": records, "candidates": [c["candidate"]["id"] for c in last["candidates"]],
           "rejected": [{"id": a["property"], "reasons": a["adoption"]["reasons"]} for a in adoption
                        if a["round"] == rnd and not a["adoption"]["adopted"]],
           "clauses": [c for c in clauses if not c.get("refused")], "uncovered": uncovered,
           "screen_assessments": s["assessments"], "holes": holes, "adoption": adoption,
           "law_behaviour": screen["law_behaviour"], "reasons": []}
    if not records:
        sig = _signals(last, s, screen, ctx)
        cause, codes = zero_cause(sig, screen)
        lb = screen["law_behaviour"]
        out["zero_adopted"] = {"cause": cause, "codes": codes, "signals": sig, "causes": zero_causes(last, screen),
                               "screen_confirms": cause == "no_checkable_behaviour",
                               "basis": lb.get("quote", "") if cause == "no_checkable_behaviour" else "; ".join((sig["M"] + sig["E"] + sig["U"])[:4]),
                               "kind": lb.get("kind")}
    return out


def record_rows(law: str, pset: dict, set_id: str, generation_id: str) -> list[dict]:
    """The bp_record rows of a stored set (each one schema-valid)."""
    return [{"schema": "bp_record/1", "law": law, "generation_id": generation_id, "set_id": set_id, **a} for a in pset.get("adoption") or []]


def active_set_record(law: str, active: dict, active_id: str) -> dict:
    """A law's active set as a bp_active_set row."""
    return {"schema": "bp_active_set/1", "law": law, "active_set_id": active_id, "set_id": active["set_id"],
            "supersedes": active.get("supersedes"), "version": int(active.get("version", 1)),
            "withdrawals": list(active.get("withdrawals") or [])}


def gate_digest() -> str:
    """The digest of everything that decides an adoption: the schema files, the limits, the two
    templates, the property language and this gate's source. A property set's spec key and a
    review implementation's digest bind it, so a change to any of them makes earlier sets another
    implementation's."""
    from ..store import paths
    parts = {f: (SCHEMA_DIR / f).read_bytes() for f in [*FILES.values(), LIMITS_FILE]}
    parts |= {t: (paths.PROMPTS / t).read_bytes() for t in [*TEMPLATES, PROPERTY_LANGUAGE]}
    parts["review_schema.py"] = Path(__file__).read_bytes()
    return hashlib.sha256(b"".join(k.encode() + b"\0" + hashlib.sha256(v).digest() for k, v in sorted(parts.items()))).hexdigest()
