"""The behaviour-property review of a run whose acceptance policy says `review: required`: every
law's rules are checked against properties drawn from the law alone, before the law is
label-checked, and a law is accepted only when its review and its label route both allow it.

Reason: the label check judges a rule only on the recordings the data has; the review checks the
rule against what the law's words decide on every scene inside a declared bound, so a rule that fits
its recordings and misreads its law is not accepted.

Identities. Four, each a digest:
- `property_spec_key`: what a property set is asked on (the law, its definitions, the vocabulary, the
  reviewer's prompts, models and limits, and the adoption gate's digest, `review_schema.gate_digest`:
  its schemas, limits, templates, property language and source; never a rule, a reading, a label or a
  ruling). Two asks are one logical request only when it is equal; it is never the input of a
  certificate.
- `property_set_id`: an answer actually adopted: its spec key, every call's request and response
  digests, every field of the stored set (adopted records, each candidate's adoption, clauses, the
  screen's assessments, uncovered obligations and situations, holes). A set is the adoption gate's
  output (`review_schema.adopt_answer`) on the reviewer's raw answers; it is stored once,
  content-addressed, under `review/<law>/sets/<set_id>.json`, and read only while its content still
  gives its id. One input key may have several sets; none is chosen by being the last.
- `active_property_set_id`: the set a law's check uses (`review_states[law]["active_set"]`: the set,
  the set it supersedes, its version, and the operator's withdrawals in order, each naming the
  withdrawn property's identity and the digest of the decision). A new set or a withdrawal gives a
  new id; withdrawals carry over to a new set and remove only properties of the same identity.
- `check_key`: the active set's id, the law's roots, the dependency context of every node of its plan
  closure (the label key's contexts: records, files, concepts, reading values), the library of a
  rule-set operator, and the check's implementation digest.

The check. The roots of a law are the nodes of its plan that are not permissions; the closure (every
node they reach, permissions included) is loaded and keyed, never joined. A scene's law verdict joins
the roots' verdicts only (`law_verdict`), in the label check's order: violated, unknown, compliant,
not_applicable, no root verdict being unknown. A property's cell is judged (`judge`): `pass` when its
antecedent was shown nonempty and no scene inside the bound gives a law verdict other than the
property's expectation or an unknown one; `finding` for a Core-confirmed scene whose verdict
contradicts it; `undetermined` for an unknown verdict, a scene the replay did not confirm, an
antecedent never shown satisfiable, a search that did not finish or a synthesis that failed;
`premises_empty` for an unsatisfiable antecedent; `hole` for a property the check cannot encode
(`outside_fragment`, `multi_binder_not_supported`); `failed` for a check the infrastructure did not run.
None of `undetermined`, `premises_empty`, `hole` or `failed` is a pass.

Coverage. A clause is covered when an adopted `must_detect` property and an adopted `must_not_flag`
property of it both pass, a category being excused where the drafter gave the clause a reason for
having none and the screen did not list that clause and category as uncovered. The screen's uncovered
obligations with no clause are clauses of their own, uncovered. The holes: every uncovered clause,
every adopted property outside the fragment, and every candidate the adoption gate refused, marked a
gap or refused at a bound (`GATE_HOLES`).

Disposition, the first that holds: `failed` (the set failed, or a cell failed); for a set that adopted
no property, `no_properties` (asked again while asks remain) and on the last ask the cause the
screen's reason codes give (`zero_adopted`: the exemption `not_applicable_no_checkable_behaviour`,
a `dispute`, or `operator`); `finding`; `operator` (an undetermined or premises-empty cell);
`reviewed` (no hole, and at least one unit passed); `review_unverified`
(holes only, at least one adopted property, and the run's coverage policy fixed at its start is
`bounded`); else `operator`. A permission-only law is not checked: its exemption (`exempt_law`) is
`not_applicable_permission`, keyed on its closure, and waits for no reader. A law without checkable
behaviour has two layers (`no_behaviour_row`): a `basis` row classifying the answers, keyed on the
words, the definitions, the vocabulary, the property spec, the answers and the classifier, reused
while that key holds; and a current `exempt` credential naming it, keyed on the rules like a check
and made again, at no cost and with no unit passed, whenever they change. It is never given for a
review's own limit or failure (`exemption_refusal`).

Certificates. `review_evidence.jsonl` in the run's directory holds rows of `schema` `bp_review/2`
and `source` `behaviour_property`, of the kinds `property_set`, `check`, `basis` and `exempt`; no other row is
read, and nothing else reads the file (the concept review's `rulings.jsonl` is never review evidence).
A law's committed snapshot points at its last row (`review_states[law]["last"]`) and, when that row's
disposition is `reviewed`, `review_unverified` or `not_applicable_permission`, at it as its certificate
(`review_states[law]["certificate"]`: row digest, check key, disposition, holes, where). A row counts
only through those pointers, and only while its key equals the key computed now: a row appended and
never committed, or copied out of a candidate that was rolled back, is nothing. A candidate stages its
rows and pointers in its own copies, published with its commit in one journal, or never.

Status. `own_status` is a law's own certificate; `status` adds every law its nodes reach: each needs a
current certificate of its own (an exemption counts), a reached `review_unverified` is carried as a
condition (`inherited_from`), never counted strictly reviewed, and a reached exemption carries no
condition and is listed (`exemption_dependencies`).

Limits (persistent in `review_states`, across restarts, stage transitions and new findings):
`repairs` (review repairs rolled back, `repair_attempts`), `property_failures` (property sets that
failed, `property_attempts` asks in all), `infra_failures` (a call refused before it was sent, or a
check that did not run, `infra_attempts`). A property call is committed `pending_call` before it is
made; a call whose outcome is unknown is never sent again: the law waits for the operator and no
transition is made while it stands. A budget pause is raised at the reservation, before anything is
sent, and pauses the run. An answer from another model or channel stops every send of the run (a stop
row of the usage file, `budget`) until the operator acknowledges that stop (`acknowledge`); the call
stays settled and unusable.

The reviewer is an implementation registered by name (`register`), fixed when the run first enters a
review stage and kept for the run's life. The first stage's policy (`review_config`) fixes the
coverage policy and the limits and no reviewer, so a run generates before any reviewer is registered;
the transition into the first review stage names a registered implementation and writes its name and
implementation digest into that stage's policy (`fix_reviewer`). A generation launch that names a
reviewer is refused, and so is a later review entry, a launch or a check whose reviewer or registered
implementation differs from the one fixed. The implementation digest's `properties`
part binds the adoption gate's digest beside the reviewer's own (`impl_of`), so a change to the
schemas, the limits, the templates, the property language or the gate makes every row stale and
the run's reviewer another implementation than it fixed.

Prototype defaults the operator has not decided yet, each named where it is used: the coverage
policy's default (`strict`), the clause-coverage rule above, the limits' defaults (2, 2, 3), an
unknown verdict under `must_detect` judged undetermined, every cell requiring a Core-confirmed
antecedent, the permission law accepted in the review stage, and the review repair run in the labels
stage with the label hook."""
from __future__ import annotations

import hashlib
import json
import re
import time
from pathlib import Path
from typing import Callable

from ..store import jsonl

SCHEMA = "bp_review/2"
SOURCE = "behaviour_property"
EVIDENCE_FILE = "review_evidence.jsonl"
REVIEW_DIR = "review"
NO_BEHAVIOUR = "not_applicable_no_checkable_behaviour"
CERTIFIED = ("reviewed", "review_unverified", "not_applicable_permission", NO_BEHAVIOUR)
DISPOSITIONS = ("failed", "no_properties", "finding", "operator", "dispute", "reviewed", "review_unverified",
                "not_applicable_permission", NO_BEHAVIOUR)
#: PROVISIONAL (operator 2026-11-18): why a final property set adopted nothing, as the screen's
#: reason codes give it: a reviewer-side problem waits for the operator; no checkable behaviour,
#: explicitly confirmed by the screen, is an exemption counted apart and never strictly reviewed; a
#: disagreement between drafter and screen on the meaning is a dispute for the operator.
ZERO_REASONS = ("reviewer_problem", "no_checkable_behaviour", "meaning_disagreement")
COVERAGE_POLICIES = ("strict", "bounded")
#: PROVISIONAL (R2b open): the coverage policy a new run fixes when its options give none.
DEFAULT_COVERAGE = "strict"
#: PROVISIONAL (R6 open): the limits' defaults (repairs, property asks, infrastructure failures).
DEFAULT_LIMITS = {"repair_attempts": 2, "property_attempts": 2, "infra_attempts": 3}
#: The order a law's verdict joins its roots' verdicts in (the label check's): the first that occurs wins.
JOIN = ("violated", "unknown", "compliant", "not_applicable")
CATEGORIES = {"must_detect": ("violated",), "must_not_flag": ("compliant", "not_applicable")}
HOLE_STATUSES = ("outside_fragment", "multi_binder_not_supported")
#: A run's review configuration in a stage's policy, with the test of a legal value: the first stage fixes the
#: coverage and the limits with no reviewer (None), the first review entry the reviewer, its digest and `test_only`.
CONFIG_FIELDS = {"reviewer": lambda v: v is None or (isinstance(v, str) and bool(v)),
                 "implementation": lambda v: v is None or (isinstance(v, dict) and set(v) == {"properties", "check"}),
                 "coverage": lambda v: v in COVERAGE_POLICIES,
                 "test_only": lambda v: isinstance(v, bool),
                 "repair_attempts": lambda v: isinstance(v, int) and not isinstance(v, bool) and v >= 0,
                 "property_attempts": lambda v: isinstance(v, int) and not isinstance(v, bool) and v >= 1,
                 "infra_attempts": lambda v: isinstance(v, int) and not isinstance(v, bool) and v >= 1}

#: The reviewer implementations this harness knows, by name: a factory giving an object with
#: `digest() -> {"properties", "check"}`, `spec_key(run, law) -> str`, `properties(run, law, workdir)
#: -> dict` (`state` ok|failed, `records`, `clauses`, `uncovered`, `calls`, `reasons`) and
#: `check(view, reading, law, roots, closure, records) -> list[dict]` (one cell per record). The
#: harness registers none itself.
IMPLEMENTATIONS: dict[str, Callable[[], object]] = {}


class ReviewerUnavailable(RuntimeError):
    """The reviewer or the check did not run. `executed` is False when nothing was sent (another
    attempt may be made), None when that is not known (never sent again: the operator reconciles it)."""

    def __init__(self, msg: str, executed: bool | None = False):
        super().__init__(msg)
        self.executed = executed


class WrongChannel(ReviewerUnavailable):
    """An answer from another model (`wrong_model`) or channel (`wrong_channel`) than the run fixed:
    executed and settled, never adopted and never sent again; every real send of the run stops,
    persistently, until the operator acknowledges the stop. `stop` is the stop row the reviewer wrote
    with the call's settlement (`budget.Budget.settle`), or None when the harness writes it."""

    def __init__(self, msg: str, reason: str = "wrong_model", stop: dict | None = None):
        super().__init__(msg, executed=True)
        self.reason = reason if reason in ("wrong_model", "wrong_channel") else "wrong_model"
        self.stop = stop


class Dispute(RuntimeError):
    """A review repair's answer that the finding misreads the law (`property`), rests on a parameter
    (`parameter`), or contradicts a label (`label_conflict`: `cites` names the finding's property and the
    label check's recording whose required verdicts are opposite): the operator decides it."""

    def __init__(self, msg: str, kind: str = "property", cites: dict | None = None):
        super().__init__(msg)
        self.kind = kind
        self.cites = cites or {}


def register(name: str, factory: Callable[[], object]) -> None:
    IMPLEMENTATIONS[name] = factory


def _sha(x) -> str:
    return hashlib.sha256(json.dumps(x, sort_keys=True, ensure_ascii=False, default=str).encode()).hexdigest()


def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S")


# -- the run's policy --------------------------------------------------------------------------------

def impl_of(reviewer) -> dict:
    """A reviewer's implementation digest as the harness keys it: the `properties` part binds the
    reviewer's own and the adoption gate's (`review_schema.gate_digest`), which decides what of its
    answers is adopted; the `check` part is the reviewer's."""
    from .review_schema import gate_digest
    d = reviewer.digest()
    return {"properties": _sha([str(d["properties"]), gate_digest()])[:32], "check": str(d["check"])}


def spec_of(reviewer, run, law: str) -> str:
    """A law's `property_spec_key`: the reviewer's spec key with the adoption gate's digest."""
    from .review_schema import gate_digest
    return _sha([reviewer.spec_key(run, law), gate_digest()])[:32]


def implementation_digest(name: str | None) -> dict | None:
    """The registered implementation's digest (`impl_of`), or None when `name` is not registered."""
    if not name or name not in IMPLEMENTATIONS:
        return None
    return impl_of(IMPLEMENTATIONS[name]())


