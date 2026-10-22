"""The behaviour review: a second vendor's model shows situations in which a rule and the law it
formalizes decide differently; the harness certifies each one; two judges decide it.

A node divergence returns the node only when it is admitted:
- its trace is consistent (`TraceLint.checkTrace`) and its witness instant valid (`checkWitness`);
- it states a case — a typed formula over the trace, naming concrete classes and no parameter,
  assumption, rule, concept or legal aggregate — that holds at one instant `at` (`Case.check`,
  `Case.eval`);
- stage A, a judge that sees the law, the definitions that apply to it, the rendered case and the
  contracts it reads, and never the rule, the record, the reviewer's prose or any mapping, decides
  the law's verdict on that case;
- the rule's instantaneous verdict at `at` differs from stage A's (compliant and not applicable
  count alike);
- stage B, shown everything an excuse can rest on (the record, the rendered rule, the contracts,
  the parameters with their review status, the admitted aggregates, stage A's verdict and the
  rule's), upholds it: no disclosed reading, operator-reviewed parameter value or admitted
  aggregate membership explains the mismatch.
A Lean program (`Certificate.record`, one `CERT` line per divergence) runs the trace check, the
case and the rule. The reviewer runs it itself through its tools, one divergence per check, before
it submits; the harness runs it on every divergence of the submission. A submission with a schema
defect or a divergence that cannot be evaluated comes back while submissions remain; the last one
stands, and what it still carries leaves the review undecided. A judge whose answer stays invalid
defers the law (bounded by the ledger), never upholds by default. An upheld case is an obligation:
replayed on every later rule of the node, open while the rule diverges from the law's verdict,
satisfied once the rule gives it, and dropped only when it can no longer be evaluated or a judge's
changed input no longer upholds it.

Concepts keep their contract-versus-body review, whose traces pass the same trace check and whose
adjudication fails closed the same way.
"""
from __future__ import annotations

import hashlib
import json
import shutil
import re
import threading
from dataclasses import dataclass, field
from pathlib import Path

from ..agents import render, session
from ..lean import lean, render_formula, surface
from ..model import corpus, nodeid, ontology
from ..model.blueprint import Node
from ..model.reading import Reading
from ..store import jsonl, paths
from ..store.state import Run
from . import validate as validate_phase

PLACEHOLDERS_REVIEW_CODE = ("law_and_segmentation", "record", "rendered", "atoms_read", "contracts", "parameters", "trace_format",
                            "case_language", "case_vocabulary", "max_divergences", "review_checks", "review_submissions")
PLACEHOLDERS_JUDGE_CASE = ("law", "definitions", "case", "contracts")
PLACEHOLDERS_ADJUDICATE = ("law_and_segmentation", "definitions", "record", "rendered", "contracts", "parameters", "aggregates",
                           "item", "precedents")
VERDICTS = {"accept", "return"}
GAP_KINDS = {"standard_factor", "broader_contract"}
KINDS = {"rule_permits_unlawful", "rule_forbids_lawful", "rule_undecided"}
#: The verdicts a reviewer may claim for the law, spelt as `Verdict.tag`.
LAWFUL = {"violated", "compliant", "not_applicable"}
ANSWER_KEYS = {"verdict", "divergences", "advisories", "gap_candidates"}
DIVERGENCE_KEYS = {"kind", "situation", "law_words", "rule_reads", "lawful_verdict", "grounding", "trace", "case", "entities", "at", "unstatable"}
STAGE_A_KEYS = {"verdict", "decisive", "law_words", "reason"}
STAGE_A_VERDICTS = {"violated", "compliant", "not_applicable", "undetermined"}
STAGE_B_KEYS = {"outcome", "law_words", "reason"}
#: The outcomes a word-level item may receive: the claim confirmed, or the words permit the carried contract.
WORD_LEVEL_OUTCOMES = {"upheld", "dismissed_permitted_reading"}
CERT_SCHEMA = "certificate-run/1"
CASE_SCHEMA = "case/1"
WORD_LEVEL_SCHEMA = "word_level/1"


def enabled(run: Run) -> bool:
    return bool(run.opts.reviewer_model)


def _ws(s) -> str:
    return " ".join(str(s or "").split())


def _norm(s) -> str:
    """Whitespace-normalized, case-folded, without backticks, double quotation marks or the
    backslashes that escape them: the marks a quotation adds or drops do not make it less verbatim."""
    return _ws(re.sub(r'[`"\\“”]', "", str(s or "")).replace("’", "'").replace("''", "'")).lower()


def _in(q: str, haystack: str) -> bool:
    """The quote occurs in the haystack, punctuation at its edges aside. A quote elided with `…`,
    `...` or `[...]` occurs when every fragment does, in order, and the fragments together carry at
    least three words."""
    frags = [f for f in (_norm(x).strip(" .,;:") for x in re.split(r"\[\s*(?:…|\.\.\.)\s*\]|…|\.\.\.", str(q or ""))) if f]
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


