"""The review stage of a run whose policy is `review: required`, with a scripted reviewer registered as
a test stand-in (no model, no solver; its rows carry the test credential, which a production run
refuses): the G → R → L order and the transitions, the four identities and the certificates, the two
acceptance conditions decided together, the review check inside every candidate a label repair or a
review repair opens, coverage and permissions, the persistent limits, and a run with `review: none`
left as it was.

The library, the candidate, the snapshot, the journal, the ledger, the routing and the label check
are the real ones; the gate's toolchain step, the whole-library build and the validator are stood in
for as in the candidate's own tests; the label check's monitor is its own tests' stand-in program."""
import copy
import json
import tempfile
import unittest
from contextlib import ExitStack, contextmanager
from dataclasses import replace
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import session
from harness.checks import gate
from harness.lean import lean
from harness.model import nodeid
from harness.phases import behaviour_review as br
from harness.phases import candidate as cand
from harness.phases import feedback, integrate, label_repair
from harness.store import jsonl, paths, stages
from harness.store.budget import BudgetPaused
from harness.store.gaps import GapLedger
from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
from harness.store.state import DEPENDENCY_POLICY, Options, Run, commit_state, stage_policy_refusal
from scripts.tests import fake_reviewer
from scripts.tests.fake_reviewer import cell, prop, pset
from scripts.tests.s24_helpers import close_row, open_row, write_stages
from scripts.tests.test_candidate import Base, Gates, files, node_rec, passing, world
from scripts.tests.test_label_repair import L, N
from scripts.tests.test_label_repair_session import DIFF5, repairing, set_verdict

CODE = {"source_commit": None, "code": {"files": {}, "digest": "x"}}
COMPOSES_5 = [{"span": "o1", "rule": N[5], "map": {"v": "v"}, "as": "condition"}]


class Crash(BaseException):
    pass


def policy(review: str = "required", **cfg) -> dict:
    p = {"label_repair": True, "dependency": DEPENDENCY_POLICY, "review": review}
    if review == "required":
        p["review_config"] = {**br.fix_reviewer(br.config_of({}), fake_reviewer.NAME), **cfg}   # the reviewer already fixed
    return p


def stage(run, kind: str = "review", review: str = "required", **cfg) -> None:
    """The run's stage record: G0 with the policy, then the stage of `kind` entered from it."""
    pol = policy(review, **cfg)
    rows = [open_row("G0", run_id=run.opts.run_id, kind="generation", acceptance_policy=pol, semantic={}, effects={}, code_baseline=CODE)]
    if kind != "generation":
        sid = {"review": "R1", "labels": "L1"}[kind]
        rows += [close_row("G0", "t1"), open_row(sid, run_id=run.opts.run_id, kind=kind, prev="G0", transition="t1",
                                                  acceptance_policy=pol, semantic={}, effects={}, code_baseline=CODE)]
    write_stages(run.dir, *rows)


def law_of(i: str) -> str:
    return nodeid.law_of(i)[0]


@contextmanager
def tools():
    """The gate's toolchain, the build and the validator stood in for; no model session may start."""
    def no_session(*a, **k):
        raise AssertionError("a model session started")
    with ExitStack() as s:
        s.enter_context(mock.patch.object(gate, "_toolchain", Gates()))
        s.enter_context(mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())))
        s.enter_context(mock.patch.object(lean, "lake_build", lambda *a, **k: (0, "")))
        s.enter_context(mock.patch.object(cand, "validate_records", passing))
        s.enter_context(mock.patch.object(session, "run", no_session))
        yield


def persist_of(run, ledger):
    return lambda: commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))


def reload(run, ledger):
    fresh = Run(run.opts); fresh.restore_state(); fresh.load_accepted()
    fresh.law_entries = ledger.entries
    return fresh


@contextmanager
def rworld(nodes: dict | None = None, kind: str = "review", review: str = "required", **cfg):
    """A run of laws L-1.. (one node each unless `nodes` says otherwise), every law planned and its
    nodes accepted, in a stage of `kind` under `review`, the scripted reviewer registered."""
    fake = fake_reviewer.install()
    nodes = nodes or {N[k]: node_rec(N[k]) for k in (1, 2, 3)}
    with world({}, nodes) as (run, lib), tools():
        laws = sorted({law_of(i) for i in nodes})
        ledger = Ledger(run.ledger_file, laws, 2)
        ledger.attempt = 1
        for law in laws:
            ledger.mark_planned(law, sorted(i for i in nodes if law_of(i) == law), 1)
        run.law_entries = ledger.entries
        stage(run, kind, review, **cfg)
        persist = persist_of(run, ledger)
        persist()
        yield run, ledger, fake, persist


def both(tag: str = "a", clause: str = "C1"):
    """A property set covering clause C1 with one property of each category."""
    return pset(prop("p"), prop("q", "must_not_flag"), tag=tag)


def passes(roots, records):
    return [cell(r["id"], {roots[0]: "violated" if r["category"] == "must_detect" else "compliant"}) for r in records]


def finds(roots, records):
    """`p` (must_detect) finds; `q` passes."""
    return [cell(r["id"], {roots[0]: "compliant"}) for r in records]


def on_mark(rule: str, before, after):
    return lambda roots, recs: (before if fake_reviewer.mark_of(rule) == "v1" else after)(roots, recs)


def script(fake, law, *answers, cells=passes):
    fake.sets[law] = list(answers)
    fake.cells[law] = cells


def review(run, ledger, law, persist):
    return br.review_law(run, ledger, law, fake_reviewer.FAKE, persist, [])


def live_rows(run):
    return br.read_rows(run.dir / br.EVIDENCE_FILE)