def config_of(opts) -> dict:
    """The review configuration a new run fixes in its first stage from its options: the coverage
    policy and the limits. It fixes no reviewer: the run's first review entry does (`fix_reviewer`)."""
    get = (lambda k, d=None: opts.get(k, d)) if isinstance(opts, dict) else (lambda k, d=None: getattr(opts, k, d))
    return {"reviewer": None, "implementation": None, "coverage": get("review_coverage", DEFAULT_COVERAGE), "test_only": False,
            **{k: get(f"review_{k}", v) for k, v in DEFAULT_LIMITS.items()}}


def fix_reviewer(cfg: dict, name: str) -> dict:
    """The review configuration `cfg` with the reviewer `name` fixed: its name, the registered
    implementation's digest now and whether it is a test stand-in; the coverage and limits kept."""
    return {**cfg, "reviewer": name, "implementation": implementation_digest(name), "test_only": is_test_only(name)}


def entry_refusal(cfg: dict, name: str | None) -> str | None:
    """Why a review stage may not be entered, naming the reviewer `name` (None: none named), under the
    review configuration `cfg` of the stage it leaves, or None. While the run's reviewer is not fixed,
    the entry fixes it and must name a registered implementation; once fixed, a name given must be it,
    and it must be registered as it was fixed (`reviewer_refusal_of`)."""
    fixed = cfg.get("reviewer")
    if fixed is None:
        if not name:
            return ("the run's reviewer is fixed when it first enters its review stage, and none is named: give "
                    "--behaviour_reviewer <a registered implementation>")
        if name not in IMPLEMENTATIONS:
            return f"the reviewer `{name}` is not registered in this harness"
        return None
    if name and name != fixed:
        return f"a run keeps its reviewer once its review stage fixed it (`{fixed}`, named `{name}`); start a new run id"
    return reviewer_refusal_of(cfg)


def is_test_only(name: str | None) -> bool:
    """Whether a registered implementation is a test stand-in (`test_only`): its rows carry the test
    credential, which no production run accepts, and a run that names it accepts nothing else."""
    return bool(name and name in IMPLEMENTATIONS and getattr(IMPLEMENTATIONS[name](), "test_only", False))


def credential(cfg: dict) -> str:
    return "test" if cfg.get("test_only") else "production"


def config_defects(cfg) -> list[str]:
    if not isinstance(cfg, dict):
        return ["`review_config` is not an object"]
    return [f"`review_config.{k}` is missing" if k not in cfg else f"`review_config.{k}` is {cfg[k]!r}, not a legal value"
            for k, legal in CONFIG_FIELDS.items() if k not in cfg or not legal(cfg[k])]


def config_refusal(fixed: dict, opts) -> str | None:
    """Why a launch's options differ from the review configuration its run fixed (the implementation
    digest is compared with the registered one where the reviewer is used, `reviewer_refusal`). The
    reviewer is never fixed by a launch: while the run's first review entry has not fixed it, a launch
    that names one is refused; once fixed, a launch names it or none. The coverage policy is fixed for
    the run's life; a limit (`DEFAULT_LIMITS`) is a run limit, which an explicit launch option may raise,
    never below the fixed value (`config`)."""
    now = config_of(opts)
    get = (lambda k: opts.get(k)) if isinstance(opts, dict) else (lambda k: getattr(opts, k, None))
    named = get("behaviour_reviewer")
    if named and fixed.get("reviewer") is None:
        return (f"the run's reviewer is fixed when the run enters its review stage (stage enter --kind review "
                f"--behaviour_reviewer {named}), never by a launch: give no --behaviour_reviewer")
    if named and named != fixed.get("reviewer"):
        return f"a run keeps its reviewer once its review stage fixed it ({fixed.get('reviewer')!r} → {named!r}); start a new run id"
    if fixed.get("coverage") != now.get("coverage"):
        return f"the run's review configuration is fixed for its life (coverage: {fixed.get('coverage')!r} → {now.get('coverage')!r}); start a new run id"
    lowered = sorted(k for k in DEFAULT_LIMITS if isinstance(now.get(k), int) and isinstance(fixed.get(k), int) and now[k] < fixed[k])
    if lowered:
        return ("a review limit of the run is raised, never lowered below the one its first stage fixed (" + ", ".join(f"review_{k}: {fixed[k]} → {now[k]}" for k in lowered)
                + ")")
    return None


def _stage(run) -> dict | None:
    from ..store import stages
    d = getattr(run, "dir", None)
    try:
        return stages.active_stage(d) if d is not None else None
    except (OSError, jsonl.DataIntegrityError):
        return None


def stage_required(stage: dict | None) -> bool:
    return bool(stage) and (stage.get("acceptance_policy") or {}).get("review") == "required"


def required(run) -> bool:
    """Whether the run's active stage requires the review for acceptance."""
    return stage_required(_stage(run))


def config(run) -> dict:
    """The run's review configuration as its active stage holds it (the coverage and limits its first
    stage fixed, the reviewer its first review entry fixed, or None before), each limit (`DEFAULT_LIMITS`) at
    the value an operator's launch last set for it, as the run's record of limit changes holds it
    (`loop.record_limit_changes`), never below the fixed one. A record that cannot be read raises
    nothing."""
    from ..loop import LIMIT_CHANGES_FILE
    cfg = dict(((_stage(run) or {}).get("acceptance_policy") or {}).get("review_config") or {})
    d = getattr(run, "dir", None)
    try:
        rows = jsonl.read_strict(Path(d) / LIMIT_CHANGES_FILE) if d is not None else []
    except jsonl.DataIntegrityError:
        rows = []
    last = {r.get("option"): r.get("to") for r in rows if isinstance(r, dict)}
    for k in DEFAULT_LIMITS:
        v = last.get(f"review_{k}")
        if isinstance(cfg.get(k), int) and isinstance(v, int) and not isinstance(v, bool) and v > cfg[k]:
            cfg[k] = v
    return cfg


def reviewer_refusal_of(cfg: dict) -> str | None:
    """Why the reviewer a review configuration fixed cannot be used now: none named, not registered,
    or another implementation than the one fixed."""
    name = cfg.get("reviewer")
    if not name:
        return "the run's reviewer is not fixed yet: it is fixed when the run first enters its review stage"
    if name not in IMPLEMENTATIONS:
        return f"the run's reviewer `{name}` is not registered in this harness"
    if implementation_digest(name) != cfg.get("implementation"):
        return f"the registered reviewer `{name}` is another implementation than the run fixed: a run keeps its reviewer for its life"
    if is_test_only(name) != bool(cfg.get("test_only")):
        return f"the reviewer `{name}` is {'a test stand-in' if is_test_only(name) else 'a production reviewer'}, and the run fixed the other"
    return None


def reviewer_refusal(run) -> str | None:
    return reviewer_refusal_of(config(run))


def reviewer_for(run):
    why = reviewer_refusal(run)
    if why:
        raise ReviewerUnavailable(why, executed=False)
    return IMPLEMENTATIONS[config(run)["reviewer"]]()


def usage_file(run_or_dir) -> Path:
    """The run's usage file, which holds the send gate of every role (`budget`)."""
    return Path(run_or_dir if isinstance(run_or_dir, (str, Path)) else run_or_dir.dir) / "usage.jsonl"


def run_stops(run_or_dir) -> list[dict]:
    """The run's stops no acknowledgement confirms, from its usage file."""
    from ..store import budget
    return budget.open_stops(jsonl.read_strict(usage_file(run_or_dir)))


def stop_run(run, law: str, why: str, reason: str = "wrong_model", **fields) -> dict:
    """Stop every real send of the run (a stop row in its usage file); returns the row."""
    from ..store import budget
    return budget.write_stop(usage_file(run), reason, why, law=law, **fields)


# -- property sets -----------------------------------------------------------------------------------

def set_id(pset: dict) -> str:
    """The `property_set_id` of an answer actually adopted (not of what it was asked on): every field
    of the stored set (its generation, calls, adopted records, every candidate's adoption decision
    and ratings, clauses, the screen's assessments, uncovered obligations and situations, holes and
    the zero-adoption classification), so no field of it can change while its id still holds."""
    return _sha({k: v for k, v in pset.items() if k != "set_id"})[:32]


def set_path(run, law: str, sid: str) -> Path:
    return run.dir / REVIEW_DIR / law / "sets" / f"{sid}.json"


def save_set(run, law: str, pset: dict) -> str:
    sid = set_id(pset)
    f = set_path(run, law, sid)
    if not f.exists():
        jsonl.write_atomic(f, json.dumps({**pset, "set_id": sid}, ensure_ascii=False, indent=1))
    return sid


def load_set(run, law: str, sid: str | None) -> dict | None:
    """A stored set whose content still gives its id, else None (missing, damaged or forged)."""
    if not sid:
        return None
    try:
        d = jsonl.read_json(set_path(run, law, sid), None)
    except (OSError, jsonl.DataIntegrityError, ValueError):
        return None
    if not isinstance(d, dict) or d.get("set_id") != sid or set_id(d) != sid:
        return None
    return d


def active_id(active: dict | None) -> str | None:
    """The `active_property_set_id` of a law's active set: its set, its version and its withdrawals in order."""
    if not active or not active.get("set_id"):
        return None
    return _sha({"set": active["set_id"], "version": int(active.get("version", 1)),
                 "withdrawals": [[w.get("identity"), w.get("decision_sha"), w.get("date")] for w in active.get("withdrawals", [])]})[:32]


def new_active(set_id_: str, prev: dict | None) -> dict:
    """The active set a newly adopted or re-activated set gives: the operator's withdrawals carry over
    (they name property identities, never display ids, so they remove only properties of the same
    identity from the new set), and the version counts up."""
    prev = prev or {}
    return {"set_id": set_id_, "supersedes": prev.get("set_id"), "version": int(prev.get("version", 0)) + 1,
            "withdrawals": list(prev.get("withdrawals", []))}


def withdrawn_identities(active: dict | None) -> frozenset:
    return frozenset(w.get("identity") for w in (active or {}).get("withdrawals", []) if w.get("identity"))


def active_records(pset: dict, active: dict) -> list[dict]:
    """The set's adopted records less every one whose identity the operator withdrew. The identity is
    recomputed from the record's content (binders with class and subject, antecedent, category,
    expected), never read from a stored field or the display id: a withdrawn must_detect property
    never takes away a must_not_flag property with the same antecedent, nor one with another binder
    class."""
    from .review_schema import identity
    gone = withdrawn_identities(active)
    return [r for r in pset.get("records", []) if identity(r) not in gone]


def withdraw(run, law: str, prop: str, decision) -> str:
    """The operator withdraws one property of a law's active set (`decision`: the ruling's record,
    whose digest the withdrawal binds): the property is named by its display id in the active set and
    withdrawn by its identity, so every record of that identity leaves the set and no other does.
    The active set gets a new id, so the certificate keyed on the old one stops counting, and the next
    check computes the disposition from the properties left. A property whose identity is already
    withdrawn (the same decision submitted again, or another display id of the same identity)
    changes nothing. Returns the new active id."""
    from .review_schema import antecedent_sha, identity, sha
    st = run.review_states.setdefault(law, {})
    act = st.get("active_set")
    if not act:
        raise ValueError(f"`{law}` has no active property set")
    pset = load_set(run, law, act.get("set_id"))
    if pset is None:
        raise ValueError(f"`{law}`: its active property set is missing or damaged")
    named = [r for r in pset.get("records", []) if r.get("id") == prop]
    if not named:
        raise ValueError(f"`{law}`: its active property set has no property `{prop}`")
    ident, dsha = identity(named[0]), sha(decision)
    if any(w.get("identity") == ident for w in act.get("withdrawals", [])):
        return active_id(act)
    act["withdrawals"] = list(act.get("withdrawals", [])) + [{"identity": ident, "antecedent_sha": antecedent_sha(named[0]),
                                                              "property": prop, "decision_sha": dsha, "date": _now()}]
    return active_id(act)


# -- the check and its judgment ------------------------------------------------------------------------

def law_verdict(verdicts: dict, roots: list[str]) -> str:
    """A scene's law verdict: the join of its roots' verdicts only; no root verdict is unknown."""
    seen = {verdicts[r] for r in roots if r in verdicts}
    return next((v for v in JOIN if v in seen), "unknown")


