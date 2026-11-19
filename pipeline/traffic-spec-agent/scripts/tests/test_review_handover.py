"""The run-time contracts around the review stage, with no model:

- `stage.handover`, the conditions under which the launcher enters the next stage itself: each one
  refusing on its own (waiting at the checkpoint), a round trip without progress the operator's, and
  the transition entered only when all hold, on a synthetic repository at a handed-over checkpoint;
- the labels stage holding for the operator a law whose review repairs are spent (its finding
  stands), with its operator line, as the review stage does;
- the reviewer fixed when the run first enters its review stage: G0 fixes none, a launch that generates
  may not name one, the first review entry must name a registered one and records it with its digest in
  the new stage's row, a later entry keeps it (another name or implementation refused), and the handover
  waits until the reviewer it would name is registered;
- the review limits (2/2/3) raised by the run's options and never lowered, the reviewer and the
  coverage fixed, and every change of a run limit recorded with its old and new value;
- the spend report: money apart from the Claude API equivalent, each request counted once and an
  unsettled one at its reservation; a Claude row says how its session was paid."""
import hashlib
import json
import os
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness import loop
from harness.agents import session
from harness.phases import behaviour_review as br
from harness.phases import feedback
from harness.store import budget, jsonl, shared_failures, stages
from harness.store.state import Options, stage_policy_refusal
from harness.tools import stage
from scripts.tests import fake_reviewer
from scripts.tests import test_s24_a2_stage as a2
from scripts.tests import test_behaviour_review_stage as brs
from scripts.tests.test_label_repair import L


def required_policy() -> dict:
    fake_reviewer.install()
    return {"label_repair": True, "dependency": "build_usable_v1", "review": "required",
            "review_config": br.fix_reviewer(br.config_of({}), fake_reviewer.NAME)}