def _digest(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------------------------
# The reviewer's tool session: checks against Core, then one accepted submission
# ---------------------------------------------------------------------------------------------
def _fn(name: str, description: str, arg: str, arg_description: str) -> dict:
    return {"type": "function", "name": name, "description": description, "strict": False,
            "parameters": {"type": "object", "properties": {arg: {"type": "object", "description": arg_description}}, "required": [arg]}}


def _canon(x) -> str:
    return json.dumps(x, sort_keys=True, ensure_ascii=False)


class ReviewTools:
    """The state of one reviewer session: `checks` check calls and `submissions` submissions,
    counted apart so a submission is always possible after the checks are spent. A check runs one
    divergence in its own directory under `checks/`; a submission runs the schema checks and the
    mechanical evidence checks on the exact answer. A submission with a schema defect or an
    unusable divergence comes back with the messages while submissions remain; the last one
    stands whatever it carries. Results are cached by the divergence's content for the session:
    the rule, the concepts, the reading and Core do not change while it runs. Subclasses give
    `_check(divergence, directory)` and `_submit(answer, number)`."""
    check_name = "check_divergence"

    def __init__(self, out_dir: Path, checks: int, submissions: int):
        self.out_dir, self.checks, self.submissions = out_dir, max(0, int(checks)), max(1, int(submissions))
        self.max_requests = self.checks + self.submissions + 4
        self.reset()
        self.launch = 0                                       # the session's first launch is L1

    def reset(self) -> None:
        """A new launch of the session: counts and cache start empty; its evidence goes to its own
        directories, so a relaunch keeps what the earlier launch wrote."""
        self.launch = getattr(self, "launch", 0) + 1
        self.used_checks = self.used_submissions = 0
        self.done, self.answer, self.attempts, self.cache = False, None, [], {}

    def choice(self):
        return "required" if self.used_checks < self.checks else {"type": "function", "name": "submit_review"}

    def call(self, name: str, args: dict) -> str:
        if name == self.check_name:
            if self.used_checks >= self.checks:
                return json.dumps({"status": "checks spent", "messages": ["no check is left: call `submit_review` with your answer"]})
            self.used_checks += 1
            return json.dumps(self._check(args.get("divergence"), self.out_dir / "checks" / f"L{self.launch}" / f"{self.used_checks:03d}"),
                              ensure_ascii=False)
        if name == "submit_review":
            self.used_submissions += 1
            answer = args.get("answer")
            defects = self._submit(answer, self.used_submissions) if isinstance(answer, dict) else ["`answer` must be the answer's JSON object"]
            last = self.used_submissions >= self.submissions
            if defects and not last:
                return json.dumps({"accepted": False, "defects": defects, "submissions_left": self.submissions - self.used_submissions,
                                   "checks_left": self.checks - self.used_checks}, ensure_ascii=False)
            self.done, self.answer = True, answer if isinstance(answer, dict) else None
            out = {"accepted": True, "final": True}
            if defects:
                out["defects"] = defects                     # the last submission stands with them: those challenges are not evaluated
            return json.dumps(out, ensure_ascii=False)
        return json.dumps({"error": f"no tool `{name}`: the tools are `{self.check_name}` and `submit_review`"})


class BehaviourTools(ReviewTools):
    def __init__(self, run: Run, n: Node, law: corpus.Law, reading: Reading, binders: list[str], windows: str, history: str,
                 out_dir: Path, checks: int, submissions: int):
        self.run, self.n, self.law, self.reading, self.binders = run, n, law, reading, binders
        self.windows, self.history = windows, history
        self.specs = [
            _fn("check_divergence", "Run one divergence through the harness's checks and Core: the trace check, the case check, "
                "the case's value at `at` (and, when it is not true, which of its facts are not), and the rule's verdict at `at`. "
                "Returns what the harness would make of it: `certifiable`, `refuted`, `unusable`, `unstatable` or `schema defects`, with the "
                "messages (they call it divergence 1). No judge is asked.", "divergence", "one divergence, in the answer's schema"),
            _fn("submit_review", "Submit the answer. The harness runs the same checks on every divergence of it; an answer with a "
                "schema defect or a divergence that cannot be evaluated comes back with the messages while submissions remain. "
                "The accepted submission is the answer.", "answer", "the answer, in the Output schema")]
        super().__init__(out_dir, checks, submissions)

    def cert(self, d: dict, where: Path) -> dict | None:
        """The certificate record of one divergence, run once per session; None when the program
        printed none for it."""
        key = _canon({k: d.get(k) for k in ("trace", "case", "entities", "at", "grounding")})
        if key not in self.cache:
            self.cache[key] = certify(self.run, self.n, {1: d}, self.reading, where).get(1)
        return self.cache[key]

    def judgeable(self, k: int, d: dict, c: dict | None) -> list[str]:
        if c is None:
            return [f"divergence {k}: not certified"]
        bad = cert_unusable(k, d, c, self.windows, self.history)
        return bad if bad or c.get("rule_result") is not None else [f"divergence {k}: the certificate printed no verdict of the rule"]

    def _check(self, d, where: Path) -> dict:
        schema = divergence_schema_defects(1, d, self.law.text, self.binders)
        if not schema and "unstatable" in d:
            return {"status": "unstatable", "messages": ["recorded as a gap candidate when submitted; nothing is run"]}
        if schema or not isinstance(d, dict) or not _certifiable(d, self.binders):     # nothing is run on a malformed divergence
            return {"status": "schema defects", "messages": schema or ["the divergence cannot be run"]}
        c = self.cert(d, where)
        bad = self.judgeable(1, d, c)
        refuted = cert_refutations(1, d, c) if c is not None else []
        status = "unusable" if bad else "refuted" if refuted else "certifiable"
        return {"status": status, "messages": schema + bad + refuted, "case_value": (c or {}).get("case_value"),
                "rule_verdict": (c or {}).get("rule_result")}

    def _submit(self, a: dict, number: int) -> list[str]:
        cap = self.run.opts.max_divergences
        errs = behaviour_defects(a, self.law.text, self.binders, cap)
        divs = a.get("divergences") if isinstance(a.get("divergences"), list) else []
        unusable, certified = [], 0
        if not (cap and len(divs) > cap):
            for k, d in enumerate(divs, 1):
                if isinstance(d, dict) and _certifiable(d, self.binders) and not divergence_schema_defects(k, d, self.law.text, self.binders):
                    bad = self.judgeable(k, d, self.cert(d, self.out_dir / "submissions" / f"L{self.launch}" / f"{number:03d}" / f"d{k}"))
                    unusable += bad; certified += not bad
        self.attempts.append({"divergences": len(divs), "certified": certified, "schema_defects": len(errs), "certificate_defects": len(unusable),
                              "checks_before": self.used_checks})
        return errs + unusable

    def certs_of(self, a: dict) -> dict[int, dict]:
        """The records of the answer's certifiable divergences, from the session's cache."""
        divs = a.get("divergences") if isinstance(a.get("divergences"), list) else []
        recs = {k: self.cert(d, self.out_dir / "final" / f"d{k}") for k, d in enumerate(divs, 1)
                if isinstance(d, dict) and _certifiable(d, self.binders) and not divergence_schema_defects(k, d, self.law.text, self.binders)}
        return {k: c for k, c in recs.items() if c is not None}


@dataclass
class ReviewOutcome:
    """What a review decided, for the loop's one branch per status: `accepted`; `returned` (an
    upheld item, with `keys` for the repeat count); `proceed_with_question` (accepted, with
    `questions` for the operator); `deferred` (a judge whose answer stayed invalid, or a harness that
    did not run, or a reviewer whose answer stayed unusable: `defer_stage` names which, and the law
    keeps its record and budget; a second consecutive deferral of one stage closes it)."""
    status: str
    reasons: list[str] = field(default_factory=list)
    advisories: list[str] = field(default_factory=list)
    keys: list[str] = field(default_factory=list)
    questions: list[str] = field(default_factory=list)
    defer_stage: str | None = None
    param_notes: list[tuple[str, str]] = field(default_factory=list)   # (proposed parameter, the reviewer's words on it)


class Deferred(Exception):
    """A judge answered invalidly twice (`stage` names it), or the certificate harness or the
    rulings file failed: the review defers instead of deciding."""
    def __init__(self, stage: str, why: str):
        super().__init__(why)
        self.stage, self.why = stage, why


# ---------------------------------------------------------------------------------------------
# The trace format a reviewer writes situations in (the decoder's keys; the conventions Core holds)
# ---------------------------------------------------------------------------------------------
TRACE_CONVENTIONS = """### Trace format

The keys below are generated from the decoder the harness runs your traces through, so every atom
can be written. A trace is `{"scenes": [scene, ...]}` with `t` strictly increasing (milliseconds).
Every key is optional unless marked required, and a key left out is unobserved (an atom that reads
it is unknown), never false: write every key the rule and your case read. Numbers are in Core
units: metres, seconds, m/s, m/s², degrees and degrees per second.

Frame. Every position, heading, velocity, lane direction and boundary is in one world frame, +x
east and +y north, angles counter-clockwise. Left of a heading is its counter-clockwise side: a
lateral offset, a bearing's lateral component and a side are positive to the left. A yaw rate is
positive when the heading turns to the left (counter-clockwise). A lane's ordinal 1 is its leftmost
lane, looking along the lane's direction.

Occupancy is decided only for the tracks `occupancy_observed` lists (`true` lists every user): for
them a pair in `occupies` is occupied and any other pair is not; for any other track every
occupancy is unknown, whatever `occupies` says. For an observed track you do not write `occupies`:
the harness derives it from the track's footprint and the structures' boundaries, as the check below
states, and replaces whatever the trace lists for it. Relations are computed from the users'
kinematics when `relations` leaves them out, except `visible`. A look-back of length d needs scenes
reaching d before the observation judged, no two consecutive scenes more than d/2 apart; otherwise
the look-back is unknown.

The harness checks every trace you write before it runs anything on it, exactly and with no
tolerance; a trace that fails is returned to you with the messages. The check, as Core states it:

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


#: Where the scene keeps each kind of entity, and the decoder of its record.
_BASES = {"user": ("users[]", "roadUser"), "structure?": ("structures[]", "structure'"), "device": ("devices[]", "device"),
          "relation": ("relations[]", "relation")}


def _accessor(atoms_src: str, name: str) -> str:
    m = re.search(rf"^def {re.escape(name)} \(s : Scene\).*?(?=^def |^/--|^-- -|\Z)", atoms_src, re.S | re.M)
    return m.group(0) if m else ""


def _field_path(atoms_src: str, name: str, fields: dict, depth: int = 0) -> str | None:
    """The trace path an atom accessor reads, from the projections in its body (`(s.user x).bind
    (·.kin.speed)` ↦ `users[].kin.speed`), following a call of another accessor."""
    body = _accessor(atoms_src, name)
    if not body or depth > 4:
        return None
    if re.search(r"\bs\.env\.(\w+)", body):
        f = re.search(r"\bs\.env\.(\w+)", body).group(1)
        key = fields.get("env", {}).get(f, (None,))[0]
        return f"env.{key}" if key else None
    base = re.search(r"\(s\.(user|structure\?|device|relation) ", body)
    chain = re.findall(r"(?:·|\bu|\bst|\bdv)\.((?:\w+\.)*\w+)", body)
    if base and chain:
        prefix, rec = _BASES[base.group(1)]
        path = []
        for f in chain[-1].split("."):
            key, sub = fields.get(rec, {}).get(f, (None, ""))
            if key is None:
                return None
            path.append(key)
            rec = sub or rec
        return f"{prefix}.{'.'.join(path)}"
    call = re.search(r"\b((?:ru|kin|st|dev|sig|env|rel)_\w+) s\b", body.split(":=", 1)[-1])
    if call and call.group(1) != name:
        inner = _field_path(atoms_src, call.group(1), fields, depth + 1)
        if inner is None:
            return None
        sub = re.search(r"\.bind \(·\.(\w+)\)|\.map \(·\.(\w+)\)", body.split(":=", 1)[-1])
        if sub:
            f = sub.group(1) or sub.group(2)
            for rec in fields.values():
                if f in rec:
                    return f"{inner}.{rec[f][0]}"
        return inner
    return None


def trace_place(atom: str, keys: dict[str, list[str]] | None = None) -> str:
    """Where a trace writes what an atom (Lean name) reads: the field its accessor in
    `Core/Vocab/Atoms.lean` projects, found under its JSON key in the decoder; a class or a kind
    where the codecs put it; occupancy where it is declared; a relation measured or computed."""
    if atom == "rel_occupies" or atom == "rel_occupies_regions":
        return "`occupies` with the track in `occupancy_observed`"
    prefix, _, rest = atom.partition("_")
    spell = surface.enumeration_spellings()
    if prefix == "ru" and rest in spell.get("RoadUserClass", set()):
        return "`users[].classes`"
    if prefix == "st" and rest in spell.get("StructureKind", set()):
        return f"`structures[].kind` = `{rest}`"
    if prefix == "dev" and rest in spell.get("DeviceKind", set()):
        return f"`devices[].kind` = `{rest}`"
    if atom == "ru_aggregate":
        return "`users[].classes` (the aggregate's classes through the reading)"
    atoms_src = (paths.CORE / "Vocab" / "Atoms.lean").read_text(encoding="utf-8")
    p = _field_path(atoms_src, atom, decoder_fields(_decode_source()))
    if p:
        return f"`{p}`" + (", or computed from the users' kinematics when `relations` leaves it out" if prefix == "rel" else "")
    if prefix == "rel":
        return "computed from the users' kinematics"
    if prefix == "st":
        return "computed from the users' positions, headings and extents and the structures' positions and boundaries"
    return "(see the trace format)"


def atoms_read(rule_json: dict, concepts: dict[str, dict]) -> list[str]:
    """Every atom (Lean name) the rule reads: its own leaves, and what the concepts and primitives
    it calls read, so a trace that leaves none of them out can be judged."""
    names: set[str] = set()

    def walk(x) -> None:
        if isinstance(x, dict):
            for k in ("atom", "measure", "derived", "quantity"):
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


def atoms_read_block(rule_json: dict, concepts: dict[str, dict], what: str = "rule") -> str:
    keys = decoder_keys(_decode_source())
    rows = "\n".join(f"- `{a}` — in the trace: {trace_place(a, keys)}" for a in atoms_read(rule_json, concepts))
    return (f"### The atoms this {what} reads\n\nEvery atom the {what} reads, including those its concepts and primitives "
            f"read, and where a trace writes it. A trace that leaves one out where the {what} reads it leaves the {what} "
            "unknown there.\n\n" + rows + "\n")


def trace_format_block() -> str:
    keys = "\n".join(f"- {rec}: " + ", ".join(rows) + "." for rec, rows in decoder_keys(_decode_source()).items())
    spell = surface.enumeration_spellings()
    rows = "\n".join(f"- {name}: {', '.join(sorted(vals))}" for name, vals in sorted(spell.items()))
    return (TRACE_CONVENTIONS + surface.lint_contract() + "\n" + keys
            + "\n\nEnumeration spellings (the values the decoder accepts):\n" + rows + "\n")


# ---------------------------------------------------------------------------------------------
# The reviewer's answer: a strict schema
# ---------------------------------------------------------------------------------------------
def _parameters_block(reading: Reading, names: set[str] | None = None) -> str:
    rows = [f"- `{p['name']}` = {p.get('value')} {p.get('unit')}: {p.get('convention', '')}" + (" (proposed, unreviewed)" if p.get("proposed") else "")
            for p in reading.data.get("params", []) if names is None or p["name"] in names]
    return "### Parameters\n\n" + ("\n".join(rows) or "(none)") + "\n"


def has_case(d: dict) -> bool:
    return "case" in d or "entities" in d or "at" in d


def behaviour_defects(answer: dict, law_text: str, binders: list[str], max_divergences: int | None = None) -> list[str]:
    """Defects of the answer as an answer: only the schema's keys; the verdict word; each
    divergence's kind, the reviewer's verdict for the law, a grounding over the rule's binders, a
    trace with scenes, a quote of the law that occurs in it, and either a case (`case`, `entities`,
    `at`) or the words of a situation the vocabulary cannot state (`unstatable`)."""
    errs = []
    extra = sorted(set(answer) - ANSWER_KEYS)
    if extra:
        errs.append(f"the answer carries keys outside the schema: {extra}")
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
    limit_defect = divergence_limit_defect(divs, max_divergences)
    if limit_defect:
        errs.append(limit_defect)
    for k, d in enumerate(divs, 1):
        errs += divergence_schema_defects(k, d, law_text, binders)
    return errs


def divergence_schema_defects(k: int, d, law_text: str, binders: list[str]) -> list[str]:
    """The schema defects of one divergence of a behaviour review."""
    if not isinstance(d, dict):
        return [f"divergence {k} is not an object"]
    errs = []
    extra = sorted(set(d) - DIVERGENCE_KEYS)
    if extra:
        errs.append(f"divergence {k}: keys outside the schema {extra} — a divergence carries evidence only, never a fix or a mapping")
    if d.get("kind") not in KINDS:
        errs.append(f"divergence {k}: kind must be one of {sorted(KINDS)}")
    if d.get("lawful_verdict") not in LAWFUL:
        errs.append(f"divergence {k}: lawful_verdict must be one of {sorted(LAWFUL)}")
    g = d.get("grounding")
    if not isinstance(g, dict) or set(g) != set(binders) or not all(isinstance(v, int) and not isinstance(v, bool) for v in g.values()):
        errs.append(f"divergence {k}: grounding must map exactly the binders {binders} to track ids")
    tr = d.get("trace")
    if not isinstance(tr, dict) or not isinstance(tr.get("scenes"), list) or not tr["scenes"]:
        errs.append(f"divergence {k}: trace must be an object with a non-empty `scenes` list")
    if not _in(d.get("law_words", ""), law_text):
        errs.append(f"divergence {k}: law_words is not verbatim from the law")
    if "unstatable" in d:
        if not _ws(d.get("unstatable")) or has_case(d):
            errs.append(f"divergence {k}: `unstatable` names the words the vocabulary cannot state, and then the divergence has no `case`, `entities` or `at`")
    else:
        if not (isinstance(d.get("case"), dict) or d.get("case") in ("tt", "ff")):
            errs.append(f"divergence {k}: `case` must be a formula in the case language")
        if not isinstance(d.get("entities"), dict):
            errs.append(f"divergence {k}: `entities` must be an object (empty when the case names only binders)")
        if not isinstance(d.get("at"), int) or isinstance(d.get("at"), bool):
            errs.append(f"divergence {k}: `at` must be a scene's timestamp in milliseconds")
    return errs


def divergence_limit_defect(divergences, max_divergences: int | None) -> str | None:
    """The one canonical check for the reviewer answer's divergence budget."""
    if isinstance(divergences, list) and max_divergences is not None and len(divergences) > max_divergences:
        return (f"the answer carries {len(divergences)} divergences; at most {max_divergences}: "
                "keep those the law's words decide most plainly")
    return None


def _certifiable(d: dict, binders: list[str]) -> bool:
    g, tr = d.get("grounding"), d.get("trace")
    return (isinstance(g, dict) and set(g) == set(binders) and all(isinstance(t, int) and not isinstance(t, bool) for t in g.values())
            and isinstance(tr, dict) and isinstance(tr.get("scenes"), list) and bool(tr["scenes"])
            and "unstatable" not in d and (isinstance(d.get("case"), dict) or d.get("case") in ("tt", "ff"))
            and isinstance(d.get("entities"), dict) and isinstance(d.get("at"), int) and not isinstance(d.get("at"), bool))


# ---------------------------------------------------------------------------------------------
# The Lean protocol: one program per certificate run, one `CERT` line per divergence it is given
# ---------------------------------------------------------------------------------------------
class HarnessFailure(RuntimeError):
    """The certificate program did not run, or its output breaks the protocol."""


def _cert_source(node_id: str, reading_json: Path, items: list[tuple[int, Path, Path, dict[str, int]]]) -> str:
    """A Lean program that prints, for each divergence, `CERT\\t<json>`: `Certificate.record` of its
    trace and case for the node's rule among the library's rules (concepts expanded), under the run's
    reading. A reading that does not decode stops the program."""
    rns = nodeid.rule_namespace(node_id)
    rows = ", ".join(
        f'({k}, {json.dumps(str(t.resolve()))}, {json.dumps(str(c.resolve()))}, [{", ".join(f"({json.dumps(b)}, {g})" for b, g in gr.items())}])'
        for k, t, c, gr in items)
    return f'''import TrafficSpec
import {nodeid.rule_module(node_id)}
open TrafficSpec Lean
def main : IO UInt32 := do
  let r := {rns}.rule
  let rules := ((allRules.filter (·.id != r.id)) ++ [r]).map (Concept.expandRule allConcepts)
  let r' := Concept.expandRule allConcepts r
  let ρtext ← IO.FS.readFile {json.dumps(str(reading_json.resolve()))}
  match Decode.parse Decode.reading ρtext with
  | .error e => do IO.println s!"READING_DECODE\\t{{e}}"; return 1
  | .ok ρ =>
    let items : List (Nat × String × String × List (String × Nat)) := [{rows}]
    for (k, tpath, cpath, grounding) in items do
      let tt ← IO.FS.readFile tpath
      let ct ← IO.FS.readFile cpath
      IO.println s!"CERT\\t{{(Certificate.record rules r' ρ k tt ct grounding).compress}}"
    return 0
'''


def parse_cert(output: str, expected: set[int]) -> dict[int, dict]:
    """The `CERT` records of a certificate run, by divergence number. A missing, unparseable or
    duplicate line, an unknown schema or an unexpected number breaks the protocol."""
    got: dict[int, dict] = {}
    for line in output.splitlines():
        if not line.startswith("CERT\t"):
            continue
        try:
            rec = json.loads(line[5:])
        except json.JSONDecodeError as e:
            raise HarnessFailure(f"an unparseable CERT line: {e}")
        if not isinstance(rec, dict) or rec.get("schema") != CERT_SCHEMA:
            raise HarnessFailure(f"a CERT line of an unknown schema: {str(rec)[:120]}")
        k = rec.get("divergence")
        if not isinstance(k, int) or k not in expected:
            raise HarnessFailure(f"a CERT line for an unexpected divergence {k!r}")
        if k in got:
            raise HarnessFailure(f"two CERT lines for divergence {k}")
        got[k] = rec
    missing = sorted(expected - set(got))
    if missing:
        raise HarnessFailure(f"no CERT line for divergence(s) {missing}")
    return got


def certify(run: Run, n: Node, divs: dict[int, dict], reading: Reading, out_dir: Path) -> dict[int, dict]:
    """Run the certificate program on every certifiable divergence; their records by number."""
    if not divs:
        return {}
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in list(out_dir.glob("trace_*.json")) + list(out_dir.glob("case_*.json")):
        stale.unlink()
    items = []
    for k, d in divs.items():
        t, c = out_dir / f"trace_{k}.json", out_dir / f"case_{k}.json"
        t.write_text(json.dumps(d["trace"], ensure_ascii=False, indent=1), encoding="utf-8")
        c.write_text(json.dumps({"case": d["case"], "entities": d["entities"], "at": d["at"]}, ensure_ascii=False, indent=1), encoding="utf-8")
        items.append((k, t, c, {b: int(x) for b, x in d["grounding"].items()}))
    reading_json = out_dir / "reading.json"
    reading_json.write_text(reading.lean_json(), encoding="utf-8")
    prog = out_dir / "certificate.lean"
    prog.write_text(_cert_source(n.id, reading_json, items), encoding="utf-8")
    ok, out = lean.lean_run(paths.LIBRARY, prog)
    (out_dir / "certificate.out").write_text(out, encoding="utf-8")
    if not ok:
        raise HarnessFailure(f"the certificate program did not run: {out[-600:]}")
    recs = parse_cert(out, set(divs))
    try:
        _diagnose(n, divs, recs, reading_json, out_dir / "diagnosis")
    except HarnessFailure as e:                              # an aid only: the certificate stands without it
        for c in recs.values():
            if (c.get("case_value") or {}).get("value") not in (None, "true"):
                c["diagnosis_error"] = str(e)[:300]
    return recs


def _conjuncts(f) -> list:
    """A case formula's conjuncts, an n-ary or nested `and` flattened."""
    if isinstance(f, dict) and set(f) == {"and"} and isinstance(f["and"], list):
        return [g for x in f["and"] for g in _conjuncts(x)]
    return [f]


def _diagnose(n: Node, divs: dict[int, dict], recs: dict[int, dict], reading_json: Path, out_dir: Path) -> None:
    """For every case that is evaluated but not true at `at`, which of its conjuncts is not, and,
    within a conjunct over every road user, which fact fails for which user: each part is run as a
    case of its own, by the same certificate program. Recorded on the record as `diagnosis`."""
    shutil.rmtree(out_dir, ignore_errors=True)               # the diagnosis of this certificate run only, never an earlier one's
    parts: list[tuple[int, int, dict, str]] = []          # (divergence, item number, case document, label)
    for k, c in recs.items():
        cv, d = c.get("case_value"), divs[k]
        if not isinstance(cv, dict) or cv.get("value") == "true" or c.get("case_check_errors") or c.get("case_decode_errors") \
                or c.get("trace_decode_errors"):
            continue
        cs = _conjuncts(d["case"])
        scene = next((sc for sc in d["trace"]["scenes"] if isinstance(sc, dict) and sc.get("t") == d["at"]), {})
        tracks = [u.get("track") for u in scene.get("users", []) if isinstance(u, dict) and isinstance(u.get("track"), int)]
        for i, f in enumerate(cs, 1):
            parts.append((k, len(parts), {"case": f, "entities": d["entities"], "at": d["at"]}, f"conjunct {i} of {len(cs)}"))
            if isinstance(f, dict) and isinstance(f.get("forall_user"), str):
                v, facts = f["forall_user"], _conjuncts(f.get("body"))
                for t in tracks:
                    for j, g in enumerate(facts, 1):
                        parts.append((k, len(parts), {"case": g, "entities": {**d["entities"], v: {"kind": "track", "id": t}}, "at": d["at"]},
                                      f"conjunct {i} of {len(cs)}, for `{v}` = track {t}: fact {j} of {len(facts)}"))
    if not parts:
        return
    out_dir.mkdir(parents=True, exist_ok=True)
    items = []
    for k in sorted({k for k, _i, _d, _l in parts}):
        (out_dir / f"trace_{k}.json").write_text(json.dumps(divs[k]["trace"], ensure_ascii=False), encoding="utf-8")
    for k, idx, doc, _label in parts:
        t, cf = out_dir / f"trace_{k}.json", out_dir / f"case_{idx}.json"
        cf.write_text(json.dumps(doc, ensure_ascii=False), encoding="utf-8")
        items.append((idx + 1, t, cf, {b: int(x) for b, x in divs[k]["grounding"].items()}))
    prog = out_dir / "certificate.lean"
    prog.write_text(_cert_source(n.id, reading_json, items), encoding="utf-8")
    ok, out = lean.lean_run(paths.LIBRARY, prog)
    (out_dir / "certificate.out").write_text(out, encoding="utf-8")
    if not ok:
        raise HarnessFailure(f"the certificate program did not run on the case's parts: {out[-600:]}")
    got = parse_cert(out, {idx + 1 for _k, idx, _d, _l in parts})
    failing = {(k, label) for k, idx, _doc, label in parts
               if (got[idx + 1].get("case_value") or {}).get("value") != "true" or got[idx + 1].get("case_check_errors")}
    for k, idx, doc, label in parts:
        r = got[idx + 1]
        v = r.get("case_value") or {}
        if (k, label) not in failing or any(k2 == k and l2.startswith(label + ",") for k2, l2 in failing):
            continue                                      # true, or a conjunct whose failing facts are named below it
        why = ", ".join(v.get("unknown_reasons") or [])
        recs[k].setdefault("diagnosis", []).append(
            f"{label} is {v.get('value', 'not evaluated')}" + (f" ({why})" if why else "") + f": {json.dumps(doc['case'], ensure_ascii=False)[:300]}")


#: Unknown reasons that are the trace's, not the rule's: an atom left out, a look-back sampled too
#: sparsely, a look-back the scenes do not cover, an identity gap. A longer or denser trace removes
#: each. For a divergence claiming the rule undecided, a look-back that no trace of ordinary length
#: covers is the claim itself, so there the truncated window stays the rule's.
def _trace_defect(reason: str, kind: str | None) -> bool:
    if reason.startswith(("absent_atom:", "sampling_gap:", "identity_gap:")):
        return True
    return kind != "rule_undecided" and reason.startswith("window_truncated:")


def _aggregate_unresolved_only(reasons: list[str]) -> bool:
    return bool(reasons) and all(r.startswith("aggregate_unresolved:") for r in reasons)


class _Need:
    """The history a verdict at an observation reads: seconds behind, observations behind (one per
    rise), metres of path behind and ahead, seconds ahead, and whether it reaches the trace's start
    or end, or holds a window whose length is not fixed."""
    def __init__(self, back=0, steps=0, ahead=0, path_back=0, path_ahead=0, to_start=False, to_end=False, unknown=False):
        from fractions import Fraction
        self.back, self.steps, self.ahead = Fraction(back), steps, Fraction(ahead)
        self.path_back, self.path_ahead = Fraction(path_back), Fraction(path_ahead)
        self.to_start, self.to_end, self.unknown = to_start, to_end, unknown

    def join(self, o: "_Need") -> "_Need":
        return _Need(max(self.back, o.back), max(self.steps, o.steps), max(self.ahead, o.ahead), max(self.path_back, o.path_back),
                     max(self.path_ahead, o.path_ahead), self.to_start or o.to_start, self.to_end or o.to_end, self.unknown or o.unknown)


def history_of(formulas: list, concepts: dict, reading: Reading) -> _Need:
    """The history the verdict at an observation reads, from the exported formulas: a window behind
    (`holds_for`, `at_last`, a primitive's time parameter) adds its length behind its body, a
    `rises` one observation, a window ahead (`within`, `until_within`) its length ahead; `since`,
    `count` and the elapsed measures read back to where their condition began, `always`,
    `eventually` and `until` to the trace's end. Siblings take the larger need, nested windows add
    up. A concept's body is read with its call's parameter values; a length the reading does not
    fix is marked unknown, never guessed."""
    from fractions import Fraction
    from ..lean import surface
    from ..model import units
    _m, prims = surface._dimensions()
    by_lean = {cid.replace(".", "_"): rec for cid, rec in (concepts or {}).items()}
    values = {}
    for p in reading.data.get("params", []):
        try:
            values[p["name"]] = units.to_core(p["value"], p["unit"])[1]
        except (KeyError, TypeError, ValueError):
            pass

    def length(t, env):
        if isinstance(t, dict) and isinstance(t.get("lit"), dict):
            return Fraction(int(t["lit"].get("num", 0)), int(t["lit"].get("den", 1)))
        if isinstance(t, dict) and "param" in t:
            return env.get(t["param"], values.get(t["param"]))
        return None

    def walk(x, env, depth=0) -> _Need:
        if depth > 40:
            return _Need(unknown=True)
        if isinstance(x, list):
            out = _Need()
            for y in x:
                out = out.join(walk(y, env, depth + 1))
            return out
        if not isinstance(x, dict):
            return _Need()
        for op in ("holds_for", "at_last", "within", "until_within"):
            if op in x:
                d = length(x.get("length"), env)
                inner = walk([x.get(k) for k in ("body", "when", "hold", "reach") if k in x], env, depth + 1)
                if d is None:
                    inner.unknown = True
                    return inner
                behind = op in ("holds_for", "at_last")
                if x[op] == "path":
                    if behind:
                        inner.path_back += d
                    else:
                        inner.path_ahead += d
                elif behind:
                    inner.back += d
                else:
                    inner.ahead += d
                return inner
        if "rises" in x:
            inner = walk(x["rises"], env, depth + 1)
            inner.steps += 1
            return inner
        for op in ("since", "count", "since_rise", "distance_while"):
            if op in x:
                inner = walk([v for k, v in x.items() if k != op] + [x[op]], env, depth + 1)
                inner.to_start = True
                return inner
        for op in ("always", "eventually", "until"):
            if op in x:
                inner = walk(x[op], env, depth + 1)
                inner.to_end = True
                return inner
        name = x.get("derived") or x.get("quantity")
        if isinstance(name, str):
            ps = x.get("params") or []
            if name in by_lean:
                rec = by_lean[name]
                formals = [q.get("name") for q in rec.get("params", [])]
                return walk(rec.get("body_json"), {f: length(t, env) for f, t in zip(formals, ps)}, depth + 1)
            out = _Need()
            dims = (prims.get(name) or (None, []))[1]
            for t, dim in zip(ps, dims):
                if dim == UNIT_DIMS["second"]:                 # a primitive's time parameter is a window behind
                    d = length(t, env)
                    out = out.join(_Need(back=d) if d is not None else _Need(unknown=True))
            return out
        if "rule" in x:
            return _Need(unknown=True)                         # a composed rule's own history is not read here
        return walk(list(x.values()), env, depth + 1)

    return walk(formulas, {})


def history_text(n: _Need) -> str:
    """The history as the reviewer is told it, or empty when the verdict reads only its own observation."""
    num = lambda q: f"{float(q):g}"
    parts = []
    if n.to_start:
        parts.append("back to where a condition it measures began, so the trace starts before that")
    elif n.back or n.steps:
        at = "`at`" if not n.steps else ("the observation before `at`" if n.steps == 1 else f"the {n.steps} observations before `at`")
        parts.append(f"up to {num(n.back)} s before {at}" if n.back else f"{at}")
    if n.path_back:
        parts.append(f"{num(n.path_back)} m of the subject's path behind it")
    if n.to_end:
        parts.append("to the end of the trace")
    elif n.ahead:
        parts.append(f"up to {num(n.ahead)} s after `at`")
    if n.path_ahead:
        parts.append(f"{num(n.path_ahead)} m of the subject's path ahead")
    if not parts and not n.unknown:
        return ""
    text = "the verdict at `at` reads " + ("; ".join(parts) if parts else "a window") + ": write the trace so that it covers all of it"
    return text + (" (a window whose length the reading does not fix is not counted)" if n.unknown else "")


def window_params(params: list[dict]) -> str:
    """The parameters of a rule that can set a look-back, with their values (a time or a length):
    what a trace's scenes must be dense and long enough for."""
    from ..model import units
    rows = [f"`{p['name']}` = {p.get('value')} {p.get('unit')}" for p in params
            if units.FACTORS.get(str(p.get("unit")), ("",))[0] in ("second", "metre")]
    return ", ".join(rows)


def _trace_remedy(reason: str, windows: str = "", history: str = "") -> str:
    """What the reviewer writes so the reason no longer arises; `windows` names the rule's
    parameters that can set a look-back, with their values, and `history` the history the verdict
    at `at` reads."""
    what = reason.split(":", 1)[1] if ":" in reason else reason
    sizes = f" (this rule's look-backs are set by {windows})" if windows else ""
    if reason == "absent_atom:rel_occupies":
        return "occupancy is unknown — list the track in `occupancy_observed` (or set it to `true`)"
    if reason.startswith("absent_atom:"):
        return f"`{what}` is not written — in the trace: {trace_place(what)}; write it in every scene the rule reads it"
    if reason.startswith("window_truncated:"):
        return (f"the look-back of `{what}` reaches before the first scene — {history}" if history else
                f"the look-back of `{what}` reaches before the first scene — add scenes covering its full length before `at`{sizes}")
    if reason.startswith("identity_gap:"):
        return f"track {what} is missing inside its own span — keep it in every scene between its first and last appearance"
    return (f"the look-back of `{what}` is sampled too sparsely: within the window behind `at`, consecutive scenes may be at "
            f"most half the window's length apart{sizes}")


def cert_defects(k: int, d: dict, c: dict, windows: str = "", history: str = "") -> list[str]:
    """Why a certified divergence is not admitted, as the reviewer is told: what kept it from being
    evaluated, then what its execution refuted."""
    return cert_unusable(k, d, c, windows, history) + cert_refutations(k, d, c)


def cert_unusable(k: int, d: dict, c: dict, windows: str = "", history: str = "") -> list[str]:
    """What kept a certified divergence from being evaluated; empty when the case holds and the
    rule's verdict at `at` is decided or undecided for a reason no trace removes."""
    head = f"divergence {k}"
    out = [f"{head}: the trace does not decode: {e}" for e in c.get("trace_decode_errors") or []]
    out += [f"{head}: the case does not decode: {e}" for e in c.get("case_decode_errors") or []]
    out += [f"{head}: trace check: {e}" for e in c.get("lint_errors") or []]
    out += [f"{head}: witness: {e}" for e in c.get("witness_errors") or []]
    out += [f"{head}: case: {e}" for e in c.get("case_check_errors") or []]
    cv = c.get("case_value")
    if isinstance(cv, dict) and cv.get("value") != "true":
        why = ", ".join(cv.get("unknown_reasons") or [])
        where = c.get("diagnosis") or []
        if not where and c.get("diagnosis_error"):
            where = ["(which of its facts fail could not be determined: the diagnosis did not run)"]
        out.append(f"{head}: the case is {cv.get('value')} at `at`" + (f" ({why})" if why else "")
                   + (": " + "; ".join(where[:6]) if where else "")
                   + " — state the facts that hold on the trace at that instant, or change the trace")
    rr = c.get("rule_result")
    if isinstance(rr, dict) and rr.get("verdict") == "unknown":
        reasons = rr.get("unknown_reasons") or []
        if reasons and not _aggregate_unresolved_only(reasons) and all(_trace_defect(r, d.get("kind")) for r in reasons):
            out.append(f"{head}: the rule's verdict at `at` is unknown only because the trace is incomplete: "
                       + "; ".join(sorted({_trace_remedy(r, windows, history) for r in reasons})))
    return out


def cert_refutations(k: int, d: dict, c: dict) -> list[str]:
    """What the execution of an evaluated case refuted: the rule gives at `at` the very verdict the
    reviewer claims for the law, or the two differ only as compliant and not applicable."""
    head, out = f"divergence {k}", []
    rr = c.get("rule_result")
    if isinstance(rr, dict) and rr.get("verdict") == d.get("lawful_verdict"):
        out.append(f"{head}: the rule gives at `at` the very verdict you claim for the law ({rr.get('verdict')}), so the case "
                   "shows no divergence — revise the trace and the case until it does, or drop the divergence")
    elif isinstance(rr, dict) and {rr.get("verdict"), d.get("lawful_verdict")} == {"compliant", "not_applicable"}:
        out.append(f"{head}: compliant and not applicable are both no violation, so the case shows no divergence in conduct")
    return out


# ---------------------------------------------------------------------------------------------
# Rendering a case for the judges
# ---------------------------------------------------------------------------------------------
def render_case(canonical, entities: dict, at: int, grounding: dict[str, int], glosses: dict[str, str],
                times: list[int] | None = None) -> str:
    """The mechanical rendering of a certified case: the variables it names, the instant, the
    formula as prose, glossed from the contracts of the atoms it reads, and then the same facts in
    time order (`render_formula.timeline`), whose only input from the trace is its timestamps
    (`times`, for the observation before `at`)."""
    names = [f"- `{b}`: a road user (track {t})" for b, t in sorted(grounding.items())]
    names += [f"- `{e}`: a {v.get('kind')} ({v.get('kind')} {v.get('id')})" for e, v in sorted(entities.items())]
    return ("Variables:\n" + "\n".join(names) + f"\n\nAt the observation at t = {at} ms, the following holds:\n"
            + render_formula.formula(canonical, glosses) + "\n\n" + render_formula.timeline(canonical, at, {}, times))


def _case_glosses(onto: ontology.Ontology, case_atoms: list[str]) -> dict[str, str]:
    return validate_phase.glosses_of(case_atoms, onto)


def case_id(law: str, d: dict, canonical) -> str:
    return _digest({"law": law, "trace": d.get("trace"), "case": canonical, "entities": d.get("entities"), "at": d.get("at")})


# ---------------------------------------------------------------------------------------------
# The judgment context and the two judges
# ---------------------------------------------------------------------------------------------
@dataclass
class Context:
    """Everything the judges of one node's review are shown, built once before replay."""
    law: corpus.Law
    seg: str
    definitions: list[dict]
    record: dict
    rendering: str
    rule_glosses: dict[str, str]
    params: list[dict]
    aggregates: list[dict]
    precedence_hash: str


def definitions_block(defs: list[dict]) -> str:
    if not defs:
        return "### Definitions that apply\n\n(none of the law's words has a posted definition that applies)\n"
    return "### Definitions that apply\n\n" + "\n".join(f"- `{d['id']}` — {_ws(d.get('text'))}" for d in defs) + "\n"


def params_block(params: list[dict]) -> str:
    if not params:
        return "### Parameters\n\n(the rule names no parameter)\n"
    rows = [f"- `{p['name']}` = {p.get('value')} {p.get('unit')} — convention: {_ws(p.get('convention'))}; "
            f"{'proposed, not reviewed by the operator' if p.get('proposed') else 'reviewed by the operator'}" for p in params]
    return ("### Parameters (operator-owned; shown only to explain the rule's executed verdict)\n\n" + "\n".join(rows) + "\n")


def aggregates_block(aggs: list[dict]) -> str:
    if not aggs:
        return "### Admitted aggregates\n\n(the rule reads no legal aggregate)\n"
    out = ["### Admitted aggregates (verified by the independent aggregate gate; not open to membership review)", ""]
    for a in aggs:
        out.append(f"- `{a['id']}` from `{a.get('definition')}`: included {', '.join(a.get('included', [])) or '(none)'}; "
                   f"unresolved {', '.join(a.get('unresolved', [])) or '(none)'}; every other class excluded"
                   + (f"; certificate {a['certificate_digest'][:16]}" if a.get("certificate_digest") else ""))
    return "\n".join(out) + "\n"


def _equivalent(a: str, b: str) -> bool:
    return a == b or {a, b} == {"compliant", "not_applicable"}


def stage_a_defects(a: dict, haystack: str) -> list[str]:
    errs = []
    extra, missing = sorted(set(a) - STAGE_A_KEYS), sorted(STAGE_A_KEYS - set(a))
    if extra or missing:
        errs.append(f"the answer has exactly the keys {sorted(STAGE_A_KEYS)}" + (f"; extra {extra}" if extra else "") + (f"; missing {missing}" if missing else ""))
    if a.get("verdict") not in STAGE_A_VERDICTS:
        errs.append(f"`verdict` is one of {sorted(STAGE_A_VERDICTS)}")
    if not isinstance(a.get("decisive"), bool):
        errs.append("`decisive` is true or false")
    if not _ws(a.get("law_words")) or not _in(a.get("law_words", ""), haystack):
        errs.append("`law_words` is a non-empty verbatim quote of the law or of a definition you were given")
    if not _ws(a.get("reason")):
        errs.append("`reason` is a non-empty sentence")
    return errs


def stage_a_prompt(ctx: Context, rendered_case: str, case_glosses: dict[str, str]) -> str:
    return render.render("judge_case.md", {
        "law": f"### The law\n\n**{ctx.law.id}** — {ctx.law.title}\n\n{ctx.law.text}\n",
        "definitions": definitions_block(ctx.definitions),
        "case": "### The case\n\n" + rendered_case + "\n",
        "contracts": validate_phase.contracts_table(case_glosses)})


def stage_a_digest(run: Run, prompt: str, ctx: Context) -> str:
    return _digest({"prompt": prompt, "model": run.opts.model, "effort": run.opts.judge_effort, "precedence": ctx.precedence_hash})


def run_stage_a(run: Run, ctx: Context, prompt: str, out_dir: Path, label: str) -> dict:
    hay = ctx.law.text + "\n" + "\n".join(_ws(d.get("text")) for d in ctx.definitions)
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=lambda a: stage_a_defects(a, hay),
                                           usage_label=f"{label}:{ctx.record.get('node_id', '')}")
    if answer is None and not errs:
        raise Deferred("stage_a", "dry run: stage A was not asked")
    if errs:
        raise Deferred("stage_a", f"stage A's answer stayed invalid: {'; '.join(errs)[:300]}")
    return answer


