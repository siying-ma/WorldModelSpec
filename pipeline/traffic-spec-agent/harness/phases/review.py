"""The concept review: a second vendor's model shows, as executable traces, situations in which a
concept's body and its contract decide differently; the harness runs the body on each one; the
concept adjudicator rules on every confirmed divergence and every word-level item by the contract's
words.

A divergence's trace must be consistent (`TraceLint.checkTrace`) before the body is run on it
(`execute_concept_divergences`, one Lean program per review). The reviewer runs that program itself
through its tools before it submits; the harness runs it on every divergence of the submission. A
submission with a schema defect or a divergence that cannot be evaluated comes back while
submissions remain; the last one stands. An adjudication whose answer stays invalid defers the
concept (bounded by the ledger), never upholds by default. An upheld challenge is replayed on every
later version of the concept's lineage (`replay_concept`) and rechecked where its words changed
(`recheck_concept`). The same adjudication decides a coder's dependency-defect report
(`dependency_report`).

Every ruling is appended to the run's `rulings.jsonl` (supersession by `ruling_identity`, never
rewritten); a review saves its outcome with its inputs and its rulings before they are recorded, so
a review stopped at any point resumes to the same outcome (`resume_review`, `finish_review`).
"""
from __future__ import annotations

import hashlib
import json
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
from ..store.state import Run
from . import validate as validate_phase
from .code import concept_dir

VERDICTS = {"accept", "return"}


def enabled(run: Run) -> bool:
    return bool(run.opts.reviewer_model)


def _ws(s) -> str:
    return " ".join(str(s or "").split())


def _whole(text: str, _limit: int) -> str:
    return text


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


@dataclass
class ReviewOutcome:
    """What a concept review decided, for the loop's one branch per status: `accepted`; `returned`
    (an upheld item, its reasons); `deferred` (an adjudication whose answer stayed invalid, a program
    that did not run, or a reviewer whose answer stayed unusable: `defer_stage` names which, and the
    concept keeps its record and budget; a second consecutive deferral of one judge stage closes it)."""
    status: str
    reasons: list[str] = field(default_factory=list)
    advisories: list[str] = field(default_factory=list)
    defer_stage: str | None = None


#: Fields a saved outcome written by run version 2 carries, which no review sets any more: read and
#: ignored, never another field. Reading such an outcome does not make it reusable: a review reuses a
#: saved outcome only when its saved inputs digest is this review's (`resume_review`).
RETIRED_OUTCOME_FIELDS = ("keys", "questions", "satisfied", "param_notes")


class Deferred(Exception):
    """A judge (the concept adjudication, or a dependency report's) answered invalidly twice (`stage`
    names it), or a review program or the rulings file failed: the review defers instead of deciding."""
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
# The programs a review runs: their failure, and their own registry
# ---------------------------------------------------------------------------------------------
class HarnessFailure(RuntimeError):
    """A review's program (a concept program, the computed-relation check) did not run, or its output
    breaks the protocol."""


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


def _trace_defect(reason: str, kind: str | None, bounded_history: bool = True) -> bool:
    """Whether an unknown reason is missing evidence a trace can supply. A window behind `at` the
    trace does not cover is missing evidence when the history is bounded (a covering trace exists);
    when it is unbounded no finite trace covers it, and for a claim that the rule is undecided it is
    the claim itself."""
    if reason.startswith(("absent_atom:", "sampling_gap:", "identity_gap:")):
        return True
    return reason.startswith("window_truncated:") and (bounded_history or kind != "rule_undecided")


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


# ---------------------------------------------------------------------------------------------
# A duty as an occurrence in the posted law
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
    return at, inherited_rows(run) + own[:at]


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
            _INHERITED_CACHE[key] = jsonl.read_strict(f)
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
    return [r for r in rows if not (r.get("ruling_id") and r["ruling_id"] in children) and r.get("ruling") != "retired"]


def ruling_identity(row: dict) -> tuple | None:
    """What a concept ruling decides: a challenge (`case_id`), its case alone, whichever version of
    the lineage judged it, so a successor's ruling on a carried challenge supersedes its
    predecessor's; or a structural finding (`finding_id`). Any other row has no identity: it
    supersedes nothing by itself."""
    if row.get("case_id") and str(row.get("key", "")).startswith("concept:"):
        return ("concept_case", row["case_id"])
    if row.get("finding_id") and str(row.get("key", "")).startswith("concept:"):
        if row.get("finding_root"):
            return ("concept_finding", row["finding_id"])
        return ("concept_finding_unrooted", row.get("subject"), row["finding_id"])   # written before findings had a root
    return None