class Judgment(unittest.TestCase):
    """The unit judgment (unknown is never a pass, a law joins its own roots only) and the dispositions."""

    def test_unknown_premises_and_unconfirmed_scenes_are_never_a_pass(self):
        for cat in ("must_detect", "must_not_flag"):
            rec = prop("p", cat)
            cases = {"unknown law verdict": (cell("p", {"A": "unknown"}), "undetermined"),
                     "no root verdict (no grounding)": (cell("p", {"B": "violated"}), "undetermined"),
                     "empty antecedent": (cell("p", None, antecedent="empty"), "premises_empty"),
                     "antecedent never confirmed by Core": (cell("p", None, antecedent="unknown"), "undetermined"),
                     "an unknown scene is possible": (cell("p", {"A": "violated"}, unknown=True), "undetermined"),
                     "solver did not finish": (cell("p", None, status="solver_incomplete"), "undetermined"),
                     "synthesis failed": (cell("p", None, status="synthesis_failed"), "undetermined"),
                     "replay not confirmed": (cell("p", {"A": "unknown" if cat == "must_detect" else "violated"}, replay="not_realized"),
                                              "undetermined"),
                     "outside the fragment": (cell("p", None, status="outside_fragment"), "hole"),
                     "a check that did not run": (cell("p", None, status="failed"), "failed")}
            for why, (c, want) in cases.items():
                with self.subTest(cat=cat, case=why):
                    self.assertEqual(br.judge(rec, c, ["A"])[0], want)
        self.assertEqual(br.judge(prop("p"), None, ["A"])[0], "undetermined")

    def test_a_law_verdict_joins_its_own_roots_only(self):
        self.assertEqual(br.law_verdict({"A": "compliant", "B": "violated"}, ["A"]), "compliant")      # A composes B
        self.assertEqual(br.judge(prop("q", "must_not_flag"), cell("q", {"A": "compliant", "B": "violated"}), ["A"])[0], "pass")
        self.assertEqual(br.judge(prop("p"), cell("p", {"A": "compliant", "B": "violated"}), ["A"])[0], "finding")
        self.assertEqual(br.law_verdict({"A1": "compliant", "A2": "unknown"}, ["A1", "A2"]), "unknown")
        self.assertEqual(br.law_verdict({"A1": "violated", "A2": "unknown"}, ["A1", "A2"]), "violated")
        self.assertEqual(br.law_verdict({"A1": "not_applicable", "A2": "compliant"}, ["A1", "A2"]), "compliant")

    def test_dispositions_and_coverage(self):
        ok = lambda p: cell(p, {"A": "violated" if p.startswith("p") else "compliant"})
        two = pset(prop("p"), prop("q", "must_not_flag"), prop("p2", clause="C2"), clauses=("C1", "C2"))
        c = lambda s, cells, pol="strict": br.classify(s, s["records"], cells, ["A"], pol)
        self.assertEqual(c(both(), [ok("p"), ok("q")])["disposition"], "reviewed")
        half = c(two, [ok("p"), ok("q"), ok("p2")])                     # C2 has no must_not_flag property
        self.assertEqual((half["disposition"], half["holes"]), ("operator", [{"kind": "uncovered_clause", "clause": "C2",
                                                                               "categories": ["must_not_flag"]}]))
        self.assertEqual(c(two, [ok("p"), ok("q"), ok("p2")], "bounded")["disposition"], "review_unverified")
        out = c(both(), [cell("p", None, status="outside_fragment"), cell("q", None, status="outside_fragment")], "bounded")
        self.assertEqual((out["disposition"], out["coverage"]["executed"], out["coverage"]["passed"]), ("review_unverified", 0, 0))
        self.assertEqual(c(pset(), [], "bounded")["disposition"], "operator")                     # zero adopted
        self.assertEqual(c(both(), [ok("p"), cell("q", None, antecedent="empty")], "bounded")["disposition"], "operator")
        self.assertEqual(c(pset(state="failed"), [])["disposition"], "failed")
        fnd = c(both(), [cell("p", {"A": "compliant"}), cell("q", {"A": "unknown"})])
        self.assertEqual((fnd["disposition"], [u["property"] for u in fnd["undetermined"]]), ("finding", ["q"]))   # both kept

    def test_a_category_is_excused_only_on_the_screens_explicit_word(self):
        clause = {"id": "C1", "quote": "x", "no_property": [{"category": "must_not_flag", "reason": "the words decide none"}]}
        silent = pset(prop("p"), clauses=(clause,))
        self.assertEqual(br.classify(silent, silent["records"], [cell("p", {"A": "violated"})], ["A"], "strict")["disposition"], "operator")
        said = pset(prop("p"), clauses=(clause,), assessments=[{"clause": "C1", "category": "must_not_flag", "agrees_no_property": True,
                                                                "basis": "the clause states only a duty"}])
        self.assertEqual(br.classify(said, said["records"], [cell("p", {"A": "violated"})], ["A"], "strict")["disposition"], "reviewed")
        missed = pset(prop("p"), prop("q", "must_not_flag"), uncovered=[{"clause": None, "quote": "an obligation no clause names"}])
        out = br.classify(missed, missed["records"], [cell("p", {"A": "violated"}), cell("q", {"A": "compliant"})], ["A"], "strict")
        self.assertEqual((out["disposition"], out["holes"][0]["clause"]), ("operator", "U1"))