def available_outcomes(ctx: Context, sensitive: bool) -> set[str]:
    out = {"upheld", "dismissed_permitted_reading"}
    if any(not p.get("proposed") for p in ctx.params):
        out.add("dismissed_approved_parameter")
    if any(p.get("proposed") for p in ctx.params):
        out.add("parameter_question")
    if sensitive:
        out.add("verified_aggregate")
    return out


def stage_b_defects(a: dict, haystack: str, allowed: set[str]) -> list[str]:
    errs = []
    extra, missing = sorted(set(a) - STAGE_B_KEYS), sorted(STAGE_B_KEYS - set(a))
    if extra or missing:
        errs.append(f"the answer has exactly the keys {sorted(STAGE_B_KEYS)}" + (f"; extra {extra}" if extra else "") + (f"; missing {missing}" if missing else ""))
    if a.get("outcome") not in allowed:
        errs.append(f"`outcome` is one of the outcomes available for this item: {sorted(allowed)}")
    if not _ws(a.get("law_words")) or not _in(a.get("law_words", ""), haystack):
        errs.append("`law_words` is a non-empty verbatim quote of the law or of a definition you were given")
    if not _ws(a.get("reason")):
        errs.append("`reason` is a non-empty sentence")
    return errs


def stage_b_item(rendered_case: str, stage_a: dict, rule_verdict: dict, sensitive: bool, allowed: set[str]) -> str:
    why = ", ".join(rule_verdict.get("unknown_reasons") or [])
    return ("### The item\n\nA certified case (the facts hold on the trace at the instant named; the rule was run on it):\n\n"
            + rendered_case + "\n\n"
            f"- the law's verdict on the case (stage A): **{stage_a.get('verdict')}** — \"{_ws(stage_a.get('law_words'))}\": {_ws(stage_a.get('reason'))}\n"
            f"- the rule's verdict at that instant: **{rule_verdict.get('verdict')}**" + (f" ({why})" if why else "") + "\n"
            + ("- the harness established mechanically that forcing an admitted aggregate's membership of a track the rule reads "
               "makes the rule agree with the law: `verified_aggregate` is available\n" if sensitive else
               "- no aggregate membership the rule reads changes its verdict: `verified_aggregate` is not available\n")
            + f"- outcomes available for this item: {', '.join(f'`{o}`' for o in sorted(allowed))}\n")