def _superseding(row: dict, effective: list[dict], supersedes: str | None) -> dict:
    """The row with the ruling it supersedes: the effective ruling of its identity, else `supersedes`."""
    ident = ruling_identity(row)
    if ident is not None:
        prev = next((r for r in effective if ruling_identity(r) == ident), None)
        row["supersedes"] = prev.get("ruling_id") if prev else supersedes
    return row


def _ruling_content(row: dict) -> dict:
    return {k: v for k, v in row.items() if k not in ("ruling_id", "supersedes")}


def append_ruling(run: Run, row: dict, supersedes: str | None = None, ruling_id: str | None = None) -> dict:
    """Append a row with a fresh `ruling_id`; an earlier ruling of the same identity is superseded by it.
    A row of a new identity may name the ruling it supersedes (`supersedes`: a concept case whose
    recorded content changed, under a new id, supersedes the ruling of the case it came from). A row
    given its `ruling_id` (a review's ruling, `ReviewRulings`) is appended once: when the run's file
    holds that id with the same content, the row recorded under it is returned and nothing is
    written; the same id with other content is a `RulingsError`, never a row dropped. Content is
    every field but the id and the ruling it supersedes, which is decided when the row is recorded."""
    with _RULINGS_LOCK:
        row = dict(row)
        if ruling_id:
            kept = next((r for r in jsonl.read_strict(_rulings_file(run)) if r.get("ruling_id") == ruling_id), None)
            if kept is not None:
                if _ruling_content(kept) != _ruling_content(row):
                    raise RulingsError(f"ruling {ruling_id} is recorded with other content than the ruling given under that id")
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


def precedent_rows(run: Run, key: str, rows: list[dict] | None = None) -> list[dict]:
    """The effective rulings under `key` (a concept's): what was decided before, among `rows` (the
    run's rulings as they stand when None)."""
    return [r for r in effective_rows(_all_rows(run) if rows is None else rows) if r.get("key") == key and r.get("ruling") != "advisory"]


#: How much of an earlier ruling's item and reason the precedents show.
PRECEDENT_ITEM, PRECEDENT_REASON = 400, 600


def precedents_block(rows: list[dict]) -> str:
    """Earlier rulings, most recent first, so a situation decided once is decided alike."""
    if not rows:
        return "### Earlier rulings\n\n(none)\n"
    out = ["### Earlier rulings (most recent first)", ""]
    for r in reversed(rows[-30:]):
        out.append(f"- iteration {r.get('iteration')}, `{r.get('subject')}`: {surface.shorten(str(r.get('item')), PRECEDENT_ITEM)} — "
                   f"**{r.get('ruling')}**: {surface.shorten(str(r.get('reason')), PRECEDENT_REASON)}")
    return "\n".join(out) + "\n"


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
    return [] if old == new else [f"{path} changed from {surface.shorten(json.dumps(old), 60)} to {surface.shorten(json.dumps(new), 60)}"]


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


# ---------------------------------------------------------------------------------------------
# A review's saved record: its inputs, its outcome and its rulings
# ---------------------------------------------------------------------------------------------


def _write_outcome(out_dir: Path, data: dict) -> None:
    jsonl.write_atomic(out_dir / "review_outcome.json", json.dumps(data, ensure_ascii=False, indent=1))


#: The prompt files a concept's review renders.
CONCEPT_REVIEW_PROMPTS = ("review_concept.md", "adjudicate_concept.md", "recheck_concept.md")


def _inputs_digest(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True, ensure_ascii=False, default=str).encode("utf-8")).hexdigest()


#: The options a concept's review and its adjudication use.
CONCEPT_REVIEW_SETTINGS = ("model", "judge_effort", "reviewer_model", "review_effort", "review_checks", "review_submissions")


def review_settings(run: Run, prompts: tuple[str, ...], settings: tuple[str, ...]) -> dict:
    """What a review's outcome depends on besides its record and the rulings: the iteration its
    rulings are recorded under, the prompt files it renders, and the options it uses (`settings`:
    its sessions' models, efforts and limits)."""
    o = run.opts
    return {"iteration": run.iteration, "prompts": {t: _digest((paths.PROMPTS / t).read_text(encoding="utf-8")) for t in prompts},
            "opts": {k: getattr(o, k, None) for k in settings}}


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


