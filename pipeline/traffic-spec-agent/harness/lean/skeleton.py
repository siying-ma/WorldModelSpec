"""Rule and witness skeletons, generated from a blueprint node.

The skeleton carries everything the gate's DECLARATION_MISMATCH step compares (id, laws, binders,
assumptions, intentions, facts, operationalizations, residues, surrogate, abstractions), the node's parameters as `Term` values,
and the four scenarios with their expected verdicts and masked atoms; the formulas and the scenes
are left to the coding session, marked `TODO`. Both files build as written, so the session's first
gate run measures its own work rather than a spelling.
"""
from __future__ import annotations
import re
from ..model import nodeid
from ..model.blueprint import Node, ConceptRecord, SCENARIOS, standard_scenarios, CONCEPT_SCENARIOS, concepts_of, normalize_verdict
from ..model.units import FACTORS, lean_unit

VERDICT_LEAN = {"violated": ".violated", "compliant": ".compliant", "not_applicable": ".notApplicable", "unknown": "(.unknown [])"}


def _s(text: object) -> str:
    """A Lean string literal of the text exactly: an id or a name is compared as written."""
    t = str(text if text is not None else "")
    for a, b in (("\\", "\\\\"), ('"', '\\"'), ("\n", "\\n"), ("\t", "\\t"), ("\r", "\\r")):
        t = t.replace(a, b)
    return '"' + t + '"'


def _prose(text: object) -> str:
    """A Lean string literal of prose (a standard, a convention, a residue's why, a contract), its
    whitespace collapsed: there it carries no meaning, and the gate compares such fields so."""
    return _s(" ".join(str(text if text is not None else "").split()))


def _ident(name: str) -> str:
    """A Lean identifier from a parameter or binder name (`p.ttc_bound` → `pTtcBound`)."""
    parts = re.split(r"[^A-Za-z0-9]+", name.strip())
    parts = [p for p in parts if p]
    if not parts:
        return "x"
    head = parts[0]
    tail = "".join(p[:1].upper() + p[1:] for p in parts[1:])
    ident = head + tail
    if not re.match(r"[A-Za-z_]", ident):
        ident = "p" + ident
    return ident


def _lean_list(items: list[str]) -> str:
    return "[" + ", ".join(items) + "]"


def _span_lines(node: Node, roles: set[str], exception_kind: str | None = None) -> list[str]:
    """One line per span of `roles` and per exception span of the recorded `exception_kind`: a
    `meets_duty` exception is written in the obligation beside the duty, a `lifts_duty` one in the
    applicability, negated."""
    def kept(s: dict) -> bool:
        return s.get("role") in roles or (exception_kind is not None and s.get("role") == "exception"
                                          and node.exception_kind(s.get("id")) == exception_kind)
    def role(s: dict) -> str:
        if s.get("role") != "exception":
            return str(s.get("role"))
        return "exception, meets_duty: beside the duty" if exception_kind == "meets_duty" else "exception, lifts_duty: negated"
    return [f"{s['id']} ({role(s)}): {' '.join(str(s.get('text', '')).split())}"
            for s in node.get("segmentation", []) if kept(s)]


