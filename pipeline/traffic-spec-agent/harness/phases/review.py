"""The behaviour review: a second vendor's model asked the behavioural question, its claims
executed, and the law's side of each confirmed claim adjudicated.

The review runs after the gate, once per node that passed it, over the law, the record (with the
coder's narrowings), the mechanical rendering of the formulas, the atoms the rule reads, the
contracts, the reading's parameters and the trace format. It asks for situations in which a road
user complying with the rule breaks the law, breaking the rule complies with the law, or the rule
returns no verdict inside the law's domain — each written as a trace with the law's verdict. The
harness runs the rule on every trace: a trace on which the rule's verdict differs from the law's
confirms the rule's side of the divergence; a trace on which they agree is an advisory. The
reviewer's own `verdict` decides nothing.

Execution cannot confirm the reviewer's verdict for the law. Every confirmed divergence, from any
answer the review session gave, goes to the adjudicator, a tool-less session of the agents' own
vendor, which upholds it, dismisses it (a reasonable reading gives the rule's verdict, or the
reviewer's own rules make it an advisory), or sends it to the operator as a question about an
aggregate word's membership. Only an upheld divergence returns the node.

Answers are JSON under a strict schema; an answer with defects (a quote not in the inputs, a trace
that does not decode or leaves out an atom the rule reads) is asked for once more. Concepts keep
their contract-versus-body review, which no law and no trace can replace.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from ..agents import render, session
from ..lean import lean, render_formula
from ..model import corpus, nodeid, ontology
from ..model.blueprint import Node
from ..model.reading import Reading
from ..store import paths
from ..store.state import Run
from . import validate as validate_phase

PLACEHOLDERS_REVIEW_CODE = ("law_and_segmentation", "record", "rendered", "atoms_read", "contracts", "parameters", "trace_format")
PLACEHOLDERS_ADJUDICATE = ("law_and_segmentation", "record", "rendered", "contracts", "divergences")
RULINGS = {"upheld", "dismissed", "reading"}
VERDICTS = {"accept", "return"}
GAP_KINDS = {"standard_factor", "broader_contract"}
KINDS = {"rule_permits_unlawful", "rule_forbids_lawful", "rule_undecided"}
#: The verdicts a reviewer may give the law, spelt as the review harness prints the rule's (`Verdict.tag`).
LAWFUL = {"violated", "compliant", "not_applicable"}


def enabled(run: Run) -> bool:
    return bool(getattr(run.opts, "reviewer_model", None))


def _ws(s) -> str:
    return " ".join(str(s or "").split())


def _norm(s) -> str:
    """Whitespace-normalized, case-folded, without backticks, double quotation marks or the
    backslashes that escape them: the marks a quotation adds or drops do not make it less verbatim."""
    return _ws(re.sub(r'[`"\\\u201c\u201d]', "", str(s or "")).replace("\u2019", "'").replace("''", "'")).lower()


def _in(q: str, haystack: str) -> bool:
    """The quote occurs in the haystack, punctuation at its edges aside. A quote elided with `…`,
    `...` or `[...]` occurs when every fragment does, in order, and the fragments together carry at
    least three words."""
    frags = [f for f in (_norm(x).strip(" .,;:") for x in re.split(r"\[\s*(?:\u2026|\.\.\.)\s*\]|\u2026|\.\.\.", str(q or ""))) if f]
    if not frags or (len(frags) > 1 and sum(len(f.split()) for f in frags) < 3):
        return False
    h, pos = _norm(haystack), 0
    for f in frags:
        i = h.find(f, pos)
        if i < 0:
            return False
        pos = i + len(f)
    return True


def _quoted(q: str, haystack: str) -> bool:
    """`_in`, also with the rendering's annotations left out of both the quote and the haystack."""
    return _in(q, haystack) or _in(render_formula.bare(q), render_formula.bare(haystack))


def _strings(x) -> list[str]:
    """Every string value of a JSON value, depth first."""
    if isinstance(x, str):
        return [x]
    if isinstance(x, dict):
        return [s for v in x.values() for s in _strings(v)]
    if isinstance(x, list):
        return [s for v in x for s in _strings(v)]
    return []