def word_level_item(item: dict) -> str:
    return ("### The item (word-level: no trace can show it)\n\n"
            f"The reviewer claims that the words \"{_ws(item.get('words'))}\" of span {item.get('span')} exclude "
            f"{_ws(item.get('factor'))}, which the contract the record carries for them admits ({_ws(item.get('nearest'))}). "
            "Uphold it when the contract's own words admit what the law's words exclude and the difference changes where the "
            "law applies or what it requires; otherwise the words permit the carried contract.\n"
            f"- outcomes available for this item: {', '.join(f'`{o}`' for o in sorted(WORD_LEVEL_OUTCOMES))}\n")


def stage_b_prompt(run: Run, ctx: Context, item: str, contracts: dict[str, str]) -> str:
    return render.render("adjudicate.md", {
        "law_and_segmentation": f"### Law\n\n**{ctx.law.id}** — {ctx.law.title}\n\n{ctx.law.text}\n\nSpans:\n{ctx.seg}\n",
        "definitions": definitions_block(ctx.definitions),
        "record": "### Record\n\n```json\n" + json.dumps(ctx.record, ensure_ascii=False, indent=1) + "\n```\n",
        "rendered": "### Rendering\n\n" + ctx.rendering + "\n",
        "contracts": validate_phase.contracts_table(contracts),
        "parameters": params_block(ctx.params),
        "aggregates": aggregates_block(ctx.aggregates),
        "item": item,
        "precedents": precedents_block(run, f"law:{ctx.law.id}")})


def stage_b_digest(run: Run, prompt: str) -> str:
    return _digest({"prompt": prompt, "model": run.opts.model, "effort": run.opts.judge_effort})


def run_stage_b(run: Run, ctx: Context, prompt: str, allowed: set[str], out_dir: Path, label: str) -> dict:
    hay = ctx.law.text + "\n" + "\n".join(_ws(d.get("text")) for d in ctx.definitions)
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=lambda a: stage_b_defects(a, hay, allowed),
                                           usage_label=f"{label}:{ctx.record.get('node_id', '')}")
    if answer is None and not errs:
        raise Deferred("stage_b", "dry run: stage B was not asked")
    if errs:
        raise Deferred("stage_b", f"stage B's answer stayed invalid: {'; '.join(errs)[:300]}")
    return answer


def aggregate_sensitive(c: dict, stage_a_verdict: str, ctx: Context) -> bool:
    """Whether forcing one admitted aggregate's membership of one track, away from a decided value,
    makes the rule agree with stage A."""
    admitted = {a["id"] for a in ctx.aggregates}
    for o in c.get("sensitivity_overrides") or []:
        if o.get("aggregate_id") in admitted and o.get("original") in ("true", "false") \
                and (o.get("original") == "true") != bool(o.get("override")) and _equivalent(o.get("rule_verdict", ""), stage_a_verdict):
            return True
    return False


# ---------------------------------------------------------------------------------------------
# Rulings: append-only, each executable case under a stable id, the latest row of a case effective
# ---------------------------------------------------------------------------------------------
_RULINGS_LOCK = threading.Lock()


class RulingsError(jsonl.DataIntegrityError):
    """`rulings.jsonl` breaks the supersession rule: a row superseding one that does not exist, a
    cycle, or two rows superseding the same row. The run stops; the file is kept as it is."""
    def __init__(self, why: str):
        super().__init__(Path("rulings.jsonl"), None, why)


def _rulings_file(run: Run) -> Path:
    return run.dir / "rulings.jsonl"


def _all_rows(run: Run) -> list[dict]:
    """Every row, read strictly: a line that does not parse stops the run (`DataIntegrityError`)."""
    return jsonl.read_strict(_rulings_file(run))


def effective_rows(rows: list[dict]) -> list[dict]:
    """Every row that no later row supersedes, in file order; rows without a `ruling_id` (earlier
    runs' rows) stand as they are. A broken chain is an error, never a guess."""
    by_id = {r["ruling_id"]: r for r in rows if r.get("ruling_id")}
    children: dict[str, list[str]] = {}
    for r in rows:
        s = r.get("supersedes")
        if s:
            if s not in by_id:
                raise RulingsError(f"ruling {r.get('ruling_id')} supersedes {s}, which does not exist")
            children.setdefault(s, []).append(r.get("ruling_id"))
    two = [s for s, cs in children.items() if len(cs) > 1]
    if two:
        raise RulingsError(f"ruling(s) {two} are superseded twice")
    for r in rows:                                          # a chain that returns to itself
        seen, cur = set(), r
        while cur is not None and cur.get("supersedes"):
            if cur.get("ruling_id") in seen:
                raise RulingsError(f"a supersession cycle through {cur.get('ruling_id')}")
            seen.add(cur.get("ruling_id"))
            cur = by_id.get(cur["supersedes"])
    return [r for r in rows if not (r.get("ruling_id") and r["ruling_id"] in children) and r.get("ruling") != "retired"]


def append_ruling(run: Run, row: dict) -> dict:
    """Append a row with a fresh `ruling_id`; a case already ruled is superseded by it."""
    with _RULINGS_LOCK:
        row = dict(row)
        row["ruling_id"] = _digest({"row": row, "n": len(_all_rows(run))})[:20]
        if row.get("case_id"):
            prev = next((r for r in effective_rows(_all_rows(run)) if r.get("case_id") == row["case_id"]), None)
            row["supersedes"] = prev.get("ruling_id") if prev else None
        jsonl.append_atomic(_rulings_file(run), row)
        return row


def precedents_block(run: Run, key: str) -> str:
    """The effective rulings under `key` (a law, or a concept), most recent first: what was decided
    before, and why, so a situation decided once is decided alike."""
    rows = [r for r in effective_rows(_all_rows(run)) if r.get("key") == key and r.get("ruling") != "advisory"]
    if not rows:
        return "### Earlier rulings\n\n(none)\n"
    out = ["### Earlier rulings (most recent first)", ""]
    for r in reversed(rows[-30:]):
        out.append(f"- iteration {r.get('iteration')}, `{r.get('subject')}`: {r.get('item')} — **{r.get('ruling')}**: {r.get('reason')}")
    return "\n".join(out) + "\n"


#: The states of an upheld case that keep it an obligation: the current rule still diverges from the
#: law's verdict (`None` on a fresh upheld row, or `open`), or gives it (`satisfied`).
OBLIGATIONS = {None, "open", "satisfied"}


def upheld_rows(run: Run, laws: set[str]) -> list[dict]:
    """The obligations on these laws' nodes: effective rulings upheld on a certified case, open or
    satisfied, oldest first. A case leaves only when it is invalidated (it can no longer be
    evaluated), re-adjudicated (a judge's changed input no longer upholds it) or retired."""
    keys = {f"law:{law}" for law in laws}
    return [r for r in effective_rows(_all_rows(run))
            if r.get("key") in keys and r.get("ruling") == "upheld" and r.get("schema") == CASE_SCHEMA
            and r.get("obligation") in OBLIGATIONS]


def upheld_block(run: Run, laws: set[str]) -> str:
    """The certified cases earlier reviews upheld against these laws' nodes, for a planning
    session, rendered as the judges saw them."""
    rows = upheld_rows(run, laws)
    if not rows:
        return "## Situations decided against earlier records\n\n(none)\n"
    out = ["## Situations decided against earlier records", "",
           "Each is a certified case: its facts hold on a trace at the instant named, the law's verdict on it was decided by a "
           "judge blind to the rule, and an earlier rule of the node named gave another verdict there. The harness runs every "
           "later rule of that node on it before any review. Treat each as a regression obligation: the repaired rule must give "
           "the law's verdict on it. It is not a mapping instruction. One marked satisfied is one an earlier repair already "
           "met: the repaired rule must keep giving the law's verdict there.", ""]
    for r in rows:
        a = r.get("stage_a") or {}
        b = r.get("stage_b") or {}
        state = "satisfied by the current rule" if r.get("obligation") == "satisfied" else "open"
        out.append(f"- `{r.get('subject')}` (iteration {r.get('iteration')}, {state}):\n\n  " + _ws(r.get("case_rendered")).replace(" - ", "\n  - ")
                   + f"\n\n  the law: **{a.get('verdict')}** (\"{_ws(a.get('law_words'))[:200]}\"); the rule then: "
                   f"{(r.get('rule_result') or {}).get('verdict')}; upheld because: {_ws(b.get('reason'))[:300]}\n"
                   f"  reviewer's note (not verified): {_ws(r.get('situation'))[:240]}")
    return "\n".join(out) + "\n"