class Policy(Base):
    """A new run requires the review; a test run and an old run do not; the configuration is fixed."""

    def test_a_new_run_requires_the_review_and_a_test_run_does_not(self):
        fake_reviewer.install()
        with world({}, {N[1]: node_rec(N[1])}) as (run, _lib), mock.patch("harness.tools.handoff.code_digest", lambda: CODE["code"]):
            opts = replace(run.opts, label_repair=True, label_deferred=True)
            g0 = loop.first_stage(run, opts, {})
            cfg = g0["acceptance_policy"]["review_config"]                           # G0 fixes no reviewer
            self.assertEqual((g0["acceptance_policy"]["review"], cfg["reviewer"], cfg["implementation"], cfg["coverage"],
                              cfg["test_only"]), ("required", None, None, "strict", False))
            self.assertEqual((cfg["repair_attempts"], cfg["property_attempts"], cfg["infra_attempts"]), (2, 2, 3))
            self.assertEqual(br.config_defects(cfg), [])
            fixed = br.fix_reviewer(cfg, "fake")                                     # what the first review entry writes
            self.assertEqual((fixed["reviewer"], fixed["implementation"], fixed["test_only"]), ("fake", br.impl_of(fake_reviewer.FAKE), True))
            self.assertEqual({k: v for k, v in fixed.items() if k not in ("reviewer", "implementation", "test_only")},
                             {k: v for k, v in cfg.items() if k not in ("reviewer", "implementation", "test_only")})
            self.assertEqual(br.config_defects(fixed), [])
            t0 = loop.first_stage(run, replace(opts, mode="test", base_run="b"), {"base_run": "d"})
            self.assertEqual(t0["acceptance_policy"]["review"], "none")

    def test_launch_options(self):
        base = dict(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), label_repair=True)
        self.assertRegex(loop.check_options(Options(**base, review_stage=True, label_deferred=True)) or "", "three stages")
        self.assertRegex(loop.check_options(Options(**base, review_stage=True, label_dataset="d")) or "", "reads no training")
        self.assertRegex(loop.check_options(Options(**{**base, "label_repair": False}, review_stage=True)) or "", "label_repair")
        self.assertRegex(loop.check_options(Options(**base, label_deferred=True, review_coverage="loose")) or "", "review_coverage")
        self.assertRegex(loop.check_options(Options(**base, label_deferred=True, review_infra_attempts=0)) or "", "review_infra_attempts")
        self.assertIsNone(loop.check_options(Options(**base, review_stage=True)))
        self.assertEqual(loop.launch_kind(Options(**base, review_stage=True)), "review")
        for name in ("nobody", "fake"):                                              # no launch that generates names a reviewer
            self.assertRegex(loop.launch_refusal(Options(**base, label_deferred=True, behaviour_reviewer=name, dry_run=True)) or "",
                             "fixed when the run enters its review stage")
        self.assertIsNone(loop.launch_refusal(Options(**base, label_deferred=True, dry_run=True)))
        self.assertRegex(loop.launch_refusal(Options(**base, review_stage=True, behaviour_reviewer="nobody", dry_run=True)) or "",
                         "not registered")
        fake_reviewer.install()
        self.assertRegex(loop.launch_refusal(Options(**base, review_stage=True, behaviour_reviewer="fake", reviewer_model="x",
                                                     aggregate_verifier_model="y", allow_same_vendor=True)) or "",
                         "behaviour_review_budget_usd")

    def test_the_stage_fixes_the_review_configuration(self):
        fake_reviewer.install()
        row = {"stage_id": "R1", "acceptance_policy": policy()}
        opts = Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), label_repair=True, review_stage=True,
                       behaviour_reviewer="fake")
        self.assertIsNone(stage_policy_refusal(row, opts))
        self.assertIsNone(stage_policy_refusal(row, replace(opts, behaviour_reviewer=None)))   # none named: the fixed one stands
        self.assertRegex(stage_policy_refusal(row, replace(opts, review_coverage="bounded")) or "", "fixed for its life")
        self.assertRegex(stage_policy_refusal(row, replace(opts, behaviour_reviewer="other")) or "", "keeps its reviewer")
        g0 = {"stage_id": "G0", "acceptance_policy": {**policy(), "review_config": br.config_of({})}}   # not fixed yet
        gen = replace(opts, review_stage=False, label_deferred=True, behaviour_reviewer=None)
        self.assertIsNone(stage_policy_refusal(g0, gen))
        self.assertRegex(stage_policy_refusal(g0, replace(gen, behaviour_reviewer="fake")) or "", "fixed when the run enters its review stage")
        self.assertRegex(stage_policy_refusal(row, replace(opts, review_repair_attempts=1)) or "", "never lowered")   # a run limit
        self.assertIsNone(stage_policy_refusal(row, replace(opts, review_repair_attempts=5)))
        self.assertRegex(stage_policy_refusal({"stage_id": "R1", "acceptance_policy": {**policy(), "review": "maybe"}}, opts) or "",
                         "not a legal value")
        bad = copy.deepcopy(policy()); bad["review_config"]["coverage"] = "loose"
        self.assertRegex(stage_policy_refusal({"stage_id": "R1", "acceptance_policy": bad}, opts) or "", "review_config.coverage")
        self.assertIsNone(stage_policy_refusal({"stage_id": "G0", "acceptance_policy": policy("none")}, replace(opts, review_stage=False)))

    def test_another_implementation_and_a_production_run_refuse_the_stand_in(self):
        with rworld() as (run, ledger, fake, persist):
            script(fake, L[1], both())
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")
            self.assertTrue(br.status(run, ledger, L[1])["ok"])
            fake_reviewer.install("fake-v2")                       # the same name, another implementation (R8)
            self.assertIn("another implementation", br.reviewer_refusal(run))
            self.assertEqual(br.status(run, ledger, L[1])["class"], "unavailable")
            fake_reviewer.install()
            stage(run, "review", test_only=False)                  # a production policy: the test credential is refused
            self.assertIn("test stand-in", br.reviewer_refusal(run))
            s = br.own_status(run, ledger, L[1])
            self.assertFalse(s["ok"])
            self.assertIn("credential", s["why"])
            stage(run, "review")
            self.assertTrue(br.status(run, ledger, L[1])["ok"])
            loop.accept_ready(run, replace(run.opts, label_repair=False), ledger, None, [])
            self.assertEqual(br.counts(run, ledger)["test_credentials"], [L[1]])     # never counted as a review
            self.assertEqual(br.counts(run, ledger)["reviewed_strict"], [])


class Staged(Base):
    """T1/T3: generation leaves the review to the review stage, the label check waits for it."""

    def test_generation_then_review_then_labels(self):
        nodes = {N[1]: node_rec(N[1]), N[2]: node_rec(N[2]), N[3]: node_rec(N[3], permission=True)}
        with rworld(nodes, kind="generation") as (run, ledger, fake, persist):
            self.assertEqual(loop.label_ready(run, ledger), {})                       # no label check before the review
            self.assertEqual(loop.defer_labels(run, ledger, []), [])
            self.assertEqual(loop.accept_permissions(run, ledger, []), [])            # no acceptance in generation, a permission's neither
            self.assertEqual(br.work(run, ledger), {"review": [L[1], L[2]], "exempt": [L[3]], "repair": []})
            self.assertEqual(feedback.pending_lists(run, ledger)["awaiting_review"], [L[1], L[2], L[3]])
            self.assertEqual(fake.property_calls, [])
            stage(run, "review")
            for k in (1, 2):
                script(fake, L[k], both())
            done = br.review_iteration(run, ledger, persist, [])
            self.assertEqual(sorted(done["reviewed"]), [f"{L[1]}:reviewed", f"{L[2]}:reviewed"])
            self.assertEqual(done["exempted"], [f"{L[3]}:not_applicable_permission"])
            self.assertEqual(ledger.entries[L[3]].state, "accepted")                  # the permission is accepted in R (R21)
            self.assertEqual(br.work(run, ledger), {"review": [], "exempt": [], "repair": []})
            self.assertTrue(all("candidate" in r["where"] for r in live_rows(run).values() if r["kind"] != "property_set"))
            stage(run, "labels")
            self.assertEqual(sorted(loop.label_ready(run, ledger)), [L[1], L[2]])
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual(snap["review_states"][L[1]]["certificate"]["disposition"], "reviewed")
            self.assertEqual(len(fake.property_calls), 2)

    def test_old_run_with_review_none_is_unchanged(self):
        nodes = {N[1]: node_rec(N[1]), N[2]: node_rec(N[2]), N[3]: node_rec(N[3], permission=True)}
        with rworld(nodes, kind="labels", review="none") as (run, ledger, fake, persist):
            self.assertEqual(sorted(loop.label_ready(run, ledger)), [L[1], L[2]])
            self.assertFalse(br.required(run))
            self.assertEqual(br.work(run, ledger), {"review": [], "exempt": [], "repair": []})
            self.assertNotIn("awaiting_review", feedback.pending_lists(run, ledger))
            loop.accept_ready(run, replace(run.opts, label_repair=False), ledger, None, [])
            self.assertEqual({e.state for e in ledger.entries.values()}, {"accepted"})
            self.assertEqual(run.label_states[L[3]]["state"], "generated_not_label_aligned")
            persist()
            self.assertNotIn("review_states", jsonl.read_json(run.state_file, {}))
            self.assertEqual((fake.property_calls, fake.check_calls), ([], []))

    def test_without_a_stage_record_nothing_changes(self):
        with rworld(kind="labels", review="none") as (run, ledger, fake, persist):
            (run.dir / stages.STAGES_FILE).unlink()
            self.assertFalse(br.required(run))
            self.assertEqual(sorted(loop.label_ready(run, ledger)), [L[1], L[2], L[3]])