def _session(run: Run, out_dir: Path, label: str, prompt: str, check):
    return validate_phase._session(run, out_dir, label, prompt, check=check, model=run.opts.reviewer_model,
                                   effort=getattr(run.opts, "review_effort", None))


# ---------------------------------------------------------------------------------------------
# The trace format a reviewer writes situations in (the decoder's keys; the spellings are the ontology's)
# ---------------------------------------------------------------------------------------------
TRACE_CONVENTIONS = """### Trace format

The keys below are generated from the decoder the harness runs your traces through, so every atom
the rule reads can be written. A trace is `{"scenes": [scene, ...]}` with `t` strictly increasing
(milliseconds). Every key is optional unless marked required, and a key left out is unobserved
(the rule reads it as unknown), never false: write every key the rule reads. Numbers are in Core
units: metres, seconds, m/s, m/s², degrees and degrees per second; positions, headings and
velocities in one world frame. Occupancy is decided only for the tracks `occupancy_observed`
lists (`true` lists every user): for them a pair in `occupies` is occupied and any other pair is
not, or, with `occupies` left out, occupancy is computed from footprints and boundaries; for any
other track every occupancy is unknown, whatever `occupies` says. Relations are computed from
kinematics when absent, except `visible`. The map is repeated in every scene. A look-back of
length d needs scenes reaching d before the observation judged, no two consecutive scenes more
than d/2 apart; otherwise the look-back is unknown. Instants whose look-back reaches before the
first scene are not judged, so begin the trace at least d before the situation.

"""
#: The decoder functions of the trace document, and the name each record goes by in the format.
_RECORDS = {"scene": "scene", "roadUser": "user (scene.users[])", "kin": "kin (user.kin)", "signals": "sig (user.sig)",
            "posture": "posture (user.posture)", "warningLamp": "warning lamp (sig.warning_lamps[])",
            "structure'": "structure (scene.structures[])", "laneInfo": "lane (structure.lane)",
            "device": "device (scene.devices[])", "conditions": "conditions (device.conditions)",
            "timeWindow": "time window (conditions.windows[])", "env": "env (scene.env)",
            "civilTime": "civil time (env.civil_time)", "relation": "relation (scene.relations[])"}
_SUB = {"roadUser": "user", "kin": "kin", "signals": "sig", "posture": "posture", "warningLamp": "warning lamp",
        "structure'": "structure", "laneInfo": "lane", "device": "device", "conditions": "conditions",
        "timeWindow": "time window", "env": "env", "civilTime": "civil time", "relation": "relation",
        "marking": "[marking type, marking colour]"}
_PRIM = {"vec": "[x, y]", "num": "number", "bool": "bool", "nat": "nat", "int": "int", "str": "string"}


def _decoder_type(tok: str, key: str) -> str:
    import re
    if key == "extent":
        return "[half_length, half_width, half_height]"
    if tok in _PRIM:
        return _PRIM[tok]
    if tok in _SUB:
        return _SUB[tok]
    m = re.match(r"\(enum (\w+)\.ofString\)", tok)
    if m:
        return f"a {m.group(1)} spelling"
    m = re.match(r"\(pair (\w+) (\w+)\)", tok)
    if m:
        return f"[{_PRIM.get(m.group(1), m.group(1))}, {_PRIM.get(m.group(2), m.group(2))}]"
    return "value"


def decoder_keys(decode_source: str) -> dict[str, list[str]]:
    """Every key the trace decoder reads, per record, with its type and whether it is required: read
    from the decoder's source, so the format a reviewer writes in is the format that decodes."""
    import re
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


_RECORD_OF_PREFIX = {"kin": ("kin (user.kin)", "users[].kin."), "sig": ("sig (user.sig)", "users[].sig."),
                     "env": ("env (scene.env)", "env."), "st": ("structure (scene.structures[])", "structures[]."),
                     "rel": ("relation (scene.relations[])", "relations[]."), "dev": ("device (scene.devices[])", "devices[].")}