def quoted_spans(n: Node, law_text: str, quote: str) -> str:
    """The substantive spans of the node whose words the quote covers, as `s1,s4` (`-` when the
    quote is not found): what a divergence objects to, so a repeat is the same objection to the
    same words."""
    lt = _norm(law_text)
    frags = [f for f in (_norm(x).strip(" .,;:") for x in re.split(r"\[\s*(?:…|\.\.\.)\s*\]|…|\.\.\.", str(quote or ""))) if f]
    covered, pos = [], 0
    for f in frags:
        a = lt.find(f, pos)
        if a < 0:
            return "-"
        covered.append((a, a + len(f))); pos = a + len(f)
    ids = []
    for s in n.get("segmentation", []):
        t = _norm(s.get("text"))
        i = lt.find(t) if t and s.get("role") != "boilerplate" else -1
        if i >= 0 and any(i < b and i + len(t) > a for a, b in covered):
            ids.append(str(s.get("id")))
    return ",".join(ids) or "-"


# ---------------------------------------------------------------------------------------------
# Judging one certified divergence (fresh or replayed)
# ---------------------------------------------------------------------------------------------
@dataclass
class Judged:
    """The route of one certified divergence: `upheld`, a stage B dismissal or question, or an
    advisory route (`rule_agrees`, `stage_a_undetermined`, `aggregate_unresolved`, `not_admissible`)."""
    route: str
    row: dict
    line: str
    key: str = ""
    question: str = ""


def judge_divergence(run: Run, n: Node, ctx: Context, onto: ontology.Ontology, d: dict, c: dict, out_dir: Path, label: str,
                     previous: dict | None = None) -> Judged:
    """Stage A, the comparison, the sensitivity and stage B for one admitted divergence. A previous
    ruling's judge outputs are reused when that judge's digest is unchanged. Raises `Deferred` when
    a judge's answer stays invalid."""
    canonical = c.get("canonical_case")
    glosses_case = _case_glosses(onto, c.get("case_atoms") or [])
    times = [sc.get("t") for sc in ((d.get("trace") or {}).get("scenes") or []) if isinstance(sc, dict) and isinstance(sc.get("t"), int)]
    rendered = render_case(canonical, d.get("entities") or {}, d.get("at"), d.get("grounding") or {}, glosses_case, times)
    cid = case_id(n.law, d, canonical)
    rule = c.get("rule_result") or {}
    base = {"schema": CASE_SCHEMA, "key": f"law:{n.law}", "subject": n.id, "iteration": run.iteration, "case_id": cid,
            "kind": d.get("kind"), "situation": _ws(d.get("situation"))[:600], "law_words": d.get("law_words"),
            "lawful_verdict": d.get("lawful_verdict"), "grounding": d.get("grounding"), "trace": d.get("trace"),
            "case": canonical, "entities": d.get("entities"), "at": d.get("at"), "case_rendered": rendered, "rule_result": rule}
    head = f"case on `{n.id}` at t={d.get('at')} — rule: {rule.get('verdict')}"
    if rule.get("verdict") == "unknown" and _aggregate_unresolved_only(rule.get("unknown_reasons") or []):
        row = {**base, "route": "aggregate_unresolved", "ruling": "advisory", "reason": "the rule is unknown only for an unresolved aggregate membership",
               "item": head, "stage_a": None, "stageA_digest": None, "stage_b": None, "stageB_digest": None}
        return Judged("aggregate_unresolved", row, f"{head}: unknown only for {', '.join(rule.get('unknown_reasons'))}; the admitted "
                      "aggregate leaves that membership unresolved, which no repair of the rule can decide")
    a_prompt = stage_a_prompt(ctx, rendered, glosses_case)
    a_dig = stage_a_digest(run, a_prompt, ctx)
    if previous and previous.get("stageA_digest") == a_dig and previous.get("stage_a"):
        stage_a = previous["stage_a"]
    else:
        stage_a = run_stage_a(run, ctx, a_prompt, out_dir, f"{label}_stage_a")
    base = {**base, "stage_a": stage_a, "stageA_digest": a_dig}
    line = f"{head}; the law (stage A): {stage_a.get('verdict')} — \"{_ws(stage_a.get('law_words'))[:160]}\""
    if stage_a.get("verdict") == "undetermined" or not stage_a.get("decisive"):
        row = {**base, "route": "stage_a_undetermined", "ruling": "advisory", "reason": _ws(stage_a.get("reason")), "item": line,
               "stage_b": None, "stageB_digest": None}
        return Judged("stage_a_undetermined", row, f"{line}: the case does not decide the law's verdict")
    if rule.get("verdict") != "unknown" and _equivalent(rule.get("verdict", ""), stage_a.get("verdict", "")):
        row = {**base, "route": "rule_agrees", "ruling": "advisory", "reason": "the rule gives the law's verdict on the case", "item": line,
               "stage_b": None, "stageB_digest": None}
        return Judged("rule_agrees", row, f"{line}: the rule agrees with the law on the case")
    sensitive = aggregate_sensitive(c, stage_a.get("verdict", ""), ctx)
    allowed = available_outcomes(ctx, sensitive)
    contracts = {**ctx.rule_glosses, **glosses_case}
    b_prompt = stage_b_prompt(run, ctx, stage_b_item(rendered, stage_a, rule, sensitive, allowed), contracts)
    b_dig = stage_b_digest(run, b_prompt)
    if previous and previous.get("stageB_digest") == b_dig and previous.get("stage_b"):
        stage_b = previous["stage_b"]
    else:
        stage_b = run_stage_b(run, ctx, b_prompt, allowed, out_dir, f"{label}_stage_b")
    outcome = stage_b["outcome"]
    key = f"{d.get('kind')}:{quoted_spans(n, ctx.law.text, stage_a.get('law_words'))}"
    row = {**base, "route": outcome, "ruling": outcome, "sensitive": sensitive, "stage_b": stage_b, "stageB_digest": b_dig,
           "reason": _ws(stage_b.get("reason")), "item": line, "outcome": key,
           "certificate_digests": [a.get("certificate_digest") for a in ctx.aggregates if a.get("certificate_digest")] if outcome == "verified_aggregate" else []}
    question = ""
    if outcome == "parameter_question":
        names = ", ".join(f"`{x}`" for x in questioned_parameters(ctx.params, stage_b.get("reason", "")))
        question = (f"`{n.law}` ({n.id}): the rule's verdict on a certified case turns on the value of {names}, which you have not "
                    f"reviewed — {_ws(stage_b.get('reason'))[:300]}")
    return Judged(outcome, row, f"{line}; stage B: {outcome} — {_ws(stage_b.get('reason'))[:200]}", key=key, question=question)


def judge_word_level(run: Run, n: Node, ctx: Context, item: dict, out_dir: Path, label: str) -> Judged:
    prompt = stage_b_prompt(run, ctx, word_level_item(item), ctx.rule_glosses)
    b = run_stage_b(run, ctx, prompt, WORD_LEVEL_OUTCOMES, out_dir, label)
    line = (f"word-level: span {item.get('span')} — \"{_ws(item.get('words'))}\" is carried by a broader contract "
            f"({_ws(item.get('nearest'))[:160]}); the words exclude {_ws(item.get('factor'))[:160]}: file a gap on this span")
    key = f"broader_contract:{item.get('span')}"
    row = {"schema": WORD_LEVEL_SCHEMA, "label": "word_level", "key": f"law:{n.law}", "subject": n.id, "iteration": run.iteration,
           "item": line, "ruling": b["outcome"], "reason": _ws(b.get("reason")), "stage_b": b, "stageB_digest": stage_b_digest(run, prompt),
           "outcome": key}
    return Judged(b["outcome"], row, f"{line} — stage B: {b['outcome']}: {_ws(b.get('reason'))[:200]}", key=key)


# ---------------------------------------------------------------------------------------------
# Replay: the upheld cases of this node, re-judged against the current rule
# ---------------------------------------------------------------------------------------------
def replay_upheld(run: Run, n: Node, ctx: Context, onto: ontology.Ontology, reading: Reading,
                  out_dir: Path, pending: list | None = None, questions: list | None = None) -> tuple[list[str], list[str], list[str]]:
    """(reasons and keys of the cases still decided otherwise, notes). Each obligation of this node
    id (an upheld case, open or satisfied) is certified again under the current Core, rule and
    reading, and judged again where a judge's input changed. Validity is kept apart from
    satisfaction:
    - a case that can no longer be evaluated, for a trace or case reason, is `invalidated`: it leaves
      the obligations, and a note starting "obligation invalidated" goes to the operator;
    - a case still upheld against the rule stays `open` (the node is returned), whether the law's
      verdict is the one recorded or a newly judged one;
    - a case on which the rule gives the recorded law's verdict stays an obligation, `satisfied`;
    - any other judgment (the law's verdict changed and the rule now agrees with it, stage A
      undetermined, stage B no longer upholding it) is `re-adjudicated`: it leaves the obligations.
    A row is appended only when the state or a judge's digest changes, so a replay of an unchanged
    rule, and a resumed run, add none. Only a reason in the case or its trace invalidates (it does
    not decode, fails the trace or witness check, or the case is not true): a rule whose verdict is
    unknown on the trace is judged like any other mismatch. A case that stage B now rules a
    parameter question keeps its state, and its question is added to `questions`, as a fresh
    review asks it. With `pending`, the rows are collected there instead of appended: the caller
    records them only when the review reaches its outcome, so a review that defers, pauses or never
    runs (and whose rule is rolled back) changes no obligation. Raises `Deferred` when a judge's
    answer stays invalid or the certificate program fails."""
    rows = [r for r in upheld_rows(run, {n.law}) if r.get("subject") == n.id]
    if not rows:
        return [], [], []
    binders = [b["name"] for b in n.get("binders", [])]
    notes, divs, by_k = [], {}, {}
    for r in rows:
        g = r.get("grounding") if isinstance(r.get("grounding"), dict) else {}
        if set(g) != set(binders) and len(g) == 1 and len(binders) == 1:
            g = {binders[0]: next(iter(g.values()))}
        if set(g) != set(binders):
            notes.append(f"upheld case of iteration {r.get('iteration')} not replayed on `{n.id}`: its grounding names {sorted(g)}, "
                         f"the node's binders are {binders}")
            continue
        k = len(divs) + 1
        divs[k] = {"kind": r.get("kind"), "situation": r.get("situation"), "law_words": r.get("law_words"),
                   "lawful_verdict": r.get("lawful_verdict"), "grounding": g, "trace": r.get("trace"),
                   "case": r.get("case"), "entities": r.get("entities") or {}, "at": r.get("at")}
        by_k[k] = r
    if not divs:
        return [], [], notes
    try:
        certs = certify(run, n, divs, reading, out_dir / "replay")
    except HarnessFailure as e:
        raise Deferred("certificate", f"replay: {e}")
    reasons, keys = [], []
    record = pending.append if pending is not None else (lambda row: append_ruling(run, row))
    case_fields = ("schema", "key", "subject", "case_id", "kind", "situation", "law_words", "lawful_verdict",
                   "grounding", "trace", "case", "entities", "at", "case_rendered", "item", "outcome")
    for k, d in divs.items():
        r, c = by_k[k], certs[k]
        cv = c.get("case_value") or {}
        unusable = ([f"the trace does not decode: {e}" for e in c.get("trace_decode_errors") or []]
                    + [f"the case does not decode: {e}" for e in c.get("case_decode_errors") or []]
                    + [f"trace check: {e}" for e in c.get("lint_errors") or []] + [f"witness: {e}" for e in c.get("witness_errors") or []]
                    + [f"case: {e}" for e in c.get("case_check_errors") or []]
                    + ([f"the case is {cv.get('value')} on its trace at `at`"] if cv and cv.get("value") != "true" else []))
        if unusable:
            row = {**{x: r.get(x) for x in case_fields}, "iteration": run.iteration, "route": "invalidated", "ruling": "advisory",
                   "obligation": "invalidated", "rule_result": c.get("rule_result"), "reason": "; ".join(unusable)[:600],
                   "stage_a": r.get("stage_a"), "stageA_digest": r.get("stageA_digest"), "stage_b": r.get("stage_b"),
                   "stageB_digest": r.get("stageB_digest")}
            record(row)
            notes.append(f"obligation invalidated: the upheld case of iteration {r.get('iteration')} on `{n.id}` can no longer be "
                         f"evaluated — {row['reason'][:240]}")
            continue
        j = judge_divergence(run, n, ctx, onto, d, c, out_dir / "replay", f"replay_{k}", previous=r)
        law_then = (r.get("stage_a") or {}).get("verdict")
        law_now = (j.row.get("stage_a") or {}).get("verdict")
        same_law = law_now is not None and law_then is not None and _equivalent(law_now, law_then) \
            and j.route not in ("stage_a_undetermined", "aggregate_unresolved")
        if same_law and j.route == "rule_agrees":
            row = {**{x: r.get(x) for x in case_fields}, "iteration": run.iteration, "route": "upheld", "ruling": "upheld",
                   "obligation": "satisfied", "rule_result": c.get("rule_result"), "reason": r.get("reason"),
                   "stage_a": j.row.get("stage_a"), "stageA_digest": j.row.get("stageA_digest"), "stage_b": r.get("stage_b"),
                   "stageB_digest": r.get("stageB_digest")}
            if r.get("obligation") != "satisfied" or row["stageA_digest"] != r.get("stageA_digest"):
                record(row)
            notes.append(f"upheld case of iteration {r.get('iteration')} is satisfied by this rule of `{n.id}`; it stays an obligation")
        elif j.route == "upheld":                         # still decided otherwise: by the same law's verdict, or a newly judged one
            row = {**j.row, "case_id": r.get("case_id"), "obligation": "open"}
            if (r.get("obligation") or "open") != "open" or row.get("stageA_digest") != r.get("stageA_digest") \
                    or row.get("stageB_digest") != r.get("stageB_digest"):
                record(row)
            reasons.append(f"upheld at iteration {r.get('iteration')} and still decided otherwise by this rule: {j.line}")
            keys.append(r.get("outcome") or j.key)
        elif j.route == "parameter_question":            # the operator's question: the case keeps its state until it is answered
            if questions is not None and j.question:
                questions.append(j.question)
            notes.append(f"upheld case of iteration {r.get('iteration')} on `{n.id}` now turns on an unreviewed parameter: "
                         f"it stays an obligation, and the question is put to the operator — {j.line[:240]}")
        else:
            record({**j.row, "case_id": r.get("case_id"), "obligation": "re-adjudicated"})
            notes.append(f"upheld case of iteration {r.get('iteration')} re-adjudicated on `{n.id}` ({j.route}): it is no longer an "
                         f"obligation — {j.line[:240]}")
    return reasons, keys, notes


# ---------------------------------------------------------------------------------------------
# The review of a node
# ---------------------------------------------------------------------------------------------
def rule_aggregate_ids(rule_json: dict | None) -> list[str]:
    out: list[str] = []

    def walk(x) -> None:
        if isinstance(x, dict):
            if x.get("atom") == "ru_aggregate" and isinstance(x.get("args"), list) and len(x["args"]) == 2 and isinstance(x["args"][1], dict):
                lit = x["args"][1].get("lit")
                if isinstance(lit, str) and lit not in out:
                    out.append(lit)
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(rule_json or {})
    return out