def rule_skeleton(node: Node) -> str:
    ns = nodeid.rule_namespace(node.id)
    binders = node.get("binders", [])
    params = node.params()
    ops = node.get("operationalizations", [])
    asms = node.get("assumptions", [])
    intents = list(dict.fromkeys(a.get("id") for a in node.get("intentions", [])))
    facts = list(dict.fromkeys(a.get("id") for a in node.get("facts", [])))
    residues = node.get("residues", [])
    surrogate = any(o.get("surrogate") for o in ops)
    elements = node.get("elements", [])
    comps = node.dependencies()
    borrowed = node.definition_references()

    head = ["/-", f"  {node.id} — {', '.join(node.get('law_refs', []))}", "",
            "  THE READING (the blueprint's; the coding session records here, per span, how each element,",
            "  operationalization and composition below is written, and every choice the text did not dictate).", "",
            "  Spans:"]
    for s in node.get("segmentation", []):
        head.append(f"    {s['id']} ({s.get('role')}): {' '.join(str(s.get('text', '')).split())}")
    if elements:
        head += ["", "  Elements (span → atoms, derived):"]
        for e in elements:
            head.append(f"    {e.get('span')}: atoms {e.get('atoms', [])}, derived {e.get('derived', [])}"
                        + (f", borrowing {e.get('source_spans')}" if e.get("source_spans") else ""))
    if comps:
        head += ["", "  Compositions (span → node, as, map):"]
        for c in comps:
            head.append(f"    {c.get('span')}: {c.get('rule')} as {c.get('as')} map {c.get('map')}" + (f" scopes {c.get('scopes')}" if c.get("scopes") else ""))
    if borrowed:
        head += ["", "  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):"]
        for c in borrowed:
            head.append(f"    {c.get('span')}: {c.get('source')}: {' '.join(str(c.get('quote', '')).split())}")
    if node.literals():
        head += ["", "  Literals the text states (each written through its Units constructor):"]
        for l in node.literals():
            head.append(f"    {l.get('span')}: {l.get('value')} {l.get('unit')} — {l.get('text')}")
    head += ["", "  No magnitude below is this file's own: parameters name the reading, literals are the text's.", "-/"]

    out = head + ["import TrafficSpec.Core.Language.Rule", "", f"namespace {ns}", ""]
    out.append("/-- The binders, as arguments (order and names are the node's). -/")
    for b in binders:
        out.append(f"def {_ident('v_' + b['name'])} : Arg := .var {_s(b['name'])}")
    out.append("")
    if params:
        out.append("/-- The reading's parameters; no value of any of them lives in this file. -/")
        for p in params:
            out.append(f"def {_ident(p)} : Term := .param {_s(p)}")
        out.append("")
    out.append("def zeroMetres : Term := .lit Q.zero .metre")
    out.append("")
    out.append("-- TODO(code): class formulas, applicability and obligation — from the node's elements,")
    out.append("-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.")
    out.append("")
    for b in binders:
        out.append(f"/-- Class of `{b['name']}`: {', '.join(b.get('class_elements', []))} -/")
        out.append(f"def {_ident('cls_' + b['name'])} : Formula := .tt  -- TODO")
    out.append("")
    app_spans = _span_lines(node, {"trigger", "condition"}, "lifts_duty")
    obl_spans = _span_lines(node, {"obligation", "standard"}, "meets_duty")
    out.append("/-- Applicability: " + ("; ".join(app_spans) if app_spans else "(no trigger/condition span)") + " -/")
    out.append("def applicability : Formula := .tt  -- TODO")
    out.append("")
    out.append("/-- Obligation: " + ("; ".join(obl_spans) if obl_spans else "(no obligation span)") + " -/")
    out.append("def obligation : Formula := .tt  -- TODO")
    out.append("")
    out.append("def rule : Rule :=")
    out.append(f"  {{ id := {_s(node.id)}")
    out.append(f"    laws := {_lean_list([_s(l) for l in node.get('law_refs', [])])}")
    if binders:
        blines = [f"{{ name := {_s(b['name'])}, cls := {_ident('cls_' + b['name'])} }}" for b in binders]
        out.append("    binders :=")
        out.append("      [ " + "\n      , ".join(blines) + " ]")
    else:
        out.append("    binders := []")
    out.append("    applicability := applicability")
    out.append("    obligation := obligation")
    out.append(f"    assumptions := {_lean_list([_s(a.get('id')) for a in asms])}")
    out.append(f"    intentions := {_lean_list([_s(i) for i in intents])}")
    out.append(f"    facts := {_lean_list([_s(i) for i in facts])}")
    if ops:
        olines = []
        for o in ops:
            olines.append("{ standard := " + _prose(o.get("standard", "")) +
                          "\n          concepts := " + _lean_list([_s(c) for c in sorted(concepts_of(o))]) +
                          "\n          params := " + _lean_list([_s(p) for p in o.get("params", [])]) +
                          "\n          convention := " + _prose(o.get("convention", "")) +
                          f"\n          surrogate := {'true' if o.get('surrogate') else 'false'} }}")
        out.append("    operationalizations :=")
        out.append("      [ " + "\n      , ".join(olines) + " ]")
    else:
        out.append("    operationalizations := []")
    out.append(f"    residues := {_lean_list([_prose(r.get('why', '')) for r in residues])}"
               "  -- the node's, verbatim; not yours to change")
    out.append("    narrowings := []  -- one { span := \"<span id>\", why := \"<why>\", kind := \"reading\" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated")
    out.append(f"    surrogate := {'true' if surrogate else 'false'}")
    out.append(f"    abstractions := {_lean_list([_s(a) for a in node.abstractions()])} }}"
               "  -- the record's approved abstractions: the rule is partial coverage where any is listed")
    out.append("")
    out.append(f"end {ns}")
    return "\n".join(out) + "\n"