class Handover(unittest.TestCase):
    """`stage.handover` on run `r` at a handed-over checkpoint (the stand-ins of the stage tests)."""

    def setup(self, w, kinds=("generation",), pol=None, budgets=True):
        """The run's stage record: the stages of `kinds` in order on this checkout's code, under `pol`
        (review required by default), exported; the reviewer's and total budgets set."""
        pol = pol or required_policy()
        rows = []
        for i, kind in enumerate(kinds):
            sid = f"{kind[0].upper()}{i}"
            if rows:
                rows.append({"event": "close", "stage_id": rows[-1]["stage_id"], "transition_id": f"t{i}",
                             "output_checkpoint": None, "closed_at": "x"})
            prev = next((r["stage_id"] for r in reversed(rows) if r["event"] == "open"), None)
            rows.append({**w.g0, "stage_id": sid, "stage_kind": kind, "launch_kinds": list(stages.LAUNCH_KINDS[kind]),
                         "previous_stage_id": prev, "transition_id": f"t{i}", "acceptance_policy": pol})
        (w.rd / stages.STAGES_FILE).write_text("".join(json.dumps(r) + "\n" for r in rows))
        o = json.loads((w.rd / "options.json").read_text())
        if budgets:
            o.update(behaviour_review_budget_usd=5.0, total_budget_usd=50.0)
        (w.rd / "options.json").write_text(json.dumps(o))
        a2.fake_export("r")

    def state(self, w, **fields):
        s = json.loads((w.rd / "state.json").read_text())
        s.update(fields)
        (w.rd / "state.json").write_text(json.dumps(s))

    def assert_waits(self, why, to="review", dataset=None):
        verdict, reasons = stage.handover("r", to, dataset)
        self.assertEqual(verdict, "wait", reasons)
        self.assertTrue(any(why in r for r in reasons), reasons)

    def test_generation_to_review_when_every_condition_holds(self):
        with a2.world() as w:
            self.setup(w)
            self.assertEqual(stage.handover("r", "review"), ("enter", []))

    def test_each_condition_alone_keeps_the_run_at_its_checkpoint(self):
        cases = {
            "label repair(s) active": lambda w: self.state(w, label_states={"A": {"active": {"attempt": 1}}}),
            "concept review(s) deferred": lambda w: self.state(w, deferred_concepts=[{"concept_id": "c"}]),
            "a review repair active": lambda w: self.state(w, review_states={"A": {"active_repair": {"attempt": 1}}}),
            "have no settlement": lambda w: (w.rd / "usage.jsonl").write_text(json.dumps(
                {"state": "pending", "request": "q1", "vendor": "anthropic", "reserved_usd": 2.0}) + "\n"),
            "differs from the active stage's baseline": lambda w: w.change("harness/loop.py"),
            "last export is not of its active stage": lambda w: (w.rd / stages.STAGES_FILE).write_text(
                (w.rd / stages.STAGES_FILE).read_text() + "\n"),
        }
        for why, make in cases.items():
            with self.subTest(why), a2.world() as w:
                self.setup(w)
                make(w)
                self.assert_waits(why)

    def test_an_active_stop_of_any_kind_is_the_operators_and_never_entered(self):
        """Every stop `feedback.active_stops` lists for the run, alone and with no other blocker, answers
        `operator` (launcher exit 4) naming the stop, never `enter`."""
        cases = {
            "paused_defect": lambda w: (w.rd / shared_failures.PAUSES).write_text(json.dumps(
                {"iteration": 1, "signatures": ["sig"], "occurrences": {}, "spent_usd": {}}) + "\n"),
            "wrong_model": lambda w: budget.write_stop(w.rd / "usage.jsonl", "wrong_model", "another model", law="A"),
            "unknown_execution": lambda w: self.state(w, review_states={"A": {"pending_call": {"spec_key": "k"}}}),
            "budget": lambda w: (w.rd / "usage.jsonl").write_text(json.dumps(
                {"state": "settled", "request": "q1", "vendor": "anthropic", "cost_usd": 60.0, "label": "x"}) + "\n"),
        }
        for kind, make in cases.items():
            with self.subTest(kind), a2.world() as w:
                self.setup(w)
                (w.rd / "summary.json").write_text(json.dumps({"status": "awaiting_review", "stop_reason": ""}))
                self.assertEqual(stage.handover("r", "review"), ("enter", []))
                make(w)
                verdict, reasons = stage.handover("r", "review")
                self.assertEqual(verdict, "operator", reasons)
                self.assertTrue(any(f"({kind}) is active" in r for r in reasons), reasons)
                self.assertEqual(stage.main(["handover", "r", "--to", "review"]), 4)

    def test_a_paused_defect_alone_keeps_every_handover_from_entering(self):
        """A run at `awaiting_review` with an unanswered `paused_defect` and no other blocker is never
        entered, from generation or from labels; once a resume answers the pause, it is."""
        for kinds in (("generation",), ("generation", "review", "labels")):
            with self.subTest(kinds), a2.world() as w:
                self.setup(w, kinds=kinds)
                (w.rd / "summary.json").write_text(json.dumps({"status": "awaiting_review", "stop_reason": ""}))
                (w.rd / shared_failures.PAUSES).write_text(json.dumps(
                    {"iteration": 1, "signatures": ["sig"], "occurrences": {}, "spent_usd": {}}) + "\n")
                verdict, reasons = stage.handover("r", "review")
                self.assertEqual(verdict, "operator", reasons)
                self.assertIn("stop `defect-1` (paused_defect) is active", reasons[0])
                shared_failures.answer(w.rd)
                self.assertEqual(stage.handover("r", "review"), ("enter", []))

    def test_the_operator_chooses_a_partial_scope_and_this_machine_must_hold_the_reviewer(self):
        with a2.world(gen=a2.report(["A"], ["B"])) as w:
            self.setup(w)
            self.assert_waits("stage-enter with SCOPE")                              # never a partial scope by itself
        with a2.world() as w:
            self.setup(w, pol={**required_policy(), "review_config": br.fix_reviewer(br.config_of({}), "nobody")})
            self.assert_waits("no reviewer here")
        with a2.world() as w:
            self.setup(w, budgets=False)
            self.assert_waits("behaviour_review_budget_usd")
        with a2.world() as w:
            self.setup(w, pol={"label_repair": True, "dependency": "build_usable_v1", "review": "none"})
            self.assert_waits("not `review: required`")
        with a2.world() as w:
            self.setup(w)
            self.assert_waits("only by the operator's stage-enter", to="labels")      # generation never goes to labels

    def test_review_to_labels_needs_the_runs_dataset_here(self):
        with a2.world() as w, tempfile.TemporaryDirectory() as t:
            self.setup(w, kinds=("generation", "review"))
            self.assert_waits("no training dataset", to="labels")
            self.assert_waits("does not open", to="labels", dataset=t)
            (Path(t) / "INDEX.csv").write_text("index v1\n")
            ds = SimpleNamespace(data_version="d1")
            with mock.patch("recorded.dataset.Dataset", lambda p: ds):
                self.assertEqual(stage.handover("r", "labels", t), ("enter", []))     # no comparison set fixed yet
                (w.rd / "comparison_set.json").write_text(json.dumps({"data_version": "d1", "index": a2.sha(Path(t) / "INDEX.csv")}))
                a2.fake_export("r")
                self.assertEqual(stage.handover("r", "labels", t), ("enter", []))
                ds.data_version = "d2"
                self.assert_waits("data version d2", to="labels", dataset=t)

    def test_a_round_trip_without_progress_is_the_operators(self):
        with a2.world() as w:
            self.setup(w, kinds=("generation", "review", "labels"))
            raw = (w.rd / "state.json").read_bytes()                                 # what the review stage R1 handed over
            h = a2.sha(w.rd / "state.json")
            (w.rd / stages.BLOBS_DIR).mkdir(parents=True)
            (w.rd / stages.BLOBS_DIR / h).write_bytes(raw)
            (w.rd / stages.STAGES_DIR / "R1").mkdir(parents=True)
            (w.rd / stages.STAGES_DIR / "R1" / "manifest.json").write_text(json.dumps({"stage_id": "R1", "files": {"results/r/state.json": h}}))
            a2.fake_export("r")
            verdict, reasons = stage.handover("r", "review")
            self.assertEqual(verdict, "operator", reasons)
            self.assertIn("round trip without progress", reasons[0])
            moved = json.loads(raw); moved["review_states"] = {"A": {"repairs": 1}}         # R1 handed over another state
            (w.rd / stages.BLOBS_DIR / h).write_bytes(json.dumps(moved).encode())
            self.assertEqual(stage.handover("r", "review"), ("enter", []))              # a blob not its digest: no comparison
            h2 = hashlib.sha256(json.dumps(moved).encode()).hexdigest()
            (w.rd / stages.BLOBS_DIR / h2).write_bytes(json.dumps(moved).encode())
            (w.rd / stages.STAGES_DIR / "R1" / "manifest.json").write_text(json.dumps({"stage_id": "R1", "files": {"results/r/state.json": h2}}))
            self.assertEqual(stage.handover("r", "review"), ("enter", []))

    def test_the_command_line(self):
        with a2.world() as w:
            self.setup(w)
            self.assertEqual(stage.main(["handover", "r", "--to", "review"]), 0)
            self.assertEqual(stage.main(["handover", "r", "--to", "labels"]), 1)