def build_context(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, reading: Reading, rule_json: dict,
                  coder_narrowings: list[dict]) -> Context:
    from ..model import definitions as definitions_mod
    from . import aggregate as aggregate_phase
    glosses = validate_phase.glosses_for(n, onto, run)
    rendering = render_formula.render_rule(rule_json, glosses)
    record = {k: v for k, v in n.raw.items() if k not in ("segmentation", "scenarios")}
    record["narrowings_by_the_coder"] = coder_narrowings
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in n.get("segmentation", []))
    params = [p for p in reading.data.get("params", []) if p["name"] in set(n.params())]
    certs = aggregate_phase.certificate_digests(run)
    aggs = []
    for aid in rule_aggregate_ids(rule_json):
        a = reading.aggregate(aid)
        if a is not None:
            aggs.append({**a, "certificate_digest": certs.get(aid)})
    return Context(law, seg, definitions_mod.applicable(run, law.id), record, rendering, glosses, params, aggs,
                   definitions_mod.precedence_hash(run))


def review_behaviour(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, reading: Reading, rule_json: dict | None,
                     coder_narrowings: list[dict], out_dir: Path) -> ReviewOutcome:
    """The review of a coded node. The judgment context is built first; the node's upheld cases are
    replayed under it (a case still upheld returns the node without a reviewer; a judge that stays
    invalid defers the law); then the reviewer is asked, its divergences certified, and the
    admitted ones judged. `returned` when an item is upheld; else `deferred` (stage `reviewer`) when
    a challenge could not be evaluated; else `proceed_with_question` or `accepted`. A case whose
    execution refutes the reviewer is an advisory. Raises `SessionUnavailable` when a session could
    not be launched."""
    if not enabled(run):
        if run.opts.dry_run:
            return ReviewOutcome("accepted", advisories=["dry run"])
        raise RuntimeError("a reviewer_model is required for a rule review")
    if rule_json is None:
        return ReviewOutcome("returned", reasons=["the gate exported no rule to review"])
    try:
        ctx = build_context(run, n, law, onto, reading, rule_json, coder_narrowings)
    except render_formula.Unrendered as e:
        raise session.SessionUnavailable(f"the renderer has no phrasing for the {e} (harness/lean/render_formula.py)") from e
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "rendered_rule.md").write_text(ctx.rendering, encoding="utf-8")
    try:
        pending, replay_questions = [], []
        replayed, replay_keys, replay_notes = replay_upheld(run, n, ctx, onto, reading, out_dir, pending, replay_questions)
    except Deferred as e:
        return ReviewOutcome("deferred", reasons=[f"replay of the upheld cases: {e}"], defer_stage=e.stage)
    def commit() -> None:                                 # the replay's states, recorded only with a final outcome
        for row in pending:
            append_ruling(run, row)
    if replayed:
        commit()
        _write_outcome(out_dir, {"replayed": replayed, "notes": replay_notes})
        return ReviewOutcome("returned", reasons=replayed, advisories=replay_notes + [f"question: {q}" for q in replay_questions],
                             keys=sorted(set(replay_keys)))
    binders = [b["name"] for b in n.get("binders", [])]
    rj = rule_json or {}
    history = history_text(history_of([b.get("cls") for b in rj.get("binders", [])] + [rj.get("applicability"), rj.get("obligation")],
                                      run.all_concepts(), reading))
    blocks = {
        "law_and_segmentation": f"### Law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans:\n{ctx.seg}\n",
        "record": "### Record\n\n```json\n" + json.dumps(ctx.record, ensure_ascii=False, indent=1) + "\n```\n",
        "rendered": "### Rendering\n\n" + ctx.rendering + "\n",
        "atoms_read": atoms_read_block(rule_json, run.all_concepts()),
        "contracts": validate_phase.contracts_table(ctx.rule_glosses) + aggregates_block(ctx.aggregates),
        "parameters": _parameters_block(reading, set(n.params())) + (f"\nHistory: {history}.\n" if history else ""),
        "trace_format": trace_format_block(),
        "case_language": surface.case_language(),
        "case_vocabulary": surface.case_vocabulary(onto),
        "max_divergences": str(run.opts.max_divergences),
        "review_checks": str(run.opts.review_checks),
        "review_submissions": str(run.opts.review_submissions),
    }
    prompt = render.render("review_code.md", blocks)
    windows = window_params([p for p in reading.data.get("params", []) if p.get("name") in set(n.params())])
    cap = run.opts.max_divergences
    n_passes = max(1, int(run.opts.review_passes or 1))
    passes = [BehaviourTools(run, n, law, reading, binders, windows, history, out_dir / f"pass{k}",
                             run.opts.review_checks, run.opts.review_submissions)
              for k in range(1, n_passes + 1)]
    (out_dir / "review_behaviour_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return ReviewOutcome("accepted", advisories=["review skipped (dry run)"])
    try:
        run_passes(run, n, prompt, out_dir, passes)
        answer, certs, pass_notes, pass_summary, errs = join_passes(passes, law, binders, cap)
    except HarnessFailure as e:
        return ReviewOutcome("deferred", reasons=[f"the certificate harness: {e}"], defer_stage="certificate")
    attempts = [a for t in passes for a in t.attempts]
    if answer is None:
        return ReviewOutcome("deferred", reasons=["behaviour review: no pass submitted a usable answer — " + "; ".join(pass_notes)[:600]],
                             defer_stage="reviewer")
    divs = answer.get("divergences") or []
    advisories = list(replay_notes) + [f"behaviour review, {x}" for x in pass_notes] + [str(x) for x in answer.get("advisories", [])]
    for g in gap_candidate_lines(answer.get("gap_candidates", [])):
        advisories.append(g)
    # a challenge the harness could not evaluate (its schema, its certificate, no rule verdict)
    # leaves the review undecided: without an upheld item it defers the law, never accepts it
    upheld, keys, questions, judged_rows, unusable, status_of = [], [], list(replay_questions), [], [], {}
    if answer.get("verdict") == "return" and not divs:
        unusable.append("the reviewer returned the rule with no divergence")
    try:
        for k, d in enumerate(divs, 1):
            status_of[k] = "not evaluated, unverified"
            schema = divergence_schema_defects(k, d, law.text, binders)
            if not schema and "unstatable" in d:
                advisories.append(f"gap candidate: divergence {k} is unstatable in the vocabulary — \"{_ws(d.get('unstatable'))[:240]}\" "
                                  f"(law: \"{_ws(d.get('law_words'))[:160]}\")")
                continue
            c = certs.get(k)
            bad = schema or (cert_unusable(k, d, c, windows, history) if c is not None else [f"divergence {k}: not certified"])
            if not bad and c.get("rule_result") is None:
                bad = [f"divergence {k}: the certificate printed no verdict of the rule"]
            if bad:
                unusable.append("; ".join(bad)[:600])
                continue
            refuted = cert_refutations(k, d, c)
            if refuted:
                status_of[k] = "refuted by execution"
                advisories.append(f"divergence {k}: refuted by execution — " + "; ".join(refuted)[:400])
                continue
            j = judge_divergence(run, n, ctx, onto, d, c, out_dir, f"divergence_{k}")
            status_of[k] = f"certified, judged {j.route}"
            judged_rows.append(j)
            if j.route == "upheld":
                upheld.append(j.line); keys.append(j.key)
            elif j.route == "parameter_question":
                questions.append(j.question); advisories.append(j.line)
            else:
                advisories.append(j.line)
        for i, item in enumerate(_broader_contract_items(answer.get("gap_candidates", [])), 1):
            j = judge_word_level(run, n, ctx, item, out_dir, f"word_level_{i}")
            judged_rows.append(j)
            if j.route == "upheld":
                upheld.append(j.line); keys.append(j.key)
            else:
                advisories.append(j.line)
    except Deferred as e:
        for j in judged_rows:                                # what was decided before the failure stands
            append_ruling(run, j.row)
        return ReviewOutcome("deferred", reasons=[str(e.why)], advisories=advisories, defer_stage=e.stage)
    for j in judged_rows:
        append_ruling(run, j.row)
    notes = param_notes(n, reading, answer, status_of, run.iteration)
    _write_outcome(out_dir, {"reviewer_verdict": answer.get("verdict"), "upheld": upheld, "questions": questions,
                             "unusable": unusable, "advisories": advisories, "schema_defects": errs, "attempts": attempts,
                             "param_notes": notes, "passes": pass_summary})
    if not unusable or upheld:
        commit()
    if upheld:
        return ReviewOutcome("returned", reasons=upheld, advisories=advisories, keys=sorted(set(keys)), param_notes=notes)
    if unusable:
        return ReviewOutcome("deferred", reasons=[f"behaviour review: {len(unusable)} challenge(s) could not be evaluated: " + " | ".join(unusable)[:900]],
                             advisories=advisories, defer_stage="reviewer", param_notes=notes)
    if questions:
        return ReviewOutcome("proceed_with_question", advisories=advisories, questions=questions, param_notes=notes)
    return ReviewOutcome("accepted", advisories=advisories, param_notes=notes)


def run_passes(run: Run, n: Node, prompt: str, out_dir: Path, passes: list) -> None:
    """The independent reviewer sessions of one rule review, run at the same time: the same prompt,
    each its own tool state, evidence directory (`pass<k>/`) and stream (`review_behaviour_p<k>`).
    A budget pause in either pauses the run and a session that never ran makes the review one that
    never ran, as for a single session; a certificate program that does not run defers at
    `certificate`. Each is raised once every pass has ended."""
    from concurrent.futures import ThreadPoolExecutor
    from ..store.budget import BudgetPaused
    with ThreadPoolExecutor(max_workers=len(passes)) as ex:
        futures = [ex.submit(session.run_tools, prompt, out_dir, run.opts, t, label=f"review_behaviour_p{k}",
                             effort=run.opts.review_effort, model=run.opts.reviewer_model, subject=n.id)
                   for k, t in enumerate(passes, 1)]
        errors = []
        for f in futures:
            try:
                f.result()
            except BaseException as e:                       # every pass ends before any is acted on
                errors.append(e)
    for kind in (BudgetPaused, session.SessionUnavailable, HarnessFailure):
        for e in errors:
            if isinstance(e, kind):
                raise e
    if errors:
        raise errors[0]


def join_passes(passes: list, law: corpus.Law, binders: list[str], cap: int | None) -> tuple:
    """The review's answer, joined from its passes: `(answer, certificates by number, notes on the
    passes, a summary per pass, the schema defects of the usable answers)`. A pass whose final
    answer is missing, is not a review, returns the rule with no divergence or exceeds the cap is
    dropped, with a note; with no usable pass the answer is None. The usable passes' divergences
    are joined in pass order. Only a divergence that can be judged (certified, its case true, the
    rule's verdict decided) is ever merged, and only with one from another pass whose canonical
    case, entities, `at`, grounding and rule verdict are the same: it is judged once. Every other
    divergence is kept as submitted, so a challenge that cannot be evaluated is never lost to a
    copy. Advisories and gap candidates are joined, exact repeats dropped; the verdict is `return`
    when any usable pass returned."""
    usable, notes, summary, errs = [], [], [], []
    for k, t in enumerate(passes, 1):
        a = t.answer
        divs = a.get("divergences") if isinstance(a, dict) else None
        why = ("submitted no answer" if a is None else
               "submitted an answer that is not a review" if a.get("verdict") not in VERDICTS or not isinstance(divs, list) else
               "returned the rule with no divergence" if a.get("verdict") == "return" and not divs else
               divergence_limit_defect(divs, cap))
        summary.append({"pass": k, "submitted": a is not None, "verdict": (a or {}).get("verdict") if isinstance(a, dict) else None,
                        "divergences": len(divs) if isinstance(divs, list) else None, "attempts": t.attempts, "dropped": why})
        if why:
            notes.append(f"pass {k} {why}" if not why.startswith("the answer") else f"pass {k}: {why}")
            continue
        usable.append((k, t, a))
        errs += behaviour_defects(a, law.text, binders, cap)
    if not usable:
        return None, {}, notes, summary, errs
    joined, certs, seen = [], {}, {}                     # seen: merge key → the pass that contributed it
    advisories, gaps, seen_text = [], [], set()
    as_list = lambda x: x if isinstance(x, list) else []
    for k, t, a in usable:
        recs = t.certs_of(a)
        for local, d in enumerate(a.get("divergences") or [], 1):
            c = recs.get(local)
            key = None
            if isinstance(d, dict) and c is not None and not divergence_schema_defects(local, d, law.text, binders) \
                    and not t.judgeable(local, d, c):
                key = _canon({"case": c.get("canonical_case"), "entities": d.get("entities"), "at": d.get("at"),
                              "grounding": d.get("grounding"), "rule": (c.get("rule_result") or {}).get("verdict")})
                if key in seen and seen[key] != k:              # the same judgeable challenge from another pass: judged once
                    continue
                seen.setdefault(key, k)
            joined.append(d)
            if c is not None:
                certs[len(joined)] = c
        for x in as_list(a.get("advisories")):
            if _ws(x) not in seen_text:
                seen_text.add(_ws(x)); advisories.append(x)
        for g in as_list(a.get("gap_candidates")):
            gk = _canon({kk: g.get(kk) for kk in ("kind", "span", "words")}) if isinstance(g, dict) else _canon(g)
            if gk not in seen_text:
                seen_text.add(gk); gaps.append(g)
    verdict = "return" if any(a.get("verdict") == "return" for _k, _t, a in usable) else "accept"
    return {"verdict": verdict, "divergences": joined, "advisories": advisories, "gap_candidates": gaps}, certs, notes, summary, errs


def param_notes(n: Node, reading: Reading, answer: dict, status_of: dict[int, str], iteration: int) -> list[tuple[str, str]]:
    """The reviewer's words on each proposed parameter of the node: every advisory, and every
    divergence situation, that names the parameter by its id, labelled with what became of it.
    Information for the operator who reviews the value; it routes nothing."""
    proposed = sorted(p["name"] for p in reading.data.get("params", []) if p.get("proposed") and p.get("name") in set(n.params()))
    texts = [("advisory", _ws(a)) for a in answer.get("advisories", []) if isinstance(a, (str, int, float))]
    texts += [(f"divergence {k}, {status_of.get(k, 'not evaluated, unverified')}", _ws(d.get("situation")))
              for k, d in enumerate(answer.get("divergences") or [], 1) if isinstance(d, dict)]
    return [(name, f"the reviewer (`{n.id}`, iteration {iteration}; {label}): \"{text[:500]}\"")
            for name in proposed for label, text in texts if re.search(rf"(?<![\w.]){re.escape(name)}(?![\w])", text)]


def questioned_parameters(params: list[dict], reason) -> list[str]:
    """The proposed parameters a stage-B parameter question is about: those its reason names by id,
    or every proposed parameter of the node where it names none."""
    proposed = [p["name"] for p in params if p.get("proposed")]
    cited = [x for x in proposed if re.search(rf"(?<![\w.]){re.escape(x)}(?![\w])", str(reason or ""))]
    return cited or proposed


def _write_outcome(out_dir: Path, data: dict) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "review_outcome.json").write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")