def witness_skeleton(node: Node) -> str:
    ns = nodeid.witness_namespace(node.id)
    binders = [b["name"] for b in node.get("binders", [])]
    scen = {s.get("name"): s for s in node.get("scenarios", [])}
    grounding = ", ".join(f"({_s(b)}, {i + 1})" for i, b in enumerate(binders))
    out = ["/-", f"  Witnesses for {node.id}.", "",
           "  TODO(code): describe the geometry once built — the carriageway, the bodies, the instants; every",
           "  figure here is the witness's own and appears nowhere in the rule.", "-/",
           f"import {nodeid.rule_module(node.id)}", "import TrafficSpec.Core.Evidence.Builders", "",
           f"namespace {ns}", "", "open TrafficSpec", "",
           "def m (n : Int) : Q := Units.metres n", "def cm (n : Int) : Q := Units.centimetres n", "",
           f"-- Binders ↦ tracks: {', '.join(f'{b} ↦ {i + 1}' for i, b in enumerate(binders)) or '(no binders)'}", ""]
    std = standard_scenarios(node)
    names = list(std) + [x for x in scen if x and x not in std]   # every planned scenario, the standard ones first
    for name in names:
        s = scen.get(name, {})
        narrative = " ".join(str(s.get("narrative", "")).split())
        out.append(f"/-- `{name}` ({normalize_verdict(s.get('expected', SCENARIOS.get(name, '')))}): {narrative} -/")
        out.append(f"def {name}Trace : Trace :=")
        out.append("  Build.trace 3 0 (Units.seconds 1) fun _k t =>")
        out.append("    Build.scene t (some 1)")
        out.append("      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)")
        out.append("      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …")
        out.append("      [ ]  -- devices")
        out.append("")
    out.append("def witness (name : String) (τ : Trace) (expected : Verdict)")
    out.append("    (absent : List String := []) (boundary : String := \"\") : Scenario :=")
    out.append("  { name := name")
    out.append(f"    rule := {_s(node.id)}")
    out.append("    trace := τ")
    out.append("    reading := {}          -- ignored by the gate: the run's reading is substituted")
    out.append("    manifest := Build.manifest absent")
    out.append(f"    grounding := [{grounding}]")
    out.append("    expected := expected")
    out.append("    boundary := boundary }")
    out.append("")
    lines = []
    for name in names:
        s = scen.get(name, {})
        expected = VERDICT_LEAN[normalize_verdict(s.get("expected", std.get(name, "")))]
        masked = s.get("masked", []) if name == "blind" else []
        if isinstance(masked, str):
            masked = [masked]
        extra = f" {_lean_list([_s(a) for a in masked])}" if masked else ""
        if s.get("boundary"):
            extra += f" (boundary := {_s(' '.join(str(s['boundary']).split()))})"
        lines.append(f"witness {_s(name)} {name}Trace {expected}{extra}")
    out.append("def scenarios : List Scenario :=")
    out.append("  [ " + "\n  , ".join(lines) + " ]")
    out.append("")
    out.append(f"end {ns}")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------------------------
# Concept skeletons: the declarations the gate compares, the formals as `Arg`/`Term` values, one
# instance and the three scenarios; the body and the scenes are left to the session.
# ---------------------------------------------------------------------------------------------
def _punit(unit: str) -> str:
    return lean_unit(FACTORS[unit][0])


def _sort_lean(a: dict) -> str:
    s = a.get("sort")
    if s == "track":
        return ".track"
    if s == "region":
        return ".region"
    if s == "nat":
        return ".nat"
    return ".literal " + _lean_list([_s(v) for v in a.get("values", [])])


def _comment_text(text: object) -> str:
    """Text on one line inside a Lean block comment, with no comment delimiter of its own."""
    return " ".join(str(text).split()).replace("/-", "/ -").replace("-/", "- /")