def unfixed_policy() -> dict:
    """The policy a new run's G0 records: the review required, coverage and limits fixed, no reviewer."""
    return {**required_policy(), "review_config": br.config_of({})}


class ReviewerFixedAtReview(unittest.TestCase):
    """The run's reviewer is fixed by its first review entry, in the transition's own stage row."""

    def setUp(self):
        fake_reviewer.install()
        self.addCleanup(fake_reviewer.install)
        self.addCleanup(br.IMPLEMENTATIONS.pop, "other", None)

    def world(self, w):
        rows = stages.read_stages(w.rd)
        rows[0]["acceptance_policy"] = unfixed_policy()
        (w.rd / stages.STAGES_FILE).write_text(json.dumps(rows[0]) + "\n")
        a2.fake_export("r")

    def step(self, w, kind, frm, t, reviewer=None):
        rec = stage.enter("r", kind, frm, t, reviewer=reviewer)
        self.assertEqual(rec["status"], "exported")
        stage.confirm("r", t, w.push())
        return rec

    def refused(self, w, why, *args, **kw):
        before = a2.tree_bytes(w.root)
        with self.assertRaises(SystemExit) as e:
            stage.enter("r", *args, **kw)
        self.assertIn(why, str(e.exception))
        self.assertEqual(a2.tree_bytes(w.root), before)                              # nothing written
        return str(e.exception)

    def config(self, w, sid):
        return next(r for r in stages.read_stages(w.rd) if r["event"] == "open" and r["stage_id"] == sid)["acceptance_policy"]["review_config"]

    def test_g0_fixes_no_reviewer_and_no_launch_that_generates_names_one(self):
        g0 = {"stage_id": "G0", "acceptance_policy": unfixed_policy()}
        self.assertEqual(br.config_defects(g0["acceptance_policy"]["review_config"]), [])
        opts = Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), label_repair=True, label_deferred=True)
        self.assertIsNone(stage_policy_refusal(g0, opts))                            # the launch in G0 runs
        self.assertIsNone(loop.launch_refusal(replace(opts, dry_run=True)))
        named = replace(opts, behaviour_reviewer="fake")
        self.assertRegex(stage_policy_refusal(g0, named) or "", "fixed when the run enters its review stage")
        self.assertRegex(loop.launch_refusal(replace(named, dry_run=True)) or "", "fixed when the run enters its review stage")

    def test_the_first_review_entry_fixes_the_reviewer_and_a_later_one_keeps_it(self):
        with a2.world() as w:
            self.world(w)
            self.assertIn(stages.REVIEW_REFUSAL, self.refused(w, "none is named", "review", "G0", "t1"))
            self.refused(w, "`nobody` is not registered", "review", "G0", "t1", reviewer="nobody")
            self.refused(w, "only on entering a review stage", "generation", "G0", "t1", reviewer="fake")
            rec = self.step(w, "review", "G0", "t1", reviewer="fake")
            r1 = rec["to"]
            fixed = rec["rows"][1]["acceptance_policy"]["review_config"]               # in the transition's journal rows
            self.assertEqual(self.config(w, r1), fixed)
            self.assertEqual((fixed["reviewer"], fixed["implementation"], fixed["test_only"]),
                             ("fake", br.impl_of(fake_reviewer.FAKE), True))
            g0 = self.config(w, "G0")
            self.assertEqual({k: fixed[k] for k in ("coverage", *br.DEFAULT_LIMITS)}, {k: g0[k] for k in ("coverage", *br.DEFAULT_LIMITS)})
            self.assertEqual((g0["reviewer"], g0["implementation"], g0["test_only"]), (None, None, False))
            l1 = self.step(w, "labels", r1, "t2")["to"]
            self.assertEqual(self.config(w, l1), fixed)
            br.register("other", lambda: fake_reviewer.Fake("other-v1"))
            self.refused(w, "keeps its reviewer once its review stage fixed it", "review", l1, "t3", reviewer="other")
            r2 = self.step(w, "review", l1, "t3", reviewer="fake")["to"]                # the same one named
            self.assertEqual(self.config(w, r2), fixed)
            l2 = self.step(w, "labels", r2, "t4")["to"]
            r3 = self.step(w, "review", l2, "t5")["to"]                                 # none named: the fixed one stands
            self.assertEqual(self.config(w, r3), fixed)
            r4 = self.step(w, "review", r3, "t6", reviewer="fake")["to"]                # review → review
            self.assertEqual(self.config(w, r4), fixed)
            fake_reviewer.install("fake-v2")                                           # the same name, another implementation
            self.refused(w, "another implementation than the run fixed", "review", r4, "t7", reviewer="fake")
            self.refused(w, "another implementation than the run fixed", "review", r4, "t7")

    def test_the_review_launch_names_the_fixed_reviewer_or_none(self):
        row = {"stage_id": "R1", "acceptance_policy": {**required_policy()}}
        opts = Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), label_repair=True, review_stage=True)
        self.assertIsNone(stage_policy_refusal(row, opts))
        self.assertIsNone(stage_policy_refusal(row, replace(opts, behaviour_reviewer="fake")))
        self.assertRegex(stage_policy_refusal(row, replace(opts, behaviour_reviewer="other")) or "", "keeps its reviewer")

    def test_the_handover_waits_until_the_reviewer_it_names_is_registered(self):
        with a2.world() as w:
            Handover.setup(self, w, pol=unfixed_policy())
            verdict, reasons = stage.handover("r", "review")
            self.assertEqual(verdict, "wait")
            self.assertTrue(any("no reviewer here" in r and "none is named" in r for r in reasons), reasons)
            verdict, reasons = stage.handover("r", "review", reviewer="nobody")        # no production reviewer registered
            self.assertEqual(verdict, "wait")
            self.assertTrue(any("`nobody` is not registered" in r for r in reasons), reasons)
            self.assertEqual(stage.handover("r", "review", reviewer="fake"), ("enter", []))
            self.assertEqual(stage.main(["handover", "r", "--to", "review"]), 1)
            self.assertEqual(stage.main(["handover", "r", "--to", "review", "--behaviour_reviewer", "fake"]), 0)
        with a2.world() as w:                                                         # once fixed: the one fixed, or none named
            Handover.setup(self, w, pol=required_policy())
            self.assertEqual(stage.handover("r", "review"), ("enter", []))
            self.assertEqual(stage.handover("r", "review", reviewer="fake"), ("enter", []))
            br.register("other", lambda: fake_reviewer.Fake("other-v1"))
            verdict, reasons = stage.handover("r", "review", reviewer="other")
            self.assertEqual(verdict, "wait")
            self.assertTrue(any("keeps its reviewer" in r for r in reasons), reasons)