def outcome_of(saved: dict, out_dir: Path | None = None) -> ReviewOutcome:
    """A saved outcome (`review_outcome.json` → `outcome`) read back: the fields of `ReviewOutcome`,
    and `RETIRED_OUTCOME_FIELDS` ignored. Any other field, or a missing status, is a format error
    (`DataIntegrityError` on the file in `out_dir`), never dropped."""
    fields = set(ReviewOutcome.__dataclass_fields__)
    if not isinstance(saved, dict) or "status" not in saved or set(saved) - fields - set(RETIRED_OUTCOME_FIELDS):
        bad = sorted(set(saved) - fields - set(RETIRED_OUTCOME_FIELDS)) if isinstance(saved, dict) else []
        raise jsonl.DataIntegrityError((out_dir or Path(".")) / "review_outcome.json", None,
                                       f"the saved outcome is not one a review writes ({', '.join(bad) or 'no status'})")
    return ReviewOutcome(**{k: v for k, v in saved.items() if k in fields})


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
    unrunnable = [f"divergence {k}: cannot be run as recorded — " + surface.shorten("; ".join(bad[:3]), 400) for k, bad in defects.items() if bad]
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
                    raise HarnessFailure(f"an unparseable LINT line: {surface.shorten(line, 200)}")
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
        body = ({"compliant": "in the interval", "violated": "outside the interval"} if quantity else
                {"compliant": "holds", "violated": "fails"}).get(tag, tag)
        lines = {f: divergence_lines(k, d, quantity, body, observed, f" [{why}]" if tag == "unknown" and why else "", cut) for f, cut in LINE_FORMS.items()}
        reason = None
        if tag in ("decode", "missing", "unfilled", "at_missing"):
            reason = "formals" if tag == "unfilled" else "admission"
            errors.append(f"divergence {k}: " + {"decode": f"the trace does not decode: {surface.shorten(why, 200)}", "missing": "the harness printed no verdict",
                                                  "unfilled": "the instance leaves a formal unfilled",
                                                  "at_missing": "`at` names no observation of the trace"}[tag])
        elif lint.get(k):
            reason = "admission"
            incomplete.append(f"divergence {k}: trace check: " + "; ".join(lint[k][:8]))
        elif tag == claimed:
            unconfirmed.append(lines["shown"][0] + CONCEPT_AGREES)
        elif tag == "unknown" and why and all(_trace_defect(r, "rule_undecided" if d.get("kind") == "undecided" else None) for r in why.split(",")):
            reason = "history"
            incomplete.append(f"divergence {k}: {surface.shorten(_ws(d.get('situation')), 120)} — the body's verdict on the trace is unknown only because the "
                              "trace is incomplete: " + "; ".join(sorted({_trace_remedy(r) for r in why.split(",")})))
        else:
            confirmed.append({**{f: x[1] for f, x in lines.items()}, "div": d, "rule": body + (f" ({why})" if tag == "unknown" and why else ""),
                              "key": f"{d.get('kind')}", "verdict": tag, "value": observed if quantity else None,
                              "facts": executed_facts(d, read_paths, occd.get(k)),
                              **({"relations_stripped": stripped[k]} if k in stripped else {})})
        if runs is not None:
            runs[k] = {"tag": tag, "why": why, "value": value.get(k), "facts": executed_facts(d, read_paths, occd.get(k)), "reason": reason}
    return confirmed, unconfirmed, errors, incomplete + unrunnable


#: The forms of an item's line: `line`, whole, as its ruling keeps it; `shown`, as notes and
#: messages show it, its texts cut at a word boundary.
LINE_FORMS = {"line": _whole, "shown": surface.shorten}


def _shown(item: dict) -> str:
    """An item's line as notes and messages show it (`LINE_FORMS`)."""
    return item.get("shown") or item["line"]