def concept_skeleton(c: ConceptRecord, definition_text: str | None = None) -> str:
    """The concept file as the harness writes it. A concept bound to a posted definition is based on
    that definition: its contract is the record's reading of it, not its text; the posted text is
    shown apart from the contract; a text not given is marked abnormal in the header."""
    ns = nodeid.concept_namespace(c.id)
    head = ["/-", f"  {c.id} — {' '.join(str(c.get('contract', '')).split())}", ""]
    if c.get("definition"):
        head.append(f"  Based on the posted definition `{c.get('definition')}`: the contract above is this record's reading")
        head.append("  of it, not its text.")
        head.append("")
        if definition_text:
            head.append("  The posted text (the definition's words; the concept denotes its contract):")
            head.append(f"    {_comment_text(definition_text)}")
        else:
            head.append("  ABNORMAL: the posted text of this definition was not available when this file was written;")
            head.append("  a valid record names a definition of the run's corpus.")
        head.append("")
    head.append("  THE READING (the blueprint's; the session records here, per element, how the contract's words are")
    head.append("  written, and every choice the contract did not dictate).")
    head.append("")
    head.append("  Elements (contract words → atoms, concepts):")
    for e in c.elements():
        head.append(f"    {' '.join(str(e.get('span', '')).split())}: atoms {e.get('atoms', [])}, concepts {e.get('concepts', [])}")
    if c.literals():
        head.append("")
        head.append("  Literals the contract states (declared; written through a `Units` constructor):")
        for l in c.literals():
            head.append(f"    {l.get('value')} {l.get('unit')} — {l.get('why')}")
    head += ["", "  No magnitude below is this file's own: parameters are formals the caller fills.", "-/"]
    out = head + ["import TrafficSpec.Core.Language.Concept", "", f"namespace {ns}", ""]
    out.append("/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/")
    for a in c.args():
        out.append(f"def {_ident('a_' + a['name'])} : Arg := .var {_s(a['name'])}")
    if c.params():
        out.append("")
        out.append("/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/")
        for pr in c.params():
            out.append(f"def {_ident('p_' + pr['name'])} : Term := .param {_s(pr['name'])}")
    out.append("")
    if c.get("kind") == "quantity":
        out.append("-- TODO(code): the quantity, from the contract's elements, over the formals and claimed names only.")
        out.append("def body : Term := .lit Q.zero .count  -- TODO")
        body_ctor = ".quantity body"
    else:
        out.append("-- TODO(code): the formula, from the contract's elements, over the formals and claimed names only.")
        out.append("def body : Formula := .tt  -- TODO")
        body_ctor = ".formula body"
    out.append("")
    out.append("def concept : Concept :=")
    out.append(f"  {{ id := {_s(c.id)}")
    out.append(f"    contract := {_prose(c.get('contract', ''))}")
    out.append(f"    definition := {('some ' + _s(c.get('definition'))) if c.get('definition') else 'none'}")
    out.append("    args := " + _lean_list([f"({_s(a['name'])}, {_sort_lean(a)})" for a in c.args()]))
    out.append("    params := " + _lean_list([f"⟨{_s(pr['name'])}, {_punit(pr['unit'])}⟩" for pr in c.params()]))
    out.append(f"    body := {body_ctor}")
    out.append(f"    residues := {_lean_list([_prose(r.get('why', '')) for r in c.get('residues', [])])}"
               "  -- the record's, verbatim; not yours to change")
    out.append("    narrowings := []  -- one { span := \"<words of the contract>\", why := \"<why>\", kind := \"reading\" } per reading you chose that the contract leaves open, explained in the header")
    out.append(f"    supersedes := {('some ' + _s(c.get('supersedes'))) if c.get('supersedes') else 'none'} }}")
    out.append("")
    out.append(f"end {ns}")
    return "\n".join(out) + "\n"