class Evidence(Base):
    """The evidence: only committed, keyed, schema-checked rows are certificates; never `rulings.jsonl`."""

    def test_other_rows_and_rulings_are_not_evidence(self):
        with rworld(kind="labels") as (run, ledger, fake, persist):
            jsonl.append_atomic(run.dir / "rulings.jsonl", {"subject": N[1], "law": L[1], "state": "upheld"})
            jsonl.append_atomic(run.dir / br.EVIDENCE_FILE, {"schema": "bp_review/1", "source": br.SOURCE, "law": L[1], "disposition": "reviewed"})
            jsonl.append_atomic(run.dir / br.EVIDENCE_FILE, {"schema": br.SCHEMA, "source": "fixture_replay", "law": L[1], "disposition": "reviewed"})
            self.assertEqual(br.own_status(run, ledger, L[1])["class"], "not_run")
            self.assertEqual(live_rows(run), {})
            run.review_states[L[1]] = {"last": {"row": "0" * 64}, "certificate": {"row": "0" * 64}}
            self.assertEqual(br.own_status(run, ledger, L[1])["class"], "not_run")

    def test_a_row_without_a_committed_pointer_is_nothing(self):
        with rworld(kind="labels") as (run, ledger, fake, persist):
            script(fake, L[1], both())
            review(run, ledger, L[1], persist)
            row = br.own_status(run, ledger, L[1])["row"]
            snap = jsonl.read_json(run.state_file, {})
            for k in ("last", "certificate"):
                snap["review_states"][L[1]].pop(k)
            jsonl.write_atomic(run.state_file, json.dumps(snap))
            fresh = reload(run, ledger)
            self.assertIn(br.row_sha(row), live_rows(fresh))
            self.assertEqual(br.own_status(fresh, ledger, L[1])["class"], "not_run")

    def test_two_answers_to_one_input_key_and_a_withdrawal(self):
        with rworld(kind="labels") as (run, ledger, fake, persist):
            script(fake, L[1], both("a"))
            review(run, ledger, L[1], persist)
            first = run.review_states[L[1]]["active_set"]
            first_id = br.active_id(first)
            self.assertTrue(br.status(run, ledger, L[1])["ok"])
            # the only must_not_flag property of C1 withdrawn: the certificate stops counting, C1 becomes a hole
            br.withdraw(run, L[1], "q", "operator ruled the property misreads the clause")
            self.assertNotEqual(br.active_id(run.review_states[L[1]]["active_set"]), first_id)
            s = br.own_status(run, ledger, L[1])
            self.assertEqual((s["ok"], s["class"]), (False, "stale"))
            self.assertIn(L[1], br.work(run, ledger)["review"])
            self.assertEqual(review(run, ledger, L[1], persist), "operator")         # withdrawing never makes a pass
            self.assertEqual(len(fake.property_calls), 1)                            # checked again, no new call
            # a second answer to the same input key is another set: the old certificate does not cover it
            other = br.save_set(run, L[1], {**both("b"), "spec_key": fake.spec_key(run, L[1])})
            self.assertNotEqual(other, first["set_id"])

    def test_a_damaged_set_file_is_not_evidence(self):
        with rworld(kind="labels") as (run, ledger, fake, persist):
            script(fake, L[1], both())
            review(run, ledger, L[1], persist)
            f = br.set_path(run, L[1], run.review_states[L[1]]["active_set"]["set_id"])
            d = json.loads(f.read_text()); d["records"][0]["category"] = "must_not_flag"
            f.write_text(json.dumps(d))
            self.assertEqual(br.own_status(run, ledger, L[1])["class"], "damaged")

    def test_a_changed_rule_makes_the_row_stale(self):
        with rworld(kind="labels") as (run, ledger, fake, persist):
            script(fake, L[1], both())
            review(run, ledger, L[1], persist)
            rel = nodeid.rule_path(N[1])
            (paths.LIBRARY / rel).write_text(files("node", N[1], "v9")[rel])
            self.assertEqual(br.own_status(run, ledger, L[1])["class"], "stale")
            self.assertEqual(br.revoke_unreviewed(run, ledger, []), [])              # nothing was accepted


class Acceptance(Base):
    """Both conditions: label route and review, decided together."""

    def test_aligned_labels_do_not_clear_a_stale_review(self):
        with rworld(kind="labels") as (run, ledger, fake, persist):
            for k in (1, 2, 3):
                script(fake, L[k], both())
                review(run, ledger, L[k], persist)
            loop.accept_ready(run, replace(run.opts, label_repair=False), ledger, None, [])
            self.assertEqual(ledger.entries[L[1]].state, "accepted")
            br.withdraw(run, L[1], "p", "ruled")
            to_user = []
            loop.accept_ready(run, replace(run.opts, label_repair=False), ledger, None, to_user)
            self.assertEqual(ledger.entries[L[1]].state, "planned")
            self.assertTrue(any("review no longer allows it" in x for x in to_user))
            self.assertNotIn(L[1], loop.label_ready(run, ledger))

    def test_a_dependency_without_a_certificate_holds_its_reader(self):
        nodes = {N[1]: node_rec(N[1]), N[2]: node_rec(N[2], compositions=[{"span": "o1", "rule": N[1], "map": {"v": "v"}, "as": "condition"}])}
        with rworld(nodes, kind="labels") as (run, ledger, fake, persist):
            script(fake, L[2], both())
            review(run, ledger, L[2], persist)
            s = br.status(run, ledger, L[2])
            self.assertEqual((s["ok"], s["class"], s.get("waits")), (False, "dependency_unreviewed", L[1]))
            script(fake, L[1], both(), cells=finds)
            review(run, ledger, L[1], persist)
            self.assertFalse(br.status(run, ledger, L[2])["ok"])                     # a finding upstream holds it too
            self.assertNotIn(L[2], loop.label_ready(run, ledger))

    def test_route_entry_never_accepts_without_review(self):
        from types import SimpleNamespace
        with rworld(kind="labels") as (run, ledger, fake, persist):
            chk = SimpleNamespace(outcome="aligned", coverage={"matched": 1, "eligible": 1}, notes=[], summary={"counts": {}}, abstractions=[])
            self.assertEqual(loop.route_entry(run, ledger, L[1], chk, [N[1]], {"state": "accepted", "evidence": "x"}, []), "awaiting_review")
            self.assertEqual(ledger.entries[L[1]].state, "planned")