def judge(rec: dict, cell: dict | None, roots: list[str]) -> tuple[str, str]:
    """One property on its cell: (`pass` | `finding` | `undetermined` | `premises_empty` | `hole` |
    `failed`, why). PROVISIONAL (R19, R20 open): an unknown verdict is undetermined under either
    category, and every cell needs a Core-confirmed antecedent."""
    if cell is None:
        return "undetermined", "the check returned no cell for it"
    s = cell.get("status")
    if s in HOLE_STATUSES:
        return "hole", s
    if s == "failed":
        return "failed", cell.get("detail", "the check did not run")
    if s != "searched":
        return "undetermined", f"the search did not decide it ({s})"
    if cell.get("antecedent") == "empty":
        return "premises_empty", "its antecedent is unsatisfiable under the premises: nothing was checked"
    if cell.get("antecedent") != "nonempty":
        return "undetermined", "its antecedent was not shown satisfiable by a Core-confirmed scene"
    if cell.get("unknown_possible"):
        return "undetermined", "a scene of its antecedent leaves the law's verdict unknown: unknown is not a pass"
    want = CATEGORIES.get(rec.get("category"))
    if want is None:
        return "undetermined", f"its category {rec.get('category')!r} is not one the check judges"
    found, open_ = [], []
    for w in cell.get("witnesses", []):
        v = law_verdict(w.get("verdicts") or {}, roots)
        if v == "unknown":
            open_.append(f"scene {w.get('scene')}: the law's verdict is unknown")
        elif v not in want:
            if w.get("replay") == "confirmed":
                found.append(f"scene {w.get('scene')}: the law gives {v}, the property expects {'/'.join(want)}")
            else:
                open_.append(f"scene {w.get('scene')}: a disagreement Core did not confirm ({w.get('replay')})")
        elif w.get("replay") not in (None, "confirmed"):
            open_.append(f"scene {w.get('scene')}: replay {w.get('replay')}")
    if found:
        return "finding", "; ".join(found[:3])
    if open_:
        return "undetermined", "; ".join(open_[:3])
    return "pass", "no counterexample within the declared bound"


def clause_list(pset: dict) -> list[dict]:
    """The clauses a set covers: the drafter's, then each uncovered obligation the screen found with
    no clause, as a clause of its own."""
    out = [c if isinstance(c, dict) else {"id": c} for c in pset.get("clauses", [])]
    ids = {c["id"] for c in out}
    for i, u in enumerate(pset.get("uncovered", [])):
        if not u.get("clause") or u.get("clause") not in ids:
            out.append({"id": u.get("clause") or f"U{i + 1}", "quote": u.get("quote", ""), "from_screen": True})
    return out


#: The holes the adoption gate records (a set's `holes`) that the clause coverage below does not
#: derive itself: a candidate refused, a gap of the words, a count or size bound. The gate's other
#: kinds (an unconfirmed reason, a missed obligation, an uncovered situation) are the clauses the
#: coverage finds uncovered.
GATE_HOLES = ("rejected", "expression_gap", "count_or_size_refused")


def coverage(pset: dict, records: list[dict], judged: dict) -> dict:
    """Which clauses are covered, and the holes (PROVISIONAL, R2a: a clause needs a passing property
    of each category; a category is excused only where the drafter gave a reason and the screen
    confirmed it explicitly for that clause and category, never by not objecting). The holes the
    adoption gate recorded of the kinds `GATE_HOLES` are holes of the check as well, so they reach
    the row and its certificate, not the set file alone."""
    confirmed = {(x.get("clause"), x.get("category")) for x in pset.get("screen_assessments", [])
                 if x.get("agrees_no_property") is True and x.get("basis")}
    holes, covered = [], {}
    for c in clause_list(pset):
        need = []
        for cat in CATEGORIES:
            excused = any(n.get("category") == cat for n in c.get("no_property", [])) and (c["id"], cat) in confirmed \
                and not c.get("from_screen")
            if excused:
                continue
            ok = [r["id"] for r in records if r.get("clause") == c["id"] and r.get("category") == cat and judged[r["id"]][0] == "pass"]
            covered.setdefault(c["id"], {})[cat] = ok
            if not ok:
                need.append(cat)
        if need:
            holes.append({"kind": "uncovered_clause", "clause": c["id"], "categories": need})
    holes += [{"kind": judged[r["id"]][1], "property": r["id"]} for r in records if judged[r["id"]][0] == "hole"]
    holes += [h for h in pset.get("holes") or [] if isinstance(h, dict) and h.get("kind") in GATE_HOLES]
    return {"clauses": [c["id"] for c in clause_list(pset)], "covered": covered, "holes": holes, "adopted": len(records),
            "executed": sum(1 for r in records if judged[r["id"]][0] != "hole"),
            "passed": sum(1 for r in records if judged[r["id"]][0] == "pass")}


def zero_adopted(pset: dict, final: bool) -> tuple[str, str]:
    """The disposition of a set with no adopted property: asked again while asks remain
    (`no_properties`); on the last ask, by the screen's reason codes (`ZERO_REASONS`): one code
    `no_checkable_behaviour` with the screen's explicit confirmation and basis is the exemption
    `not_applicable_no_checkable_behaviour`; one code `meaning_disagreement` is a `dispute`; anything
    else (a reviewer-side problem, mixed or missing codes) waits for the operator."""
    z = pset.get("zero_adopted") or {}
    codes = sorted({c for c in z.get("codes", []) if c in ZERO_REASONS}) if isinstance(z.get("codes"), list) else []
    unknown = [c for c in (z.get("codes") or []) if c not in ZERO_REASONS]
    if not final:
        return "no_properties", f"no adopted property; asked again (reasons {codes or 'none given'})"
    if codes == ["no_checkable_behaviour"] and not unknown and z.get("screen_confirms") is True and z.get("basis"):
        why = exemption_refusal(pset)
        if why:
            return "operator", f"no adopted property, and no exemption: {why}"
        return NO_BEHAVIOUR, f"no checkable behaviour, confirmed by the screen: {str(z['basis'])[:200]}"
    if codes == ["meaning_disagreement"] and not unknown:
        return "dispute", f"drafter and screen disagree on the law's meaning: {str(z.get('basis', ''))[:200]}"
    return "operator", f"no adopted property ({'reasons ' + ', '.join(codes + unknown) if codes or unknown else 'no reason given'})"


#: What a set that adopted nothing may show and still not be a law without checkable behaviour: the
#: reviewer could not say it (time it cannot express, an atom missing, words it cannot express), its
#: answer was not valid, or it could not decide. Each is a limit or a failure of the review, never
#: the law's.
NOT_THE_LAWS = ("unsupported_time", "missing_atom", "not_expressible", "invalid_answer", "undecidable", "cannot_tell")


def exemption_refusal(pset: dict) -> str | None:
    """Why a set that adopted nothing gives no exemption for a law without checkable behaviour (None
    when it may): an answer that was not valid, an adopted or a written candidate, a cause of
    `NOT_THE_LAWS`, or classification signals other than the no-behaviour one alone."""
    z = pset.get("zero_adopted") or {}
    if pset.get("state") != "ok":
        return "the answer was not valid"
    if pset.get("records") or pset.get("candidates") or pset.get("rejected"):
        return "candidates were written: the drafter did not find the law without checkable behaviour"
    named = sorted({c for c in list(z.get("codes") or []) + list(z.get("causes") or []) if c in NOT_THE_LAWS})
    named += sorted(k for k in NOT_THE_LAWS if z.get(k))
    if named:
        return f"the review could not say it ({', '.join(named)}): a limit of the review, not of the law"
    sig = z.get("signals")
    if isinstance(sig, dict) and (not sig.get("N") or any(sig.get(k) for k in ("E", "M", "U"))):
        return f"the classification signals are not no-behaviour alone ({sorted(k for k, v in sig.items() if v)})"
    return None


def classify(pset: dict, records: list[dict], cells: list[dict], roots: list[str], policy: str, final: bool = True) -> dict:
    """A law's disposition on its active records and the check's cells (see the module's description);
    `final` when no further property ask remains."""
    empty = {"judged": {}, "coverage": {}, "holes": [], "findings": [], "undetermined": []}
    if pset.get("state") != "ok":
        return {**empty, "disposition": "failed", "why": "; ".join(pset.get("reasons", [])[:3]) or "the property set failed"}
    if not records:
        disp, why = zero_adopted(pset, final)
        return {**empty, "disposition": disp, "why": why}
    by = {c.get("property"): c for c in cells}
    judged = {r["id"]: judge(r, by.get(r["id"]), roots) for r in records}
    cov = coverage(pset, records, judged)
    findings = [{"property": p, "detail": d, "category": next(r.get("category") for r in records if r["id"] == p)}
                for p, (k, d) in judged.items() if k == "finding"]
    open_ = [{"property": p, "class": k, "detail": d} for p, (k, d) in judged.items() if k in ("undetermined", "premises_empty")]
    out = {"judged": {p: list(v) for p, v in judged.items()}, "coverage": cov, "holes": cov["holes"], "findings": findings,
           "undetermined": open_, "why": ""}
    if any(k == "failed" for k, _ in judged.values()):
        return {**out, "disposition": "failed", "why": "a cell of the check did not run"}
    if findings:
        return {**out, "disposition": "finding"}
    if open_:
        return {**out, "disposition": "operator", "why": "; ".join(f"{u['property']}: {u['detail']}" for u in open_[:3])}
    if not cov["holes"] and cov["passed"]:
        return {**out, "disposition": "reviewed"}
    if policy == "bounded":
        return {**out, "disposition": "review_unverified"}
    return {**out, "disposition": "operator", "why": f"holes under the strict coverage policy: {cov['holes'][:4]}"}


def roots_of(view, ledger, law: str) -> list[str]:
    """A law's roots: the nodes of its plan that are not permissions."""
    nodes = view.all_nodes()
    return sorted(i for i in ledger.entries[law].nodes if not (nodes.get(i) or {}).get("permission"))


def check_key(view, reading, law: str, plan: list[str], roots: list[str], act_id: str | None, impl_check: str | None, base: dict,
              kind: str = "check") -> str:
    """The inputs a law's check (or exemption) depends on (see the module's description)."""
    from .integrate import context_version, library_digest
    from ..loop import plan_closure
    closure = plan_closure(view, list(plan))
    nodes = view.all_nodes()

    def ctx(i: str) -> str | None:
        try:
            return context_version(view, "node", i, reading, base)
        except (KeyError, ValueError, OSError):
            return None
    sets = library_digest(view, set(plan)) if any((nodes.get(i) or {}).get("rule_sets") for i in closure) else None
    return _sha({"kind": kind, "active": act_id, "roots": sorted(roots), "plan": sorted(plan), "contexts": {i: ctx(i) for i in closure},
                 "rule_sets": sets, "check": impl_check})[:32]


def row_sha(row: dict) -> str:
    return _sha(row)


def read_rows(f: Path) -> dict[str, dict]:
    """The review rows of an evidence file, by digest: only `schema` bp_review/2 and `source`
    behaviour_property; any other row is not review evidence."""
    try:
        rows = jsonl.read_strict(f)
    except FileNotFoundError:
        return {}
    return {row_sha(r): r for r in rows if isinstance(r, dict) and r.get("schema") == SCHEMA and r.get("source") == SOURCE}


def evidence_file(run) -> Path:
    return Path(getattr(run, "review_evidence_file", None) or (run.dir / EVIDENCE_FILE))


def _row(law: str, kind: str, where: dict, stage_id, cred: str = "production", **fields) -> dict:
    return {"schema": SCHEMA, "source": SOURCE, "credential": cred, "kind": kind, "law": law, "stage_id": stage_id, "where": where,
            **fields, "at": _now()}


def run_check(reviewer, view, reading, ledger, law: str, pset: dict, active: dict, base: dict, where: dict, stage_id, policy: str,
              final: bool = True, states: dict | None = None) -> dict:
    """Run the check of one law on `view` (the run, or a candidate's view with its library in force)
    and build its row; `ReviewerUnavailable` when the check did not run. `states` are the review
    states the row will be published to (the view's by default)."""
    from ..loop import plan_closure
    plan = list(ledger.entries[law].nodes)
    roots = roots_of(view, ledger, law)
    closure = plan_closure(view, plan)
    records = active_records(pset, active)
    cells = reviewer.check(view, reading, law, roots, closure, records) if records and pset.get("state") == "ok" else []
    c = classify(pset, records, cells, roots, policy, final)
    impl = impl_of(reviewer)
    aid = active_id(active)
    if c["disposition"] == NO_BEHAVIOUR:
        return no_behaviour_row(reviewer, view, reading, ledger, law, pset, base, where, stage_id, c["why"],
                                view.review_states if states is None else states)
    return _row(law, "check", where, stage_id, credential(config(view)), roots=roots, plan=sorted(plan), closure=closure, property_spec_key=pset.get("spec_key"),
                property_set_id=active["set_id"], active_property_set_id=aid,
                check_key=check_key(view, reading, law, plan, roots, aid, impl["check"], base),
                impl={"properties": impl["properties"], "check": impl["check"]}, policy=policy, **c)