def divergence_lines(k: int, d: dict, quantity: bool, body: str, observed, mark: str, cut) -> tuple[str, str]:
    """A divergence as run: (its head, its line), the situation and the contract's words each passed
    through `cut` (`LINE_FORMS`). `body` is the body's verdict or, for a quantity, where its value
    lies, `observed` a quantity's value, `mark` the unknown reasons the line carries."""
    sit = cut(_ws(d.get("situation")), 160)
    if quantity:
        lo, hi = d["contract_value"]["lo"], d["contract_value"]["hi"]
        head = (f"divergence {k} ({d.get('kind')}) at t={d.get('at')} ms: {sit} — contract: from {lo[0]} {lo[1]} "
                f"to {hi[0]} {hi[1]}; the body's value there: {observed} ({body})")
    else:
        head = f"divergence {k} ({d.get('kind')}) at t={d.get('at')} ms: {sit} — contract: {d.get('contract_verdict')}, body: {body}"
    return head, head + mark + f'; contract: "{cut(_ws(d.get("contract_words")), 120)}"'


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
                                                      "items": "### Items\n\n" + listing + "\n", "precedents": precedents_block(precedent_rows(run, key, known))})
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
        raise Deferred("concept_adjudication", f"the concept adjudication stayed invalid: {surface.shorten('; '.join(errs), 300)}")
    rows = {r.get("item"): r for r in answer.get("rulings", []) if isinstance(r, dict)}
    out = [(i, rows[k]["ruling"], f"{_ws(rows[k].get('reason'))} — \"{_ws(rows[k].get('quote'))}\"") for k, i in enumerate(items, 1)]
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
        _ruled(run, rulings, {"key": key, "subject": rec.id, "iteration": run.iteration, "item": _ws(i.get("line")),
                              "ruling": ruling, "reason": _ws(why), **replay}, (i.get("lineage_of") or {}).get("ruling_id"))
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
        return {"status": status, "messages": errors + incomplete + unconfirmed + [_shown(c) for c in confirmed]}

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
        raise Deferred("concept_adjudication", f"the concept recheck stayed invalid: {surface.shorten('; '.join(errs), 300)}")
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
    reason = _ws(f"rechecked under the current contract: {said} — {_ws(answer.get('reason'))} — \"{_ws(answer.get('quote'))}\"; "
                 f"the body: {body}")
    if claim is not None and not body_within(rec, claim, obs):
        content = renewed_content(rec, r, d, claim, answer["quote"])
        head = (f"divergence (renewed from {cid[:12]}) at t={d.get('at')} ms — contract: {said}; "
                + (f"the body's value there: {body}" if quantity else f"body: {body}"))
        out.items.append({**{f: head + f'; contract: "{cut(_ws(answer["quote"]), 120)}"' for f, cut in LINE_FORMS.items()}, "div": content, "rule": body,
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
                                f"the body: {body}")})
        written = _ruled(run, rulings, row, r.get("ruling_id"))
    else:
        written = _ruled(run, rulings, row)
    if claim is None:
        by = answer.get("undecided_by", "unstated")
        out.carry.append({"case_id": written["case_id"], "row": written, "reason": "undecided", "undecided_by": by,
                          "why": f"{UNDECIDED}{_undecided_why(by)}: {surface.shorten(_ws(answer.get('reason')), 300)}"})
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
                              "why": "its record fails today's schema: " + surface.shorten("; ".join(bad), 300)})
            continue
        if undecided_under(r, current):                   # the contract decides nothing here: carried, never compared
            by = ((r.get("recheck") or {}).get("answer") or {}).get("undecided_by", "unstated")
            out.carry.append({"case_id": r.get("case_id"), "row": r, "reason": "undecided", "undecided_by": by,
                              "why": f"{UNDECIDED}{_undecided_why(by)}: {surface.shorten(_ws((r.get('recheck') or {}).get('quote')), 200)}"})
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
                              "why": f"it cannot be run on this body: {surface.shorten(line, 300)}"})
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
            out.notes.append(f"an upheld challenge is met by this body; it stays an obligation: {surface.shorten(meets[k], 240)}")
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
        out.items.append({**{f: _ws(r.get("item")) if m else f"an earlier upheld finding, as recorded: {cut(_ws(r.get('item')), 300)}"
                             for f, cut in LINE_FORMS.items()},
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
        out += [f"#### Challenge `{c.get('case_id')}`", "", surface.shorten(_ws(r.get("item")), 400), "",
                f"Why it cannot be judged as recorded ({c.get('reason', 'formals')}): {c.get('why')}", "",
                "Its record: ```json " + surface.shorten(json.dumps({k: r.get(k) for k in CONCEPT_CASE_FIELDS if r.get(k) is not None}, ensure_ascii=False), 6000) + "```", ""]
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
        return finish_review(run, out, rulings, {}, DependencyReport("upheld" if ruling == "upheld" else "dismissed", cid, [why], _shown(item),
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
    on the concept as what it computes as built. It reads the rulings as they
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
        return outcome_of(decided, out_dir)
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
    still = [f"{_shown(i)} — upheld again: {w}" for i, r, w in replayed if r == "upheld"]
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
    upheld = [f"{_shown(i)} — upheld: {w}" for i, r, w in ruled if r == "upheld"]
    notes = replay_notes + [str(x) for x in answer.get("advisories", [])] + [f"dismissed: {_shown(i)} — {w}" for i, r, w in ruled if r == "dismissed"]
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
                                                             + surface.shorten(" | ".join(unusable), 900)], advisories=notes, defer_stage="reviewer"))
    if unextended:
        why = {c["case_id"]: c["why"] for c in rep.carry}
        return done(data, ReviewOutcome("deferred", reasons=["challenges carried over but not extended: "
                                                             + surface.shorten(" | ".join(f"{cid[:12]}: {why.get(cid, '')}" for cid in unextended), 900)],
                                        advisories=notes, defer_stage="evidence"))
    return done(data, ReviewOutcome("accepted", advisories=notes + [f"refuted by execution: {x}" for x in unconfirmed]))