def trace_place(atom: str, keys: dict[str, list[str]] | None = None) -> str:
    """Where a trace writes what an atom (Lean name) reads, by the decoder's own keys: a field of its
    record when the decoder has one by that name; occupancy, classes and kinds where they live."""
    if keys is None:
        keys = decoder_keys((paths.CORE / "Runtime" / "Decode.lean").read_text(encoding="utf-8"))
    prefix, _, rest = atom.partition("_")
    if atom == "rel_occupies":
        return "`occupies` with the track in `occupancy_observed`"
    if prefix == "ru":
        return "`users[].classes`" + (" (aggregate words through the reading)" if rest == "aggregate" else "")
    rec = _RECORD_OF_PREFIX.get(prefix)
    if rec is None:
        return "(see the trace format)"
    fields = {r.split("`")[1] for r in keys.get(rec[0], []) if r.startswith("`")}
    if rest in fields:
        return f"`{rec[1]}{rest}`"
    if prefix in ("st", "dev"):
        from ..lean import surface
        kinds = surface.enumeration_spellings().get("StructureKind" if prefix == "st" else "DeviceKind", set())
        if rest in kinds:
            return f"`{rec[1]}kind` = `{rest}`"
        return "computed from the users' positions and the structures' positions and boundaries"
    if prefix == "rel":
        return "computed from the users' kinematics when `relations` leaves it out"
    return "(see the trace format)"


def atoms_read(rule_json: dict, concepts: dict[str, dict]) -> list[str]:
    """Every atom (Lean name) the rule reads: its own leaves, and what the concepts and primitives
    it calls read, so a trace that leaves none of them out can be judged."""
    from ..lean import surface
    names: set[str] = set()

    def walk(x) -> None:
        if isinstance(x, dict):
            for k in ("atom", "measure", "derived"):
                if isinstance(x.get(k), str):
                    names.add(x[k])
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(rule_json)
    prims = surface.primitive_reads()
    reads = {n for n in names if not n.startswith(("drv_", "prim_"))}
    for n in names:
        if n.startswith("prim_"):
            reads.update(prims.get(n, []))
        elif n.startswith("drv_"):
            rec = next((r for cid, r in concepts.items() if cid.replace(".", "_") == n), {})
            reads.update(a.replace(".", "_") for a in rec.get("reads", []))
    return sorted(reads)


def atoms_read_block(rule_json: dict, concepts: dict[str, dict]) -> str:
    keys = decoder_keys((paths.CORE / "Runtime" / "Decode.lean").read_text(encoding="utf-8"))
    rows = "\n".join(f"- `{a}` — in the trace: {trace_place(a, keys)}" for a in atoms_read(rule_json, concepts))
    return ("### The atoms this rule reads\n\nEvery atom the rule reads, including those its concepts and primitives "
            "read, and where a trace writes it. A trace that leaves one out where the rule reads it leaves the rule "
            "unknown there.\n\n" + rows + "\n")


def trace_format_block() -> str:
    from ..lean import surface
    src = (paths.CORE / "Runtime" / "Decode.lean").read_text(encoding="utf-8")
    keys = "\n".join(f"- {rec}: " + ", ".join(rows) + "." for rec, rows in decoder_keys(src).items())
    spell = surface.enumeration_spellings()
    rows = "\n".join(f"- {name}: {', '.join(sorted(vals))}" for name, vals in sorted(spell.items()))
    return TRACE_CONVENTIONS + keys + "\n\nEnumeration spellings (the values the decoder accepts):\n" + rows + "\n"


# ---------------------------------------------------------------------------------------------
# Behaviour review of a node: claims as traces, traces executed
# ---------------------------------------------------------------------------------------------
def _parameters_block(reading: Reading, names: set[str] | None = None) -> str:
    rows = [f"- `{p['name']}` = {p.get('value')} {p.get('unit')}: {p.get('convention', '')}" + (" (proposed, unreviewed)" if p.get("proposed") else "")
            for p in reading.data.get("params", []) if names is None or p["name"] in names]
    return "### Parameters\n\n" + ("\n".join(rows) or "(none)") + "\n"