def exempt_row(view, reading, ledger, law: str, base: dict, where: dict, stage_id, impl: dict) -> dict:
    """The exemption of a permission-only law: every node of its plan a permission, generated, and
    every segment's text in the law's text; keyed on its closure, with no property set."""
    from ..model import corpus
    plan = list(ledger.entries[law].nodes)
    nodes = view.all_nodes()
    text = next((l.text for l in corpus.load_laws(view.opts.laws) if l.id == law), "") if Path(view.opts.laws).exists() else ""
    flat = " ".join(text.split())
    bad = [] if plan else ["the plan is empty"]
    bad += [i for i in plan if not (nodes.get(i) or {}).get("permission")]
    bad += [f"{i}: segment `{s.get('id')}` not in the law's text" for i in plan for s in (nodes.get(i) or {}).get("segmentation", [])
            if s.get("text") and " ".join(str(s["text"]).split()) not in flat]
    disp = "not_applicable_permission" if not bad else "operator"
    return _row(law, "exempt", where, stage_id, credential(config(view)), roots=[], plan=sorted(plan), check_key=check_key(view, reading, law, plan, [], None,
                                                                                               impl["check"], base, kind="exempt"),
                impl=impl, disposition=disp, holes=[], findings=[], undetermined=[], why="; ".join(bad[:3]))


# -- the exemption of a law without checkable behaviour: a basis on the words, a credential on the rules --

#: The version of the zero-adoption classification a basis is made with.
NO_BEHAVIOUR_CLASSIFIER = "zero-adoption/1"


def law_text(view, law: str) -> str:
    from ..model import corpus
    return next((l.text for l in corpus.load_laws(view.opts.laws) if l.id == law), "") if Path(view.opts.laws).exists() else ""


def words_digest(view, law: str, base: dict) -> str:
    """What a property set is asked on besides the reviewer's own spec: the law's words, the posted
    definitions, and the vocabulary and conventions (Core, the ontology)."""
    defs = Path(view.opts.laws).with_name("definitions.jsonl")
    return _sha({"law": law, "text": hashlib.sha256(law_text(view, law).encode()).hexdigest(),
                 "definitions": hashlib.sha256(defs.read_bytes()).hexdigest() if defs.is_file() else None,
                 "core": base.get("core"), "ontology": base.get("ontology")})[:32]


def basis_key(view, law: str, sid: str, spec: str, impl_properties: str, base: dict) -> str:
    """The key of a no-behaviour classification: the words (`words_digest`), the property spec, the
    set whose actual answers were classified, the reviewer's property implementation and the
    classifier's version; never a rule, a reading or a plan."""
    return _sha({"words": words_digest(view, law, base), "spec": spec, "set": sid, "properties": impl_properties,
                 "classifier": NO_BEHAVIOUR_CLASSIFIER})[:32]


def no_behaviour_row(reviewer, view, reading, ledger, law: str, pset: dict, base: dict, where: dict, stage_id, why: str,
                     states: dict) -> dict:
    """The current credential of a law without checkable behaviour, and its basis. The basis (a row of
    kind `basis`) is the classification of the set's actual answers, keyed on `basis_key`: the law's
    pointer to it (`basis`) is reused while its key holds, so a change to the rules alone asks no new
    property call and keeps the classification. The credential (kind `exempt`, disposition
    `not_applicable_no_checkable_behaviour`) names the basis and is keyed like a check on the current
    plan, roots and closure, their readings and the check's implementation (`check_key`): any change
    there makes it stale, and a fresh one is made at no cost on the library in force, with no unit
    passed (adopted, executed and passed all zero). It is refused (`operator`) when the set was asked
    on other words than the law's now, when the classification does not give the exemption
    (`exemption_refusal`), or when the law's plan is not wholly generated. The basis row, when new, is
    returned under `_basis` for `emit` to write first."""
    from ..loop import plan_closure
    st = states.setdefault(law, {})
    plan = list(ledger.entries[law].nodes)
    roots = roots_of(view, ledger, law)
    impl = impl_of(reviewer)
    sid = pset.get("set_id") or set_id(pset)
    words = words_digest(view, law, base)
    bad = []
    if (st.get("asked_on") or {}).get(sid) != words:
        bad.append("its property set was asked on other words of the law, definitions or vocabulary than now: ask again")
    why_not = exemption_refusal(pset)
    if why_not:
        bad.append(why_not)
    nodes = view.all_nodes()
    missing = [i for i in plan if i not in nodes]
    if not plan or missing:
        bad.append("its plan is empty" if not plan else f"its plan is not generated ({', '.join(missing[:4])})")
    key = basis_key(view, law, sid, pset.get("spec_key"), impl["properties"], base)
    common = dict(roots=roots, plan=sorted(plan), closure=plan_closure(view, plan), property_spec_key=pset.get("spec_key"),
                  property_set_id=sid, impl={"properties": impl["properties"], "check": impl["check"]}, holes=[], findings=[],
                  undetermined=[], coverage={"adopted": 0, "executed": 0, "passed": 0})
    cred = credential(config(view))
    if bad:
        return _row(law, "check", where, stage_id, cred, active_property_set_id=active_id(st.get("active_set")),
                    check_key=check_key(view, reading, law, plan, roots, active_id(st.get("active_set")), impl["check"], base),
                    disposition="operator", why="; ".join(bad), **common)
    ptr = st.get("basis") or {}
    new = None
    if ptr.get("basis_key") != key:
        new = _row(law, "basis", where, stage_id, cred, property_spec_key=pset.get("spec_key"), property_set_id=sid, basis_key=key,
                   words=words, classifier=NO_BEHAVIOUR_CLASSIFIER, impl_properties=impl["properties"],
                   zero_adopted=pset.get("zero_adopted"), disposition=NO_BEHAVIOUR, why=why)
        ptr = {"row": row_sha(new), "basis_key": key}
    row = _row(law, "exempt", where, stage_id, cred, basis=dict(ptr), basis_key=key,
               check_key=check_key(view, reading, law, plan, roots, key, impl["check"], base, kind=NO_BEHAVIOUR),
               disposition=NO_BEHAVIOUR, why=why, **common)
    if new is not None:
        row["_basis"] = new
    return row


def emit(f: Path, states: dict, law: str, row: dict) -> None:
    """Write a row (its new basis first, when it has one) and point the law's state at them."""
    basis = row.pop("_basis", None)
    if basis is not None:
        jsonl.append_atomic(f, basis)
        states.setdefault(law, {})["basis"] = {"row": row_sha(basis), "basis_key": basis["basis_key"]}
    jsonl.append_atomic(f, row)
    publish(states, law, row)


def basis_refusal(run, law: str, st: dict, row: dict, rows: dict, base: dict) -> str | None:
    """Why a no-behaviour credential's basis no longer holds (None while it does): the law's basis
    pointer names another row, the row is gone, its set is lost or changed, or its key (the words, the
    property spec, the answers, the classifier) is not the one computed now."""
    ptr = st.get("basis") or {}
    if ptr.get("row") != (row.get("basis") or {}).get("row"):
        return "its credential names another classification basis than the law's"
    b = rows.get(ptr.get("row"))
    if b is None or b.get("kind") != "basis":
        return "its classification basis names no basis row"
    pset = load_set(run, law, b.get("property_set_id"))
    if pset is None:
        return "the property set its basis classified does not give its id"
    try:
        spec = spec_of(IMPLEMENTATIONS[config(run)["reviewer"]](), run, law)
    except ReviewerUnavailable as e:
        return f"the property spec cannot be computed ({e})"
    now = basis_key(run, law, b["property_set_id"], spec, (row.get("impl") or {}).get("properties"), base)
    if now != b.get("basis_key"):
        return "its classification basis no longer holds (the law's words, the definitions, the vocabulary, the property spec or the classifier changed)"
    return None


def publish(states: dict, law: str, row: dict) -> None:
    """The law's pointers to a new row: its last row always, its certificate only when the row's
    disposition certifies, else none."""
    st = states.setdefault(law, {})
    ptr = {"row": row_sha(row), "check_key": row["check_key"], "disposition": row["disposition"], "holes": row.get("holes", []),
           "where": row["where"]}
    st["last"] = ptr
    if row["disposition"] in CERTIFIED:
        st["certificate"] = ptr
    else:
        st.pop("certificate", None)


# -- status --------------------------------------------------------------------------------------------

def own_status(run, ledger, law: str, base: dict | None = None, reading=None, rows: dict | None = None) -> dict:
    """A law's own review on `run` (the run, or a candidate's view with its library in force): `class`
    is its last row's disposition, or `not_run` (no committed pointer, or one naming no row), `stale`
    (its key, plan or active set differ from now), `damaged` (its set file does not give its id) or
    `unavailable` (the reviewer cannot be loaded); `ok` when that row is its certificate."""
    from ..model.reading import Reading
    from ..loop import context_base, semantic_inputs
    st = (getattr(run, "review_states", None) or {}).get(law) or {}
    ptr = st.get("last")
    out = lambda cls, why, **k: {"ok": False, "class": cls, "why": why, **k}
    if not ptr:
        return out("not_run", "no committed review")
    rows = rows if rows is not None else read_rows(evidence_file(run))
    row = rows.get(ptr.get("row"))
    if row is None:
        return out("not_run", "its committed pointer names no review row")
    if row.get("credential") != credential(config(run)):
        return out("not_run", f"its row carries the {row.get('credential')!r} credential, which this run does not accept")
    e = ledger.entries.get(law)
    if e is None or sorted(e.nodes) != row.get("plan"):
        return out("stale", "the law's plan is not the one reviewed", row=row)
    if row["kind"] == "check":
        act = st.get("active_set")
        if active_id(act) != row.get("active_property_set_id"):
            return out("stale", "its active property set changed (a new set, or a property withdrawn)", row=row)
        if load_set(run, law, act.get("set_id")) is None:
            return out("damaged", "its property set file does not give its id", row=row)
    why = reviewer_refusal(run)
    if why:
        return out("unavailable", why, row=row)
    impl = implementation_digest(config(run).get("reviewer"))
    if row.get("impl") != impl:
        return out("stale", "the check's implementation is not the one the row was made with", row=row)
    base = base or context_base(run.opts, semantic_inputs(run.opts))
    reading = reading or Reading(run.reading_file)
    nb = row["kind"] == "exempt" and row.get("disposition") == NO_BEHAVIOUR
    if nb:
        why = basis_refusal(run, law, st, row, rows, base)
        if why:
            return out("stale", why, row=row)
    key = check_key(run, reading, law, list(e.nodes), row["roots"], row.get("basis_key") if nb else row.get("active_property_set_id"),
                    impl["check"], base, kind=NO_BEHAVIOUR if nb else row["kind"])
    if key != row.get("check_key"):
        return out("stale", "what the check depends on changed since (a rule, a concept, a reading, a composed node)", row=row)
    cert = (st.get("certificate") or {}).get("row") == ptr["row"] and row["disposition"] in CERTIFIED
    return {"ok": cert, "class": row["disposition"], "why": row.get("why", ""), "row": row}


def readers(run, ledger, law: str) -> list[str]:
    """The laws whose plan reaches a node of `law` (none of them permission-only)."""
    from ..loop import permission_only, plan_closure
    mine = set(ledger.entries[law].nodes)
    return sorted(l for l, e in ledger.entries.items() if l != law and e.nodes and not permission_only(run, l, ledger)
                  and mine & set(plan_closure(run, list(e.nodes))))


#: The credentials that say a law has nothing to check, never that something was checked.
EXEMPTIONS = ("not_applicable_permission", NO_BEHAVIOUR)


def status(run, ledger, law: str, base: dict | None = None, reading=None) -> dict:
    """Whether the review allows `law` to be accepted: `ok` when it and every law its nodes reach hold
    a current credential (a reached law whose credential is stale, an exemption's included, holds it);
    `strict` when its own is `reviewed` and no reached law is `review_unverified`; `inherited_from`,
    the reached laws whose credential is `review_unverified` (a condition carried to this law). A
    reached exemption (`EXEMPTIONS`) carries no condition: the law's own check loads the exempt law's
    rules in its closure and keys on them. It is listed in `exemption_dependencies` (its type, its
    law, its current credential), and is never counted as strictly reviewed: `strict` speaks of this
    law's own check only."""
    from ..loop import reached_laws
    if not required(run):
        return {"ok": True, "class": "not_required", "strict": False, "inherited_from": [], "exemption_dependencies": []}
    if law not in ledger.entries:
        return {"ok": False, "class": "not_run", "strict": False, "inherited_from": [], "exemption_dependencies": [], "why": "not in the ledger"}
    rows = read_rows(evidence_file(run))
    own = own_status(run, ledger, law, base, reading, rows)
    if not own["ok"]:
        return {**own, "strict": False, "inherited_from": [], "exemption_dependencies": []}
    inherited, exempt = [], []
    for dep in sorted(reached_laws(run, ledger, law)):
        s = own_status(run, ledger, dep, base, reading, rows)
        if not s["ok"]:
            return {"ok": False, "class": "dependency_unreviewed", "strict": False, "inherited_from": [], "exemption_dependencies": [],
                    "waits": dep, "why": f"`{dep}`, which it reaches, holds no current review credential ({s['class']}: {s.get('why', '')[:160]})"}
        if s["class"] == "review_unverified":
            inherited.append(dep)
        elif s["class"] in EXEMPTIONS:
            exempt.append({"type": s["class"], "law": dep, "credential": row_sha(s["row"]), "check_key": s["row"].get("check_key")})
    return {"ok": True, "class": own["class"], "strict": own["class"] == "reviewed" and not inherited, "inherited_from": inherited,
            "exemption_dependencies": exempt}