class Coverage(Base):
    """Holes: `strict` (the default) waits for the operator; `bounded`, fixed at the start, certifies
    `review_unverified`, never strict, carried to every law that reaches it."""

    def test_strict_holds_a_review_with_holes(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], pset(prop("p")))                                       # no must_not_flag property of C1
            self.assertEqual(review(run, ledger, L[1], persist), "operator")
            self.assertFalse(br.status(run, ledger, L[1])["ok"])
            self.assertEqual(br.route_holds(run, ledger, []), [L[1]])
            self.assertEqual(ledger.entries[L[1]].state, "blocked")

    def test_bounded_certifies_and_carries_the_condition(self):
        nodes = {N[1]: node_rec(N[1]), N[2]: node_rec(N[2], compositions=[{"span": "o1", "rule": N[1], "map": {"v": "v"}, "as": "condition"}])}
        with rworld(nodes, kind="labels", coverage="bounded") as (run, ledger, fake, persist):
            script(fake, L[1], pset(prop("p")))
            script(fake, L[2], both())
            self.assertEqual(review(run, ledger, L[1], persist), "review_unverified")
            self.assertEqual(review(run, ledger, L[2], persist), "reviewed")
            s1, s2 = br.status(run, ledger, L[1]), br.status(run, ledger, L[2])
            self.assertEqual((s1["ok"], s1["strict"]), (True, False))
            self.assertEqual((s2["ok"], s2["strict"], s2["inherited_from"]), (True, False, [L[1]]))
            loop.accept_ready(run, replace(run.opts, label_repair=False), ledger, None, [])
            self.assertEqual(run.review_states[L[2]]["review_condition"], {"inherited_from": [L[1]]})
            self.assertNotIn("review_condition", run.review_states[L[1]])


class ZeroAdopted(Base):
    """Operator 2026-11-18 (provisional): a final set with no adopted property is classified by the
    screen's reason codes; it is asked again while asks remain."""

    def zero(self, codes, confirms=None, basis="the law only defines a term"):
        z = {"codes": codes, "basis": basis}
        if confirms is not None:
            z["screen_confirms"] = confirms
        return {**pset(tag=str(codes) + str(confirms)), "zero_adopted": z}

    def test_each_cause(self):
        cases = {"reviewer problem": (["reviewer_problem"], None, "operator"),
                 "no checkable behaviour, confirmed": (["no_checkable_behaviour"], True, br.NO_BEHAVIOUR),
                 "no checkable behaviour, not confirmed": (["no_checkable_behaviour"], None, "operator"),
                 "a meaning disagreement": (["meaning_disagreement"], None, "dispute"),
                 "mixed reasons": (["no_checkable_behaviour", "meaning_disagreement"], True, "operator"),
                 "no reason": ([], None, "operator")}
        for why, (codes, confirms, want) in cases.items():
            with self.subTest(why), rworld(kind="review") as (run, ledger, fake, persist):
                script(fake, L[1], self.zero(codes, confirms), self.zero(codes, confirms))
                self.assertEqual(review(run, ledger, L[1], persist), "no_properties")      # an ask remains: asked again
                self.assertIn(L[1], br.work(run, ledger)["review"])
                self.assertEqual(review(run, ledger, L[1], persist), want)
                self.assertEqual(len(fake.property_calls), 2)
                s = br.status(run, ledger, L[1])
                if want == br.NO_BEHAVIOUR:
                    self.assertEqual((s["ok"], s["strict"]), (True, False))
                    self.assertEqual(br.route_holds(run, ledger, []), [])
                    self.assertEqual(br.own_status(run, ledger, L[1])["class"], br.NO_BEHAVIOUR)
                    self.assertIn(br.NO_BEHAVIOUR, br.CERTIFIED)
                else:
                    self.assertFalse(s["ok"])
                    self.assertEqual(br.route_holds(run, ledger, []), [L[1]])


class Permissions(Base):
    """A permission-only law is exempted in R and accepted there; it waits for no reader, and a reader
    needs its exemption as it needs any certificate it reaches."""

    def test_exempt_without_waiting_and_invalidated_with_its_reader(self):
        nodes = {N[1]: node_rec(N[1], permission=True),
                 N[2]: node_rec(N[2], compositions=[{"span": "o1", "rule": N[1], "map": {"v": "v"}, "as": "exception"}]),
                 N[3]: node_rec(N[3], permission=True)}
        with rworld(nodes, kind="review") as (run, ledger, fake, persist):
            self.assertEqual(br.work(run, ledger)["exempt"], [L[1], L[3]])
            script(fake, L[2], both())
            br.review_iteration(run, ledger, persist, [])
            self.assertEqual((ledger.entries[L[1]].state, ledger.entries[L[3]].state), ("accepted", "accepted"))   # no reader needed
            self.assertTrue(br.status(run, ledger, L[2])["ok"])
            c = br.counts(run, ledger)
            stage(run, "review", test_only=False)
            self.assertEqual(br.counts(run, ledger)["generated_not_reviewed"], [])  # a test credential never counts
            stage(run, "review")
            self.assertEqual(c["test_credentials"], [L[1], L[3]])
            rel = nodeid.rule_path(N[1])
            (paths.LIBRARY / rel).write_text(files("node", N[1], "v2")[rel])         # the permission changes
            self.assertEqual(br.own_status(run, ledger, L[1])["class"], "stale")
            self.assertEqual(br.own_status(run, ledger, L[2])["class"], "stale")
            self.assertEqual(br.revoke_unreviewed(run, ledger, []), [L[1]])

    def test_an_empty_plan_is_never_exempted(self):
        with rworld({N[1]: node_rec(N[1], permission=True)}, kind="review") as (run, ledger, fake, persist):
            from harness.loop import context_base, semantic_inputs
            ledger.entries[L[1]].nodes = []
            row = br.exempt_row(run, None, ledger, L[1], context_base(run.opts, semantic_inputs(run.opts)), {"stage": "R1"}, "R1",
                                fake.digest())
            self.assertEqual((row["disposition"], row["why"]), ("operator", "the plan is empty"))

    def test_old_runs_accept_permissions_as_before(self):
        with rworld({N[1]: node_rec(N[1], permission=True)}, kind="labels", review="none") as (run, ledger, fake, persist):
            self.assertEqual(loop.accept_permissions(run, ledger, []), [L[1]])


def rec5() -> str:
    return json.dumps({k: v for k, v in node_rec(N[5]).items() if k != "segmentation"})


@contextmanager
def labelled(**cfg):
    """The label repair world (five laws, a synthetic dataset), in a labels stage of a run that
    requires the review, every law with a node reviewed on the library as it is."""
    fake = fake_reviewer.install()
    with repairing(outputs={"record.jsonl": rec5(), "lean.diff": DIFF5}) as (run, ledger, training, by_id):
        stage(run, "labels", **cfg)
        persist = persist_of(run, ledger)
        for law in (L[1], L[2], L[3], L[5]):
            script(fake, law, both())
            assert review(run, ledger, law, persist) == "reviewed", law
        yield run, ledger, training, by_id, fake, persist


def label_repair_of(run, ledger, training, by_id):
    return label_repair.repair_law(run, ledger, training, by_id[L[5]], [], label_repair.ontology.load(run.opts.ontology),
                                   GapLedger.for_run(label_repair.paths.GAPS_DIR, run), [], [])


def fix5(run_, txn, law, evidence):
    """A review repair session that rewrites the rule of L-5 (its mark v1 → v2)."""
    return [cand.Change("node", N[5], node_rec(N[5]), files("node", N[5], "v2"))]