def behaviour_defects(answer: dict, law_text: str, rendering: str, binders: list[str]) -> list[str]:
    """Defects of the answer as an answer: the verdict word, each divergence's kind, lawful verdict,
    grounding over the rule's binders, a trace with scenes, and quotes that occur in the law and in
    the rendering."""
    errs = []
    if answer.get("verdict") not in VERDICTS:
        errs.append("`verdict` must be `accept` or `return`")
    divs = answer.get("divergences", [])
    if not isinstance(divs, list):
        return errs + ["`divergences` must be a list"]
    gaps = answer.get("gap_candidates", [])
    if not isinstance(gaps, list) or not all(isinstance(g, dict) and all(_ws(g.get(k)) for k in ("span", "words", "factor", "nearest"))
                                             and g.get("kind") in GAP_KINDS for g in gaps):
        errs.append("`gap_candidates` must be a list of objects with `kind` (`standard_factor` or `broader_contract`), `span`, `words`, `factor` and `nearest`")
    else:
        for k, g in enumerate(gaps, 1):
            if not _in(g.get("words", ""), law_text):
                errs.append(f"gap candidate {k}: `words` is not verbatim from the law — quote the words of the span that name the factor")
    if answer.get("verdict") == "return" and not divs:
        errs.append("a return needs at least one divergence with a trace")
    for k, d in enumerate(divs, 1):
        if not isinstance(d, dict):
            errs.append(f"divergence {k} is not an object"); continue
        if d.get("kind") not in KINDS:
            errs.append(f"divergence {k}: kind must be one of {sorted(KINDS)}")
        if d.get("lawful_verdict") not in LAWFUL:
            errs.append(f"divergence {k}: lawful_verdict must be one of {sorted(LAWFUL)}")
        g = d.get("grounding")
        if not isinstance(g, dict) or set(g) != set(binders) or not all(isinstance(v, int) for v in g.values()):
            errs.append(f"divergence {k}: grounding must map exactly the binders {binders} to track ids")
        tr = d.get("trace")
        if not isinstance(tr, dict) or not isinstance(tr.get("scenes"), list) or not tr["scenes"]:
            errs.append(f"divergence {k}: trace must be an object with a non-empty `scenes` list")
        if not _in(d.get("law_words", ""), law_text):
            errs.append(f"divergence {k}: law_words is not verbatim from the law")
        if not _quoted(d.get("rule_reads", ""), rendering):
            errs.append(f"divergence {k}: rule_reads is not verbatim from the rendering")
    return errs


def _review_harness_source(node_id: str, reading_json: Path, traces: list[tuple[int, Path, str, dict[str, int]]]) -> str:
    """A Lean program that decodes each trace and prints the rule's episode verdict on it, without
    an expectation (the comparison with the law's verdict is the harness's). An instant whose only
    unknown is a window reaching past the trace's start or end is not judged: a written situation
    begins and ends somewhere, and its look-back covers the observations after it. A trace with no
    other instant stays unknown."""
    rns = nodeid.rule_namespace(node_id)
    items = ", ".join(
        f'({k}, {json.dumps(str(p.resolve()))}, [{", ".join(f"({json.dumps(b)}, {t})" for b, t in g.items())}])'
        for k, p, _lawful, g in traces)
    return f'''import TrafficSpec
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import {nodeid.rule_module(node_id)}
open TrafficSpec Lean
def main : IO Unit := do
  let r := {rns}.rule
  let rules := ((allRules.filter (·.id != r.id)) ++ [r]).map (Concept.expandRule allConcepts)
  let r' := Concept.expandRule allConcepts r
  let ρtext ← IO.FS.readFile {json.dumps(str(reading_json.resolve()))}
  let ρ ← match Decode.parse Decode.reading ρtext with
    | .ok v => pure v
    | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; pure ({{}} : Reading)
  let items : List (Nat × String × List (String × Nat)) := [{items}]
  for (k, path, grounding) in items do
    let text ← IO.FS.readFile path
    match Decode.parse Decode.trace text with
    | .error e => IO.println s!"DIS\\t{{k}}\\tdecode\\t{{e}}"
    | .ok τ =>
      let m := Manifest.full "review"
      let S := Grounding.Setup.mk' rules (maskTrace m τ) ρ m.reidGap
      let g : Grounding.Grounding := ⟨grounding.map fun (n, t) => (n, Grounding.canon S.cm t)⟩
      let tl := Grounding.evaluate S r' g
      let vs := tl.verdicts.toList.map (·.2)
      let edge := fun (v : Verdict) => match v with
        | .unknown rs => !rs.isEmpty && rs.all (fun x => match x with | .windowTruncated _ => true | _ => false)
        | _ => false
      let judged := vs.filter (fun v => !edge v)
      let got := Grounding.episode (if judged.isEmpty then vs else judged)
      IO.println s!"DIS\\t{{k}}\\t{{got.tag}}\\t{{String.intercalate "," (got.reasons.map UnknownReason.tag)}}"
'''