def ready(run, ledger, law: str) -> bool:
    """Whether the review lets `law` be label-checked or accepted (always, without `review: required`)."""
    return not required(run) or status(run, ledger, law)["ok"]


def revoke_unreviewed(run, ledger, to_user: list[str]) -> list[str]:
    """Every accepted law the review no longer allows loses its acceptance (`revoke_law`)."""
    from ..loop import revoke_law
    if not required(run):
        return []
    out = []
    for law, e in sorted(ledger.entries.items()):
        if e.state == "accepted":
            s = status(run, ledger, law)
            if not s["ok"]:
                reason = f"acceptance revoked: its review no longer allows it ({s['class']}: {s.get('why', '')})"
                revoke_law(run, ledger, law, reason, [[law, "review", s["class"]]])
                to_user.append(f"`{law}`: {reason}")
                out.append(law)
    return out


def gate_route(view, routed, said: list[str]) -> list[str]:
    """In a candidate's route (its view with its library in force, its staged pointers): every law
    the route leaves accepted that the review does not allow is left planned before anything is
    published, its label state `awaiting_review`. Returns those laws."""
    if not required(view):
        return []
    out = []
    for law, e in sorted(routed.entries.items()):
        if e.state != "accepted":
            continue
        s = status(view, routed, law)
        if not s["ok"]:
            e.state = "planned"
            st = dict(view.label_states.get(law) or {})
            st.update(state="awaiting_review", review=s["class"])
            view.label_states[law] = st
            said.append(f"`{law}`: not accepted — its review does not allow it ({s['class']})")
            out.append(law)
    return out


def propagate(run, ledger) -> dict[str, list[str]]:
    """The review condition of every accepted law that reaches a `review_unverified` law
    (`review_states[law]["review_condition"]`), recomputed so it holds exactly while it does. (On a
    merge with the parameter condition this is its second kind, in the same propagation.)"""
    out = {}
    if not required(run):
        return out
    for law, e in ledger.entries.items():
        st = run.review_states.get(law)
        if e.state != "accepted":
            if st and "review_condition" in st:
                st.pop("review_condition")
            continue
        s = status(run, ledger, law)
        if s.get("inherited_from"):
            run.review_states.setdefault(law, {})["review_condition"] = {"inherited_from": s["inherited_from"]}
            out[law] = s["inherited_from"]
        elif st and "review_condition" in st:
            st.pop("review_condition")
    return out


# -- work and routing -------------------------------------------------------------------------------

def _generated(run, ledger, law: str, av) -> bool:
    from ..loop import own_generated, reached_laws
    return own_generated(run, ledger, law, av) and all(own_generated(run, ledger, l, av) for l in reached_laws(run, ledger, law))


def candidates(run, ledger, permissions: bool = False) -> list[str]:
    """The planned laws in the stage's scope whose generation is complete (theirs and of every law
    they reach): the laws a review can judge (the permission-only ones with `permissions`, else the others)."""
    from ..loop import in_scope, label_scope, permission_only
    from ..store.state import Availability
    av = Availability(run, entries=ledger.entries)
    scope = label_scope(run)
    return sorted(e.law for e in ledger.entries.values() if e.state == "planned" and in_scope(scope, e.law)
                  and permission_only(run, e.law, ledger) == permissions and _generated(run, ledger, e.law, av))


def hold_reason(run, law: str, s: dict) -> str | None:
    """Why a law's review waits for the operator, or None while the review can still move it."""
    st = (run.review_states or {}).get(law) or {}
    cfg = config(run)
    stops = run_stops(run)
    if stops:
        return ("the reviewer's calls are stopped for the whole run until the operator acknowledges each open stop: "
                + "; ".join(f"`{x['stop']}` ({x.get('reason')}: {str(x.get('why', ''))[:200]})" for x in stops))
    if st.get("pending_call"):
        return f"a property call has no known outcome (spec {st['pending_call'].get('spec_key')}): reconcile it; it is never sent again"
    if st.get("dispute"):
        d = st["dispute"]
        if d.get("kind") == "label_conflict":
            return (f"its finding and its labels require opposite verdicts (property {d.get('property')}, recording "
                    f"{d.get('recording')}): {d.get('reason', '')[:200]}")
        return f"its review repair disputes the finding ({d.get('kind')}): {d.get('reason', '')[:200]}"
    if int(st.get("infra_failures", 0)) > cfg.get("infra_attempts", 1):
        return (f"the reviewer or its check did not run {st.get('infra_failures')} time(s): its retries are spent "
                f"(limit {cfg.get('infra_attempts')} beyond the first)")
    cls = s["class"]
    if cls == "dispute":
        return f"its property sets end in a dispute on the law's meaning: {s.get('why', '')[:240]}"
    if cls in ("failed", "no_properties") and int(st.get("property_asks", 0)) >= cfg.get("property_attempts", 1):
        return f"its property set was asked {st.get('property_asks')} time(s) and failed (limit {cfg.get('property_attempts')})"
    if cls == "finding" and not st.get("active_repair") and int(st.get("repairs", 0)) >= cfg.get("repair_attempts", 0):
        findings = [f"{x.get('property')}: {str(x.get('detail', ''))[:120]}" for x in (s.get("row") or {}).get("findings", [])[:3]]
        failed = [f"{x.get('check')} {x.get('subject')}: {x.get('status')}" for x in (st.get("last_repair") or {}).get("failed", [])[:4]]
        lab = (getattr(run, "label_states", None) or {}).get(law) or {}
        return (f"its review repairs are spent ({st.get('repairs', 0)}) and a finding stands — the finding {findings}; the last "
                f"repair {(st.get('last_repair') or {}).get('outcome')} {failed}; its labels {lab.get('outcome') or 'not checked'}"
                " (a repair failing on both sides is not a proven conflict)")
    if cls in ("operator", "damaged", "unavailable"):
        return f"its review needs your decision ({cls}): {s.get('why', '')[:240]}"
    return None


def work(run, ledger) -> dict[str, list[str]]:
    """The review work: `review` (a law of the review stage with no current row, or a failed set
    with asks left), `exempt` (a permission-only law with no current exemption) and `repair` (a
    finding with repairs left: the labels stage's work, PROVISIONAL R15)."""
    out = {"review": [], "exempt": [], "repair": []}
    if not required(run):
        return out
    for law in candidates(run, ledger):
        s = own_status(run, ledger, law)
        if hold_reason(run, law, s):
            continue
        if s["class"] in ("not_run", "stale", "failed", "no_properties"):
            out["review"].append(law)
        elif s["class"] == "finding":
            out["repair"].append(law)
    out["exempt"] = [law for law in candidates(run, ledger, permissions=True)
                     if own_status(run, ledger, law)["class"] in ("not_run", "stale")]
    return out


def route_holds(run, ledger, to_user: list[str]) -> list[str]:
    """Each law whose review waits for the operator (`hold_reason`) is blocked on its decision token.
    Returns the laws blocked."""
    if not required(run):
        return []
    out = []
    for law in candidates(run, ledger) + candidates(run, ledger, permissions=True):
        why = hold_reason(run, law, own_status(run, ledger, law))
        if why:
            ledger.block(law, [f"decision:{law}"], [f"review: {why}"])
            run.review_states.setdefault(law, {})["held"] = why
            to_user.append(f"`{law}`: held for you — {why}")
            out.append(law)
    return out


# -- the review stage -------------------------------------------------------------------------------

def _where(run, txn) -> tuple[dict, str | None]:
    sid = (_stage(run) or {}).get("stage_id")
    return ({"candidate": txn.id} if txn is not None else {"stage": sid}), sid


def _on(run, txn):
    """(records, reading, context manager) the check runs on: a read-only candidate's when given."""
    import contextlib
    from ..model.reading import Reading
    if txn is None:
        return run, Reading(run.reading_file), contextlib.nullcontext()
    return txn.view, txn.reading, txn.inside()


def review_law(run, ledger, law: str, reviewer, persist: Callable[[], None], to_user: list[str], txn=None) -> str:
    """Review one law: its property set (asked only when its input key has no adopted set and the
    asks allow; the call committed `pending_call` before it is made), then the check (on the read-only
    candidate `txn` when given), its row appended and its pointers committed. Returns the
    disposition, or `unreconciled` / `unavailable` / `held` when nothing was judged."""
    from ..loop import context_base, semantic_inputs
    from ..store.budget import RunPaused
    st = run.review_states.setdefault(law, {})
    cfg = config(run)
    if run_stops(run):
        return "stopped"
    if st.get("pending_call"):
        return "unreconciled"
    try:
        spec = spec_of(reviewer, run, law)
    except ReviewerUnavailable as e:
        st["infra_failures"] = int(st.get("infra_failures", 0)) + 1
        persist()
        to_user.append(f"`{law}`: its reviewer did not run ({e}); nothing judged")
        return "unavailable"
    base = context_base(run.opts, semantic_inputs(run.opts))
    words = words_digest(run, law, base)
    sid = (st.get("sets") or {}).get(spec)
    pset = load_set(run, law, sid)
    if pset is not None and (st.get("last") or {}).get("disposition") in ("failed", "no_properties") \
            and (pset.get("state") != "ok" or not pset.get("records")) and (st.get("active_set") or {}).get("set_id") == sid:
        pset = None                                   # a failed or empty set already judged: a new logical call while asks remain
    if pset is not None and (st.get("asked_on") or {}).get(sid) != words:
        pset = None                                   # asked on other words of the law: not evidence for these
    where, stage_id = _where(run, txn)
    if pset is None:
        if int(st.get("property_asks", 0)) >= cfg["property_attempts"]:
            return "held"
        ask = int(st.get("property_asks", 0)) + 1
        st["property_asks"] = ask                     # counted before it is made, so a stop never gives a free ask
        st["calls_made"] = n = int(st.get("calls_made", 0)) + 1    # one directory per logical call, never reused
        st["pending_call"] = {"spec_key": spec, "at": _now(), "ask": ask, "workdir": f"{REVIEW_DIR}/{law}/calls/call-{n:02d}"}
        persist()                                     # committed before the call: a stop leaves it unreconciled, never resent
        try:
            got = reviewer.properties(run, law, run.dir / st["pending_call"]["workdir"])
        except RunPaused:                             # refused before anything was sent (a limit or a stop): the run pauses
            st.pop("pending_call", None)
            st["property_asks"] = ask - 1
            persist()
            raise
        except WrongChannel as e:                     # executed, by another model or channel: every send of the run stops
            pending = st["pending_call"]
            stop = e.stop or stop_run(run, law, str(e), e.reason, call=pending["workdir"])
            st.pop("pending_call")                    # settled and unusable: never adopted, never sent again
            st["property_asks"] = ask - 1             # not a failure of the law's property set
            st.setdefault("unusable_calls", []).append({**pending, "outcome": e.reason, "why": str(e)[:300], "stop": stop["stop"],
                                                        "kept": kept_files(run.dir / pending["workdir"])})
            persist()
            to_user.append(f"`{law}`: its property call was answered by another model or channel ({e}); every send of the run is "
                           f"stopped until you acknowledge stop `{stop['stop']}` (review_decide acknowledge)")
            return "stopped"
        except ReviewerUnavailable as e:
            if e.executed is False:                   # nothing was sent: the ask is given back, the retry counts as infrastructure
                st.pop("pending_call", None)
                st["property_asks"] = ask - 1
            st["infra_failures"] = int(st.get("infra_failures", 0)) + 1
            persist()
            to_user.append(f"`{law}`: its property call did not run ({e})"
                           + ("" if e.executed is False else "; its outcome is unknown: reconcile it, it is never sent again"))
            return "unavailable"
        sid = adopt(run, law, st, spec, got, where, stage_id)
        st.setdefault("asked_on", {})[sid] = words    # what it was asked on, besides its spec
        persist()
        pset = load_set(run, law, sid)
    elif (st.get("active_set") or {}).get("set_id") != sid:
        st["active_set"] = new_active(sid, st.get("active_set"))
    view, reading, ctx = _on(run, txn)
    try:
        with ctx:
            row = run_check(reviewer, view, reading, ledger, law, pset, st["active_set"], base, where, stage_id, cfg["coverage"],
                            final=int(st.get("property_asks", 0)) >= cfg["property_attempts"], states=run.review_states)
    except ReviewerUnavailable as e:
        st["infra_failures"] = int(st.get("infra_failures", 0)) + 1
        persist()
        to_user.append(f"`{law}`: its check did not run ({e}); nothing judged")
        return "unavailable"
    if row["disposition"] == "failed" and pset.get("state") == "ok":
        st["infra_failures"] = int(st.get("infra_failures", 0)) + 1      # a cell the check did not run: the set is kept
    emit(evidence_file(run), run.review_states, law, row)     # nothing until the pointers below are committed
    persist()
    to_user.append(f"`{law}`: review {row['disposition']}" + (f" — {row['why']}" if row["why"] else "")
                   + (f"; findings {[f['property'] for f in row['findings']]}" if row["findings"] else ""))
    return row["disposition"]


