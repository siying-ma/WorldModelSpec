"""Rule and witness skeletons, generated from a blueprint node.

The skeleton carries everything the gate's DECLARATION_MISMATCH step compares (id, laws, binders,
assumptions, operationalizations, residues, surrogate), the node's parameters as `Term` values,
and the four scenarios with their expected verdicts and masked atoms; the formulas and the scenes
are left to the coding session, marked `TODO`. Both files build as written, so the session's first
gate run measures its own work rather than a spelling.
"""
from __future__ import annotations
import re
from . import nodeid
from .blueprint import Node, SCENARIOS, concepts_of, normalize_verdict

VERDICT_LEAN = {"violated": ".violated", "compliant": ".compliant", "not_applicable": ".notApplicable", "unknown": "(.unknown [])"}


def _s(text: object) -> str:
    """A Lean string literal."""
    t = str(text if text is not None else "").replace("\\", "\\\\").replace('"', '\\"')
    return '"' + " ".join(t.split()) + '"'


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


def _comment(text: str, indent: str = "  ") -> str:
    return "\n".join(f"{indent}-- {l}" if l else f"{indent}--" for l in text.splitlines()) if text else ""


def _span_lines(node: Node, roles: set[str]) -> list[str]:
    return [f"{s['id']} ({s.get('role')}): {' '.join(str(s.get('text', '')).split())}"
            for s in node.get("segmentation", []) if s.get("role") in roles]


def rule_skeleton(node: Node) -> str:
    ns = nodeid.rule_namespace(node.id)
    binders = node.get("binders", [])
    params = node.params()
    ops = node.get("operationalizations", [])
    asms = node.get("assumptions", [])
    residues = node.get("residues", [])
    surrogate = any(o.get("surrogate") for o in ops)
    elements = node.get("elements", [])
    comps = node.compositions()

    head = [f"/-", f"  {node.id} — {', '.join(node.get('law_refs', []))}", "",
            "  THE READING (the blueprint's; the coding session records here, per span, how each element,",
            "  operationalization and composition below is written, and every choice the text did not dictate).", "",
            "  Spans:"]
    for s in node.get("segmentation", []):
        head.append(f"    {s['id']} ({s.get('role')}): {' '.join(str(s.get('text', '')).split())}")
    if elements:
        head += ["", "  Elements (span → atoms, derived):"]
        for e in elements:
            head.append(f"    {e.get('span')}: atoms {e.get('atoms', [])}, derived {e.get('derived', [])}")
    if comps:
        head += ["", "  Compositions (span → node, as, map):"]
        for c in comps:
            head.append(f"    {c.get('span')}: {c.get('rule')} as {c.get('as')} map {c.get('map')}")
    if node.literals():
        head += ["", "  Literals the text states (each written through its Units constructor):"]
        for l in node.literals():
            head.append(f"    {l.get('span')}: {l.get('value')} {l.get('unit')} — {l.get('text')}")
    head += ["", "  No magnitude below is this file's own: parameters name the reading, literals are the text's.", "-/"]

    out = head + ["import TrafficSpec.Core.Rule", "", f"namespace {ns}", ""]
    out.append("/-- The binders, as arguments (order and names are the node's). -/")
    for b in binders:
        out.append(f"private def {_ident('v_' + b['name'])} : Arg := .var {_s(b['name'])}")
    out.append("")
    if params:
        out.append("/-- The reading's parameters; no value of any of them lives in this file. -/")
        for p in params:
            out.append(f"private def {_ident(p)} : Term := .param {_s(p)}")
        out.append("")
    out.append("private def zeroMetres : Term := .lit Q.zero .metre")
    out.append("")
    out.append("-- TODO(code): class formulas, applicability and obligation — from the node's elements,")
    out.append("-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.")
    out.append("")
    for b in binders:
        out.append(f"/-- Class of `{b['name']}`: {', '.join(b.get('class_elements', []))} -/")
        out.append(f"private def {_ident('cls_' + b['name'])} : Formula := .tt  -- TODO")
    out.append("")
    app_spans = _span_lines(node, {"trigger", "condition", "exception"})
    obl_spans = _span_lines(node, {"obligation", "standard"})
    out.append("/-- Applicability: " + ("; ".join(app_spans) if app_spans else "(no trigger/condition span)") + " -/")
    out.append("private def applicability : Formula := .tt  -- TODO")
    out.append("")
    out.append("/-- Obligation: " + ("; ".join(obl_spans) if obl_spans else "(no obligation span)") + " -/")
    out.append("private def obligation : Formula := .tt  -- TODO")
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
    if ops:
        olines = []
        for o in ops:
            olines.append("{ standard := " + _s(o.get("standard", "")) +
                          "\n          concepts := " + _lean_list([_s(c) for c in sorted(concepts_of(o))]) +
                          "\n          params := " + _lean_list([_s(p) for p in o.get("params", [])]) +
                          "\n          convention := " + _s(o.get("convention", "")) +
                          f"\n          surrogate := {'true' if o.get('surrogate') else 'false'} }}")
        out.append("    operationalizations :=")
        out.append("      [ " + "\n      , ".join(olines) + " ]")
    else:
        out.append("    operationalizations := []")
    out.append(f"    residues := {_lean_list([_s(r.get('why', '')) for r in residues])}"
               "  -- the node's, verbatim; append one entry per CONSEQUENCE in the header")
    out.append(f"    surrogate := {'true' if surrogate else 'false'} }}")
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
           f"import {nodeid.rule_module(node.id)}", "import TrafficSpec.Core.Builders", "",
           f"namespace {ns}", "", "open TrafficSpec", "",
           "private def m (n : Int) : Q := Units.metres n", "private def cm (n : Int) : Q := Units.centimetres n", "",
           f"-- Binders ↦ tracks: {', '.join(f'{b} ↦ {i + 1}' for i, b in enumerate(binders)) or '(no binders)'}", ""]
    for name in SCENARIOS:
        s = scen.get(name, {})
        narrative = " ".join(str(s.get("narrative", "")).split())
        out.append(f"/-- `{name}` ({SCENARIOS[name]}): {narrative} -/")
        out.append(f"private def {name}Trace : Trace :=")
        out.append("  Build.trace 3 0 (Units.seconds 1) fun _k t =>")
        out.append("    Build.scene t (some 1)")
        out.append("      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)")
        out.append("      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …")
        out.append("      [ ]  -- devices")
        out.append("")
    out.append("private def witness (name : String) (τ : Trace) (expected : Verdict)")
    out.append("    (absent : List String := []) : Scenario :=")
    out.append("  { name := name")
    out.append(f"    rule := {_s(node.id)}")
    out.append("    trace := τ")
    out.append("    reading := {}          -- ignored by the gate: the run's reading is substituted")
    out.append("    manifest := Build.manifest absent")
    out.append(f"    grounding := [{grounding}]")
    out.append("    expected := expected }")
    out.append("")
    lines = []
    for name in SCENARIOS:
        s = scen.get(name, {})
        expected = VERDICT_LEAN[normalize_verdict(s.get("expected", SCENARIOS[name]))]
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