class LabelStageHold(brs.Base):
    """A finding whose review repairs are spent is neither review repair work nor label repair work; the
    labels stage holds it for the operator on its decision token and says so."""

    def test_spent_review_repairs_are_held_in_the_labels_stage(self):
        with brs.labelled(repair_attempts=1) as (run, ledger, training, by_id, fake, persist):
            brs.ReviewRepair.finding(self, fake, run, ledger, persist, after=brs.finds)
            with mock.patch.object(br, "REPAIR_SESSION", brs.fix5):
                self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "rolled_back")
            from harness.phases import label_repair
            self.assertNotIn(L[5], br.work(run, ledger)["repair"])
            self.assertNotIn(L[5], label_repair.awaiting(run, ledger))
            self.assertEqual(ledger.entries[L[5]].state, "planned")
            blocked = sorted(l for l, e in ledger.entries.items() if e.state == "blocked")
            prog = {"notes": [], "to_user": [], "gaps_filed": [], "coder_narrowings": {}, "stage": "start"}
            opts = replace(run.opts, label_repair=True, label_deferred=False, label_stage=True)
            with mock.patch.object(loop, "accept_ready", lambda *a, **k: None), \
                    mock.patch.object(label_repair, "run_repairs", lambda *a, **k: {}), \
                    mock.patch.object(loop.feedback_phase, "write_feedback", lambda *a, **k: None):
                loop.label_iteration(run, opts, prog, persist, ledger, None, None, by_id, [], None, training)
            self.assertEqual(ledger.entries[L[5]].state, "blocked")
            self.assertIn(f"decision:{L[5]}", ledger.entries[L[5]].own_gaps)
            self.assertTrue(any(x.startswith(f"`{L[5]}`: held for you — its review repairs are spent") for x in prog["to_user"]),
                            prog["to_user"])
            self.assertEqual(sorted(l for l, e in ledger.entries.items() if e.state == "blocked"), blocked + [L[5]])   # only it