#: Unknown reasons that are the trace's, not the rule's: an atom left out, a look-back sampled too
#: sparsely (any trace can sample densely), and a look-back the scenes do not cover. For a
#: divergence claiming the rule undecided, a look-back that no trace of ordinary length covers is
#: the claim itself, so there the truncated window stays the rule's.
def _trace_defect(reason: str, kind: str | None) -> bool:
    if reason.startswith(("absent_atom:", "sampling_gap:")):
        return True
    return kind != "rule_undecided" and reason.startswith("window_truncated:")


def _trace_remedy(reason: str) -> str:
    """What the reviewer writes so the reason no longer arises."""
    what = reason.split(":", 1)[1] if ":" in reason else reason
    if reason == "absent_atom:rel_occupies":
        return "occupancy is unknown — list the track in `occupancy_observed` (or set it to `true`)"
    if reason.startswith("absent_atom:"):
        return f"`{what}` is not written — in the trace: {trace_place(what)}; write it in every scene the rule reads it"
    if reason.startswith("window_truncated:"):
        return f"the look-back of `{what}` reaches before the first scene — add scenes covering its full length before the observation judged"
    return f"the look-back of `{what}` is sampled too sparsely — no two consecutive scenes more than half its length apart"


def quoted_spans(n: Node, law_text: str, quote: str) -> str:
    """The substantive spans of the node whose words the quote covers, as `s1,s4` (`-` when the
    quote is not found): what a divergence objects to, so a repeat is the same objection to the same words."""
    norm = lambda x: " ".join(str(x or "").split()).lower()
    lt, q = norm(law_text), norm(quote)
    a = lt.find(q) if q else -1
    if a < 0:
        return "-"
    b, ids = a + len(q), []
    for s in n.get("segmentation", []):
        t = norm(s.get("text"))
        i = lt.find(t) if t and s.get("role") != "boilerplate" else -1
        if i >= 0 and i < b and i + len(t) > a:
            ids.append(str(s.get("id")))
    return ",".join(ids) or "-"


