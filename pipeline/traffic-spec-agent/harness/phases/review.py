"""The behaviour review: a second vendor's model shows situations in which a rule and the law it
formalizes decide differently; the harness certifies each one; two judges decide it.

A node divergence returns the node only when it is admitted:
- its trace is consistent (`TraceLint.checkTrace`) and its witness instant valid (`checkWitness`);
- it states a case — a typed formula over the trace, naming concrete classes and no parameter,
  rule, concept or legal aggregate, and only assumptions and declared intentions of the run's
  catalogue — that holds at one instant `at` (`Case.check`, `Case.eval`);
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
from dataclasses import asdict, dataclass, field
from pathlib import Path

from ..agents import render, session
from ..lean import index_sync, lean, render_formula, surface
from ..lean.surface import _decode_source, decoder_fields, decoder_keys, read_part, trace_schema, unread_keys
from ..model import corpus, nodeid, ontology
from ..model.blueprint import Node, span_offsets
from ..model.reading import Reading
from ..store import jsonl, paths
from ..store.gaps import GapLedger
from ..store.state import Run
from . import validate as validate_phase
from .code import concept_dir, node_dir

PLACEHOLDERS_REVIEW_CODE = ("law_and_segmentation", "definitions", "record", "rendered", "atoms_read", "contracts", "parameters", "trace_format",
                            "case_language", "case_vocabulary", "not_atoms", "obligations", "filed", "max_divergences", "review_checks",
                            "review_submissions")
PLACEHOLDERS_JUDGE_CASE = ("law", "definitions", "case", "contracts")
PLACEHOLDERS_ADJUDICATE = ("law_and_segmentation", "definitions", "record", "rendered", "contracts", "parameters", "aggregates",
                           "item", "precedents", "not_atoms")
VERDICTS = {"accept", "return"}
GAP_KINDS = {"standard_factor", "broader_contract"}
KINDS = {"rule_permits_unlawful", "rule_forbids_lawful", "rule_undecided"}
#: The verdicts a reviewer may claim for the law, spelt as `Verdict.tag`.
LAWFUL = {"violated", "compliant", "not_applicable"}
ANSWER_KEYS = {"verdict", "divergences", "advisories", "gap_candidates"}
DIVERGENCE_KEYS = {"kind", "situation", "law_words", "rule_reads", "lawful_verdict", "grounding", "trace", "case", "entities", "at", "unstatable",
                   "extends"}
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
            if isinstance(answer, str):                    # an answer sent as a JSON string is the same answer
                try:
                    answer = json.loads(answer)
                except json.JSONDecodeError:
                    pass
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
    """A rule reviewer's session. Its check and its submission decide each divergence by
    `divergence_status`, as the review acts on it, with the cases to extend (`extendable`, each case
    id with its recorded row)."""
    def __init__(self, run: Run, n: Node, law: corpus.Law, reading: Reading, binders: list[str], windows: str, history: str,
                 out_dir: Path, checks: int, submissions: int, need: "_Need | None" = None, extendable: dict[str, dict] | None = None):
        self.run, self.n, self.law, self.reading, self.binders = run, n, law, reading, binders
        self.windows, self.history, self.need, self.extendable = windows, history, need, dict(extendable or {})
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
        bad = cert_unusable(k, d, c, self.windows, self.history, self.need)
        return bad if bad or c.get("rule_result") is not None else [f"divergence {k}: the certificate printed no verdict of the rule"]

    def status(self, k: int, d, where: Path) -> Status:
        return divergence_status(k, d, lambda: self.cert(d, where), self.law.text, self.binders, self.extendable,
                                 self.windows, self.history, self.need)

    def _check(self, d, where: Path) -> dict:
        s = self.status(1, d, where)
        out = {"status": s.status, "messages": s.messages}
        if s.status in ("unusable", "refuted", "certifiable"):
            c = self.cert(d, where) or {}
            out.update(case_value=c.get("case_value"), rule_verdict=c.get("rule_result"))
        return out

    def _submit(self, a: dict, number: int) -> list[str]:
        cap = self.run.opts.max_divergences
        errs = behaviour_defects(a, self.law.text, self.binders, cap)
        divs = a.get("divergences") if isinstance(a.get("divergences"), list) else []
        unusable, certified = [], 0
        if not (cap and len(divs) > cap):
            for k, d in enumerate(divs, 1):
                s = self.status(k, d, self.out_dir / "submissions" / f"L{self.launch}" / f"{number:03d}" / f"d{k}")
                if s.status == "unusable":
                    unusable += s.messages
                certified += s.status in ("refuted", "certifiable")
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
    satisfied: list[str] = field(default_factory=list)                 # keys of obligations the rule now meets: their streaks reset
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
can be written. They are the only keys a trace holds: Core never reads any other, so a trace that
holds one is refused, the key named. A trace is `{"scenes": [scene, ...]}` with `t` strictly increasing (milliseconds).
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
states, and replaces whatever the trace lists for it. Core computes the relations between users
from their kinematics: a relation it computes from the scene is never supplied in `relations`, and a
trace that supplies one fails the check; supply only one it cannot compute (`visible`, or a pair
whose geometry the scene leaves out). A look-back of length d needs scenes
reaching d before the observation judged, no two consecutive scenes more than d/2 apart; otherwise
the look-back is unknown.

The harness checks every trace you write before it runs anything on it, exactly and with no
tolerance; a trace that fails is returned to you with the messages. The check, as Core states it:

"""
def unread_key_defects(k: int, trace) -> list[str]:
    """A fresh written trace holding keys the decoder does not read: refused, the keys named. What
    Core does not execute is no evidence, and a judge must never take it for a fact."""
    bad = unread_keys(trace)
    return [f"divergence {k}: the trace holds key(s) the decoder does not read, so Core never executes them: "
            + ", ".join(f"`{p}`" for p in bad[:8]) + (f" and {len(bad) - 8} more" if len(bad) > 8 else "")
            + " — remove them; only the keys of the trace format are evidence"] if bad else []


#: Where the scene keeps each kind of entity, and the decoder of its record.
_BASES = {"user": ("users[]", "roadUser"), "structure?": ("structures[]", "structure'"), "device": ("devices[]", "device"),
          "relation": ("relations[]", "relation")}


def _accessor(atoms_src: str, name: str) -> str:
    m = re.search(rf"^def {re.escape(name)} \(s : Scene\).*?(?=^def |^/--|^-- -|\Z)", atoms_src, re.S | re.M)
    return m.group(0) if m else ""


def _field_path(atoms_src: str, name: str, fields: dict, depth: int = 0) -> str | None:
    """The trace path an atom accessor reads, from the projections in its body (`(s.user x).bind
    (·.kin.speed)` ↦ `users[].kin.speed`), following a call of another accessor. A projection of
    the entity's record (`u.f`, `st.f`, `dv.f`, or a first `·.f`) starts a path, each later `·.g`
    continues it (`.bind (·.lane) |>.bind (·.direction)` ↦ `lane.direction`), and the path stops at a
    step the decoder does not read (a method, a tuple index, a field no key fills). The last path
    that reads a decoded field is the one the accessor answers from."""
    body = _accessor(atoms_src, name)
    if not body or depth > 4:
        return None
    if re.search(r"\bs\.env\.(\w+)", body):
        f = re.search(r"\bs\.env\.(\w+)", body).group(1)
        key = fields.get("env", {}).get(f, (None,))[0]
        return f"env.{key}" if key else None
    base = re.search(r"\(s\.(user|structure\?|device|relation) ", body)
    if base:
        prefix, base_rec = _BASES[base.group(1)]
        best, cur = None, None
        for m in re.finditer(r"(·|\bu|\bst|\bdv)\.((?:\w+\.)*\w+)", body):
            if m.group(1) != "·" or cur is None:
                cur = ([], base_rec, True)                # a projection of the record starts a path
            path, rec, open_ = cur
            for f in m.group(2).split("."):
                key, sub = fields.get(rec, {}).get(f, (None, ""))
                if key is None or not open_:
                    open_ = False
                    break
                path, rec = path + [key], sub or rec
            cur = (path, rec, open_)
            if path:
                best = path
        if best:
            return f"{prefix}.{'.'.join(best)}"
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
        refining = sorted(c for c, p in surface.kind_refinements().items() if p == rest)
        if rest in surface.abstract_kinds():
            return f"`structures[].kind` = a kind that refines `{rest}` ({', '.join(f'`{c}`' for c in refining)}); `{rest}` itself is abstract and labels no structure"
        return f"`structures[].kind` = `{rest}`" + (f" or a kind that refines it ({', '.join(f'`{c}`' for c in refining)})" if refining else "")
    if prefix == "dev" and rest in spell.get("DeviceKind", set()):
        return f"`devices[].kind` = `{rest}`"
    if atom == "ru_aggregate":
        return "`users[].classes` (the aggregate's classes through the reading)"
    atoms_src = (paths.CORE / "Vocab" / "Atoms.lean").read_text(encoding="utf-8")
    p = _field_path(atoms_src, atom, decoder_fields(_decode_source()))
    if p:
        return f"`{p}`" + (", which Core computes from the users' kinematics where the scene has them: then it is never supplied" if prefix == "rel" else "")
    if prefix == "rel":
        return "computed from the users' kinematics"
    if prefix == "st":
        return "computed from the users' positions, headings and extents and the structures' positions and boundaries"
    return "(see the trace format)"


def names_called(exported, keys: tuple[str, ...] = ("atom", "measure", "derived", "quantity")) -> set[str]:
    """The Lean names an exported formula or term names under `keys`, at any depth of nesting."""
    names: set[str] = set()

    def walk(x) -> None:
        if isinstance(x, dict):
            for k in keys:
                if isinstance(x.get(k), str):
                    names.add(x[k])
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(exported)
    return names


def primitives_called(body) -> list[str]:
    """The primitives (Lean names) an exported body calls, as a Boolean (`derived`) or a value
    (`quantity`), wherever an operator nests the call."""
    return sorted(n for n in names_called(body, ("derived", "quantity")) if n.startswith("prim_"))


def atoms_read(rule_json: dict, concepts: dict[str, dict]) -> list[str]:
    """Every atom (Lean name) the rule reads: its own leaves, and what the concepts and primitives
    it calls read, so a trace that leaves none of them out can be judged."""
    names = names_called(rule_json)
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
    if not _member(answer.get("verdict"), VERDICTS):
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
    else:
        errs += unread_key_defects(k, tr)
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



def _registry(run: Run | None, subject: str, task: Path | None) -> tuple[str, str]:
    """A review program's own registry (`index_sync.registry_source`), so that a program run beside
    other sessions' gates reads no generated file they rewrite: the ids the gate of `task`
    registered (its `registry.json`), or, with no such file, the run's accepted records, or, with no
    run (an offline check), every active record on disk; with `subject` itself registered."""
    from ..checks import gate
    if task is not None and (task / "registry.json").exists():
        nodes, concepts = gate.task_registry(task)
        keep = gate.task_keep(task)
    elif run is not None:
        nodes, concepts, keep = sorted(run.all_nodes()), sorted(run.all_concepts()), set()
    else:
        nodes, concepts, keep = None, None, set()
    if nodeid.is_concept_id(subject):
        concepts = None if concepts is None else sorted(set(concepts) | {subject})
    else:
        nodes = None if nodes is None else sorted(set(nodes) | {subject})
    return index_sync.registry_source(nodes, concepts, keep | {subject})