def gap_candidate_lines(gaps: list) -> list[str]:
    """One line per factor of a standard the law names (span and verbatim words), however many
    aspects of it the reviewer listed: the operator decides a named factor, not each thing it could
    be read as. A `broader_contract` candidate is judged instead (`judge_word_level`)."""
    grouped: dict[tuple[str, str], list[dict]] = {}
    for g in gaps if isinstance(gaps, list) else []:
        if isinstance(g, dict) and g.get("kind") != "broader_contract":
            grouped.setdefault((str(g.get("span")), _ws(g.get("words")).lower()), []).append(g)
    return [f"gap candidate: span {span} — \"{_ws(gs[0].get('words'))}\": " + "; ".join(_ws(g.get("factor")) for g in gs)
            + f" (nearest: {_ws(gs[0].get('nearest'))[:200]})" for (span, _w), gs in grouped.items()]


def _broader_contract_items(gaps: list) -> list[dict]:
    out, seen = [], set()
    for g in gaps if isinstance(gaps, list) else []:
        if isinstance(g, dict) and g.get("kind") == "broader_contract":
            key = (str(g.get("span")), _ws(g.get("words")).lower())
            if key not in seen:
                seen.add(key); out.append(g)
    return out


# ---------------------------------------------------------------------------------------------
# Review of a concept: claims about the body against the contract, as traces, executed
# ---------------------------------------------------------------------------------------------
PLACEHOLDERS_REVIEW_CONCEPT = ("contract", "record", "rendered", "atoms_read", "contracts", "trace_format", "review_checks", "review_submissions")
PLACEHOLDERS_ADJUDICATE_CONCEPT = ("contract", "record", "rendered", "contracts", "items", "precedents")
CONCEPT_KINDS = {"holds_wrongly", "fails_wrongly", "undecided"}
#: The kinds of a divergence of a quantity concept, whose contract gives an interval, not a verdict.
QUANTITY_KINDS = {"value_wrongly", "undecided"}
#: The dimension of each Core unit, as exponents of (metre, second, degree).
UNIT_DIMS = {"metre": (1, 0, 0), "second": (0, 1, 0), "degree": (0, 0, 1), "metrePerSecond": (1, -1, 0),
             "metrePerSecondSq": (1, -2, 0), "degreePerSecond": (0, -1, 1), "perMetre": (-1, 0, 0), "ratio": (0, 0, 0),
             "count": (0, 0, 0)}
#: The contract's verdict, as the episode verdict the concept's instance gives when the body agrees.
CONTRACT_VERDICTS = {"holds": "compliant", "fails": "violated"}
CONCEPT_RULINGS = {"upheld", "dismissed"}
CONCEPT_AGREES = " (the body agrees with the contract on this trace)"


def _track_formals(rec) -> list[str]:
    return [a["name"] for a in rec.args() if a.get("sort") == "track"]


def concept_review_defects(answer: dict, rec, contract: str, rendering: str, result_dim: tuple | None = None) -> list[str]:
    """Defects of a concept review as an answer: the verdict word; each divergence's kind, the
    contract's verdict, the contract's words (verbatim), an instance that fills every literal formal
    with an admissible spelling and every parameter with a value in its unit, a grounding of every
    track formal, and a trace with scenes; each `not_general` item's words, verbatim."""
    errs = []
    if answer.get("verdict") not in VERDICTS:
        errs.append("`verdict` must be `accept` or `return`")
    divs, tuned = answer.get("divergences", []), answer.get("not_general", [])
    if not isinstance(divs, list) or not isinstance(tuned, list):
        return errs + ["`divergences` and `not_general` must be lists"]
    if answer.get("verdict") == "return" and not divs and not tuned:
        errs.append("a return needs at least one divergence with a trace or one `not_general` item")
    for k, d in enumerate(divs, 1):
        errs += concept_divergence_defects(k, d, rec, contract, result_dim)
    for k, t in enumerate(tuned, 1):
        if not isinstance(t, dict) or not _ws(t.get("why")) or not _quoted(t.get("words", ""), contract + "\n" + rendering):
            errs.append(f"not_general {k}: `words` must be verbatim from the contract or the rendering, with a `why`")
    return errs


def _unit_dim(spelling) -> tuple | None:
    """The dimension of a unit as a reviewer or the export spells it (`m/s^2`, `metre_per_second_sq`)."""
    from ..model import units
    if spelling in units.FACTORS:
        return UNIT_DIMS.get(units.FACTORS[spelling][0])
    camel = re.sub(r"_(\w)", lambda m: m.group(1).upper(), str(spelling))
    return UNIT_DIMS.get(camel)


def body_dim(rec, body: dict | None) -> tuple | None:
    """The dimension of a quantity concept's value, inferred from its exported body: a parameter
    has its declared unit, a measure or primitive its generated dimension, and the operators
    combine them. None where it cannot be decided (a concept called inside, an unknown name)."""
    from ..lean import surface
    measures, prims = surface._dimensions()
    pdims = {p["name"]: _unit_dim(p.get("unit")) for p in rec.params()}

    def dim(t):
        if not isinstance(t, dict):
            return None
        if "lit" in t:
            return _unit_dim(t.get("unit"))
        if "param" in t:
            return pdims.get(t["param"])
        if "measure" in t:
            return measures.get(t["measure"])
        if "quantity" in t:
            return (prims.get(t["quantity"]) or (None,))[0]
        if "distance_while" in t:
            return UNIT_DIMS["metre"]
        if "since_rise" in t:
            return UNIT_DIMS["second"]
        if "aggregate" in t:
            return UNIT_DIMS["count"] if t["aggregate"] == "count" else dim(t.get("of"))
        if "neg" in t or "abs" in t:
            return dim(t.get("neg", t.get("abs")))
        if "cond" in t:
            a, b = dim(t.get("then")), dim(t.get("else"))
            return a if a == b else None
        for op in ("add", "sub", "mul", "div"):
            if op in t and isinstance(t[op], list) and len(t[op]) == 2:
                a, b = dim(t[op][0]), dim(t[op][1])
                if a is None or b is None:
                    return None
                if op in ("add", "sub"):
                    return a if a == b else None
                return tuple(x + y if op == "mul" else x - y for x, y in zip(a, b))
        return None
    return dim(body)


def _interval_defects(k: int, cv, result_dim: tuple | None) -> list[str]:
    """`contract_value` of a quantity divergence: `lo` and `hi` as [value, unit], of one dimension
    (the value's, where it is known), `lo` at most `hi`."""
    from ..model import units
    head = f"divergence {k}: contract_value"
    if not isinstance(cv, dict) or set(cv) != {"lo", "hi"}:
        return [f"{head} must be {{\"lo\": [value, unit], \"hi\": [value, unit]}}, the interval the contract's words put the value in"]
    ends = [cv["lo"], cv["hi"]]
    if not all(isinstance(e, list) and len(e) == 2 and isinstance(e[0], (int, float)) and e[1] in units.FACTORS for e in ends):
        return [f"{head}: `lo` and `hi` are each [value, unit] with a unit of {sorted(units.FACTORS)}"]
    dims = {_unit_dim(e[1]) for e in ends}
    if len(dims) != 1:
        return [f"{head}: `lo` and `hi` are in units of different dimensions"]
    if result_dim is not None and dims != {result_dim}:
        from ..lean import surface
        return [f"{head}: the value is in {surface.render_dim(result_dim)}, the interval in {surface.render_dim(dims.pop())}"]
    if units.to_core(*cv["lo"])[1] > units.to_core(*cv["hi"])[1]:
        return [f"{head}: `lo` exceeds `hi`"]
    return []


def concept_divergence_defects(k: int, d, rec, contract: str, result_dim: tuple | None = None) -> list[str]:
    """The defects of one divergence of a concept review; one without defects can be run. A
    divergence of a quantity concept states `contract_value`, the interval the contract's words put
    the value in, where a formula concept's states `contract_verdict`."""
    from ..model import units
    if not isinstance(d, dict):
        return [f"divergence {k} is not an object"]
    errs = []
    tracks = _track_formals(rec)
    literals = {a["name"]: set(a.get("values", [])) for a in rec.args() if a.get("sort") == "literal"}
    params = {p["name"]: str(p.get("unit", "")) for p in rec.params()}
    if rec.get("kind") == "quantity":
        if d.get("kind") not in QUANTITY_KINDS:
            errs.append(f"divergence {k}: kind must be one of {sorted(QUANTITY_KINDS)} for a quantity")
        if "contract_verdict" in d:
            errs.append(f"divergence {k}: a quantity's divergence states `contract_value`, never `contract_verdict`")
        errs += _interval_defects(k, d.get("contract_value"), result_dim)
    else:
        if d.get("kind") not in CONCEPT_KINDS:
            errs.append(f"divergence {k}: kind must be one of {sorted(CONCEPT_KINDS)}")
        if d.get("contract_verdict") not in CONTRACT_VERDICTS:
            errs.append(f"divergence {k}: contract_verdict must be one of {sorted(CONTRACT_VERDICTS)}")
    if not _in(d.get("contract_words", ""), contract):
        errs.append(f"divergence {k}: contract_words is not verbatim from the contract")
    inst = d.get("instance") if isinstance(d.get("instance"), dict) else {}
    lits = inst.get("literals") if isinstance(inst.get("literals"), dict) else {}
    if set(lits) != set(literals) or any(lits[f] not in literals[f] for f in lits):
        errs.append(f"divergence {k}: instance.literals maps exactly the literal formals {sorted(literals)} to one of their admissible spellings"
                    + (f"; {sorted(set(lits) - set(literals))} are not literal formals" if set(lits) - set(literals) else "")
                    + ("; with no literal formal it is `{}`" if not literals else ""))
    ps = inst.get("params") if isinstance(inst.get("params"), dict) else {}
    if set(ps) != set(params):
        errs.append(f"divergence {k}: instance.params must give every parameter {sorted(params)} a [value, unit]")
    for name, v in ps.items():
        ok = isinstance(v, list) and len(v) == 2 and isinstance(v[0], (int, float)) and v[1] in units.FACTORS \
            and name in params and params[name] in units.FACTORS and units.FACTORS[v[1]][0] == units.FACTORS[params[name]][0]
        if not ok:
            errs.append(f"divergence {k}: parameter `{name}` must be [value, unit] in a unit of {params.get(name)!r}")
    g = d.get("grounding")
    if not isinstance(g, dict) or set(g) != set(tracks) or not all(isinstance(x, int) for x in g.values()):
        errs.append(f"divergence {k}: grounding must map exactly the track formals {tracks} to track ids")
    tr = d.get("trace")
    if not isinstance(tr, dict) or not isinstance(tr.get("scenes"), list) or not tr["scenes"]:
        errs.append(f"divergence {k}: trace must be an object with a non-empty `scenes` list")
    return errs


def _lean_q(value: float, unit: str) -> str:
    """A parameter value as a Core literal term: the value converted to the Core unit, exactly."""
    from ..model import units
    core, q = units.to_core(value, unit)
    return f".lit (Q.mk' ({q.numerator}) {q.denominator}) .{core}"