def execute_divergences(run: Run, n: Node, answer: dict, reading: Reading,
                        out_dir: Path, law_text: str = "") -> tuple[list[dict], list[str], list[str], list[str]]:
    """Run the rule on every divergence trace. Returns (confirmed, unconfirmed, errors, incomplete):
    a trace on which the rule's verdict differs from the law's (or is unknown where the law
    decides) confirms the divergence, returned as `{line, div, rule}`; one on which they agree is the reviewer's advisory; one on
    which the rule is unknown only because the trace leaves out an atom the rule reads, or does not
    cover or sample a look-back (`_trace_defect`), is incomplete, the trace's defect and not the
    rule's, named with what to write; a divergence whose verdict,
    grounding or trace is malformed is not run, and it, a trace that does not decode and a harness
    that does not run are errors the caller reports. Divergences keep their numbers in the answer."""
    binders = {b["name"] for b in n.get("binders", [])}

    def runnable(d: dict) -> bool:
        g, tr = d.get("grounding"), d.get("trace")
        return (d.get("lawful_verdict") in LAWFUL and isinstance(g, dict) and set(g) == binders
                and all(isinstance(t, int) for t in g.values())
                and isinstance(tr, dict) and isinstance(tr.get("scenes"), list) and bool(tr["scenes"]))
    listed = answer.get("divergences")
    numbered = {k: d for k, d in enumerate(listed if isinstance(listed, list) else [], 1) if isinstance(d, dict)}
    skipped = [f"divergence {k}: not run, its verdict, grounding or trace is malformed" for k, d in numbered.items() if not runnable(d)]
    divs = {k: d for k, d in numbered.items() if runnable(d)}
    if not divs:
        return [], [], skipped, []
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in out_dir.glob("disagreement_*.json"):
        stale.unlink()
    traces = []
    for k, d in divs.items():
        p = out_dir / f"disagreement_{k}.json"
        p.write_text(json.dumps(d.get("trace"), ensure_ascii=False, indent=1), encoding="utf-8")
        traces.append((k, p, d["lawful_verdict"], {b: int(t) for b, t in d["grounding"].items()}))
    reading_json = out_dir / "reading.json"
    reading_json.write_text(reading.lean_json(), encoding="utf-8")
    harness = out_dir / "review_harness.lean"
    harness.write_text(_review_harness_source(n.id, reading_json, traces), encoding="utf-8")
    ok, hout = lean.lean_run(paths.LIBRARY, harness)
    (out_dir / "review_harness.out").write_text(hout, encoding="utf-8")
    if not ok:
        return [], [], skipped + [f"the review harness did not run: {hout[-600:]}"], []
    got = {}
    for line in hout.splitlines():
        parts = line.split("\t")
        if parts[0] == "DIS" and len(parts) >= 3:
            got[int(parts[1])] = (parts[2], parts[3] if len(parts) > 3 else "")
    confirmed, unconfirmed, errors, incomplete = [], [], list(skipped), []
    for k, _p, lawful, _g in traces:
        d = divs[k]
        tag, why = got.get(k, ("missing", ""))
        head = (f"divergence {k} ({d.get('kind')}) [{quoted_spans(n, law_text, d.get('law_words'))}]: "
                f"{_ws(d.get('situation'))[:160]} — law: {d.get('lawful_verdict')}, rule: {tag}")
        if tag == "decode":
            errors.append(f"divergence {k}: the trace does not decode: {why[:200]}")
        elif tag == "missing":
            errors.append(f"divergence {k}: the harness printed no verdict")
        elif tag == lawful:
            unconfirmed.append(head + " (the rule agrees with the law on this trace)")
        elif tag == "unknown" and why and all(_trace_defect(r, d.get("kind")) for r in why.split(",")):
            incomplete.append(f"divergence {k} ({d.get('kind')}): {_ws(d.get('situation'))[:120]} — the rule's verdict on the trace is "
                              f"unknown only because the trace is incomplete: " + "; ".join(sorted({_trace_remedy(r) for r in why.split(",")})))
        else:
            line = head + (f" [{why}]" if tag == "unknown" and why else "") + f'; law: "{_ws(d.get("law_words"))[:120]}"; rule: "{_ws(d.get("rule_reads"))[:120]}"'
            confirmed.append({"line": line, "div": d, "rule": tag + (f" ({why})" if tag == "unknown" and why else "")})
    return confirmed, unconfirmed, errors, incomplete


def gap_candidate_lines(gaps: list) -> list[str]:
    """One line per factor of a standard the law names (span and verbatim words), however many
    aspects of it the reviewer listed: the operator decides a named factor, not each thing it could
    be read as. A `broader_contract` candidate is adjudicated instead (`broader_contract_items`)."""
    grouped: dict[tuple[str, str], list[dict]] = {}
    for g in gaps if isinstance(gaps, list) else []:
        if isinstance(g, dict) and g.get("kind") != "broader_contract":
            grouped.setdefault((str(g.get("span")), _ws(g.get("words")).lower()), []).append(g)
    return [f"gap candidate: span {span} — \"{_ws(gs[0].get('words'))}\": " + "; ".join(_ws(g.get("factor")) for g in gs)
            + f" (nearest: {_ws(gs[0].get('nearest'))[:200]})" for (span, _w), gs in grouped.items()]


def broader_contract_items(gaps: list) -> list[dict]:
    """The reviewer's `broader_contract` candidates as adjudication items: the law's words carried by a
    contract that admits what they exclude, which no trace can show, so the adjudicator rules on the
    words alone. An upheld one returns the node so that the plan files a gap on the span."""
    out, seen = [], set()
    for g in gaps if isinstance(gaps, list) else []:
        if not (isinstance(g, dict) and g.get("kind") == "broader_contract"):
            continue
        key = (str(g.get("span")), _ws(g.get("words")).lower())
        if key in seen:
            continue
        seen.add(key)
        words, nearest = _ws(g.get("words")), _ws(g.get("nearest"))
        out.append({"line": f"gap: span {g.get('span')} — \"{words}\" is carried by a broader contract ({nearest[:160]}); "
                            f"the words exclude {_ws(g.get('factor'))[:160]}: file a gap on this span",
                    "div": {"kind": "broader_contract",
                            "situation": f"the words \"{words}\" of span {g.get('span')} exclude {_ws(g.get('factor'))}, "
                                         f"which the carried contract admits",
                            "law_words": words, "lawful_verdict": "not_applicable", "rule_reads": nearest},
                    "rule": "not executed: no contract makes the distinction, so no trace can show it"})
    return out