def concept_witness_skeleton(c: ConceptRecord) -> str:
    ns = nodeid.concept_witness_namespace(c.id)
    tracks = [a["name"] for a in c.args() if a.get("sort") == "track"]
    lits = [a for a in c.args() if a.get("sort") == "literal"]
    nats = [a for a in c.args() if a.get("sort") == "nat"]
    grounding = ", ".join(f"({_s(n)}, {i + 1})" for i, n in enumerate(tracks))
    regions = [a["name"] for a in c.args() if a.get("sort") == "region"]
    region_ids = ", ".join(f"({_s(n)}, {100 + i})" for i, n in enumerate(regions))
    scen = {s.get("name"): s for s in c.get("scenarios", [])}
    inst_name = c.id + "@w"
    out = ["/-", f"  Witnesses for {c.id}.", "",
           "  TODO(code): describe the geometry once built — the bodies, the regions, the instants; every figure",
           "  here is the witness's own, including the values the instance gives the formal parameters.", "-/",
           f"import {nodeid.concept_module(c.id)}", "import TrafficSpec.Core.Evidence.Builders", "",
           f"namespace {ns}", "", "open TrafficSpec", "",
           "def m (n : Int) : Q := Units.metres n", "def cm (n : Int) : Q := Units.centimetres n", "",
           f"-- Formals ↦ tracks: {', '.join(f'{n} ↦ {i + 1}' for i, n in enumerate(tracks)) or '(no track formal)'}",
           f"-- Formals ↦ regions: {', '.join(f'{n} ↦ {100 + i}' for i, n in enumerate(regions)) or '(no region formal)'}"
           + ("  (TODO: each id a structure of every trace)" if regions else ""), "",
           "/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a",
           "    value through a `Units` constructor (TODO), a quantity concept given its expected bounds. -/",
           "def inst : Concept.Instance :=",
           f"  {{ name := {_s(inst_name)}",
           f"    concept := {_s(c.id)}",
           "    literals := " + _lean_list([f"({_s(a['name'])}, {_s((a.get('values') or [''])[0])})" for a in lits]) + ("  -- TODO choose" if lits else ""),
           "    nats := " + _lean_list([f"({_s(a['name'])}, 0)" for a in nats]) + ("  -- TODO choose" if nats else ""),
           "    params := " + _lean_list([f"({_s(pr['name'])}, .lit (Q.ofInt 0) {_punit(pr['unit'])})" for pr in c.params()]) + ("  -- TODO values" if c.params() else ""),
           "    bounds := " + ("some (.lit Q.zero .count, .lit Q.zero .count)  -- TODO the expected interval" if c.get("kind") == "quantity" else "none"),
           "  }",                                    # its own line: a comment above must never swallow the brace
           "",
           "def instances : List Concept.Instance := [inst]", ""]
    names = list(CONCEPT_SCENARIOS) + (["counterexample"] if c.get("supersedes") and c.get("counterexample") else [])
    for name in names:
        s = scen.get(name) if name != "counterexample" else (c.get("counterexample") or {})
        s = s or {}
        expected = normalize_verdict(s.get("expected", CONCEPT_SCENARIOS.get(name, "violated")))
        narrative = " ".join(str(s.get("narrative", "")).split())
        out.append(f"/-- `{name}` ({expected}): {narrative} -/")
        out.append(f"def {name}Trace : Trace :=")
        out.append("  Build.trace 3 0 (Units.seconds 1) fun _k t =>")
        out.append("    Build.scene t (some 1)")
        out.append("      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)")
        out.append("      [ ]  -- TODO structures")
        out.append("      [ ]  -- devices")
        out.append("")
    out.append("def witness (name : String) (τ : Trace) (expected : Verdict)")
    out.append("    (absent : List String := []) : Scenario :=")
    out.append("  { name := name")
    out.append("    rule := inst.name")
    out.append("    trace := τ")
    out.append("    reading := {}          -- ignored by the gate: the run's reading is substituted")
    out.append("    manifest := Build.manifest absent")
    out.append(f"    grounding := [{grounding}]")
    if regions:
        out.append(f"    regions := [{region_ids}]")
    out.append("    expected := expected }")
    out.append("")
    lines = []
    for name in names:
        s = scen.get(name) if name != "counterexample" else (c.get("counterexample") or {})
        s = s or {}
        expected = VERDICT_LEAN[normalize_verdict(s.get("expected", CONCEPT_SCENARIOS.get(name, "violated")))]
        masked = s.get("masked", []) if name == "blind" else []
        if isinstance(masked, str):
            masked = [masked]
        extra = f" {_lean_list([_s(a) for a in masked])}" if masked else ""
        lines.append(f"witness {_s(name)} {name}Trace {expected}{extra}")
    out.append("def scenarios : List Scenario :=")
    out.append("  [ " + "\n  , ".join(lines) + " ]")
    out.append("")
    out.append(f"end {ns}")
    return "\n".join(out) + "\n"