def admit(run, law: str, st: dict, spec: str, got: dict) -> dict:
    """The property set an answer gives. A reviewer returns its answers raw (`rounds`, each the
    author's draft and the screen, with its `calls`), and the adoption gate of `review_schema`
    decides every candidate on the law's context and the operator's withdrawn identities: an answer
    invalid as a whole gives a `failed` set (nothing published, no exemption; per-candidate checks
    kept as diagnostics). A set the reviewer adopted itself is taken only from a test stand-in
    (whose credential no production run accepts); from any other reviewer it is refused."""
    from . import review_schema
    pending = st.get("pending_call") or {}
    gen = review_schema.sha({"spec_key": spec, "ask": pending.get("ask"), "workdir": pending.get("workdir")})
    if "rounds" in got:
        calls = list(got.get("calls", []))
        if got.get("state", "ok") != "ok":
            return {"state": "failed", "records": [], "clauses": [], "calls": calls, "generation_id": gen,
                    "reasons": list(got.get("reasons") or ["the reviewer reports the generation failed"])}
        try:
            ctx = review_schema.context_for(run, law)
        except (KeyError, OSError, ValueError) as e:
            return {"state": "failed", "records": [], "clauses": [], "calls": calls, "generation_id": gen,
                    "reasons": [f"the law's context could not be built: {e}"]}
        out = review_schema.adopt_answer(list(got["rounds"]), ctx, withdrawn_identities(st.get("active_set")))
        return {**out, "calls": calls, "generation_id": gen, "answers": review_schema.sha(got["rounds"])}
    if is_test_only(config(run).get("reviewer")) or got.get("state") != "ok":
        return got
    return {"state": "failed", "records": [], "clauses": [], "calls": list(got.get("calls", [])), "generation_id": gen,
            "reasons": ["the reviewer returned an adopted set, not its answers: only the harness's adoption gate adopts"]}


def adopt(run, law: str, st: dict, spec: str, got: dict, where: dict, stage_id) -> str:
    """Store an answer as a property set (decided by `admit`), make it the law's active set and write
    its row; the pending call is settled. Returns its id."""
    got = {**admit(run, law, st, spec, got), "spec_key": spec}
    new = save_set(run, law, got)
    supersedes = (st.get("active_set") or {}).get("set_id")
    st.setdefault("sets", {})[spec] = new
    st["active_set"] = new_active(new, st.get("active_set"))
    jsonl.append_atomic(evidence_file(run), _row(law, "property_set", where, stage_id, credential(config(run)), property_spec_key=spec,
                                                 property_set_id=new, active_property_set_id=active_id(st["active_set"]),
                                                 supersedes=supersedes, state=got.get("state")))
    st.pop("pending_call", None)
    return new


def execution_evidence(run, law: str, pending: dict) -> list[str]:
    """The files that show a pending call was executed: an answer or a provider credential the
    reviewer left in the call's directory."""
    d = run.dir / str(pending.get("workdir") or "")
    return sorted(p.name for p in d.glob("*") if p.is_file() and p.name.split(".")[0] in ("response", "answer", "credential")) \
        if pending.get("workdir") and d.is_dir() else []


def reconcile(run, law: str, executed: bool, answer: dict | None = None) -> str:
    """The operator's settlement of a law's pending call (PROVISIONAL, R17 open: the `review_decide
    reconcile` command's core). `not executed` is refused while an answer or a credential of the call
    exists (a damaged answer is not proof that nothing ran); it gives the ask back. `executed` with the
    saved answer adopts it; executed with none ends the logical call failed. A run-wide stop is never
    cleared here. Returns what was recorded."""
    st = run.review_states.get(law) or {}
    pending = st.get("pending_call")
    if not pending:
        raise ValueError(f"`{law}` has no pending call")
    if not executed:
        shown = execution_evidence(run, law, pending)
        if shown:
            raise ValueError(f"`{law}`: its call left {shown}: it cannot be recorded as not executed")
        st.pop("pending_call")
        st["property_asks"] = max(0, int(st.get("property_asks", 0)) - 1)
        st["infra_failures"] = int(st.get("infra_failures", 0)) + 1
        return "not_executed"
    from ..loop import context_base, semantic_inputs
    from ..store import budget
    words = words_digest(run, law, context_base(run.opts, semantic_inputs(run.opts)))
    if answer is not None:
        named = [k for k, x in budget.gate_rows(jsonl.read_strict(usage_file(run)))[0].items() if x.get("call") == pending.get("workdir")]
        if named:
            raise ValueError(f"`{law}`: its call is named by stop {named}: an answer from another model or channel is never adopted")
        sid = adopt(run, law, st, pending["spec_key"], answer, {"decision": "reconcile"}, (_stage(run) or {}).get("stage_id"))
        st.setdefault("asked_on", {})[sid] = words
        return "adopted"
    sid = adopt(run, law, st, pending["spec_key"], {"state": "failed", "records": [], "clauses": [], "calls": [],
                                                    "reasons": ["executed, no valid answer was kept: the logical call ends failed"]},
                {"decision": "reconcile"}, (_stage(run) or {}).get("stage_id"))
    st.setdefault("asked_on", {})[sid] = words
    return "failed"


def kept_files(d: Path) -> dict[str, str]:
    """The files a call left in its directory, by name, with their digests."""
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(Path(d).glob("*")) if p.is_file()} \
        if Path(d).is_dir() else {}


def integrity_defects(run) -> list[str]:
    """What of the review's kept evidence is lost or changed: a property set a law's state names whose
    file does not give its id; a file an unusable call left, or a response a stop names, missing or
    not the one recorded."""
    out = []
    for law, st in sorted((getattr(run, "review_states", None) or {}).items()):
        sids = {(st.get("active_set") or {}).get("set_id")} | set((st.get("sets") or {}).values())
        out += [f"`{law}`: property set {sid} is missing or does not give its id" for sid in sorted(x for x in sids if x)
                if load_set(run, law, sid) is None]
        for c in st.get("unusable_calls", []):
            now = kept_files(run.dir / c.get("workdir", ""))
            out += [f"`{law}`: {c.get('workdir')}/{name} of an unusable call is {'missing' if name not in now else 'changed'}"
                    for name, sha in sorted((c.get("kept") or {}).items()) if now.get(name) != sha]
    from ..store import budget
    for k, row in budget.gate_rows(jsonl.read_strict(usage_file(run)))[0].items():
        if row.get("response"):
            p = run.dir / row["response"]
            sha = hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
            if sha != row.get("response_sha"):
                out.append(f"stop `{k}`: the response {row['response']} is {'missing' if sha is None else 'not the one recorded'}")
    return out


def unknown_calls(review_states: dict, rows: list[dict], named: str | None = None) -> list[dict]:
    """The review's calls whose execution is not known, each `{law, call, text}` or `{request, label,
    text}`: a property call committed and not settled (cleared by `reconcile` of its law), a reviewer
    request of the usage file pending or unknown (cleared by a settlement of that request), and the
    request `named` (a stop's) when it is."""
    from ..store import budget
    out = [{"law": law, "call": st["pending_call"].get("workdir"),
            "text": f"`{law}`: property call {st['pending_call'].get('workdir')} has no known outcome"}
           for law, st in sorted((review_states or {}).items()) if st.get("pending_call")]
    _spent, unresolved, _settled, _v = budget.fold(rows)
    labels = {r.get("request"): r.get("label") or "" for r in rows if r.get("request")}
    out += [{"request": q, "label": labels.get(q), "text": f"request {q} ({labels.get(q)}) has no known outcome"} for q in sorted(unresolved)
            if budget.ROLE_BEHAVIOUR_REVIEW in labels.get(q, "") or q == named]
    return out


def unresolved_calls(run, rows: list[dict], stop: dict | None = None) -> list[str]:
    """The review's calls whose execution is not known (`unknown_calls`), the request a stop names included."""
    return [x["text"] for x in unknown_calls(getattr(run, "review_states", None) or {}, rows, (stop or {}).get("request"))]


def read_record(record_file) -> tuple[dict, str]:
    """The operator's decision record (a JSON object) and the digest of its bytes."""
    raw = Path(record_file).read_bytes()
    try:
        rec = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"the record {record_file} is not JSON ({e.msg})")
    if not isinstance(rec, dict):
        raise ValueError(f"the record {record_file} is not a JSON object")
    return rec, hashlib.sha256(raw).hexdigest()


def acknowledge(run, stop_id: str, record_file) -> dict:
    """The operator confirms one persisted stop (`review_decide acknowledge`). The record binds the
    run (`run_id`), the stop (`stop`) and the decision (`decision: acknowledge`) and says why (`reason`);
    its digest is written with the acknowledgement, and the same record again changes nothing. It is
    refused, with nothing written, while a review call's execution is not known (reconcile it first:
    an acknowledgement never makes an unknown call known, releases a reservation or says a call did
    not run) or while kept evidence is lost or changed (`integrity_defects`: that needs a real
    recovery). It confirms that stop only: no other stop, no spend, no reservation, no limit, no
    attempt count, no model, channel or reviewer implementation changes, and a call the stop settled
    stays settled and unusable. Then the checks a launch makes are run again and reported
    (`after_acknowledge`); an acknowledgement passes none of them. Returns {row, again, checks, open}."""
    from ..store import budget
    rec, sha = read_record(record_file)
    bad = [f"`{k}` is {rec.get(k)!r}, not {v!r}" for k, v in (("run_id", run.opts.run_id), ("stop", stop_id), ("decision", "acknowledge"))
           if rec.get(k) != v]
    if not isinstance(rec.get("reason"), str) or not rec["reason"].strip():
        bad.append("`reason` is missing: the record says why the stop is confirmed")
    if bad:
        raise budget.AcknowledgeRefused("the record does not bind this acknowledgement: " + "; ".join(bad))

    def refusal(rows, stop):
        why = unresolved_calls(run, rows, stop)
        if why:
            return "reconcile first, nothing written: " + "; ".join(why[:6])
        why = integrity_defects(run)
        if why:
            return "a lost answer or a broken digest needs a real recovery, not a confirmation: " + "; ".join(why[:6])
        return None
    row, again = budget.acknowledge(usage_file(run), stop_id, sha, rec, refusal)
    return {"row": row, "again": again, "checks": after_acknowledge(run), "open": [x["stop"] for x in run_stops(run)]}


def after_acknowledge(run) -> list[str]:
    """The checks a launch makes, run again after an acknowledgement: the run's review configuration
    and the reviewer, model and channel it fixed; the tree and the kept evidence; every budget limit
    (an acknowledgement is never a limit raised); every stop of the run still active, of every kind
    (`feedback.active_stops`, with the status the run's last launch ended on): a defect pause, a limit,
    an unknown call or another stop is never cleared by this acknowledgement."""
    from ..store import budget
    from ..tools import handoff
    out = [f"review configuration: {d}" for d in config_defects(config(run))]
    why = reviewer_refusal(run)
    if why:
        out.append(f"reviewer: {why}")
    try:
        if (run.dir / "handoff" / "manifest.json").exists():
            out += [f"tree: {r}" for r in handoff.verify(run.opts.run_id, artifacts=True)[0]]
        else:
            handoff.check_on_launch(run)
    except SystemExit as e:
        out.append(f"tree: {e}")
    out += [f"evidence: {d}" for d in integrity_defects(run)]
    out += [f"budget: {x}: an acknowledgement raises no limit" for x in budget.spent_limits(usage_file(run), run.opts)]
    from . import feedback
    try:
        saved = jsonl.read_json(run.dir / "summary.json", {}) or {}
    except (OSError, jsonl.DataIntegrityError) as e:
        saved = {}
        out.append(f"summary: the run's summary.json cannot be read ({e}): the stop its last launch ended on is not known")
    status = saved.get("status") or ""
    out += [f"stop `{x['id']}` ({x['kind']}) is still active: {feedback.one_line(x['cause'])[:200]}; cleared by: {x['clears']}"
            for x in feedback.active_stops(run, status, saved.get("stop_reason") or "")
            if not (x["id"] == "budget" and status != "paused_budget") and x["id"] != "integrity-evidence"]   # reported above
    return out