class LabelRepair(Base):
    """T6: the check runs again inside every label repair's candidate."""

    def test_a_label_repair_keeping_its_review_is_accepted_in_one_commit(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            calls = len(fake.property_calls)
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            self.assertEqual(label_repair_of(run, ledger, training, by_id), "committed")
            self.assertEqual(ledger.entries[L[5]].state, "accepted")
            s = br.own_status(run, ledger, L[5])
            self.assertEqual((s["ok"], s["class"]), (True, "reviewed"))
            self.assertIn("candidate", s["row"]["where"])
            self.assertEqual(len(fake.property_calls), calls)                        # no property call
            self.assertIn((L[5], ("v2",)), [(c[0], c[1]) for c in fake.check_calls])
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual(snap["review_states"][L[5]]["certificate"]["row"], br.row_sha(s["row"]))

    def test_a_label_repair_that_makes_a_finding_is_rolled_back_and_counted(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            fake.cells[L[5]] = on_mark(N[5], passes, finds)
            rows = live_rows(run)
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            self.assertEqual(label_repair_of(run, ledger, training, by_id), "rolled_back")
            st = run.label_states[L[5]]
            self.assertEqual(st["repairs"], 1)
            self.assertTrue(any(f["check"] == "review_non_regression" for f in st["last_repair"]["failed"]))
            self.assertEqual(live_rows(run), rows)
            self.assertEqual(ledger.entries[L[5]].state, "planned")
            self.assertTrue(br.own_status(run, ledger, L[5])["ok"])

    def test_another_law_made_undetermined_rolls_back(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            run.accepted_nodes[N[1]]["compositions"] = COMPOSES_5
            persist()
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")
            fake.cells[L[1]] = on_mark(N[5], passes, lambda roots, recs: [cell(r["id"], {roots[0]: "unknown"}) for r in recs])
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            self.assertEqual(label_repair_of(run, ledger, training, by_id), "rolled_back")
            failed = run.label_states[L[5]]["last_repair"]["failed"]
            self.assertTrue(any(f["check"] == "review_non_regression" and f["subject"] == L[1] for f in failed))

    def test_without_a_certificate_the_known_units_are_still_kept(self):
        """Fix 6: a law with no certificate but a finding row may not lose a passed unit or let its
        finding leave the check; a law with no row at all has nothing to keep."""
        with labelled() as (run, ledger, training, by_id, fake, persist):
            run.accepted_nodes[N[1]]["compositions"] = COMPOSES_5
            run.accepted_nodes[N[2]]["compositions"] = COMPOSES_5
            persist()
            fake.cells[L[1]] = finds                                                  # p finds, q passes: no certificate
            self.assertEqual(review(run, ledger, L[1], persist), "finding")
            run.review_states.pop(L[2])                                               # L-2: never reviewed
            persist()
            unknown = lambda which: (lambda roots, recs: [cell(r["id"], {roots[0]: "unknown"}) if r["id"] == which
                                                          else finds(roots, [r])[0] for r in recs])
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            for which in ("q", "p"):                                                  # the passed unit lost; the finding gone unknown
                with self.subTest(lost=which):
                    fake.cells[L[1]] = on_mark(N[5], finds, unknown(which))
                    self.assertEqual(label_repair_of(run, ledger, training, by_id), "rolled_back")
                    failed = run.label_states[L[5]]["last_repair"]["failed"]
                    self.assertTrue(any(f["subject"] == L[1] and f["check"] == "review_non_regression" for f in failed))
                    self.assertFalse(any(f["subject"] == L[2] for f in failed))      # nothing to keep: passes, issues nothing
            run.label_states[L[5]]["repairs"] = 0
            fake.cells[L[1]] = finds
            self.assertEqual(label_repair_of(run, ledger, training, by_id), "committed")
            self.assertEqual(br.own_status(run, ledger, L[2])["class"], "not_run")    # no certificate was issued for it

    def test_a_stop_after_the_commit_point_is_completed_whole(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            real = cand._apply
            seen = {"n": 0}

            def stop_once(journal, f, run_=None):
                if run_ is not None and seen["n"] == 0:
                    seen["n"] += 1
                    raise Crash()
                return real(journal, f, run_)
            with mock.patch.object(cand, "_apply", stop_once):
                with self.assertRaises(Crash):
                    label_repair_of(run, ledger, training, by_id)
            cand._OPEN.clear()
            self.assertIsNotNone(cand.recover_pending())                            # the next owner completes it
            fresh = Run(run.opts); snap = fresh.restore_state(); fresh.load_accepted()
            led = Ledger(run.ledger_file, list(L.values()), 2)
            fresh.law_entries = led.entries
            self.assertEqual(led.entries[L[5]].state, "accepted")
            s = br.own_status(fresh, led, L[5])
            self.assertEqual((s["ok"], s["class"]), (True, "reviewed"))
            self.assertEqual(snap["review_states"][L[5]]["certificate"]["row"], br.row_sha(s["row"]))

    def test_rows_of_a_rolled_back_candidate_copied_into_the_run_are_nothing(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            fake.cells[L[5]] = on_mark(N[5], passes, finds)
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            label_repair_of(run, ledger, training, by_id)
            staged = sorted(run.dir.glob("iter-*/candidate/*/review_evidence.jsonl"))
            self.assertTrue(staged)
            before = br.own_status(run, ledger, L[5])
            (run.dir / br.EVIDENCE_FILE).write_bytes(staged[-1].read_bytes())        # every row, the rolled-back one too
            self.assertEqual(br.own_status(run, ledger, L[5])["row"], before["row"])


class ReviewRepair(Base):
    """R15 (labels stage): a finding goes to a review repair with the label hook (no regression, no
    improvement asked) and the review hook (the finding cleared into a new certificate)."""

    def finding(self, fake, run, ledger, persist, law=L[5], rule=N[5], after=passes):
        fake.cells[law] = on_mark(rule, finds, after)
        self.assertEqual(review(run, ledger, law, persist), "finding")

    def test_a_finding_repaired_to_a_new_certificate_is_committed(self):
        with labelled() as (run, ledger, training, by_id, fake, persist), mock.patch.object(br, "REPAIR_SESSION", fix5):
            self.finding(fake, run, ledger, persist)
            self.assertEqual(br.work(run, ledger)["repair"], [L[5]])
            self.assertEqual(loop.runnable_work(run, replace(run.opts, label_stage=True, label_dataset="d"), ledger,
                                                ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2), {})["review_repairs"],
                             [L[5]])
            calls = len(fake.property_calls)
            self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "committed")
            s = br.own_status(run, ledger, L[5])
            self.assertEqual((s["ok"], s["class"]), (True, "reviewed"))
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual((snap["review_states"][L[5]]["repairs"], snap["review_states"][L[5]].get("active_repair")), (1, None))
            self.assertEqual(snap["review_states"][L[5]]["certificate"]["row"], br.row_sha(s["row"]))
            self.assertEqual(len(fake.property_calls), calls)
            self.assertEqual(run.label_states[L[5]]["outcome"], "mismatch")          # its labels did not have to improve

    def test_a_law_with_no_label_state_and_an_aligned_law_can_be_repaired(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            run.label_states.pop(L[2]); persist()                                     # never label-checked
            for law, node in ((L[2], N[2]), (L[3], N[3])):                            # L-3 is aligned
                with self.subTest(law=law):
                    self.finding(fake, run, ledger, persist, law, node)
                    change = lambda r, t, l, e, node=node: [cand.Change("node", node, node_rec(node), files("node", node, "v2"))]
                    with mock.patch.object(br, "REPAIR_SESSION", change):
                        self.assertEqual(br.repair_finding(run, ledger, law, training, persist, []), "committed")
                    self.assertTrue(br.own_status(run, ledger, law)["ok"])

    def test_a_repair_losing_a_label_match_rolls_back(self):
        with labelled() as (run, ledger, training, by_id, fake, persist), mock.patch.object(br, "REPAIR_SESSION", fix5):
            self.finding(fake, run, ledger, persist)
            set_verdict(training, "r5c", N[5], "violated")                            # r5c matched; now it does not
            self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "rolled_back")
            self.assertTrue(any(f["check"] == "label_non_regression" for f in run.review_states[L[5]]["last_repair"]["failed"]))

    def test_a_finding_that_disappears_into_anything_else_is_not_a_pass(self):
        others = {"unknown": lambda roots, recs: [cell(r["id"], {roots[0]: "unknown"}) for r in recs],
                  "outside the fragment": lambda roots, recs: [cell(r["id"], None, status="outside_fragment") for r in recs],
                  "empty antecedent": lambda roots, recs: [cell(r["id"], None, antecedent="empty") for r in recs],
                  "synthesis failed": lambda roots, recs: [cell(r["id"], None, status="synthesis_failed") for r in recs],
                  "a passed unit lost": lambda roots, recs: [cell("p", {roots[0]: "violated"}), cell("q", None, status="outside_fragment")]}
        for why, after in others.items():
            with self.subTest(why), labelled(coverage="bounded") as (run, ledger, training, by_id, fake, persist), \
                    mock.patch.object(br, "REPAIR_SESSION", fix5):
                self.finding(fake, run, ledger, persist, after=after)
                rows = live_rows(run)
                self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "rolled_back")
                s = br.own_status(run, ledger, L[5])
                self.assertEqual((s["ok"], s["class"]), (False, "finding"))
                self.assertEqual(live_rows(run), rows)
                self.assertEqual(run.review_states[L[5]]["repairs"], 1)
                self.assertNotIn(L[5], loop.label_ready(run, ledger))

    def test_attempts_are_counted_when_they_start_and_a_dispute_goes_to_the_operator(self):
        with labelled(repair_attempts=1) as (run, ledger, training, by_id, fake, persist):
            self.finding(fake, run, ledger, persist, after=finds)
            with mock.patch.object(br, "REPAIR_SESSION", side_effect=Crash()):
                with self.assertRaises(Crash):
                    br.repair_finding(run, ledger, L[5], training, persist, [])     # stopped mid-attempt
            cand._OPEN.clear()
            fresh = reload(run, ledger)
            self.assertEqual((fresh.review_states[L[5]]["repairs"], fresh.review_states[L[5]]["active_repair"]["attempt"]), (1, 1))
            with mock.patch.object(br, "REPAIR_SESSION", fix5):
                self.assertEqual(br.repair_finding(fresh, ledger, L[5], training, persist_of(fresh, ledger), []), "rolled_back")
            self.assertEqual(fresh.review_states[L[5]]["repairs"], 1)                # the resumed attempt is not counted again
            self.assertEqual(br.work(fresh, ledger)["repair"], [])
            self.assertEqual(br.route_holds(fresh, ledger, []), [L[5]])
        with labelled() as (run, ledger, training, by_id, fake, persist):
            self.finding(fake, run, ledger, persist)
            def disputes(*a):
                raise br.Dispute("the property reads the clause as covering a parked vehicle", "property")
            with mock.patch.object(br, "REPAIR_SESSION", disputes):
                self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "dispute")
            self.assertEqual(run.review_states[L[5]]["repairs"], 1)                  # a dispute is a substantive attempt
            self.assertEqual(br.route_holds(run, ledger, []), [L[5]])

    def test_a_session_that_did_not_run_counts_against_the_infrastructure_limit(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            self.finding(fake, run, ledger, persist)
            self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "unavailable")   # the default session
            st = run.review_states[L[5]]
            self.assertEqual((st.get("repairs", 0), st["infra_failures"], st.get("active_repair")), (0, 1, None))


class Limits(Base):
    """Asks, infrastructure retries and unknown outcomes: persistent, never resent."""

    def test_asks_are_counted_before_the_call_and_kept_across_restarts_and_stages(self):
        with rworld(kind="review", property_attempts=2) as (run, ledger, fake, persist):
            script(fake, L[1], pset(state="failed", tag="x"), pset(state="failed", tag="y"))
            self.assertEqual(review(run, ledger, L[1], persist), "failed")
            self.assertIn(L[1], br.work(run, ledger)["review"])
            fresh = reload(run, ledger)
            self.assertEqual(fresh.review_states[L[1]]["property_asks"], 1)
            self.assertEqual(review(fresh, ledger, L[1], persist_of(fresh, ledger)), "failed")
            stage(fresh, "labels"); stage(fresh, "review")
            self.assertNotIn(L[1], br.work(fresh, ledger)["review"])
            self.assertEqual(review(fresh, ledger, L[1], persist_of(fresh, ledger)), "held")
            self.assertEqual(len(fake.property_calls), 2)
            self.assertEqual(br.route_holds(fresh, ledger, []), [L[1]])

    def test_infrastructure_retries_are_bounded_beyond_the_first(self):
        with rworld(kind="review", infra_attempts=2) as (run, ledger, fake, persist):
            down = lambda: br.ReviewerUnavailable("refused before sending", executed=False)
            script(fake, L[1], down(), down(), down(), both())
            for _ in range(3):
                self.assertEqual(review(run, ledger, L[1], persist), "unavailable")
            self.assertEqual(run.review_states[L[1]]["property_asks"], 0)            # nothing was sent: no ask consumed
            self.assertNotIn(L[1], br.work(run, ledger)["review"])
            self.assertEqual(br.route_holds(run, ledger, []), [L[1]])
            self.assertEqual(jsonl.read_json(run.state_file, {})["review_states"][L[1]]["infra_failures"], 3)

    def test_an_unknown_outcome_is_never_resent_and_not_executed_needs_no_answer(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], br.ReviewerUnavailable("timed out after sending", executed=None), both())
            self.assertEqual(review(run, ledger, L[1], persist), "unavailable")
            self.assertEqual(review(run, ledger, L[1], persist), "unreconciled")
            self.assertEqual(len(fake.property_calls), 1)
            self.assertTrue(br.transition_refusals(jsonl.read_json(run.state_file, {}), run.dir))
            pending = run.review_states[L[1]]["pending_call"]
            d = run.dir / pending["workdir"]; d.mkdir(parents=True, exist_ok=True)
            (d / "response.json").write_text("{}")                                    # an answer was kept
            with self.assertRaisesRegex(ValueError, "cannot be recorded as not executed"):
                br.reconcile(run, L[1], executed=False)
            (d / "response.json").unlink()
            self.assertEqual(br.reconcile(run, L[1], executed=False), "not_executed")
            persist()
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")
            self.assertEqual(run.review_states[L[1]]["property_asks"], 1)

    def test_a_wrong_model_stops_every_call_of_the_run(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], br.WrongChannel("answered by another model"))
            script(fake, L[2], both())
            self.assertEqual(review(run, ledger, L[1], persist), "stopped")
            fresh = reload(run, ledger)                                               # persistent across a restart
            self.assertEqual(review(fresh, ledger, L[2], persist_of(fresh, ledger)), "stopped")
            self.assertEqual(len(fake.property_calls), 1)
            self.assertTrue(any("stopped run-wide" in x for x in br.transition_refusals({}, run.dir)))
            self.assertEqual(fresh.review_states[L[1]]["unusable_calls"][0]["outcome"], "wrong_model")   # settled, unusable
            with self.assertRaisesRegex(ValueError, "no pending call"):
                br.reconcile(fresh, L[1], executed=True)                             # nothing to reconcile: it is never resent
            self.assertTrue(br.run_stops(fresh))

    def test_a_budget_pause_propagates_and_judges_nothing(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], BudgetPaused("the review role's limit is reached"), both())
            with self.assertRaises(BudgetPaused):
                review(run, ledger, L[1], persist)
            st = jsonl.read_json(run.state_file, {})["review_states"][L[1]]
            self.assertEqual((st.get("pending_call"), st.get("last"), st.get("infra_failures", 0), st["property_asks"]), (None, None, 0, 0))
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")