def adjudication_defects(answer: dict, count: int, haystack: str) -> list[str]:
    """Defects of an adjudication: every divergence ruled once, a ruling word, a reason, a verbatim quote."""
    rows = answer.get("rulings")
    if not isinstance(rows, list):
        return ["`rulings` must be a list"]
    errs, seen = [], []
    for r in rows:
        if not isinstance(r, dict) or not isinstance(r.get("divergence"), int) or not 1 <= r["divergence"] <= count:
            errs.append(f"a ruling must name a divergence by its number, 1 to {count}"); continue
        k = r["divergence"]
        if k in seen:
            errs.append(f"divergence {k} is ruled twice")
        seen.append(k)
        if r.get("ruling") not in RULINGS:
            errs.append(f"divergence {k}: ruling must be one of {sorted(RULINGS)}")
        if not _ws(r.get("reason")):
            errs.append(f"divergence {k}: a ruling needs a reason")
        if not _quoted(r.get("quote", ""), haystack):
            errs.append(f"divergence {k}: the quote is not verbatim from the law, the record, the rendering or the contracts")
    errs += [f"divergence {k} has no ruling" for k in range(1, count + 1) if k not in seen]
    return errs


def adjudicate(run: Run, blocks: dict[str, str], items: list[dict], out_dir: Path,
               record: dict | None = None) -> list[tuple[dict, str, str]]:
    """Each confirmed divergence and broader-contract item with its ruling and reason. An item the
    adjudicator leaves unruled, or rules with a defect it keeps, stands as upheld: the adjudicator
    can only release a node from an item, never add one. Raises `SessionUnavailable` when the session
    never ran."""
    listing = "\n\n".join(
        f"{k}. ({i['div'].get('kind')}) {_ws(i['div'].get('situation'))}\n"
        f"   the law's words, per the reviewer: \"{_ws(i['div'].get('law_words'))}\"\n"
        f"   the reviewer's verdict for the law: {i['div'].get('lawful_verdict')}\n"
        f"   the rule's executed verdict: {i['rule']}\n"
        f"   the rule's words, per the reviewer: \"{_ws(i['div'].get('rule_reads'))}\""
        for k, i in enumerate(items, 1))
    ins = {k: blocks[k] for k in ("law_and_segmentation", "record", "rendered", "contracts")}
    ins["divergences"] = "### Divergences\n\n" + listing + "\n"
    prompt = render.render("adjudicate.md", ins)
    # a quote is looked for in the blocks as shown (the record serialized, so a quote may run across a
    # key and its value) and in the record's string values unescaped
    hay = "\n".join(blocks[k] for k in ("law_and_segmentation", "record", "rendered", "contracts")) \
        + "\n" + "\n".join(_strings(record or {}))
    answer, errs = validate_phase._session(run, out_dir, "adjudicate", prompt,
                                           check=lambda a: adjudication_defects(a, len(items), hay))
    rows = {r.get("divergence"): r for r in (answer or {}).get("rulings", []) if isinstance(r, dict)}
    bad = {int(m) for e in errs for m in re.findall(r"^divergence (\d+)", e)}
    out = []
    for k, i in enumerate(items, 1):
        r = rows.get(k)
        if r is None or k in bad or r.get("ruling") not in RULINGS:
            out.append((i, "upheld", "no valid ruling" + (f" ({'; '.join(errs)[:200]})" if errs else "")))
        else:
            out.append((i, r["ruling"], f"{_ws(r.get('reason'))} — \"{_ws(r.get('quote'))[:160]}\""))
    return out