class Limits(unittest.TestCase):
    """The reviewer and coverage are fixed; the review limits are run limits: raised, never lowered."""

    def test_raised_never_lowered(self):
        fake_reviewer.install()
        row = {"stage_id": "R1", "acceptance_policy": brs.policy()}
        opts = Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), label_repair=True, review_stage=True,
                       behaviour_reviewer="fake")
        self.assertIsNone(stage_policy_refusal(row, replace(opts, review_repair_attempts=5, review_infra_attempts=4)))
        self.assertRegex(stage_policy_refusal(row, replace(opts, review_property_attempts=1)) or "", "never lowered")
        self.assertRegex(stage_policy_refusal(row, replace(opts, review_coverage="bounded")) or "", "fixed for its life")
        with tempfile.TemporaryDirectory() as t, mock.patch.object(br, "_stage", lambda r: row):
            run = SimpleNamespace(dir=Path(t), state_file=Path(t) / "state.json")
            self.assertEqual(br.config(run)["repair_attempts"], 2)
            saved = {"review_repair_attempts": 2, "review_property_attempts": 2, "review_infra_attempts": 3}
            loop.record_limit_changes(run, saved, replace(opts, review_repair_attempts=5))
            loop.record_limit_changes(run, {**saved, "review_repair_attempts": 5}, replace(opts, review_repair_attempts=4))
            cfg = br.config(run)                                                     # the last value set, never below the fixed one
            self.assertEqual((cfg["repair_attempts"], cfg["property_attempts"], cfg["infra_attempts"], cfg["reviewer"]), (4, 2, 3, "fake"))
            jsonl.append_atomic(Path(t) / loop.LIMIT_CHANGES_FILE, {"option": "review_property_attempts", "from": 2, "to": 1})
            self.assertEqual(br.config(run)["property_attempts"], 2)

    def test_each_change_of_a_run_limit_is_recorded(self):
        with tempfile.TemporaryDirectory() as t:
            run = SimpleNamespace(dir=Path(t), state_file=Path(t) / "state.json")
            run.state_file.write_text(json.dumps({"iteration": 4}))
            opts = Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), claude_budget_usd=400,
                           total_budget_usd=425, review_repair_attempts=3, model="m2")
            saved = {"claude_budget_usd": 300, "total_budget_usd": 325, "review_repair_attempts": 2, "model": "m1",
                     "label_repair_attempts": 2}
            rows = loop.record_limit_changes(run, saved, opts)
            self.assertEqual(sorted((r["option"], r["from"], r["to"], r["iteration"]) for r in rows),
                             [("claude_budget_usd", 300, 400, 4), ("review_repair_attempts", 2, 3, 4), ("total_budget_usd", 325, 425, 4)])
            self.assertEqual(jsonl.read_strict(Path(t) / loop.LIMIT_CHANGES_FILE), rows)
            self.assertEqual(loop.record_limit_changes(run, {**saved, **{r["option"]: r["to"] for r in rows}}, opts), [])