def _concept_review_harness_source(cid: str, traces: list[tuple]) -> str:
    """A Lean program that, for each divergence, prints the trace check's messages (`LINT`) and runs
    the concept, as the instance the divergence names, on its trace (`DIS`): compliant where the
    body holds throughout, violated where it fails, unknown where it has no value; an instant whose
    only unknown is a window reaching past the trace's start or end is not judged, as for a rule. A
    quantity concept runs against the interval its divergence states (`bounds`): compliant where its
    value lies in it. The occupancy of every observed track is derived from the geometry first."""
    ns = nodeid.concept_namespace(cid)
    bound = lambda b: "none" if b is None else f"some (({_lean_q(*b[0])} : TrafficSpec.Term), ({_lean_q(*b[1])} : TrafficSpec.Term))"
    items = ", ".join(
        f'({k}, {json.dumps(str(p.resolve()))}, [{", ".join(f"({json.dumps(b)}, {t})" for b, t in g.items())}], '
        f'[{", ".join(f"({json.dumps(f)}, {json.dumps(v)})" for f, v in lits.items())}], '
        f'[{", ".join(f"({json.dumps(n)}, ({_lean_q(v[0], v[1])} : TrafficSpec.Term))" for n, v in ps.items())}], {bound(bd)})'
        for k, p, g, lits, ps, bd in traces)
    return f'''import TrafficSpec
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import {nodeid.concept_module(cid)}
open TrafficSpec Lean
def main : IO Unit := do
  let c := {ns}.concept
  let cs := (allConcepts.filter (·.id != c.id)) ++ [c]
  let items : List (Nat × String × List (String × Nat) × List (String × String) × List (String × TrafficSpec.Term) × Option (TrafficSpec.Term × TrafficSpec.Term)) := [{items}]
  for (k, path, grounding, lits, ps, bd) in items do
    let inst : Concept.Instance := {{ name := s!"review_{{k}}", concept := c.id, literals := lits, params := ps, bounds := bd }}
    match Concept.asRule cs inst with
    | none => IO.println s!"DIS\\t{{k}}\\tunfilled\\t"
    | some r =>
      let r' := Concept.expandRule cs r
      let text ← IO.FS.readFile path
      match Decode.parse Decode.trace text with
      | .error e => IO.println s!"DIS\\t{{k}}\\tdecode\\t{{e}}"
      | .ok τ0 =>
        let τ := TraceLint.completeOccupancy τ0
        IO.println s!"LINT\\t{{k}}\\t{{(Json.arr ((TraceLint.checkTrace τ).map Json.str).toArray).compress}}"
        let m := Manifest.full "review"
        let S := Grounding.Setup.mk' [r'] (maskTrace m τ) ({{}} : Reading) m.reidGap
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


def execute_concept_divergences(rec, answer: dict, out_dir: Path, result_dim: tuple | None = None) -> tuple[list[dict], list[str], list[str], list[str]]:
    """Run the concept on every divergence trace, as a rule's case is run. Returns (confirmed,
    unconfirmed, errors, incomplete): a trace on which the body's verdict differs from the
    contract's — or is unknown where the contract decides, for a divergence claiming the body
    undecided — confirms it; one on which they agree is the reviewer's advisory; one unknown only
    because the trace leaves an atom out or does not cover or sample a look-back, or one that fails
    the trace check, is incomplete."""
    contract = " ".join(str(rec.get("contract", "")).split())
    listed = answer.get("divergences") if isinstance(answer.get("divergences"), list) else []
    divs = {k: d for k, d in enumerate(listed, 1) if not concept_divergence_defects(k, d, rec, contract, result_dim)}
    quantity = rec.get("kind") == "quantity"
    if not divs:
        return [], [], [], []
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in out_dir.glob("disagreement_*.json"):
        stale.unlink()
    traces = []
    for k, d in divs.items():
        p = out_dir / f"disagreement_{k}.json"
        p.write_text(json.dumps(d.get("trace"), ensure_ascii=False, indent=1), encoding="utf-8")
        inst = d.get("instance") or {}
        bd = (tuple(d["contract_value"]["lo"]), tuple(d["contract_value"]["hi"])) if quantity else None
        traces.append((k, p, {b: int(t) for b, t in d["grounding"].items()}, dict(inst.get("literals") or {}), dict(inst.get("params") or {}), bd))
    harness = out_dir / "review_harness.lean"
    harness.write_text(_concept_review_harness_source(rec.id, traces), encoding="utf-8")
    ok, hout = lean.lean_run(paths.LIBRARY, harness)
    (out_dir / "review_harness.out").write_text(hout, encoding="utf-8")
    if not ok:
        raise HarnessFailure(f"the concept review harness did not run: {hout[-600:]}")
    got, lint = {}, {}
    for line in hout.splitlines():
        parts = line.split("\t")
        if parts[0] == "DIS" and len(parts) >= 3:
            got[int(parts[1])] = (parts[2], parts[3] if len(parts) > 3 else "")
        elif parts[0] == "LINT" and len(parts) >= 3:
            try:
                lint[int(parts[1])] = json.loads(parts[2])
            except json.JSONDecodeError:
                raise HarnessFailure(f"an unparseable LINT line: {line[:200]}")
    confirmed, unconfirmed, errors, incomplete = [], [], [], []
    for k, d in divs.items():
        tag, why = got.get(k, ("missing", ""))
        claimed = "compliant" if quantity else CONTRACT_VERDICTS[d["contract_verdict"]]   # a quantity's claim: its value lies in the interval
        if quantity:
            lo, hi = d["contract_value"]["lo"], d["contract_value"]["hi"]
            body = {"compliant": "in the interval", "violated": "outside the interval"}.get(tag, tag)
            head = (f"divergence {k} ({d.get('kind')}): {_ws(d.get('situation'))[:160]} — contract: from {lo[0]} {lo[1]} to {hi[0]} {hi[1]}, body: {body}")
        else:
            body = {"compliant": "holds", "violated": "fails"}.get(tag, tag)
            head = (f"divergence {k} ({d.get('kind')}): {_ws(d.get('situation'))[:160]} — contract: {d.get('contract_verdict')}, body: {body}")
        if tag in ("decode", "missing", "unfilled"):
            errors.append(f"divergence {k}: " + {"decode": f"the trace does not decode: {why[:200]}", "missing": "the harness printed no verdict",
                                                  "unfilled": "the instance leaves a formal unfilled"}[tag])
        elif lint.get(k):
            incomplete.append(f"divergence {k}: trace check: " + "; ".join(lint[k][:8]))
        elif tag == claimed:
            unconfirmed.append(head + CONCEPT_AGREES)
        elif tag == "unknown" and why and all(_trace_defect(r, "rule_undecided" if d.get("kind") == "undecided" else None) for r in why.split(",")):
            incomplete.append(f"divergence {k}: {_ws(d.get('situation'))[:120]} — the body's verdict on the trace is unknown only because the "
                              "trace is incomplete: " + "; ".join(sorted({_trace_remedy(r) for r in why.split(",")})))
        else:
            line = head + (f" [{why}]" if tag == "unknown" and why else "") + f'; contract: "{_ws(d.get("contract_words"))[:120]}"'
            confirmed.append({"line": line, "div": d, "rule": body + (f" ({why})" if tag == "unknown" and why else ""),
                              "key": f"{d.get('kind')}"})
    return confirmed, unconfirmed, errors, incomplete


def adjudicate_concept(run: Run, rec, blocks: dict[str, str], items: list[dict], out_dir: Path) -> list[tuple[dict, str, str]]:
    """Each confirmed divergence and `not_general` item of a concept with its ruling. An item left
    unruled, or ruled with a defect the adjudicator keeps after the re-ask, is never upheld by
    default: the adjudication raises `Deferred` (`concept_adjudication`)."""
    listing = "\n\n".join(
        (f"{k}. ({i['div'].get('kind')}) {_ws(i['div'].get('situation'))}\n"
         f"   the contract's words, per the reviewer: \"{_ws(i['div'].get('contract_words'))}\"\n"
         f"   the reviewer's verdict for the contract: {i['div'].get('contract_verdict')}\n"
         f"   the body's executed verdict: {i['rule']}")
        if i["div"].get("kind") != "not_general" else
        (f"{k}. (not_general) the words \"{_ws(i['div'].get('words'))}\": {_ws(i['div'].get('why'))}")
        for k, i in enumerate(items, 1))
    key = f"concept:{rec.id}"
    prompt = render.render("adjudicate_concept.md", {**{k: blocks[k] for k in ("contract", "record", "rendered", "contracts")},
                                                      "items": "### Items\n\n" + listing + "\n", "precedents": precedents_block(run, key)})
    hay = "\n".join(blocks[k] for k in ("contract", "record", "rendered", "contracts")) + "\n" + "\n".join(_strings(rec.raw))

    def defects(a: dict) -> list[str]:
        errs = []
        rows = a.get("rulings")
        if not isinstance(rows, list):
            return ["`rulings` must be a list"]
        seen = []
        for r in rows:
            k = r.get("item") if isinstance(r, dict) else None
            if not isinstance(k, int) or not 1 <= k <= len(items):
                errs.append(f"a ruling must name an item by its number, 1 to {len(items)}"); continue
            if k in seen:
                errs.append(f"item {k} is ruled twice")
            seen.append(k)
            if r.get("ruling") not in CONCEPT_RULINGS:
                errs.append(f"item {k}: ruling must be one of {sorted(CONCEPT_RULINGS)}")
            if not _ws(r.get("reason")):
                errs.append(f"item {k}: a ruling needs a reason")
            if not _quoted(r.get("quote", ""), hay):
                errs.append(f"item {k}: the quote is not verbatim from the contract, the record or the rendering")
        errs += [f"item {k} has no ruling" for k in range(1, len(items) + 1) if k not in seen]
        return errs
    answer, errs = validate_phase._session(run, out_dir, "adjudicate", prompt, check=defects, usage_label=f"adjudicate:{rec.id}")
    if answer is None and not errs:
        raise Deferred("concept_adjudication", "dry run: the concept's items were not adjudicated")
    if errs:
        raise Deferred("concept_adjudication", f"the concept adjudication stayed invalid: {'; '.join(errs)[:300]}")
    rows = {r.get("item"): r for r in answer.get("rulings", []) if isinstance(r, dict)}
    out = [(i, rows[k]["ruling"], f"{_ws(rows[k].get('reason'))} — \"{_ws(rows[k].get('quote'))[:160]}\"") for k, i in enumerate(items, 1)]
    for i, ruling, why in out:
        append_ruling(run, {"key": key, "subject": rec.id, "iteration": run.iteration, "item": _ws(i.get("line"))[:400],
                            "ruling": ruling, "reason": _ws(why)[:600]})
    return out


class ConceptTools(ReviewTools):
    """A concept reviewer's session: `run_instance` runs one divergence's instance of the body on
    its trace; `submit_review` runs every divergence of the answer the same way. Schema defects, a
    trace that does not decode or run, and an incomplete trace are what keeps a submission open; a
    trace on which the body agrees with the contract keeps its route, an advisory."""
    check_name = "run_instance"

    def __init__(self, rec, contract: str, rendering: str, result_dim, out_dir: Path, checks: int, submissions: int):
        self.rec, self.contract, self.rendering, self.result_dim = rec, contract, rendering, result_dim
        self.specs = [
            _fn("run_instance", "Run one divergence: the trace check, then the concept's body, as the instance names it, on the "
                "trace. Returns whether the body confirms the divergence (`confirmed`), agrees with the contract (`agrees`), or "
                "could not be evaluated (`unusable`, `schema defects`), with the messages (they call it divergence 1). No "
                "adjudicator is asked.", "divergence", "one divergence, in the answer's schema"),
            _fn("submit_review", "Submit the answer. The harness runs every divergence of it the same way; an answer with a "
                "schema defect or a divergence that cannot be evaluated comes back with the messages while submissions remain. "
                "The accepted submission is the answer.", "answer", "the answer, in the Output schema")]
        self.final = ([], [], [], [])
        super().__init__(out_dir, checks, submissions)

    def run_answer(self, a: dict, where: Path) -> tuple:
        key = _canon(a)
        if key not in self.cache:
            self.cache[key] = execute_concept_divergences(self.rec, a, where, self.result_dim)
        return self.cache[key]

    def _check(self, d, where: Path) -> dict:
        schema = concept_divergence_defects(1, d, self.rec, self.contract, self.result_dim)
        if schema:
            return {"status": "schema defects", "messages": schema}
        confirmed, unconfirmed, errors, incomplete = self.run_answer({"divergences": [d]}, where)
        status = "unusable" if errors or incomplete else "agrees" if unconfirmed else "confirmed"
        return {"status": status, "messages": errors + incomplete + unconfirmed + [c["line"] for c in confirmed]}

    def _submit(self, a: dict, number: int) -> list[str]:
        errs = concept_review_defects(a, self.rec, self.contract, self.rendering, self.result_dim)
        res = self.run_answer(a, self.out_dir / "submissions" / f"L{self.launch}" / f"{number:03d}")
        self.final = res
        divs = a.get("divergences") if isinstance(a.get("divergences"), list) else []
        self.attempts.append({"divergences": len(divs), "confirmed": len(res[0]), "schema_defects": len(errs),
                              "unusable": len(res[2]) + len(res[3]), "checks_before": self.used_checks})
        return errs + res[2] + res[3]


def literal_formals_line(rec) -> str:
    """What `instance.literals` maps, named from the record's formals: each literal formal with its
    admissible spellings, or none."""
    lits = [a for a in rec.args() if a.get("sort") == "literal"]
    if not lits:
        return "Literal formals to instantiate: none, so `instance.literals` is `{}`."
    return "Literal formals to instantiate, each to one of its spellings in `instance.literals`: " + "; ".join(
        f"`{a['name']}` ({', '.join(f'`{v}`' for v in a.get('values', []))})" for a in lits) + "."


def review_concept(run: Run, rec, extras: dict, out_dir: Path) -> ReviewOutcome:
    """The concept's body, rendered from its code, is reviewed by a second vendor against its
    contract: each divergence comes as a trace (which passes the trace check) and an instance, the
    harness runs the body on it, and every divergence execution confirms, and every `not_general`
    item, goes to the adjudicator, which rules by the contract's words. `returned` with the upheld
    items; else `deferred` when a challenge could not be evaluated (stage `reviewer`), the
    adjudication stays invalid or the harness does not run; else `accepted`, its advisories recorded
    on the concept as what it computes as built. Raises `SessionUnavailable` when a session could
    not be launched."""
    if not enabled(run):
        if run.opts.dry_run:
            return ReviewOutcome("accepted", advisories=["dry run"])
        raise RuntimeError("a reviewer_model is required for a concept review")
    onto = ontology.load(run.opts.ontology)
    glosses = {aid: onto.contract(aid) for aid in extras.get("reads", [])}
    for cid, crec in run.all_concepts().items():
        glosses[cid] = " ".join(str(crec.get("contract", "")).split())
    try:
        rendering = render_formula.render_concept({"args": [{"name": a["name"], "sort": {"sort": a["sort"], "values": a.get("values", [])}} for a in rec.args()],
                                                   "params": [{"name": p["name"], "unit": p["unit"]} for p in rec.params()],
                                                   "kind": rec.get("kind"), "body": extras.get("body_json")}, glosses)
    except render_formula.Unrendered as e:
        raise session.SessionUnavailable(f"the renderer has no phrasing for the {e} (harness/lean/render_formula.py)") from e
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "rendered_body.md").write_text(rendering, encoding="utf-8")
    contract = " ".join(str(rec.get("contract", "")).split())
    record = {k: v for k, v in rec.raw.items() if k not in ("scenarios", "used_by")}
    record["narrowings_by_the_coder"] = [n for n in extras.get("narrowings_added", []) if isinstance(n, dict)]
    definition = f"\n\nThe definition it quotes: `{rec.get('definition')}`" if rec.get("definition") else ""
    blocks = {
        "contract": f"### Contract\n\n`{rec.id}`: {contract}{definition}\n",
        "record": "### Record\n\n```json\n" + json.dumps(record, ensure_ascii=False, indent=1) + "\n```\n\n" + literal_formals_line(rec) + "\n",
        "rendered": "### Rendering\n\n" + rendering + "\n",
        "atoms_read": atoms_read_block(extras.get("body_json") or {}, run.all_concepts(), what="concept"),
        "contracts": validate_phase.contracts_table(glosses),
        "trace_format": trace_format_block(),
        "review_checks": str(run.opts.review_checks),
        "review_submissions": str(run.opts.review_submissions),
    }
    prompt = render.render("review_concept.md", blocks)
    result_dim = body_dim(rec, extras.get("body_json")) if rec.get("kind") == "quantity" else None
    tools = ConceptTools(rec, contract, rendering, result_dim, out_dir, run.opts.review_checks,
                         run.opts.review_submissions)
    (out_dir / "review_concept_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return ReviewOutcome("accepted", advisories=["review skipped (dry run)"])
    try:
        session.run_tools(prompt, out_dir, run.opts, tools, label="review_concept", effort=run.opts.review_effort,
                          model=run.opts.reviewer_model, subject=rec.id)
    except HarnessFailure as e:
        return ReviewOutcome("deferred", reasons=[str(e)], defer_stage="certificate")
    answer = tools.answer
    if answer is None:
        return ReviewOutcome("deferred", reasons=[f"concept review: the reviewer submitted no answer in {tools.max_requests} requests"],
                             defer_stage="reviewer")
    errs = concept_review_defects(answer, rec, contract, rendering, result_dim)
    if answer.get("verdict") not in VERDICTS:
        return ReviewOutcome("deferred", reasons=["concept review: the answer is not a review: " + "; ".join(errs)], defer_stage="reviewer")
    confirmed, unconfirmed, errors, incomplete = tools.final         # the submitted answer's divergences, as run
    tuned = [{"line": f"not general: \"{_ws(t.get('words'))}\" — {_ws(t.get('why'))}", "div": {"kind": "not_general", **t}, "rule": "not executed",
              "key": "not_general"} for t in answer.get("not_general", []) if isinstance(t, dict)]
    items = confirmed + tuned
    try:
        rulings = adjudicate_concept(run, rec, blocks, items, out_dir) if items else []
    except Deferred as e:
        return ReviewOutcome("deferred", reasons=[e.why], defer_stage=e.stage)
    upheld = [f"{i['line']} — upheld: {w}" for i, r, w in rulings if r == "upheld"]
    notes = [str(x) for x in answer.get("advisories", [])] + [f"dismissed: {i['line']} — {w}" for i, r, w in rulings if r == "dismissed"]
    # a challenge the harness could not evaluate (a schema defect of the final answer, a trace that
    # does not decode or run, an incomplete trace) leaves the review undecided: without an upheld
    # item it defers the concept; a trace on which the body gives the contract's verdict is advisory
    unusable = concept_review_defects(answer, rec, contract, rendering, result_dim) + errors + incomplete
    _write_outcome(out_dir, {"reviewer_verdict": answer.get("verdict"), "rulings": [{"item": i["line"], "ruling": r, "why": w} for i, r, w in rulings],
                             "unconfirmed": unconfirmed, "unusable": unusable, "schema_defects": errs})
    if upheld:
        return ReviewOutcome("returned", reasons=upheld, advisories=notes)
    if unusable:
        return ReviewOutcome("deferred", reasons=[f"concept review: {len(unusable)} challenge(s) could not be evaluated: " + " | ".join(unusable)[:900]],
                             advisories=notes, defer_stage="reviewer")
    return ReviewOutcome("accepted", advisories=notes + [f"refuted by execution: {x}" for x in unconfirmed])