def review_behaviour(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, reading: Reading, rule_json: dict | None,
                     coder_narrowings: list[dict], out_dir: Path) -> tuple[bool, list[str], list[str]]:
    """(accepted, reasons, advisories). Accepted when no divergence is both confirmed by execution
    and upheld by the adjudicator; the reviewer's prose verdict alone neither accepts nor returns. A
    well-formed answer is run at once, and an incomplete trace (an atom left out, a look-back not
    covered or sampled) is a defect the reviewer is asked once to repair, like a schema defect; one
    still incomplete after that is recorded as unconfirmed. A divergence confirmed on the first
    answer counts even when the second answer drops it."""
    if not enabled(run):
        return True, [], ["reviewer off"]
    if rule_json is None:
        return False, ["the gate exported no rule to review"], []
    glosses = validate_phase.glosses_for(n, onto, run)
    aggs = validate_phase.aggregates_for(n, reading)
    try:
        rendering = render_formula.render_rule(rule_json, glosses)
    except render_formula.Unrendered as e:
        raise session.SessionUnavailable(f"the renderer has no phrasing for the {e} (harness/lean/render_formula.py)") from e
    (out_dir / "rendered_rule.md").parent.mkdir(parents=True, exist_ok=True)
    (out_dir / "rendered_rule.md").write_text(rendering, encoding="utf-8")
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in n.get("segmentation", []))
    record = {k: v for k, v in n.raw.items() if k not in ("segmentation", "scenarios")}
    record["narrowings_by_the_coder"] = coder_narrowings
    binders = [b["name"] for b in n.get("binders", [])]
    blocks = {
        "law_and_segmentation": f"### Law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans:\n{seg}\n",
        "record": "### Record\n\n```json\n" + json.dumps(record, ensure_ascii=False, indent=1) + "\n```\n",
        "rendered": "### Rendering\n\n" + rendering + "\n",
        "atoms_read": atoms_read_block(rule_json, run.all_concepts()),
        "contracts": validate_phase.contracts_table(glosses, aggs),
        "parameters": _parameters_block(reading, set(n.params())),
        "trace_format": trace_format_block(),
    }
    prompt = render.render("review_code.md", blocks)
    executed: dict[str, tuple[list[dict], list[str], list[str], list[str]]] = {}

    def run_traces(a: dict) -> tuple[list[dict], list[str], list[str], list[str]]:
        key = json.dumps(a, sort_keys=True, ensure_ascii=False)
        if key not in executed:
            executed[key] = execute_divergences(run, n, a, reading, out_dir, law.text)
        return executed[key]

    check = lambda a: behaviour_defects(a, law.text, rendering, binders) + run_traces(a)[3]
    answer, errs = _session(run, out_dir, "review_behaviour", prompt, check)
    if answer is None:
        if errs:
            return False, [f"behaviour review: {e}" for e in errs], []
        return True, [], ["review skipped (dry run)"]
    if answer.get("verdict") not in VERDICTS or not isinstance(answer.get("divergences", []), list):
        return False, ["behaviour review: the answer is not a review (no verdict or divergence list): " + "; ".join(errs)], []
    _c, unconfirmed, errors, incomplete = run_traces(answer)
    confirmed, seen = [], set()
    for res in executed.values():                          # every answer's confirmations, the first answer's included
        for c in res[0]:
            key = (c["div"].get("kind"), _ws(c["div"].get("situation")))
            if key not in seen:
                seen.add(key); confirmed.append(c)
    unconfirmed = unconfirmed + [f"not confirmed — {x}" for x in incomplete]
    advisories = [str(x) for x in answer.get("advisories", [])] + unconfirmed + errors + gap_candidate_lines(answer.get("gap_candidates", []))
    items = confirmed + broader_contract_items(answer.get("gap_candidates", []))
    rulings = adjudicate(run, blocks, items, out_dir, record) if items else []
    upheld = [i["line"] for i, r, _w in rulings if r == "upheld"]
    advisories += [f"dismissed by the adjudicator — {i['line']}: {w}" for i, r, w in rulings if r == "dismissed"]
    advisories += [f"aggregate question: {i['line']}: {w}" for i, r, w in rulings if r == "reading"]
    (out_dir / "review_outcome.json").write_text(json.dumps({
        "reviewer_verdict": answer.get("verdict"), "rulings": [{"divergence": i["line"], "ruling": r, "why": w} for i, r, w in rulings],
        "unconfirmed": unconfirmed, "errors": errors, "schema_defects": errs}, ensure_ascii=False, indent=1), encoding="utf-8")
    if upheld:
        return False, upheld, advisories
    return True, [], advisories + (["the reviewer said `return` but no divergence was confirmed and upheld"] if answer.get("verdict") == "return" else [])