class Resume(Base):
    """A review stopped after each commit equals one that was not, except a call with no known outcome."""

    def outcome(self, run, ledger):
        st = run.review_states[L[1]]
        row = br.own_status(run, ledger, L[1]).get("row") or {}
        return ((st.get("certificate") or {}).get("disposition"), br.own_status(run, ledger, L[1])["ok"], st.get("active_set"),
                st.get("sets"), st.get("property_asks"))

    def test_each_stop_point(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], both())
            review(run, ledger, L[1], persist)
            want = self.outcome(run, ledger)
        for k in (1, 2, 3, 4):
            with self.subTest(stop_after_persist=k), rworld(kind="review") as (run, ledger, fake, persist):
                script(fake, L[1], both(), both())
                n = {"i": 0}

                def stopping():
                    n["i"] += 1
                    if n["i"] == k == 3:
                        raise Crash()                                                # the row appended, its pointers not committed
                    persist()
                    if n["i"] == k:
                        raise Crash()
                try:
                    review(run, ledger, L[1], stopping)
                except Crash:
                    pass
                fresh = reload(run, ledger)
                if k == 1:                                                           # the call committed, its outcome not known
                    self.assertEqual(review(fresh, ledger, L[1], persist_of(fresh, ledger)), "unreconciled")
                    self.assertEqual(len(fake.property_calls), 0)
                    continue
                if k == 3:
                    self.assertEqual(br.own_status(fresh, ledger, L[1])["class"], "not_run")   # an orphan row is nothing
                if br.work(fresh, ledger)["review"]:
                    review(fresh, ledger, L[1], persist_of(fresh, ledger))
                self.assertEqual(self.outcome(fresh, ledger), want)
                self.assertEqual(len(fake.property_calls), 1)                        # the adopted answer is never asked again