class Spend(unittest.TestCase):

    def test_money_apart_from_the_api_equivalent(self):
        rows = [{"state": "pending", "request": "o", "vendor": "openai", "reserved_usd": 9.0},
                {"state": "settled", "request": "o", "vendor": "openai", "cost_usd": 1.0},
                {"state": "pending", "request": "a", "vendor": "anthropic", "reserved_usd": 20.0},
                {"state": "settled", "request": "a", "vendor": "anthropic", "cost_usd": 2.0, "billing": "account"},
                {"state": "settled", "request": "k", "vendor": "anthropic", "cost_usd": 3.0, "billing": "api_key"},
                {"state": "pending", "request": "lost", "vendor": "anthropic", "reserved_usd": 4.0},
                {"state": "pending", "request": "u", "vendor": "anthropic", "reserved_usd": 5.0},
                {"state": "unknown", "request": "u", "vendor": "anthropic", "reserved_usd": 5.0, "cost_usd": None, "billing": "account"},
                {"state": "settled", "vendor": "anthropic", "cost_usd": 0.5},
                budget.stop_row("wrong_model", "x")]
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "usage.jsonl"
            f.write_text("".join(json.dumps(r) + "\n" for r in rows))
            self.assertEqual(feedback.spend_report(f), {"cash": {"openai": 1.0, "claude_api_key": 3.0}, "claude_api_equivalent": 7.0,
                                                        "claude_billing_not_recorded": 4.5, "unsettled_requests": 2})

    def test_a_claude_row_says_how_it_was_paid(self):
        with mock.patch.dict(os.environ, {}, clear=False):
            os.environ.pop("ANTHROPIC_API_KEY", None)
            self.assertEqual(session.claude_billing({"PYTHONPATH": "x"}), "account")
            self.assertEqual(session.claude_billing({"ANTHROPIC_API_KEY": "k"}), "api_key")
            os.environ["ANTHROPIC_API_KEY"] = "k"
            self.assertEqual(session.claude_billing(None), "api_key")


if __name__ == "__main__":
    unittest.main()