def exempt_law(run, ledger, law: str, reviewer, persist: Callable[[], None], to_user: list[str], txn=None) -> str:
    """Record the exemption of a permission-only law and, once it holds, accept the law
    (PROVISIONAL, R21 open: a permission law is accepted in the review stage). It waits for no reader."""
    from ..loop import context_base, semantic_inputs
    where, stage_id = _where(run, txn)
    base = context_base(run.opts, semantic_inputs(run.opts))
    view, reading, ctx = _on(run, txn)
    with ctx:
        row = exempt_row(view, reading, ledger, law, base, where, stage_id, impl_of(reviewer))
    jsonl.append_atomic(evidence_file(run), row)
    publish(run.review_states, law, row)
    if row["disposition"] == "not_applicable_permission":
        ledger.accept(law, list(ledger.entries[law].nodes))
        run.label_states[law] = {"state": "generated_not_label_aligned", "nodes": list(ledger.entries[law].nodes),
                                 "reason": "every node is a permission: never violated, outside the label check; not reviewed"}
    persist()
    to_user.append(f"`{law}`: {row['disposition']}" + (f" ({row['why']})" if row["why"] else ""))
    return row["disposition"]


def review_iteration(run, ledger, persist: Callable[[], None], to_user: list[str]) -> dict[str, list[str]]:
    """A review launch's iteration: acceptances the review no longer allows are revoked; each law to
    review is reviewed and each permission-only law exempted, the checks run on one read-only
    candidate; the laws only the operator can move are held. Returns what was done, by kind."""
    from .candidate import SCHEDULING, Candidate
    done = {"revoked": revoke_unreviewed(run, ledger, to_user), "reviewed": [], "exempted": [], "held": []}
    try:
        reviewer = reviewer_for(run)
    except ReviewerUnavailable as e:
        to_user.append(f"the review did not run: {e}")
        return done
    w = work(run, ledger)
    if w["review"] or w["exempt"]:
        with SCHEDULING.pause(timeout=600):
            txn = Candidate.open(run, hooks=())
            try:
                for law in w["review"]:
                    done["reviewed"].append(f"{law}:{review_law(run, ledger, law, reviewer, persist, to_user, txn)}")
                for law in w["exempt"]:
                    done["exempted"].append(f"{law}:{exempt_law(run, ledger, law, reviewer, persist, to_user, txn)}")
            finally:
                txn.close("the review checks of the stage")
    done["held"] = route_holds(run, ledger, to_user)
    persist()
    return done


# -- the hook every candidate of a required run carries --------------------------------------------------

def prior(run, ledger) -> dict[str, dict]:
    """The production status of every law with a committed row, computed before a candidate opens."""
    if not required(run):
        return {}
    rows = read_rows(evidence_file(run))
    return {law: own_status(run, ledger, law, rows=rows) for law, st in (run.review_states or {}).items()
            if st.get("last") and law in ledger.entries}


def _holes(row_or_status) -> list:
    return [json.dumps(h, sort_keys=True) for h in ((row_or_status or {}).get("holes") or [])]


def _units(row: dict | None) -> dict[str, str]:
    return {p: v[0] for p, v in ((row or {}).get("judged") or {}).items()}


def _same_set(was: dict, row: dict) -> bool:
    return (was.get("row") or {}).get("active_property_set_id") == row.get("active_property_set_id")


def kept_units(was: dict, row: dict) -> list[str]:
    """What a new row loses of the law's last row on the same active set: a unit that passed and no
    longer passes, a unit of a finding that left the check (gone, unknown, empty or outside it) rather
    than passing or still finding. Empty when there is no earlier row on that set."""
    if not was.get("row") or not _same_set(was, row):
        return []
    before, now = _units(was["row"]), _units(row)
    lost = [f"{p}: passed before, now {now.get(p, 'not checked')}" for p, k in before.items() if k == "pass" and now.get(p) != "pass"]
    lost += [f"{p}: a finding before, now {now.get(p, 'not checked')}" for p, k in before.items()
             if k == "finding" and now.get(p) not in ("pass", "finding")]
    return lost


def non_regression(was: dict, row: dict) -> tuple[bool, str]:
    """Whether a new row keeps what the law had: its certificate (a `reviewed` stays `reviewed`, a
    `review_unverified` gains no hole, an exemption stays), and in every case each unit of its last row
    on the same active set (`kept_units`). A law with no earlier row has nothing to keep, and is said so."""
    now = row["disposition"]
    lost = kept_units(was, row)
    if lost:
        return False, f"units lost: {lost[:4]}"
    if not was.get("ok"):
        return True, (f"no review certificate before ({was.get('class')}); its earlier units are kept; now {now}" if was.get("row")
                      else f"no earlier review row: no unit to keep; now {now} (no certificate is claimed by this check)")
    if was["class"] == "reviewed":
        return now == "reviewed", f"its review was reviewed and is now {now}"
    if was["class"] == "review_unverified":
        if now == "reviewed":
            return True, ""
        if now == "review_unverified":
            new = sorted(set(_holes(row)) - set(_holes(was.get("row"))))
            return not new, f"new holes {new}"
        return False, f"its review was review_unverified and is now {now}"
    if was["class"] in ("not_applicable_permission", NO_BEHAVIOUR):
        return now == was["class"], f"its exemption ({was['class']}) is lost ({now})"
    return True, ""


def repair_goal(was: dict, row: dict) -> tuple[bool, str]:
    """The target of a review repair: a new certificate the run's policy allows, no hole beyond the
    finding row's, every unit that passed there still passing, and every property the finding named
    passing (a finding gone into anything else is not a pass)."""
    if row["disposition"] not in CERTIFIED:
        return False, f"the finding is not cleared: the review is now {row['disposition']}"
    prev = was.get("row") or {}
    new = sorted(set(_holes(row)) - set(_holes(prev)))
    if new:
        return False, f"the repair opened new holes {new}"
    named = [f["property"] for f in prev.get("findings", [])]
    not_passed = [p for p in named if _units(row).get(p) != "pass"]
    if not_passed:
        return False, f"the properties of the finding did not pass: {not_passed}"
    lost = [p for p, k in _units(prev).items() if k == "pass" and _units(row).get(p) != "pass"]
    if lost:
        return False, f"units that passed before no longer pass: {lost}"
    return True, f"the finding is cleared: {row['disposition']}"


def review_hook(run, ledger, prior_status: dict[str, dict], plans: dict[str, list[str]], target: str | None = None,
                goal: str | None = None):
    """The review check of a candidate (`review_non_regression`, a `candidate.Hook`): for every law
    the change reaches (and `target`) with an active property set or an exemption, the check or the
    exemption runs again on the candidate; its row and pointers are staged in the candidate's copies,
    published only with the commit. A law with a certificate must keep it (`non_regression`); a law
    with none passes without one (its staged row certifies it only if it certifies); with `goal`
    `finding` the target must meet `repair_goal`. A check that did not run is `unavailable`."""
    from .candidate import CheckResult
    from ..loop import context_base, permission_only, semantic_inputs

    def hook(txn, aff) -> list:
        view, out = txn.view, []
        base = context_base(view.opts, semantic_inputs(view.opts))     # on the candidate's library: Core is named, not located
        laws = sorted(set(aff.laws) | ({target} if target else set()))
        try:
            reviewer = reviewer_for(run)
        except ReviewerUnavailable as e:
            return [CheckResult("review_non_regression", law, "unavailable", [str(e)]) for law in laws]
        cfg = config(run)
        where, stage_id = {"candidate": txn.id}, (_stage(run) or {}).get("stage_id")
        for law in laws:
            if law not in plans or law not in txn.ledger.entries:
                out.append(CheckResult("review_non_regression", law, "pass", ["not in the ledger: nothing reviewed"]))
                continue
            was = prior_status.get(law) or {"ok": False, "class": "not_run"}
            st = view.review_states.get(law) or {}
            try:
                if permission_only(view, law, txn.ledger):
                    row = exempt_row(view, txn.reading, txn.ledger, law, base, where, stage_id, impl_of(reviewer))
                else:
                    pset = load_set(run, law, (st.get("active_set") or {}).get("set_id"))
                    if pset is None:
                        ok = not (law == target and goal == "finding")
                        out.append(CheckResult("review_non_regression", law, "pass" if ok else "fail",
                                               ["no property set: no review certificate before, none issued; the law stays awaiting "
                                                "its review"]))
                        continue
                    row = run_check(reviewer, view, txn.reading, txn.ledger, law, pset, st["active_set"], base, where, stage_id,
                                    cfg["coverage"])
            except ReviewerUnavailable as e:
                out.append(CheckResult("review_non_regression", law, "unavailable", [str(e)[:300]]))
                continue
            emit(view.review_evidence_file, view.review_states, law, row)
            txn.review_touched.add(law)
            ok, why = repair_goal(was, row) if law == target and goal == "finding" else non_regression(was, row)
            out.append(CheckResult("review_non_regression", law, "pass" if ok else "fail",
                                   [why] + [f["detail"] for f in row["findings"][:2]] + [u["detail"] for u in row["undetermined"][:2]]))
        return out
    return hook


# -- the review repair of a finding (PROVISIONAL, R15 open: in the labels stage, with the label hook) ---------

def no_session(run, txn, law: str, evidence: dict) -> list:
    """The review repair session's stand-in while no session is wired to its prompt (`repair_prompt`):
    it never runs."""
    raise ReviewerUnavailable("the review repair session is not wired in this harness", executed=False)


#: The session a review repair asks: `(run, txn, law, evidence) -> list[candidate.Change]`; raises
#: `Dispute` to dispute the finding, `ReviewerUnavailable` or `session.SessionUnavailable` when it did not run.
REPAIR_SESSION: Callable = no_session


def render_findings(row: dict, labels: dict | None = None) -> dict:
    """What a review repair is shown of a finding: the properties, their clauses and the finding's
    details, the holes; with `labels`, the label check's results the law already has, as context the
    repair must not regress (`label_context`), never as its goal; never a trace file, another law's
    rule or a diagnosis."""
    return {"findings": row.get("findings", []), "holes": row.get("holes", []), "policy": row.get("policy"),
            **({"label_context": labels} if labels else {})}


def label_context(run, law: str) -> dict | None:
    """The label results a review repair of `law` is given beside its finding, all already computed:
    its committed label check (outcome, coverage, the recordings that mismatch, the files of the check
    and its evidence, relative to the run) and the label checks that refused an earlier candidate of
    its repairs. None when it has neither. No label is judged again for it, and improving the labels
    is not the review repair's goal."""
    from . import label_check
    st = (getattr(run, "label_states", None) or {}).get(law) or {}
    refused = [x for x in ((run.review_states.get(law) or {}).get("last_repair") or {}).get("failed", [])
               if x.get("check") == "label_non_regression"] + [x for x in (st.get("last_repair") or {}).get("failed", [])
                                                               if x.get("check") == "label_non_regression"]
    out = {}
    if st.get("check"):
        rec = label_check.committed_checks(run.dir, {law: st})[law]
        out.update(outcome=st.get("outcome"), coverage=st.get("coverage"), check=st["check"], evidence=st.get("evidence"),
                   mismatches=sorted(r for r, x in label_check.eligible_statuses(rec).items() if x == "mismatch"))
    if refused:
        out["refused_candidates"] = refused
    return out or None


def findings_block(evidence: dict, run_dir: Path) -> str:
    """The evidence part of a review repair's prompt (`render_findings`): the findings, the recorded
    coverage holes and the run's coverage policy; then, when the law has them, its label results
    (`label_context`) as non-regression context: the committed label check as its label repair is
    shown it, and the checks that refused an earlier candidate of the law's repairs."""
    out = ["## Review findings", "", f"Coverage policy: {evidence.get('policy')}.", "", "Findings:", "```json",
           json.dumps(evidence.get("findings", []), ensure_ascii=False, indent=1), "```", "",
           "Recorded coverage holes (they must not increase):", "```json",
           json.dumps(evidence.get("holes", []), ensure_ascii=False, indent=1), "```"]
    labels = evidence.get("label_context")
    if labels:
        out += ["", "### Existing label-check results (non-regression context)", "",
                "They must not regress; improving them is not this repair's goal."]
        if labels.get("check"):
            cov = labels.get("coverage") or {}
            out.append(f"Label check: {labels.get('outcome')} ({cov.get('matched')} of {cov.get('eligible')} plain label(s) match).")
            f = run_dir / str(labels.get("evidence") or "")
            if labels.get("evidence") and f.is_file():
                out += ["The law's committed label check, as its label repair is shown it (the repair goal it names is that "
                        "repair's, not this one's):", "", re.sub(r"(?m)^(#+) ", r"##\1 ", f.read_text(encoding="utf-8"))]
        if labels.get("refused_candidates"):
            out.append("Label checks that refused an earlier candidate of this law's repairs (diagnostics of rolled-back "
                       "candidates, not rulings on the accepted library):")
            out += [f"- {r.get('check')} `{r.get('subject')}`: {r.get('status')}" + "".join(f"; {x}" for x in r.get("details", []))
                    for r in labels["refused_candidates"]]
    return "\n".join(out) + "\n"