def _cert_source(node_id: str, reading_json: Path, items: list[tuple[int, Path, Path, dict[str, int]]],
                 registry: tuple[str, str]) -> str:
    """A Lean program that prints, for each divergence, `CERT\\t<json>`: `Certificate.record` of its
    trace and case for the node's rule among the library's rules (concepts expanded), under the run's
    reading, after the check that the trace supplies no relation Core computes from the scene
    (`RELCHECK`, `harness/lean/relations.py`). A reading that does not decode stops the program."""
    rns = nodeid.rule_namespace(node_id)
    rows = ", ".join(
        f'({k}, {json.dumps(str(t.resolve()))}, {json.dumps(str(c.resolve()))}, [{", ".join(f"({json.dumps(b)}, {g})" for b, g in gr.items())}])'
        for k, t, c, gr in items)
    from ..lean import relations
    imports, defs = registry
    return f'''{imports}import {nodeid.rule_module(node_id)}
{defs}open TrafficSpec Lean
{relations.lean_defs()}
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
      match Decode.parse Decode.trace tt with
      | .ok τ => RelCheck.run (toString k) τ
      | .error _ => pure ()
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
    for line in output.splitlines():                     # a supplied relation Core computes is a defect of a hand-written trace
        parts = line.split("\t")
        if parts[0] == "RELCHECK" and len(parts) >= 5 and parts[1].isdigit() and int(parts[1]) in got:
            c = got[int(parts[1])]
            c.setdefault("relation_errors", []).append(f"t={parts[2]} ({parts[3]}): {parts[4]}")
            c.setdefault("relation_fields", []).append([parts[2], parts[3], parts[4].split(":", 1)[0]])
    return got


def strip_computed_relations(trace: dict, fields: list) -> dict:
    """A saved trace without the supplied relation fields Core computes (`relation_fields`: the
    instant, the pair `a-b` and the atom of each `RELCHECK`): Core computes them from the scene
    instead. A relation entry left with only its pair is removed."""
    from ..lean.relations import atom_keys
    keys = atom_keys()
    drop = {(str(t), pair, keys[atom]) for t, pair, atom in fields if atom in keys}
    out = json.loads(json.dumps(trace))
    for sc in out.get("scenes") or []:
        if not isinstance(sc, dict) or not isinstance(sc.get("relations"), list):
            continue
        kept = []
        for m in sc["relations"]:
            if isinstance(m, dict):
                pair = f"{m.get('a')}-{m.get('b')}"
                m = {k: v for k, v in m.items() if (str(sc.get("t")), pair, k) not in drop}
                if set(m) <= {"a", "b"}:
                    continue
            kept.append(m)
        sc["relations"] = kept
    return out


#: How a case's messages name each kind of declared-fact id (`case_declarations[].kind`).
_DECLARED_KIND = {"asm": ("assumption", "assumptions"), "int": ("declared intention", "intentions")}


def undeclared_case_errors(recs: dict[int, dict], catalogue: dict[str, dict]) -> None:
    """A certified case that names an assumption (`asm.*`) or a declared intention (`int.*`) the
    run's catalogue does not hold under that kind is not admitted: its judges could not be told what
    the id means. The defect joins the case's own errors, which return it to the reviewer."""
    for c in recs.values():
        for d in c.get("case_declarations") or []:
            if d["id"] in catalogue and d["id"].startswith(d["kind"] + "."):
                continue
            one, many = _DECLARED_KIND[d["kind"]]
            c["case_check_errors"] = (c.get("case_check_errors") or []) + [
                f"the case names the {one} `{d['id']}`, which is in no catalogue of the run: a case states only {many} "
                "the run's declarations give a meaning"]


def certify(run: Run, n: Node, divs: dict[int, dict], reading: Reading, out_dir: Path, saved: bool = False) -> dict[int, dict]:
    """Run the certificate program on every certifiable divergence; their records by number. With
    `saved` (a recorded obligation's trace, replayed), the supplied relations Core computes are not
    a defect of the submission: they are stripped, Core computes them, and the case is certified
    again; the record keeps what was stripped (`relations_stripped`)."""
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
    registry = _registry(run, n.id, None if run is None else node_dir(run, n.id))
    prog.write_text(_cert_source(n.id, reading_json, items, registry), encoding="utf-8")
    with lean.evaluation_lock(paths.LIBRARY):
        code, out = lean.lean_run(paths.LIBRARY, prog); ok = code == 0
    (out_dir / "certificate.out").write_text(out, encoding="utf-8")
    if not ok:
        raise HarnessFailure(f"the certificate program did not run: {out[-600:]}")
    recs = parse_cert(out, set(divs))
    undeclared_case_errors(recs, reading.declarations() if hasattr(reading, "declarations") else {})
    if saved:
        strip = {k: c for k, c in recs.items() if c.get("relation_fields")}
        if strip:
            again = certify(run, n, {k: {**divs[k], "trace": strip_computed_relations(divs[k]["trace"], c["relation_fields"])}
                                     for k, c in strip.items()}, reading, out_dir / "stripped")
            for k, c in strip.items():
                recs[k] = {**again[k], "relations_stripped": c["relation_errors"]}
            divs = {k: d for k, d in divs.items() if k not in strip}     # the stripped ones were diagnosed on their own run
    try:
        _diagnose(n, divs, {k: recs[k] for k in divs}, reading_json, out_dir / "diagnosis", registry)
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


def _diagnose(n: Node, divs: dict[int, dict], recs: dict[int, dict], reading_json: Path, out_dir: Path,
              registry: tuple[str, str]) -> None:
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
    prog.write_text(_cert_source(n.id, reading_json, items, registry), encoding="utf-8")
    with lean.evaluation_lock(paths.LIBRARY):
        code, out = lean.lean_run(paths.LIBRARY, prog); ok = code == 0
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


def _trace_defect(reason: str, kind: str | None, bounded_history: bool = True) -> bool:
    """Whether an unknown reason is missing evidence a trace can supply. A window behind `at` the
    trace does not cover is missing evidence when the history is bounded (a covering trace exists);
    when it is unbounded no finite trace covers it, and for a claim that the rule is undecided it is
    the claim itself."""
    if reason.startswith(("absent_atom:", "sampling_gap:", "identity_gap:")):
        return True
    return reason.startswith("window_truncated:") and (bounded_history or kind != "rule_undecided")


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
        for op in ("since", "count", "since_rise", "distance_while", "heading_since"):
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
                if dim == _dims()["second"]:                 # a primitive's time parameter is a window behind
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


def cert_unusable(k: int, d: dict, c: dict, windows: str = "", history: str = "", need: "_Need | None" = None) -> list[str]:
    """What keeps a certified divergence from being judged, as the reviewer is told it, by the
    standard replayed evidence meets (`admission`, with the rule's history `need`): empty when it is
    judged. An invalid case names its defects; insufficient evidence names what the trace must add."""
    cls, reasons = admission(d, c, need or _Need())
    head = f"divergence {k}"
    if cls == "judge":
        return []
    if cls == "insufficient":
        return [f"{head}: the rule's verdict at `at` is unknown only because the trace is incomplete: "
                + "; ".join(sorted({_trace_remedy(r, windows, history) for r in reasons}))]
    out = [f"{head}: the trace does not decode: {e}" for e in c.get("trace_decode_errors") or []]
    out += [f"{head}: the case does not decode: {e}" for e in c.get("case_decode_errors") or []]
    out += [f"{head}: trace check: {e}" for e in c.get("lint_errors") or []]
    out += [f"{head}: trace check: a supplied relation at {e}" for e in c.get("relation_errors") or []]
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


@dataclass
class Status:
    """What a rule review does with one divergence (`divergence_status`): its `status`, the messages
    the reviewer is shown, and the case to extend it continues (`prior`), if any."""
    status: str
    messages: list[str]
    prior: dict | None = None


def divergence_status(k: int, d, cert, law_text: str, binders: list[str], extendable: dict[str, dict],
                      windows: str = "", history: str = "", need: "_Need | None" = None) -> Status:
    """The one decision on divergence `k` that the reviewer's check reports and the submitted answer
    acts on. `cert()` gives its certificate record (None when the program printed none) and is
    called only for a divergence that can be run; `extendable` maps each case to extend to its
    recorded row. The status is:
    - `unstatable`: recorded as a gap candidate, nothing run;
    - `schema defects`: nothing run;
    - `unusable`: not certified, a defect `cert_unusable` names, no verdict of the rule, or an
      extension of a case to extend that does not continue its evidence (`node_extension_defects`);
    - `refuted`: the rule gives at `at` the verdict claimed for the law (`cert_refutations`) and
      the divergence extends no case to extend: an advisory;
    - `certifiable`: judged. An extension of a case to extend is judged whatever the rule gives,
      and is recorded as satisfied where the rule gives the law's verdict and that verdict is the
      one the case was upheld for."""
    schema = divergence_schema_defects(k, d, law_text, binders)
    if not schema and "unstatable" in d:
        return Status("unstatable", [f"divergence {k}: recorded as a gap candidate when submitted; nothing is run"])
    if schema or not _certifiable(d, binders):
        return Status("schema defects", schema or [f"divergence {k}: the divergence cannot be run"])
    c = cert()
    if c is None:
        return Status("unusable", [f"divergence {k}: not certified"])
    bad = cert_unusable(k, d, c, windows, history, need)
    if not bad and c.get("rule_result") is None:
        bad = [f"divergence {k}: the certificate printed no verdict of the rule"]
    refuted = cert_refutations(k, d, c)
    if bad:
        return Status("unusable", bad + refuted)
    ext = d.get("extends")
    prior = extendable.get(ext) if isinstance(ext, str) else None
    if prior is None:
        note = [f"divergence {k}: `extends` names no case to extend, so it is judged as a new case"] if "extends" in d else []
        return Status("refuted", refuted + note) if refuted else Status("certifiable", note)
    broken = node_extension_defects(prior, d, c, binders)
    if broken:
        return Status("unusable", [f"divergence {k} extends case {ext[:12]} but does not continue it: " + "; ".join(broken)])
    if refuted:
        return Status("certifiable", [f"divergence {k} extends case {ext[:12]}, and the rule gives at `at` the verdict you claim for the "
                                      "law: when submitted it is judged again, and recorded as satisfied where the law's verdict is still "
                                      "the one the case was upheld for — keep it"], prior)
    return Status("certifiable", [f"divergence {k} extends case {ext[:12]}: when submitted it is judged again"], prior)


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


def _case_glosses(onto: ontology.Ontology, case_atoms: list[str], run: Run | None = None,
                  declared: list[dict] | None = None) -> dict[str, str]:
    """The contracts of the names a case reads. An assumption the case states is shown as what it is,
    a declaration of the source with its catalogue meaning, never as a verified fact; an assumption
    the case does not state is not shown."""
    ids = [d.get("id") for d in declared or []]
    out = validate_phase.glosses_of(list(case_atoms) + ids, onto, run)
    for d in declared or []:
        if d.get("kind") == "asm":
            out[d["id"]] = f"{render_formula.DECLARED_BY_SOURCE}{out[d['id']]}"
    return out


# ---------------------------------------------------------------------------------------------
# A duty as an occurrence in the posted law, and a case's identity
# ---------------------------------------------------------------------------------------------
_SENTENCE_BREAK = re.compile(r"(?<=[.?!])\s+(?=[A-Z(\[\u201c\"])")


def law_digest(text: str) -> str:
    return _digest(text)[:16]


def sentence_around(text: str, start: int, end: int) -> str:
    """The sentence of the law's text that contains the characters `start`..`end`."""
    breaks = [0] + [m.end() for m in _SENTENCE_BREAK.finditer(text)] + [len(text)]
    a = max(b for b in breaks if b <= start)
    z = min((b for b in breaks if b >= end), default=len(text))
    return text[a:z].strip()


def _occurrence(law: corpus.Law, ranges: list[tuple[int, int]]) -> dict:
    dig = law_digest(law.text)
    ranges = sorted(tuple(r) for r in ranges)
    return {"id": f"{law.id}@{dig}:" + ",".join(f"{a}-{z}" for a, z in ranges), "law": law.id, "law_digest": dig,
            "ranges": [list(r) for r in ranges], "words": [law.text[a:z] for a, z in ranges],
            "context": sentence_around(law.text, ranges[0][0], ranges[-1][1]) if ranges else ""}


def duty_of(n: Node, law: corpus.Law) -> dict:
    """The duty a node formalizes, identified by its occurrence in the posted law: the character
    offsets of its obligation spans and the law's content digest; the sentence that contains it is
    its qualifying context. Two duties in identical words are two occurrences."""
    offs = span_offsets(n.get("segmentation", []), law.text)
    return _occurrence(law, [offs[str(s["id"])] for s in n.get("segmentation", []) if s.get("role") == "obligation" and str(s.get("id")) in offs])


def merged_ranges(text: str, ranges: list) -> list[tuple[int, int]]:
    """Character ranges of a law joined wherever only spaces or punctuation lie between them, so the
    same words read as the same stretches however a segmentation cuts them."""
    out: list[list[int]] = []
    for a, z in sorted(tuple(r) for r in ranges):
        if out and not re.search(r"\w", text[out[-1][1]:a]):
            out[-1][1] = max(out[-1][1], z)
        else:
            out.append([a, z])
    return [(a, z) for a, z in out]


def sibling_duties(n: Node, law: corpus.Law) -> list[dict]:
    """The law's other duties, as this node's segmentation marks them (`sibling` spans), each a
    stretch of the law's words: spans that adjoin are one stretch, whatever the cut."""
    offs = span_offsets(n.get("segmentation", []), law.text)
    ranges = [offs[str(s["id"])] for s in n.get("segmentation", []) if s.get("role") == "sibling" and str(s.get("id")) in offs]
    return [_occurrence(law, [r]) for r in merged_ranges(law.text, ranges)]


def overlaps(a: list, b: list) -> bool:
    return any(x0 < y1 and y0 < x1 for x0, x1 in a for y0, y1 in b)


def duty_block(n: Node, law: corpus.Law) -> str:
    """For a law of several duties: which one is judged, with its qualifying sentence, and which are
    judged separately; empty for a law of one duty."""
    others = sibling_duties(n, law)
    if not others:
        return ""
    d = duty_of(n, law)
    words = [law.text[a:z] for a, z in merged_ranges(law.text, d["ranges"])]
    out = ["### The duty judged here", "", *[f"> {w}" for w in words], "", f"in the sentence: \u201c{_ws(d['context'])}\u201d", "",
           "### Judged separately", "", "These duties of the law are judged on their own cases; every other word of the law applies by its meaning.", ""]
    out += [f"- \u201c{_ws(' '.join(o['words']))}\u201d (in the sentence: \u201c{_ws(o['context'])}\u201d)" for o in others]
    return "\n".join(out) + "\n"


_USER_QUANTIFIERS = ("forall_user", "exists_user")
_SORTED_QUANTIFIERS = ("forall_region", "exists_region", "forall_device", "exists_device")
_WINDOWS = ("holds_for", "within", "until_within", "at_last")


def rename_case(x, env: dict[str, str], bound) -> object:
    """A case formula with every name it uses renamed, in scope: a free name through `env` (a name
    `env` lacks is kept), a name a quantifier or an aggregate binds to `bound(name)`, which renames
    its occurrences in that binder's scope only. The names a formula holds: `var` fields, the
    variable of a user quantifier (`forall_user`, `exists_user`), the vehicle of a window
    (`subject`), of `distance_while` and of `heading_since`, and the caller's names a rule reference maps to (the
    values of `map`; its keys name the referenced rule's binders)."""
    if isinstance(x, list):
        return [rename_case(v, env, bound) for v in x]
    if not isinstance(x, dict):
        return x
    q = next((k for k in _USER_QUANTIFIERS if isinstance(x.get(k), str)), None)
    if q:
        b = bound(x[q])
        return {**{k: rename_case(v, env, bound) for k, v in x.items() if k not in (q, "body")},
                q: b, "body": rename_case(x.get("body"), {**env, x[q]: b}, bound)}
    if (any(k in x for k in _SORTED_QUANTIFIERS) or "aggregate" in x) and isinstance(x.get("var"), str):
        b = bound(x["var"])
        scoped = {**env, x["var"]: b}
        return {k: (b if k == "var" else rename_case(v, scoped if k in ("body", "where", "of") else env, bound)) for k, v in x.items()}
    out = {}
    for k, v in x.items():
        if isinstance(v, str) and (k == "var" or k in ("distance_while", "heading_since") or (k == "subject" and any(w in x for w in _WINDOWS))):
            out[k] = env.get(v, v)
        elif k == "map" and isinstance(v, dict) and ("rule" in x or "rule_applies" in x):
            out[k] = {i: env.get(o, o) if isinstance(o, str) else o for i, o in v.items()}
        else:
            out[k] = rename_case(v, env, bound)
    return out


def case_names(x, scope: frozenset = frozenset(), free: list | None = None, bound: list | None = None) -> tuple[list, list]:
    """The names a case formula uses free and the names its binders declare, each in order of
    first appearance (the traversal of `rename_case`)."""
    free = [] if free is None else free
    bound = [] if bound is None else bound
    rename_case(x, {}, lambda b: (bound.append(b), b)[1])
    def walk(y, sc):
        if isinstance(y, list):
            for v in y:
                walk(v, sc)
            return
        if not isinstance(y, dict):
            return
        q = next((k for k in _USER_QUANTIFIERS if isinstance(y.get(k), str)), None)
        if q:
            walk(y.get("body"), sc | {y[q]}); return
        if (any(k in y for k in _SORTED_QUANTIFIERS) or "aggregate" in y) and isinstance(y.get("var"), str):
            for k, v in y.items():
                if k != "var":
                    walk(v, sc | {y["var"]} if k in ("body", "where", "of") else sc)
            return
        for k, v in y.items():
            if isinstance(v, str) and (k == "var" or k in ("distance_while", "heading_since") or (k == "subject" and any(w in y for w in _WINDOWS))):
                if v not in sc and v not in free:
                    free.append(v)
            elif k == "map" and isinstance(v, dict) and ("rule" in y or "rule_applies" in y):
                for o in v.values():
                    if isinstance(o, str) and o not in sc and o not in free:
                        free.append(o)
            else:
                walk(v, sc)
    walk(x, set(scope))
    return free, bound


def canonical_names(case, entities: dict, grounding: dict, binders: list[str]) -> dict[str, str]:
    """The canonical name of each free name of a case: the node's binders by position (`user1`, …),
    the named entities by kind and trace id (`region1`, `device1`, …), any other free name by its
    first appearance (`x1`, …). A name a binder of the case declares is named apart, by
    `canonical_case`."""
    names: dict[str, str] = {}
    for b in [b for b in binders if b in grounding] + sorted(b for b in grounding if b not in binders):
        names[b] = f"user{len(names) + 1}"
    count: dict[str, int] = {}
    for e, v in sorted((entities or {}).items(), key=lambda kv: (str((kv[1] or {}).get("kind")), str((kv[1] or {}).get("id")))):
        kind = str((v or {}).get("kind") or "entity")
        count[kind] = count.get(kind, 0) + 1
        names.setdefault(e, f"{kind}{count[kind]}")
    for v in case_names(case)[0]:
        if v not in names:
            names[v] = f"x{sum(1 for x in names.values() if x.startswith('x')) + 1}"
    return names


def canonical_case(d: dict, canonical, binders: list[str]) -> dict:
    """The case in canonical names: `case`, `entities`, `grounding`, and `names` (canonical → as
    written). Each binder of the case is named `xK` after the free names, in order of appearance,
    so a renaming of the case, of its binders included, changes none of it."""
    names = canonical_names(canonical, d.get("entities") or {}, d.get("grounding") or {}, binders)
    back = {v: k for k, v in names.items()}
    def local(b):
        c = f"x{sum(1 for x in back if x.startswith('x')) + 1}"
        back[c] = b
        return c
    return {"case": rename_case(canonical, names, local), "entities": {names.get(e, e): v for e, v in (d.get("entities") or {}).items()},
            "grounding": {names.get(b, b): t for b, t in (d.get("grounding") or {}).items()}, "names": back}


def repair_case_names(r: dict) -> tuple[dict, bool]:
    """A recorded case whose binders' declarations, window vehicles, `distance_while` or `heading_since` vehicles or rule
    maps kept the names as written while its `var` fields were renamed (rows recorded before every
    name of a case was renamed), with each such name restored to its canonical one from the row's
    `names`. A name is restored only where it is out of scope and `names` gives its canonical
    name, so a consistent row is returned unchanged and a repaired one is not repaired again.
    Returns (row, whether it changed)."""
    case, names = r.get("case"), r.get("names")
    if not isinstance(case, dict) or not isinstance(names, dict):
        return r, False
    canon = {w: c for c, w in names.items() if isinstance(w, str)}
    known = set(r.get("grounding") or {}) | set(r.get("entities") or {})
    def fix(y, sc):
        if isinstance(y, list):
            return [fix(v, sc) for v in y]
        if not isinstance(y, dict):
            return y
        q = next((k for k in _USER_QUANTIFIERS if isinstance(y.get(k), str)), None)
        if q:
            b = y[q]
            free_b = case_names(y.get("body"))[0]
            if b not in free_b and canon.get(b) in free_b:
                b = canon[b]
            return {**y, q: b, "body": fix(y.get("body"), sc | {b})}
        if (any(k in y for k in _SORTED_QUANTIFIERS) or "aggregate" in y) and isinstance(y.get("var"), str):
            return {k: (fix(v, sc | {y["var"]}) if k in ("body", "where", "of") else (v if k == "var" else fix(v, sc))) for k, v in y.items()}
        out = {}
        for k, v in y.items():
            name_site = isinstance(v, str) and (k in ("distance_while", "heading_since") or (k == "subject" and any(w in y for w in _WINDOWS)))
            if name_site and v not in sc and v not in known and v in canon:
                out[k] = canon[v]
            elif k == "map" and isinstance(v, dict) and ("rule" in y or "rule_applies" in y):
                out[k] = {i: (canon[o] if isinstance(o, str) and o not in sc and o not in known and o in canon else o) for i, o in v.items()}
            else:
                out[k] = fix(v, sc)
        return out
    fixed = fix(case, frozenset())
    return ({**r, "case": fixed}, True) if fixed != case else (r, False)


def case_id(law: corpus.Law, d: dict, canon: dict) -> str:
    """A case's factual identity: the law's content, the trace, the case, its entities, the instant
    and its grounding, all in canonical names. The verdict claimed is not part of it."""
    return _digest({"law": law.id, "law_digest": law_digest(law.text), "trace": d.get("trace"), "case": canon["case"],
                    "entities": canon["entities"], "at": d.get("at"), "grounding": canon["grounding"]})


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
    duty: dict = field(default_factory=dict)              # the duty occurrence the node formalizes (`duty_of`)
    duty_block: str = ""                                  # what stage A is shown of it (`duty_block`)
    precedents: list[dict] = field(default_factory=list)  # the rulings on this duty, as they stand (`decided`)
    not_atoms: str = ""                                   # the ontology's section on what is not an atom, verbatim
    sources: list[dict] = field(default_factory=list)     # the definition sources the record borrows from, as fetched (`definitions.source_record`)
    rulings: list[dict] | None = None                     # the run's rulings as the review began (`ReviewRulings.base`); None: as they stand

    def decided(self, row: dict) -> None:
        """A ruling this review has made joins the precedents its later judges are shown, as it
        will stand once recorded: it replaces the precedent of the same identity, and an advisory
        row is no precedent."""
        ident = ruling_identity(row)
        if ident is not None:
            self.precedents = [r for r in self.precedents if ruling_identity(r) != ident]
        if row.get("ruling") and row["ruling"] not in ("advisory", "retired"):
            self.precedents.append(row)


def context_definitions(ctx) -> str:
    """What every role of a node's review is shown of definitions: those that apply to the law, then
    each definition source the record borrows from, whole, with its own."""
    from ..model import definitions as definitions_mod
    return definitions_block(ctx.definitions) + definitions_mod.render_sources(getattr(ctx, "sources", []), definitions_mod.SOURCES_HEADING)


def context_haystack(ctx) -> str:
    """The words a judge may quote: the law's, the applicable definitions', and each definition
    source's with the definitions that apply to it."""
    texts = [d.get("text") for d in ctx.definitions]
    texts += [t for s in getattr(ctx, "sources", []) for t in [s.get("text")] + [d.get("text") for d in s.get("definitions", [])]]
    return ctx.law.text + "\n" + "\n".join(_ws(t) for t in texts)


def definitions_block(defs: list[dict]) -> str:
    if not defs:
        return "### Definitions that apply\n\n(none of the law's words has a posted definition that applies)\n"
    return "### Definitions that apply\n\n" + "\n".join(f"- `{d['id']}` — {_ws(d.get('text'))}" + (f" {corpus.split_note(d)}" if d.get("split") else "")
                                                       for d in defs) + "\n"


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
        covered = "".join(f"; covered {c['class']} by {', '.join(c.get('covered_by', []))} (its label adds no membership evidence: "
                          "every member the definition admits within it carries a covering class)" for c in a.get("covered", []))
        out.append(f"- `{a['id']}` from `{a.get('definition')}`: included {', '.join(a.get('included', [])) or '(none)'}; "
                   f"unresolved {', '.join(a.get('unresolved', [])) or '(none)'}{covered}; every other class excluded"
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
        "law": f"### The law\n\n**{ctx.law.id}** — {ctx.law.title}\n\n{ctx.law.text}\n" + (f"\n{ctx.duty_block}" if ctx.duty_block else ""),
        "definitions": context_definitions(ctx),
        "case": "### The case\n\n" + rendered_case + "\n",
        "contracts": validate_phase.contracts_table(case_glosses)})


def stage_a_digest(run: Run, prompt: str, ctx: Context) -> str:
    return _digest({"prompt": prompt, "model": run.opts.model, "effort": run.opts.judge_effort, "precedence": ctx.precedence_hash})


def run_stage_a(run: Run, ctx: Context, prompt: str, out_dir: Path, label: str) -> dict:
    hay = context_haystack(ctx)
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=lambda a: stage_a_defects(a, hay),
                                           usage_label=f"{label}:{ctx.record.get('node_id', '')}", shared=True)
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
    return ("### The item (structural evidence: a word-level claim no trace can show)\n\n"
            f"The reviewer claims that the words \"{_ws(item.get('words'))}\" of span {item.get('span')} exclude "
            f"{_ws(item.get('factor'))}, which the contract the record carries for them admits ({_ws(item.get('nearest'))}). "
            "Uphold it when the contract's own words admit what the law's words exclude and the difference changes where the "
            "law applies or what it requires; otherwise the words permit the carried contract.\n"
            f"- outcomes available for this item: {', '.join(f'`{o}`' for o in sorted(WORD_LEVEL_OUTCOMES))}\n")


def stage_b_prompt(run: Run, ctx: Context, item: str, contracts: dict[str, str], lineage: str = "") -> str:
    return render.render("adjudicate.md", {
        "law_and_segmentation": f"### Law\n\n**{ctx.law.id}** — {ctx.law.title}\n\n{ctx.law.text}\n\nSpans:\n{ctx.seg}\n",
        "definitions": context_definitions(ctx),
        "record": "### Record\n\n```json\n" + json.dumps(ctx.record, ensure_ascii=False, indent=1) + "\n```\n\n"
                  + GapLedger.for_run(paths.GAPS_DIR, run).cited_block(ctx.record),
        "rendered": "### Rendering\n\n" + ctx.rendering + "\n",
        "contracts": validate_phase.contracts_table(contracts),
        "parameters": params_block(ctx.params),
        "aggregates": aggregates_block(ctx.aggregates),
        "item": item,
        "precedents": precedents_block([r for r in ctx.precedents if not lineage or r.get("lineage") != lineage]),
        "not_atoms": ctx.not_atoms})


def stage_b_digest(run: Run, prompt: str) -> str:
    return _digest({"prompt": prompt, "model": run.opts.model, "effort": run.opts.judge_effort})


def run_stage_b(run: Run, ctx: Context, prompt: str, allowed: set[str], out_dir: Path, label: str) -> dict:
    hay = context_haystack(ctx)
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=lambda a: stage_b_defects(a, hay, allowed),
                                           usage_label=f"{label}:{ctx.record.get('node_id', '')}", shared=True)
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
    """The rulings a review reads and appends to: the run's, or a candidate's own copy of them."""
    return getattr(run, "rulings_file", None) or run.dir / "rulings.jsonl"


def _all_rows(run: Run) -> list[dict]:
    """Every row, read strictly: a line that does not parse stops the run (`DataIntegrityError`).
    The run's own rows follow the rows it inherits (`inherited_rows`)."""
    return rulings_as_of(run)[1]


def rulings_as_of(run: Run, at: int | None = None) -> tuple[int, list[dict]]:
    """The run's rulings as they stood when its file held `at` rows (all of them when None), read in
    one pass: `(at, the rows)`, the inherited rows first. The file is only ever appended to, so its
    first `at` rows are what a review that began at `at` read, however many rows came after."""
    own = jsonl.read_strict(_rulings_file(run))
    at = len(own) if at is None else at
    return at, inherited_rows(run) + _named(own[:at])


_UNBOUND = re.compile(r"is not bound|is not a bound track")


def _named(rows: list[dict]) -> list[dict]:
    """The rows of one rulings file with each case's names made consistent (`repair_case_names`).
    An invalidation that only those names caused (its case changed by the repair, and its reason a
    name the case left unbound) decided nothing: it is left out, and a row that superseded it
    supersedes what it superseded, so the case it took out is judged again. The file is never
    rewritten."""
    out, void = [], {}
    for r in rows:
        r, changed = repair_case_names(r)
        if changed and r.get("route") == "invalidated" and r.get("supersedes") and _UNBOUND.search(str(r.get("reason", ""))):
            void[r.get("ruling_id")] = r["supersedes"]
            continue
        out.append(r)
    def target(s):
        while s in void:
            s = void[s]
        return s
    return [{**r, "supersedes": target(r["supersedes"])} if r.get("supersedes") in void else r for r in out]


_INHERITED_CACHE: dict[tuple, list[dict]] = {}


def inherited_rows(run: Run) -> list[dict]:
    """The upheld obligations of the records a run inherits from its base chain, read-only from
    every run of the chain that wrote one: a ruling a later generation made on a record an earlier
    one accepted (a reported defect adjudicated there) counts as much as the accepting run's. The
    chain's rulings are folded in generation order, each under an id qualified by its run
    (`<run>/<id>`, its supersessions qualified alike), so supersession across generations holds and
    no two runs' ids collide; a generation that plans a law again drops the earlier generations'
    rulings on that law's nodes. Of the folded effective rows, those on a record the run inherits are
    returned (`inherited_from` naming the run that wrote each), and a ruling of this run on the same
    identity supersedes one once. Rows of a law this run plans again are not read: its records are
    not inherited."""
    from ..store.state import listed_laws
    prov = getattr(run, "provenance", None) or {}
    chain = list(getattr(run, "base_chain", None) or [])
    if not prov or not chain:
        return []
    folded: list[dict] = []
    for rid in chain:
        listed = listed_laws((jsonl.read_json(paths.run_dir(rid) / "options.json", None) or {}).get("laws"))
        if listed:
            folded = [r for r in folded if str(r.get("subject", "")).startswith("drv.")
                      or nodeid.law_of(str(r.get("subject", "")))[0] not in listed]
        f = paths.run_dir(rid) / "rulings.jsonl"
        if not f.exists():
            continue
        st = f.stat()
        key = (str(f), st.st_mtime_ns, st.st_size)
        if key not in _INHERITED_CACHE:
            _INHERITED_CACHE[key] = _named(jsonl.read_strict(f))
        q = lambda x: x if not x or "/" in x else f"{rid}/{x}"
        folded += [{**r, "ruling_id": q(r.get("ruling_id")), "supersedes": q(r.get("supersedes")), "inherited_from": rid}
                   for r in _INHERITED_CACHE[key]]
    return [{**r, "supersedes": None} for r in effective_rows(folded) if r.get("subject") in prov and r.get("ruling") == "upheld"]


def effective_rows(rows: list[dict]) -> list[dict]:
    """Every row that no later row supersedes, in file order; rows without a `ruling_id` (earlier
    runs' rows) stand as they are. A broken chain is an error, never a guess."""
    by_id = {r["ruling_id"]: r for r in rows if r.get("ruling_id")}
    children: dict[str, list[str]] = {}
    for r in rows:
        s = r.get("supersedes")
        if s:
            if s not in by_id and "/" in s:                 # an inherited ruling, read from the run that holds it
                continue
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
    heads = [r for r in rows if not (r.get("ruling_id") and r["ruling_id"] in children)]
    return [r for r in _one_state_each(heads, by_id) if r.get("ruling") != "retired"]


def _one_state_each(heads: list[dict], by_id: dict[str, dict]) -> list[dict]:
    """Of unsuperseded rows that are states of one obligation — a case of one law on one duty, of
    one lineage, on the same trace, instant and grounding, stating the same facts whatever their
    names — only the last stands (rows recorded before a replay kept the identity it replayed),
    keeping the earlier duty it was carried from. A retirement counts as the state of the case it
    retires. A case carried to another duty, an extension stating more facts, and any other row
    stand as they are."""
    def obligation(r):
        x, seen = r, set()
        while x is not None and x.get("ruling") == "retired" and x.get("ruling_id") not in seen:
            seen.add(x.get("ruling_id"))
            x = by_id.get(x.get("supersedes"))
        if x is None or x.get("schema") != CASE_SCHEMA or not str(x.get("key", "")).startswith("law:") or not x.get("case_id") \
                or not isinstance(x.get("case"), dict):
            return None
        return (x.get("key"), x.get("duty"), x.get("lineage") or x.get("case_id"),
                _digest({"trace": x.get("trace"), "at": x.get("at"), "grounding": sorted((x.get("grounding") or {}).values()),
                         "facts": sorted(_grounded_conjuncts(x.get("case"), x.get("entities") or {}, x.get("grounding") or {}))}))
    keys = [obligation(r) for r in heads]
    last = {k: i for i, k in enumerate(keys) if k is not None}
    came_from = {}                                       # the duty an obligation was carried from, kept by its later states
    for r, k in zip(heads, keys):
        if k is not None and r.get("lineage_from"):
            came_from.setdefault(k, r["lineage_from"])
    return [({**r, "lineage_from": came_from[k]} if k in came_from and not r.get("lineage_from") else r)
            for i, (r, k) in enumerate(zip(heads, keys)) if k is None or last[k] == i]


def ruling_identity(row: dict) -> tuple | None:
    """What a ruling decides: a case judged on one duty occurrence (`case_id`, `duty`), or a
    structural finding on one occurrence of the law's words (`finding_id`). A concept's challenge is
    its case alone, whichever version of the lineage judged it, so a successor's ruling on a carried
    challenge supersedes its predecessor's."""
    if row.get("case_id") and str(row.get("key", "")).startswith("concept:"):
        return ("concept_case", row["case_id"])
    if row.get("finding_id") and str(row.get("key", "")).startswith("concept:"):
        if row.get("finding_root"):
            return ("concept_finding", row["finding_id"])
        return ("concept_finding_unrooted", row.get("subject"), row["finding_id"])   # written before findings had a root
    if row.get("case_id"):
        return ("case", row["case_id"], row.get("duty") or row.get("subject"))
    if row.get("finding_id"):
        return ("finding", row["finding_id"])
    return None


def _superseding(row: dict, effective: list[dict], supersedes: str | None) -> dict:
    """The row with the ruling it supersedes: the effective ruling of its identity, else `supersedes`."""
    ident = ruling_identity(row)
    if ident is not None:
        prev = next((r for r in effective if ruling_identity(r) == ident), None)
        row["supersedes"] = prev.get("ruling_id") if prev else supersedes
    return row


def append_ruling(run: Run, row: dict, supersedes: str | None = None, ruling_id: str | None = None) -> dict:
    """Append a row with a fresh `ruling_id`; an earlier ruling of the same identity is superseded by it.
    A row of a new identity may name the ruling it supersedes (`supersedes`: a concept case whose
    recorded content changed, under a new id, supersedes the ruling of the case it came from). A row
    given its `ruling_id` (a review's ruling, `ReviewRulings`) is appended once: when the run's file
    holds that id, the row recorded under it is returned and nothing is written."""
    with _RULINGS_LOCK:
        row = dict(row)
        if ruling_id:
            kept = next((r for r in jsonl.read_strict(_rulings_file(run)) if r.get("ruling_id") == ruling_id), None)
            if kept is not None:
                return kept
            row["ruling_id"] = ruling_id
        else:
            row["ruling_id"] = _digest({"row": row, "n": len(_all_rows(run))})[:20]
        _superseding(row, effective_rows(_all_rows(run)), supersedes)
        jsonl.append_atomic(_rulings_file(run), row)
        return row


class ReviewRulings:
    """The rulings one review decides, kept in order until its outcome is saved (`finish_review`),
    then recorded. Each has the id it is recorded under, fixed by the review's inputs, the rulings
    it began from and the row itself, so recording them again appends nothing. What the review
    reads of the rulings is `rows()`: the run's rulings as they stood when it began (`base`, the
    first `at` rows of the run's file), then its own."""
    def __init__(self, inputs: str | None, at: int, base: list[dict]):
        self.inputs, self.at, self.base = inputs, at, base
        self.items: list[dict] = []

    def rows(self) -> list[dict]:
        return self.base + [x["row"] for x in self.items]

    def add(self, row: dict, supersedes: str | None = None) -> dict:
        """The row as it will be recorded: its id, and the ruling it supersedes among `rows()`."""
        row = dict(row)
        content = _digest(row)
        again = sum(1 for x in self.items if x["content"] == content)
        row["ruling_id"] = _digest({"review": self.inputs, "at": self.at, "row": content, "again": again})[:20]
        _superseding(row, effective_rows(self.rows()), supersedes)
        self.items.append({"id": row["ruling_id"], "row": row, "supersedes": supersedes, "content": content})
        return row

    def saved(self) -> list[dict]:
        return [{"id": x["id"], "row": x["row"], "supersedes": x["supersedes"]} for x in self.items]


def _ruled(run: Run, rulings: ReviewRulings | None, row: dict, supersedes: str | None = None) -> dict:
    """A ruling decided: kept with its review's rulings, or, outside a review, recorded at once."""
    return rulings.add(row, supersedes) if rulings is not None else append_ruling(run, row, supersedes)


def precedent_rows(run: Run, key: str, duty: dict | None = None, rows: list[dict] | None = None) -> list[dict]:
    """The effective rulings under `key` (a law, or a concept), and for a law those on the duty
    occurrence judged (or one overlapping it): what was decided before, among `rows` (the run's
    rulings as they stand when None). A node's review takes them when it begins and adds each
    ruling it makes (`Context.decided`), so its judges rule one after another, each shown the
    earlier ones."""
    rows = [r for r in effective_rows(_all_rows(run) if rows is None else rows) if r.get("key") == key and r.get("ruling") != "advisory"]
    if duty:
        rows = [r for r in rows if r.get("duty") == duty.get("id")
                or (r.get("law_digest") == duty.get("law_digest") and overlaps(r.get("duty_ranges") or [], duty.get("ranges") or []))]
    return rows


def precedents_block(rows: list[dict]) -> str:
    """Earlier rulings, most recent first, so a situation decided once is decided alike."""
    if not rows:
        return "### Earlier rulings\n\n(none)\n"
    out = ["### Earlier rulings (most recent first)", ""]
    for r in reversed(rows[-30:]):
        out.append(f"- iteration {r.get('iteration')}, `{r.get('subject')}`: {r.get('item')} — **{r.get('ruling')}**: {r.get('reason')}")
    return "\n".join(out) + "\n"


#: The states of an upheld case that keep it an obligation: the current rule still diverges from the
#: law's verdict (`None` on a fresh upheld row, or `open`), or gives it (`satisfied`).
OBLIGATIONS = {None, "open", "satisfied"}


def upheld_rows(run: Run, laws: set[str], structural: bool = False, rows: list[dict] | None = None) -> list[dict]:
    """The obligations on these laws' duties: effective rulings upheld on a certified case, open or
    satisfied, oldest first (with `structural`, the upheld word-level findings, open), among `rows`
    (the run's rulings as they stand when None). A case leaves only when it is invalidated (it can
    no longer be evaluated), re-adjudicated (a judge's changed input no longer upholds it) or
    retired; a finding when it is re-adjudicated or retired."""
    keys = {f"law:{law}" for law in laws}
    schema = WORD_LEVEL_SCHEMA if structural else CASE_SCHEMA
    return [r for r in effective_rows(_all_rows(run) if rows is None else rows)
            if r.get("key") in keys and r.get("ruling") == "upheld" and r.get("schema") == schema
            and r.get("obligation") in (OBLIGATIONS - {"satisfied"} if structural else OBLIGATIONS)]


def obligations_of(run: Run, n: Node, law: corpus.Law, structural: bool = False, rows: list[dict] | None = None) -> list[tuple[dict, bool]]:
    """The obligations this node answers for, each with whether it is the node's own duty (True) or a
    candidate correspondence (False: an earlier duty whose occurrence overlaps this node's, after a
    merge, a split or a changed qualifying context; judged for this duty and kept only if upheld).
    A candidate already carried to this duty by an earlier review is not taken again. Read from
    `rows` (the run's rulings as they stand when None)."""
    duty = duty_of(n, law)
    rows = upheld_rows(run, {law.id}, structural, rows)
    carried = {(r.get("lineage_from") or "") for r in rows if r.get("duty") == duty["id"]}
    out = []
    for r in rows:
        if r.get("duty") == duty["id"] or (not r.get("duty") and r.get("subject") == n.id):
            out.append((r, True))
        elif r.get("law_digest") == duty["law_digest"] and overlaps(r.get("duty_ranges") or [], duty["ranges"]) \
                and f"{r.get('case_id') or r.get('finding_id')}|{r.get('duty')}" not in carried:
            out.append((r, False))
    return out


def upheld_block(run: Run, laws: set[str]) -> str:
    """The certified cases earlier reviews upheld against these laws' nodes, and the structural
    evidence upheld and still open, for a planning session, rendered as the judges saw them."""
    rows = upheld_rows(run, laws)
    structural = upheld_rows(run, laws, structural=True)
    if not rows and not structural:
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
    if structural:
        out += ["", "Structural evidence (no trace can show it; decided by a judge on the law's words and the contracts alone, "
                "and decided again on every later record of the node; it stays open while it is still upheld):", ""]
        for r in structural:
            out.append(f"- `{r.get('subject')}` (iteration {r.get('iteration')}, open): {_ws(r.get('item'))[:400]}; "
                       f"upheld because: {_ws((r.get('stage_b') or {}).get('reason'))[:300]}")
    return "\n".join(out) + "\n"


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
                     previous: dict | None = None, lineage: str = "") -> Judged:
    """Stage A, the comparison, the sensitivity and stage B for one admitted divergence, in
    canonical names. A previous ruling's judge outputs are reused when that judge's digest is
    unchanged. `lineage` is the case's lineage when it continues an earlier case (a replay, an
    extended trace); a new case starts its own. Raises `Deferred` when a judge's answer stays invalid."""
    binders = [b["name"] for b in n.get("binders", [])]
    canon = canonical_case(d, c.get("canonical_case"), binders)
    glosses_case = _case_glosses(onto, c.get("case_atoms") or [], run, c.get("case_declarations") or [])
    times = [sc.get("t") for sc in ((d.get("trace") or {}).get("scenes") or []) if isinstance(sc, dict) and isinstance(sc.get("t"), int)]
    rendered = render_case(canon["case"], canon["entities"], d.get("at"), canon["grounding"], glosses_case, times)
    cid = case_id(ctx.law, d, canon)
    lineage = lineage or (previous or {}).get("lineage") or cid
    rule = c.get("rule_result") or {}
    base = {"schema": CASE_SCHEMA, "key": f"law:{n.law}", "subject": n.id, "iteration": run.iteration, "case_id": cid, "lineage": lineage,
            "duty": ctx.duty.get("id"), "duty_ranges": ctx.duty.get("ranges"), "law_digest": ctx.duty.get("law_digest"),
            "kind": d.get("kind"), "situation": _ws(d.get("situation"))[:600], "law_words": d.get("law_words"),
            "lawful_verdict": d.get("lawful_verdict"), "grounding": canon["grounding"], "trace": d.get("trace"),
            "case": canon["case"], "entities": canon["entities"], "names": canon["names"], "at": d.get("at"),
            "case_rendered": rendered, "rule_result": rule}
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
    base = {**base, "stage_a": stage_a, "stageA_digest": a_dig,
            "sibling_quote": bool(ctx.duty_block) and quote_in_siblings(n, ctx.law, stage_a.get("law_words"))}
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
    b_prompt = stage_b_prompt(run, ctx, stage_b_item(rendered, stage_a, rule, sensitive, allowed), contracts, lineage)
    b_dig = stage_b_digest(run, b_prompt)
    if previous and previous.get("stageB_digest") == b_dig and previous.get("stage_b"):
        stage_b = previous["stage_b"]
    else:
        stage_b = run_stage_b(run, ctx, b_prompt, allowed, out_dir, f"{label}_stage_b")
    outcome = stage_b["outcome"]
    key = f"case:{lineage[:16]}"
    row = {**base, "route": outcome, "ruling": outcome, "sensitive": sensitive, "stage_b": stage_b, "stageB_digest": b_dig,
           "reason": _ws(stage_b.get("reason")), "item": line, "outcome": key,
           "certificate_digests": [a.get("certificate_digest") for a in ctx.aggregates if a.get("certificate_digest")] if outcome == "verified_aggregate" else []}
    question = ""
    if outcome == "parameter_question":
        names = ", ".join(f"`{x}`" for x in questioned_parameters(ctx.params, stage_b.get("reason", "")))
        question = (f"`{n.law}` ({n.id}): the rule's verdict on a certified case turns on the value of {names}, which you have not "
                    f"reviewed — {_ws(stage_b.get('reason'))[:300]}")
    return Judged(outcome, row, f"{line}; stage B: {outcome} — {_ws(stage_b.get('reason'))[:200]}", key=key, question=question)


def quote_in_siblings(n: Node, law: corpus.Law, quote) -> bool:
    """Whether stage A's quote lies only in the law's other duties: recorded as a measurement, never a route."""
    offs = span_offsets(n.get("segmentation", []), law.text)
    sib = [offs[str(s["id"])] for s in n.get("segmentation", []) if s.get("role") == "sibling" and str(s.get("id")) in offs]
    own = [offs[str(s["id"])] for s in n.get("segmentation", []) if s.get("role") not in ("sibling", "boilerplate") and str(s.get("id")) in offs]
    i = law.text.find(_ws(quote)) if _ws(quote) else -1
    if i < 0 or not sib:
        return False
    q = [(i, i + len(_ws(quote)))]
    return overlaps(q, sib) and not overlaps(q, own)


def word_level_defects(n: Node, law: corpus.Law, item: dict) -> list[str]:
    """Why a word-level item cannot be judged: its span is not one of the node's, or its words are
    not verbatim within that span."""
    offs = span_offsets(n.get("segmentation", []), law.text)
    r = offs.get(str(item.get("span")))
    if r is None:
        return [f"word-level item: span {item.get('span')!r} is not a span of `{n.id}`"]
    if not _ws(item.get("words")) or _ws(item.get("words")) not in _ws(law.text[r[0]:r[1]]):
        return [f"word-level item: \"{_ws(item.get('words'))[:120]}\" is not verbatim in span {item.get('span')}"]
    return []


def words_at(n: Node, law: corpus.Law, item: dict) -> list[int]:
    """Where a word-level item's words occur in the law: within its span, else the span itself."""
    offs = span_offsets(n.get("segmentation", []), law.text)
    r = offs.get(str(item.get("span")), (0, 0))
    i = law.text.find(_ws(item.get("words")), r[0]) if _ws(item.get("words")) else -1
    return [i, i + len(_ws(item.get("words")))] if i >= 0 else list(r)


def finding_id(n: Node, law: corpus.Law, item: dict) -> str:
    """A structural finding's identity: the occurrence of its words in the law, the contract clause it
    names, and the record's mapping of that span when it was found."""
    where = words_at(n, law, item)
    mapping = sorted({a for e in n.get("elements", []) if str(e.get("span")) == str(item.get("span"))
                      for a in list(e.get("atoms") or []) + list(e.get("derived") or [])})
    return _digest({"law": law.id, "law_digest": law_digest(law.text), "words_at": where, "clause": _ws(item.get("nearest")), "mapping": mapping})


def judge_word_level(run: Run, n: Node, ctx: Context, item: dict, out_dir: Path, label: str, previous: dict | None = None) -> Judged:
    """Stage B on a structural finding (no trace can show it), against the current record. Its row
    carries the finding's identity, so an upheld finding is an obligation re-adjudicated before
    every later acceptance."""
    fid = (previous or {}).get("finding_id") or finding_id(n, ctx.law, item)
    prompt = stage_b_prompt(run, ctx, word_level_item(item), ctx.rule_glosses, lineage=fid)
    dig = stage_b_digest(run, prompt)
    b = previous["stage_b"] if previous and previous.get("stageB_digest") == dig and previous.get("stage_b") else \
        run_stage_b(run, ctx, prompt, WORD_LEVEL_OUTCOMES, out_dir, label)
    line = (f"structural evidence: span {item.get('span')} — \"{_ws(item.get('words'))}\" is carried by a broader contract "
            f"({_ws(item.get('nearest'))[:160]}); the words exclude {_ws(item.get('factor'))[:160]}: file a gap on this span")
    key = f"finding:{fid[:16]}"
    row = {"schema": WORD_LEVEL_SCHEMA, "label": "word_level", "evidence": "structural", "key": f"law:{n.law}", "subject": n.id, "iteration": run.iteration,
           "finding_id": fid, "lineage": fid, "words_at": (previous or {}).get("words_at") or words_at(n, ctx.law, item), "duty": ctx.duty.get("id"), "duty_ranges": ctx.duty.get("ranges"),
           "law_digest": ctx.duty.get("law_digest"), "item_data": {k: item.get(k) for k in ("kind", "span", "words", "factor", "nearest")},
           "item": line, "ruling": b["outcome"], "reason": _ws(b.get("reason")), "stage_b": b, "stageB_digest": dig,
           "obligation": "open" if b["outcome"] == "upheld" else None, "outcome": key}
    return Judged(b["outcome"], row, f"{line} — stage B: {b['outcome']}: {_ws(b.get('reason'))[:200]}", key=key)


# ---------------------------------------------------------------------------------------------
# Admission: one standard for fresh and replayed evidence
# ---------------------------------------------------------------------------------------------
def bounded(need: "_Need") -> bool:
    """Whether the history a verdict reads has a finite length at the parameter values: then a trace
    that covers it always exists. One that reaches the trace's start or end, or whose length the
    reading does not fix, is unbounded."""
    return not (need.to_start or need.to_end or need.unknown)


def admission(d: dict, c: dict, need: "_Need") -> tuple[str, list[str]]:
    """What a certified divergence is, fresh or replayed: `invalid` (it does not decode, fails the
    trace or witness check, or the case is not true at `at`), `insufficient` (the rule's verdict is
    unknown only for missing evidence a longer, denser or fuller trace supplies: an absent
    observation, a sampling gap, an identity gap, or a window behind `at` the trace does not cover
    when the history is bounded), or `judge` (a decided verdict, or an unknown one that is the
    rule's: a window no finite trace covers, a reason no trace removes). The reasons come with it.
    No class erases an obligation."""
    head = "the case"
    bad = [f"the trace does not decode: {e}" for e in c.get("trace_decode_errors") or []]
    bad += [f"the case does not decode: {e}" for e in c.get("case_decode_errors") or []]
    bad += [f"trace check: {e}" for e in c.get("lint_errors") or []] + [f"witness: {e}" for e in c.get("witness_errors") or []]
    bad += [f"trace check: a supplied relation at {e}" for e in c.get("relation_errors") or []]
    bad += [f"case: {e}" for e in c.get("case_check_errors") or []]
    cv = c.get("case_value")
    if isinstance(cv, dict) and cv.get("value") != "true":
        why = ", ".join(cv.get("unknown_reasons") or [])
        bad.append(f"{head} is {cv.get('value')} at `at`" + (f" ({why})" if why else "")
                   + (" once the supplied relations Core computes were left to Core: it rested on a contradiction of the scene ("
                      + "; ".join(c["relations_stripped"])[:300] + ")" if c.get("relations_stripped") else ""))
    if bad:
        return "invalid", bad
    rr = c.get("rule_result") or {}
    if rr.get("verdict") == "unknown":
        reasons = rr.get("unknown_reasons") or []
        if reasons and not _aggregate_unresolved_only(reasons) and all(_trace_defect(r, d.get("kind"), bounded(need)) for r in reasons):
            return "insufficient", reasons
    return "judge", []


# ---------------------------------------------------------------------------------------------
# Replay: the obligations of this node's duty, judged again against the current rule
# ---------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------
# Continuity: when a new submission continues a recorded obligation's evidence
# ---------------------------------------------------------------------------------------------
_ID_KEYS = ("track", "id")


def _keyed(xs: list):
    """A list of scene entities by identity (a user by `track`, a structure or device by `id`, a
    relation by its pair), or None for a list of anything else."""
    if not xs or not all(isinstance(x, dict) for x in xs):
        return None
    for k in _ID_KEYS:
        if all(k in x for x in xs):
            return {json.dumps(x[k]): x for x in xs}
    if all("a" in x and "b" in x for x in xs):
        return {f"{x['a']}-{x['b']}": x for x in xs}
    return None


def _kept(old, new, path: str) -> list[str]:
    """Where `new` does not keep a value `old` states: every key `old` states is in `new` with the
    same value, recursively; a list of entities keeps each entity by identity; `new` may add keys,
    entities and scenes."""
    if isinstance(old, dict):
        if not isinstance(new, dict):
            return [f"{path} is no longer an object"]
        out = []
        for k, v in old.items():
            if k not in new:
                out.append(f"{path}.{k} is left out")
            else:
                out += _kept(v, new[k], f"{path}.{k}")
        return out
    if isinstance(old, list) and _keyed(old) is not None:
        o, nw = _keyed(old), _keyed(new) if isinstance(new, list) else None
        if nw is None:
            return [f"{path} is no longer a list of the same entities"]
        out = []
        for k, v in o.items():
            out += [f"{path}[{k}] is left out"] if k not in nw else _kept(v, nw[k], f"{path}[{k}]")
        return out
    return [] if old == new else [f"{path} changed from {json.dumps(old)[:60]} to {json.dumps(new)[:60]}"]


_COMPUTED_CACHE: dict[str, list] = {}


def computed_relation_fields(traces: list) -> list[list]:
    """For each written trace, the supplied relation fields Core computes from its own scene, as
    Lean's relation check finds them (`[t, a-b, atom]`, the `RELCHECK` lines): the fields a
    normalized trace leaves to Core. A trace that supplies no relation, or does not decode, has
    none. Raises `HarnessFailure` when the check does not run."""
    import tempfile
    from ..lean import relations
    out: list = [None] * len(traces)
    todo = {}
    for i, tr in enumerate(traces):
        scenes = tr.get("scenes") if isinstance(tr, dict) else None
        if not isinstance(scenes, list) or not any(isinstance(sc, dict) and sc.get("relations") for sc in scenes):
            out[i] = []
            continue
        key = _digest(tr)
        if key in _COMPUTED_CACHE:
            out[i] = _COMPUTED_CACHE[key]
        else:
            todo[i] = key
    if todo:
        with tempfile.TemporaryDirectory() as t:
            rows = []
            for i in todo:
                f = Path(t) / f"trace_{i}.json"
                f.write_text(json.dumps(traces[i], ensure_ascii=False), encoding="utf-8")
                rows.append(f"({i}, {json.dumps(str(f))})")
            prog = Path(t) / "computed.lean"
            prog.write_text("import TrafficSpec.Core\nopen TrafficSpec Lean\n" + relations.lean_defs() + f"""
def main : IO Unit := do
  for (k, p) in ([{", ".join(rows)}] : List (Nat × String)) do
    match Decode.parse Decode.trace (← IO.FS.readFile p) with
    | .ok τ => RelCheck.run (toString k) τ
    | .error _ => pure ()
""", encoding="utf-8")
            with lean.evaluation_lock(paths.LIBRARY):
                code, text = lean.lean_run(paths.LIBRARY, prog)
            if code != 0:
                raise HarnessFailure(f"the relation check did not run: {text[-400:]}")
        found: dict[int, list] = {i: [] for i in todo}
        for line in text.splitlines():
            parts = line.split("\t")
            if parts[0] == "RELCHECK" and len(parts) >= 5 and parts[1].isdigit() and int(parts[1]) in found:
                found[int(parts[1])].append([parts[2], parts[3], parts[4].split(":", 1)[0]])
        for i, key in todo.items():
            _COMPUTED_CACHE[key] = out[i] = found[i]
    return out


def normalized_trace(trace: dict, fields: list) -> dict:
    """The evidence a written trace states: its decoder-read keys, without the supplied relation
    fields Core computes from that scene and pair (`fields`, from `computed_relation_fields`). A
    relation Core cannot compute there (no geometry for it, or `visible`) stays evidence. Replay and
    continuity compare traces in this one form."""
    out = strip_computed_relations(read_part(trace), fields)
    for sc in out.get("scenes") or []:
        if isinstance(sc, dict) and sc.get("relations") == []:
            del sc["relations"]
    return out


def trace_extension_defects(old: dict, new: dict) -> list[str]:
    """Why a trace does not extend a recorded one: a scene of the recorded trace is missing at its
    instant, or a field it states changed. Scenes may be added and unobserved fields filled. Both
    traces are compared normalized: only the relation fields Core computes from that scene and pair
    are left to Core; every other supplied value, a measured relation Core cannot compute among
    them, must be kept."""
    if not isinstance(new, dict):
        return ["the trace is not an object"]
    if not isinstance(old, dict):
        return []
    fo, fn = computed_relation_fields([old, new])
    o, n = normalized_trace(old, fo), normalized_trace(new, fn)
    by_t = {sc.get("t"): sc for sc in n.get("scenes") or [] if isinstance(sc, dict)}
    out = []
    for sc in o.get("scenes") or []:
        if not isinstance(sc, dict):
            continue
        if sc.get("t") not in by_t:
            out.append(f"the scene at t={sc.get('t')} is left out")
        else:
            out += _kept(sc, by_t[sc["t"]], f"t={sc.get('t')}")
    return out


def _grounded_conjuncts(case, entities: dict, grounding: dict) -> set[str]:
    """The facts a case states, each conjunct with its named entities and binders replaced by what
    they denote in the trace (`track:1`, `region:10`), and its own bound variables numbered by first
    appearance in it: the same facts compare equal whatever the names, and adding a conjunct
    changes none of the others."""
    labels = {b: f"track:{t}" for b, t in (grounding or {}).items()}
    labels.update({e: f"{(v or {}).get('kind')}:{(v or {}).get('id')}" for e, v in (entities or {}).items()})
    out = set()
    for c in _conjuncts(case):
        n = iter(range(1 << 30))
        env = {**labels, **{v: f"b{next(n)}" for v in case_names(c)[0] if v not in labels}}
        out.add(json.dumps(rename_case(c, env, lambda _b: f"b{next(n)}"), sort_keys=True))
    return out


def node_extension_defects(prior: dict, d: dict, c: dict, binders: list[str]) -> list[str]:
    """Why a divergence that `extends` a recorded case does not continue it: its trace does not
    extend the recorded trace, its binders are grounded to other tracks, it is read at another
    instant, or its case leaves out a fact the recorded case states (facts may be added)."""
    canon = canonical_case(d, c.get("canonical_case"), binders)
    out = trace_extension_defects(prior.get("trace") or {}, d.get("trace") or {})
    if canon["grounding"] != (prior.get("grounding") or {}):
        out.append(f"the binders are grounded to {canon['grounding']}, the recorded case to {prior.get('grounding')}")
    if d.get("at") != prior.get("at"):
        out.append(f"it is read at t={d.get('at')}, the recorded case at t={prior.get('at')}")
    lost = _grounded_conjuncts(prior.get("case"), prior.get("entities") or {}, prior.get("grounding") or {}) \
        - _grounded_conjuncts(canon["case"], canon["entities"], canon["grounding"])
    if lost:
        out.append(f"its case leaves out {len(lost)} fact(s) the recorded case states")
    return out


def concept_extension_defects(old: dict, d: dict, rec) -> list[str]:
    """Why a concept divergence that `extends` a recorded challenge does not continue it: its trace
    does not extend the recorded trace; a recorded formal (a track, a region, a literal, a nat, a parameter)
    keeps no value under a formal of the same sort — the same name, or one formal the successor
    renamed it to, holding the same value; or its instant, its contract words or its claimed
    verdict or interval changed. Only a formal the recorded challenge did not have is new; its
    contract words may change only where the recorded ones are no longer verbatim in the current
    contract (the divergence's own words are, by its schema); its claim only where the challenge's
    effective claim is `undecided` under the current contract."""
    out = trace_extension_defects(old.get("trace") or {}, d.get("trace") or {})
    sorts = {a["name"]: a.get("sort") for a in rec.args()} | {p["name"]: "param" for p in rec.params()}
    oi, ni = old.get("instance") or {}, d.get("instance") or {}
    def values(inst: dict, g: dict, regions: dict) -> dict[str, tuple[str, str]]:
        v = {f: ("track", json.dumps(t)) for f, t in (g or {}).items()}
        v |= {f: ("region", json.dumps(r)) for f, r in (regions or {}).items()}
        v |= {f: ("literal", json.dumps(x)) for f, x in (inst.get("literals") or {}).items()}
        v |= {f: ("nat", json.dumps(x)) for f, x in (inst.get("nats") or {}).items()}
        v |= {f: ("param", json.dumps(x)) for f, x in (inst.get("params") or {}).items()}
        return v
    was = values(oi, old.get("grounding") or {}, old.get("regions") or {})
    now = values(ni, d.get("grounding") or {}, d.get("regions") or {})
    taken = set()
    for f, (sort, val) in was.items():
        if f in now and sorts.get(f) == sort:
            if now[f] != (sort, val):
                out.append(f"formal `{f}` holds {now[f][1]}, the recorded challenge {val}")
            taken.add(f)
            continue
        same = [g for g, sv in now.items() if sv == (sort, val) and g not in was and g not in taken]
        if len(same) != 1:
            out.append(f"recorded formal `{f}` ({sort} {val}) corresponds to " + ("no formal" if not same else f"several formals {same}")
                       + " of the same sort holding its value")
        else:
            taken.add(same[0])
    if d.get("at") != old.get("at"):
        out.append(f"it is read at t={d.get('at')}, the recorded challenge at t={old.get('at')}")
    if _ws(d.get("contract_words")) != _ws(old.get("contract_words")) and _in(str(old.get("contract_words") or ""), _ws(rec.get("contract"))):
        out.append("its contract words are not the recorded ones, which the contract still states verbatim")
    if (d.get("contract_verdict") != old.get("contract_verdict") or d.get("contract_value") != old.get("contract_value")) \
            and not undecided_under(old, contract_digest(rec)):
        out.append("its claimed verdict or interval is not the recorded one")
    return out


#: The fields of a recorded case: what a replay certifies again.
CASE_FACTS =("kind", "situation", "law_words", "lawful_verdict", "grounding", "trace", "case", "entities", "names", "at", "case_rendered")


@dataclass
class Replayed:
    """What a replay found: `reasons` and `keys` of the obligations still decided otherwise (open),
    `satisfied` keys (the rule now gives the law's verdict), `notes`, and `evidence`: the obligations
    whose evidence the reviewer must extend before they can be judged (each with `case_id`, the
    rendered case, its trace, the reasons and what to add)."""
    reasons: list[str] = field(default_factory=list)
    keys: list[str] = field(default_factory=list)
    satisfied: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)
    evidence: list[dict] = field(default_factory=list)


def _to_node(r: dict, binders: list[str]) -> tuple[dict | None, str]:
    """A recorded case in the node's own names: `userK` is the node's K-th binder. A case recorded
    before names were canonical grounds the binders under the node's own names, and is taken as it
    is. None, with why, when the case names road users the node's binders do not correspond to."""
    g = r.get("grounding") or {}
    if g and set(g) == set(binders):
        return {"kind": r.get("kind"), "situation": r.get("situation"), "law_words": r.get("law_words"), "lawful_verdict": r.get("lawful_verdict"),
                "grounding": dict(g), "trace": r.get("trace"), "case": r.get("case"), "entities": r.get("entities") or {}, "at": r.get("at")}, ""
    users = sorted((k for k in (r.get("grounding") or {}) if re.fullmatch(r"user\d+", k)), key=lambda k: int(k[4:]))
    if len(users) != len(binders) or len(users) != len(r.get("grounding") or {}):
        return None, (f"the case grounds {len(r.get('grounding') or {})} road user(s), the node has the binders {binders}: "
                      "supply the grounding of each binder")
    names = {u: b for u, b in zip(users, binders)}
    case, entities = r.get("case"), r.get("entities") or {}
    free, declared = case_names(case)
    used = set(free) | set(declared) | set(entities) | set(binders)
    def fresh(base: str) -> str:                       # a name none of the case's or the node's names takes
        k = 1
        while f"{base}_{k}" in used:
            k += 1
        used.add(f"{base}_{k}")
        return f"{base}_{k}"
    env = dict(names)
    for v in list(entities) + [v for v in free if v not in names and v not in entities]:
        if v in binders:                               # an entity or other free name the node's binders take
            env[v] = fresh(v)
    return {"kind": r.get("kind"), "situation": r.get("situation"), "law_words": r.get("law_words"), "lawful_verdict": r.get("lawful_verdict"),
            "grounding": {names[u]: t for u, t in r["grounding"].items()}, "trace": r.get("trace"),
            "case": rename_case(case, env, lambda b: fresh(b) if b in binders else b),
            "entities": {env.get(e, e): v for e, v in entities.items()}, "at": r.get("at")}, ""


def _words_span(n: Node, law: corpus.Law, item: dict, words_at: list | None) -> dict:
    """A recorded word-level item with its span renamed to the node's span holding the same words."""
    if not words_at:
        return item
    offs = span_offsets(n.get("segmentation", []), law.text)
    sid = next((k for k, (a, z) in offs.items() if a <= words_at[0] and words_at[1] <= z), None)
    return {**item, "span": sid} if sid else item


def replay_obligations(run: Run, n: Node, ctx: Context, onto: ontology.Ontology, reading: Reading, need: "_Need",
                       out_dir: Path, pending: list | None = None, questions: list | None = None) -> Replayed:
    """Each obligation of the node's duty (an upheld case, open or satisfied; an open structural
    finding), and each candidate correspondence from an earlier duty whose occurrence overlaps it,
    as the rulings stood when the review began (`ctx.rulings`), is judged again under the current
    Core, rule and reading, by the admission standard fresh evidence meets (`admission`):
    - a case that is `invalid` (it does not decode, fails a check, or is not true) is `invalidated`:
      it leaves the obligations, and a note starting "obligation invalidated" goes to the operator;
    - a case whose evidence is `insufficient` (a window it does not cover when the history is
      bounded, a sampling gap, an absent observation, or road users the node's binders do not
      correspond to) stays an obligation, and its owner is the reviewer: it is listed in `evidence`;
    - a case still upheld stays `open` (the node is returned); one on which the rule gives the
      recorded law's verdict stays an obligation, `satisfied`; any other judgment is
      `re-adjudicated` and leaves;
    - an open structural finding is re-adjudicated by stage B against the current record: still
      upheld, it stays open; otherwise it leaves.
    A candidate correspondence is kept, under this duty and with its lineage, only when it is
    upheld or satisfied here; otherwise a note says so. A row is appended only when the state or a
    judge's digest changes, so a replay of an unchanged rule adds none. With `pending`, the rows
    are collected there, and recorded only when the review reaches its outcome. Each row joins the
    precedents the review's later judges are shown (`Context.decided`). A case that stage B
    now rules a parameter question keeps its state, and its question goes to `questions`. Raises
    `Deferred` when a judge's answer stays invalid or the certificate program fails."""
    out = Replayed()

    def record(row: dict) -> None:
        if pending is not None:
            pending.append(row)
        else:
            append_ruling(run, row)
        ctx.decided(row)
    binders = [b["name"] for b in n.get("binders", [])]
    divs, by_k = {}, {}
    for r, own in obligations_of(run, n, ctx.law, False, getattr(ctx, "rulings", None)):
        d, why = _to_node(r, binders)
        if d is None:
            if own:
                out.evidence.append({"case_id": r.get("case_id"), "case_rendered": r.get("case_rendered"), "trace": r.get("trace"),
                                     "at": r.get("at"), "grounding": r.get("grounding"), "reasons": [why], "remedy": why})
                out.notes.append(f"obligation of iteration {r.get('iteration')} on `{n.id}` needs its evidence extended: {why}")
            else:
                out.notes.append(f"case {str(r.get('case_id'))[:12]} of the earlier duty overlapping `{n.id}` is not carried over: {why}")
            continue
        k = len(divs) + 1
        divs[k], by_k[k] = d, (r, own)
    certs = {}
    if divs:
        try:
            certs = certify(run, n, divs, reading, out_dir / "replay", saved=True)
        except HarnessFailure as e:
            raise Deferred("certificate", f"replay: {e}")
    carry = lambda r: {"lineage_from": f"{r.get('case_id') or r.get('finding_id')}|{r.get('duty')}"}
    # the next state of the node's own obligation keeps the identity it was recorded under (its case
    # id, however the case's names hash today, and the earlier duty it was carried from), so it
    # supersedes that obligation; a case carried to this duty from an overlapping one starts its own
    same = lambda r, own: ({"case_id": r.get("case_id"), **({"lineage_from": r["lineage_from"]} if r.get("lineage_from") else {})}
                           if own else carry(r))
    facts = lambda r: {k: r.get(k) for k in CASE_FACTS}       # the recorded case, kept under every later state
    for k, d in divs.items():
        (r, own), c = by_k[k], certs.get(k) or {}
        cls, why = admission(d, c, need) if c else ("invalid", ["the certificate printed nothing for the case"])
        if cls == "invalid":
            if own:
                record({**r, "iteration": run.iteration, "route": "invalidated", "ruling": "advisory", "obligation": "invalidated",
                        "rule_result": c.get("rule_result"), "reason": "; ".join(why)[:600]})
                out.notes.append(f"obligation invalidated: the upheld case of iteration {r.get('iteration')} on `{n.id}` can no longer be "
                                 f"evaluated — {'; '.join(why)[:240]}")
            continue
        if cls == "insufficient":
            remedy = "; ".join(sorted({_trace_remedy(x, "", history_text(need)) for x in why}))
            if own:
                out.evidence.append({"case_id": r.get("case_id"), "case_rendered": r.get("case_rendered"), "trace": r.get("trace"),
                                     "at": r.get("at"), "grounding": r.get("grounding"), "reasons": why, "remedy": remedy})
                out.notes.append(f"obligation of iteration {r.get('iteration')} on `{n.id}` needs its evidence extended: {remedy[:240]}")
            continue
        j = judge_divergence(run, n, ctx, onto, d, c, out_dir / "replay", f"replay_{k}", previous=r if own else None,
                             lineage=r.get("lineage") or r.get("case_id"))
        law_then = (r.get("stage_a") or {}).get("verdict")
        law_now = (j.row.get("stage_a") or {}).get("verdict")
        same_law = law_now is not None and law_then is not None and _equivalent(law_now, law_then) \
            and j.route not in ("stage_a_undetermined", "aggregate_unresolved")
        key = r.get("outcome") or j.key
        if same_law and j.route == "rule_agrees":
            row = {**facts(r), **j.row, "route": "upheld", "ruling": "upheld", "obligation": "satisfied", "reason": r.get("reason"),
                   "stage_b": r.get("stage_b"), "stageB_digest": r.get("stageB_digest"), "outcome": key, **same(r, own)}
            if not own or r.get("obligation") != "satisfied" or row["stageA_digest"] != r.get("stageA_digest"):
                record(row)
            out.satisfied.append(key)
            out.notes.append(f"upheld case of iteration {r.get('iteration')} is satisfied by this rule of `{n.id}`; it stays an obligation")
        elif j.route == "upheld":
            row = {**facts(r), **j.row, "obligation": "open", "outcome": key, **same(r, own)}
            if not own or (r.get("obligation") or "open") != "open" or row.get("stageA_digest") != r.get("stageA_digest") \
                    or row.get("stageB_digest") != r.get("stageB_digest"):
                record(row)
            out.reasons.append(f"upheld at iteration {r.get('iteration')} and still decided otherwise by this rule: {j.line}")
            out.keys.append(key)
        elif j.route == "parameter_question":
            if questions is not None and j.question:
                questions.append(j.question)
            out.notes.append(f"upheld case of iteration {r.get('iteration')} on `{n.id}` now turns on an unreviewed parameter: "
                             f"it stays an obligation, and the question is put to the operator — {j.line[:240]}")
        elif own:
            record({**facts(r), **j.row, "obligation": "re-adjudicated", **same(r, own)})
            out.notes.append(f"upheld case of iteration {r.get('iteration')} re-adjudicated on `{n.id}` ({j.route}): it is no longer an "
                             f"obligation — {j.line[:240]}")
        else:
            out.notes.append(f"case {str(r.get('case_id'))[:12]} of the earlier duty overlapping `{n.id}` is not upheld for this duty "
                             f"({j.route}); it is not carried over — {j.line[:200]}")
    for i, (r, own) in enumerate(obligations_of(run, n, ctx.law, True, getattr(ctx, "rulings", None)), 1):
        item = _words_span(n, ctx.law, r.get("item_data") or {}, r.get("words_at"))
        bad = word_level_defects(n, ctx.law, item)
        if bad:
            if own:
                out.reasons.append(f"an open structural finding of iteration {r.get('iteration')} cannot be re-adjudicated on `{n.id}`: "
                                   + "; ".join(bad) + " — the record must carry those words")
                out.keys.append(r.get("outcome") or f"finding:{str(r.get('finding_id'))[:16]}")
            continue
        j = judge_word_level(run, n, ctx, item, out_dir / "replay", f"replay_word_level_{i}", previous=r if own else None)
        key = r.get("outcome") or j.key
        if j.route == "upheld":
            row = {**j.row, "finding_id": r.get("finding_id"), "lineage": r.get("lineage") or r.get("finding_id"), "words_at": r.get("words_at"),
                   "obligation": "open", "outcome": key, **({} if own else carry(r))}
            if not own or row.get("stageB_digest") != r.get("stageB_digest"):
                record(row)
            out.reasons.append(f"a structural finding of iteration {r.get('iteration')} still stands against this record: {j.line}")
            out.keys.append(key)
        elif own:
            record({**j.row, "finding_id": r.get("finding_id"), "words_at": r.get("words_at"), "obligation": "re-adjudicated"})
            out.notes.append(f"structural finding of iteration {r.get('iteration')} re-adjudicated on `{n.id}`: {j.line[:240]}")
    return out


# ---------------------------------------------------------------------------------------------
# The review of a node
# ---------------------------------------------------------------------------------------------
def rule_aggregate_ids(rule_json: dict | None, concepts: dict[str, dict] | None = None, nodes: dict[str, dict] | None = None) -> list[str]:
    """The admitted aggregates a rule reads: in its own formulas, in the bodies of the concepts it
    calls (as far as they call others), and in the rules it composes (their claims)."""
    out: list[str] = []
    by_lean = {cid.replace(".", "_"): rec for cid, rec in (concepts or {}).items()}
    seen: set[str] = set()

    def add(a: str) -> None:
        if a not in out:
            out.append(a)

    def walk(x) -> None:
        if isinstance(x, dict):
            if x.get("atom") == "ru_aggregate" and isinstance(x.get("args"), list) and len(x["args"]) == 2 and isinstance(x["args"][1], dict):
                lit = x["args"][1].get("lit")
                if isinstance(lit, str):
                    add(lit)
            name = x.get("derived") or x.get("quantity")
            if isinstance(name, str) and name in by_lean and name not in seen:
                seen.add(name); walk(by_lean[name].get("body_json"))
            rid = x.get("rule")
            if isinstance(rid, str) and rid in (nodes or {}) and rid not in seen:
                seen.add(rid)
                for c in Node(nodes[rid]).claimed_atoms():
                    if c.startswith("ru.aggregate="):
                        add(c.split("=", 1)[1])
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(rule_json or {})
    return out


def build_context(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, reading: Reading, rule_json: dict,
                  coder_narrowings: list[dict], rulings: list[dict] | None = None) -> Context:
    """What the judges of a node's review are shown, its precedents taken from `rulings` (the run's
    rulings as the review began; as they stand when None)."""
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
    for aid in rule_aggregate_ids(rule_json, run.all_concepts(), run.all_nodes()):
        a = reading.aggregate(aid)
        if a is not None:
            aggs.append({**a, "certificate_digest": certs.get(aid)})
    duty = duty_of(n, law)
    return Context(law, seg, definitions_mod.applicable(run, law.id), record, rendering, glosses, params, aggs,
                   definitions_mod.precedence_hash(run), duty=duty, duty_block=duty_block(n, law),
                   precedents=precedent_rows(run, f"law:{law.id}", duty, rulings), not_atoms=ontology.not_atoms_text(onto),
                   sources=definitions_mod.source_records(run, n.definition_sources()), rulings=rulings)


def evidence_block(items: list[dict]) -> str:
    """The obligations whose evidence the reviewer must extend before they can be judged."""
    if not items:
        return ""
    out = ["## Cases to extend", "",
           "Each case below was upheld against an earlier rule of this duty and stays an obligation, but its evidence no longer "
           "suffices to judge this rule. For each, submit a divergence with `\"extends\": \"<case id>\"` whose trace extends this "
           "one (earlier scenes, denser scenes, the missing observations) and whose case states the same facts, grounding the "
           "node's binders. The law's verdict is judged again on what you submit; nothing is assumed. An extension on which this rule "
           "gives the verdict you claim for the law is no advisory: it is judged again, and recorded as satisfied where the "
           "law's verdict is unchanged.", ""]
    for x in items:
        out += [f"### Case `{x['case_id']}`", "", _ws(x.get("case_rendered")), "", f"What it lacks: {x.get('remedy')}", "",
                "Its trace: ```json " + json.dumps(x.get("trace"), ensure_ascii=False)[:6000] + "```", ""]
    return "\n".join(out) + "\n"


def review_behaviour(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, reading: Reading, rule_json: dict | None,
                     coder_narrowings: list[dict], out_dir: Path) -> ReviewOutcome:
    """The review of a coded node. The judgment context is built first (with the duty the node
    formalizes and the rulings on it as they stand); the duty's obligations are replayed under it
    (one still upheld returns the node without a reviewer; a judge that stays invalid defers the
    law); then the reviewer is asked, given the obligations whose evidence it must extend, its
    divergences certified, and the admitted ones judged. An upheld item returns the rule whatever
    else happened (a later judge's failure keeps its own pending state). Otherwise `deferred`
    (stage `reviewer`) when a challenge could not be evaluated or a pass gave no usable answer,
    (stage `evidence`) when an obligation's evidence was not extended; else
    `proceed_with_question` or `accepted`. Operator questions are carried on every outcome. A case
    whose execution refutes the reviewer is an advisory. The review reads the rulings as they stood
    when it began, and its outcome is saved with its rulings before they are recorded
    (`resume_review`, `finish_review`), so a review stopped at any point and resumed on the same
    inputs gives the same outcome, asks no judge twice and records each ruling once. Raises
    `SessionUnavailable` when a session could not be launched."""
    if not enabled(run):
        if run.opts.dry_run:
            return ReviewOutcome("accepted", advisories=["dry run"])
        raise RuntimeError("a reviewer_model is required for a rule review")
    if rule_json is None:
        return ReviewOutcome("returned", reasons=["the gate exported no rule to review"])
    built: dict = {}

    def inputs_of(rows: list[dict]) -> str | None:
        try:
            built["ctx"] = build_context(run, n, law, onto, reading, rule_json, coder_narrowings, rows)
        except render_formula.Unrendered as e:
            raise session.SessionUnavailable(f"the renderer has no phrasing for the {e} (harness/lean/render_formula.py)") from e
        return review_inputs(run, n, law, reading, rule_json, built["ctx"], rows)
    out_dir.mkdir(parents=True, exist_ok=True)
    rulings, decided = resume_review(run, out_dir, inputs_of)
    if decided is not None:
        return outcome_of(decided)
    ctx = built["ctx"]
    ctx.rulings = rulings.base
    done = lambda data, outcome: finish_review(run, out_dir, rulings, data, outcome, outcome.status != "deferred")
    (out_dir / "rendered_rule.md").write_text(ctx.rendering, encoding="utf-8")
    rj = rule_json or {}
    need = history_of([b.get("cls") for b in rj.get("binders", [])] + [rj.get("applicability"), rj.get("obligation")],
                      run.all_concepts(), reading)
    history = history_text(need)
    pending, replay_questions = [], []
    try:
        rep = replay_obligations(run, n, ctx, onto, reading, need, out_dir, pending, replay_questions)
    except Deferred as e:
        return done({"deferred": e.why}, ReviewOutcome("deferred", reasons=[f"replay of the obligations: {e}"], defer_stage=e.stage,
                                                       questions=replay_questions))
    if rep.reasons:                                       # the replay's states, recorded only with a final outcome
        for row in pending:
            rulings.add(row)
        return done({"replayed": rep.reasons, "notes": rep.notes},
                    ReviewOutcome("returned", reasons=rep.reasons, advisories=rep.notes, keys=sorted(set(rep.keys)),
                                  questions=replay_questions, satisfied=sorted(set(rep.satisfied))))
    binders = [b["name"] for b in n.get("binders", [])]
    blocks = {
        "law_and_segmentation": f"### Law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans:\n{ctx.seg}\n",
        "record": "### Record\n\n```json\n" + json.dumps(ctx.record, ensure_ascii=False, indent=1) + "\n```\n\n"
                  + GapLedger.for_run(paths.GAPS_DIR, run).cited_block(ctx.record),
        "rendered": "### Rendering\n\n" + ctx.rendering + "\n",
        "atoms_read": atoms_read_block(rule_json, run.all_concepts()),
        "contracts": validate_phase.contracts_table(ctx.rule_glosses) + aggregates_block(ctx.aggregates),
        "parameters": _parameters_block(reading, set(n.params())) + (f"\nHistory: {history}.\n" if history else ""),
        "trace_format": trace_format_block(),
        "case_language": surface.case_language(),
        "definitions": context_definitions(ctx),
        "case_vocabulary": surface.case_vocabulary(onto),
        "not_atoms": ctx.not_atoms,
        "max_divergences": str(run.opts.max_divergences),
        "review_checks": str(run.opts.review_checks),
        "review_submissions": str(run.opts.review_submissions),
    }
    windows = window_params([p for p in reading.data.get("params", []) if p.get("name") in set(n.params())])
    cap = run.opts.max_divergences
    n_passes = max(1, int(run.opts.review_passes or 1))
    by_case = {r.get("case_id"): r for r, _own in obligations_of(run, n, law, False, rulings.base)}
    extendable = {x["case_id"]: by_case[x["case_id"]] for x in rep.evidence if x["case_id"] in by_case}
    passes = [BehaviourTools(run, n, law, reading, binders, windows, history, out_dir / f"pass{k}",
                             run.opts.review_checks, run.opts.review_submissions, need, extendable)
              for k in range(1, n_passes + 1)]

    def prompt_of(k: int) -> str:
        """Pass `k`'s prompt, once the passes before it have ended: what they filed is shown as
        already filed, and a case one of them extended is no longer a case to extend (for its tool too)."""
        filed = [x for t in passes[:k - 1] for x in filed_divergences(t, cap)]
        taken = {d.get("extends") for d, _c in filed if isinstance(d.get("extends"), str)}
        passes[k - 1].extendable = {cid: p for cid, p in extendable.items() if cid not in taken}
        text = render.render("review_code.md", {**blocks, "obligations": evidence_block([x for x in rep.evidence if x["case_id"] not in taken]),
                                                "filed": filed_block(filed)})
        (out_dir / ("review_behaviour_prompt.md" if k == 1 else f"review_behaviour_prompt_p{k}.md")).write_text(text, encoding="utf-8")
        return text
    prompt_of(1)
    if run.opts.dry_run:
        return finish_review(run, out_dir, rulings, {}, ReviewOutcome("accepted", advisories=["review skipped (dry run)"]), False)
    try:
        run_passes(run, n, prompt_of, out_dir, passes, context=_pass_context(run, n, reading, rule_json))
        answer, certs, pass_notes, pass_summary, errs, unusable_passes = join_passes(passes, law, binders, cap)
    except HarnessFailure as e:
        return done({"deferred": str(e)}, ReviewOutcome("deferred", reasons=[f"the certificate harness: {e}"], defer_stage="certificate",
                                                        questions=replay_questions))
    attempts = [a for t in passes for a in t.attempts]
    if answer is None:
        why = "behaviour review: no pass submitted a usable answer — " + "; ".join(pass_notes)[:600]
        return done({"deferred": why, "passes": pass_summary}, ReviewOutcome("deferred", reasons=[why], defer_stage="reviewer",
                                                                            questions=replay_questions))
    divs = answer.get("divergences") or []
    advisories = list(rep.notes) + [f"behaviour review, {x}" for x in pass_notes] + [str(x) for x in answer.get("advisories", [])]
    for g in gap_candidate_lines(answer.get("gap_candidates", [])):
        advisories.append(g)
    # a challenge the harness could not evaluate (its schema, its certificate, no rule verdict)
    # leaves the review undecided: without an upheld item it defers the law, never accepts it
    upheld, keys, questions, judged_rows, unusable, status_of = [], [], list(replay_questions), [], [], {}
    unusable += [f"pass {k}: {why}" for k, why in unusable_passes]
    extended: dict[str, dict] = {x["case_id"]: x for x in rep.evidence}
    if answer.get("verdict") == "return" and not divs:
        unusable.append("the reviewer returned the rule with no divergence")
    deferred: Deferred | None = None
    try:
        for k, d in enumerate(divs, 1):
            status_of[k] = "not evaluated, unverified"
            # a case already extended by an earlier divergence of the answer is no longer one to extend
            s = divergence_status(k, d, lambda: certs.get(k), law.text, binders,
                                  {cid: p for cid, p in extendable.items() if cid in extended}, windows, history, need)
            if s.status == "unstatable":
                advisories.append(f"gap candidate: divergence {k} is unstatable in the vocabulary — \"{_ws(d.get('unstatable'))[:240]}\" "
                                  f"(law: \"{_ws(d.get('law_words'))[:160]}\")")
                continue
            if s.status in ("schema defects", "unusable"):
                unusable.append("; ".join(s.messages)[:600])
                continue
            if s.status == "refuted":
                status_of[k] = "refuted by execution"
                advisories.append(f"divergence {k}: refuted by execution — " + "; ".join(s.messages)[:400])
                continue
            c, prior = certs[k], s.prior
            j = judge_divergence(run, n, ctx, onto, d, c, out_dir, f"divergence_{k}",
                                 lineage=(prior.get("lineage") or prior.get("case_id")) if prior else "")
            status_of[k] = f"certified, judged {j.route}"
            if prior is not None:                         # an obligation's evidence, extended: its lineage goes on
                extended.pop(d.get("extends"), None)
                law_then = (prior.get("stage_a") or {}).get("verdict")
                same = law_then is not None and _equivalent((j.row.get("stage_a") or {}).get("verdict") or "", law_then)
                state = "open" if j.route == "upheld" else "satisfied" if same and j.route == "rule_agrees" else "re-adjudicated"
                j.row.update({"predecessor": prior.get("case_id"), "obligation": state, "outcome": prior.get("outcome") or j.key,
                              **({"route": "upheld", "ruling": "upheld"} if state == "satisfied" else {})})
                j.key = j.row["outcome"]
                pending.append({**prior, "iteration": run.iteration, "obligation": "extended", "route": "extended",
                                "reason": f"its evidence was extended as case {j.row['case_id'][:12]}"})
                ctx.decided(pending[-1])
                if state == "satisfied":
                    rep.satisfied.append(j.key)
            judged_rows.append(j)
            ctx.decided(j.row)
            if j.route == "upheld":
                upheld.append(j.line); keys.append(j.key)
            elif j.route == "parameter_question":
                questions.append(j.question); advisories.append(j.line)
            else:
                advisories.append(j.line)
        for i, item in enumerate(_broader_contract_items(answer.get("gap_candidates", [])), 1):
            bad = word_level_defects(n, law, item)
            if bad:                                       # an item that is not the law's words never reaches stage B
                advisories.append("structural evidence not judged: " + "; ".join(bad))
                continue
            j = judge_word_level(run, n, ctx, item, out_dir, f"word_level_{i}")
            judged_rows.append(j)
            ctx.decided(j.row)
            if j.route == "upheld":
                upheld.append(j.line); keys.append(j.key)
            else:
                advisories.append(j.line)
    except Deferred as e:
        deferred = e
    for j in judged_rows:                                 # what was decided stands, whatever failed after it
        rulings.add(j.row)
    if upheld or (deferred is None and not unusable):     # the replay's states, recorded only with a final outcome
        for row in pending:
            rulings.add(row)
    notes = param_notes(n, reading, answer, status_of, run.iteration)
    missing = [f"case {cid[:12]}: its evidence was not extended ({_ws(x.get('remedy'))[:200]})" for cid, x in extended.items()]
    data = {"reviewer_verdict": answer.get("verdict"), "upheld": upheld, "questions": questions,
            "unusable": unusable, "evidence_missing": missing, "advisories": advisories, "schema_defects": errs,
            "attempts": attempts, "param_notes": notes, "passes": pass_summary,
            "deferred": deferred.why if deferred else None}
    if upheld:
        return done(data, ReviewOutcome("returned", reasons=upheld, advisories=advisories + ([f"pending: {deferred.why}"] if deferred else []),
                                        keys=sorted(set(keys)), questions=questions, param_notes=notes, satisfied=sorted(set(rep.satisfied))))
    if deferred is not None:
        return done(data, ReviewOutcome("deferred", reasons=[str(deferred.why)], advisories=advisories, defer_stage=deferred.stage,
                                        questions=questions, param_notes=notes))
    if unusable:
        return done(data, ReviewOutcome("deferred", reasons=[f"behaviour review: {len(unusable)} challenge(s) could not be evaluated: "
                                                             + " | ".join(unusable)[:900]],
                                        advisories=advisories, defer_stage="reviewer", questions=questions, param_notes=notes))
    if missing:
        return done(data, ReviewOutcome("deferred", reasons=["obligations whose evidence the reviewer did not extend: " + " | ".join(missing)[:900]],
                                        advisories=advisories, defer_stage="evidence", questions=questions, param_notes=notes,
                                        satisfied=sorted(set(rep.satisfied))))
    if questions:
        return done(data, ReviewOutcome("proceed_with_question", advisories=advisories, questions=questions, param_notes=notes,
                                        satisfied=sorted(set(rep.satisfied))))
    return done(data, ReviewOutcome("accepted", advisories=advisories, param_notes=notes, satisfied=sorted(set(rep.satisfied))))


def pass_digest(run: Run, n: Node, prompt: str, k: int, context: str) -> str:
    """What a pass's answer depends on: its prompt, the record it reviews, the rule as built and the
    context its gate ran on (`context`), the reviewer and its limits."""
    o = run.opts
    return _digest({"prompt": prompt, "record": n.raw, "context": context, "pass": k, "model": o.reviewer_model, "effort": o.review_effort,
                    "checks": o.review_checks, "submissions": o.review_submissions, "max_divergences": o.max_divergences})


def _pass_context(run: Run, n: Node, reading: Reading, rule_json: dict | None) -> str | None:
    """The rule as built and the context its gate ran on, or None when that context cannot be
    computed (then no pass is reused)."""
    from . import code as code_phase
    try:
        task = code_phase.task_context(run, "node", n.id, n.raw, reading)
    except Exception:
        return None
    return _digest({"rule": rule_json, "task": task}) if task else None


def restore_pass(t, digest: str) -> bool:
    """A pass that already submitted on these inputs (`answer.json` in its directory) takes that
    submission back instead of running again; any other file is ignored."""
    try:
        kept = json.loads((t.out_dir / "answer.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    if kept.get("digest") != digest or not isinstance(kept.get("answer"), dict):
        return False
    t.done, t.answer, t.attempts = True, kept["answer"], list(kept.get("attempts") or [])
    return True


def run_passes(run: Run, n: Node, prompt_of, out_dir: Path, passes: list, context: str | None = None) -> None:
    """The reviewer sessions of one rule review, one after another: pass `k` is asked `prompt_of(k)`,
    taken once the passes before it have ended, and has its own tool state, evidence directory
    (`pass<k>/`) and stream (`review_behaviour_p<k>`). With a `context` (the rule as built and its
    gate's context), a pass that submitted keeps its submission with the digest of its inputs, its
    prompt among them, and a pass that already submitted on the same inputs is not run again, so a
    review interrupted after a pass ended reruns only the later ones. A budget pause, a session that
    never ran or a certificate program that does not run is raised at once: no later pass runs."""
    for k, t in enumerate(passes, 1):
        prompt = prompt_of(k)
        digest = pass_digest(run, n, prompt, k, context) if context else None
        if digest and restore_pass(t, digest):
            continue
        session.run_tools(prompt, out_dir, run.opts, t, label=f"review_behaviour_p{k}",
                          effort=run.opts.review_effort, model=run.opts.reviewer_model, subject=n.id)
        if digest and t.done and isinstance(t.answer, dict):
            t.out_dir.mkdir(parents=True, exist_ok=True)
            jsonl.write_atomic(t.out_dir / "answer.json", json.dumps({"digest": digest, "answer": t.answer, "attempts": t.attempts},
                                                                     ensure_ascii=False, indent=1))


def _answer_of(t) -> dict | None:
    """A pass's final answer, an answer sent as a JSON string parsed."""
    a = t.answer
    if isinstance(a, str):
        try:
            a = json.loads(a)
        except json.JSONDecodeError:
            return None
    return a if isinstance(a, dict) else None


def pass_answer(t, cap: int | None) -> tuple:
    """A pass's answer and its divergences, with why the pass is unusable: `why` when it submitted
    nothing or no review, `broken` when its review returned the rule with no divergence or exceeds
    the cap (its items kept as evidence)."""
    a = _answer_of(t)
    divs = a.get("divergences") if isinstance(a, dict) else None
    why = ("submitted no answer" if t.answer is None else
           "submitted an answer that is not a review" if a is None or not _member(a.get("verdict"), VERDICTS) or not isinstance(divs, list) else None)
    broken = None if why else ("returned the rule with no divergence" if a.get("verdict") == "return" and not divs else
                               divergence_limit_defect(divs, cap))
    return a, divs, why, broken


def filed_divergences(t, cap: int | None) -> list[tuple[dict, dict]]:
    """What a pass filed: each divergence of its usable answer that the review will judge (status
    `certifiable`), with its certificate record."""
    a, divs, why, broken = pass_answer(t, cap)
    if why or broken:
        return []
    out = []
    for k, d in enumerate(divs, 1):
        where = t.out_dir / "final" / f"d{k}"
        if t.status(k, d, where).status == "certifiable":
            out.append((d, t.cert(d, where)))
    return out


def filed_block(filed: list[tuple[dict, dict]]) -> str:
    """The divergences earlier sessions of the review filed, shown to a later one as already filed."""
    if not filed:
        return ""
    out = ["## Already filed", "",
           "An earlier session of this review filed the divergences below; each will be judged.", ""]
    for i, (d, c) in enumerate(filed, 1):
        ext = f", extending case `{d['extends']}`" if isinstance(d.get("extends"), str) else ""
        out += [f"### Filed {i} ({d.get('kind')}{ext})", "",
                f"Situation: {_ws(d.get('situation'))}", "",
                f"The law's words: \"{_ws(d.get('law_words'))}\"; the verdict claimed for the law: {d.get('lawful_verdict')}; "
                f"the rule's verdict at t={d.get('at')} ms: {((c or {}).get('rule_result') or {}).get('verdict')}.", "",
                "Its case: ```json " + json.dumps({"case": d.get("case"), "entities": d.get("entities"), "grounding": d.get("grounding")},
                                                  ensure_ascii=False) + "```", ""]
    return "\n".join(out) + "\n"


def join_passes(passes: list, law: corpus.Law, binders: list[str], cap: int | None) -> tuple:
    """The review's answer, joined from its passes: `(answer, certificates by number, notes on the
    passes, a summary per pass, the schema defects of the usable answers, the passes whose answer
    is unusable with why)`. A pass that submitted nothing, or an answer that is not a review, is
    noted; one that returned the rule with no divergence, or whose final answer still exceeds the
    cap, makes the review unusable, every item kept as evidence: an answer is never truncated. The
    usable passes' divergences are joined in pass order. Only a divergence that can be judged
    (certified, its case true, the rule's verdict decided) is ever merged, and only with one from
    another pass of the same case (`case_id`: its trace, case, entities, `at` and grounding), rule
    verdict, claimed lawful verdict and `extends`: it is the same evidence, judged once. A
    divergence on another trace is its own evidence. Every other divergence is kept as submitted.
    Advisories and gap candidates are joined, exact repeats dropped; the verdict is `return` when
    any usable pass returned. With no usable pass the answer is None."""
    usable, notes, summary, errs, unusable = [], [], [], [], []
    for k, t in enumerate(passes, 1):
        a, divs, why, broken = pass_answer(t, cap)
        summary.append({"pass": k, "submitted": t.answer is not None, "verdict": (a or {}).get("verdict") if isinstance(a, dict) else None,
                        "divergences": len(divs) if isinstance(divs, list) else None, "attempts": t.attempts, "unusable": why or broken})
        if why:
            notes.append(f"pass {k} {why}"); unusable.append((k, why))
            continue
        if broken:                                         # never truncated, never judged: kept as evidence
            unusable.append((k, broken)); summary[-1]["items"] = divs
            notes.append(f"pass {k}: {broken}")
            continue
        usable.append((k, t, a))
        errs += behaviour_defects(a, law.text, binders, cap)
    if not usable:
        return None, {}, notes, summary, errs, unusable
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
                key = _canon({"case_id": case_id(law, d, canonical_case(d, c.get("canonical_case"), binders)),
                              "rule": (c.get("rule_result") or {}).get("verdict"), "lawful": d.get("lawful_verdict"),
                              "extends": d.get("extends")})
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
    return ({"verdict": verdict, "divergences": joined, "advisories": advisories, "gap_candidates": gaps}, certs, notes, summary, errs,
            unusable)


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
    jsonl.write_atomic(out_dir / "review_outcome.json", json.dumps(data, ensure_ascii=False, indent=1))


#: The prompt files a node's review renders, and those a concept's review renders.
NODE_REVIEW_PROMPTS = ("review_code.md", "judge_case.md", "adjudicate.md")
CONCEPT_REVIEW_PROMPTS = ("review_concept.md", "adjudicate_concept.md", "recheck_concept.md")


def _inputs_digest(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True, ensure_ascii=False, default=str).encode("utf-8")).hexdigest()


#: The options a node's review uses (its passes and its divergence cap included), and those a
#: concept's review and its adjudication use.
NODE_REVIEW_SETTINGS = ("model", "judge_effort", "reviewer_model", "review_effort", "review_passes", "review_checks",
                        "review_submissions", "max_divergences")
CONCEPT_REVIEW_SETTINGS = ("model", "judge_effort", "reviewer_model", "review_effort", "review_checks", "review_submissions")


def review_settings(run: Run, prompts: tuple[str, ...], settings: tuple[str, ...]) -> dict:
    """What a review's outcome depends on besides its record and the rulings: the iteration its
    rulings are recorded under, the prompt files it renders, and the options it uses (`settings`:
    its sessions' models, efforts and limits)."""
    o = run.opts
    return {"iteration": run.iteration, "prompts": {t: _digest((paths.PROMPTS / t).read_text(encoding="utf-8")) for t in prompts},
            "opts": {k: getattr(o, k, None) for k in settings}}


def review_inputs(run: Run, n: Node, law: corpus.Law, reading: Reading, rule_json: dict | None, ctx: Context, rows: list[dict]) -> str | None:
    """The identity of what a node's review decides on: the law, the record and the rule as built,
    the context its gate ran on (`_pass_context`), everything its judges are shown but the rulings,
    the reading, the operator's decisions on the gaps the record cites, the law's rulings as the
    review began (`rows`), and `review_settings`. None when the gate's context cannot be computed:
    then nothing the review saved is taken back."""
    context = _pass_context(run, n, reading, rule_json)
    if context is None:
        return None
    return _inputs_digest({"law": [law.id, law.title, law.text], "record": n.raw, "rule": rule_json, "context": context,
                           "shown": {k: v for k, v in vars(ctx).items() if k not in ("law", "precedents", "rulings")},
                           "reading": reading.data, "gaps": GapLedger.for_run(paths.GAPS_DIR, run).cited_block(ctx.record),
                           "rulings": [r for r in effective_rows(rows) if r.get("key") == f"law:{law.id}"],
                           **review_settings(run, NODE_REVIEW_PROMPTS, NODE_REVIEW_SETTINGS)})


def saved_review(out_dir: Path) -> dict | None:
    """The record a review left in `out_dir` (`review_outcome.json`): its inputs, the number of the
    run's rulings it began from and, once it reached an outcome, the outcome (`final` unless it was
    deferred) and its rulings. None for anything else."""
    try:
        saved = json.loads((out_dir / "review_outcome.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(saved, dict) or "inputs" not in saved or not isinstance(saved.get("rulings_at"), int):
        return None
    return saved


def record_rows(run: Run, saved: dict) -> None:
    """The rulings a saved review decided, recorded in order, each once (`append_ruling` by its id)."""
    for x in saved.get("rows") or []:
        append_ruling(run, x["row"], x.get("supersedes"), ruling_id=x["id"])


def resume_review(run: Run, out_dir: Path, inputs_of) -> tuple[ReviewRulings, dict | None]:
    """Where a review begins. A review stopped before the loop applied its outcome left its record
    in `out_dir` (`saved_review`): its rulings are recorded first, each once, whatever follows.
    When the record's inputs are this review's (`inputs_of`, computed on the run's rulings as they
    stood when it began, so its own rulings change nothing), the review goes on from it: a final
    outcome is returned as it was decided, without a judge; any other (deferred, or not reached) is
    decided again on the same rulings, every judgment already given taken back by its digest.
    Otherwise the review begins on the rulings as they stand, its inputs saved before any session.
    Returns the review's rulings and the final outcome, if any."""
    saved = saved_review(out_dir)
    if saved is not None:
        at, rows = rulings_as_of(run, saved["rulings_at"])
        inputs = inputs_of(rows)
        record_rows(run, saved)
        if inputs is not None and inputs == saved["inputs"]:
            return ReviewRulings(inputs, at, rows), (saved.get("outcome") if saved.get("final") else None)
    at, rows = rulings_as_of(run)
    inputs = inputs_of(rows)
    _write_outcome(out_dir, {"inputs": inputs, "rulings_at": at})
    return ReviewRulings(inputs, at, rows), None


def finish_review(run: Run, out_dir: Path, rulings: ReviewRulings, data: dict, outcome, final: bool):
    """A review's outcome: saved whole with its inputs and its rulings in one write, then its
    rulings recorded; a review stopped between the two is completed from the record
    (`resume_review`). A deferred outcome is not `final`: it is decided again."""
    saved = {**data, "inputs": rulings.inputs, "rulings_at": rulings.at, "final": final, "outcome": asdict(outcome),
             "rows": rulings.saved()}
    _write_outcome(out_dir, saved)
    record_rows(run, saved)
    return outcome


def outcome_of(saved: dict) -> ReviewOutcome:
    return ReviewOutcome(**{**saved, "param_notes": [tuple(x) for x in saved.get("param_notes") or []]})


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
PLACEHOLDERS_REVIEW_CONCEPT = ("contract", "record", "rendered", "atoms_read", "contracts", "trace_format", "carry_over", "review_checks",
                               "review_submissions")
PLACEHOLDERS_ADJUDICATE_CONCEPT = ("contract", "record", "rendered", "contracts", "items", "precedents")
CONCEPT_KINDS = {"holds_wrongly", "fails_wrongly", "undecided"}
#: The kinds of a divergence of a quantity concept, whose contract gives an interval, not a verdict.
QUANTITY_KINDS = {"value_wrongly", "undecided"}
#: The contract's verdict, as the episode verdict the concept's instance gives when the body agrees.
CONTRACT_VERDICTS = {"holds": "compliant", "fails": "violated"}
CONCEPT_CASE_SCHEMA = "concept_case/1"
#: What a concept ruling keeps to be replayed: the immutable trace, the instance, the grounding, its regions, `at` and the claim.
CONCEPT_CASE_FIELDS = ("kind", "situation", "contract_words", "contract_verdict", "contract_value", "instance", "grounding", "regions", "trace", "at")


def concept_case_id(concept_id: str, d: dict) -> str:
    """A concept case's identity: the concept and the case's fields. `regions` enters only when it
    names a region, so a case recorded before concepts took regions keeps its id."""
    return _digest({"concept": concept_id, **{x: d.get(x) for x in CONCEPT_CASE_FIELDS if x != "regions" or d.get("regions")}})
CONCEPT_RULINGS = {"upheld", "dismissed"}
CONCEPT_AGREES = " (the body agrees with the contract on this trace)"


def _dims() -> dict[str, tuple[int, int, int]]:
    """Each Core unit's dimension, as Core states it."""
    from ..model import units
    return units.DIMS


def _track_formals(rec) -> list[str]:
    return [a["name"] for a in rec.args() if a.get("sort") == "track"]


# The types of the values a concept review or a dependency report states, each tested before any
# membership, index, lookup or conversion: a malformed value is a schema defect, never a crash.
def _is_str(x) -> bool:
    return isinstance(x, str)


def _is_num(x) -> bool:
    """A finite number that is not a boolean."""
    import math
    return isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)


def _is_nat(x) -> bool:
    return isinstance(x, int) and not isinstance(x, bool) and x >= 0


def _is_id(x) -> bool:
    """A track, region or device id, or a timestamp: an integer that is not a boolean."""
    return isinstance(x, int) and not isinstance(x, bool)


def _member(x, allowed) -> bool:
    """`x` is a string and one of `allowed`."""
    return isinstance(x, str) and x in allowed


def _is_quantity(v) -> bool:
    """[value, unit]: a finite number and one of Core's unit spellings."""
    from ..model import units
    return isinstance(v, list) and len(v) == 2 and _is_num(v[0]) and _member(v[1], units.FACTORS)


def concept_review_defects(answer: dict, rec, contract: str, rendering: str, result_dim: tuple | None = None) -> list[str]:
    """Defects of a concept review as an answer: the verdict word; each divergence's kind, the
    contract's verdict, the contract's words (verbatim), an instance that fills every literal formal
    with an admissible spelling and every parameter with a value in its unit, a grounding of every
    track formal, and a trace with scenes; each `not_general` item's words, verbatim."""
    errs = []
    if not _member(answer.get("verdict"), VERDICTS):
        errs.append("`verdict` must be `accept` or `return`")
    divs, tuned = answer.get("divergences", []), answer.get("not_general", [])
    if not isinstance(divs, list) or not isinstance(tuned, list):
        return errs + ["`divergences` and `not_general` must be lists"]
    if answer.get("verdict") == "return" and not divs and not tuned:
        errs.append("a return needs at least one divergence with a trace or one `not_general` item")
    for k, d in enumerate(divs, 1):
        errs += concept_divergence_defects(k, d, rec, contract, result_dim)
    for k, t in enumerate(tuned, 1):
        errs += structural_item_defects(k, t, contract, rendering)
    return errs


def structural_item_defects(k: int, t, contract: str, rendering: str) -> list[str]:
    """Why a `not_general` item cannot be judged: its `words` are not a verbatim string of the
    contract or the rendering, or it states no `why`."""
    if not isinstance(t, dict) or not _is_str(t.get("why")) or not _ws(t.get("why")) or not _is_str(t.get("words")) \
            or not _ws(t.get("words")) or not _quoted(t["words"], contract + "\n" + rendering):
        return [f"not_general {k}: `words` must be verbatim from the contract or the rendering, with a `why`"]
    return []


def _unit_dim(spelling) -> tuple | None:
    """The dimension of a unit as a reviewer or the export spells it (`m/s^2`, `metre_per_second_sq`)."""
    from ..model import units
    if spelling in units.FACTORS:
        return _dims().get(units.FACTORS[spelling][0])
    camel = re.sub(r"_(\w)", lambda m: m.group(1).upper(), str(spelling))
    return _dims().get(camel)


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
            return _dims()["metre"]
        if "since_rise" in t:
            return _dims()["second"]
        if "heading_since" in t:
            return _dims()["degree"]
        if "aggregate" in t:
            return _dims()["count"] if t["aggregate"] == "count" else dim(t.get("of"))
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
    if not all(_is_quantity(e) for e in ends):
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


def concept_divergence_defects(k: int, d, rec, contract: str, result_dim: tuple | None = None, saved: bool = False) -> list[str]:
    """The defects of one divergence of a concept review; one without defects can be run. A
    divergence of a quantity concept states `contract_value`, the interval the contract's words put
    the value in, where a formula concept's states `contract_verdict`. Every container has its
    shape: `instance` (absent means `{}`) and its `literals`, `nats` and `params` are objects,
    `grounding` an object, `trace` an object with a list of scenes; a value of the wrong shape is a
    defect, never read as empty. A fresh trace holding keys the decoder does not read is refused;
    a `saved` one (a recorded challenge, replayed) keeps them as unverified annotations. A saved
    challenge's contract words are those of the contract it was recorded under: the replay compares
    that contract with the current one by digest, so they need not be verbatim in the current one."""
    from ..model import units
    if not isinstance(d, dict):
        return [f"divergence {k} is not an object"]
    errs = []
    tracks = _track_formals(rec)
    literals = {a["name"]: set(a.get("values", [])) for a in rec.args() if a.get("sort") == "literal"}
    params = {p["name"]: str(p.get("unit", "")) for p in rec.params()}
    if rec.get("kind") == "quantity":
        if not _member(d.get("kind"), QUANTITY_KINDS):
            errs.append(f"divergence {k}: kind must be one of {sorted(QUANTITY_KINDS)} for a quantity")
        if "contract_verdict" in d:
            errs.append(f"divergence {k}: a quantity's divergence states `contract_value`, never `contract_verdict`")
        errs += _interval_defects(k, d.get("contract_value"), result_dim)
    else:
        if not _member(d.get("kind"), CONCEPT_KINDS):
            errs.append(f"divergence {k}: kind must be one of {sorted(CONCEPT_KINDS)}")
        if not _member(d.get("contract_verdict"), CONTRACT_VERDICTS):
            errs.append(f"divergence {k}: contract_verdict must be one of {sorted(CONTRACT_VERDICTS)}")
    if not _is_str(d.get("contract_words")) or not (saved or _in(d["contract_words"], contract)):
        errs.append(f"divergence {k}: contract_words is not verbatim from the contract")
    inst = d.get("instance", {})
    if not isinstance(inst, dict):
        errs.append(f"divergence {k}: instance must be an object of `literals`, `nats` and `params`")
        inst = {}
    for part in ("literals", "nats", "params"):
        if part in inst and not isinstance(inst[part], dict):
            errs.append(f"divergence {k}: instance.{part} must be an object")
    lits = inst.get("literals") if isinstance(inst.get("literals"), dict) else {}
    if set(lits) != set(literals) or any(not _member(lits[f], literals.get(f, set())) for f in lits):
        errs.append(f"divergence {k}: instance.literals maps exactly the literal formals {sorted(literals)} to one of their admissible spellings"
                    + (f"; {sorted(set(lits) - set(literals))} are not literal formals" if set(lits) - set(literals) else "")
                    + ("; with no literal formal it is `{}`" if not literals else ""))
    ps = inst.get("params") if isinstance(inst.get("params"), dict) else {}
    if set(ps) != set(params):
        errs.append(f"divergence {k}: instance.params must give every parameter {sorted(params)} a [value, unit]")
    for name, v in ps.items():
        ok = _is_quantity(v) and name in params and params[name] in units.FACTORS and units.FACTORS[v[1]][0] == units.FACTORS[params[name]][0]
        if not ok:
            errs.append(f"divergence {k}: parameter `{name}` must be [value, unit] in a unit of {params.get(name)!r}")
    nats = [a["name"] for a in rec.args() if a.get("sort") == "nat"]
    ns = inst.get("nats") if isinstance(inst.get("nats"), dict) else {}
    if set(ns) != set(nats) or not all(_is_nat(v) for v in ns.values()):
        errs.append(f"divergence {k}: instance.nats maps exactly the nat formals {sorted(nats)} to natural numbers"
                    + ("; with no nat formal it is `{}` or absent" if not nats else ""))
    g = d.get("grounding")
    if not isinstance(g, dict) or set(g) != set(tracks) or not all(_is_id(x) for x in g.values()):
        errs.append(f"divergence {k}: grounding must map exactly the track formals {tracks} to track ids")
    regions = [a["name"] for a in rec.args() if a.get("sort") == "region"]
    rg = d.get("regions", {})
    if not isinstance(rg, dict) or set(rg) != set(regions) or not all(_is_nat(x) for x in rg.values()):
        errs.append(f"divergence {k}: regions must map exactly the region formals {regions} to region ids (natural numbers)"
                    + ("; with no region formal it is `{}` or absent" if not regions else ""))
    tr = d.get("trace")
    if not isinstance(tr, dict) or not isinstance(tr.get("scenes"), list) or not tr["scenes"]:
        errs.append(f"divergence {k}: trace must be an object with a non-empty `scenes` list")
    elif not all(isinstance(sc, dict) and _is_id(sc.get("t")) for sc in tr["scenes"]):
        errs.append(f"divergence {k}: every scene is an object with an integer timestamp `t` (ms)")
    else:
        times = {sc["t"] for sc in tr["scenes"]}
        if not _is_id(d.get("at")) or d.get("at") not in times:
            errs.append(f"divergence {k}: `at` must be the timestamp (ms) of one of the trace's scenes: the observation the body is read at")
        if not saved:
            errs += unread_key_defects(k, tr)
    return errs


def _lean_q(value: float, unit: str) -> str:
    """A parameter value as a Core literal term: the value converted to the Core unit, exactly."""
    from ..model import units
    core, q = units.to_core(value, unit)
    return f".lit (Q.mk' ({q.numerator}) {q.denominator}) .{core}"


def _concept_review_harness_source(cid: str, traces: list[tuple], reading_json: Path | None, registry: tuple[str, str]) -> str:
    """A Lean program that, for each divergence, prints the trace check's messages (`LINT`) and runs
    the concept, as the instance the divergence names, on its trace (`DIS`): its verdict at the
    observation `at` — compliant where the body holds there, violated where it fails, unknown where
    it has no value, as `Certificate.verdictAt` reads a rule; its region formals bound to the regions
    the divergence names, and a region no scene of the trace holds a `LINT` message. A trace the
    admission rejects is reported as `LINT` messages and not run. A quantity concept runs against the
    interval its divergence states (`bounds`): compliant where its value at `at` lies in it; its
    value there is printed (`VAL`, in Core units). It runs on the run's reading (`reading_json`: its
    admitted aggregates), as the rules that call the concept do. The occupancy of every observed track
    is derived from the geometry first. A relation the trace supplies that Core computes from the
    scene is printed `RELCHECK` (`harness/lean/relations.py`)."""
    from ..lean import relations
    ns = nodeid.concept_namespace(cid)
    bound = lambda b: "none" if b is None else f"some (({_lean_q(*b[0])} : TrafficSpec.Term), ({_lean_q(*b[1])} : TrafficSpec.Term))"
    items = ", ".join(
        f'({k}, {json.dumps(str(p.resolve()))}, [{", ".join(f"({json.dumps(b)}, {t})" for b, t in g.items())}], '
        f'[{", ".join(f"({json.dumps(f)}, {int(r)})" for f, r in regs.items())}], '
        f'[{", ".join(f"({json.dumps(f)}, {json.dumps(v)})" for f, v in lits.items())}], '
        f'[{", ".join(f"({json.dumps(f)}, {int(v)})" for f, v in nats.items())}], '
        f'[{", ".join(f"({json.dumps(n)}, ({_lean_q(v[0], v[1])} : TrafficSpec.Term))" for n, v in ps.items())}], {bound(bd)}, ({int(at)} : Int))'
        for k, p, g, regs, lits, nats, ps, bd, at in traces)
    imports, defs = registry
    return f'''{imports}import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import {nodeid.concept_module(cid)}
{defs}open TrafficSpec Lean
{relations.lean_defs()}
def main : IO Unit := do
  let c := {ns}.concept
  let cs := (allConcepts.filter (·.id != c.id)) ++ [c]
  let ρ : Reading ← {"pure {}" if reading_json is None else f'match Decode.parse Decode.reading (← IO.FS.readFile {json.dumps(str(reading_json.resolve()))}) with | .ok v => pure v | .error e => throw (IO.userError s!"reading: {{e}}")'}
  let items : List (Nat × String × List (String × Nat) × List (String × Nat) × List (String × String) × List (String × Nat) × List (String × TrafficSpec.Term) × Option (TrafficSpec.Term × TrafficSpec.Term) × Int) := [{items}]
  for (k, path, grounding, regs, lits, nats, ps, bd, atT) in items do
    let inst : Concept.Instance := {{ name := s!"review_{{k}}", concept := c.id, literals := lits, nats := nats, params := ps, bounds := bd }}
    match Concept.asRule cs inst with
    | none => IO.println s!"DIS\\t{{k}}\\tunfilled\\t"
    | some r =>
      let r' := Concept.expandRule cs r
      let text ← IO.FS.readFile path
      match Decode.parse Decode.trace text with
      | .error e => IO.println s!"DIS\\t{{k}}\\tdecode\\t{{e}}"
      | .ok τ0 =>
        let τ := TraceLint.completeOccupancy τ0
        let m := Manifest.full "review"
        let admitted := Grounding.Setup.admit [r'] (maskTrace m τ) ρ m.reidGap
        let refused := (match admitted with | .error ds => ds | .ok _ => []) ++
          regs.filterMap fun (n, reg) => if τ.any (fun s => (s.structure? reg).isSome) then none
            else some s!"region formal `{{n}}` is region {{reg}}, which is no structure of the trace"
        IO.println s!"LINT\\t{{k}}\\t{{(Json.arr ((TraceLint.checkTrace τ ++ refused).map Json.str).toArray).compress}}"
        RelCheck.run (toString k) τ
        for s in τ do
          IO.println s!"OCCD\\t{{k}}\\t{{s.t}}\\t{{String.intercalate "," (s.occupies.map fun p => s!"{{p.1}}-{{p.2}}")}}"
        match admitted, refused with
        | .error _, _ | _, _ :: _ => IO.println s!"DIS\\t{{k}}\\tlint\\t"
        | .ok S, [] =>
          let g : Grounding.Grounding := {{ assign := grounding.map (fun (n, t) => (n, Grounding.canon S.cm t)), regions := regs }}
          let tl := Grounding.evaluate S r' g
          let mut found : Option (Nat × Verdict) := none
          for j in [0:tl.verdicts.size] do
            if tl.verdicts[j]!.1 == atT then found := some (j, tl.verdicts[j]!.2)
          match found with
          | none => IO.println s!"DIS\\t{{k}}\\tat_missing\\t"
          | some (j, v) =>
            IO.println s!"DIS\\t{{k}}\\t{{v.tag}}\\t{{String.intercalate "," (v.reasons.map UnknownReason.tag)}}"
            match r'.obligation with
            | .and (.cmp _ _ value) _ =>
              match (Semantics.evalTAll (S.ctx g.binding) value)[j]? with
              | some (.ok q) => IO.println s!"VAL\\t{{k}}\\t{{q.num}}/{{q.den}}"
              | some (.error e) => IO.println s!"VAL\\t{{k}}\\tunknown:{{e.tag}}"
              | none => IO.println s!"VAL\\t{{k}}\\tmissing"
            | _ => pure ()
'''


def _core_value(raw: str | None, dim: tuple | None) -> str:
    """A value the harness printed (`num/den` in Core units) as the adjudicator reads it."""
    if not raw or "/" not in raw or raw.startswith("unknown"):
        return raw or "not printed"
    from fractions import Fraction
    from ..lean import surface
    num, den = raw.split("/", 1)
    return f"{float(Fraction(int(num), int(den))):g}" + (f" {surface.render_dim(dim)}" if dim is not None else " (Core units)")


def execute_concept_divergences(rec, answer: dict, out_dir: Path, result_dim: tuple | None = None,
                                reading: Reading | None = None, saved: bool = False,
                                registry: tuple[str, str] | None = None,
                                runs: dict | None = None) -> tuple[list[dict], list[str], list[str], list[str]]:
    """Run the concept on every divergence trace, as a rule's case is run. Returns (confirmed,
    unconfirmed, errors, incomplete): a trace on which the body's verdict differs from the
    contract's — or is unknown where the contract decides, for a divergence claiming the body
    undecided — confirms it; one on which they agree is the reviewer's advisory; one unknown only
    because the trace leaves an atom out or does not cover or sample a look-back, or one that fails
    the trace check (a supplied relation Core computes among them), is incomplete. With `saved` (a
    recorded challenge's trace, replayed), the supplied relations Core computes are stripped and the
    concept is run again on the stripped trace; the item keeps what was stripped
    (`relations_stripped`). A divergence that fails the schema is not run and is accounted for all
    the same, among the incomplete, with its defects: no submitted divergence disappears. With
    `runs`, each divergence run is also recorded there by its number as the body gave it (`tag`:
    compliant, violated or unknown, its unknown reasons `why`, a quantity's `value` as printed in
    Core units), with its executed facts (`facts`) and, where it could not be judged, the reason
    code of `R0_REASONS` (`reason`: `admission` for a trace that does not decode, names no
    observation or fails the trace check, `formals` for an instance that leaves a formal unfilled,
    `history` for a verdict unknown only because the trace is incomplete)."""
    contract = " ".join(str(rec.get("contract", "")).split())
    listed = answer.get("divergences") if isinstance(answer.get("divergences"), list) else []
    defects = {k: concept_divergence_defects(k, d, rec, contract, result_dim, saved) for k, d in enumerate(listed, 1)}
    divs = {k: d for k, d in enumerate(listed, 1) if not defects[k]}
    unrunnable = [f"divergence {k}: cannot be run as recorded — " + "; ".join(bad[:3])[:400] for k, bad in defects.items() if bad]
    quantity = rec.get("kind") == "quantity"
    if not divs:
        return [], [], [], unrunnable
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in out_dir.glob("disagreement_*.json"):
        stale.unlink()
    traces = []
    for k, d in divs.items():
        p = out_dir / f"disagreement_{k}.json"
        p.write_text(json.dumps(d.get("trace"), ensure_ascii=False, indent=1), encoding="utf-8")
        inst = d.get("instance") or {}
        bd = (tuple(d["contract_value"]["lo"]), tuple(d["contract_value"]["hi"])) if quantity else None
        traces.append((k, p, {b: int(t) for b, t in d["grounding"].items()}, {f: int(r) for f, r in (d.get("regions") or {}).items()},
                       dict(inst.get("literals") or {}), dict(inst.get("nats") or {}),
                       dict(inst.get("params") or {}), bd, d["at"]))
    harness = out_dir / "review_harness.lean"
    rj = None
    if reading is not None:
        rj = out_dir / "reading.json"; rj.write_text(reading.lean_json(), encoding="utf-8")
    stripped: dict[int, list[str]] = {}
    for _pass in (1, 2):                                   # a second pass only for saved traces whose supplied relations were stripped
        harness.write_text(_concept_review_harness_source(rec.id, traces, rj, registry or index_sync.registry_source()), encoding="utf-8")
        with lean.evaluation_lock(paths.LIBRARY):
            code, hout = lean.lean_run(paths.LIBRARY, harness); ok = code == 0
        (out_dir / "review_harness.out").write_text(hout, encoding="utf-8")
        if not ok:
            raise HarnessFailure(f"the concept review harness did not run: {hout[-600:]}")
        got, lint, value, rel, occd = {}, {}, {}, {}, {}
        for line in hout.splitlines():
            parts = line.split("\t")
            if parts[0] == "DIS" and len(parts) >= 3:
                got[int(parts[1])] = (parts[2], parts[3] if len(parts) > 3 else "")
            elif parts[0] == "VAL" and len(parts) >= 3:
                value[int(parts[1])] = parts[2]
            elif parts[0] == "LINT" and len(parts) >= 3:
                try:
                    lint[int(parts[1])] = json.loads(parts[2])
                except json.JSONDecodeError:
                    raise HarnessFailure(f"an unparseable LINT line: {line[:200]}")
            elif parts[0] == "RELCHECK" and len(parts) >= 5 and parts[1].isdigit():
                rel.setdefault(int(parts[1]), []).append([parts[2], parts[3], parts[4].split(":", 1)[0]])
            elif parts[0] == "OCCD" and len(parts) >= 3 and parts[1].isdigit() and parts[2].lstrip("-").isdigit():
                occd.setdefault(int(parts[1]), {})[int(parts[2])] = [x for x in (parts[3] if len(parts) > 3 else "").split(",") if x]
        if not (saved and rel) or _pass == 2:
            break
        for k, fields in rel.items():
            divs[k] = {**divs[k], "trace": strip_computed_relations(divs[k].get("trace") or {}, fields)}
            stripped[k] = [f"t={t} ({pair}): {atom}" for t, pair, atom in fields]
            (out_dir / f"disagreement_{k}.json").write_text(json.dumps(divs[k]["trace"], ensure_ascii=False, indent=1), encoding="utf-8")
    for k, fields in rel.items():                          # a fresh trace's supplied relation Core computes: a defect of the submission
        lint.setdefault(k, []).extend(f"a supplied relation at t={t} ({pair}): {atom}: supplied, but Core computes it from the scene; "
                                      "remove it from the trace" for t, pair, atom in fields)
    keys = decoder_keys(_decode_source())
    read_paths = [m.group(1) for a in sorted({str(x).split("=")[0].replace(".", "_") for x in rec.claimed_atoms()})
                  if (m := re.match(r"`([^`]+)`", trace_place(a, keys)))]
    confirmed, unconfirmed, errors, incomplete = [], [], [], []
    for k, d in divs.items():
        tag, why = got.get(k, ("missing", ""))
        claimed = "compliant" if quantity else CONTRACT_VERDICTS[d["contract_verdict"]]   # a quantity's claim: its value lies in the interval
        observed = _core_value(value.get(k), result_dim)
        if quantity:
            lo, hi = d["contract_value"]["lo"], d["contract_value"]["hi"]
            body = {"compliant": "in the interval", "violated": "outside the interval"}.get(tag, tag)
            head = (f"divergence {k} ({d.get('kind')}) at t={d.get('at')} ms: {_ws(d.get('situation'))[:160]} — contract: from {lo[0]} {lo[1]} "
                    f"to {hi[0]} {hi[1]}; the body's value there: {observed} ({body})")
        else:
            body = {"compliant": "holds", "violated": "fails"}.get(tag, tag)
            head = (f"divergence {k} ({d.get('kind')}) at t={d.get('at')} ms: {_ws(d.get('situation'))[:160]} — contract: {d.get('contract_verdict')}, body: {body}")
        reason = None
        if tag in ("decode", "missing", "unfilled", "at_missing"):
            reason = "formals" if tag == "unfilled" else "admission"
            errors.append(f"divergence {k}: " + {"decode": f"the trace does not decode: {why[:200]}", "missing": "the harness printed no verdict",
                                                  "unfilled": "the instance leaves a formal unfilled",
                                                  "at_missing": "`at` names no observation of the trace"}[tag])
        elif lint.get(k):
            reason = "admission"
            incomplete.append(f"divergence {k}: trace check: " + "; ".join(lint[k][:8]))
        elif tag == claimed:
            unconfirmed.append(head + CONCEPT_AGREES)
        elif tag == "unknown" and why and all(_trace_defect(r, "rule_undecided" if d.get("kind") == "undecided" else None) for r in why.split(",")):
            reason = "history"
            incomplete.append(f"divergence {k}: {_ws(d.get('situation'))[:120]} — the body's verdict on the trace is unknown only because the "
                              "trace is incomplete: " + "; ".join(sorted({_trace_remedy(r) for r in why.split(",")})))
        else:
            line = head + (f" [{why}]" if tag == "unknown" and why else "") + f'; contract: "{_ws(d.get("contract_words"))[:120]}"'
            confirmed.append({"line": line, "div": d, "rule": body + (f" ({why})" if tag == "unknown" and why else ""),
                              "key": f"{d.get('kind')}", "verdict": tag, "value": observed if quantity else None,
                              "facts": executed_facts(d, read_paths, occd.get(k)),
                              **({"relations_stripped": stripped[k]} if k in stripped else {})})
        if runs is not None:
            runs[k] = {"tag": tag, "why": why, "value": value.get(k), "facts": executed_facts(d, read_paths, occd.get(k)), "reason": reason}
    return confirmed, unconfirmed, errors, incomplete + unrunnable


def _item_facts(i: dict) -> str:
    """The executed facts of an adjudicated item: those its execution rendered (with the occupancy
    the harness derived), else rendered from the item's own trace; none for a structural item."""
    if i.get("facts"):
        return i["facts"]
    d = i.get("div") or {}
    if d.get("kind") == "not_general" or not isinstance(d.get("trace"), dict):
        return ""
    return executed_facts(d)


def executed_facts(d: dict, read_paths: list[str] | None = None, occupancy: dict | None = None) -> str:
    """The executed facts of a divergence: what the decoder reads of its trace, and only that; the
    keys it does not read listed apart as the reviewer's unverified annotations."""
    return render_formula.trace_facts(d.get("trace") if isinstance(d.get("trace"), dict) else {}, d.get("grounding") or {}, d.get("at"),
                                      d.get("instance") if isinstance(d.get("instance"), dict) else {}, read_paths, occupancy,
                                      d.get("regions") if isinstance(d.get("regions"), dict) else {})


def adjudicate_concept(run: Run, rec, blocks: dict[str, str], items: list[dict], out_dir: Path, body_digest: str = "",
                       label: str = "adjudicate", rulings: ReviewRulings | None = None) -> list[tuple[dict, str, str]]:
    """Each confirmed divergence and `not_general` item of a concept with its ruling. An item left
    unruled, or ruled with a defect the adjudicator keeps after the re-ask, is never upheld by
    default: the adjudication raises `Deferred` (`concept_adjudication`). Within a review, the
    precedents and the rulings are its own (`rulings`)."""
    known = rulings.rows() if rulings is not None else None
    listing = "\n\n".join(
        (f"{k}. ({i['div'].get('kind')}) {_ws(i['div'].get('situation'))}" + (" [an item upheld before, run again]" if i.get("replay_of") else "") + "\n"
         f"   the contract's words, per the reviewer: \"{_ws(i['div'].get('contract_words'))}\"\n"
         + (f"   the interval the contract's words put the value in, per the reviewer: from {i['div']['contract_value']['lo'][0]} "
            f"{i['div']['contract_value']['lo'][1]} to {i['div']['contract_value']['hi'][0]} {i['div']['contract_value']['hi'][1]}\n"
            f"   the body's value at t={i['div'].get('at')} ms: {i.get('value')}; executed verdict: {i['rule']}"
            if isinstance(i['div'].get('contract_value'), dict) else
            f"   the reviewer's verdict for the contract: {i['div'].get('contract_verdict')}\n"
            f"   the body's executed verdict at t={i['div'].get('at')} ms: {i['rule']}")
         + ("\n\n" + _item_facts(i) if _item_facts(i) else ""))
        if i["div"].get("kind") != "not_general" else
        (f"{k}. (not_general) the words \"{_ws(i['div'].get('words'))}\": {_ws(i['div'].get('why'))}"
         + (" [a finding upheld before, decided again on this body]" if i.get("replay_of") or i.get("legacy_of") else ""))
        for k, i in enumerate(items, 1))
    key = f"concept:{rec.id}"
    prompt = render.render("adjudicate_concept.md", {**{k: blocks[k] for k in ("contract", "record", "rendered", "contracts")},
                                                      "items": "### Items\n\n" + listing + "\n", "precedents": precedents_block(precedent_rows(run, key, None, known))})
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
            if not _member(r.get("ruling"), CONCEPT_RULINGS):
                errs.append(f"item {k}: ruling must be one of {sorted(CONCEPT_RULINGS)}")
            if not _ws(r.get("reason")):
                errs.append(f"item {k}: a ruling needs a reason")
            if not _quoted(r.get("quote", ""), hay):
                errs.append(f"item {k}: the quote is not verbatim from the contract, the record or the rendering")
        errs += [f"item {k} has no ruling" for k in range(1, len(items) + 1) if k not in seen]
        return errs
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=defects, usage_label=f"{label}:{rec.id}")
    if answer is None and not errs:
        raise Deferred("concept_adjudication", "dry run: the concept's items were not adjudicated")
    if errs:
        raise Deferred("concept_adjudication", f"the concept adjudication stayed invalid: {'; '.join(errs)[:300]}")
    rows = {r.get("item"): r for r in answer.get("rulings", []) if isinstance(r, dict)}
    out = [(i, rows[k]["ruling"], f"{_ws(rows[k].get('reason'))} — \"{_ws(rows[k].get('quote'))[:160]}\"") for k, i in enumerate(items, 1)]
    for i, ruling, why in out:
        d = i["div"]
        if d.get("kind") == "not_general":                # a structural finding: an obligation by its identity, re-adjudicated later
            root = i.get("finding_root") or concept_lineage(run, rec, known)[-1]
            replay = {"schema": CONCEPT_STRUCTURAL_SCHEMA, "finding_root": root,
                      "finding_id": i.get("replay_of") or concept_finding_id(root, rec, d.get("words"), blocks.get("rendered", "")),
                      "words": d.get("words"), "why": d.get("why"), "contract_digest": contract_digest(rec),
                      "body_digest": body_digest, "obligation": "open" if ruling == "upheld" else None,
                      **({"legacy_of": i["legacy_of"]} if i.get("legacy_of") else {})}
        else:
            replay = {
                "schema": CONCEPT_CASE_SCHEMA, "case_id": concept_case_id(rec.id, d),
                **{x: d.get(x) for x in CONCEPT_CASE_FIELDS}, "verdict": i.get("verdict"), "value": i.get("value"),
                "contract_digest": contract_digest(rec), "body_digest": body_digest,
                "obligation": "open" if ruling == "upheld" else None}
            if i.get("replay_of"):
                replay["case_id"] = i["replay_of"]
            elif i.get("lineage_of"):                     # renewed content (an extension, or a recheck's answer): its own id
                replay["lineage"] = i["lineage_of"].get("case_id")
            if i.get("recheck"):
                replay["recheck"] = i["recheck"]
        _ruled(run, rulings, {"key": key, "subject": rec.id, "iteration": run.iteration, "item": _ws(i.get("line"))[:400],
                              "ruling": ruling, "reason": _ws(why)[:600], **replay}, (i.get("lineage_of") or {}).get("ruling_id"))
    return out


class ConceptTools(ReviewTools):
    """A concept reviewer's session: `run_instance` runs one divergence's instance of the body on
    its trace; `submit_review` runs every divergence of the answer the same way. Schema defects, a
    trace that does not decode or run, and an incomplete trace are what keeps a submission open; a
    trace on which the body agrees with the contract keeps its route, an advisory."""
    check_name = "run_instance"

    def __init__(self, rec, contract: str, rendering: str, result_dim, out_dir: Path, checks: int, submissions: int,
                 reading: Reading | None = None, carry: dict[str, dict] | None = None, registry: tuple[str, str] | None = None):
        self.rec, self.contract, self.rendering, self.result_dim, self.reading = rec, contract, rendering, result_dim, reading
        self.registry = registry
        self.carry = carry or {}
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
            self.cache[key] = execute_concept_divergences(self.rec, a, where, self.result_dim, self.reading, registry=self.registry)
        return self.cache[key]

    def extension_defects(self, k: int, d) -> list[str]:
        """Why divergence `k`'s `extends` is not an extension: it names no challenge to carry over, or
        it does not continue that challenge's evidence. Continuity is judged only on a divergence
        whose own schema holds; one that does not has its schema defects instead."""
        if not isinstance(d, dict) or "extends" not in d:
            return []
        if concept_divergence_defects(k, d, self.rec, self.contract, self.result_dim):
            return []
        old = self.carry.get(d["extends"]) if isinstance(d["extends"], str) else None
        if old is None:
            return [f"divergence {k}: `extends` names no challenge to carry over (they are {sorted(self.carry) or 'none'})"]
        return [f"divergence {k} extends {d['extends'][:12]} but does not continue it: {e}" for e in concept_extension_defects(old, d, self.rec)]

    def _check(self, d, where: Path) -> dict:
        schema = concept_divergence_defects(1, d, self.rec, self.contract, self.result_dim)
        schema = schema or self.extension_defects(1, d)
        if schema:
            return {"status": "schema defects", "messages": schema}
        confirmed, unconfirmed, errors, incomplete = self.run_answer({"divergences": [d]}, where)
        status = "unusable" if errors or incomplete else "agrees" if unconfirmed else "confirmed"
        return {"status": status, "messages": errors + incomplete + unconfirmed + [c["line"] for c in confirmed]}

    def _submit(self, a: dict, number: int) -> list[str]:
        errs = concept_review_defects(a, self.rec, self.contract, self.rendering, self.result_dim)
        divs = a.get("divergences") if isinstance(a.get("divergences"), list) else []
        errs += [e for k, d in enumerate(divs, 1) for e in self.extension_defects(k, d)]
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


CONCEPT_STRUCTURAL_SCHEMA = "concept_structural/1"
#: An older upheld concept row of a structural item, as its `item` was written before it had a schema.
_LEGACY_ITEM = re.compile(r'^not general: "(.*)" — (.*)$', re.S)


def concept_lineage(run: Run, rec, rows: list[dict] | None = None) -> list[str]:
    """The concept and every version it supersedes, newest first: through the accepted records (the
    run's and its base chain's) and, where a version is not among them, through the rulings (`rows`;
    the run's as they stand when None) that name its predecessor. A cycle stops the walk."""
    try:
        records = run.all_concepts()
    except AttributeError:
        records = {}
    preds = {r.get("subject"): r.get("predecessor") for r in (_all_rows(run) if rows is None else rows)
             if r.get("predecessor") and r.get("subject")}
    out, cur = [rec.id], rec.get("supersedes")
    while isinstance(cur, str) and cur and cur not in out:
        out.append(cur)
        cur = (records.get(cur) or {}).get("supersedes") or preds.get(cur)
    return out


def concept_finding_id(root: str, rec, words: str, rendering: str = "") -> str:
    """A structural finding's identity on a concept: the lineage's root (the first version), and
    the occurrence of the quoted words, where they first stand in the contract (else in the
    rendering): an unrelated concept with the same wording has another root, and other words of the
    same contract another occurrence. A successor carries the identity of the findings it inherits."""
    w, contract, shown = _ws(words), _ws(rec.get("contract")), _ws(rendering)
    at = ("contract", contract.find(w)) if w and w in contract else ("rendering", shown.find(w)) if w and w in shown else ("none", -1)
    return _digest({"concept_finding": root, "words": w, "source": at[0], "offset": at[1]})


@dataclass
class ConceptReplay:
    """What a concept's replay found: `items` for the adjudicator (executed challenges the body still
    confirms against the contract they were decided under, challenges renewed under the current
    contract that the body departs from, and open structural findings), `notes`, and `carry` (upheld
    challenges that cannot be run on this body, or whose effective claim is `undecided`, each
    `{case_id, row, reason, why}`): obligations the reviewer must carry over."""
    items: list = field(default_factory=list)
    notes: list = field(default_factory=list)
    carry: list = field(default_factory=list)

    def undecided(self) -> dict[str, int]:
        """The carried challenges the current contract leaves `undecided`, counted apart by why: the
        facts it turns on are missing, the contract does not decide, or the answer did not say."""
        out = {by: 0 for by in (*UNDECIDED_BY, "unstated")}
        for c in self.carry:
            if c.get("reason") == "undecided":
                out[c.get("undecided_by", "unstated")] = out.get(c.get("undecided_by", "unstated"), 0) + 1
        return out


#: Why a saved challenge cannot be run on the current record: its formals do not correspond (their
#: names, sorts, literal spellings, nats or parameters, or a claim of the other kind of concept); its
#: trace no longer admits (its shape, `at`, decoding, the trace check); its recorded history is
#: incomplete (the body is unknown only because the trace does not cover what it reads); a unit is
#: incompatible (a parameter's or the interval's dimension); a grounding is missing (a track or region
#: formal without an id). Such a challenge is carried to the reviewer, never discharged.
R0_REASONS = ("formals", "admission", "history", "units", "grounding")
#: A recheck's answer for a formula concept; a quantity's is an interval, or `undecided`.
RECHECK_VERDICTS = {"holds", "fails", "undecided"}
#: Why a recheck's answer is `undecided`, when it says: the facts leave a fact the answer turns on
#: unobserved, or the contract's words do not decide on the facts given.
UNDECIDED_BY = {"facts": "the facts it turns on are missing", "contract": "the contract's words do not decide it"}
PLACEHOLDERS_RECHECK_CONCEPT = ("contract", "contracts", "parameters", "facts", "question")
_SITUATION_NOTE = re.compile(r"\s*The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed\.")


def r0_reason(defect: str) -> str:
    """The reason (`R0_REASONS`) a schema defect of a saved challenge (`concept_divergence_defects`)
    names, read from the field the defect is about; the execution reports its own reason codes."""
    if re.search(r"grounding must map|regions must map", defect):
        return "grounding"
    if re.search(r"parameter `[^`]*` must be \[value, unit\]|contract_value: (?:the value is in|`lo` and `hi` are)", defect):
        return "units"
    if re.search(r"trace must be|every scene is|`at` must be", defect):
        return "admission"
    return "formals"


def contract_digest(rec) -> str:
    """The digest of a concept's contract, as a ruling records the contract it was decided under."""
    return _digest(_ws(rec.get("contract")))


def contract_block(rec, posted: dict[str, str] | None = None) -> str:
    """The contract as a concept's judges read it: its words, and the definition it quotes, by its id
    and, where `posted` holds it, with its posted text."""
    did = rec.get("definition")
    text = (posted or {}).get(str(did)) if did else None
    definition = (f"\n\nThe definition it quotes: `{did}`" + (f" — {_ws(text)}" if text else "")) if did else ""
    return f"### Contract\n\n`{rec.id}`: {_ws(rec.get('contract'))}{definition}\n"


def recheck_blocks(run: Run, rec, instance: dict, facts: str, result_dim: tuple | None) -> dict[str, str]:
    """What a recheck is shown, and nothing else: the current contract with the definition it quotes
    (its posted text, from the run's corpus);
    the contracts of the atoms and concepts its words map to (the record's elements) or name; each
    parameter the concept names, with its meaning and this instance's value; the executed facts; and
    the question the concept's kind asks. Never the body, its verdict or value, its rendering, the
    record's narrowings, a recorded claim or contract words, the reviewer's situation, or a ruling."""
    onto = ontology.load(run.opts.ontology)
    concepts = run.all_concepts()
    contract = _ws(rec.get("contract"))
    names = {a.split("=")[0] for a in rec.claimed_atoms()} | set(rec.refs())
    names |= {n for n in onto.atom_ids | set(concepts) if re.search(rf"(?<![\w.]){re.escape(n)}(?!\w)", contract)}
    glosses = {n: _ws((concepts.get(n) or {}).get("contract")) if n in concepts else onto.contract(n) for n in sorted(names)}
    given = (instance or {}).get("params") or {}
    params = [f"- `{p['name']}` ({p.get('unit')}): {_ws(p.get('meaning')) or 'no meaning stated'}; its value here: "
              + (f"{given[p['name']][0]} {given[p['name']][1]}" if isinstance(given.get(p["name"]), list) and len(given[p["name"]]) == 2 else "none given")
              for p in rec.params()]
    if rec.get("kind") == "quantity":
        dim = surface.render_dim(result_dim) if result_dim is not None else "the unit its contract's words state"
        question = (f"The concept is a quantity: a value in {dim}. Answer the interval the contract's words put its value in at the "
                    "observation judged, on these facts, or `undecided`.")
    else:
        question = ("The concept is a formula. Answer whether the contract's words, read on these facts at the observation judged, "
                    "hold, fail, or leave it undecided.")
    posted = {str(x.get("id")): str(x.get("text", "")) for x in corpus.load_definitions(Path(run.opts.laws))} if rec.get("definition") else {}
    return {"contract": contract_block(rec, posted),
            "contracts": "### The contracts of the names the contract's words use\n\n" + validate_phase.contracts_table(glosses),
            "parameters": "### Parameters\n\n" + ("\n".join(params) if params else "(none)") + "\n",
            "facts": _SITUATION_NOTE.sub("", facts),
            "question": "### The question\n\n" + question + "\n"}


def recheck_defects(a, rec, result_dim: tuple | None) -> list[str]:
    """Defects of a recheck's answer: a formula's `verdict` one of holds, fails, undecided; a
    quantity's `interval` (`lo` and `hi` as [value, unit], of the value's dimension, `lo` at most
    `hi`) or the verdict `undecided`, one of them; a `reason`; a `quote` verbatim from the contract."""
    if not isinstance(a, dict):
        return ["the answer must be a JSON object"]
    errs = []
    if rec.get("kind") == "quantity":
        if ("interval" in a) == (a.get("verdict") == "undecided"):
            errs.append('a quantity\'s answer states either `interval` or `"verdict": "undecided"`, and only one of them')
        elif "interval" in a:
            errs += [e.replace("divergence 0: contract_value", "`interval`") for e in _interval_defects(0, a["interval"], result_dim)]
    elif "interval" in a or not _member(a.get("verdict"), RECHECK_VERDICTS):
        errs.append(f"a formula's answer states `verdict`, one of {sorted(RECHECK_VERDICTS)}, and no `interval`")
    if "undecided_by" in a and (a.get("verdict") != "undecided" or not _member(a["undecided_by"], set(UNDECIDED_BY))):
        errs.append(f"`undecided_by` is given only with the verdict `undecided`, and is one of {sorted(UNDECIDED_BY)}")
    if not _is_str(a.get("reason")) or not _ws(a.get("reason")):
        errs.append("the answer needs a `reason`")
    if not _is_str(a.get("quote")) or not _in(a["quote"], _ws(rec.get("contract"))):
        errs.append("`quote` must be verbatim from the contract")
    return errs


def recheck_cache_file(run: Run) -> Path:
    """The run's recheck answers, one row per valid answer (`key`, the concept, the iteration, the
    answer): kept across iterations and restarts of the run, and never a ruling."""
    return run.dir / "recheck_answers.jsonl"


def recheck_concept(run: Run, rec, instance: dict, facts: str, out_dir: Path, result_dim: tuple | None,
                    label: str = "recheck") -> dict:
    """What the current contract decides on a saved challenge's executed facts, asked of
    `recheck_concept.md` with `recheck_blocks` alone: `verdict` or, for a quantity, `interval`, with
    `reason` and `quote` (and, for `undecided`, optionally `undecided_by`). An answer that stays
    invalid after the re-ask decides nothing: the replay defers, as an invalid concept adjudication
    does. A valid answer is kept in the run's recheck answers under the digest of the full prompt,
    the model and the effort (`validate.answer_digest`): the same recheck asked again in any later
    iteration or after a restart takes the latest kept answer that the current answer check admits,
    without a session; any change to what the prompt shows, to the prompt file, the model or the
    effort is another key."""
    prompt = render.render("recheck_concept.md", recheck_blocks(run, rec, instance, facts, result_dim))
    key = validate_phase.answer_digest(run, prompt)
    if not run.opts.dry_run:
        kept = [r for r in jsonl.read_strict(recheck_cache_file(run)) if r.get("key") == key and isinstance(r.get("answer"), dict)]
        for row in reversed(kept):
            if not recheck_defects(row["answer"], rec, result_dim):
                out_dir.mkdir(parents=True, exist_ok=True)
                (out_dir / f"{label}_prompt.md").write_text(prompt, encoding="utf-8")
                jsonl.write_atomic(out_dir / f"{label}_kept.json",
                                   json.dumps({"key": key, "iteration": row.get("iteration"), "answer": row["answer"]}, ensure_ascii=False, indent=1))
                return row["answer"]
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=lambda a: recheck_defects(a, rec, result_dim),
                                           usage_label=f"{label}:{rec.id}")
    if answer is None and not errs:
        raise Deferred("concept_adjudication", "dry run: the concept's challenge was not rechecked")
    if errs:
        raise Deferred("concept_adjudication", f"the concept recheck stayed invalid: {'; '.join(errs)[:300]}")
    jsonl.append_atomic(recheck_cache_file(run), {"key": key, "concept": rec.id, "iteration": run.iteration, "answer": answer})
    return answer


def _core_interval(iv: dict) -> tuple:
    """An interval's ends in Core units, exactly: ((unit, value), (unit, value))."""
    from ..model import units
    return tuple(units.to_core(*iv[e]) for e in ("lo", "hi"))


def recheck_claim(rec, answer: dict) -> dict | None:
    """The claim a recheck's answer states, in a recorded case's fields; None when it is `undecided`."""
    if answer.get("verdict") == "undecided":
        return None
    return {"contract_value": answer["interval"]} if rec.get("kind") == "quantity" else {"contract_verdict": answer["verdict"]}


def same_claim(rec, claim: dict, row: dict) -> bool:
    """Whether a claim is the one a case records: the same verdict; for a quantity, the same interval
    once both are converted to Core units."""
    if rec.get("kind") != "quantity":
        return claim.get("contract_verdict") == row.get("contract_verdict")
    try:
        return _core_interval(claim["contract_value"]) == _core_interval(row.get("contract_value"))
    except (KeyError, TypeError, ValueError):
        return False


def body_within(rec, claim: dict, obs: dict) -> bool:
    """Whether the body, as executed (`obs`), gives a claim: a formula's verdict equal to it; a
    quantity's value contained in the interval, both ends included, compared exactly once the value
    and the interval are in one unit (Core's)."""
    if rec.get("kind") != "quantity":
        return {"compliant": "holds", "violated": "fails"}.get(obs.get("tag")) == claim.get("contract_verdict")
    from fractions import Fraction
    raw = obs.get("value")
    if not isinstance(raw, str) or not re.fullmatch(r"-?\d+/\d+", raw):
        return False
    num, den = raw.split("/", 1)
    (_, lo), (_, hi) = _core_interval(claim["contract_value"])
    return lo <= Fraction(int(num), int(den)) <= hi


def _claim_text(claim: dict | None) -> str:
    if claim is None:
        return "undecided"
    if "contract_value" in claim:
        lo, hi = claim["contract_value"]["lo"], claim["contract_value"]["hi"]
        return f"from {lo[0]} {lo[1]} to {hi[0]} {hi[1]}"
    return str(claim.get("contract_verdict"))


#: Why a challenge whose recheck left the current contract undecided is carried, not compared.
UNDECIDED = "the current contract does not decide the recorded claim"


def _undecided_why(by: str) -> str:
    return f" ({UNDECIDED_BY[by]})" if by in UNDECIDED_BY else ""


def undecided_under(r: dict, current: str) -> bool:
    """Whether a case's effective claim is `undecided`: its last recheck, made under the current
    contract (`current`, its digest), found the contract deciding nothing on its facts."""
    rc = r.get("recheck") if isinstance(r.get("recheck"), dict) else {}
    return (rc.get("answer") or {}).get("verdict") == "undecided" and rc.get("contract_digest") == current == r.get("contract_digest")


def renewed_content(rec, old: dict, d: dict, claim: dict, quote: str) -> dict:
    """The content of a case renewed under the current contract: the recorded trace, instance,
    grounding, regions and instant, with the recheck's answer as its claim, its quote as the contract
    words, the kind that claim makes, and a situation that names the case it was renewed from."""
    quantity = rec.get("kind") == "quantity"
    fields = {x: d.get(x) for x in CONCEPT_CASE_FIELDS if d.get(x) is not None and x not in ("contract_verdict", "contract_value")}
    return {**fields, **claim, "contract_words": quote,
            "kind": "value_wrongly" if quantity else {"holds": "fails_wrongly", "fails": "holds_wrongly"}[claim["contract_verdict"]],
            "situation": f"renewed from {old.get('case_id')} under the current contract"}


def recheck_case(run: Run, rec, r: dict, d: dict, obs: dict, out: ConceptReplay, out_dir: Path, result_dim: tuple | None,
                 body_digest: str, rulings: ReviewRulings | None = None) -> None:
    """A saved challenge that runs on this body, recorded under another contract than the current one
    (or under no recorded contract): the current contract is rechecked on its executed facts, and
    the answer is compared with the body.
    - `undecided`: one row, the same id, `open`, the current digest and the `recheck`; that answer is
      the case's effective claim from then on, so it is carried to the reviewer (`UNDECIDED`) and
      never compared, on this replay and every later one under the same contract.
    - The body within the answer: one row, `satisfied`, the current digest and the `recheck`; under
      the same id when the answer is the recorded claim, else as a renewed case (`renewed_content`)
      under its own id, with `lineage` the old case and superseding its ruling.
    - The body outside the answer: the renewed case goes to the concept adjudicator as a confirmed
      divergence (`lineage_of`, with the `recheck`), whose ruling is its row: upheld returns the
      concept, dismissed records it dismissed."""
    cid = str(r.get("case_id") or "")
    quantity = rec.get("kind") == "quantity"
    answer = recheck_concept(run, rec, d.get("instance") or {}, obs.get("facts") or executed_facts(d), out_dir / f"recheck_{cid[:12]}", result_dim)
    claim = recheck_claim(rec, answer)
    body = _core_value(obs.get("value"), result_dim) if quantity else {"compliant": "holds", "violated": "fails"}.get(obs.get("tag"), obs.get("tag"))
    current = contract_digest(rec)
    said = _claim_text(claim)
    recheck = {"answer": {k: answer[k] for k in ("verdict", "interval", "undecided_by") if k in answer}, "quote": answer["quote"],
               "contract_digest": current}
    reason = _ws(f"rechecked under the current contract: {said} — {_ws(answer.get('reason'))} — \"{_ws(answer.get('quote'))[:160]}\"; "
                 f"the body: {body}")[:600]
    if claim is not None and not body_within(rec, claim, obs):
        content = renewed_content(rec, r, d, claim, answer["quote"])
        head = (f"divergence (renewed from {cid[:12]}) at t={d.get('at')} ms — contract: {said}; "
                + (f"the body's value there: {body}" if quantity else f"body: {body}"))
        out.items.append({"line": head + f'; contract: "{_ws(answer["quote"])[:120]}"', "div": content, "rule": body,
                          "key": content["kind"], "verdict": obs.get("tag"), "value": body if quantity else None,
                          "facts": obs.get("facts") or executed_facts(d), "lineage_of": r, "recheck": recheck})
        return
    fields = {x: d.get(x) for x in CONCEPT_CASE_FIELDS if d.get(x) is not None}
    renewed = claim is not None and not same_claim(rec, claim, r)
    if renewed:
        fields = renewed_content(rec, r, d, claim, answer["quote"])
    row = satisfied_on(run, rec, r, fields, body_digest, "open" if claim is None else "satisfied")
    if renewed:
        row = {k: v for k, v in row.items() if k not in ("contract_verdict", "contract_value") or k in fields}
    row.update({"contract_digest": current, "verdict": obs.get("tag"), "value": body if quantity else None, "recheck": recheck, "reason": reason})
    if renewed:
        row.update({"case_id": concept_case_id(rec.id, row), "lineage": cid,
                    "item": _ws(f"recheck of {cid[:12]} (t={d.get('at')} ms): the current contract decides {said}, the case recorded "
                                f"{_claim_text({k: r.get(k) for k in ('contract_verdict', 'contract_value') if r.get(k) is not None})}; "
                                f"the body: {body}")[:400]})
        written = _ruled(run, rulings, row, r.get("ruling_id"))
    else:
        written = _ruled(run, rulings, row)
    if claim is None:
        by = answer.get("undecided_by", "unstated")
        out.carry.append({"case_id": written["case_id"], "row": written, "reason": "undecided", "undecided_by": by,
                          "why": f"{UNDECIDED}{_undecided_why(by)}: {_ws(answer.get('reason'))[:300]}"})
    else:
        out.notes.append("an upheld challenge is met by this body under the current contract; it stays an obligation: "
                         f"challenge {written['case_id'][:12]} (t={d.get('at')} ms), rechecked: the current contract: {said}; the body: {body}")


def satisfied_on(run: Run, rec, old: dict, evidence: dict, body_digest: str, obligation: str = "satisfied") -> dict:
    """The row recording that this concept's body meets an upheld challenge (or, with `obligation`
    `open`, that it does not): on this concept's identity (its key and subject), with the evidence it
    was met on (the grounding, instance and trace that continue the challenge), the case's identity
    and lineage, and the version it came from. Its rows of an earlier version are superseded by it; a
    later version finds it through the lineage."""
    row = {k: v for k, v in old.items() if k not in ("ruling_id", "supersedes", "inherited_from")}
    row.update(evidence)
    row.update({"key": f"concept:{rec.id}", "subject": rec.id, "iteration": run.iteration, "obligation": obligation,
                "ruling": "upheld", "body_digest": body_digest, "lineage": old.get("lineage") or old.get("case_id"),
                "predecessor": old.get("subject") if old.get("subject") != rec.id else old.get("predecessor")})
    return row


def replay_concept(run: Run, rec, out_dir: Path, result_dim: tuple | None, body_digest: str,
                   rulings: ReviewRulings | None = None) -> ConceptReplay:
    """The upheld challenges and structural findings of this concept, and of the concept it
    supersedes, before any reviewer. Each challenge is read from its effective row (the last of its
    supersession chain), whose claim and `contract_digest` decide its path:
    - R0: it cannot be run on this body (its formals do not correspond, its trace no longer admits,
      its recorded history is incomplete, a unit is incompatible, a grounding is missing), or its
      effective claim is `undecided` under the current contract (`undecided_under`): it is an
      obligation of insufficient evidence, carried over to the reviewer with its reason, never
      compared, never discharged by default, never rechecked again, and no row is written;
    - R1: it runs, and its row was decided under the current contract (the same digest): the body
      giving the recorded claim leaves it `satisfied`; one that does not goes to the adjudicator
      (`replay_of`);
    - R2: it runs, and its row was decided under another contract, or records none: the current
      contract is rechecked on its executed facts (`recheck_case`), never shown the body or the
      recorded claim, and the answer is compared with the body; a body that departs from the answer
      goes to the adjudicator as a renewed case. What R2 records carries the current digest, so the
      next replay of the same contract takes R1 (or R0, for `undecided`) and pays no recheck.
    An open structural finding, and an older upheld structural row without a schema, goes back to
    the adjudicator against the current contract and rendering. Within a review, the rulings read
    and written are its own (`rulings`: those the run had when it began, then its own)."""
    every = (lambda: rulings.rows()) if rulings is not None else (lambda: _all_rows(run))
    keys = {f"concept:{c}" for c in concept_lineage(run, rec, every())}
    rows = [r for r in effective_rows(every()) if r.get("key") in keys and r.get("ruling") == "upheld"]
    out = ConceptReplay()
    contract = " ".join(str(rec.get("contract", "")).split())
    current = contract_digest(rec)
    formals = {a["name"]: a.get("sort") for a in rec.args()}
    divs, by_k = {}, {}
    for r in [r for r in rows if r.get("schema") == CONCEPT_CASE_SCHEMA and r.get("obligation") in ("open", "satisfied", None)]:
        d = {x: r.get(x) for x in CONCEPT_CASE_FIELDS if r.get(x) is not None}
        inst, g = r.get("instance") or {}, r.get("grounding") or {}
        named = {**{f: "literal" for f in inst.get("literals") or {}}, **{f: "nat" for f in inst.get("nats") or {}}, **{f: "track" for f in g},
                 **{f: "region" for f in r.get("regions") or {}}}
        if any(formals.get(f) != sort for f, sort in named.items()) or set(named) != set(formals):
            out.carry.append({"case_id": r.get("case_id"), "row": r, "reason": "formals",
                              "why": f"its formals {sorted(named)} do not correspond to {sorted(formals)}"})
            continue
        bad = concept_divergence_defects(1, d, rec, contract, result_dim, saved=True)
        if bad:
            out.carry.append({"case_id": r.get("case_id"), "row": r, "reason": r0_reason(bad[0]),
                              "why": "its record fails today's schema: " + "; ".join(bad)[:300]})
            continue
        if undecided_under(r, current):                   # the contract decides nothing here: carried, never compared
            by = ((r.get("recheck") or {}).get("answer") or {}).get("undecided_by", "unstated")
            out.carry.append({"case_id": r.get("case_id"), "row": r, "reason": "undecided", "undecided_by": by,
                              "why": f"{UNDECIDED}{_undecided_why(by)}: {_ws((r.get('recheck') or {}).get('quote'))[:200]}"})
            continue
        k = len(divs) + 1
        divs[k], by_k[k] = d, r
    runs: dict[int, dict] = {}
    confirmed, unconfirmed, errors, incomplete = execute_concept_divergences(
        rec, {"divergences": list(divs.values())}, out_dir, result_dim, Reading(run.reading_file), saved=True,
        registry=_registry(run, rec.id, concept_dir(run, rec.id)), runs=runs) if divs else ([], [], [], [])
    k_of = lambda line: int(m.group(1)) if (m := re.match(r"divergence (\d+)", line)) else None
    for line in errors + incomplete:
        k = k_of(line)
        r = by_k.pop(k, None)
        if r is not None:
            out.carry.append({"case_id": r.get("case_id"), "row": r, "reason": (runs.get(k) or {}).get("reason") or "admission",
                              "why": f"it cannot be run on this body: {line[:300]}"})
    confirms = {k_of(c["line"]): c for c in confirmed}
    meets = {k_of(line): line for line in unconfirmed}
    for k, r in by_k.items():
        if r.get("contract_digest") != current and (k in confirms or k in meets):
            recheck_case(run, rec, r, divs[k], runs.get(k) or {}, out, out_dir, result_dim, body_digest, rulings)
        elif k in confirms:
            out.items.append({**confirms[k], "replay_of": r.get("case_id")})
        elif k in meets:
            if r.get("obligation") != "satisfied" or r.get("subject") != rec.id:
                _ruled(run, rulings, satisfied_on(run, rec, r, {x: r.get(x) for x in CONCEPT_CASE_FIELDS if r.get(x) is not None}, body_digest))
            out.notes.append(f"an upheld challenge is met by this body; it stays an obligation: {meets[k][:240]}")
    # structural findings: typed rows, and older rows written before they had a schema
    migrated = {r.get("legacy_of") for r in every() if r.get("legacy_of")}     # any row that ever took an older row over
    typed = [r for r in rows if r.get("schema") == CONCEPT_STRUCTURAL_SCHEMA and r.get("obligation") in ("open", None)
             and r.get("ruling_id") not in migrated]
    for r in typed:
        item = {"line": f"not general: \"{_ws(r.get('words'))}\" — {_ws(r.get('why'))}", "rule": "not executed", "key": "not_general",
                "div": {"kind": "not_general", "words": r.get("words"), "why": r.get("why")}}
        if r.get("finding_root"):                         # carried under its own identity
            item.update({"replay_of": r.get("finding_id"), "finding_root": r["finding_root"]})
        else:                                             # written before findings had a root: decided again under a rooted identity
            item["legacy_of"] = r.get("ruling_id")
        out.items.append(item)
    for r in rows:
        if r.get("schema") or r.get("case_id") or r.get("finding_id") or r.get("ruling_id") in migrated:
            continue
        m = _LEGACY_ITEM.match(_ws(r.get("item")))
        words, why = (m.group(1), m.group(2)) if m else ("", "")
        out.items.append({"line": _ws(r.get("item")) if m else f"an earlier upheld finding, as recorded: {_ws(r.get('item'))[:300]}",
                          "rule": "not executed", "key": "not_general", "legacy_of": r.get("ruling_id"),
                          "div": {"kind": "not_general", "words": words or _ws(r.get("item")), "why": why or _ws(r.get("reason"))}})
    return out


def carry_over_block(carry: list[dict]) -> str:
    """The upheld challenges the reviewer must carry over to this body: each with its recorded
    instance, grounding, trace, instant and claim, and why it cannot be judged as recorded."""
    if not carry:
        return ""
    out = ["### Challenges to carry over", "",
           "Each challenge below was upheld against an earlier body of this concept and stays an obligation, but it cannot be judged "
           "on this body as recorded. For each, submit a divergence with `\"extends\": \"<case id>\"` that continues it: every scene "
           "of its trace, with every field it states, and the same instant, contract words and claimed verdict or interval; where "
           "the recorded contract words are no longer verbatim in the contract, quote the contract's words that decide the same claim "
           "instead; where it is marked `undecided` (the current contract does not decide the recorded claim), state the claim the "
           "current contract's words decide there, quoting them; every recorded formal keeps its value, under the same name or the "
           "one formal it became; only a formal the challenge did not have takes a value of yours. A challenge left without such a "
           "divergence keeps the review open.", ""]
    for c in carry:
        r = c.get("row") or {}
        out += [f"#### Challenge `{c.get('case_id')}`", "", _ws(r.get("item"))[:400], "",
                f"Why it cannot be judged as recorded ({c.get('reason', 'formals')}): {c.get('why')}", "",
                "Its record: ```json " + json.dumps({k: r.get(k) for k in CONCEPT_CASE_FIELDS if r.get(k) is not None}, ensure_ascii=False)[:6000] + "```", ""]
    return "\n".join(out) + "\n"


def concept_blocks(run: Run, rec, extras: dict) -> tuple[dict[str, str], str, str]:
    """What a concept's reviewer and adjudicator are shown: (the prompt blocks, the rendering of the
    body, the contract). `extras` carries the body (`body_json`), the atoms it reads and the
    readings its coder chose: the gate's extras for a concept under review, or the accepted record
    itself, which keeps them. The body is the gate's export, every call of another concept expanded
    into that concept's body, and it is what the rendering shows; the contracts shown are those of
    the atoms it reads, of every primitive that body calls, at any depth, with its ontology
    contract, and of the catalogue's concepts. Raises `render_formula.Unrendered`."""
    onto = ontology.load(run.opts.ontology)
    glosses = {aid: onto.contract(aid) for aid in extras.get("reads", [])}
    glosses.update(validate_phase.glosses_of(primitives_called(extras.get("body_json")), onto, run))
    for cid, crec in run.all_concepts().items():
        glosses[cid] = " ".join(str(crec.get("contract", "")).split())
    rendering = render_formula.render_concept({"args": [{"name": a["name"], "sort": {"sort": a["sort"], "values": a.get("values", [])}} for a in rec.args()],
                                               "params": [{"name": p["name"], "unit": p["unit"]} for p in rec.params()],
                                               "kind": rec.get("kind"), "body": extras.get("body_json")}, glosses)
    contract = " ".join(str(rec.get("contract", "")).split())
    record = {k: v for k, v in rec.raw.items() if k not in ("scenarios", "used_by")}
    record["narrowings_by_the_coder"] = [n for n in extras.get("narrowings_added", []) if isinstance(n, dict)]
    blocks = {
        "contract": contract_block(rec),
        "record": "### Record\n\n```json\n" + json.dumps(record, ensure_ascii=False, indent=1) + "\n```\n\n" + literal_formals_line(rec) + "\n",
        "rendered": "### Rendering\n\n" + rendering + "\n",
        "atoms_read": atoms_read_block(extras.get("body_json") or {}, run.all_concepts(), what="concept"),
        "contracts": validate_phase.contracts_table(glosses),
        "trace_format": trace_format_block(),
        "review_checks": str(run.opts.review_checks),
        "review_submissions": str(run.opts.review_submissions),
    }
    return blocks, rendering, contract


# ---------------------------------------------------------------------------------------------
# A reported defect of a concept a task reaches: adjudicated before anyone is charged
# ---------------------------------------------------------------------------------------------
@dataclass
class DependencyReport:
    """What became of a task's `dependency_defect.json`, the stage it reached, and what it costs.

    `status`, by stage:
    - `none`: no report was written.
    - `protocol`: a report was written and refused before any ruling: malformed, naming a concept
      the task does not reach, a trace that does not run, or no disagreement when the concept is
      run on it. No ruling exists and the concept takes no obligation from it. The session produced
      its output, so its attempt is counted as any finished but invalid output is: a repair spends
      one of its attempts, a coding task is charged by its own gate verdict.
    - `upheld` or `dismissed`: the concept adjudication ruled on a confirmed disagreement; the
      attempt is counted as a finished one.
    - `deferred` (a judge's answer stayed invalid) or `unavailable` (a session or a program did not
      run): the ruling is not finished (`NOT_JUDGED`); no attempt is counted, the task waits and its
      report is judged again.
    Whatever the status, the API cost of every session that ran is booked: an attempt not counted
    is not free.

    `execution` is what running the reported trace showed, kept apart from the ruling: `not_run`
    (refused on its form), `not_confirmed` (run; no disagreement shown), `confirmed` (run; the
    concept gives what the report says its contract excludes) or `unknown` (the stage was not
    recorded, as when the run itself stopped). `concept` is the concept the report names, once read."""
    status: str
    concept: str = ""
    reasons: list[str] = field(default_factory=list)
    line: str = ""
    execution: str = "unknown"


#: A report no one could decide (`loop.report_of`): its task waits, uncharged and unpublished, and
#: the report is judged again; every caller routes these two the same way.
NOT_JUDGED = ("deferred", "unavailable")


def report_form(run: Run, task_dir: Path, reached: set[str]) -> tuple[dict, list[str]]:
    """A task's `dependency_defect.json` and what is wrong with its form: not JSON, a concept the
    task does not reach (or not accepted), or a divergence that does not meet the concept's schema."""
    from ..model.blueprint import ConceptRecord
    try:
        d = json.loads((task_dir / "dependency_defect.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        return {}, [f"dependency_defect.json cannot be read: {e}"]
    cid = d.get("concept_id") if isinstance(d, dict) else None
    acc = run.all_concepts().get(cid) if isinstance(cid, str) else None
    if acc is None or cid not in reached:
        return d if isinstance(d, dict) else {}, [f"the report names `{cid}`, which is not an accepted concept this task reaches"]
    rec = ConceptRecord(acc)
    result_dim = body_dim(rec, acc.get("body_json")) if rec.get("kind") == "quantity" else None
    return d, concept_divergence_defects(1, d, rec, " ".join(str(rec.get("contract", "")).split()), result_dim)


def dependency_report(run: Run, task_dir: Path, reached: set[str]) -> DependencyReport:
    """Read and judge a task's report that a concept it reaches computes what its contract
    excludes. The report is a concept divergence (the concept's id, the contract's words, the
    instance with its `nats`, the grounding, a trace, `at`, and the claimed contract verdict or, for
    a quantity, interval). The harness checks its form, that the task reaches the concept, and runs
    the concept on the trace; a disagreement goes to the existing concept adjudication. Its ruling is
    recorded like a concept review's."""
    from ..model.blueprint import ConceptRecord
    if not (task_dir / "dependency_defect.json").exists():
        return DependencyReport("none")
    d, bad = report_form(run, task_dir, reached)
    cid = d.get("concept_id") if isinstance(d, dict) else ""
    if bad:
        return DependencyReport("protocol", str(cid or ""), bad, execution="not_run")
    reached_stage = DependencyReport("unavailable", cid)       # what a stage that stops leaves known (`loop.report_of`)
    try:
        acc = run.all_concepts()[cid]
        rec = ConceptRecord(acc)
        result_dim = body_dim(rec, acc.get("body_json")) if rec.get("kind") == "quantity" else None
        out = task_dir / "dependency_defect"
        confirmed, agrees, errors, incomplete = execute_concept_divergences(rec, {"divergences": [d]}, out, result_dim, Reading(run.reading_file),
                                                                            registry=_registry(run, rec.id, task_dir))
        if not confirmed:
            return DependencyReport("protocol", cid, errors + incomplete + [f"the concept gives the verdict the report claims for its contract: {x}" for x in agrees],
                                    execution="not_confirmed")
        reached_stage.execution = "confirmed"
        blocks, _rendering, _contract = concept_blocks(run, rec, acc)
        rulings, decided = resume_review(run, out, lambda rows: concept_inputs(run, rec, acc, blocks, rows, {"report": d}))
        if decided is not None:
            return DependencyReport(**{"execution": "confirmed", **decided})
        ruled = adjudicate_concept(run, rec, blocks, confirmed, out, _digest(acc.get("body_json")), "adjudicate_report", rulings)
        item, ruling, why = ruled[0]
        return finish_review(run, out, rulings, {}, DependencyReport("upheld" if ruling == "upheld" else "dismissed", cid, [why], item["line"],
                                                                     execution="confirmed"), True)
    except (Deferred, HarnessFailure, session.SessionUnavailable) as e:
        e.reached = reached_stage
        raise


def _concept_context(run: Run, rec, extras: dict) -> str | None:
    """The body as built and the context its gate ran on, or None when that context cannot be
    computed (`_pass_context`, for a concept)."""
    from . import code as code_phase
    try:
        task = code_phase.task_context(run, "concept", rec.id, rec.raw, Reading(run.reading_file))
    except Exception:
        return None
    return _digest({"body": extras.get("body_json"), "task": task}) if task else None


def concept_inputs(run: Run, rec, extras: dict, blocks: dict[str, str], rows: list[dict], more: dict | None = None) -> str | None:
    """The identity of what a concept's review (or the adjudication of a defect reported against
    it, with the report in `more`) decides on: the record, the body, what it reads and the coder's
    readings, the context its gate ran on (`_concept_context`), everything its reviewer and judges
    are shown but the rulings, the reading, the lineage's rulings as the review began (`rows`), and
    `review_settings`. None when the gate's context cannot be computed: then nothing the review
    saved is taken back."""
    context = _concept_context(run, rec, extras)
    if context is None:
        return None
    keys = {f"concept:{c}" for c in concept_lineage(run, rec, rows)}
    return _inputs_digest({"record": rec.raw, "body": extras.get("body_json"), "reads": extras.get("reads"),
                           "narrowings": extras.get("narrowings_added"), "context": context, "shown": blocks,
                           "reading": Reading(run.reading_file).data, "rulings": [r for r in effective_rows(rows) if r.get("key") in keys],
                           **(more or {}), **review_settings(run, CONCEPT_REVIEW_PROMPTS, CONCEPT_REVIEW_SETTINGS)})


def review_concept(run: Run, rec, extras: dict, out_dir: Path) -> ReviewOutcome:
    """The concept's body, rendered from its code, is reviewed by a second vendor against its
    contract: each divergence comes as a trace (which passes the trace check) and an instance, the
    harness runs the body on it, and every divergence execution confirms, and every `not_general`
    item, goes to the adjudicator, which rules by the contract's words. `returned` with the upheld
    items; else `deferred` when a challenge could not be evaluated (stage `reviewer`), the
    adjudication stays invalid or the harness does not run; else `accepted`, its advisories recorded
    on the concept as what it computes as built. As a node's review, it reads the rulings as they
    stood when it began and saves its outcome with its rulings before they are recorded
    (`resume_review`, `finish_review`). Raises `SessionUnavailable` when a session could not be
    launched."""
    if not enabled(run):
        if run.opts.dry_run:
            return ReviewOutcome("accepted", advisories=["dry run"])
        raise RuntimeError("a reviewer_model is required for a concept review")
    try:
        blocks, rendering, contract = concept_blocks(run, rec, extras)
    except render_formula.Unrendered as e:
        raise session.SessionUnavailable(f"the renderer has no phrasing for the {e} (harness/lean/render_formula.py)") from e
    out_dir.mkdir(parents=True, exist_ok=True)
    rulings, decided = resume_review(run, out_dir, lambda rows: concept_inputs(run, rec, extras, blocks, rows))
    if decided is not None:
        return outcome_of(decided)
    done = lambda data, outcome: finish_review(run, out_dir, rulings, data, outcome, outcome.status != "deferred")
    (out_dir / "rendered_body.md").write_text(rendering, encoding="utf-8")
    result_dim = body_dim(rec, extras.get("body_json")) if rec.get("kind") == "quantity" else None
    body_digest = _digest(extras.get("body_json"))
    replay_notes: list[str] = []
    try:
        rep = replay_concept(run, rec, out_dir / "replay", result_dim, body_digest, rulings)
        replay_notes = rep.notes
        replayed = adjudicate_concept(run, rec, blocks, rep.items, out_dir, body_digest, "adjudicate_replay", rulings) if rep.items else []
    except HarnessFailure as e:
        return done({"deferred": str(e)}, ReviewOutcome("deferred", reasons=[f"replay: {e}"], defer_stage="certificate"))
    except Deferred as e:
        return done({"deferred": e.why}, ReviewOutcome("deferred", reasons=[e.why], defer_stage=e.stage, advisories=replay_notes))
    still = [f"{i['line']} — upheld again: {w}" for i, r, w in replayed if r == "upheld"]
    if still:
        return done({"replayed": still}, ReviewOutcome("returned", reasons=still, advisories=replay_notes))
    carry = {c["case_id"]: c["row"] for c in rep.carry if c.get("case_id")}
    prompt = render.render("review_concept.md", {**blocks, "carry_over": carry_over_block(rep.carry)})
    tools = ConceptTools(rec, contract, rendering, result_dim, out_dir, run.opts.review_checks,
                         run.opts.review_submissions, Reading(run.reading_file), carry,
                         registry=_registry(run, rec.id, concept_dir(run, rec.id)))
    (out_dir / "review_concept_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return finish_review(run, out_dir, rulings, {}, ReviewOutcome("accepted", advisories=["review skipped (dry run)"]), False)
    try:
        session.run_tools(prompt, out_dir, run.opts, tools, label="review_concept", effort=run.opts.review_effort,
                          model=run.opts.reviewer_model, subject=rec.id)
    except HarnessFailure as e:
        return done({"deferred": str(e)}, ReviewOutcome("deferred", reasons=[str(e)], defer_stage="certificate"))
    answer = tools.answer
    if answer is None:
        why = f"concept review: the reviewer submitted no answer in {tools.max_requests} requests"
        return done({"deferred": why}, ReviewOutcome("deferred", reasons=[why], defer_stage="reviewer"))
    errs = concept_review_defects(answer, rec, contract, rendering, result_dim)
    if not _member(answer.get("verdict"), VERDICTS):
        why = "concept review: the answer is not a review: " + "; ".join(errs)
        return done({"deferred": why}, ReviewOutcome("deferred", reasons=[why], defer_stage="reviewer"))
    confirmed, unconfirmed, errors, incomplete = tools.final         # the submitted answer's divergences, as run
    listed = answer.get("divergences") if isinstance(answer.get("divergences"), list) else []
    extension = {k: d["extends"] for k, d in enumerate(listed, 1)
                 if isinstance(d, dict) and isinstance(d.get("extends"), str) and d["extends"] in carry
                 and not concept_divergence_defects(k, d, rec, contract, result_dim) and not tools.extension_defects(k, d)}
    # an extension whose contract words (no longer verbatim) or claim (the challenge's was `undecided`) are not the recorded ones
    # is new content: a new id with lineage
    renewed = {k for k, cid in extension.items() if _ws(listed[k - 1].get("contract_words")) != _ws(carry[cid].get("contract_words"))
               or any(listed[k - 1].get(f) != carry[cid].get(f) for f in ("contract_verdict", "contract_value"))}
    k_of = lambda line: int(m.group(1)) if (m := re.match(r"divergence (\d+)", line)) else None
    for c in confirmed:                                   # an extension continues its challenge's lineage
        if k_of(c["line"]) in renewed:
            c["lineage_of"] = carry[extension[k_of(c["line"])]]
        elif k_of(c["line"]) in extension:
            c["replay_of"] = extension[k_of(c["line"])]
    for line in unconfirmed:                              # an extension the body meets: the challenge stays an obligation, satisfied,
        old = carry.get(extension.get(k_of(line)))       # decided under the current contract, which it was evaluated under
        if old is not None:
            d = listed[k_of(line) - 1]
            row = satisfied_on(run, rec, old, {x: d.get(x) for x in CONCEPT_CASE_FIELDS if d.get(x) is not None}, body_digest)
            row = {**{k: v for k, v in row.items() if k != "recheck"}, "contract_digest": contract_digest(rec)}
            if k_of(line) in renewed:
                row.update({"case_id": concept_case_id(rec.id, row), "lineage": old.get("case_id")})
                rulings.add(row, old.get("ruling_id"))
            else:
                rulings.add(row)
    ran = {k_of(x["line"]) for x in confirmed} | {k_of(x) for x in unconfirmed}
    unextended = sorted(cid for cid in carry if cid not in {extension[k] for k in extension if k in ran})
    tuned_all = answer.get("not_general") if isinstance(answer.get("not_general"), list) else []
    tuned = [{"line": f"not general: \"{_ws(t.get('words'))}\" — {_ws(t.get('why'))}", "div": {"kind": "not_general", **t}, "rule": "not executed",
              "key": "not_general"} for k, t in enumerate(tuned_all, 1) if not structural_item_defects(k, t, contract, rendering)]
    items = confirmed + tuned
    try:
        ruled = adjudicate_concept(run, rec, blocks, items, out_dir, body_digest, "adjudicate", rulings) if items else []
    except Deferred as e:
        return done({"deferred": e.why}, ReviewOutcome("deferred", reasons=[e.why], defer_stage=e.stage))
    upheld = [f"{i['line']} — upheld: {w}" for i, r, w in ruled if r == "upheld"]
    notes = replay_notes + [str(x) for x in answer.get("advisories", [])] + [f"dismissed: {i['line']} — {w}" for i, r, w in ruled if r == "dismissed"]
    # a challenge the harness could not evaluate (a schema defect of the final answer, a trace that
    # does not decode or run, an incomplete trace) leaves the review undecided: without an upheld
    # item it defers the concept; a trace on which the body gives the contract's verdict is advisory
    unusable = concept_review_defects(answer, rec, contract, rendering, result_dim) + errors + incomplete \
        + [e for k, d in enumerate(listed, 1) for e in tools.extension_defects(k, d)]
    data = {"reviewer_verdict": answer.get("verdict"), "rulings": [{"item": i["line"], "ruling": r, "why": w} for i, r, w in ruled],
            "unconfirmed": unconfirmed, "unusable": unusable, "schema_defects": errs, "undecided": rep.undecided()}
    if upheld:
        return done(data, ReviewOutcome("returned", reasons=upheld, advisories=notes))
    if unusable:
        return done(data, ReviewOutcome("deferred", reasons=[f"concept review: {len(unusable)} challenge(s) could not be evaluated: "
                                                             + " | ".join(unusable)[:900]], advisories=notes, defer_stage="reviewer"))
    if unextended:
        why = {c["case_id"]: c["why"] for c in rep.carry}
        return done(data, ReviewOutcome("deferred", reasons=["challenges carried over but not extended: "
                                                             + " | ".join(f"{cid[:12]}: {why.get(cid, '')}" for cid in unextended)[:900]],
                                        advisories=notes, defer_stage="evidence"))
    return done(data, ReviewOutcome("accepted", advisories=notes + [f"refuted by execution: {x}" for x in unconfirmed]))