class Transitions(unittest.TestCase):
    """T2/R7: the stage commands on a synthetic repository: G → R → L → R → G allowed, G → L refused,
    review refused under `none`, and no transition while a call's outcome is unknown."""

    def setUp(self):
        from scripts.tests import test_s24_a2_stage as s24
        self.s24 = s24

    @contextmanager
    def required_world(self):
        s24 = self.s24
        fake_reviewer.install()
        with s24.world() as w:
            rows = stages.read_stages(w.rd)
            rows[0]["acceptance_policy"] = policy()
            (w.rd / stages.STAGES_FILE).write_text(json.dumps(rows[0]) + "\n")
            s24.fake_export("r")
            yield w

    def step(self, w, kind, frm, t):
        from harness.tools import stage as stage_tool
        rec = stage_tool.enter("r", kind, frm, t)
        self.assertEqual(rec["status"], "exported")
        stage_tool.confirm("r", t, w.push())
        return rec["to"]

    def test_the_table(self):
        s24 = self.s24
        from harness.tools import stage as stage_tool
        with self.required_world() as w:
            before = s24.tree_bytes(w.root)
            with self.assertRaises(SystemExit) as e:
                stage_tool.enter("r", "labels", "G0", "tx")
            self.assertIn(stages.LABELS_REFUSAL, str(e.exception))
            self.assertEqual(s24.tree_bytes(w.root), before)
            r1 = self.step(w, "review", "G0", "t1")
            l1 = self.step(w, "labels", r1, "t2")
            r2 = self.step(w, "review", l1, "t3")
            g1 = self.step(w, "generation", r2, "t4")
            self.assertEqual((r1, l1, r2, g1), ("R0", "L0", "R1", "G1"))
            kinds = [r["stage_kind"] for r in stages.read_stages(w.rd) if r["event"] == "open"]
            self.assertEqual(kinds, ["generation", "review", "labels", "review", "generation"])
            self.assertTrue(all(r["acceptance_policy"] == policy() for r in stages.read_stages(w.rd) if r["event"] == "open"))

    def test_refusals_before_anything_is_written(self):
        s24 = self.s24
        from harness.tools import stage as stage_tool
        with s24.world() as w:                                                       # an old policy: `review: none`
            before = s24.tree_bytes(w.root)
            with self.assertRaises(SystemExit) as e:
                stage_tool.enter("r", "review", "G0", "t1")
            self.assertIn(stages.REVIEW_REFUSAL, str(e.exception))
            self.assertEqual(s24.tree_bytes(w.root), before)
        with self.required_world() as w:
            fake_reviewer.install("fake-v2")                                         # another implementation than the run fixed
            before = s24.tree_bytes(w.root)
            with self.assertRaises(SystemExit) as e:
                stage_tool.enter("r", "review", "G0", "t1")
            self.assertIn("another implementation", str(e.exception))
            self.assertEqual(s24.tree_bytes(w.root), before)
        with self.required_world() as w:
            snap = json.loads((w.rd / "state.json").read_text())
            snap["review_states"] = {"A": {"pending_call": {"spec_key": "k"}}}
            (w.rd / "state.json").write_text(json.dumps(snap))
            from harness.phases import label_check
            label_check.freeze(w.rd)
            s24.fake_export("r")
            before = s24.tree_bytes(w.root)
            with self.assertRaises(SystemExit) as e:
                stage_tool.enter("r", "review", "G0", "t1")
            self.assertIn("no known outcome", str(e.exception))
            self.assertEqual(s24.tree_bytes(w.root), before)


if __name__ == "__main__":
    unittest.main()