def repair_prompt(run, txn, law, evidence: dict, onto) -> str:
    """The `node_repair.md` prompt of a review repair of `law` (a corpus law) on the candidate `txn`:
    the law's own parts as a label repair has them, the review state as its verdict, the finding
    evidence (`findings_block`), and the prompt's `review_findings` section shown."""
    from ..agents import render
    from .label_repair import law_parts
    st = run.review_states.get(law.id) or {}
    attempt = (st.get("active_repair") or {}).get("attempt") or int(st.get("repairs", 0)) + 1
    named = sorted({f.get("property") for f in evidence.get("findings", [])})
    parts = {**law_parts(run, txn, law, [], onto),
             "verdict": (f"## The law's state\n\nReview: finding (properties {', '.join(named) or 'none named'}). Repair goal: the "
                         f"review repair goal under Review findings. Review repair {attempt} of {config(run).get('repair_attempts')} for this law.\n"),
             "evidence": findings_block(evidence, run.dir)}
    return render.render("node_repair.md", parts, sections={"review_findings": True})


def conflict_refusal(run, law: str, row: dict, cites: dict) -> str | None:
    """Why a repair's claim that a finding and a label require opposite verdicts is not shown by the
    evidence (None when it is): the property is one of the finding's, the recording one of the law's
    committed label mismatches, and the verdict the property requires (violated for `must_detect`,
    not violated for `must_not_flag`) is the opposite of the recording's label."""
    from . import label_check
    prop = next((f for f in row.get("findings", []) if f.get("property") == cites.get("property")), None)
    if prop is None:
        return f"property {cites.get('property')!r} is not one of the finding's"
    st = (getattr(run, "label_states", None) or {}).get(law) or {}
    if not st.get("check"):
        return "the law has no committed label check"
    rec = label_check.committed_checks(run.dir, {law: st})[law]
    scored = {x.get("recording_id"): x for x in rec.get("scored", []) if x.get("label") is not None and not x.get("judgment_call")}
    r = scored.get(cites.get("recording"))
    if r is None or r.get("status") != "mismatch":
        return f"recording {cites.get('recording')!r} is not a mismatch of the law's committed label check"
    wants = prop.get("category") == "must_detect"
    if (r.get("label") in ("violated", "violation")) == wants:
        return "the property and the label require the same kind of verdict: no conflict is shown"
    return None


def repair_finding(run, ledger, law: str, training, persist: Callable[[], None], to_user: list[str],
                   prog: dict | None = None) -> str:
    """One review repair of `law`'s finding in a candidate whose hooks are the concept review, the
    label hook (every law it reaches keeps its matches) and the review hook (goal `finding`):
    committed, with the route decided on label and review together, or rolled back and counted. A
    dispute goes to the operator; a session or a check that did not run counts against the
    infrastructure limit, never the repairs. `prog` is the loop's progress of the iteration (`to_user`
    its own list): a kept repair commits it, with the lines the commit says, in the same snapshot as
    its state, so a stop past the commit point resumes with them said. Every outcome's line is said
    before `persist`. Returns `committed`, `rolled_back`, `dispute`, `unavailable` or `held`."""
    from . import label_check
    from .candidate import SCHEDULING, Candidate, ChangeRefused, CommitRefused, concept_review
    from ..agents import session
    from ..loop import context_base, label_key, label_state, semantic_inputs, staged
    st = run.review_states.setdefault(law, {})
    cfg = config(run)
    s = own_status(run, ledger, law)
    resumed = bool(st.get("active_repair"))
    if s["class"] != "finding" or (not resumed and int(st.get("repairs", 0)) >= cfg["repair_attempts"]) or run_stops(run):
        return "held"
    if not resumed:                                   # a new attempt is counted before it starts; its resume is not counted again
        st["repairs"] = int(st.get("repairs", 0)) + 1
        st["active_repair"] = {"attempt": st["repairs"], "at": _now(), "finding_row": (st.get("last") or {}).get("row")}
        persist()
    attempt = st["active_repair"]["attempt"]
    run.law_entries = ledger.entries
    plans = {e.law: list(e.nodes) for e in ledger.entries.values()}
    hooks = [concept_review]
    if training is not None:                          # the labels must not regress; improving them is not this repair's goal
        hooks.append(label_check.label_hook(training, label_check.committed_checks(run.dir, run.label_states), plans))
    hooks.append(review_hook(run, ledger, prior(run, ledger), plans, target=law, goal="finding"))
    result = ""
    with SCHEDULING.pause(timeout=600):
        txn = Candidate.open(run, hooks=tuple(hooks))
        try:
            if training is not None:
                training.bind(txn)
            changes = REPAIR_SESSION(run, txn, law, render_findings(s["row"], label_context(run, law)))
            txn.apply(changes)
            results = txn.verify()
            if any(r.status == "unavailable" for r in results):
                raise ReviewerUnavailable("; ".join(f"{r.check} {r.subject}: {(r.details or [''])[0]}" for r in results
                                                    if r.status == "unavailable")[:300])
            if not all(r.status == "pass" for r in results):
                bad = [{"check": r.check, "subject": r.subject, "status": r.status, "details": [str(x)[:300] for x in r.details[:3]]}
                       for r in results if r.status != "pass"]
                txn.rollback("; ".join(f"{b['check']} {b['subject']}: {b['status']}" for b in bad[:4]))
                st["last_repair"] = {"attempt": attempt, "candidate": txn.id, "outcome": "rolled_back", "failed": bad[:12]}
                result = "rolled_back"
            else:
                vst = txn.view.review_states.setdefault(law, {})
                vst.update(repairs=attempt, last_repair={"attempt": attempt, "candidate": txn.id, "outcome": "committed"})
                vst.pop("active_repair", None)
                txn.review_touched.add(law)
                for o in [o for o in txn.label_checks if o not in run.label_states]:
                    txn.label_checks.pop(o)            # compared only: a law never label-checked is routed by its own label check
                routed = txn.route(None, [])
                base = context_base(run.opts, semantic_inputs(run.opts)) if staged(run) else None

                def keyed(o, ns):                      # each label state keyed on the candidate it was checked on
                    if base is None:
                        return None
                    with txn.inside():
                        return label_key(run, o, list(ns), base=base, view=txn.view, reading=txn.reading)
                updates = {o: {k: v for k, v in label_state(run, o, c, run.label_states[o]["nodes"], txn.area / "label", txn.id,
                                                            key=keyed(o, run.label_states[o]["nodes"])).items() if k != "repairs"}
                           for o, c in txn.label_checks.items() if o in ledger.entries}
                said = list(routed.said) + [f"`{law}`: review repair committed"]
                from ..store import paths
                from ..store.state import prog_paths
                txn.commit(routed=routed, label_updates=updates,
                           extra_state=None if prog is None else {"prog": prog_paths({**prog, "to_user": to_user + said}, paths.stored)})
                for l in routed.entries:
                    if l in ledger.entries and l in txn.published["ledger"]:
                        ledger.entries[l].__dict__.update({k: getattr(txn.published["ledger"][l], k) for k in ("state", "nodes", "gaps",
                                                                                                            "own_gaps", "waits_on", "reasons")})
                to_user.extend(said)
                result = "committed"
        except Dispute as e:
            why = conflict_refusal(run, law, s["row"], e.cites) if e.kind == "label_conflict" else None
            if why:                                    # an unshown conflict is an attempt that changed nothing
                st["last_repair"] = {"attempt": attempt, "outcome": f"refused: a label conflict not shown ({why})"}
                result = "rolled_back"
            else:
                st["dispute"] = {"kind": e.kind, "reason": str(e), "findings": [f["property"] for f in s["row"]["findings"]],
                                 **({"property": e.cites.get("property"), "recording": e.cites.get("recording"),
                                     "label": label_context(run, law)} if e.kind == "label_conflict" else {})}
                st["last_repair"] = {"attempt": attempt, "outcome": "dispute"}
                result = "dispute"
        except (ReviewerUnavailable, session.SessionUnavailable) as e:
            if getattr(e, "executed", False) is False:    # nothing ran: the attempt is given back, the retry counts as infrastructure
                st["repairs"] = attempt - 1
            st["infra_failures"] = int(st.get("infra_failures", 0)) + 1
            to_user.append(f"`{law}`: its review repair did not run ({str(e)[:240]}); counted against the infrastructure limit")
            result = "unavailable"
        except (ChangeRefused, CommitRefused, ValueError) as e:
            st["last_repair"] = {"attempt": attempt, "candidate": txn.id, "outcome": f"refused: {str(e)[:300]}"}
            result = "rolled_back"
        finally:
            if txn.status == "open":
                (txn.rollback if txn.changed else txn.close)(f"the review repair ended: {result or 'stopped'}")
    if result != "committed":
        st.pop("active_repair", None)
        to_user.append(f"`{law}`: review repair {result}")
    persist()
    return result


def counts(run, ledger) -> dict[str, list[str]]:
    """The laws by their review standing, for the report: accepted strictly reviewed, accepted under a
    review condition (its own `review_unverified` or one inherited), permission laws generated and not
    reviewed (with `via_readers`, a derived label only, where a reader with a `reviewed` certificate
    reaches it), laws without checkable behaviour, awaiting review, a finding to repair, held for the
    operator; and, for each accepted law, the exemptions it reaches (`exemption_dependencies`: `<law>
    <- <exempt law> (<type>, credential <row>)`), never counted among the strictly reviewed."""
    keys = ("reviewed_strict", "review_unverified", "generated_not_reviewed", "via_readers", "awaiting_review", "review_repair",
            "review_held", "test_credentials", "no_checkable_behaviour", "exemption_dependencies")
    out = {k: [] for k in keys}
    if not required(run):
        return out
    if config(run).get("test_only"):                  # a test stand-in's certificates are never counted as reviews
        out["test_credentials"] = sorted(l for l, e in ledger.entries.items() if e.state == "accepted")
        return out
    w = work(run, ledger)
    for law, e in ledger.entries.items():
        if e.state == "accepted":
            s = status(run, ledger, law)
            if not s["ok"]:
                continue                                  # its acceptance no longer holds: revoked at the next acceptance pass
            out["exemption_dependencies"] += [f"{law} <- {d['law']} ({d['type']}, credential {d['credential'][:16]})"
                                              for d in s.get("exemption_dependencies", [])]
            if s["class"] == "not_applicable_permission":
                out["generated_not_reviewed"].append(law)
                if any(own_status(run, ledger, r)["class"] == "reviewed" for r in readers(run, ledger, law)):
                    out["via_readers"].append(law)
            elif s["class"] == NO_BEHAVIOUR:
                out["no_checkable_behaviour"].append(law)
            elif s.get("strict"):
                out["reviewed_strict"].append(law)
            else:
                out["review_unverified"].append(law)
        elif (run.review_states.get(law) or {}).get("held") and e.state == "blocked":
            out["review_held"].append(law)
    out["awaiting_review"] = sorted(set(w["review"]) | set(w["exempt"]))
    out["review_repair"] = list(w["repair"])
    return {k: sorted(v) for k, v in out.items()}


def transition_refusals(snap: dict, run_dir: Path | None = None) -> list[str]:
    """Why no stage transition may be made on a run's committed snapshot: a property call whose
    outcome is unknown, a review repair begun and not ended, a stop of the run's sends not acknowledged."""
    out = [f"`{law}`: a property call with no known outcome (reconcile it first)"
           for law, st in sorted((snap.get("review_states") or {}).items()) if st.get("pending_call")]
    out += [f"`{law}`: a review repair active" for law, st in sorted((snap.get("review_states") or {}).items()) if st.get("active_repair")]
    if run_dir is not None:
        out += [f"the run's sends are stopped run-wide: stop `{x['stop']}` ({x.get('reason')}: {str(x.get('why', ''))[:200]}) "
                "is not acknowledged" for x in run_stops(Path(run_dir))]
    return out
